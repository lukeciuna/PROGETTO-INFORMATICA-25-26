%% =========================================================
% 1. PARAMETRI DI ACQUISIZIONE DEL SEGNALE
% =========================================================
% In questa sezione vengono definiti i parametri fondamentali per
% l'acquisizione del segnale ECG simulato, tra cui la frequenza di
% campionamento e la durata della registrazione.

% Fs (Sampling Frequency) = Frequenza di campionamento del segnale ECG.
% Il valore di 360 Hz è comunemente utilizzato in database ECG di
% riferimento, come quelli disponibili su PhysioNet.
% Tale valore garantisce che il segnale viene campionato 360 volte al secondo,
% consentendo una rappresentazione temporale accurata delle sue variazioni.
Fs = 360;

% Vettore temporale relativo a una registrazione della durata di 10 secondi.

t = 0:1/Fs:10;
% Tale vettore permette di associare ogni campione del segnale
% al relativo istante di acquisizione. Ciò consente di effettuare
% analisi temporali del tracciato ECG, quali l'identificazione dei
% battiti cardiaci, la valutazione della loro durata e lo studio della
% periodicità del ritmo cardiaco nel tempo.

%% =========================================================
% 2. GENERAZIONE DEL SEGNALE ECG SIMULATO
% =========================================================
% In assenza di dati provenienti da database clinici reali, viene
% generato un segnale ECG sintetico con caratteristiche semplificate ma
% sufficienti per la validazione preliminare dell'algoritmo.

% Componente sinusoidale di base che simula l'attività cardiaca periodica.
ecg_clean = sin(2*pi*1.3*t) + 0.5*sin(2*pi*2.6*t);
%La frequenza fondamentale (1.3 Hz) rappresenta il ritmo cardiaco
% simulato, mentre la seconda armonica contribuisce ad arricchire la
% morfologia del segnale.
%La sovrapposizione di più componenti
% sinusoidali consente infatti di ottenere una rappresentazione più
% realistica rispetto a una singola sinusoide.

%% Generazione artificiale dei complessi QRS
% I complessi QRS rappresentano la depolarizzazione ventricolare e
% costituiscono la componente più evidente dell'ECG.
% Vengono simulati introducendo picchi di ampiezza elevata in posizioni
% periodiche lungo il segnale.

for i = 1:200:length(t)  % Simulazione di un battito cardiaco ogni 200 campioni del segnale


    % Verifica necessaria per evitare errori.
    if i+5 < length(ecg_clean)

        % Incremento locale dell'ampiezza del segnale per simulare
        % un complesso QRS stretto e facilmente rilevabile.
        ecg_clean(i:i+5) = ecg_clean(i:i+5) + 2;

        % L'estensione di 6 campioni consente di ottenere un picco
        % sufficientemente stretto senza risultare eccessivamente
        % artificiale dal punto di vista morfologico.
    end
end

%% Introduzione di rumore fisiologico

% Per rendere il segnale più realistico vengono aggiunte due tipologie
% di disturbo comunemente presenti negli ECG reali:
% - rumore gaussiano ad alta frequenza;
% - deriva della linea di base (baseline wander) a bassa frequenza.


noise = 0.3*randn(size(t)) + 0.2*sin(2*pi*0.2*t);

% randn è una funzione che genera valori casuali con distribuzione
% gaussiana.

% La componente 0.3*randn(size(t)) simula il rumore ad alta frequenza
% tipicamente presente durante l'acquisizione del segnale ECG.

% Tale rumore può essere associato a interferenze elettroniche,
% artefatti degli elettrodi e rumore strumentale.

% La componente 0.2*sin(2*pi*0.2*t) rappresenta una sinusoide a bassa
% frequenza pari a 0.2 Hz.

% Questa componente simula la deriva della linea di base (baseline
% wander), fenomeno generalmente causato dalla respirazione e dai
% movimenti del paziente.

% La combinazione delle due componenti consente di ottenere un segnale
% maggiormente rappresentativo delle condizioni di acquisizione reali.

% Segnale ECG finale ottenuto dalla somma del segnale ideale e delle
% componenti di rumore.
ecg = ecg_clean + noise;

% ecg_clean rappresenta il segnale ECG ideale privo di disturbi.


%% =========================================================
% VISUALIZZAZIONE DEL SEGNALE ECG GREZZO
% =========================================================

figure; % Creazione di una nuova finestra grafica per la visualizzazione del segnale.

plot(t, ecg); % Rappresentazione del segnale ECG nel dominio del tempo.

% L'asse delle ascisse (X) rappresenta il tempo espresso in secondi.

% L'asse delle ordinate (Y) rappresenta l'ampiezza del segnale ECG.

title('ECG grezzo (con rumore)'); % Titolo del grafico che identifica il
% segnale prima delle operazioni di filtraggio.

xlabel('Tempo (s)');
ylabel('Ampiezza');

grid on; % Attivazione della griglia per facilitare la lettura del grafico
% e l'analisi visiva delle principali caratteristiche del segnale.


%% =========================================================
% 3. FILTRAGGIO DEL SEGNALE ECG
% =========================================================
% Viene applicato un filtro passa-banda compreso tra 5 Hz e 15 Hz,
% intervallo che contiene gran parte dell'energia associata ai complessi
% QRS. Tale operazione consente di attenuare il rumore ad alta frequenza
% e la deriva della linea di base.

[b,a] = butter(4, [5 15]/(Fs/2), 'bandpass');

% Il parametro "4" rappresenta l'ordine del filtro e determina la
% pendenza della risposta in frequenza, ovvero la rapidità con cui
% vengono attenuate le componenti al di fuori della banda selezionata.

% In generale, un ordine più elevato corrisponde a una maggiore
% selettività del filtro.

% filtfilt = filtraggio bidirezionale (forward e backward)
ecg_filt = filtfilt(b, a, ecg);

% L'applicazione della funzione filtfilt comporta l'esecuzione del
% filtro sia in avanti sia all'indietro lungo il segnale.

% Questa procedura elimina lo sfasamento temporale introdotto dal filtro
% e consente di preservare la corretta localizzazione temporale dei
% complessi QRS.

%% Confronto tra segnale originale e segnale filtrato
figure;

plot(t, ecg, 'b'); hold on;
plot(t, ecg_filt, 'r');

legend('Segnale originale','Segnale filtrato');
title('Confronto tra ECG originale e filtrato');
xlabel('Tempo (s)');
ylabel('Ampiezza');
grid on;

%% =========================================================
% 4. ALGORITMO DI PAN-TOMPKINS (VERSIONE SEMPLIFICATA)
% =========================================================
% L'algoritmo Pan-Tompkins è uno dei metodi più utilizzati per il
% rilevamento automatico dei complessi QRS. In questa implementazione
% viene proposta una versione semplificata delle sue principali fasi.

%% 4.1 Derivazione del segnale
% La derivata enfatizza le variazioni rapide di ampiezza tipiche dei
% complessi QRS e riduce l'influenza delle componenti più lente.

der = diff(ecg_filt);

% Ripristino della lunghezza originale del vettore.
der = [der 0];

%% 4.2 Elevamento al quadrato
% Tutti i valori diventano positivi e le variazioni di maggiore entità
% vengono amplificate, facilitando l'identificazione dei QRS.

sq = der.^2;

%% 4.3 Moving Window Integration (MWI)
% Calcolo dell'energia media del segnale all'interno di una finestra
% temporale di 150 ms, come previsto dall'approccio Pan-Tompkins.

win = round(0.15 * Fs);
mwi = movmean(sq, win);

%% Visualizzazione del segnale elaborato
figure;
plot(t, mwi);

title('Segnale elaborato mediante MWI');
xlabel('Tempo (s)');
ylabel('Energia');
grid on;

%% =========================================================
% 5. RILEVAMENTO DEI COMPLESSI QRS
% =========================================================
% L'identificazione dei picchi R viene effettuata mediante la funzione
% findpeaks applicata al segnale ottenuto dopo la fase di integrazione.

% Definizione di una soglia adattativa pari al 50% del valore massimo.
threshold = 0.5 * max(mwi);

[peaks, locs] = findpeaks(mwi, ...
    'MinPeakHeight', threshold, ...
    'MinPeakDistance', round(0.25*Fs));

% MinPeakHeight:
% esclude i picchi di ampiezza inferiore alla soglia.

% MinPeakDistance:
% impone una distanza minima tra due rilevazioni consecutive,
% evitando il conteggio multiplo dello stesso battito cardiaco.

% Visualizzazione delle posizioni dei picchi rilevati.
hold on;
plot(t(locs), peaks, 'ro');

%% =========================================================
% 6. CALCOLO DELLA FREQUENZA CARDIACA
% =========================================================
% La frequenza cardiaca viene stimata a partire dagli intervalli RR,
% ovvero dalle distanze temporali tra due picchi R consecutivi.

RR_intervals = diff(locs) / Fs;

% Conversione degli intervalli RR in battiti per minuto (bpm).
heart_rate = 60 ./ RR_intervals;

% Calcolo della frequenza cardiaca media.
fprintf('\nFrequenza cardiaca media: %.2f bpm\n', mean(heart_rate));

%% =========================================================
% 7. CLASSIFICAZIONE SEMPLIFICATA DEL RITMO CARDIACO
% =========================================================
% Classificazione basata sui valori medi della frequenza cardiaca:
% - Tachicardia: HR > 100 bpm
% - Bradicardia: HR < 60 bpm
% - Ritmo normale: 60 bpm <= HR <= 100 bpm

if mean(heart_rate) > 100
    label = "TACHICARDIA";
elseif mean(heart_rate) < 60
    label = "BRADICARDIA";
else
    label = "NORMALE";
end

fprintf('Diagnosi automatica: %s\n', label);

%% =========================================================
% 8. VISUALIZZAZIONE DEI RISULTATI
% =========================================================
% Rappresentazione del segnale filtrato con evidenziazione delle
% posizioni dei complessi QRS rilevati automaticamente.

figure;

% In questa fase vengono individuati i punti di massima ampiezza del
% segnale ECG filtrato in corrispondenza delle regioni precedentemente
% identificate come complessi QRS.

qrs_locs = zeros(size(locs));

for k = 1:length(locs)

    % Definizione della finestra di ricerca attorno al complesso QRS.
    start_idx = max(1, locs(k)-round(0.05*Fs));
    end_idx   = min(length(ecg_filt), locs(k)+round(0.05*Fs));

    % Ricerca del massimo locale del segnale filtrato.
    [~, idx_max] = max(ecg_filt(start_idx:end_idx));

    % Memorizzazione della posizione del picco individuato.
    qrs_locs(k) = start_idx + idx_max - 1;

end

% Visualizzazione del segnale ECG filtrato.
plot(t, ecg_filt);
hold on;

% Evidenziazione dei picchi R rilevati.
plot(t(qrs_locs), ecg_filt(qrs_locs), 'ro', 'MarkerSize',8, 'LineWidth',1.5);

title(['ECG filtrato e rilevamento QRS - ', label]);
xlabel('Tempo (s)');
ylabel('Ampiezza ECG');
grid on;

%% =========================================================
% 9. ESTRAZIONE DELLE FEATURE
% =========================================================
% In questa fase il segnale viene trasformato in una caratteristica
% numerica utilizzabile da futuri algoritmi di machine learning per
% compiti di classificazione o riconoscimento di patologie.

% La feature selezionata è la frequenza cardiaca media.
features = mean(heart_rate);

disp(' ');
disp('Feature estratta (Heart Rate medio):');
disp(features);

disp('=== FINE PROGETTO ECG ===');
