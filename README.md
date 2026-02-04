# GLR Assignment Collector

Deze applicatie automatiseert het verzamelen en structureren van ingeleverde opdrachten vanuit Microsoft Teams (OneDrive). De tool scant de *Submitted files* map, filtert op de gekozen opdracht, selecteert automatisch de laatste versie, pakt ZIP-bestanden uit en plaatst alles gestructureerd in je Downloads map.

## ⚠️ Eénmalige Installatie & Rechten

Omdat dit een interne applicatie is (niet ondertekend door Apple), vereist macOS dat je **eenmalig** handmatig toestemming geeft voor schijftoegang. Zonder deze stap zal de Mac bij elke map om toestemming vragen.

1.  Sleep de **GLR Collector.app** naar je map **Applicaties** of je Bureaublad.
2.  Open **Systeeminstellingen** (System Settings).
3.  Ga naar **Privacy en beveiliging** (Privacy & Security) > **Volledige schijftoegang** (Full Disk Access).
4.  Klik op het **+** icoon onderaan de lijst (voer wachtwoord in indien nodig).
5.  Selecteer de **GLR Collector** app en klik op **Open**.
6.  Zorg dat de schakelaar achter de app op **AAN** (blauw) staat.

*De app heeft nu toestemming om bestanden te lezen uit OneDrive en te schrijven naar Downloads.*

---

## Gebruik

Er zijn twee manieren om de applicatie te gebruiken:

### Methode 1: Drag & Drop (Snel)
Gebruik dit als je de map met ingeleverde bestanden al open hebt staan.

1.  Selecteer de map `Submitted files` in Finder (binnen de OneDrive/Teams structuur).
2.  Sleep deze map direct op het icoon van de **GLR Collector**.
3.  De app verwerkt **alle** opdrachten die in deze map gevonden worden.
4.  De doelmap opent automatisch zodra het proces klaar is.

### Methode 2: Dubbelklikken (Menu)
Gebruik dit als je specifiek één opdracht wilt ophalen.

1.  Dubbelklik op de **GLR Collector**.
2.  Selecteer in het venster de `Submitted files` map van de klas.
3.  Kies de gewenste opdracht uit de lijst.
4.  De app haalt alleen deze opdracht op en opent de doelmap na afronding.

---

## Output

De verzamelde bestanden worden standaard geplaatst in:
`~/Downloads/GLR_NAKIJKEN/`

De bestandsstructuur wordt automatisch als volgt opgebouwd:
```text
GLR_NAKIJKEN/
└── [Naam Opdracht]/
    ├── [Naam Student A]/
    │   ├── index.html
    │   └── style.css
    ├── [Naam Student B]/
    │   └── (Uitgepakte bestanden)
    └── ...
```

## Functionaliteiten

* **Versiebeheer:** Detecteert automatisch mappen als `Version_1`, `Versie 2` etc. en downloadt alleen de nieuwste.
* **Auto-Unzip:** ZIP-bestanden worden direct uitgepakt in de map van de student.
* **Schoon:** `node_modules`, `.git` mappen en macOS systeembestanden (`.DS_Store`) worden automatisch gefilterd en niet gekopieerd.

## Probleemoplossing

**De app opent niet ("Onbekende ontwikkelaar")**
De eerste keer kan macOS de app blokkeren.
* Oplossing: Klik met de **rechtermuisknop** op de app en kies **Open**. Bevestig daarna met "Open".

**De output map is leeg**
* Controleer of OneDrive volledig is gesynchroniseerd. De bestanden moeten lokaal op de Mac staan.
* Controleer of de mapstructuur in Teams overeenkomt met de standaard (Studentmap -> Opdrachtmap).