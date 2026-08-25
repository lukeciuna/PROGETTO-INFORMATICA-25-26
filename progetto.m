%% =========================================================
% 1. PARAMETRI DI ACQUISIZIONE DEL SEGNALE ECG
% =========================================================

% In questa prima fase vengono definiti i parametri necessari per
% l'elaborazione del segnale ECG reale utilizzato nel progetto.
%
% Il segnale analizzato non viene generato artificialmente, ma proviene
% da una registrazione reale appartenente al MIT-BIH Arrhythmia Database,
% un database clinico ampiamente utilizzato nella ricerca scientifica
% per lo sviluppo e la valutazione di algoritmi automatici di analisi ECG.
%
% La frequenza di campionamento utilizzata è pari a 360 Hz, ovvero il
% segnale viene acquisito attraverso 360 campioni ogni secondo.
% Questo valore permette di descrivere con sufficiente precisione le
% variazioni temporali dell'attività elettrica cardiaca, comprese quelle
% associate ai complessi QRS.


%% =========================================================
% 2. CARICAMENTO DEL SEGNALE ECG REALE DA PHYSIONET
% =========================================================

% Il segnale ECG utilizzato viene caricato dal file precedentemente
% ottenuto dal database MIT-BIH disponibile sulla piattaforma PhysioNet.
%
% La registrazione scelta corrisponde al record 100 del database e
% contiene un tracciato ECG reale acquisito durante il monitoraggio
% di un paziente.
%
% L'utilizzo di un segnale reale permette di rendere l'analisi più
% rappresentativa rispetto a un segnale simulato, poiché sono presenti
% tutte le caratteristiche tipiche di una registrazione clinica,
% come variazioni del ritmo cardiaco e possibili disturbi presenti
% durante l'acquisizione.


load('100.mat');


% La registrazione ECG contiene più informazioni associate al segnale.
% In questa fase viene selezionato il primo canale disponibile, che
% rappresenta il tracciato ECG utilizzato per tutte le elaborazioni
% successive.
%
% La conversione in vettore riga permette di uniformare il formato
% del segnale e facilitarne la gestione all'interno delle funzioni MATLAB.

ecg = ecg(:)';


% Il database MIT-BIH utilizza una frequenza di campionamento pari a
% 360 Hz. Questo parametro viene mantenuto durante tutte le operazioni
% successive perché necessario per convertire correttamente le posizioni
% dei campioni in valori temporali.

Fs = 360;


% Creazione dell'asse temporale associato al segnale.
%
% Ogni campione ECG viene associato al relativo istante di acquisizione.
% Questo permette di rappresentare graficamente il segnale nel dominio
% del tempo e di calcolare successivamente parametri come gli intervalli RR
% e la frequenza cardiaca.

t = (0:length(ecg)-1)/Fs;


% Per rendere più efficiente l'elaborazione viene considerata solamente
% una finestra iniziale della registrazione della durata di 60 secondi.
%
% Questa durata è sufficiente per individuare diversi cicli cardiaci,
% calcolare gli intervalli tra battiti consecutivi e ottenere una stima
% della frequenza cardiaca media.

durata = 60;


% Conversione della durata temporale scelta nel corrispondente numero
% di campioni necessari.

campioni = durata * Fs;


% Controllo di sicurezza per verificare che il numero di campioni richiesti
% non sia superiore alla lunghezza effettiva della registrazione disponibile.

campioni = min(campioni,length(ecg));


% Estrazione della porzione di ECG selezionata.

ecg = ecg(1:campioni);


% Aggiornamento dell'asse temporale dopo la riduzione del segnale.

t = (0:length(ecg)-1)/Fs;



%% =========================================================
% VISUALIZZAZIONE DEL SEGNALE ECG GREZZO
% =========================================================

% Prima di applicare qualsiasi elaborazione digitale viene visualizzato
% il segnale ECG originale.
%
% Questa rappresentazione permette di osservare direttamente il tracciato
% così come acquisito dal database, evidenziando la forma d'onda cardiaca
% prima delle operazioni di filtraggio e rilevamento automatico.

figure;

plot(t,ecg);


% L'asse orizzontale rappresenta il tempo espresso in secondi,
% mentre l'asse verticale rappresenta l'ampiezza del segnale ECG.

title('ECG reale MIT-BIH - PhysioNet');

xlabel('Tempo (s)');
ylabel('Ampiezza');

grid on;



%% =========================================================
% 3. FILTRAGGIO DEL SEGNALE ECG
% =========================================================

% Il segnale ECG acquisito può contenere componenti indesiderate dovute
% all'ambiente di acquisizione, al movimento del paziente o agli strumenti
% utilizzati durante la registrazione.
%
% Per migliorare la qualità del segnale viene quindi applicato un filtro
% passa-banda con frequenza compresa tra 5 Hz e 15 Hz.
%
% Questa banda permette di mantenere principalmente le componenti associate
% ai complessi QRS, che rappresentano la parte del segnale ECG caratterizzata
% dalle variazioni più rapide e importanti per il rilevamento del battito.


[b,a] = butter(4,[5 15]/(Fs/2),'bandpass');


% Viene utilizzato un filtro Butterworth del quarto ordine.
%
% Questo tipo di filtro è caratterizzato da una risposta in frequenza
% regolare e consente di attenuare le componenti indesiderate mantenendo
% una buona qualità del segnale nella banda di interesse.


% Il filtraggio viene effettuato attraverso la funzione filtfilt.
%
% A differenza di un filtraggio tradizionale, questa funzione applica
% l'operazione sia in avanti sia all'indietro nel tempo.
%
% In questo modo viene eliminato lo sfasamento temporale introdotto dal
% filtro, mantenendo la corretta posizione dei complessi QRS all'interno
% del segnale.

ecg_filt = filtfilt(b,a,ecg);

%% =========================================================
% CONFRONTO TRA SEGNALE ECG ORIGINALE E SEGNALE FILTRATO
% =========================================================

% Dopo l'applicazione del filtro viene effettuato un confronto grafico
% tra il segnale ECG originale e quello filtrato.
%
% Questa visualizzazione permette di osservare l'effetto del filtraggio
% digitale e verificare la riduzione delle componenti indesiderate,
% mantenendo comunque riconoscibile la morfologia caratteristica del
% segnale cardiaco.


figure;

plot(t,ecg,'b'); 
hold on;

plot(t,ecg_filt,'r');


legend('Segnale originale','Segnale filtrato');

title('Confronto tra ECG originale e filtrato');

xlabel('Tempo (s)');
ylabel('Ampiezza');

grid on;



%% =========================================================
% 4. ALGORITMO DI PAN-TOMPKINS (VERSIONE SEMPLIFICATA)
% =========================================================

% In questa sezione viene implementata una versione semplificata
% dell'algoritmo di Pan-Tompkins, uno dei metodi più utilizzati
% per il rilevamento automatico dei complessi QRS nei segnali ECG.
%
% L'obiettivo dell'algoritmo è individuare automaticamente i picchi R,
% che rappresentano il punto principale del complesso QRS e permettono
% successivamente di determinare la distanza tra battiti consecutivi.
%
% L'algoritmo originale comprende diverse fasi:
% filtraggio, derivazione, elevamento al quadrato, integrazione mediante
% finestra mobile e rilevamento dei picchi.
%
% Nel presente progetto viene implementata una versione semplificata
% mantenendo le principali caratteristiche del metodo.


%% =========================================================
% 4.1 DERIVAZIONE DEL SEGNALE
% =========================================================

% La prima fase dell'algoritmo consiste nel calcolo della derivata
% del segnale ECG filtrato.
%
% La derivata permette di evidenziare le variazioni rapide di ampiezza
% associate al complesso QRS, rendendo più semplice l'identificazione
% dei battiti cardiaci.
%
% Le componenti caratterizzate da variazioni lente vengono invece
% attenuate.

der = diff(ecg_filt);


% Poiché la funzione diff riduce di un elemento la lunghezza del vettore,
% viene aggiunto un valore nullo finale per riportare il segnale alla
% stessa dimensione dell'ECG originale.

der = [der 0];



%% =========================================================
% 4.2 ELEVAZIONE AL QUADRATO
% =========================================================

% Il segnale derivato viene elevato al quadrato.
%
% Questa operazione rende tutti i valori positivi e amplifica le variazioni
% di maggiore ampiezza, caratteristiche tipiche dei complessi QRS.
%
% In questo modo i picchi associati all'attività ventricolare risultano
% maggiormente distinguibili rispetto alle altre componenti del segnale.

sq = der.^2;



%% =========================================================
% 4.3 MOVING WINDOW INTEGRATION (MWI)
% =========================================================

% L'ultima fase della preparazione del segnale consiste nell'integrazione
% mediante una finestra mobile.
%
% Questa operazione permette di calcolare l'energia del segnale all'interno
% di un intervallo temporale definito e di ottenere un andamento più
% regolare, utile per il successivo rilevamento dei picchi.
%
% La finestra utilizzata ha una durata di circa 150 ms, valore comunemente
% adottato negli algoritmi di rilevamento QRS.

win = round(0.15*Fs);

mwi = movmean(sq,win);



% Visualizzazione del segnale dopo l'elaborazione Pan-Tompkins.

figure;

plot(t,mwi);

title('Segnale elaborato mediante Moving Window Integration');

xlabel('Tempo (s)');

ylabel('Energia');

grid on;



%% =========================================================
% 5. RILEVAMENTO DEI COMPLESSI QRS
% =========================================================

% Dopo la fase di elaborazione viene effettuata l'individuazione dei
% possibili complessi QRS tramite il rilevamento dei picchi.
%
% La funzione findpeaks analizza il segnale integrato e identifica i punti
% caratterizzati da un valore superiore alla soglia impostata.
%
% Ogni picco individuato rappresenta una possibile posizione del complesso
% QRS.


% La soglia viene definita come una percentuale del valore massimo
% del segnale integrato.
%
% Questa scelta permette di adattare automaticamente il rilevamento
% all'ampiezza del segnale analizzato.

threshold = 0.5*max(mwi);


[peaks,locs] = findpeaks(mwi,...
    'MinPeakHeight',threshold,...
    'MinPeakDistance',round(0.25*Fs));


% Il parametro MinPeakHeight elimina i picchi di ampiezza troppo ridotta,
% evitando il rilevamento di variazioni non associate a battiti reali.
%
% Il parametro MinPeakDistance impone una distanza minima tra due picchi
% consecutivi, evitando che lo stesso complesso QRS venga identificato
% più volte.


hold on;

plot(t(locs),peaks,'ro');



%% =========================================================
% 6. CALCOLO DELLA FREQUENZA CARDIACA
% =========================================================

% Una volta individuati i complessi QRS è possibile calcolare gli
% intervalli RR, ovvero il tempo trascorso tra due battiti consecutivi.
%
% L'analisi degli intervalli RR permette di stimare la frequenza cardiaca
% del paziente e valutare la regolarità del ritmo.


RR_intervals = diff(locs)/Fs;


% Gli intervalli RR vengono convertiti in battiti al minuto (bpm)
% attraverso la relazione:
%
% Frequenza cardiaca = 60 / intervallo RR.


heart_rate = 60./RR_intervals;


% Calcolo della frequenza cardiaca media relativa alla registrazione
% analizzata.

fprintf('\nFrequenza cardiaca media: %.2f bpm\n',mean(heart_rate));



%% =========================================================
% 7. CLASSIFICAZIONE SEMPLIFICATA DEL RITMO CARDIACO
% =========================================================

% In questa fase viene effettuata una classificazione molto semplice
% basata esclusivamente sul valore medio della frequenza cardiaca.
%
% Questa classificazione non rappresenta una diagnosi clinica, ma una
% categorizzazione automatica del ritmo ottenuta attraverso un parametro
% numerico estratto dal segnale ECG.


% Se la frequenza cardiaca media supera 100 bpm il ritmo viene classificato
% come tachicardico.

if mean(heart_rate)>100

    label="TACHICARDIA";


% Se la frequenza cardiaca media è inferiore a 60 bpm viene classificato
% come bradicardico.

elseif mean(heart_rate)<60

    label="BRADICARDIA";


% Nei restanti casi viene considerato un ritmo nella fascia normale.

else

    label="NORMALE";

end


fprintf('Diagnosi automatica: %s\n',label);


%% =========================================================
% 8. INDIVIDUAZIONE DEI PICCHI R E VISUALIZZAZIONE DEI RISULTATI
% =========================================================

% In questa fase viene effettuata una ricerca più precisa della posizione
% dei picchi R all'interno del segnale ECG filtrato.
%
% I punti individuati precedentemente dall'algoritmo Pan-Tompkins
% rappresentano infatti delle regioni candidate alla presenza di un
% complesso QRS.
%
% Per ottenere una localizzazione temporale più accurata viene ricercato
% il massimo del segnale ECG filtrato all'interno di una piccola finestra
% temporale attorno ad ogni posizione rilevata.


figure;


% Inizializzazione del vettore che conterrà le posizioni definitive
% dei picchi R.

qrs_locs = zeros(size(locs));


for k = 1:length(locs)


    % Viene definita una finestra di ricerca di circa 50 ms prima e dopo
    % ogni posizione individuata dall'algoritmo.
    %
    % Questa operazione permette di correggere eventuali piccoli errori
    % di localizzazione introdotti dalla fase di integrazione.


    start_idx = max(1,locs(k)-round(0.05*Fs));

    end_idx = min(length(ecg_filt),locs(k)+round(0.05*Fs));


    % All'interno della finestra viene ricercato il valore massimo
    % dell'ECG filtrato, che corrisponde alla posizione più probabile
    % del picco R.

    [~,idx_max] = max(ecg_filt(start_idx:end_idx));


    % Memorizzazione della posizione assoluta del picco R.

    qrs_locs(k) = start_idx + idx_max - 1;

end



% Visualizzazione del segnale ECG filtrato con evidenziazione
% dei punti corrispondenti ai complessi QRS rilevati automaticamente.

plot(t,ecg_filt);

hold on;


plot(t(qrs_locs),ecg_filt(qrs_locs),...
    'ro','MarkerSize',8,'LineWidth',1.5);


title(['ECG filtrato e rilevamento QRS - ',label]);

xlabel('Tempo (s)');

ylabel('Ampiezza ECG');

grid on;



%% =========================================================
% 9. ESTRAZIONE DELLE FEATURE
% =========================================================

% Una volta completata l'analisi del segnale vengono estratte alcune
% informazioni numeriche che possono essere utilizzate come caratteristiche
% (feature) per successive applicazioni di classificazione automatica
% mediante algoritmi di machine learning.
%
% Nel presente progetto viene utilizzata come caratteristica principale
% la frequenza cardiaca media ottenuta dagli intervalli RR.


features = mean(heart_rate);


disp(' ');

disp('Feature estratta (Heart Rate medio):');

disp(features);


disp('=== FINE PROGETTO ECG ===');



%% =========================================================
% 10. DASHBOARD RIASSUNTIVA DELL'ANALISI ECG
% =========================================================

% In questa sezione viene creata una dashboard grafica contenente
% i principali risultati ottenuti durante l'elaborazione.
%
% Lo scopo della dashboard è raccogliere in un'unica finestra tutte
% le informazioni più importanti:
%
% - segnale ECG originale;
% - segnale ECG filtrato;
% - individuazione dei complessi QRS;
% - andamento degli intervalli RR;
% - frequenza cardiaca istantanea;
% - classificazione automatica del ritmo.


figure('Name','Dashboard ECG',...
       'NumberTitle','off',...
       'Position',[100 100 1400 800]);


% Creazione di una griglia grafica organizzata in più sezioni.

tiledlayout(3,3,"Padding","compact");



%% ECG GREZZO

% Visualizzazione del segnale ECG originale acquisito dal database.
%
% Questo grafico permette di osservare il tracciato prima delle
% elaborazioni digitali.


nexttile;

plot(t,ecg);

title('ECG Grezzo');

xlabel('Tempo (s)');

ylabel('Ampiezza');

grid on;



%% ECG FILTRATO E RILEVAMENTO QRS

% Visualizzazione del segnale dopo il filtraggio digitale.
%
% I punti rossi indicano le posizioni dei picchi R individuati
% automaticamente dall'algoritmo di rilevamento QRS.


nexttile([1 2]);


plot(t,ecg_filt,'b');

hold on;


plot(t(qrs_locs),ecg_filt(qrs_locs),...
    'ro','MarkerFaceColor','r');


title(['ECG Filtrato - ',char(label)]);

xlabel('Tempo (s)');

ylabel('Ampiezza');


legend('ECG filtrato','Picchi R');

grid on;



%% SEGNALE PAN-TOMPKINS

% Visualizzazione del segnale ottenuto dopo le operazioni di derivazione,
% elevamento al quadrato e integrazione mediante finestra mobile.
%
% La soglia utilizzata per il rilevamento dei picchi viene mostrata
% per evidenziare il criterio utilizzato dall'algoritmo.


nexttile;


plot(t,mwi,'k');

hold on;


yline(threshold,'r--','Soglia');


title('MWI + Soglia');


xlabel('Tempo (s)');

ylabel('Energia');


grid on;



%% INTERVALLI RR

% Gli intervalli RR rappresentano la distanza temporale tra due battiti
% consecutivi.
%
% La loro analisi permette di valutare la regolarità del ritmo cardiaco
% durante la registrazione.


nexttile;


bar(RR_intervals);


title('Intervalli RR');


xlabel('Battito');

ylabel('Tempo (s)');


grid on;



%% FREQUENZA CARDIACA ISTANTANEA

% Visualizzazione della frequenza cardiaca calcolata per ogni intervallo RR.
%
% Questo grafico permette di osservare eventuali variazioni della
% frequenza cardiaca durante la registrazione.


nexttile;


plot(heart_rate,'LineWidth',1.5);


title('Heart Rate Istantanea');


xlabel('Intervallo RR');

ylabel('Frequenza Cardiaca (bpm)');


grid on;



%% PANNELLO RIASSUNTIVO DEI RISULTATI

% Questa sezione mostra in forma testuale i principali parametri
% ottenuti dall'elaborazione automatica.


nexttile;

axis off;


text(0,0.9,...
    ['Classificazione: ',char(label)],...
    'FontSize',14,...
    'FontWeight','bold');


text(0,0.7,...
    sprintf('HR Media: %.1f bpm',mean(heart_rate)),...
    'FontSize',12);


text(0,0.5,...
    sprintf('Battiti rilevati: %d',length(qrs_locs)),...
    'FontSize',12);


text(0,0.3,...
    sprintf('RR Medio: %.3f s',mean(RR_intervals)),...
    'FontSize',12);


text(0,0.1,...
    sprintf('Durata ECG: %.1f s',t(end)),...
    'FontSize',12);



%% =========================================================
% 11. SALVATAGGIO DEI RISULTATI
% =========================================================

% Tutti i risultati ottenuti durante l'elaborazione vengono raccolti
% all'interno di una struttura MATLAB chiamata "results".
%
% Questa struttura permette di conservare sia i parametri estratti
% dall'ECG sia le informazioni relative alla provenienza del segnale,
% rendendo possibile una successiva analisi o utilizzo dei dati.


results.HeartRate = heart_rate;

results.RR = RR_intervals;

results.QRS = qrs_locs;

results.Label = label;

results.Feature = features;


% Salvataggio del segnale ECG originale e della frequenza
% di campionamento utilizzata.

results.ECG = ecg;

results.Fs = Fs;


% Memorizzazione delle informazioni relative al database utilizzato.

results.Database = "MIT-BIH Arrhythmia Database";

results.Source = "PhysioNet";

results.Record = "100";


% Registrazione della data e dell'orario dell'elaborazione.

results.Timestamp = datetime('now');


% Creazione del file contenente tutti i risultati.

save('ECG_Results.mat','results');


disp('Risultati salvati correttamente nel file ECG_Results.mat');
