UN PROGETTO A CURA DI SCOPELLITI GIORGIA E CIUNA LUCA 

Il progetto ha l’obiettivo di realizzare un’analisi automatica di un segnale elettrocardiografico 
reale, attraverso una sequenza di elaborazioni finalizzate all’individuazione dei complessi QRS, alla 
localizzazione dei picchi R e alla successiva valutazione della frequenza cardiaca. 
In 
particolare, 
il complesso 
QRS rappresenta 
una 
delle 
principali 
componenti 
dell’elettrocardiogramma e corrisponde alla depolarizzazione dei ventricoli, cioè al fenomeno 
elettrico che precede la contrazione ventricolare. All’interno del complesso QRS è presente il picco 
R, generalmente caratterizzato dalla maggiore ampiezza, che rappresenta un punto di riferimento 
particolarmente utile per identificare con precisione il singolo battito cardiaco. 
Una volta individuata la posizione dei picchi R consecutivi, è possibile calcolare gli intervalli RR, 
ovvero gli intervalli di tempo che separano un picco R dal successivo. Gli intervalli RR sono 
fondamentali per l’analisi del ritmo cardiaco, poiché permettono di determinare la frequenza 
cardiaca attraverso la relazione tra il tempo che intercorre tra due battiti consecutivi e il numero di 
battiti al minuto. A partire dagli intervalli RR viene quindi calcolata la frequenza cardiaca 
istantanea e successivamente la frequenza cardiaca media della registrazione. 
Quest’ultima viene utilizzata nel progetto per effettuare una classificazione semplificata del ritmo 
cardiaco, distinguendo tra bradicardia, ritmo nella norma e tachicardia. 
Un elemento particolarmente significativo del progetto è l’utilizzo di una registrazione ECG reale, 
anziché di un segnale generato artificialmente. Il tracciato analizzato appartiene al MIT-BIH 
Arrhythmia Database, disponibile sulla piattaforma PhysioNet, e corrisponde nello specifico 
al record 100. La scelta di utilizzare un segnale reale permette di rendere l’analisi maggiormente 
rappresentativa di una situazione di acquisizione clinica, poiché il tracciato presenta le 
caratteristiche proprie di una registrazione effettuata su un paziente, comprese le normali 
variazioni dell’attività cardiaca e le eventuali componenti indesiderate introdotte durante 
l’acquisizione.

- Acquisizione e preparazione del segnale -

La prima informazione fondamentale utilizzata nell'elaborazione è la frequenza di campionamento, 
impostata a 360 Hz. Questo significa che il segnale ECG è rappresentato attraverso 360 campioni 
per ogni secondo di registrazione. La frequenza di campionamento è fondamentale perché 
permette di stabilire la corrispondenza tra gli indici dei campioni e il tempo reale. 
Il segnale viene caricato tramite il comando: 

load('100.mat'); 

Successivamente viene trasformato in un vettore riga attraverso: 

ecg = ecg(:)'; 

Questa operazione non modifica il contenuto del segnale, ma ne uniforma semplicemente il 
formato per facilitarne l'elaborazione successiva. 
Viene poi creato l'asse temporale: 

t = (0:length(ecg)-1)/Fs; 

Questa  operazione permette di associare ogni campione del segnale a un preciso istante di 
tempo, espresso in secondi. Questo è necessario perché il segnale ECG è inizialmente 
rappresentato come una sequenza di campioni, mentre per analizzarlo e visualizzarlo 
correttamente è utile sapere a quale momento della registrazione corrisponde ogni campione. 
Per semplificare l’elaborazione, viene scelto di analizzare solamente i primi 60 secondi della 
registrazione. La frequenza di campionamento è di 360 Hz, quindi vengono acquisiti 360 campioni 
ogni secondo. Di conseguenza, in 60 secondi sono presenti: 

60×360=21600 campioni;

Il codice verifica poi che la registrazione contenga effettivamente almeno 21.600 campioni. Se il 
segnale fosse più corto, vengono utilizzati solamente i campioni disponibili, evitando così errori 
durante l’elaborazione. 
A questo punto vengono selezionati i primi 60 secondi del segnale ECG e viene ricreato l’asse 
temporale in modo che continui a essere correttamente associato ai campioni rimasti. 
Quindi questa fase serve a stabilire la corrispondenza tra campioni e tempo e a selezionare una 
porzione di 60 secondi del segnale su cui verranno effettuate tutte le analisi successive.

- Visualizzazione dell'ECG originale -

Prima di effettuare qualsiasi elaborazione, il segnale ECG viene rappresentato graficamente nel 
dominio del tempo. 
Questa fase è importante perché consente di osservare il segnale allo stato originale, cioè prima 
dell'applicazione di filtri o algoritmi di rilevamento. 
Nel grafico l'asse orizzontale rappresenta il tempo in secondi, mentre quello verticale rappresenta 
l'ampiezza del segnale ECG. 
Questa prima visualizzazione costituisce quindi il riferimento rispetto al quale è possibile valutare 
successivamente l'effetto delle operazioni di filtraggio.

- Filtraggio del segnale -

Una volta acquisito il segnale ECG, è necessario effettuare una fase di filtraggio, poiché una 
registrazione reale può contenere, oltre all’attività elettrica del cuore, anche diverse componenti 
indesiderate. Queste possono essere dovute, ad esempio, al movimento del paziente, al rumore 
degli strumenti di acquisizione o ad altre interferenze. La presenza di queste componenti può 
rendere più difficile l’individuazione dei battiti cardiaci. 
Per migliorare la qualità del segnale viene quindi utilizzato un filtro Butterworth passa-banda di 
quarto ordine, con frequenze di taglio comprese tra 5 Hz e 15 Hz:

[b,a] = butter(4,[5 15]/(Fs/2),'bandpass');

Il termine passa-banda indica che il filtro permette di mantenere principalmente le componenti 
del segnale comprese tra 5 e 15 Hz, mentre attenua quelle che si trovano al di sotto dei 5 Hz e al di 
sopra dei 15 Hz. 
La scelta di questa banda è legata all'obiettivo principale dell'elaborazione, ovvero facilitare 
l'individuazione dei complessi QRS.. Mettendo in evidenza queste componenti, il successivo 
algoritmo di rilevamento dei battiti può lavorare su un segnale più pulito e più facilmente 
analizzabile. 

Il filtro utilizzato è un filtro Butterworth di quarto ordine, scelto per la sua capacità di ottenere 
una risposta in frequenza regolare e priva di ondulazioni nella banda passante. In altre parole, 
all’interno della banda di frequenze che si desidera conservare, il filtro non presenta variazioni 
brusche dell’ampiezza del segnale, permettendo di mantenere in maniera uniforme le componenti 
considerate di interesse. 
La scelta del quarto ordine determina la rapidità con cui il filtro attenua le frequenze che si trovano 
al di fuori della banda di interesse. Un ordine maggiore permette generalmente di ottenere una 
transizione più selettiva tra le frequenze mantenute e quelle attenuate, a fronte però di una 
maggiore complessità del filtro. 
Nel contesto dell'ECG, questa caratteristica è particolarmente utile perché permette di ridurre le 
componenti del segnale che possono ostacolare il rilevamento dei battiti, concentrando 
l'attenzione sulle variazioni più rapide associate ai complessi QRS. 

Dopo la definizione del filtro viene utilizzata la funzione: 

ecg_filt = filtfilt(b,a,ecg); 

In questo caso viene utilizzata la funzione filtfilt, che applica il filtraggio prima in una 
direzione e successivamente nella direzione opposta. Il principale vantaggio di questa procedura è 
che permette di evitare lo sfasamento temporale che potrebbe essere introdotto da un normale 
filtraggio. 
Questo aspetto è particolarmente importante nel nostro caso, perché una delle fasi successive 
consiste nell'individuare con precisione la posizione dei picchi R. Se il filtraggio modificasse la 
posizione temporale dei picchi, anche il calcolo degli intervalli RR e, di conseguenza, della 
frequenza cardiaca potrebbe risultare alterato. 
Infine, viene effettuato un confronto grafico tra il segnale ECG originale e quello filtrato. Questo 
permette di osservare direttamente l'effetto del filtraggio: il segnale filtrato presenta una riduzione 
delle componenti indesiderate, mantenendo però le caratteristiche principali dell'ECG necessarie 
per il successivo rilevamento dei complessi QRS e dei picchi R.

- Rilevamento dei complessi QRS: versione semplificata del Pan-Tompkins -

La fase centrale del progetto consiste nel rilevamento automatico dei complessi QRS. 
Il complesso QRS rappresenta la depolarizzazione ventricolare ed è caratterizzato da variazioni 
relativamente rapide del segnale ECG. Individuare correttamente questi complessi è fondamentale 
perché permette successivamente di determinare la posizione dei battiti e calcolare gli intervalli 
RR. 

Nel progetto viene implementata una versione semplificata dell'algoritmo di Pan-Tompkins. 
La logica generale è: 
ECG filtrato → derivata → elevamento al quadrato → integrazione con finestra mobile → 
rilevamento dei picchi.

- Derivazione -

La prima operazione è il calcolo della derivata: 

der = diff(ecg_filt); 

La derivata permette di descrivere quanto rapidamente varia il segnale nel tempo. Questo 
passaggio è particolarmente importante perché il complesso QRS, associato alla depolarizzazione 
dei ventricoli, presenta variazioni di ampiezza relativamente rapide e accentuate rispetto ad altre 
componenti dell’elettrocardiogramma. 
Di conseguenza, applicando la derivata, le zone del segnale caratterizzate da variazioni rapide, 
come quelle corrispondenti ai complessi QRS, vengono messe maggiormente in evidenza. Al 
contrario, le componenti che variano lentamente nel tempo risultano meno rilevanti nel segnale 
derivato. In questo modo si facilita il successivo rilevamento automatico dei battiti cardiaci. 

Dal punto di vista matematico, la derivata rappresenta la variazione del segnale rispetto al tempo. 
Nel codice, questa operazione viene approssimata attraverso la funzione diff, che calcola la 
differenza tra due campioni consecutivi: 

der(n)=ECG(n+1)−ECG(n); 

In questo modo è possibile individuare i punti in cui l'ECG presenta variazioni più marcate. 
Un aspetto tecnico da considerare è che la funzione diff restituisce un vettore con un campione 
in meno rispetto al segnale originale. Se, ad esempio, il segnale ECG contiene 1000 campioni, dopo 
l'applicazione di diff il risultato ne contiene 999. 
Per mantenere la stessa lunghezza del segnale originale e poter quindi continuare a confrontare 
correttamente i diversi segnali campione per campione, viene aggiunto un valore nullo alla fine: 
Questa operazione non modifica in maniera significativa il contenuto del segnale derivato, ma 
permette di mantenere la stessa dimensione dell’ECG originale, facilitando le elaborazioni 
successive.

der = [der 0]; 

- Elevamento al quadrato -

Successivamente il segnale derivato viene elevato al quadrato: 

sq = der.^2; 

Questa operazione ha due effetti principali. 
Il primo è rendere tutti i valori positivi. Non interessa infatti distinguere, in questa fase, se una 
variazione è positiva o negativa. 
Il secondo è amplificare maggiormente le variazioni di ampiezza elevata. 
Ad esempio, una variazione di ampiezza 2 diventa 4, mentre una variazione di ampiezza 5 diventa 
25. Di conseguenza, le variazioni rapide e più significative associate ai complessi QRS vengono 
ulteriormente evidenziate.

- Moving Window Integration -

La fase successiva dell’elaborazione consiste nell’applicazione della Moving Window Integration 
(MWI), cioè un’operazione di integrazione effettuata utilizzando una finestra temporale mobile. 
Questa fase ha lo scopo di rendere il segnale ottenuto dall’elevamento al quadrato più regolare e di 
mettere ulteriormente in evidenza le regioni dell’ECG associate ai complessi QRS.

Nel codice viene innanzitutto definita la durata della finestra: 

win = round(0.15*Fs);

La finestra scelta ha una durata di circa 150 ms, cioè 0,15 secondi. Considerando che il segnale è 
campionato a 360 Hz, il numero di campioni contenuti in questa finestra è: 

0,15×360=54 campioni 

Pertanto, l’algoritmo considera circa 54 campioni alla volta. 
Successivamente viene applicata la media mobile attraverso: 

mwi = movmean(sq,win); 

La funzione movmean calcola, per ogni punto del segnale, la media dei campioni contenuti nella 
finestra mobile. La finestra viene quindi fatta scorrere progressivamente lungo tutto il segnale: a 
ogni posizione viene calcolato un nuovo valore medio considerando i campioni presenti nella 
finestra. 
L'operazione viene effettuata sul segnale sq, cioè sul segnale precedentemente ottenuto 
tramite elevamento al quadrato della derivata. Poiché l’elevamento al quadrato rende tutti i valori 
positivi e amplifica le variazioni di maggiore ampiezza, la media mobile permette di ottenere una 
rappresentazione più stabile della quantità di energia presente nel segnale in un determinato 
intervallo temporale. 
Questa fase è particolarmente utile per il rilevamento dei complessi QRS. Infatti, quando la finestra 
mobile attraversa una regione contenente un QRS, caratterizzata da variazioni rapide e di maggiore 
ampiezza, il valore medio del segnale tende ad aumentare. Al contrario, nelle regioni in cui il 
segnale presenta variazioni più contenute, il valore della media mobile rimane generalmente più 
basso. 
Di conseguenza, la Moving Window Integration trasforma il segnale in una forma più regolare e 
rende più facilmente distinguibili le regioni corrispondenti ai complessi QRS. Il segnale ottenuto, 
indicato nel codice con mwi, sarà quindi utilizzato nella fase successiva per individuare 
automaticamente i possibili battiti attraverso la ricerca dei picchi.

- Rilevamento dei picchi R -

Una volta ottenuto il segnale attraverso la Moving Window Integration, è necessario individuare i 
picchi che possono essere associati ai complessi QRS. Questa fase è fondamentale perché 
permette di identificare automaticamente le diverse occorrenze dei battiti cardiaci all’interno della 
registrazione. 

Per effettuare il rilevamento viene innanzitutto definita una soglia di ampiezza, calcolata come il 
50% del valore massimo del segnale integrato: 

threshold = 0.5*max(mwi);

In questo modo la soglia non viene fissata a un valore assoluto, ma viene determinata in funzione 
dell’ampiezza del segnale analizzato. Questo rende il criterio di rilevamento adattabile al segnale 
considerato: se l’ampiezza del segnale aumenta o diminuisce, anche la soglia viene modificata 
proporzionalmente. 
Successivamente viene utilizzata la funzione findpeaks, che permette di individuare 
automaticamente i massimi locali presenti nel segnale:

[peaks,locs] = findpeaks(mwi,... 
'MinPeakHeight',threshold,... 
'MinPeakDistance',round(0.25*Fs)); 

In questa istruzione vengono utilizzati principalmente due criteri per stabilire quali picchi devono 
essere considerati significativi. 
Il primo è MinPeakHeight, che stabilisce l’altezza minima che un picco deve raggiungere per 
essere preso in considerazione. Nel nostro caso, il picco deve superare la soglia precedentemente 
definita, pari al 50% del valore massimo del segnale MWI. Questo permette di eliminare i picchi di 
ampiezza troppo bassa, che potrebbero essere dovuti a variazioni del segnale non associate a un 
vero complesso QRS. 
Il secondo criterio è MinPeakDistance, che impone una distanza minima tra due picchi 
consecutivi. Nel codice viene impostato un valore pari a: 

0,25×360=90 campioni;

Poiché la frequenza di campionamento è di 360 Hz, 90 campioni corrispondono a: 

36090 =0,25 s=250 ms;

Questo significa che due picchi non possono essere considerati distinti se si trovano a meno di 250 
ms l’uno dall’altro. Tale vincolo è utile per evitare che lo stesso complesso QRS venga rilevato più 
volte a causa della sua forma o delle oscillazioni presenti nel segnale. 
La funzione findpeaks restituisce due informazioni principali: peaks, che contiene i valori di 
ampiezza dei picchi individuati, e locs, che contiene le posizioni, espresse come indici dei 
campioni, dei picchi rilevati. 
È importante precisare che, in questa fase, le posizioni contenute in locs devono essere 
considerate come posizioni candidate dei complessi QRS. Infatti, il segnale analizzato è quello 
ottenuto dalla Moving Window Integration e non direttamente l’ECG filtrato. Di conseguenza, la 
posizione individuata potrebbe non coincidere esattamente con quella del picco R nel segnale ECG 
originale.

Per questo motivo, nella fase successiva del progetto, il codice utilizza queste posizioni come 
riferimento e ricerca, all’interno di una piccola finestra temporale, il massimo del segnale ECG 
filtrato. In questo modo è possibile ottenere una localizzazione più precisa dei picchi R.

- Calcolo degli intervalli RR -

Dopo aver identificato le posizioni dei battiti, è possibile calcolare gli intervalli RR: 

RR_intervals = diff(locs)/Fs; 

L'intervallo RR rappresenta il tempo che intercorre tra due battiti consecutivi. 
La funzione diff calcola la differenza tra le posizioni successive dei picchi. Poiché queste posizioni 
sono espresse in numero di campioni, la divisione per Fs permette di trasformarle in secondi. 
Ad esempio, se due battiti sono separati da 360 campioni:

RR=360360 =1s 

L'intervallo RR è quindi di un secondo. L'analisi degli intervalli RR è molto importante perché costituisce il collegamento tra il rilevamento 
dei battiti e il calcolo della frequenza cardiaca.

- Calcolo della frequenza cardiaca -

Una volta individuati i complessi QRS e, in particolare, le posizioni dei battiti consecutivi, è 
possibile calcolare gli intervalli RR, cioè gli intervalli di tempo che intercorrono tra un picco R e il 
successivo. Questi intervalli costituiscono la base per determinare la frequenza cardiaca. 
Nel codice gli intervalli RR vengono utilizzati per calcolare la frequenza cardiaca attraverso la 
relazione: 

heart_rate = 60./RR_intervals; 

La formula utilizzata è: 

HR=RR60;

dove RR è espresso in secondi, mentre HR rappresenta la frequenza cardiaca in battiti al minuto 
(bpm). Il valore 60 deriva dal fatto che un minuto è costituito da 60 secondi. 
Ad esempio, se tra due battiti consecutivi trascorre 1 secondo, significa che viene registrato un 
battito ogni secondo. Di conseguenza: 

HR=160 =60 bpm;

Se invece l’intervallo RR è pari a 0,75 secondi, i battiti sono più ravvicinati nel tempo e quindi la 
frequenza cardiaca aumenta: 

HR=0,7560 =80 bpm;

Questo permette di comprendere la relazione inversa tra intervallo RR e frequenza cardiaca: 
quando l’intervallo tra due battiti diminuisce, significa che il cuore sta battendo più velocemente e 
quindi la frequenza cardiaca aumenta. Al contrario, quando l’intervallo RR aumenta, i battiti sono 
più distanziati e la frequenza cardiaca diminuisce. 
Poiché durante i 60 secondi di registrazione vengono rilevati numerosi intervalli RR, il codice 
calcola successivamente la media della frequenza cardiaca attraverso:

mean(heart_rate);

In questo modo si ottiene un unico valore che rappresenta la frequenza cardiaca media durante la 
porzione di ECG analizzata. 
È importante distinguere la frequenza cardiaca media dalla frequenza cardiaca istantanea: la prima 
rappresenta un valore complessivo relativo all’intera registrazione, mentre la seconda viene 
calcolata per ciascun intervallo RR e permette di osservare le variazioni della frequenza cardiaca 
nel corso del tempo. 
Questa frequenza cardiaca media viene poi utilizzata nella fase successiva del progetto per 
effettuare la classificazione semplificata del ritmo cardiaco in bradicardia, ritmo normale o 
tachicardia.

- Classificazione del ritmo -

La frequenza cardiaca media viene successivamente utilizzata per effettuare una classificazione 
semplificata: 

if mean(heart_rate)>100 

label="TACHICARDIA"; 

elseif mean(heart_rate)<60 

label="BRADICARDIA"; 

else 

label="NORMALE"; 

end 

Il criterio utilizzato è: 

frequenza superiore a 100 bpm → tachicardia; 
frequenza inferiore a 60 bpm → bradicardia; 
frequenza compresa tra 60 e 100 bpm → ritmo classificato come normale.

È fondamentale precisare che questa classificazione è puramente didattica e basata sulla 
frequenza cardiaca media. 
Non deve essere interpretata come una diagnosi clinica. Infatti, una vera classificazione 
cardiologica richiederebbe l'analisi di molte altre caratteristiche del segnale e, soprattutto, una 
valutazione clinica. 
Quindi nel progetto la parola "diagnosi automatica" utilizzata nel fprintf deve essere intesa 
come classificazione automatica semplificata, non come diagnosi medica.

- Localizzazione precisa dei picchi R -

Dopo aver individuato le possibili posizioni dei complessi QRS attraverso la Moving Window 
Integration, il codice esegue un’ulteriore fase di elaborazione con l’obiettivo di determinare in 
modo più preciso la posizione dei picchi R. 
Le posizioni contenute nel vettore locs, infatti, sono state ottenute analizzando il segnale 
elaborato mediante il metodo Pan-Tompkins. Queste posizioni permettono di individuare le regioni 
temporali in cui è presente un possibile complesso QRS, ma non necessariamente coincidono con 
la posizione esatta del picco R sul segnale ECG filtrato. 
Per questo motivo, per ogni posizione individuata, viene definita una piccola finestra di 
ricerca centrata attorno al punto rilevato. In particolare, il codice considera un intervallo di 
circa ±50 ms rispetto alla posizione del candidato QRS:

start_idx = max(1,locs(k)-round(0.05*Fs)); 
end_idx = min(length(ecg_filt),locs(k)+round(0.05*Fs)); 

Poiché la frequenza di campionamento è di 360 Hz, 50 ms corrispondono a circa: 
0,05×360=18 campioni. 

Di conseguenza, per ogni posizione individuata da locs, viene analizzata una finestra che 
comprende circa 18 campioni prima e 18 campioni dopo il punto considerato. 
All’interno di questa finestra viene quindi ricercato il valore massimo del segnale ECG 
filtrato mediante: 

[~,idx_max] = max(ecg_filt(start_idx:end_idx));

L'idea è che, all'interno della regione in cui l'algoritmo ha già individuato un possibile QRS, il valore 
massimo dell'ECG filtrato rappresenti la posizione più probabile del picco R. 
La posizione così determinata viene successivamente convertita nell'indice corrispondente 
all'interno dell'intero segnale e memorizzata nel vettore: 

qrs_locs;

In questo modo il processo di rilevamento avviene in due passaggi distinti: inizialmente l'algoritmo 
individua le regioni candidate alla presenza dei complessi QRS, mentre successivamente viene 
effettuata una ricerca locale per determinare con maggiore precisione la posizione del picco R. 
Questa distinzione è importante perché i picchi R rappresentano i punti di riferimento utilizzati per 
il calcolo degli intervalli RR. Una localizzazione più precisa consente quindi di ottenere una stima 
più accurata del tempo che intercorre tra due battiti consecutivi e, di conseguenza, della frequenza 
cardiaca. 
Infine, i picchi R individuati vengono rappresentati graficamente sul segnale ECG filtrato mediante 
dei marcatori rossi. Questa visualizzazione permette di verificare immediatamente se i punti 
rilevati dall'algoritmo si trovano effettivamente in corrispondenza dei picchi caratteristici dei battiti 
cardiaci.

- Estrazione delle feature -

Una volta terminata l'elaborazione viene estratta una caratteristica numerica, chiamata feature: 

features = mean(heart_rate); 

In questo progetto la feature principale è quindi la frequenza cardiaca media. 
Il concetto di feature è particolarmente importante nel contesto del machine learning, perché un 
segnale complesso come l'ECG può essere trasformato in un insieme di parametri numerici che 
possono essere utilizzati da algoritmi automatici di classificazione. 
Nel progetto viene utilizzata una sola feature, ma un codice più avanzato potrebbe estrarne molte 
altre, relative ad esempio alla variabilità degli intervalli RR, alla morfologia dei complessi QRS o alle 
caratteristiche temporali e spettrali del segnale.

- Dashboard finale -

Il progetto include anche una dashboard riassuntiva. 

Viene utilizzato: 

tiledlayout(3,3), per organizzare diversi grafici nella stessa finestra. 

La dashboard permette di visualizzare in maniera immediata:

il segnale ECG grezzo; 
il segnale ECG filtrato; 
i picchi R rilevati; 
il segnale ottenuto attraverso la Moving Window Integration; 
la soglia di rilevamento; 
gli intervalli RR; 
la frequenza cardiaca istantanea; 
la classificazione finale; 
i principali valori numerici dell'analisi.

In particolare, il grafico degli intervalli RR permette di osservare la distanza temporale tra i battiti, 
mentre il grafico della frequenza cardiaca istantanea permette di osservare come la frequenza 
varia nel corso della registrazione. 
Il pannello riassuntivo riporta invece la classificazione, la frequenza cardiaca media, il numero di 
battiti rilevati, l'intervallo RR medio e la durata dell'ECG analizzato. 

- Salvataggio dei risultati -

Nell'ultima parte del codice tutti i risultati vengono raccolti all'interno della struttura MATLAB results. 

Vengono memorizzati: 
results.HeartRate 
results.RR 
results.QRS 
results.Label 
results.Feature 
results.ECG 
results.Fs 
oltre alle informazioni relative alla sorgente del segnale: 
results.Database 
results.Source 
results.Record
e alla data e all'ora dell'elaborazione:
results.Timestamp 
Infine, la struttura viene salvata nel file: 
save('ECG_Results.mat','results'); 
In questo modo è possibile recuperare successivamente tutti i risultati senza dover ripetere l'intera 
elaborazione.
