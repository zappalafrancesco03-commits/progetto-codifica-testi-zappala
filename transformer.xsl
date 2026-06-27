<?xml version="1.0" encoding="UTF-8"?>

<!--
     File XSLT del progetto di Codifica di Testi.
     
     Questo foglio di stile trasforma il file XML-TEI in una pagina HTML navigabile.
     La trasformazione si occupa di:
     - generare la struttura principale della pagina HTML;
     - mostrare gli articoli codificati nel file TEI;
     - visualizzare i facsimili delle pagine originali tramite SVG;
     - creare le zone cliccabili delle immagini a partire dai tag <zone>;
     - trasformare gli elementi TEI principali, come persone, luoghi, organizzazioni,
     date, note, termini del glossario e normalizzazioni;
     - permettere al CSS e al JavaScript di collegare testo e immagine attraverso
     gli attributi data-facs e data-zone.
     
     Il file non modifica il contenuto del testo, ma lo presenta in forma HTML.
-->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="tei">
  
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>
  
  <!--
       Template principale.
       Genera la pagina HTML completa a partire dal documento XML-TEI.
  -->
  <xsl:template match="/">
    <html lang="it">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        
        <title>
          <xsl:value-of select="//tei:titleStmt/tei:title"/>
        </title>
        
        <meta name="description" content="{normalize-space(//tei:encodingDesc/tei:projectDesc)}"/>
        
        <!-- Autori del progetto ricavati dal teiHeader -->
        <xsl:for-each select="//tei:titleStmt/tei:respStmt/tei:persName">
          <meta name="author" content="{normalize-space(.)}"/>
        </xsl:for-each>
        
        <link rel="stylesheet" href="style.css"/>
      </head>
      
      <body>
        <!--
             Navbar principale.
             Contiene il titolo del progetto, i link agli articoli,
             i bottoni per evidenziare le entità e lo switch
             tra versione diplomatica e interpretativa.
        -->
        <header id="indice">
          <h1>
            <xsl:value-of select="//tei:titleStmt/tei:title"/>
          </h1>
          
          <div class="navbar-bottom">
            <nav>
              <xsl:for-each select="//tei:div[@type='article']">
                <a href="#{@xml:id}">
                  <xsl:value-of select="tei:head"/>
                </a>
              </xsl:for-each>
            </nav>
            
            <div class="nav-tools">
              <div class="highlight-buttons">
                <button type="button" data-highlight="persName">Persone</button>
                <button type="button" data-highlight="placeName">Luoghi</button>
                <button type="button" data-highlight="orgName">Organizzazioni</button>
                <button type="button" data-highlight="date">Date</button>
                <button type="button" data-highlight="term">Termini</button>
              </div>
              
              <div class="version-switch">
                <button type="button" class="version-button active" data-version="diplomatic">Diplomatica</button>
                <button type="button" class="version-button" data-version="interpretative">Interpretativa</button>
              </div>
            </div>
          </div>
        </header>
        
        <!--
             La pagina è divisa in due sezioni:
             a sinistra il testo trasformato dal TEI,
             a destra i facsimili delle pagine originali.
        -->
        <main>
          <section id="text-section">
            <xsl:apply-templates select="//tei:div[@type='article']"/>
          </section>
          
          <section id="image-section">
            <xsl:apply-templates select="//tei:facsimile/tei:surface"/>
          </section>
        </main>
        
        <script src="main.js"></script>
      </body>
    </html>
  </xsl:template>
  
  <!--
       Trasforma ogni surface del facsimile in un SVG.
       L'immagine originale viene inserita dentro l'SVG e sopra di essa
       vengono disegnati i rettangoli corrispondenti alle zone TEI.
  -->
  <xsl:template match="tei:surface">
    <figure class="facsimile-page" id="{@xml:id}">
      <svg class="facsimile-svg" preserveAspectRatio="xMidYMid meet">
        <xsl:attribute name="viewBox">
          <xsl:text>0 0 </xsl:text>
          <xsl:value-of select="translate(tei:graphic/@width, 'px', '')"/>
          <xsl:text> </xsl:text>
          <xsl:value-of select="translate(tei:graphic/@height, 'px', '')"/>
        </xsl:attribute>
        
        <image x="0" y="0" preserveAspectRatio="none">
          <xsl:attribute name="width">
            <xsl:value-of select="translate(tei:graphic/@width, 'px', '')"/>
          </xsl:attribute>
          <xsl:attribute name="height">
            <xsl:value-of select="translate(tei:graphic/@height, 'px', '')"/>
          </xsl:attribute>
          <xsl:attribute name="href">
            <xsl:value-of select="tei:graphic/@url"/>
          </xsl:attribute>
        </image>
        
        <xsl:apply-templates select="tei:zone"/>
      </svg>
    </figure>
  </xsl:template>
  
  <!--
       Trasforma ogni zona TEI in un rettangolo SVG.
       L'attributo data-zone viene usato dal JavaScript per collegare
       la zona dell'immagine al testo corrispondente.
  -->
  <xsl:template match="tei:zone">
    <rect class="facsimile-zone">
      <xsl:attribute name="id">
        <xsl:value-of select="@xml:id"/>
      </xsl:attribute>
      <xsl:attribute name="data-zone">
        <xsl:value-of select="@xml:id"/>
      </xsl:attribute>
      <xsl:attribute name="x">
        <xsl:value-of select="@ulx"/>
      </xsl:attribute>
      <xsl:attribute name="y">
        <xsl:value-of select="@uly"/>
      </xsl:attribute>
      <xsl:attribute name="width">
        <xsl:value-of select="@lrx - @ulx"/>
      </xsl:attribute>
      <xsl:attribute name="height">
        <xsl:value-of select="@lry - @uly"/>
      </xsl:attribute>
    </rect>
  </xsl:template>
  
  <!-- Articolo -->
  <xsl:template match="tei:div[@type='article']">
    <article id="{@xml:id}" class="articolo">
      <xsl:apply-templates/>
    </article>
  </xsl:template>
  
  <!--
       Titolo dell'articolo.
       data-facs conserva il collegamento con la zona del facsimile.
  -->
  <xsl:template match="tei:head">
    <h2 class="titolo_articolo" data-facs="{translate(@facs, '#', '')}">
      <xsl:apply-templates/>
    </h2>
  </xsl:template>
  
  <!-- Sottotitolo o indicazione redazionale dell'articolo -->
  <xsl:template match="tei:byline">
    <p class="byline" data-facs="{translate(@facs, '#', '')}">
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  
  <!-- Paragrafi del testo -->
  <xsl:template match="tei:p">
    <p class="paragrafo" data-facs="{translate(@facs, '#', '')}">
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  
  <!-- Cambio pagina della fonte originale -->
  <xsl:template match="tei:pb">
    <span class="page-break">
      Pagina <xsl:value-of select="@n"/>
    </span>
  </xsl:template>
  
  <!-- Cambio colonna della fonte originale -->
  <xsl:template match="tei:cb">
    <span class="column-break"></span>
  </xsl:template>
  
  <!--
       Cambio riga fisica.
       Il numero della riga viene mostrato nell'output.
       Se il cambio riga arriva subito dopo un cambio pagina o colonna,
       non viene aggiunto un ulteriore <br/> per evitare spazi inutili.
  -->
  <xsl:template match="tei:lb">
    <xsl:if test="not(preceding-sibling::*[1][self::tei:cb or self::tei:pb])">
      <br/>
    </xsl:if>
    <span class="lb-marker" aria-hidden="true">
      <xsl:value-of select="@n"/>
    </span>
  </xsl:template>
  
  <!--
       Gestione della normalizzazione.
       La versione diplomatica mostra <orig>, mentre la versione interpretativa
       mostra <reg>. La visualizzazione viene controllata dal CSS e dal JS.
  -->
  <xsl:template match="tei:choice">
    <span class="choice">
      <span class="diplomatic">
        <xsl:apply-templates select="tei:orig"/>
      </span>
      <span class="interpretative">
        <xsl:apply-templates select="tei:reg"/>
      </span>
    </span>
  </xsl:template>
  
  <xsl:template match="tei:orig | tei:reg">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- Persone -->
  <xsl:template match="tei:persName">
    <span class="entity persName">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!-- Luoghi -->
  <xsl:template match="tei:placeName">
    <span class="entity placeName">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!-- Organizzazioni -->
  <xsl:template match="tei:orgName">
    <span class="entity orgName">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!-- Date -->
  <xsl:template match="tei:date">
    <span class="entity date">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!-- Riferimenti generici -->
  <xsl:template match="tei:rs">
    <span class="entity rs">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <!--
       Termini del glossario.
       Il riferimento @ref viene usato per cercare il gloss corrispondente
       e mostrarlo come tooltip al passaggio del mouse.
  -->
  <xsl:template match="tei:term">
    <xsl:variable name="reference" select="translate(@ref, '#', '')"/>
    <xsl:variable name="gloss" select="//tei:gloss[@xml:id = $reference]"/>
    
    <span class="term">
      <xsl:apply-templates/>
      
      <xsl:if test="$gloss">
        <span class="term-popup">
          <xsl:value-of select="$gloss"/>
        </span>
      </xsl:if>
    </span>
  </xsl:template>
  
  <!-- Parole particolari o usi linguistici specifici -->
  <xsl:template match="tei:distinct">
    <xsl:variable name="reference" select="translate(@corresp, '#', '')"/>
    <xsl:variable name="gloss" select="//tei:gloss[@xml:id = $reference]"/>
    
    <xsl:choose>
      <xsl:when test="$gloss">
        <span class="distinct" data-id="{$reference}">
          <xsl:apply-templates/>
          <span class="distinct_content">
            <xsl:value-of select="$gloss"/>
          </span>
        </span>
      </xsl:when>
      
      <xsl:otherwise>
        <span class="distinct" title="{@type}">
          <xsl:apply-templates/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Lingua straniera -->
  <xsl:template match="tei:foreign">
    <em class="foreign">
      <xsl:apply-templates/>
    </em>
  </xsl:template>
  
  <!-- Citazione -->
  <xsl:template match="tei:quote">
    <q class="quote">
      <xsl:apply-templates/>
    </q>
  </xsl:template>
  
  <!-- Discorso diretto -->
  <xsl:template match="tei:said">
    <q class="said">
      <xsl:apply-templates/>
    </q>
  </xsl:template>
  
  <!-- Titoli di opere -->
  <xsl:template match="tei:title">
    <cite>
      <xsl:apply-templates/>
    </cite>
  </xsl:template>
  
  <!-- Liste TEI -->
  <xsl:template match="tei:list">
    <ol class="tei-list">
      <xsl:apply-templates/>
    </ol>
  </xsl:template>
  
  <xsl:template match="tei:item">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  <!-- Nota visualizzata come tooltip -->
  <xsl:template match="tei:note">
    <span class="note-tooltip">
      <span class="note-ref">*</span>
      <span class="note-popup">
        <xsl:apply-templates/>
      </span>
    </span>
  </xsl:template>
  
  <!-- Testo in grassetto -->
  <xsl:template match="*[@rend='bold']">
    <strong>
      <xsl:apply-templates/>
    </strong>
  </xsl:template>
  
  <!-- Testo in corsivo -->
  <xsl:template match="*[@rend='italic']">
    <em>
      <xsl:apply-templates/>
    </em>
  </xsl:template>
  
</xsl:stylesheet>