<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:json="http://json.org/" xmlns:local="http://syriaca.org/ns">


    <!-- =================================================================== -->
    <!-- Generate JSON files from TEI for HIMME timeline visualizations  -->
    <!-- =================================================================== -->

    <xsl:output method="text" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>

    <!-- Local function for formatting dates for d3js visualization on timeline expected format [M]-[D]-[Y] -->
    <xsl:function name="local:formatDate">
        <xsl:param name="date"/>
        <xsl:variable name="formatDate">
            <xsl:choose>
                <xsl:when test="$date castable as xs:date">
                    <xsl:value-of select="xs:date($date)"/>
                </xsl:when>
                <xsl:when test="matches($date, '^\d{4}$')">
                    <xsl:variable name="newDate" select="concat($date, '-01-01')"/>
                    <xsl:choose>
                        <xsl:when test="$newDate castable as xs:date">
                            <xsl:value-of select="xs:date($newDate)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$newDate"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="matches($date, '^\d{4}-\d{2}')">
                    <xsl:variable name="newDate" select="concat($date, '-01')"/>
                    <xsl:choose>
                        <xsl:when test="$newDate castable as xs:date">
                            <xsl:value-of select="xs:date($newDate)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$newDate"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$date"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:try select="format-date(xs:date($formatDate), '[M]-[D]-[Y]')">
            <xsl:catch select="concat('ERROR: invalid date.', $formatDate)"/>
        </xsl:try>
    </xsl:function>

    <!-- Find start date -->
    <xsl:function name="local:startDate">
        <xsl:param name="date"/>
        <xsl:choose>
            <xsl:when test="$date[@type = 'circa'] or contains($date, 'circa')">
                <xsl:if test="$date[@notBefore] and $date[@notAfter]">
                    <xsl:value-of select="local:formatDate($date/@notBefore)"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$date[@when]">
                <xsl:value-of select="local:formatDate($date/@when)"/>
            </xsl:when>
            <xsl:when test="$date[@from] and $date[@to]">
                <xsl:value-of select="local:formatDate($date/@from)"/>
            </xsl:when>
            <xsl:when test="$date[@notBefore] and $date[@notAfter]">
                <xsl:value-of select="local:formatDate($date/@notBefore)"/>
            </xsl:when>
            <xsl:when test="$date[@notBefore] and $date[@to]">
                <xsl:value-of select="local:formatDate($date/@notBefore)"/>
            </xsl:when>
            <xsl:when test="$date[@from] and $date[@notAfter]">
                <xsl:value-of select="local:formatDate($date/@from)"/>
            </xsl:when>
            <xsl:when test="$date[@notAfter]"/>
            <xsl:when test="$date[@notBefore]">
                <xsl:value-of select="local:formatDate($date/@notBefore)"/>
            </xsl:when>
            <xsl:when test="$date[@to]"/>
            <xsl:when test="$date[@from]">
                <xsl:value-of select="local:formatDate($date/@from)"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    <!-- Find end date -->
    <xsl:function name="local:endDate">
        <xsl:param name="date"/>
        <xsl:choose>
            <xsl:when test="$date[@type = 'circa'] or contains($date, 'circa')">
                <xsl:if test="$date[@notBefore] and $date[@notAfter]">
                    <xsl:value-of select="local:formatDate($date/@notAfter)"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$date[@when]"/>
            <xsl:when test="$date[@from] and $date[@to]">
                <xsl:value-of select="local:formatDate($date/@to)"/>
            </xsl:when>
            <xsl:when test="$date[@notBefore] and $date[@notAfter]">
                <xsl:value-of select="local:formatDate($date/@notAfter)"/>
            </xsl:when>
            <xsl:when test="$date[@notBefore] and $date[@to]">
                <xsl:value-of select="local:formatDate($date/@to)"/>
            </xsl:when>
            <xsl:when test="$date[@from] and $date[@notAfter]">
                <xsl:value-of select="local:formatDate($date/@notAfter)"/>
            </xsl:when>
            <xsl:when test="$date[@notAfter]">
                <xsl:value-of select="local:formatDate($date/@notAfter)"/>
            </xsl:when>
            <xsl:when test="$date[@notBefore]"/>
            <xsl:when test="$date[@to]">
                <xsl:value-of select="local:formatDate($date/@to)"/>
            </xsl:when>
            <xsl:when test="$date[@from]"/>
        </xsl:choose>
    </xsl:function>
    <!-- Establish the URI for the following node used by links -->
    <xsl:function name="local:getFollowingID">
        <xsl:param name="label"/>
        <xsl:variable name="following" select="$label/following-sibling::*[1]"/>
        <xsl:variable name="currentEnd">
            <xsl:choose>
                <xsl:when test="local:endDate($label/tei:date) != ''">
                    <xsl:value-of select="tokenize(local:endDate($label/tei:date), '-')[last()]"/>
                </xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="nextStart">
            <xsl:choose>
                <xsl:when test="local:startDate($following/tei:date) != ''">
                    <xsl:value-of select="tokenize(local:startDate($following/tei:date), '-')[last()]"/>
                </xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$following/tei:date[@type = 'circa'] or contains($following/tei:date, 'circa')">
                <xsl:if test="$following/tei:date[@notBefore] and $following/tei:date[@notAfter]">
                    <xsl:value-of select="concat(replace(generate-id($following/tei:date/@notBefore), '\.', ''), 'c')"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$following/tei:date[@notBefore] and $following/tei:date[@to]">
                <xsl:value-of select="replace(generate-id($following/tei:date/@to), '\.', '')"/>
            </xsl:when>
            <xsl:when test="$following/tei:date[@from] and $following/tei:date[@notAfter]">
                <xsl:value-of select="replace(generate-id($following/tei:date/@from), '\.', '')"/>
            </xsl:when>
            <xsl:when test="$following/tei:date[@when]">
                <xsl:value-of select="replace(generate-id($following/tei:date/@when), '\.', '')"/>
            </xsl:when>
            <xsl:when test="$following/tei:date[@from] and $following/tei:date[@to]">
                <xsl:choose>
                    <xsl:when test="$nextStart lt $currentEnd">
                        <xsl:value-of select="replace(generate-id($following/tei:date/@to), '\.', '')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="replace(generate-id($following/tei:date/@from), '\.', '')"/>        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$following/tei:date[@notBefore] and $label/tei:date[@notAfter]">
                <xsl:choose>
                    <xsl:when test="$nextStart lt $currentEnd">
                        <xsl:value-of select="replace(generate-id($following/tei:date/@notAfter), '\.', '')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="replace(generate-id($following/tei:date/@notBefore), '\.', '')"/>        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$following/tei:date[@notBefore] and $label/tei:date[@to]">
                <xsl:choose>
                    <xsl:when test="$nextStart lt $currentEnd">
                        <xsl:value-of select="replace(generate-id($following/tei:date/@to), '\.', '')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="replace(generate-id($following/tei:date/@notBefore), '\.', '')"/>        
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$following/tei:date[@notAfter] and $label/tei:date[@from]">
                <xsl:value-of select="replace(generate-id($following/tei:date/@from), '\.', '')"/>
            </xsl:when>
            <xsl:when test="$following/tei:date[@from]">
                <xsl:value-of select="replace(generate-id($following/tei:date/@from), '\.', '')"/>
            </xsl:when>
            <xsl:when test="$following/tei:date[@to]">
                <xsl:value-of select="replace(generate-id($following/tei:date/@to), '\.', '')"/>
            </xsl:when>
            <xsl:when test="$following/tei:date[@notBefore]">
                <xsl:value-of
                    select="replace(generate-id($following/tei:date/@notBefore), '\.', '')"/>
            </xsl:when>
            <xsl:when test="$following/tei:date[@notAfter]">
                <xsl:value-of select="replace(generate-id($following/tei:date/@notAfter), '\.', '')"
                />
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="/">
        <!-- Output filename, currently based on input filename, will rename as needed -->
        <xsl:variable name="path" select="'json/'"/>
        <xsl:variable name="filename"
            select="replace(tokenize(document-uri(.), '/')[last()], '.xml', '.json')"/>
        <xsl:variable name="file" select="concat($path, $filename)"/>
        <!-- Output JSON document -->
        <xsl:result-document href="{$file}">
            <xsl:variable name="doc">
                <xsl:call-template name="xml2json"/>
            </xsl:variable>
            <!--            <test><xsl:call-template name="xml2json"/></test>-->

            <xsl:apply-templates mode="json" select="$doc"/>
        </xsl:result-document>
    </xsl:template>

    <xsl:template name="xml2json">
        <xsl:call-template name="nodes"/>
        <xsl:call-template name="links"/>
    </xsl:template>

    <!-- Format nodes -->
    <xsl:template name="nodes">
        <xsl:for-each select="//tei:event">
            <xsl:sort select="local:startDate(tei:label[@type='composition']/tei:date)" order="descending"/>
            <xsl:variable name="elevel" select="(position() * 10)"/>
            <xsl:variable name="eventTitle" select="normalize-space(string-join(tei:desc, ' '))"/>
            <xsl:for-each select="tei:label">
                <xsl:variable name="eventLabel">
                    <xsl:choose>
                        <xsl:when test="@type = 'event'">
                            <xsl:for-each select="following-sibling::tei:label">
                                <xsl:variable name="type" select="concat(upper-case(substring(@type, 1, 1)), substring(@type, 2))"/>
                                <xsl:value-of select="concat($type, ': ', normalize-space(.))"/>
                                <xsl:if test="position() != last()"><xsl:text>&lt;br \\/&gt;</xsl:text></xsl:if>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="type" select="concat(upper-case(substring(@type, 1, 1)), substring(@type, 2))"/>
                            <xsl:value-of select="concat($type, ': ', normalize-space(.))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="eventType" select="@type"/>
                <xsl:variable name="start">
                    <xsl:choose>
                        <xsl:when test="local:startDate(tei:date) != ''">
                            <xsl:value-of select="tokenize(local:startDate(tei:date), '-')[last()]"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="end">
                    <xsl:choose>
                        <xsl:when test="local:endDate(tei:date) != ''">
                            <xsl:value-of select="tokenize(local:endDate(tei:date), '-')[last()]"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="prevStart">
                    <xsl:choose>
                        <xsl:when test="local:startDate(preceding-sibling::*[1]/tei:date) != ''">
                            <xsl:value-of select="tokenize(local:startDate(preceding-sibling::*[1]/tei:date), '-')[last()]"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="prevEnd">
                    <xsl:choose>
                        <xsl:when test="local:endDate(preceding-sibling::*[1]/tei:date) != ''">
                            <xsl:value-of select="tokenize(local:endDate(preceding-sibling::*[1]/tei:date), '-')[last()]"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="prev">
                    <xsl:choose>
                        <xsl:when test="local:startDate(preceding-sibling::*[1]/tei:date) != ''">
                            <xsl:value-of select="substring(tokenize(local:startDate(preceding-sibling::*[1]/tei:date), '-')[last()], 1, 2)"/>
                        </xsl:when>
                        <xsl:when test="local:endDate(preceding-sibling::*[1]/tei:date) != ''">
                            <xsl:value-of select="substring(tokenize(local:endDate(preceding-sibling::*[1]/tei:date), '-')[last()], 1, 2)"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="level">
                    <xsl:choose>
                        <xsl:when test="not(preceding-sibling::tei:label)"><xsl:value-of select="$elevel"/></xsl:when>
                        <xsl:when test="$start != 0">
                            <xsl:choose>
                                <xsl:when test="$prevStart != 0">
                                    <xsl:choose>
                                        <xsl:when test="xs:integer($start) eq xs:integer($prevStart)">
                                            <xsl:value-of select="$elevel + (position() * 2)"/>
                                        </xsl:when>
                                        <xsl:when test="((xs:integer($start) - xs:integer($prevStart)) &lt; 50)">
                                            <xsl:value-of select="$elevel + (position() * 2)"/>
                                        </xsl:when>
                                        <xsl:when test="$prevEnd != 0">
                                            <xsl:choose>
                                                <xsl:when test="xs:integer($start) eq xs:integer($prevEnd)">
                                                    <xsl:value-of select="$elevel + (position() * 2)"/>
                                                </xsl:when>
                                                <xsl:when test="((xs:integer($start) - xs:integer($prevEnd)) &lt; 50)">
                                                    <xsl:value-of select="$elevel + (position() * 2)"/>
                                                </xsl:when>
                                                <xsl:otherwise><xsl:value-of select="$elevel"/></xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                        <xsl:otherwise><xsl:value-of select="$elevel"/></xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:when test="$prevEnd != 0">
                                    <xsl:choose>
                                        <xsl:when test="xs:integer($start) eq xs:integer($prevEnd)">
                                            <xsl:value-of select="$elevel + (position() * 2)"/>
                                        </xsl:when>
                                        <xsl:when test="((xs:integer($start) - xs:integer($prevEnd)) &lt; 50)">
                                            <xsl:value-of select="$elevel + (position() * 2)"/>
                                        </xsl:when>
                                        <xsl:otherwise><xsl:value-of select="$elevel"/></xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise><xsl:value-of select="$elevel"/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="$end != 0">
                            <xsl:choose>
                                <xsl:when test="$prevStart != 0">
                                    <xsl:choose>
                                        <xsl:when test="xs:integer($end) eq xs:integer($prevStart)">
                                            <xsl:value-of select="$elevel + (position() * 2)"/>
                                        </xsl:when>
                                        <xsl:when test="((xs:integer($end) - xs:integer($prevStart)) &lt; 50)">
                                            <xsl:value-of select="$elevel + (position() * 2)"/>
                                        </xsl:when>
                                        <xsl:otherwise><xsl:value-of select="$elevel"/></xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:when test="$prevEnd != 0">
                                    <xsl:choose>
                                        <xsl:when test="xs:integer($end) eq xs:integer($prevEnd)">
                                            <xsl:value-of select="$elevel + (position() * 2)"/>
                                        </xsl:when>
                                        <xsl:when test="((xs:integer($end) - xs:integer($prevEnd)) &lt; 50)">
                                            <xsl:value-of select="$elevel + (position() * 2)"/>
                                        </xsl:when>
                                        <xsl:otherwise><xsl:value-of select="$elevel"/></xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise><xsl:value-of select="$elevel"/></xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise><xsl:value-of select="$elevel"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="tei:date[@type = 'circa'] or contains(tei:date, 'circa')">
                        <xsl:if test="tei:date[@notBefore] and tei:date[@notAfter]">
                            <nodes>
                                <name><xsl:value-of select="$eventTitle"/></name>
                                <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                                <label><xsl:value-of select="$eventLabel"/></label>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <date><xsl:value-of select="local:formatDate(tei:date/@notBefore)"/></date>
                                <displayType>circa</displayType>
                                <display>none</display>
                                <position>start</position>
                                <level><xsl:value-of select="$level"/></level>
                                <id><xsl:value-of select="replace(generate-id(tei:date/@notBefore), '\.', '')"/></id>
                            </nodes>
                            <nodes>
                                <name><xsl:value-of select="$eventTitle"/></name>
                                <recid><xsl:value-of
                                        select="ancestor::tei:body/descendant::tei:idno[1]/text()"
                                    /></recid>
                                <label><xsl:value-of select="$eventLabel"/></label>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <date>
                                    <xsl:variable name="start" select="tokenize(string(local:formatDate(tei:date/@notBefore)), '-')[last()]"/>
                                    <xsl:variable name="end" select="tokenize(string(local:formatDate(tei:date/@notAfter)), '-')[last()]"/>
                                    <xsl:variable name="diff" select="((xs:double($end) - xs:double($start)) div 2) + xs:double($start)"/>
                                    <xsl:value-of select="concat('01-01-', $diff)"/>
                                </date>
                                <displayType>circa</displayType>
                                <display>point</display>
                                <position>center</position>
                                <level><xsl:value-of select="$level"/></level>
                                <id><xsl:value-of select="concat(replace(generate-id(tei:date/@notBefore), '\.', ''), 'c')"/></id>
                            </nodes>, <nodes>
                                <name><xsl:value-of select="$eventTitle"/></name>
                                <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                                <label><xsl:value-of select="$eventLabel"/></label>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <date><xsl:value-of select="local:formatDate(tei:date/@notAfter)"/></date>
                                <displayType>circa</displayType>
                                <display>none</display>
                                <position>end</position>
                                <level><xsl:value-of select="$level"/></level>
                                <id><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></id>
                            </nodes> ) </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@when]">
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@when)"/></date>
                            <displayType>point</displayType>
                            <display>point</display>
                            <position>start</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@when), '\.', '')"/></id>
                        </nodes>
                    </xsl:when>
                    <xsl:when test="tei:date[@from] and tei:date[@to]">
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@from)"/></date>
                            <displayType>range</displayType>
                            <display>start</display>
                            <position>start</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@from), '\.', '')"/></id>
                        </nodes>
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@to)"/></date>
                            <displayType>range</displayType>
                            <display>end</display>
                            <position>end</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@to), '\.', '')"/></id>
                        </nodes>
                    </xsl:when>
                    <xsl:when test="tei:date[@notBefore] and tei:date[@notAfter]">
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@notBefore)"/></date>
                            <displayType>between</displayType>
                            <display>start</display>
                            <position>start</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@notBefore), '\.', '')"/></id>
                        </nodes>
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@notAfter)"/></date>
                            <displayType>between</displayType>
                            <display>end</display>
                            <position>end</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></id>
                        </nodes>
                    </xsl:when>
                    <xsl:when test="tei:date[@notBefore] and tei:date[@to]">
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@notBefore)"/></date>
                            <displayType>before</displayType>
                            <display>none</display>
                            <position>start</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@notBefore), '\.', '')"/></id>
                        </nodes>
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@to)"/></date>
                            <displayType>before</displayType>
                            <display>end</display>
                            <position>end</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@to), '\.', '')"/></id>
                        </nodes>
                    </xsl:when>
                    <xsl:when test="tei:date[@from] and tei:date[@notAfter]">
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@from)"/></date>
                            <displayType>after</displayType>
                            <display>start</display>
                            <position>start</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@from), '\.', '')"/></id>
                        </nodes>
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@notAfter)"/></date>
                            <displayType>after</displayType>
                            <display>none</display>
                            <position>end</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></id>
                        </nodes>
                    </xsl:when>
                    <xsl:when test="tei:date[@notAfter]">
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date>
                                <xsl:variable name="date" select="tokenize(string(local:formatDate(tei:date/@notAfter)), '-')[last()]"/>
                                <xsl:variable name="diff" select="((xs:double($date) - 200))"/>
                                <xsl:value-of select="concat('01-01-', $diff)"/>
                                <!--<xsl:value-of select="format-date(xs:date(local:formatDate(tei:date/@notAfter)) - xs:yearMonthDuration('P200Y'),'[M]-[D]-[Y]')"/>-->
                            </date>
                            <displayType>none</displayType>
                            <display>none</display>
                            <position>start</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="concat(replace(generate-id(tei:date/@notAfter), '\.', ''),'c')"/></id>
                        </nodes>
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@notAfter)"/></date>
                            <displayType>notAfter</displayType>
                            <display>end</display>
                            <position>end</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></id>
                        </nodes>
                    </xsl:when>
                    <xsl:when test="tei:date[@notBefore]">
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@notBefore)"/></date>
                            <displayType>notBefore</displayType>
                            <display>start</display>
                            <position>start</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@notBefore), '\.', '')"/>
                            </id>
                        </nodes>
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date>
                                <xsl:variable name="date" select="tokenize(string(local:formatDate(tei:date/@notBefore)), '-')[last()]"/>
                                <xsl:variable name="diff" select="((xs:double($date) + 200))"/>
                                <xsl:value-of select="concat('01-01-', $diff)"/>
                            </date>
                            <displayType>notBefore</displayType>
                            <display>none</display>
                            <position>end</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="concat(replace(generate-id(tei:date/@notBefore), '\.', ''),'c')"/></id>
                        </nodes>
                    </xsl:when>
                    <xsl:when test="tei:date[@to]">
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@to)"/></date>
                            <displayType>to</displayType>
                            <display>end</display>
                            <position>end</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@to), '\.', '')"/></id>
                        </nodes>
                    </xsl:when>
                    <xsl:when test="tei:date[@from]">
                        <nodes>
                            <name><xsl:value-of select="$eventTitle"/></name>
                            <recid><xsl:value-of select="ancestor::tei:body/descendant::tei:idno[1]/text()"/></recid>
                            <label><xsl:value-of select="$eventLabel"/></label>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <date><xsl:value-of select="local:formatDate(tei:date/@from)"/></date>
                            <displayType>from</displayType>
                            <display>start</display>
                            <position>start</position>
                            <level><xsl:value-of select="$level"/></level>
                            <id><xsl:value-of select="replace(generate-id(tei:date/@from), '\.', '')"/></id>
                        </nodes>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="links">
        <xsl:for-each select="//tei:event">
            <xsl:variable name="eventTitle" select="normalize-space(string-join(tei:desc, ' '))"/>
            <xsl:for-each select="tei:label">
                <xsl:variable name="eventLabel" select="normalize-space(descendant::text())"/>
                <xsl:variable name="eventType" select="@type"/>
                <xsl:variable name="start">
                    <xsl:choose>
                        <xsl:when test="local:startDate(tei:date) != ''">
                            <xsl:value-of select="tokenize(local:startDate(tei:date), '-')[last()]"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="end">
                    <xsl:choose>
                        <xsl:when test="local:endDate(tei:date) != ''">
                            <xsl:value-of select="tokenize(local:endDate(tei:date), '-')[last()]"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="current">
                    <xsl:choose>
                        <xsl:when test="$end != 0"><xsl:value-of select="$end"/></xsl:when>
                        <xsl:otherwise><xsl:value-of select="$start"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="nextStart">
                    <xsl:choose>
                        <xsl:when test="local:startDate(following-sibling::*[1]/tei:date) != ''">
                            <xsl:value-of select="tokenize(local:startDate(following-sibling::*[1]/tei:date), '-')[last()]"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="nextEnd">
                    <xsl:choose>
                        <xsl:when test="local:endDate(following-sibling::*[1]/tei:date) != ''">
                            <xsl:value-of select="tokenize(local:endDate(following-sibling::*[1]/tei:date), '-')[last()]"/>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="id"
                    select="concat((count(parent::tei:event/preceding-sibling::*) + 1), (count(parent::tei:event/preceding-sibling::*) + 1))"/>
                <xsl:choose>
                    <xsl:when test="tei:date[@type = 'circa'] or contains(tei:date, 'circa')">
                        <xsl:if test="tei:date[@notBefore] and tei:date[@notAfter]">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@notBefore), '\.', '')"/></source>
                                <target><xsl:value-of select="concat(replace(generate-id(tei:date/@notBefore), '\.', ''), 'c')"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <linkType>dashed</linkType>
                            </links>
                            <links>
                                <source><xsl:value-of select="concat(replace(generate-id(tei:date/@notBefore), '\.', ''), 'c')"/></source>
                                <target><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <linkType>dashed</linkType>
                            </links>
                            <xsl:if test="local:getFollowingID(.) != ''">
                                <links>
                                    <source><xsl:value-of select="concat(replace(generate-id(tei:date/@notBefore), '\.', ''), 'c')"/></source>
                                    <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                    <eventType><xsl:value-of select="$eventType"/></eventType>
                                    <xsl:choose>
                                        <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                        <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                    </xsl:choose>
                                </links>
                            </xsl:if>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@when]">
                        <xsl:if test="local:getFollowingID(.) != ''">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@when), '\.', '')"/></source>
                                <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <xsl:choose>
                                    <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                    <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                </xsl:choose>
                            </links>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@from] and tei:date[@to]">
                        <links>
                            <source><xsl:value-of select="replace(generate-id(tei:date/@from), '\.', '')"/></source>
                            <target><xsl:value-of select="replace(generate-id(tei:date/@to), '\.', '')"/></target>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <linkType>solid</linkType>
                        </links>
                        <xsl:if test="local:getFollowingID(.) != ''">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@to), '\.', '')"/></source>
                                <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <xsl:choose>
                                    <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                    <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                </xsl:choose>
                            </links>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@notBefore] and tei:date[@notAfter]">
                        <links>
                            <source><xsl:value-of select="replace(generate-id(tei:date/@notBefore), '\.', '')"/></source>
                            <target><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></target>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <linkType>dashed</linkType>
                        </links>
                        <xsl:if test="local:getFollowingID(.) != ''">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></source>
                                <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <xsl:choose>
                                    <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                    <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                </xsl:choose>
                            </links>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@notBefore] and tei:date[@to]">
                        <links>
                            <source><xsl:value-of select="replace(generate-id(tei:date/@notBefore), '\.', '')"/></source>
                            <target><xsl:value-of select="replace(generate-id(tei:date/@to), '\.', '')"/></target>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <linkType>dashed</linkType>
                        </links>
                        <xsl:if test="local:getFollowingID(.) != ''">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@to), '\.', '')"/></source>
                                <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <xsl:choose>
                                    <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                    <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                </xsl:choose>
                            </links>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@notAfter] and tei:date[@from]">
                        <links>
                            <source><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></source>
                            <target><xsl:value-of select="replace(generate-id(tei:date/@from), '\.', '')"/></target>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <linkType>dashed</linkType>
                        </links>
                        <xsl:if test="local:getFollowingID(.) != ''">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@from), '\.', '')"/></source>
                                <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <xsl:choose>
                                    <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                    <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                </xsl:choose>
                            </links>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@notAfter]">
                        <links>
                            <source><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></source>
                            <target><xsl:value-of select="concat(replace(generate-id(tei:date/@notAfter), '\.', ''),'c')"/></target>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <linkType>fade-left</linkType>
                        </links>
                        <xsl:if test="local:getFollowingID(.) != ''">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@notAfter), '\.', '')"/></source>
                                <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <xsl:choose>
                                    <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                    <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                </xsl:choose>
                            </links>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@notBefore]">
                        <links>
                            <source><xsl:value-of select="replace(generate-id(tei:date/@notBefore), '\.', '')"/></source>
                            <target><xsl:value-of select="concat(replace(generate-id(tei:date/@notBefore), '\.', ''),'c')"/></target>
                            <eventType><xsl:value-of select="$eventType"/></eventType>
                            <linkType>fade-right</linkType>
                        </links>
                        <xsl:if test="local:getFollowingID(.) != ''">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@notBefore), '\.', '')"/></source>
                                <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <xsl:choose>
                                    <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                    <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                </xsl:choose>
                            </links>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@to]">
                        <xsl:if test="local:getFollowingID(.) != ''">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@to), '\.', '')"/></source>
                                <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <xsl:choose>
                                    <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                    <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                </xsl:choose>
                            </links>
                        </xsl:if>
                    </xsl:when>
                    <xsl:when test="tei:date[@from]">
                        <xsl:if test="local:getFollowingID(.) != ''">
                            <links>
                                <source><xsl:value-of select="replace(generate-id(tei:date/@from), '\.', '')"/></source>
                                <target><xsl:value-of select="local:getFollowingID(.)"/></target>
                                <eventType><xsl:value-of select="$eventType"/></eventType>
                                <xsl:choose>
                                    <xsl:when test="$nextStart lt $current"><linkType>solidNoArrow</linkType></xsl:when>
                                    <xsl:otherwise><linkType>solid</linkType></xsl:otherwise>
                                </xsl:choose>
                            </links>
                        </xsl:if>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>

    <!-- JSON -->
    <xsl:template match="/" mode="json">
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="." mode="detect"/>
        <xsl:text>}</xsl:text>
    </xsl:template>

    <xsl:template match="*" mode="detect">
        <xsl:choose>
            <xsl:when
                test="name(preceding-sibling::*[1]) = name(current()) and name(following-sibling::*[1]) != name(current())">
                <xsl:apply-templates select="." mode="obj-content"/>
                <xsl:text>]</xsl:text>
                <xsl:if test="count(following-sibling::*[name() != name(current())]) &gt; 0">,
                </xsl:if>
            </xsl:when>
            <xsl:when test="name(preceding-sibling::*[1]) = name(current())">
                <xsl:apply-templates select="." mode="obj-content"/>
                <xsl:if test="name(following-sibling::*[1]) = name(current())">, </xsl:if>
            </xsl:when>
            <xsl:when test="following-sibling::*[1][name() = name(current())]">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>" : [</xsl:text>
                <xsl:apply-templates select="." mode="obj-content"/>
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:when test="count(./child::*) > 0 or count(@*) > 0">
                <xsl:text>"</xsl:text><xsl:value-of select="name()"/>" : <xsl:apply-templates
                    select="." mode="obj-content"/>
                <xsl:if test="count(following-sibling::*) &gt; 0">, </xsl:if>
            </xsl:when>
            <xsl:when test="count(./child::*) = 0">
                <xsl:text>"</xsl:text><xsl:value-of select="name()"/>" : "<xsl:apply-templates
                    select="normalize-space(.)"/><xsl:text>"</xsl:text>
                <xsl:if test="count(following-sibling::*) &gt; 0">, </xsl:if>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*" mode="obj-content">
        <xsl:text>{</xsl:text>
        <xsl:apply-templates select="@*" mode="attr"/>
        <xsl:if test="count(@*) &gt; 0 and (count(child::*) &gt; 0 or text())">, </xsl:if>
        <xsl:apply-templates select="./*" mode="detect"/>
        <xsl:if test="count(child::*) = 0 and text() and not(@*)">
            <xsl:text>"</xsl:text><xsl:value-of select="name()"/>" : "<xsl:value-of select="text()"
            /><xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:if test="count(child::*) = 0 and text() and @*">
            <xsl:text>"text" : "</xsl:text>
            <xsl:value-of select="text()"/>
            <xsl:text>"</xsl:text>
        </xsl:if>
        <xsl:text>}</xsl:text>
        <xsl:if test="position() &lt; last()">, </xsl:if>
    </xsl:template>

    <xsl:template match="@*" mode="attr">
        <xsl:text>"</xsl:text><xsl:value-of select="name()"/>" : "<xsl:value-of select="."/><xsl:text>"</xsl:text>
        <xsl:if test="position() &lt; last()">,</xsl:if>
    </xsl:template>

    <xsl:template match="node/@TEXT | text()" name="removeBreaks">
        <xsl:param name="pText" select="normalize-space(.)"/>
        <xsl:copy-of select="$pText"/>
    </xsl:template>
</xsl:stylesheet>
