# Oblig 2 gjennomgang

1. Lokal utvikling og feature branch
- Man puller først fra main, ser at man er up to date
- videre oppretter en ny feature branch for hva man skal legge til
- Gjør endringer lokalt og utøfrer nødvendige lokale tester som terraform fmt, validate, init og plan
- Når alle lokale tester er godkjente kan man pushe dette til github

2. Continuous Integration (CI)
- Man kjører en pull request mot main og CI-workflowen starter automatisk. Sjekker enkle tester for validering og gjennomfører en terraform plan for alle miljøer (dev, test og prod)
- Prod er beskyttet mot pull request så jeg må inne å godkjenne denne før prod testen kjører.
- Dersom alt blir godkjent kan man gå videre med å merge til main
- Dersom noe failer må man gjøre endringene basert på feilmeldinger og pushe ny kode for testing i CI

3. Continuous Deployment (CD)
- Når koden merges med main gjennomføres CD workflowen automatisk 
- Workflowen deployer koden som allerede er blitt testet i CI. 
- Prod er også beskyttet her så jeg må inn å godkjenne denne for kjøring.

4. Alle miljøene er oppe og kjører
- Legger til en ny git tag med versjonsnummer og hva som er endret
- push dette til github
- Sjekk om alle miljøene kjører feilfritt og deretter kan man drafte new release basert på ny git versjon

5. Ved problemer med miljø etter merge
- Må rollback til tidligere stabil versjon
- Opprette en ny hotfix branch hvor man henter opp gammel stabil versjon
- push denne til github og gjennomfør CI og CD 
- Legg til ny git tag for denne versjonen som siste stabile versjon

## Oppsett av filstrukur

I oppgaven har jeg brukt scriptet "deploy-files-and-folders.ps1"
Benytter meg kun av filene terraform og shared for selve oppgave besvarelsen og basert på de tre skriptsa som var vedlagt, lagde jeg et eget (med hjelp av copilot), som fungerer lettvint for lokal testing. 
Terraform inneholder hele azure strukturen og ressursene som blir opprettet dersom workflowene fullføres.

## Main.tf, variables.tf og locals.tf
Oppretter en RG, SA og SC og benytter seg av locals for navnegivning og variables for ulike parametere.
Storage tier, replication type og environment er de tre variablene som endres dynamisk basert på hvilken environment som kjøres. De andre variablene er de samme uavhengig av miljø.
locals endres avhengig av miljø men alle ressurser følger samme navnegivning strukur
OBS! I prod skal storage tier egentlig være Premium, men denne kan ikke opprettes sammen med replication type GRS. Derav har jeg bare opprettet Standard på prod, samme i test

## Outputs.tf
Outputs viser hva som skal vises i terminal når en av environmentsa har blitt opprettet

## Backend.tf og versions.tf
backend trengs bare fordi man benytter seg av en backend som allerede er opprettet og kan hentes i backend.hcl.
Versions.tf brukes for å sette hvilke versjoner av terraform som skal benyttes i deployering av kode i azure.

## shared fil
Denne inneholder en shared backenc.hcl som brukes for å lagre state filer for environments remote slik at flere kan jobbe mot samme prosjekt.
Har så langt ikke hatt noen secrets som bør beskyttes så benytter meg ikke av key vault i denne oppgaven.

## Scripts terraform-local-testing.ps1 / backend-configs / environments
Skriptet er laget for enkel lokal testing av 'fmt','init','validate','plan','apply','destroy' for hvert miljø (dev, test, prod).
Skriptet kjøres med argument for miljø og action, pluss autoapprove når nødvendig.
Skriptet kreves at man er logget inn med az login for å få tilgang på riktig subscription_id, hvis ikke så stopper skriptet. 
Backend-configs og environments filene brukes bare ved lokal testing (bruk av script), trengs ikke ved push og opprettelse i github.
Det vil si at backend-configs brukes for å finne backend hvor state filer skal lagres istedet for lokalt. Videre skal environments gi ulike verdier for de ulike miljøene slik at prod får bedre ressurser enn dev. Dette gir fleksibilitet for de ulike miljøene og gjør koden gjenbrukbar.  

## .yaml-filer (.github/workflows mappen)
I Oppgaven benyttes TerraformCD og TerraformCI

## terraform CI
Her blir en ny feature og kode validerert med enkle tester, fmt, validate, init og plan
Dette er for å teste at den nye versjonen av koden fungerer som den skal i alle 3 ulike miljøer.
Den vil stoppe en evt merge request dersom en feil oppstår i en av miljøene og disse feilene må endres lokalt og testes på nytt
Prod miljøet er beskyttet så en required reviewer må godkjenne testen for prod
Ved godkjent test så vil det være mulig å kjøre en merge request av branch til main

## Terraform CD 
Kode er allerede testet og validert så i denne workflowen skal man deploye koden i alle 3 miljøene.
Koden starter først med å deploye dev og dersom denne er godkjent, går den videre til å deploye test.
Dersom test godkjennes, må en required reviewer godkjenne prod, før prod deployes.
Ved godkjente tester/deployment vil dette merges med main og nye versjoner av miljøene vil være oppe å kjøre. 


