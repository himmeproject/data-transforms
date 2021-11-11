<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:t="http://www.tei-c.org/ns/1.0"
    xmlns:local="http://syriaca.org/ns" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:json="http://json.org/" 
    exclude-result-prefixes="xs t xsl local html json">
    
    <!-- =================================================================== -->
    <!-- Generate HTML files from TEI for HIMME records                      -->
    <!-- File is output to file system                                       -->  
    <!--    /data/person,                                                    -->  
    <!--    /data/places                                                     -->   
    <!--    /data/practices                                                  -->
    <!-- =================================================================== -->
    
    <!-- TEI core, from srophe codebase  -->
    <xsl:import href="teiCore.xsl"/>
<!--    <xsl:import href="bibliography.xsl"/>-->
    <xsl:import href="helper-functions.xsl"/>
    <xsl:import href="generateJSON.xsl"/>
    
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="yes" omit-xml-declaration="yes" xml:space="preserve" xpath-default-namespace="http://www.w3.org/1999/xhtml"/>
    <xsl:output name="json" method="text" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>
    
    <!-- parameters -->
    <xsl:param name="map-key" select="''"/>
    <xsl:param name="nav-base" select="'/'"/>
    <xsl:param name="base-uri" select="''"/>
    <xsl:param name="repository-title" select="''"/>
    <xsl:param name="normalization">NFKC</xsl:param>
    
    <xsl:variable name="record-id" select="replace(//t:publicationStmt/t:idno[@type='URI'][1],'.xml','')"/>
    <xsl:variable name="savePath" select="concat('data/',tokenize($record-id,'/')[4])"/>
    <xsl:variable name="saveFileName" select="tokenize($record-id,'/')[5]"/>
    
    <!-- Main template -->
    <xsl:template match="/">
        <!-- Output filename, currently based on input filename, will rename as needed -->
        <xsl:variable name="htmlFile" select="concat($savePath,'/', concat($saveFileName,'.html'))"/>
        <!-- Output JSON document -->
        <xsl:result-document href="{$htmlFile}" format="html">
            <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html&gt;</xsl:text>
            <xsl:apply-templates/>
        </xsl:result-document>
        <!-- Output filename, currently based on input filename, will rename as needed -->
        <xsl:variable name="jsonFile" select="concat($savePath,'/json/', concat($saveFileName,'.json'))"/>
        <!-- Output JSON document -->
        <xsl:result-document href="{$jsonFile}" format="json">
            <xsl:variable name="doc">
                <xsl:call-template name="xml2json"/>
            </xsl:variable>
            <xsl:apply-templates mode="json" select="$doc"/>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="t:TEI">
        <html>
            <head>
                <meta charset="utf-8" />
                <meta http-equiv="X-UA-Compatible" content="IE=edge" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <xsl:call-template name="staticSearchMetadata"/>
                <xsl:call-template name="metadata"/>
                <!-- Favicon -->
                <link rel="shortcut icon" href="/resources/img/favicon.ico" />
                <!-- CSS -->
                <!-- Bootstrap -->
                <link rel="stylesheet" type="text/css" href="/resources/css/bootstrap.min.css" />
                <!-- HIMME CSS -->
                <link rel="stylesheet" type="text/css" href="/resources/css/himme.css" />
                <link rel="stylesheet" type="text/css" href="/resources/css/vis.css" />
                <!-- Mobile Smart Menu core -->
                <link rel="stylesheet" type="text/css" href="/resources/css/sm-core-css.css" />
                <!-- Leaflet -->
                <link rel="stylesheet" href="/resources/leaflet/leaflet.css" />
                <link rel="stylesheet" href="/resources/leaflet/leaflet.awesome-markers.css" />
                <!-- Javascript -->
                <!-- jquery -->
                <link href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.12.0/themes/ui-lightness/jquery-ui.css" rel="stylesheet" />
                <!-- Additional Javascript -->
                <script type="text/javascript" src="/resources/js/jquery.min.js"></script> 
                <script type="text/javascript" src="/resources/js/bootstrap.min.js"></script> 
                <script type="text/javascript" src="/resources/js/jquery.validate.min.js"></script> 
                <script type="text/javascript" src="/resources/js/main.js"></script>
                <!-- sortable table javascript -->
                <script src="/resources/js/sorttable.js"></script>
            </head>
            <body vocab="http://schema.org/">
                <xsl:call-template name="navbar"/>
                <div id="main">
                    <div id="main-content-area">
                    <!-- H1 -->
                    <h1><xsl:value-of select="descendant::t:title[1]"/></h1>
                        <p class="URI-display noIndex">
                        <small><span class="srp-label">URI: </span>
                            <span id="syriaca-id"><xsl:value-of select="descendant::t:publicationStmt/t:idno[@type='URI'][1]"/></span>
                        </small>
                    </p>
                    <!-- Contents -->
                    <!-- Abstract -->
                    <xsl:apply-templates select="descendant::t:body"/>
                    </div>
                </div>
                <!-- Footer -->
                <footer>
                    <div class="container">
                        <a href="http://creativecommons.org/licenses/by/3.0/deed.en_US" rel="license"><img alt="Creative Commons License" style="border-width:0" src="/resources/img/cc.png" height="18px" /></a>
                        This work is licensed under a <a href="http://creativecommons.org/licenses/by/3.0/deed.en_US" rel="license">Creative Commons Attribution 3.0 Unported License</a>.<br />
                        Adapted from the Srophe App (<a href="http://syriaca.org">Syriaca.org</a>), used under a CC-BY 3.0 license.<br />
                        Copyright Thomas Carlson, 2020.
                    </div>
                </footer>

            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="t:body">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="t:listPerson">
        <xsl:for-each select="t:person">
            <xsl:apply-templates select="t:note[@type='abstract']"/>
            <!-- Names -->
            <xsl:variable name="columns">
                <xsl:choose>
                    <xsl:when test="t:sex or t:state">3</xsl:when>
                    <xsl:otherwise>2</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <div class="row">
                <!-- column 1 names -->
                <div>
                    <xsl:attribute name="class">
                        <xsl:choose>
                            <xsl:when test="$columns = 3">col-md-4</xsl:when>
                            <xsl:otherwise>col-md-8</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <div class="well">
                        <h3>Names</h3>
                        <ul>
                            <xsl:for-each select="t:persName[not(@source='headword')]">
                                <xsl:sort select="local:expand-lang(@xml:lang)"/>
                                <xsl:apply-templates select="." mode="list"/>
                            </xsl:for-each>
                        </ul>
                    </div>
                </div>
                <xsl:if test="$columns = 3">
                    <div class="col-md-4">
                        <div class="well">
                            <h3>Attributes</h3>
                            <ul>
                                <xsl:for-each select="t:sex">
                                    <li><xsl:apply-templates/></li>
                                </xsl:for-each>
                                <xsl:for-each select="t:state">
                                    <li><xsl:apply-templates/></li>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </div>   
                </xsl:if>
                <div class="col-md-4">
                    <xsl:call-template name="link-icons-list"/> 
                </div>
            </div> 
            <xsl:call-template name="events"/>
            <xsl:apply-templates select="t:note[not(@type='abstract')]"/>
            <xsl:call-template name="sources"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="t:listPlace">
        <xsl:for-each select="t:place">
        <xsl:apply-templates select="t:note[@type='abstract']"/>
        <!-- Names -->
            <xsl:variable name="columns">
                <xsl:choose>
                    <xsl:when test="t:location[@type='gps']">3</xsl:when>
                    <xsl:otherwise>2</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <div class="row">
                <div>
                    <xsl:attribute name="class">
                        <xsl:choose>
                            <xsl:when test="$columns = 3">col-md-4</xsl:when>
                            <xsl:otherwise>col-md-8</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <div class="well">
                        <h3>Names</h3>
                        <ul>
                            <xsl:for-each select="t:placeName[not(@source='headword')]">
                                <xsl:sort select="local:expand-lang(@xml:lang)"/>
                                <xsl:apply-templates select="." mode="list"/>
                            </xsl:for-each>
                        </ul>
                    </div>
                </div>
                <xsl:if test="$columns = 3">
                    <div class="col-md-4 column1">
                        <xsl:call-template name="map"/>  
                    </div>    
                </xsl:if>
                <div class="col-md-4 column1">
                    <xsl:call-template name="link-icons-list"/> 
                </div>
            </div> 
            <xsl:call-template name="events"/>
            <xsl:apply-templates select="t:note[not(@type='abstract')]"/>
            <xsl:call-template name="sources"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="t:listEvent">
        <xsl:for-each select="t:event">
            <xsl:apply-templates select="t:note[@type='abstract']"/>
            <!-- Names -->
            <div class="row">
                <div class="col-md-8 column1">
                    <div class="well">
                        <div class="well">
                            <h3>Names</h3>
                            <ul>
                                <xsl:for-each select="t:label[not(@source='headword')]">
                                    <xsl:sort select="local:expand-lang(@xml:lang)"/>
                                    <xsl:apply-templates select="." mode="list"/>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 column1">
                    <xsl:call-template name="link-icons-list"/> 
                </div>
            </div> 
            <xsl:call-template name="events"/>
            <xsl:apply-templates select="t:note[not(@type='abstract')]"/>
            <xsl:call-template name="sources"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Places, Persons, Events as list -->
    <xsl:template match="t:placeName | t:title | t:persName | t:label" mode="list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <li>
                    <span class="tei-{local-name(.)}" dir="ltr">
                        <!-- 
                        <xsl:sequence select="local:attributes(.)"/>
                        <xsl:apply-templates select="." mode="plain"/>
                        -->
                        <xsl:choose>
                            <xsl:when test="t:choice">
                                <span><xsl:value-of select="local:expand-lang(@xml:lang)"/>: </span>
                                <xsl:for-each select="t:choice/t:seg">
                                    <span>
                                        <xsl:choose>
                                            <xsl:when test="contains(@xml:lang, '-Latn')">
                                                <xsl:attribute name="lang">en</xsl:attribute>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:attribute name="lang"><xsl:value-of select="@xml:lang"/></xsl:attribute>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <xsl:value-of select="."/>
                                    </span>    
                                    <xsl:if test="position() != last()"> = </xsl:if>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise><xsl:apply-templates select="." mode="plain"/></xsl:otherwise>
                        </xsl:choose>
                    </span>
                    <xsl:sequence select="local:add-footnotes(@source,.)"/>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Named Templates -->
    <!-- Events -->
    <xsl:template name="events">
        <xsl:if test="t:event">
            <div id="eventVis">
                <h3>Temporal Data</h3>
                <div>
                    <form id="filterForm">
                        <input id="filterStart" name="start" placeholder="Year"/> to <input id="filterEnd" name="end"  placeholder="Year"/>
                        <select name="filterMenu" id="filterMenu">
                            <option value="event">Event</option>
                            <option value="composition">Composition</option>
                            <option value="manuscript">Manuscript</option>
                            <option value="edition">Edition</option>
                        </select>
                        <button type="button" class="filter-btn">Filter</button>
                        Sort: 
                        <select name="sortMenu" id="sortMenu">
                            <option value="event">Event</option>
                            <option value="composition">Composition</option>
                            <option value="manuscript">Manuscript</option>
                            <option value="edition">Edition</option>
                        </select>
                        <button type="button" class="reset" id="resetGraph">Reset</button>
                    </form>
                </div>
                <div id="vis"/>
                <script src="/resources/js/d3.v4.min.js" type="text/javascript"/>
                <script src="/resources/js/d3-selection-multi.v1.js"/>
                <script src="/resources/js/vis.js"/>
                
                <script type="text/javascript">
                    <xsl:text>var jsonFile = '</xsl:text><xsl:value-of select="concat('json/', concat($saveFileName,'.json'))"/><xsl:text>';</xsl:text>
                    <xsl:text>var height = </xsl:text><xsl:value-of select="(count(//t:event) * 50) + 200 "/>
                    <!--<xsl:choose>
                        <xsl:when test="count(//t:event) lt 4">200</xsl:when>
                        <xsl:when test="count(//t:event) lt 10">400</xsl:when>
                        <xsl:when test="count(//t:event) lt 15">600</xsl:when>
                        <xsl:otherwise>800</xsl:otherwise>
                    </xsl:choose>--><xsl:text>;</xsl:text>
                    <![CDATA[
                    //Load data
                    d3.json(jsonFile, function (error, graph) {
                      if (error) throw error;
                      make(graph, "1200",height);
                    });
                  //]]>
                </script>
            </div>
        </xsl:if>
        <xsl:if test="t:event">
            <div id="event">
                <table class="table table-bordered sortable">
                    <!-- Table headers -->
                    <tr>
                        <th class="sorttable_nosort">Event Description</th>
                        <th>Date</th>
                        <th><span class="hidden-xl hidden-lg hidden-md">Comp.</span><span class="hidden-xl hidden-lg hidden-md hidden-sm hidden-xs">/</span><span class="hidden-sm hidden-xs">Composition</span></th>
                        <th><span class="hidden-xl hidden-lg hidden-md">MS.</span><span class="hidden-xl hidden-lg hidden-md hidden-sm hidden-xs">/</span><span class="hidden-sm hidden-xs">Manuscript</span></th>
                        <th><span class="hidden-xl hidden-lg hidden-md">Ed.</span><span class="hidden-xl hidden-lg hidden-md hidden-sm hidden-xs">/</span><span class="hidden-sm hidden-xs">Edition</span></th>
                    </tr>
                    <xsl:for-each select="t:event">
                       <tr>
                           <td>
                               <xsl:apply-templates select="t:desc"/>
                               <xsl:sequence select="local:add-footnotes(@source,'en')"/>
                           </td>
                           <xsl:for-each select="t:label">
                               <td>
                                   <xsl:attribute name="data-sorttable_customkey">
                                       <xsl:choose>
                                           <xsl:when test="t:date/@when"><xsl:value-of select="t:date/@when"/></xsl:when>
                                           <xsl:when test="t:date/@notBefore"><xsl:value-of select="t:date/@notBefore"/></xsl:when>
                                           <xsl:when test="t:date/@from"><xsl:value-of select="t:date/@from"/></xsl:when>
                                           <xsl:when test="t:date/@to"><xsl:value-of select="t:date/@to"/></xsl:when>
                                           <xsl:when test="t:date/@notAfter"><xsl:value-of select="t:date/@notAfter"/></xsl:when>
                                           <xsl:otherwise>0</xsl:otherwise>
                                       </xsl:choose>
                                   </xsl:attribute>
                                   <xsl:apply-templates/>
                               </td>
                           </xsl:for-each> 
                       </tr>
                    </xsl:for-each>
                </table>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:location" mode="geojson">
        <!-- source="headword" -->
        <xsl:variable name="id">
            <xsl:choose>
                <xsl:when test="/descendant::t:idno[@type='URI']"><xsl:value-of select="/descendant::t:idno[@type='URI'][1]"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="/descendant::t:idno[1]"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="title">
            <xsl:choose>
                <xsl:when test="descendant-or-self::*[@source='headword']"><xsl:value-of select="descendant-or-self::*[@source='headword']//text()"/></xsl:when>
                <xsl:when test="descendant::t:title[@level='a']"><xsl:value-of select="descendant::t:title[@level='a']"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="descendant::t:title[1]"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="desc">
            <xsl:choose>
                <xsl:when test="/descendant::t:desc[1]/t:quote"><xsl:value-of select="/descendant::t:desc[1]/t:quote"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="/descendant::t:desc[1]"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="type">
            <xsl:choose>
                <xsl:when test="/descendant::t:place/@type"><xsl:value-of select="/descendant::t:place/@type"/></xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="coords"><xsl:value-of select="t:geo"/></xsl:variable>
        <!--Expected output:
            {
            "type":"Feature",
            "geometry":{
                "type":"Point",
                "coordinates":[42.195833, 37.325]
                },
            "properties":{
                "uri":"http:\/\/medievalmideast.org\/place\/18.html",
                "name":"Jazīrat Ibn ʿUmar",
                "desc":"A city, today named Cizre, on the Tigris upriver from Mosul.",
                "type":"settlement"}
            } -->
        <xsl:text>{"type":"Feature",</xsl:text>
        <xsl:text>"geometry":{</xsl:text>
            <xsl:text>"type":"Point",</xsl:text>
            <xsl:text>"coordinates":[</xsl:text>
                <xsl:value-of select="tokenize($coords,' ')[2]"/><xsl:text>, </xsl:text><xsl:value-of select="tokenize($coords,' ')[1]"/>
            <xsl:text>]},</xsl:text>
        <xsl:text>"properties":{</xsl:text>
        <xsl:text>"uri": "</xsl:text><xsl:value-of select="replace($id,'/tei','.html')"/><xsl:text>",</xsl:text>
        <xsl:text>"name":"</xsl:text><xsl:value-of select="normalize-space($title)"/><xsl:text>"</xsl:text>
        <xsl:if test="$desc != ''">
            <xsl:text>,"desc":"</xsl:text><xsl:value-of select="normalize-space($desc)"/><xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:if test="$type != ''">
            <xsl:text>,"type":"</xsl:text><xsl:value-of select="normalize-space($type)"/><xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>}</xsl:text>
        <xsl:text>}</xsl:text>
    </xsl:template>
    <xsl:template name="geojson">
        <!-- Expected Output: {"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[42.195833, 37.325]},"properties":{"uri":"http:\/\/medievalmideast.org\/place\/18.html","name":"Jazīrat Ibn ʿUmar","desc":"A city, today named Cizre, on the Tigris upriver from Mosul.","type":"settlement"}}]} -->
        <xsl:text>{"type":"FeatureCollection","features":[
            </xsl:text><xsl:apply-templates select="descendant::t:location" mode="geojson"/>
        <xsl:text>]}</xsl:text>
    </xsl:template>
    <!-- Map templates -->
    <xsl:template name="map">
        <div id="map-data">
            <script type="text/javascript" src="/resources/leaflet/leaflet.js"/>
            <script type="text/javascript" src="/resources/leaflet/leaflet.awesome-markers.min.js"/>
            <div id="map"></div>
            <script type="text/javascript">
                <![CDATA[
                    var terrain =  L.tileLayer('https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/tiles/{z}/{x}/{y}?access_token=]]>{$config:map-api-key}<![CDATA[', {
                          attribution: 'Mapbox', 
                          id: 'mapbox/outdoors-v11', 
                          maxZoom: 12, 
                          accessToken: ]]><xsl:text>'</xsl:text><xsl:value-of select="$map-key"/><xsl:text>'</xsl:text><![CDATA[
                        });
                    var streets = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', 
                          {attribution: "OpenStreetMap"});
                                                         
                    var imperium = L.tileLayer('https://dh.gu.se/tiles/imperium/{z}/{x}/{y}.png', {
                           maxZoom: 10,
                           attribution: 'Powered by Leaflet. Map base: DARE, 2015 (cc-by-sa).'
                           });                   
                    var placesgeo = ]]><xsl:call-template name="geojson"/><![CDATA[                                
                    var sropheIcon = L.Icon.extend({
                            options: {
                                iconSize:     [35, 35],
                                iconAnchor:   [22, 94],
                                popupAnchor:  [-3, -76]}
                            });
                    var redIcon = L.AwesomeMarkers.icon({
                            icon:'glyphicon-flag',
                            markerColor: 'red'
                            }),
                    orangeIcon =  L.AwesomeMarkers.icon({
                            icon:'glyphicon-flag',
                            markerColor: 'orange'
                            }),
                    purpleIcon = L.AwesomeMarkers.icon({
                            icon:'glyphicon-flag',
                            markerColor: 'purple'
                            }),
                    blueIcon =  L.AwesomeMarkers.icon({
                            icon:'glyphicon-flag',
                            markerColor: 'blue'
                            });
                                                             
                    var geojson = L.geoJson(placesgeo, {onEachFeature: function (feature, layer){
                            var typeText = feature.properties.type
                            var popupContent = "<a href='" + feature.properties.uri + "' class='map-pop-title'>" +
                                                     feature.properties.name + "</a>" + (feature.properties.type ? "Type: " + typeText : "") +
                                                     (feature.properties.desc ? "<span class='map-pop-desc'>"+ feature.properties.desc +"</span>" : "");
                                                     layer.bindPopup(popupContent);
                             
                                                     switch (feature.properties.type) {
                                                         case 'born-at': return layer.setIcon(orangeIcon);
                                                         case 'syriaca:bornAt' : return layer.setIcon(orangeIcon);
                                                         case 'died-at':   return layer.setIcon(redIcon);
                                                         case 'syriaca:diedAt' : return layer.setIcon(redIcon);
                                                         case 'has-literary-connection-to-place':   return layer.setIcon(purpleIcon);
                                                         case 'syriaca:hasLiteraryConnectionToPlace' : return layer.setIcon(purpleIcon);
                                                         case 'has-relation-to-place':   return layer.setIcon(blueIcon);
                                                         case 'syriaca:hasRelationToPlace' :   return layer.setIcon(blueIcon);
                                                         default : '';
                                                      }               
                                                     }
                                                 })
                    var map = L.map('map').fitBounds(geojson.getBounds(),{maxZoom: 5});     
                    imperium.addTo(map);
                                                             
                    L.control.layers({"Imperium (default)": imperium,  
                                    "Terrain": terrain,
                                    "Streets": streets}).addTo(map);
                    geojson.addTo(map);     
                    ]]>
            </script>
        </div>
    </xsl:template>
    
    <!-- Page metadata -->
    <xsl:template name="metadata">
        <xsl:if test="descendant::t:note[@type='abstract']">
            <meta name="description" content="{normalize-space(string-join(descendant::t:note[@type='abstract']//text(),''))}"/>
        </xsl:if>
        <title><xsl:value-of select="descendant::t:teiHeader/descendant::t:title[1]"/></title>
    </xsl:template>
    
    <!-- Metadata used by staticSearch -->
    <xsl:template name="staticSearchMetadata">
        <!-- Type of record -->
        <xsl:choose>
            <xsl:when test="descendant::t:body/t:listEvent">
                <meta name="Document type" class="staticSearch.desc" content="Practice"/>
            </xsl:when>
            <xsl:when test="descendant::t:body/t:listPlace">
                <meta name="Document type" class="staticSearch.desc" content="Place"/>
            </xsl:when>
            <xsl:when test="descendant::t:body/t:listPerson">
                <meta name="Document type" class="staticSearch.desc" content="Person"/>
            </xsl:when>
        </xsl:choose>
        <!-- Record Title -->
        <meta name="docTitle" class="staticSearch.docTitle" content="{//t:teiHeader/descendant::t:title[1]}"/>
    </xsl:template>
    
    <!-- Site navbar -->
    <xsl:template name="navbar">
        <!--[if lt IE 7]>
                <p class="chromeframe">You are using an <strong>outdated</strong> browser. Please <a href="http://browsehappy.com/">upgrade your browser</a> or <a href="http://www.google.com/chromeframe/?redirect=true">activate Google Chrome Frame</a> to improve your experience.</p>
                <![endif]-->
        <!-- Fixed navbar -->
        <div class="navbar navbar-default navbar-fixed-top" style="background-color: #FFFFFF">
            <div class="container">
                <div class="navbar-header">
                    <a href="http://medievalmideast.org">
                        <img src="/resources/img/logo.png" width="40" height="40" alt="HIMME logo: Monumental Kufic" title="HIMME logo: Monumental Kufic" /> 
                        <span class="banner-text">
                            <span class="hidden-xl hidden-lg hidden-md">HIMME</span>
                            <span class="hidden-xl hidden-lg hidden-md hidden-sm hidden-xs">:</span>
                            <span class="hidden-sm hidden-xs">Historical Index of the Medieval Middle East</span></span></a>
                </div>
            </div>
        </div>
    </xsl:template>

    <!-- Sources -->
    <xsl:template name="sources">
        <!-- Sources -->
        <div id="sources" class="noIndex">
            <h3>Sources</h3>
            <!-- WORK in progress
            <xsl:choose>
                <xsl:when test="t:listBibl">
                    <xsl:for-each select="t:listBibl">
                        <ul class="footnote-list">
                            <xsl:for-each select="t:bibl">
                                <xsl:apply-templates select="." mode="footnote"/>
                            </xsl:for-each>
                        </ul>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <ul class="footnote-list">
                        <xsl:for-each select="t:bibl">
                            <xsl:apply-templates select="." mode="footnote"/>
                        </xsl:for-each>
                    </ul>
                </xsl:otherwise>
            </xsl:choose>
            -->
        </div>
    </xsl:template>
    
    <!-- See also template -->
    <xsl:template name="link-icons-list">
        <xsl:variable name="title" select="descendant::t:title[1]"/>
        <div id="see-also" class="well noIndex">
            <h3>See Also</h3>
            <ul>
                <xsl:for-each select="//t:idno[contains(.,'csc.org.il')]">
                    <li>
                        <a href="{normalize-space(.)}"> "
                            <xsl:value-of select="substring-before(substring-after(normalize-space(.),'sK='),'&amp;sT=')"/>" in the Comprehensive Bibliography on Syriac Christianity</a>
                    </li>
                </xsl:for-each>
                <!-- WorldCat Identities -->
                <xsl:for-each select="//t:idno[contains(.,'http://worldcat.org/identities')]">
                    <li>
                        <a href="{normalize-space(.)}"> "<xsl:value-of select="substring-after(.,'http://worldcat.org/identities/')"/>" in WorldCat Identities</a>
                    </li>
                </xsl:for-each>
                <!-- VIAF -->
                <xsl:for-each select="//t:idno[contains(.,'http://viaf.org/')]">
                    <li>
                        <a href="{normalize-space(.)}">VIAF</a>
                    </li>
                </xsl:for-each>
                <!-- Pleiades links -->
                <xsl:for-each select="//t:idno[contains(.,'pleiades')]">
                    <li>
                        <a href="{normalize-space(.)}">
                            <img src="/resources/img/circle-pi-25.png" alt="Image of the Greek letter pi in blue; small icon of the Pleiades project" title="click to view {$title} in Pleiades"/> View in Pleiades</a>
                    </li>
                </xsl:for-each>
                <!-- Google map links -->
                <xsl:for-each select="//descendant::t:location[@type='gps']/t:geo">
                    <li>
                        <xsl:variable name="geoRef">
                            <xsl:variable name="coords" select="tokenize(normalize-space(.), '\s+')"/>
                            <xsl:value-of select="$coords[1]"/>
                            <xsl:text>, </xsl:text>
                            <xsl:value-of select="$coords[2]"/>
                        </xsl:variable>
                        <a href="https://maps.google.com/maps?q={$geoRef}+(name)&amp;z=10&amp;ll={$geoRef}">
                            <img src="/resources/img/gmaps-25.png" alt="The Google Maps icon" title="click to view {$title} on Google Maps"/> View in Google Maps
                        </a>
                    </li>
                </xsl:for-each>
                
                <!-- TEI source link -->
                <li>
                    <a href="#" rel="alternate" type="application/tei+xml">
                        <img src="/resources/img/tei-25.png" alt="The Text Encoding Initiative icon" title="click to view the TEI XML source data for this place"/> TEI XML source data</a>
                </li>  
                <!-- Wikipedia links -->
                <xsl:for-each select="//t:idno[contains(.,'wikipedia')]">
                    <xsl:variable name="get-title">
                        <xsl:value-of select="replace(tokenize(.,'/')[last()],'_',' ')"/>
                    </xsl:variable>
                    <li>
                        <a href="{.}">
                            <img src="/resources/img/Wikipedia-25.png" alt="The Wikipedia icon" title="click to view {$get-title} in Wikipedia"/> "<xsl:value-of select="$get-title"/>" in Wikipedia</a>
                    </li>
                </xsl:for-each>
            </ul>
        </div>
    </xsl:template>
</xsl:stylesheet>