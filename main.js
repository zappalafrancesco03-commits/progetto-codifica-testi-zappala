document.addEventListener("DOMContentLoaded", () => {
    /*
        Imposto come visualizzazione iniziale la versione diplomatica del testo.
        In questo modo, quando la pagina viene caricata, vengono mostrate le forme originali
        presenti nell'articolo.
    */
    document.body.classList.add("show-diplomatic");

    const highlightButtons = document.querySelectorAll("[data-highlight]");
    const versionButtons = document.querySelectorAll(".version-button");
    const zones = document.querySelectorAll(".facsimile-zone");
    const textBlocks = document.querySelectorAll("[data-facs]");

    /*
        Gestione dei bottoni di evidenziazione.
        Ogni bottone possiede un attributo data-highlight, che corrisponde alla classe
        degli elementi TEI trasformati in HTML: persone, luoghi, organizzazioni, date e termini.
    */
    highlightButtons.forEach((button) => {
        button.addEventListener("click", () => {
            const type = button.dataset.highlight;
            const elements = document.querySelectorAll("." + type);

            elements.forEach((el) => {
                el.classList.toggle("highlighted-entity");
                el.classList.toggle("highlighted-" + type); // applica il colore specifico della categoria
            });

            button.classList.toggle("active"); // evidenzia anche il bottone selezionato
        });
    });

    /*
        Gestione dello switch tra versione diplomatica e interpretativa.
        La versione diplomatica mostra le forme originali, mentre quella interpretativa
        mostra le forme normalizzate inserite con choice/orig/reg nel file XML-TEI.
    */
    versionButtons.forEach((button) => {
        button.addEventListener("click", () => {
            const version = button.dataset.version;

            document.body.classList.remove("show-diplomatic", "show-interpretative");
            document.body.classList.add("show-" + version);

            versionButtons.forEach((btn) => {
                btn.classList.remove("active");
            });

            button.classList.add("active");
        });
    });

    /*
        Rimuove le evidenziazioni attive del collegamento testo-immagine.
        Viene usata ogni volta che si clicca su una nuova zona del facsimile
        o su un nuovo blocco testuale.
    */
    function clearFacsActive() {
        document.querySelectorAll(".active-zone").forEach((el) => {
            el.classList.remove("active-zone");
        });

        document.querySelectorAll(".active-text").forEach((el) => {
            el.classList.remove("active-text");
        });
    }

    /*
        Attiva il collegamento partendo da una zona del facsimile.
        Quando si clicca su un rettangolo SVG dell'immagine, la funzione cerca
        il blocco testuale che ha lo stesso riferimento nell'attributo data-facs.

        Se un paragrafo è diviso in più zone, ad esempio tra due colonne o due pagine,
        vengono evidenziate tutte le zone collegate allo stesso paragrafo.
    */
    function activateByZone(zoneId) {
        clearFacsActive();

        const matchedBlocks = [];

        textBlocks.forEach((block) => {
            const facs = block.dataset.facs || "";
            const refs = facs.split(/\s+/);

            if (refs.includes(zoneId)) {
                matchedBlocks.push(block);
            }
        });

        if (matchedBlocks.length > 0) {
            const allRefs = new Set(); // evita duplicati tra le zone collegate

            matchedBlocks.forEach((block) => {
                const facs = block.dataset.facs || "";
                const refs = facs.split(/\s+/);

                refs.forEach((refId) => {
                    allRefs.add(refId);
                });

                block.classList.add("active-text");
            });

            allRefs.forEach((refId) => {
                document.querySelectorAll(`[data-zone="${refId}"]`).forEach((zone) => {
                    zone.classList.add("active-zone");
                });
            });

            matchedBlocks[0].scrollIntoView({
                behavior: "smooth",
                block: "center"
            });
        } else {
            /*
                Caso di sicurezza: se non viene trovato un blocco testuale collegato,
                viene comunque evidenziata la zona cliccata.
            */
            document.querySelectorAll(`[data-zone="${zoneId}"]`).forEach((zone) => {
                zone.classList.add("active-zone");
            });
        }
    }

    /*
        Attiva il collegamento partendo dal testo.
        Quando si clicca su un titolo, sottotitolo o paragrafo, vengono lette le zone
        indicate nell'attributo data-facs e viene evidenziata la parte corrispondente
        sul facsimile.

        Se il testo è collegato a più zone, vengono evidenziate tutte, ma lo scroll
        porta alla prima zona, cioè all'inizio fisico del blocco nell'immagine.
    */
    function activateByText(block) {
        clearFacsActive();

        const facs = block.dataset.facs || "";
        const refs = facs.split(/\s+/);

        let firstZone = null;

        refs.forEach((zoneId) => {
            const zone = document.querySelector(`[data-zone="${zoneId}"]`);

            if (zone) {
                zone.classList.add("active-zone");

                if (!firstZone) {
                    firstZone = zone; // conserva la prima zona per lo scroll
                }
            }
        });

        if (firstZone) {
            firstZone.scrollIntoView({
                behavior: "smooth",
                block: "center"
            });
        }

        block.classList.add("active-text");
    }

    /*
        Associo il click a tutte le zone SVG del facsimile.
        Ogni zona ha un data-zone che corrisponde agli identificativi usati nel facs del testo.
    */
    zones.forEach((zone) => {
        zone.addEventListener("click", () => {
            activateByZone(zone.dataset.zone);
        });
    });

    /*
        Associo il click a tutti i blocchi testuali collegati a una zona.
        Rientrano in questa selezione paragrafi, titoli e sottotitoli con attributo data-facs.
    */
    textBlocks.forEach((block) => {
        block.addEventListener("click", () => {
            activateByText(block);
        });
    });
});