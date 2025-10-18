# Oblig 2 gjennomgang

    Lokal utvikling og feature branch
        En starter med å skrive Terraform-kode lokalt egen maskin. Når en er klar til å dele arbeidet, oppretter en feature branch hvor en deretter pusher koden til GitHub. Neste steg blir å oppretter en Pull Request mot main branch. Dette er kjernen i trunk-based development - korte, fokuserte endringer som raskt kan merges tilbake til hovedsporet.
    Continuous Integration (CI)
        Pull Request, starter CI-pipelingen automatisk. Den kjører en serie valideringer. MERK: Enkel tester nå i første omgang for å forstå prinsippene. Først sjekker den at koden er korrekt formatert (terraform fmt), deretter at syntaksen er gyldig (terraform validate), og til slutt kjører den terraform plan for alle tre miljøene. Vi validerer at koden vil fungere i alle miljøer før vi merger. Resultatet av planleggingen postes som en kommentar på PR-en, slik at både du og eventuelle reviewers kan se nøyaktig hva som vil skje i Azure. Hvis noe feiler i CI-pipelingen, må du fikse feilen lokalt, pushe ny kode, og pipelingen kjører på nytt. Først når alt er grønt og godkjent i code review, kan koden merges til main.
    Continuous Deployment (CD)
        Når koden merges til main, er det en viktig overgang. Koden er nå "bygget" i IaC-forstand - den er validert, testet og klar for deployment. CD-pipelingen tar over automatisk. Dette er "build once"-delen av prinsippet: vi validerte koden en gang i CI, nå skal vi deploye den samme koden til mange miljøer (tips: bruk script til å utføre oppgaven for å sikre at det blir gjort likt hver gang. En kan hente og kjøre script i en workflow fra et Github repo).
    Deploy til DEV
    Deploy til TEST
    Deploy til PROD (med godkjenning)
    Når alle tre miljøene er oppdatert, er jobben gjort. Samme kode er nå deployet til alle miljøer, med miljø-spesifikk konfigurasjon. Alle endringer er versjonert i Git, sporbare, og kan rulles tilbake hvis nødvendig.
