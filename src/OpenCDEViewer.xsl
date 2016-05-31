<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    File: Preferences.xsd
    Created: April 2016
    Authors: Rafael Rosa / Martí Pàmies
    Description: OpenCDE Viewer XSLT, to render input CDA.xml to HTML. 
                 Goals:
                 - Maintain XSLT version 1.0
                 - Render narrative block by using HL7 cda.xsl code but adding:
                    - PDF at nonXML body as base 64
                    - Embedded base64 images
                    - Embedded bas64 html texts
                 - Include external preferences.xml file to configure features
                 - Include documentslist.xml to display documents relations notifications
                 - Add a custom.css reference to output html, to allow user defined styles
-->
<!--
 Licensed to Clinical Document Engineering (CDE) under one or more
 contributor license agreements.  See the NOTICE file distributed with
 this work for additional information regarding copyright ownership.
 CDE licenses this file to You under the Apache License, Version 2.0
 (the "License"); you may not use this file except in compliance with
 the License.  You may obtain a copy of the License at
      http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:n1="urn:hl7-org:v3"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
    xmlns:in="urn:lantana-com:inline-variable-data" 
    xmlns:opencde="http://clinicaldocumentengineering.com/OpenCDE" >

    <xsl:output method="html" doctype-system="about:legacy-compat" />

    <!-- OpenCDE Viewer Preferences file variable -->
    <xsl:variable name="Preferences" select="document('./config/Preferences.xml')"/>
    
    <!-- OpenCDE related documents list variable -->
    <xsl:variable name="DocumentsList" select="document('./config/DocumentsList.xml')"/>
    
    <!-- Set Header fixed col with param -->
    <xsl:variable name="HeaderFixedColWidth">20%</xsl:variable>
    <xsl:variable name="lc" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uc" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

    <!-- urlencode variables, to encode DICOM Wado URL -->
    <xsl:variable name="ascii"> !"#$%&amp;'()*+,-./0123456789:;&lt;=&gt;?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~</xsl:variable>
    <xsl:variable name="latin1">&#160;&#161;&#162;&#163;&#164;&#165;&#166;&#167;&#168;&#169;&#170;&#171;&#172;&#173;&#174;&#175;&#176;&#177;&#178;&#179;&#180;&#181;&#182;&#183;&#184;&#185;&#186;&#187;&#188;&#189;&#190;&#191;&#192;&#193;&#194;&#195;&#196;&#197;&#198;&#199;&#200;&#201;&#202;&#203;&#204;&#205;&#206;&#207;&#208;&#209;&#210;&#211;&#212;&#213;&#214;&#215;&#216;&#217;&#218;&#219;&#220;&#221;&#222;&#223;&#224;&#225;&#226;&#227;&#228;&#229;&#230;&#231;&#232;&#233;&#234;&#235;&#236;&#237;&#238;&#239;&#240;&#241;&#242;&#243;&#244;&#245;&#246;&#247;&#248;&#249;&#250;&#251;&#252;&#253;&#254;&#255;</xsl:variable>

    <!-- Characters that usually don't need to be escaped -->
    <xsl:variable name="safe">!'()*-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~</xsl:variable>

    <xsl:variable name="hex" >0123456789ABCDEF</xsl:variable>

    <!-- removes the following characters, in addition to line breaks "':;?`{}“”„‚’ -->
    <xsl:variable name="simple-sanitizer-match"><xsl:text>&#10;&#13;&#34;&#39;&#58;&#59;&#63;&#96;&#123;&#125;&#8220;&#8221;&#8222;&#8218;&#8217;</xsl:text></xsl:variable>
    <xsl:variable name="simple-sanitizer-replace" select="'***************'"/>
    <xsl:variable name="javascript-injection-warning">WARNING: Javascript injection attempt detected in source CDA document. Terminating</xsl:variable>
    <xsl:variable name="malicious-content-warning">WARNING: Potentially malicious content found in CDA document.</xsl:variable>

    <!-- global variable document/code/@code, to be used when looking for each type of document preferences -->
    <xsl:variable name="DocumentCode">
        <xsl:value-of select="/n1:ClinicalDocument/n1:code/@code"/>
    </xsl:variable>
    <!-- global variable document/code/@codeSystem -->
    <xsl:variable name="DocumentCodeCodeSystem">
        <xsl:value-of select="/n1:ClinicalDocument/n1:code/@codeSystem"/>
    </xsl:variable>

    <!-- global variable title -->
    <xsl:variable name="title">
        <xsl:choose>
            <xsl:when test="string-length(/n1:ClinicalDocument/n1:title)  &gt;= 1">
                <xsl:value-of select="/n1:ClinicalDocument/n1:title"/>
            </xsl:when>
            <xsl:when test="/n1:ClinicalDocument/n1:code/@displayName">
                <xsl:value-of select="/n1:ClinicalDocument/n1:code/@displayName"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Clinical Document</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
	
	<!-- Global varibale current document ID (to search for documents relations) -->
    <xsl:variable name="id">
        <xsl:choose>
            <xsl:when test="/n1:ClinicalDocument/n1:id/@extension">
                <xsl:value-of select="/n1:ClinicalDocument/n1:id/@extension"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>ID</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    <!-- global variable Structured body or nonXMLBody, to decide who to display CDA body -->
    <xsl:variable name="structured">
        <xsl:choose>
            <xsl:when test="/n1:ClinicalDocument/n1:component/n1:nonXMLBody">
                <xsl:value-of select="'no'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'yes'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    
    <!-- MAIN template taht produce browser rendered, human readable clinical document -->
    <xsl:template match="n1:ClinicalDocument">
        <!-- <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html&gt;</xsl:text> -->
        <!--[if IE 8]> <html lang="en" class="ie8 no-js"> <![endif]-->
        <!--[if IE 9]> <html lang="en" class="ie9 no-js"> <![endif]-->
        <!--[if !IE]><!-->
        <html lang="en">
        <!--<![endif]-->
            <head>
                <meta content="text/html; charset=utf-8" http-equiv="Content-Type"/>
                <title>OpenCDE Viewer | <xsl:value-of select="$title"/></title>
                <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
                <meta content="width=device-width, initial-scale=1" name="viewport"/>
                <xsl:call-template name="addCSS"/>
            </head>
            <body>
                <xsl:attribute name="class">
                    <xsl:text>page-header-fixed</xsl:text>
                    <xsl:if test="$structured='no'"> page-full-width</xsl:if>
                </xsl:attribute>
                <!-- One line header summary -->
                <div class="page-header navbar navbar-fixed-top">
                    <div class="page-header-inner">
                        <div class="page-logo">
                            <img class="logo-default" alt="logo" src="./assets/img/OpenCDA_logo_grey.png" />
                        </div>
                        <a href="javascript:;" class="menu-toggler responsive-toggler" data-toggle="collapse" data-target=".navbar-collapse"></a>
                        <div class="info-top">
                            <div class="patient-document">
                                <xsl:call-template name="recordTargetTop"/>
                            </div>
                            <div class="title-document">
                                <xsl:call-template name="documentGeneralTop"/>
                            </div>
                            <div class="page-top">
                               <!-- DOC: Apply "search-form-expanded" right after the "search-form" class to have half expanded search box -->
                                <form class="search-form" method="GET">
                                    <div class="input-group">
                                        <input type="text" id="query_search" class="form-control input-sm" placeholder="Search..." name="query" />
                                        <span class="input-group-btn">
                                            <a href="javascript:;" class="btn submit tooltips" data-placement="bottom" data-original-title="Search"><i class="fa fa-search" ></i></a>
                                        </span>
                                    </div>
                                </form>
                                <div class="top-menu">
                                    <ul class="nav navbar-nav pull-right">

                                        <!-- Search for document relations -->
                                        <xsl:call-template name="search-realted-documents">
                                            <xsl:with-param name="documentIdRoot">
                                                <xsl:value-of select="/n1:ClinicalDocument/n1:id/@root"/>
                                            </xsl:with-param>
                                            <xsl:with-param name="documentIdExtension">
                                                <xsl:value-of select="/n1:ClinicalDocument/n1:id/@extension"/>
                                            </xsl:with-param>
                                        </xsl:call-template>

                                        <li>
                                            <a data-target="#collapseheader" data-toggle="collapse" class="btn btn-default tooltips" role="button" href="javascript:;" data-placement="bottom" data-original-title="view full header"><span><img src="./assets/img/header_btn.png" height="18px" width="18px" /></span></a>
                                        </li>
                                    </ul>                              
                                </div>
                            </div>
                        </div>                        
                    </div>
                </div>

                <!-- Main content (header collapsed + document body) -->
                <div class="page-container">
                    <!-- Full header (initally collapsed) -->
                    <div class="row full-header-view collapse" id="collapseheader">
                        <div id="fullheader" class="col-md-12">
                            <div class="portlet">
                                <div class="portlet-body">
                                    <div class="tabbable">
                                        <ul class="nav nav-tabs nav-tabs-lg">
                                           <li class="active">
                                              <a href="#header_sumary" data-toggle="tab">
                                              Header summary </a>
                                           </li>
                                           <li>
                                              <a href="#related_entities" data-toggle="tab">
                                              Related entities
                                              </a>
                                           </li>
                                           <li>
                                              <a href="#related_acts" data-toggle="tab">
                                              Related acts </a>
                                           </li>
                                        </ul>
                                        <div class="tab-content header-section">
                                            <div class="tab-pane active" id="header_sumary" role="tabpanel">
                                                <div class="row">
                                                    <div class="col-md-4 col-xs-12">
                                                        <h4><xsl:text>Patient</xsl:text></h4>
                                                        <xsl:call-template name="recordTarget"/>
                                                    </div>
                                                    <div class="col-md-4 col-xs-12">
                                                        <h4><xsl:text>Document</xsl:text></h4>
                                                        <xsl:call-template name="documentGeneral"/>
                                                    </div>
                                                    <div class="col-md-4 col-xs-6">
                                                        <h4>Legal authenticator</h4>
                                                        <xsl:call-template name="legalAuthenticator"/>
                                                    </div>
                                                    <div class="col-md-4 col-xs-6">
                                                        <h4>Custodian</h4>
                                                        <xsl:call-template name="custodian"/>
                                                    </div>

                                                </div>
                                            </div>
                                            <div class="tab-pane" id="related_entities" role="tabpanel">
                                                <div class="row">
                                                    <xsl:call-template name="author"/>
                                                    
                                                    <xsl:call-template name="authenticator"/>

                                                    
                                                    <xsl:call-template name="informationRecipient"/>  
 
                                                    
                                                    <xsl:call-template name="informant"/>  
                                                    
                                                    
                                                    <xsl:call-template name="dataEnterer"/>  
                                                    
                                                    
                                                    <xsl:call-template name="participant"/>  
                                                    
                                                </div>
                                            </div>

                                            <div class="tab-pane" id="related_acts" role="tabpanel">
                                                <div class="row">
                                                    
                                                        <xsl:call-template name="documentationOf"/>
                                                    
                                                        <xsl:call-template name="componentof"/>
                                                     
                                                        <xsl:call-template name="inFulfillmentOf"/>
                                                   
                                                        <xsl:call-template name="authorization"/>

                                                </div>
                                            </div>

                                        </div>
                                    </div>
                                </div>                      
                            </div>
                        </div>
                    </div>
                                    <!-- END display top portion of clinical document -->

                    <!-- If document is structured include sections tree -->
                    <xsl:if
                        test="$structured='yes'">
                        <div id="sidebar-menu" class="page-sidebar-wrapper">
                            <div id="section-navbar" class="page-sidebar navbar-collapse collapse">
                                <div class="sidebar-toggler"><i class="fa fa-backward tooltips" data-placement="bottom" data-original-title="Minimize menu"></i><i class="fa fa-forward tooltips" data-placement="bottom" data-original-title="Maximize menu"></i></div>
                                <xsl:call-template name="make-tableofcontents"/>
                            </div>
                        </div>                        
                    </xsl:if>
                    
                    <!-- Main narrative body content -->
                    <div class="page-content-wrapper">
                        <div class="page-content">
                            <!-- Test if document is structured or not -->
                            <xsl:choose>
                                <!-- structured case -->
                                <xsl:when test="$structured='yes'">
                                    <div class="page-content-toggler">
                                        <xsl:if test="$Preferences/opencde:Preferences
                                                                    /opencde:DocumentsCodesPreferences[@code=$DocumentCode and @codeSystem=$DocumentCodeCodeSystem]
                                                                    /opencde:DocumentCodeInitialSections">
                                            <i class="fa fa-bars summary" data-toggle="tooltip" title="Sections summary"></i>
                                        </xsl:if>
                                        
                                        <i class="fa fa-caret-square-o-down expandall tooltips" data-placement="bottom" data-original-title="Expand all"></i>
                                        <i class="fa fa-caret-square-o-up collapseall tooltips" data-placement="bottom" data-original-title="Colapse all"></i>
                                    </div>
                                    <div id="accordio" class="panel-group">
                                        <xsl:call-template name="make-contents"/>
                                    </div>
                                </xsl:when>
                                <!-- non structrued (PDF B64) -->
                                <xsl:otherwise>
                                    <div id="nonxml" class="panel-group">
                                        <xsl:call-template name="nonXMLBody-contents"/>
                                    </div>
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>
                    </div>
                </div>
                
                <!-- page footer -->
                <div class="page-footer">
                    <div class="page-footer-inner">
                         2016 &#169; OpenCDE Viewer by ClinicalDocumentEngineering.com
                    </div>
                    <div class="scroll-to-top">
                        <i class="fa fa-arrow-up"></i>
                    </div>
                </div>
                
                <!-- Add java scripts to enrich output HTML -->
                <xsl:call-template name="addJSScripts"/>
            </body>
            
        </html>
    </xsl:template>
    
    
    <!-- generate table of contents (sections tree) -->
    <xsl:template name="make-tableofcontents">
        
        <ul class="page-sidebar-menu nav" data-keep-expanded="false" data-auto-scroll="false" data-slide-speed="200">
            <xsl:for-each select="n1:component/n1:structuredBody/n1:component/n1:section">
                <xsl:choose>
                    <!-- Case section is a C-CDA DICOM Object catalog section -->
                    <xsl:when test="n1:templateId[@root='2.16.840.1.113883.10.20.6.1.1']">
                        <li>
                            <a href="#{translate(concat(n1:code/@code,n1:code/@codeSystem),'.','')}" title="DICOM" role="dicom">
                                <i class="fh fh-121181" ></i>
                                <span class="title"><b>DICOM</b></span>
                                <span class="arrow "></span>
                            </a>
                            <xsl:call-template name="make-dicom-tree">
                                <xsl:with-param name="contentDicom" select="."/>
                            </xsl:call-template>
                        </li>  
                    </xsl:when>
                    <!-- Case section is NOT a DICOM section -->
                    <xsl:otherwise>
                        <li>
                            <a  href="#{translate(concat(n1:code/@code,n1:code/@codeSystem),'.','')}">
                                <i>
                                        <xsl:attribute name="class">
                                            <xsl:value-of select="concat('fh fh-',n1:code/@code)"/>
                                        </xsl:attribute>
                                </i>
                                <span class="title"> <xsl:value-of select="./n1:title"/></span>
                                <xsl:if test="./n1:component/n1:section">
                                    <span class="arrow "></span>
                                </xsl:if>
                            </a>
                            <!-- Search for nested sections -->
                            <xsl:if test="./n1:component/n1:section">
                                <ul class="sub-menu">
                                    <xsl:for-each select="./n1:component/n1:section">
                                        <xsl:call-template name="nested-section-table-contents">
                                            <xsl:with-param name="childSection" select="."/>
                                        </xsl:call-template>
                                    </xsl:for-each>
                                </ul>
                            </xsl:if>
                        </li>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    <!-- Build nestion section, section tree -->
    <xsl:template name="nested-section-table-contents">
        <xsl:param name="childSection"></xsl:param>
        <li>
            <a href="#{translate(concat($childSection/n1:code/@code,$childSection/n1:code/@codeSystem),'.','')}">
                <i>                    
                    <xsl:attribute name="class">
                        <xsl:value-of select="concat('fh fh-',n1:code/@code)"/>
                    </xsl:attribute>
                </i>
                <span class="title">&#160;<xsl:value-of select="$childSection/n1:title"/></span>
            
            <xsl:if test="$childSection/n1:component/n1:section">
                <span class="arrow"></span>
            </xsl:if>
            </a>
            <!-- Nested sections -->
            <xsl:if test="$childSection/n1:component/n1:section">
                <ul class="sub-menu">
                <xsl:for-each select="$childSection/n1:component/n1:section">
                    <xsl:call-template name="nested-section-table-contents">
                        <xsl:with-param name="childSection" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
                </ul>
            </xsl:if>
        </li>
    </xsl:template>

    <xsl:template name="make-contents">
        <xsl:for-each select="n1:component/n1:structuredBody/n1:component/n1:section">
            <xsl:choose>
                <xsl:when test="n1:templateId[@root='2.16.840.1.113883.10.20.6.1.1']">
                    <xsl:call-template name="dicom-section">
                        <xsl:with-param name="contentDicom" select="."/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    
                    <xsl:call-template name="content-section">
                        <!-- <xsl:with-param name="content" select="."/> -->
                    </xsl:call-template>
    
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

   <!-- Top level component/section: display title and text,
        and process any nested component/sections
   -->
    <xsl:template name="content-section">
       <!--  <xsl:param name="content"></xsl:param> -->
        <div id="{translate(concat(n1:code/@code,n1:code/@codeSystem),'.','')}" class="panel section-info">
            <div class="panel-heading">
                <h4 class="panel-title">
                    <a class="accordion-toggle" for="panel_{generate-id(n1:title)}" data-toggle="collapse" href="#panel_{generate-id(n1:title)}" aria-expanded="true" aria-controls="panel_{generate-id(n1:title)}">
                        <i>
                            <xsl:attribute name="class">
                                <xsl:value-of select="concat('fh fh-',n1:code/@code)"/>
                            </xsl:attribute>
                        </i>&#160;
                        <xsl:value-of select="n1:title"/>
                    </a>
                </h4>
            </div>
            <div id="panel_{generate-id(n1:title)}" class="panel-collapse collapse in">
                <div class="panel-body">

                    <p><xsl:call-template name="section-text"/></p>
                    <author><xsl:call-template name="section-author"/></author>

                    <!-- Test if section has a related section defined -->
                    <xsl:variable name="SectionCode">
                        <xsl:value-of select="n1:code/@code"/>
                    </xsl:variable>
                    <xsl:variable name="SectionCodeCodeSystem">
                        <xsl:value-of select="n1:code/@codeSystem"/>
                    </xsl:variable>
                    <xsl:if test="$Preferences/opencde:Preferences
                                                                /opencde:DocumentsCodesPreferences[@code=$DocumentCode and @codeSystem=$DocumentCodeCodeSystem]
                                                                /opencde:SectionsRelations
                                                                /opencde:SectionRelation
                                                                /opencde:SourceSection[@code=$SectionCode and @codeSystem=$SectionCodeCodeSystem]">
                            <p><i class="fa fa-external-link"></i> &#160;
                            <a data-toggle="section" href="#{translate(concat($Preferences/opencde:Preferences
                                                                            /opencde:DocumentsCodesPreferences[@code=$DocumentCode and @codeSystem=$DocumentCodeCodeSystem]
                                                                            /opencde:SectionsRelations
                                                                            /opencde:SectionRelation
                                                                            [opencde:SourceSection[@code=$SectionCode and @codeSystem=$SectionCodeCodeSystem]]
                                                                            /opencde:TargetSection/@code,
                                              $Preferences/opencde:Preferences
                                                                            /opencde:DocumentsCodesPreferences[@code=$DocumentCode and @codeSystem=$DocumentCodeCodeSystem]
                                                                            /opencde:SectionsRelations
                                                                            /opencde:SectionRelation
                                                                            [opencde:SourceSection[@code=$SectionCode and @codeSystem=$SectionCodeCodeSystem]]
                                                                            /opencde:TargetSection/@codeSystem),'.','')}">
                                <xsl:value-of select="concat(' Related Section:',
                                                                $Preferences/opencde:Preferences
                                                                                        /opencde:DocumentsCodesPreferences[@code=$DocumentCode and @codeSystem=$DocumentCodeCodeSystem]
                                                                                        /opencde:SectionsRelations
                                                                                        /opencde:SectionRelation
                                                                                        [opencde:SourceSection[@code=$SectionCode and @codeSystem=$SectionCodeCodeSystem]]
                                                                                        /opencde:TargetSection/@displayName)"/>
                            </a>
                        </p>
                    </xsl:if>
                    <xsl:for-each select="n1:component/n1:section">
                        <xsl:call-template name="nestedSection-content">
                            <xsl:with-param name="margin" select="0"/>
                            <xsl:with-param name="childSection" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                </div>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="nestedSection-content">
        <xsl:param name="childSection"></xsl:param>
        <xsl:param name="margin"></xsl:param>
        <xsl:param name="parentPosition"></xsl:param>
        <xsl:variable name="nodePosition">
            <xsl:choose>
                <xsl:when test="$parentPosition!=''">
                    <xsl:value-of select="concat($parentPosition,'.',position())"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="position()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <div id="{translate(concat($childSection/n1:code/@code,$childSection/n1:code/@codeSystem),'.','')}" class="panel section-info" style="margin-left : {$margin}em;">
            <div class="panel-body section-info">
                <h4><xsl:value-of select="$nodePosition"/>&#160;
                    <i>
                        <xsl:attribute name="class">
                            <xsl:value-of select="concat('fh fh-',$childSection/n1:code/@code)"/>
                        </xsl:attribute>
                    </i>&#160;
                    <xsl:value-of select="$childSection/n1:title"/></h4>
                <p><xsl:call-template name="section-text"/></p>
                    <author><xsl:call-template name="section-author"/></author>
            </div>
        </div>
        <xsl:for-each select="n1:component/n1:section">
            <xsl:call-template name="nestedSection-content">
                <xsl:with-param name="margin" select="$margin+2"/>
                <xsl:with-param name="childSection" select="."/>
                <xsl:with-param name="parentPosition" select="$nodePosition"/>
            </xsl:call-template>
        </xsl:for-each>
        
    </xsl:template>

    <!-- generate DICOM section -->
    <xsl:template name="dicom-section">
        <xsl:param name="contentDicom"/>
        <div id="12118112840100082164" class="panel section-info">
           <div class="panel-heading">
              <h4 class="panel-title"><a class="accordion-toggle" data-toggle="collapse"  href="#accordion1_d0e540"><i class="fh fh-121181"></i>
                    DICOM</a></h4>
           </div>
           <div id="accordion1_d0e540" class="panel-collapse collapse in">
              <div class="panel-body">
                 
              </div>
           </div>
        </div>
    </xsl:template>
    
    <!-- generate DICOM tree (Study/Serie/SOP) -->
    <xsl:template name="make-dicom-tree">
        <xsl:param name="contentDicom"/>
        
        <!-- Get Studys -->
        <xsl:for-each select="$contentDicom
                                    [n1:templateId[@root='2.16.840.1.113883.10.20.6.1.1']]
                                    /n1:entry/n1:act[n1:templateId[@root='2.16.840.1.113883.10.20.6.2.6']]">
            <ul class="sub-menu">
                <li>        
                    <a class="tooltips" >
                        <xsl:attribute name="data-original-title">
                            <xsl:value-of select="n1:id/@root"/>
                        </xsl:attribute>
                         <span class="title">
                            <xsl:call-template name="show-time">
                                <xsl:with-param name="datetime" select="n1:effectiveTime"/>
                            </xsl:call-template>
                        </span>
                        <span class="arrow "></span>
                    </a>
                    <ul class="sub-menu">
                
                        <!-- Get Series -->
                        <xsl:for-each select="n1:entryRelationship/n1:act[n1:templateId[@root='2.16.840.1.113883.10.20.22.4.63']]">
                            <li>
                                <a>
                                    <xsl:attribute name="title">
                                        <xsl:value-of select="n1:id/@root"/>
                                    </xsl:attribute>
                               
                                    <span class="title">
                                        <xsl:value-of select="n1:code/n1:qualifier/n1:name/@displayName"/>
                                        <xsl:text>: </xsl:text>
                                        <xsl:value-of select="n1:code/n1:qualifier/n1:value/@displayName"/>
                                    </span>
                                    <span class="arrow "></span>
                                </a>
                    
                    
                                <ul class="sub-menu">
                                 <!-- Get SOP Instances -->
                                <xsl:for-each select="n1:entryRelationship/n1:observation[n1:templateId[@root='2.16.840.1.113883.10.20.6.2.8']]">

                                    <li>
                                        <!-- Test if DICOMViewer is configured -->
                                        <xsl:choose>
                                            <!-- YES Document Code Preferences Provided -->
                                            <xsl:when test="$Preferences/opencde:Preferences/opencde:DICOMViewer
                                                /opencde:ViewerType/text()='DWV'">
                                                <a class="dicom-url tooltips">
                                                    <xsl:attribute name="data-original-title">
                                                        <xsl:value-of select="n1:id/@root"/>
                                                    </xsl:attribute>
                                                    <xsl:attribute name="data-ident">
                                                        <xsl:value-of select="translate(n1:id/@root,'.','')"/>
                                                    </xsl:attribute>
                                                    <xsl:attribute name="href">
                                                        <xsl:variable name="url-sop">
                                                            <xsl:call-template name="url-encode">
                                                              <xsl:with-param name="str" select="n1:text/n1:reference/@value"/>
                                                            </xsl:call-template>
                                                        </xsl:variable>
                                                        <xsl:value-of select="concat($Preferences/opencde:Preferences/opencde:DICOMViewer
                                                                                        /opencde:ViewerParameters/opencde:Parameter[opencde:Name/text()='URL']/opencde:Value,
                                                                                        $url-sop,
                                                                                        '&amp;dwvReplaceMode=void')"/>                                                    
                                                    </xsl:attribute>
                                                    <i class="fh fh-eye"></i><span class="title">&#160;Image <xsl:value-of select="position()"/></span> 
                                                    
                                                </a>
                                            </xsl:when>
                                        <xsl:otherwise>
                                            <a data-toggle="tooltip">
                                                <xsl:attribute name="title">
                                                    <xsl:value-of select="n1:id/@root"/>
                                                </xsl:attribute>
                                                <xsl:attribute name="href">
                                                    <xsl:value-of select="n1:text/n1:reference/@value"/>
                                                </xsl:attribute>
                                                <span class="title">&#160;Image <xsl:value-of select="position()"/> </span>
                                            </a>
                                        </xsl:otherwise>
                                    </xsl:choose>

                                    </li>
                                </xsl:for-each>
                                </ul>
                            </li>
    
                        </xsl:for-each>

                    </ul>
                </li>
            </ul>
        </xsl:for-each>
    </xsl:template>

    <!-- 
        Based on DocumentsList.xml that contains the manes  of the CDA files at this
        location, search for document relations, both parent and child
    -->
    <xsl:template name="search-realted-documents">
        <xsl:param name="documentIdRoot"/>
        <xsl:param name="documentIdExtension"></xsl:param>
        
        <!-- Save parsed documents relatedDocumets, as context change when for each in DocumentsList -->
        <xsl:variable name="ParsedDocumentRelatedDocuments" select="/n1:ClinicalDocument/n1:relatedDocument"/>
        
        <!-- Search in all documents included in DocumentList.xml for a document 
             that contains a relations to current document -->
        <xsl:for-each select="$DocumentsList/opencde:DocumentsList/opencde:ClinicalDocument">
            <xsl:variable name="currentFileDocument">
                <xsl:value-of select="opencde:fileName"/>
            </xsl:variable>
            
            <!-- Test if parsed CDA document is the parent of a relation included in a file document -->
            <xsl:variable name="parentRelationTypeCode">
                <xsl:value-of select="document($currentFileDocument)/n1:ClinicalDocument/n1:relatedDocument[n1:parentDocument
                    [n1:id[@root=$documentIdRoot and @extension=$documentIdExtension]]]/@typeCode"/> 
            </xsl:variable>
            <xsl:variable name="relatedDocumentTitle">
                <xsl:choose>
                    <xsl:when test="string-length(document($currentFileDocument)/n1:ClinicalDocument/n1:title)  &gt;= 1">
                        <xsl:value-of select="document($currentFileDocument)/n1:ClinicalDocument/n1:title"/>
                    </xsl:when>
                    <xsl:when test="document($currentFileDocument)/n1:ClinicalDocument/n1:code/@displayName">
                        <xsl:value-of select="document($currentFileDocument)/n1:ClinicalDocument/n1:code/@displayName"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>Clinical Document</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="relatedDocumentEffectiveTime">
                <xsl:call-template name="show-time">
                    <xsl:with-param name="datetime" select="document($currentFileDocument)/n1:ClinicalDocument/n1:effectiveTime"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:if test="$parentRelationTypeCode">
                <xsl:choose>
                    <xsl:when test="$parentRelationTypeCode='XFRM'">
                        <li>
                            <a type="text/xml" role="button" class="btn btn-default tooltips" data-placement="bottom" data-original-title="View document transformation">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$currentFileDocument"/>
                                </xsl:attribute>
                                <span><i class="fa fa-file-pdf-o"></i></span>
                            </a>
                        </li>
                    </xsl:when>
                    <xsl:when test="$parentRelationTypeCode='APND'">

                        <li>
                            <a type="text/xml" role="button" class="btn btn-default tooltips" data-placement="bottom" data-original-title="Document addendumed" data-toogle="addendum">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$currentFileDocument"/>
                                </xsl:attribute>
                                <xsl:attribute name="title">
                                    <xsl:value-of select="$relatedDocumentTitle"/>
                                </xsl:attribute>
                                <xsl:attribute name="data-time">
                                    <xsl:value-of select="$relatedDocumentEffectiveTime"/>
                                </xsl:attribute>
                                <span><i class="fa fa-thumb-tack"></i></span>
                            </a>
                        </li>
                    </xsl:when>
                    <xsl:when test="$parentRelationTypeCode='RPLC'">
                        <li>
                            <a type="text/xml" role="button" class="btn btn-default tooltips" data-placement="bottom" data-original-title="View new document version">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$currentFileDocument"/>
                                </xsl:attribute>
                                <span><i class="fa fa-history"></i></span>
                            </a>
                        </li>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
            
            
            <!-- Test if document id in the file document is the parent of a relation included in parsed CDA  -->
            <!-- Get file document ID -->
            <xsl:variable name="FileDocumentIdRoot">
                <xsl:value-of select="document($currentFileDocument)/n1:ClinicalDocument/n1:id/@root"/>
            </xsl:variable>
            <xsl:variable name="FileDocumentIdExtension">
                <xsl:value-of select="document($currentFileDocument)/n1:ClinicalDocument/n1:id/@extension"/>
            </xsl:variable>
            <!-- Test if is include in a relation in parsed CDA -->
            <xsl:variable name="childRelationTypeCode">
                <xsl:value-of select="$ParsedDocumentRelatedDocuments[n1:parentDocument
                    [n1:id[@root=$FileDocumentIdRoot and @extension=$FileDocumentIdExtension]]]/@typeCode"/>
            </xsl:variable>
            <xsl:if test="$childRelationTypeCode">
                <xsl:choose>
                    <xsl:when test="$childRelationTypeCode='XFRM'">
                        <li>
                            <a type="text/xml" role="button" class="btn btn-default tooltips" data-placement="bottom" data-original-title="View transformed document">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$currentFileDocument"/>
                                </xsl:attribute>
                                <span><i class="fa fa-file-pdf-o"></i></span>
                            </a>
                        </li>
                    </xsl:when>
                    <xsl:when test="$childRelationTypeCode='APND'">
                        <li>
                            <a type="text/xml" role="button" class="btn btn-danger tooltips" data-placement="bottom" data-original-title="View addendumed document">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$currentFileDocument"/>
                                </xsl:attribute>
                                <span><i class="fa fa-thumb-tack fa-inverse"></i></span>
                            </a>
                        </li>
                    </xsl:when>
                    <xsl:when test="$childRelationTypeCode='RPLC'">
                        <li>
                            <a type="text/xml" role="button" class="btn btn-default tooltips" data-placement="bottom" data-original-title="View replaced document">
                                <xsl:attribute name="href">
                                    <xsl:value-of select="$currentFileDocument"/>
                                </xsl:attribute>
                                <span><i class="fa fa-history"></i></span>
                            </a>
                        </li>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- header elements -->
    <xsl:template name="documentGeneralTop">
        <h4><strong>
            <xsl:value-of select="$title"/>
        </strong></h4>
        <xsl:call-template name="show-time">
            <xsl:with-param name="datetime" select="n1:effectiveTime"/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template name="documentGeneral">
        <div class="col-md-12 col-xs-6">
            <strong>
                <i class="fa fa-barcode"></i><xsl:text> Document Id</xsl:text>
            </strong>
            <div class="info-head">       
                <xsl:call-template name="show-id">
                    <xsl:with-param name="id" select="n1:id"/>
                </xsl:call-template>
            </div>
            <strong>
                <i class="fa fa-calendar"></i><xsl:text> Document Created</xsl:text>
            </strong>
            <div class="info-head">
                <xsl:call-template name="show-time">
                    <xsl:with-param name="datetime" select="n1:effectiveTime"/>
                </xsl:call-template>
            </div>
        </div>
    </xsl:template>
    <!-- confidentiality -->
    <xsl:template name="confidentiality">
        <div class="col-xs-12">
            <strong>
                <i class="fa fa-flag"></i><xsl:text> Confidentiality</xsl:text>
            </strong>
            <div class="info-head">
                <xsl:choose>
                    <xsl:when test="n1:confidentialityCode/@code  = &apos;N&apos;">
                        <xsl:text>Normal</xsl:text>
                    </xsl:when>
                    <xsl:when test="n1:confidentialityCode/@code  = &apos;R&apos;">
                        <xsl:text>Restricted</xsl:text>
                    </xsl:when>
                    <xsl:when test="n1:confidentialityCode/@code  = &apos;V&apos;">
                        <xsl:text>Very restricted</xsl:text>
                    </xsl:when>
                </xsl:choose>
                <xsl:if test="n1:confidentialityCode/n1:originalText">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="n1:confidentialityCode/n1:originalText"/>
                </xsl:if>
            </div>
        </div>
    </xsl:template>
    <!-- author -->
    <xsl:template name="author">
        <xsl:if test="n1:author">
            <div class="col-md-4 col-xs-6">
                <h4>Author</h4>
                <div class="col-xs-12">
                <xsl:for-each select="n1:author/n1:assignedAuthor">
                    <div class="col-xs-6">
                    <strong>
                    <xsl:choose>
                        <xsl:when test="n1:assignedPerson/n1:name">
                            <xsl:call-template name="show-name">
                                <xsl:with-param name="name"
                                    select="n1:assignedPerson/n1:name"/>
                            </xsl:call-template>
                            <xsl:if test="n1:representedOrganization">
                                <xsl:text>, </xsl:text>
                                <xsl:call-template name="show-name">
                                    <xsl:with-param name="name"
                                      select="n1:representedOrganization/n1:name"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:when>
                        <xsl:when test="n1:assignedAuthoringDevice/n1:softwareName">
                            <xsl:value-of
                                select="n1:assignedAuthoringDevice/n1:softwareName"/>
                        </xsl:when>
                        <xsl:when test="n1:representedOrganization">
                            <xsl:call-template name="show-name">
                                <xsl:with-param name="name"
                                    select="n1:representedOrganization/n1:name"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="n1:id">
                                <xsl:call-template name="show-id"/>
                                <br/>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                    </strong>
                    <br />
                    <xsl:if test="n1:addr | n1:telecom">
                        <address>
                                <xsl:call-template name="show-contactInfo">
                                    <xsl:with-param name="contact" select="."/>
                                </xsl:call-template>
                        </address>
                    </xsl:if>
                    <br />
                    </div>
                </xsl:for-each>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!--  authenticator -->
    <xsl:template name="authenticator">
        <xsl:if test="n1:authenticator">
            <div class="col-md-4 col-xs-6">
                <h4>Authenticator</h4>
                <div class="col-xs-12">
                <xsl:for-each select="n1:authenticator">
                    <div class="col-xs-6">
                        <strong>
                            <i class="fa fa-pencil"></i><xsl:text> Signed</xsl:text>
                        </strong>
                        <div class="info-head">
                            <xsl:call-template name="show-name">
                                <xsl:with-param name="name"
                                    select="n1:assignedEntity/n1:assignedPerson/n1:name"/>
                            </xsl:call-template>
                            <xsl:text> at </xsl:text>
                            <xsl:call-template name="show-time">
                                <xsl:with-param name="datetime" select="n1:time"/>
                            </xsl:call-template>
                        </div>
                        <xsl:if test="n1:assignedEntity/n1:addr | n1:assignedEntity/n1:telecom">
                        <address>
                            <strong>
                                <xsl:text> Contact info</xsl:text>
                            </strong>
                            <div class="info-head">
                                <xsl:call-template name="show-contactInfo">
                                    <xsl:with-param name="contact" select="n1:assignedEntity"/>
                                </xsl:call-template>
                            </div>
                        </address>
                        </xsl:if>
                    </div>
                </xsl:for-each>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- legalAuthenticator -->
    <xsl:template name="legalAuthenticator">
        <xsl:if test="n1:legalAuthenticator">
            <div class="col-xs-12">
                <strong>
                    <xsl:call-template name="show-assignedEntity">
                        <xsl:with-param name="asgnEntity"
                            select="n1:legalAuthenticator/n1:assignedEntity"/>
                    </xsl:call-template>
                </strong>
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="show-sig">
                        <xsl:with-param name="sig"
                            select="n1:legalAuthenticator/n1:signatureCode"/>
                    </xsl:call-template>
                    <xsl:if test="n1:legalAuthenticator/n1:time/@value">
                        <xsl:text> at </xsl:text>
                        <xsl:call-template name="show-time">
                            <xsl:with-param name="datetime"
                                select="n1:legalAuthenticator/n1:time"/>
                        </xsl:call-template>
                    </xsl:if>
                <br />
                <xsl:if
                    test="n1:legalAuthenticator/n1:assignedEntity/n1:addr | n1:legalAuthenticator/n1:assignedEntity/n1:telecom">
                    
                            <xsl:call-template name="show-contactInfo">
                                <xsl:with-param name="contact"
                                    select="n1:legalAuthenticator/n1:assignedEntity"/>
                            </xsl:call-template>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- dataEnterer -->
    <xsl:template name="dataEnterer">
        <xsl:if test="n1:dataEnterer">
            <div class="col-md-4 col-xs-6">
                <h4>Data enterer</h4>
                <div class="col-xs-12">
                    <strong>
                        <xsl:call-template name="show-assignedEntity">
                            <xsl:with-param name="asgnEntity"
                                select="n1:dataEnterer/n1:assignedEntity"/>
                        </xsl:call-template>
                    </strong>
                    <br />
                       
                    <xsl:if
                        test="n1:dataEnterer/n1:assignedEntity/n1:addr | n1:dataEnterer/n1:assignedEntity/n1:telecom">
                        
                        <xsl:call-template name="show-contactInfo">
                            <xsl:with-param name="contact"
                                select="n1:dataEnterer/n1:assignedEntity"/>
                        </xsl:call-template>
                          
                    </xsl:if>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- componentOf -->
    <xsl:template name="componentof">
        <xsl:if test="n1:componentOf">
            <div class="col-md-4 col-xs-6">
                <h4>Component of</h4>
                <div class="col-xs-12">
                    <xsl:for-each select="n1:componentOf/n1:encompassingEncounter">
                        <div class="col-xs-6">
                            <dl>
                            <xsl:if test="n1:id">
                                <dt>
                                    <xsl:text>Encounter Id</xsl:text>
                                </dt>
                                <dd>
                                        <xsl:call-template name="show-id">
                                            <xsl:with-param name="id" select="n1:id"/>
                                        </xsl:call-template>
                                </dd>
                                    <xsl:if test="n1:code">
                                        <dt>
                                                    <xsl:text>Encounter Type</xsl:text>
                                        </dt>
                                        <dd>
                                                <xsl:call-template name="show-code">
                                                    <xsl:with-param name="code" select="n1:code"/>
                                                </xsl:call-template>
                                        </dd>
                                    </xsl:if>
                            </xsl:if>
                                <dt>
                                            <xsl:text>Encounter Date</xsl:text>
                                </dt>
                                <dd>
                                    <xsl:if test="n1:effectiveTime">
                                        <xsl:choose>
                                            <xsl:when test="n1:effectiveTime/@value">
                                                <xsl:text>&#160;at&#160;</xsl:text>
                                                <xsl:call-template name="show-time">
                                                    <xsl:with-param name="datetime"
                                                      select="n1:effectiveTime"/>
                                                </xsl:call-template>
                                            </xsl:when>
                                            <xsl:when test="n1:effectiveTime/n1:low">
                                                <xsl:text>&#160;From&#160;</xsl:text>
                                                <xsl:call-template name="show-time">
                                                    <xsl:with-param name="datetime"
                                                      select="n1:effectiveTime/n1:low"/>
                                                </xsl:call-template>
                                                <xsl:if test="n1:effectiveTime/n1:high">
                                                    <xsl:text> to </xsl:text>
                                                    <xsl:call-template name="show-time">
                                                      <xsl:with-param name="datetime"
                                                      select="n1:effectiveTime/n1:high"/>
                                                    </xsl:call-template>
                                                </xsl:if>
                                            </xsl:when>
                                        </xsl:choose>
                                    </xsl:if>
                                </dd>
                                <xsl:if test="n1:location/n1:healthCareFacility">
                                    <dt>
                                                <xsl:text>Encounter Location</xsl:text>
                                    </dt>
                                    <dd>
                                            <xsl:choose>
                                                <xsl:when
                                                    test="n1:location/n1:healthCareFacility/n1:location/n1:name">
                                                    <xsl:call-template name="show-name">
                                                        <xsl:with-param name="name"
                                                          select="n1:location/n1:healthCareFacility/n1:location/n1:name"
                                                        />
                                                    </xsl:call-template>
                                                    <xsl:for-each
                                                        select="n1:location/n1:healthCareFacility/n1:serviceProviderOrganization/n1:name">
                                                        <xsl:text> of </xsl:text>
                                                        <xsl:call-template name="show-name">
                                                          <xsl:with-param name="name"
                                                          select="n1:location/n1:healthCareFacility/n1:serviceProviderOrganization/n1:name"
                                                          />
                                                        </xsl:call-template>
                                                    </xsl:for-each>
                                                </xsl:when>
                                                <xsl:when test="n1:location/n1:healthCareFacility/n1:code">
                                                    <xsl:call-template name="show-code">
                                                        <xsl:with-param name="code"
                                                          select="n1:location/n1:healthCareFacility/n1:code"
                                                        />
                                                    </xsl:call-template>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:if test="n1:location/n1:healthCareFacility/n1:id">
                                                        <xsl:text>id: </xsl:text>
                                                        <xsl:for-each
                                                          select="n1:location/n1:healthCareFacility/n1:id">
                                                          <xsl:call-template name="show-id">
                                                          <xsl:with-param name="id" select="."/>
                                                          </xsl:call-template>
                                                        </xsl:for-each>
                                                    </xsl:if>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </dd>
                                </xsl:if>
                                <xsl:if test="n1:responsibleParty">
                                    <dt>
                                            <xsl:text>Responsible party</xsl:text>
                                    </dt>
                                    <dd>
                                            <xsl:call-template name="show-assignedEntity">
                                                <xsl:with-param name="asgnEntity"
                                                    select="n1:responsibleParty/n1:assignedEntity"/>
                                            </xsl:call-template>
                                    </dd>
                                </xsl:if>
                                <xsl:if
                                    test="n1:responsibleParty/n1:assignedEntity/n1:addr | n1:responsibleParty/n1:assignedEntity/n1:telecom">
                                    <dt>
                                                <xsl:text>Contact info</xsl:text>
                                    </dt>
                                    <dd>
                                            <xsl:call-template name="show-contactInfo">
                                                <xsl:with-param name="contact"
                                                    select="n1:responsibleParty/n1:assignedEntity"/>
                                            </xsl:call-template>
                                    </dd>
                                </xsl:if>
                            </dl>
                        </div>
                    </xsl:for-each>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- custodian -->
    <xsl:template name="custodian">
        <xsl:if test="n1:custodian">
            <div class="col-xs-12">
                <strong>
                    <xsl:choose>
                        <xsl:when
                            test="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:name">
                            <xsl:call-template name="show-name">
                                <xsl:with-param name="name"
                                    select="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:name"
                                />
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each
                                select="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:id">
                                <xsl:call-template name="show-id"/>
                                <xsl:if test="position()!=last()">
                                    <br/>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </strong>
                <br />
                <xsl:if
                    test="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:addr |             n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:telecom">
                    
                            <xsl:call-template name="show-contactInfo">
                                <xsl:with-param name="contact"
                                    select="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization"
                                />
                            </xsl:call-template>
            
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- documentationOf -->
    <xsl:template name="documentationOf">
        <xsl:if test="n1:documentationOf">
            <div class="col-md-4 col-xs-6">
                <h4>Documentation of</h4>
                <div class="col-xs-12">
                    <xsl:for-each select="n1:documentationOf">
                        <div class="col-xs-6">
                            <dl>
                                <xsl:if test="n1:serviceEvent/@classCode and n1:serviceEvent/n1:code">
                                    <xsl:variable name="displayName">
                                        <xsl:call-template name="show-actClassCode">
                                            <xsl:with-param name="clsCode"
                                                select="n1:serviceEvent/@classCode"/>
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <xsl:if test="$displayName">
                                        <dt>

                                                    <xsl:call-template name="firstCharCaseUp">
                                                        <xsl:with-param name="data" select="$displayName"/>
                                                    </xsl:call-template>

                                        </dt>
                                        <dd>
                                                <xsl:call-template name="show-code">
                                                    <xsl:with-param name="code"
                                                        select="n1:serviceEvent/n1:code"/>
                                                </xsl:call-template>
                                                <xsl:if test="n1:serviceEvent/n1:effectiveTime">
                                                    <xsl:choose>
                                                        <xsl:when
                                                          test="n1:serviceEvent/n1:effectiveTime/@value">
                                                          <xsl:text>&#160;at&#160;</xsl:text>
                                                          <xsl:call-template name="show-time">
                                                          <xsl:with-param name="datetime"
                                                          select="n1:serviceEvent/n1:effectiveTime"/>
                                                          </xsl:call-template>
                                                        </xsl:when>
                                                        <xsl:when
                                                          test="n1:serviceEvent/n1:effectiveTime/n1:low">
                                                          <xsl:text>&#160;from&#160;</xsl:text>
                                                          <xsl:call-template name="show-time">
                                                          <xsl:with-param name="datetime"
                                                          select="n1:serviceEvent/n1:effectiveTime/n1:low"/>
                                                          </xsl:call-template>
                                                          <xsl:if
                                                          test="n1:serviceEvent/n1:effectiveTime/n1:high">
                                                          <xsl:text> to </xsl:text>
                                                          <xsl:call-template name="show-time">
                                                          <xsl:with-param name="datetime"
                                                          select="n1:serviceEvent/n1:effectiveTime/n1:high"
                                                          />
                                                          </xsl:call-template>
                                                          </xsl:if>
                                                        </xsl:when>
                                                    </xsl:choose>
                                                </xsl:if>
                                            </dd>
                                    </xsl:if>
                                </xsl:if>
                                <xsl:for-each select="n1:serviceEvent/n1:performer">
                                    <xsl:variable name="displayName">
                                        <xsl:call-template name="show-participationType">
                                            <xsl:with-param name="ptype" select="@typeCode"/>
                                        </xsl:call-template>
                                        <xsl:text> </xsl:text>
                                        <xsl:if test="n1:functionCode/@code">
                                            <xsl:call-template name="show-participationFunction">
                                                <xsl:with-param name="pFunction"
                                                    select="n1:functionCode/@code"/>
                                            </xsl:call-template>
                                        </xsl:if>
                                    </xsl:variable>
                                    <dt>
                                                <xsl:call-template name="firstCharCaseUp">
                                                    <xsl:with-param name="data" select="$displayName"/>
                                                </xsl:call-template>
                                    </dt>
                                    <dd>
                                            <xsl:call-template name="show-assignedEntity">
                                                <xsl:with-param name="asgnEntity" select="n1:assignedEntity"
                                                />
                                            </xsl:call-template>
                                    </dd>
                                </xsl:for-each>
                            </dl>
                        </div>
                    </xsl:for-each>
                </div>  
            </div>         
        </xsl:if>
    </xsl:template>
    <!-- inFulfillmentOf -->
    <xsl:template name="inFulfillmentOf">
        <xsl:if test="n1:infulfillmentOf">
            <div class="col-md-4 col-xs-6">
                <h4>In fulfillment of</h4>
                <div class="col-xs-12">
                    <xsl:for-each select="n1:inFulfillmentOf">
                        <div class="col-xs-6">
                            <dl>
                                <dt>
                                    <xsl:text>In fulfillment of</xsl:text>
                                </dt>
                                    
                                <dd>
                                    <xsl:for-each select="n1:order">
                                        <xsl:for-each select="n1:id">
                                            <xsl:call-template name="show-id"/>
                                        </xsl:for-each>
                                        <xsl:for-each select="n1:code">
                                            <xsl:text>&#160;</xsl:text>
                                            <xsl:call-template name="show-code">
                                                <xsl:with-param name="code" select="."/>
                                            </xsl:call-template>
                                        </xsl:for-each>
                                        <xsl:for-each select="n1:priorityCode">
                                            <xsl:text>&#160;</xsl:text>
                                            <xsl:call-template name="show-code">
                                                <xsl:with-param name="code" select="."/>
                                            </xsl:call-template>
                                        </xsl:for-each>
                                    </xsl:for-each>
                                </dd>
                            </dl>
                        </div>
                    </xsl:for-each>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- informant -->
    <xsl:template name="informant">
        <xsl:if test="n1:informant">
            <div class="col-md-4 col-xs-6">
                <h4>Informant</h4>
                <div class="col-xs-12">
                <xsl:for-each select="n1:informant">
                    <div class="col-xs-6">
                        <strong>
                            <xsl:if test="n1:assignedEntity">
                                <xsl:call-template name="show-assignedEntity">
                                    <xsl:with-param name="asgnEntity" select="n1:assignedEntity"
                                    />
                                </xsl:call-template>
                            </xsl:if>
                            <xsl:if test="n1:relatedEntity">
                                <xsl:call-template name="show-relatedEntity">
                                    <xsl:with-param name="relatedEntity"
                                        select="n1:relatedEntity"/>
                                </xsl:call-template>
                            </xsl:if>
                        </strong>
                        <br />
                        <xsl:choose>
                            <xsl:when
                                test="n1:assignedEntity/n1:addr | n1:assignedEntity/n1:telecom">
                                
                                        <xsl:if test="n1:assignedEntity">
                                            <xsl:call-template name="show-contactInfo">
                                                <xsl:with-param name="contact"
                                                  select="n1:assignedEntity"/>
                                            </xsl:call-template>
                                        </xsl:if>
                            </xsl:when>
                            <xsl:when test="n1:relatedEntity/n1:addr | n1:relatedEntity/n1:telecom">
                            
                                        <xsl:if test="n1:relatedEntity">
                                            <xsl:call-template name="show-contactInfo">
                                                <xsl:with-param name="contact"
                                                  select="n1:relatedEntity"/>
                                            </xsl:call-template>
                                        </xsl:if>
                
                            </xsl:when>
                        </xsl:choose>
                    </div>
                </xsl:for-each>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- informantionRecipient -->
    <xsl:template name="informationRecipient">
        <xsl:if test="n1:informationRecipient">
            <div class="col-md-4 col-xs-6">
                <h4>Information recipient</h4>
                <div class="col-xs-12">
                <xsl:for-each select="n1:informationRecipient">
                    <div class="col-xs-6">
                        <strong>
                            <xsl:choose>
                                <xsl:when
                                    test="n1:intendedRecipient/n1:informationRecipient/n1:name">
                                    <xsl:for-each
                                        select="n1:intendedRecipient/n1:informationRecipient">
                                        <xsl:call-template name="show-name">
                                            <xsl:with-param name="name" select="n1:name"/>
                                        </xsl:call-template>
                                        <xsl:if test="position() != last()">
                                            <br/>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:for-each select="n1:intendedRecipient">
                                        <xsl:for-each select="n1:id">
                                            <xsl:call-template name="show-id"/>
                                        </xsl:for-each>
                                        <xsl:if test="position() != last()">
                                            <br/>
                                        </xsl:if>
                                        <br/>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                        </strong>
                        <br />
                        <xsl:if
                            test="n1:intendedRecipient/n1:addr | n1:intendedRecipient/n1:telecom">
                            
                                    <xsl:call-template name="show-contactInfo">
                                        <xsl:with-param name="contact" select="n1:intendedRecipient"
                                        />
                                    </xsl:call-template>
                               
                        </xsl:if>
                    </div>
                </xsl:for-each>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- participant -->
    <xsl:template name="participant">
        <xsl:if test="n1:participant">
            <div class="col-md-4 col-xs-6">
                <h4>Participant</h4>
                <div class="col-xs-12">
                    <xsl:for-each select="n1:participant">
                        <div class="col-xs-6">
                            <dl>
                                <dt>
                                    <xsl:variable name="participtRole">
                                        <xsl:call-template name="translateRoleAssoCode">
                                            <xsl:with-param name="classCode"
                                                select="n1:associatedEntity/@classCode"/>
                                            <xsl:with-param name="code"
                                                select="n1:associatedEntity/n1:code"/>
                                        </xsl:call-template>
                                    </xsl:variable>
                                    <xsl:choose>
                                        <xsl:when test="$participtRole">
                                            <span class="td_label">
                                                <xsl:call-template name="firstCharCaseUp">
                                                    <xsl:with-param name="data" select="$participtRole"
                                                    />
                                                </xsl:call-template>
                                            </span>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <span class="td_label">
                                                <xsl:text>Participant</xsl:text>
                                            </span>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </dt>
                                <dd>
                                    <xsl:if test="n1:functionCode">
                                        <xsl:call-template name="show-code">
                                            <xsl:with-param name="code" select="n1:functionCode"/>
                                        </xsl:call-template>
                                        <xsl:text> </xsl:text>
                                    </xsl:if>
                                    <xsl:call-template name="show-associatedEntity">
                                        <xsl:with-param name="assoEntity" select="n1:associatedEntity"/>
                                    </xsl:call-template>
                                    <xsl:if test="n1:time">
                                        <xsl:if test="n1:time/n1:low">
                                            <xsl:text> from </xsl:text>
                                            <xsl:call-template name="show-time">
                                                <xsl:with-param name="datetime" select="n1:time/n1:low"
                                                />
                                            </xsl:call-template>
                                        </xsl:if>
                                        <xsl:if test="n1:time/n1:high">
                                            <xsl:text> to </xsl:text>
                                            <xsl:call-template name="show-time">
                                                <xsl:with-param name="datetime" select="n1:time/n1:high"
                                                />
                                            </xsl:call-template>
                                        </xsl:if>
                                    </xsl:if>
                                    <xsl:if test="position() != last()">
                                        <br/>
                                    </xsl:if>
                                </dd>
                                <xsl:if test="n1:associatedEntity/n1:addr | n1:associatedEntity/n1:telecom">
                                    <dt>
                                                <xsl:text>Contact info</xsl:text>
                                    </dt>
                                    <dd>
                                            <xsl:call-template name="show-contactInfo">
                                                <xsl:with-param name="contact" select="n1:associatedEntity"
                                                />
                                            </xsl:call-template>
                                    </dd>
                                </xsl:if>
                            </dl>
                        </div>
                    </xsl:for-each>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- recordTarget -->
    <xsl:template name="recordTargetTop">
        <xsl:for-each select="/n1:ClinicalDocument/n1:recordTarget/n1:patientRole">
            <xsl:if test="not(n1:id/@nullFlavor)">
                <address>
                    <strong>
                        <xsl:call-template name="show-name">
                            <xsl:with-param name="name" select="n1:patient/n1:name"/>
                        </xsl:call-template>
                    </strong><br />
                    <xsl:call-template name="show-time">
                        <xsl:with-param name="datetime" select="n1:patient/n1:birthTime"/>
                    </xsl:call-template><br />
                    <xsl:for-each select="n1:patient/n1:administrativeGenderCode">
                        <xsl:call-template name="show-gender"/>
                    </xsl:for-each>

                </address>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="recordTarget">
        
            
        <xsl:for-each select="/n1:ClinicalDocument/n1:recordTarget/n1:patientRole">
            <xsl:if test="not(n1:id/@nullFlavor)">
                <div class="row">
                    <div class="col-xs-6">
                        <address>
                            <strong>
                                <xsl:call-template name="show-name">
                                    <xsl:with-param name="name" select="n1:patient/n1:name"/>
                                </xsl:call-template>
                            </strong><br />
                            <xsl:call-template name="show-contactInfo">
                                <xsl:with-param name="contact" select="."/>
                            </xsl:call-template>
                        </address>
                    </div>
                    <div class="col-xs-6">
                        <strong>
                            <i class="fa fa-calendar"></i><xsl:text> Date of birth</xsl:text>
                        </strong>
                        <div class="info-head">
                            <xsl:call-template name="show-time">
                                <xsl:with-param name="datetime" select="n1:patient/n1:birthTime"
                                    />
                            </xsl:call-template>
                        </div>
                        <strong>
                            <i class="fa fa-transgender"></i><xsl:text> Sex</xsl:text>
                        </strong>
                        <div class="info-head">
                            <xsl:for-each select="n1:patient/n1:administrativeGenderCode">
                                <xsl:call-template name="show-gender"/>
                            </xsl:for-each>
                        </div>
                        <xsl:if test="n1:patient/n1:raceCode | (n1:patient/n1:ethnicGroupCode)">
                            <strong>
                                <xsl:text>Race</xsl:text>
                            </strong>
                            <div class="info-head">
                                <xsl:choose>
                                    <xsl:when test="n1:patient/n1:raceCode">
                                        <xsl:for-each select="n1:patient/n1:raceCode">
                                            <xsl:call-template name="show-race-ethnicity"/>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>Information not available</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </div>
                            <strong>
                                <xsl:text>Ethnicity</xsl:text>
                            </strong>
                            <div class="info-head">
                                <xsl:choose>
                                    <xsl:when test="n1:patient/n1:ethnicGroupCode">
                                        <xsl:for-each select="n1:patient/n1:ethnicGroupCode">
                                            <xsl:call-template name="show-race-ethnicity"/>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>Information not available</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </div>
                            </xsl:if>
                        <strong>
                            <i class="fa fa-credit-card"></i><xsl:text> Patient IDs</xsl:text>
                        </strong>
                        <div class="info-head">
                            <xsl:for-each select="n1:id">
                                <xsl:call-template name="show-id"/>
                                <br/>
                            </xsl:for-each>
                        </div>
                    </div>
                </div>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <!-- relatedDocument -->
    <xsl:template name="relatedDocument">
        <xsl:if test="n1:relatedDocument">
            <table class="header_table moreinfo">
                <tbody>
                    <xsl:for-each select="n1:relatedDocument">
                        <tr>
                            <td bgcolor="#3399ff">
                                <xsl:attribute name="width">
                                    <xsl:value-of select="$HeaderFixedColWidth"/>
                                </xsl:attribute>
                                <span class="td_label">
                                    <xsl:text>Related document</xsl:text>
                                </span>
                            </td>
                            <td>
                                <xsl:for-each select="n1:parentDocument">
                                    <xsl:for-each select="n1:id">
                                        <xsl:call-template name="show-id"/>
                                        <br/>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </td>
                        </tr>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- authorization (consent) -->
    <xsl:template name="authorization">
        <xsl:if test="n1:authorization">
            <div class="col-md-4 col-xs-6">
                <h4>Consent</h4>
                <div class="col-xs-12">
                    <xsl:for-each select="n1:authorization">
                        <div class="col-xs-6">
                            <xsl:choose>
                                <xsl:when test="n1:consent/n1:code">
                                    <xsl:call-template name="show-code">
                                        <xsl:with-param name="code" select="n1:consent/n1:code"
                                        />
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:call-template name="show-code">
                                        <xsl:with-param name="code"
                                            select="n1:consent/n1:statusCode"/>
                                    </xsl:call-template>
                                </xsl:otherwise>
                            </xsl:choose>
                        </div>
                    </xsl:for-each>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- setAndVersion -->
    <xsl:template name="setAndVersion">
        <xsl:if test="n1:setId and n1:versionNumber">
            <table class="header_table moreinfo">
                <tbody>
                    <tr>
                        <td>
                            <xsl:attribute name="width">
                                <xsl:value-of select="$HeaderFixedColWidth"/>
                            </xsl:attribute>
                            <span class="td_label">
                                <xsl:text>SetId and Version</xsl:text>
                            </span>
                        </td>
                        <td colspan="3">
                            <xsl:text>SetId: </xsl:text>
                            <xsl:call-template name="show-id">
                                <xsl:with-param name="id" select="n1:setId"/>
                            </xsl:call-template>
                            <xsl:text>  Version: </xsl:text>
                            <xsl:value-of select="n1:versionNumber/@value"/>
                        </td>
                    </tr>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- show StructuredBody  -->
    <xsl:template match="n1:component/n1:structuredBody">
        <xsl:for-each select="n1:component/n1:section">
            <xsl:if test="not(n1:templateId[@root='2.16.840.1.113883.10.20.6.1.1'])">
                <xsl:call-template name="content-section"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- Create Javascript Array or keywords -->
    <xsl:template name="keywordsToSearch">
        <xsl:text>var keyToSearch = [ </xsl:text>
        <xsl:for-each select="$Preferences/opencde:Preferences
                                                            /opencde:DocumentsCodesPreferences[@code=$DocumentCode and @codeSystem=$DocumentCodeCodeSystem]
                                                            /opencde:SearchKeyWords/opencde:KeyWord">
            <xsl:value-of select='concat("&apos;",./text(),"&apos;,")' />
        </xsl:for-each>
        <xsl:text>]</xsl:text>
    </xsl:template>

    <!-- Create Javascript array of Initial Sections -->
    <xsl:template name="initialSections">
        <xsl:param name="content"></xsl:param>
        <!-- Save CDA context -->
        <xsl:variable name="structuredBodyContext" select="$content"/>
        <!-- Gets all sections to be displayed -->
        <xsl:text>var summaryList = [</xsl:text>
        <xsl:for-each select="$Preferences/opencde:Preferences
                                                            /opencde:DocumentsCodesPreferences[@code=$DocumentCode and @codeSystem=$DocumentCodeCodeSystem]
                                                            /opencde:DocumentCodeInitialSections/opencde:Section">
             
            <xsl:variable name="SectionCode">
                <xsl:value-of select="./@code"/>
            </xsl:variable>
            <xsl:variable name="SectionCodeCodeSystem">
                <xsl:value-of select="./@codeSystem"/>
            </xsl:variable>
            <xsl:text>'</xsl:text><xsl:value-of select="translate(concat($SectionCode,$SectionCodeCodeSystem),'.','')"/><xsl:text>',</xsl:text>
        </xsl:for-each>
        <xsl:text>];</xsl:text>
    </xsl:template>
    <!-- show nonXMLBody -->
    <xsl:template name="nonXMLBody-contents">
        <xsl:choose>
            <!-- if there is a reference, use that in an IFRAME -->
            <xsl:when test="n1:component/n1:nonXMLBody/n1:text/n1:reference">
                <iframe name="nonXMLBody" id="nonXMLBody" WIDTH="80%" HEIGHT="600"
                    src="{n1:text/n1:reference/@value}"/>
            </xsl:when>
            <xsl:when test='n1:text/@mediaType="text/plain"'>
                <pre>
               <xsl:value-of select="n1:text/text()"/>
            </pre>
            </xsl:when>
            <xsl:when test='n1:component/n1:nonXMLBody/n1:text[@mediaType="application/pdf" and @representation="B64"]'>
                <object type="application/pdf" width="100%" height="1024">
                    <xsl:attribute name="data">
                        <xsl:value-of select="concat('data:application/pdf;base64,',n1:component/n1:nonXMLBody/n1:text/text())"
                        />
                    </xsl:attribute>
                </object>
            </xsl:when>
            <xsl:otherwise>
                <CENTER>Cannot display the text</CENTER>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- top level component/section: display title and text,
     and process any nested component/sections
   -->
    
    <!-- section author -->
    <xsl:template name="section-author">
        <xsl:if test="count(n1:author)&gt;0">
            <div style="margin-left : 2em;">
                <b>
                    <xsl:text>Section Author: </xsl:text>
                </b>
                <xsl:for-each select="n1:author/n1:assignedAuthor">
                    <xsl:choose>
                        <xsl:when test="n1:assignedPerson/n1:name">
                            <xsl:call-template name="show-name">
                                <xsl:with-param name="name" select="n1:assignedPerson/n1:name"/>
                            </xsl:call-template>
                            <xsl:if test="n1:representedOrganization">
                                <xsl:text>, </xsl:text>
                                <xsl:call-template name="show-name">
                                    <xsl:with-param name="name"
                                        select="n1:representedOrganization/n1:name"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:when>
                        <xsl:when test="n1:assignedAuthoringDevice/n1:softwareName">
                            <xsl:value-of select="n1:assignedAuthoringDevice/n1:softwareName"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="n1:id">
                                <xsl:call-template name="show-id"/>
                                <br/>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                <br/>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- top-level section Text   -->
    <xsl:template name="section-text">
            <xsl:apply-templates select="n1:text"/>
    </xsl:template>
    <!--   paragraph  -->
    <xsl:template match="n1:paragraph">
        <p>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <!--   pre format  -->
    <xsl:template match="n1:pre">
        <pre>
         <xsl:apply-templates/>
      </pre>
    </xsl:template>
    <!--   Content w/ deleted text is hidden -->
    <xsl:template match="n1:content[@revised='delete']"/>
    <!--   content  -->
    <xsl:template match="n1:content">
        <span>
            <xsl:call-template name="output-attrs" />
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <!-- line break -->
    <xsl:template match="n1:br">
        <xsl:element name="br">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <!--   list  -->
    <xsl:template match="n1:list">
        <xsl:if test="n1:caption">
            <p>
                <b>
                    <xsl:apply-templates select="n1:caption"/>
                </b>
            </p>
        </xsl:if>
        <ul>
            <xsl:for-each select="n1:item">
                <li>
                    <xsl:apply-templates/>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    <xsl:template match="n1:list[@listType='ordered']">
        <xsl:if test="n1:caption">
            <span style="font-weight:bold; ">
                <xsl:apply-templates select="n1:caption"/>
            </span>
        </xsl:if>
        <ol>
            <xsl:for-each select="n1:item">
                <li>
                    <xsl:apply-templates/>
                </li>
            </xsl:for-each>
        </ol>
    </xsl:template>
    <!--   caption  -->
    <xsl:template match="n1:caption">
        <xsl:apply-templates/>
        <xsl:text>: </xsl:text>
    </xsl:template>
    <!--  Tables   -->
    <xsl:template match="n1:table">
        
        <xsl:element name="{local-name()}">
            <xsl:attribute name="class"><xsl:text>table table-striped table-hover</xsl:text></xsl:attribute>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="n1:thead | n1:tfoot | n1:tbody | n1:colgroup | n1:col | n1:tr | n1:th | n1:td">
        <xsl:element name="{local-name()}">
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="n1:table/n1:caption">
        <span style="font-weight:bold; ">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <!--   RenderMultiMedia 
    this currently only handles GIF's and JPEG's.  It could, however,
    be extended by including other image MIME types in the predicate
    and/or by generating <object> or <applet> tag with the correct
    params depending on the media type  @ID  =$imageRef  referencedObject.
    MPS: text/html case added
    -->
    <xsl:template match="n1:renderMultiMedia">
        <xsl:variable name="imageRef" select="@referencedObject"/>
        <xsl:choose>
            <xsl:when test="//n1:regionOfInterest[@ID=$imageRef]">
                <!-- Here is where the Region of Interest image referencing goes -->
                <xsl:if
                    test="//n1:regionOfInterest[@ID=$imageRef]//n1:observationMedia/n1:value[@mediaType='image/gif' or
 @mediaType='image/jpeg']">
                    <br clear="all"/>
                    <xsl:element name="img">
                        <xsl:attribute name="src">
                            <xsl:value-of
                                select="//n1:regionOfInterest[@ID=$imageRef]//n1:observationMedia/n1:value/n1:reference/@value"
                            />
                        </xsl:attribute>
                    </xsl:element>
                </xsl:if>
            </xsl:when>

            <xsl:otherwise>
                <!-- Here is where the direct MultiMedia image referencing goes -->
                <xsl:if
                    test="//n1:observationMedia[@ID=$imageRef]/n1:value[@mediaType='image/gif' or @mediaType='image/jpeg']">
                    <br clear="all"/>
                    <xsl:element name="img">
                        <!-- Test if image is a reference -->
                        <xsl:if test="//n1:observationMedia[@ID=$imageRef]/n1:value/n1:reference">
                            <xsl:attribute name="src"><xsl:value-of select="//n1:observationMedia[@ID=$imageRef]/n1:value/n1:reference/@value"/></xsl:attribute>    
                        </xsl:if>
                        <!-- Test if image is a b64 -->
                        <xsl:if test="//n1:observationMedia[@ID=$imageRef]/n1:value/@representation='B64'">
                            <xsl:attribute name="src">
                                <xsl:value-of select="concat('data:',//n1:observationMedia[@ID=$imageRef]/n1:value/@mediaType,';base64, ',//n1:observationMedia[@ID=$imageRef]/n1:value/text())"/>
                            </xsl:attribute>
                        </xsl:if>
                    </xsl:element>
                </xsl:if>

                <!-- MPS: Render ObservationMedia Html B64 embedded -->
                <xsl:if test="//n1:observationMedia[@ID=$imageRef]/n1:value[@mediaType='text/html']">

                    <object type="text/html"  width="100%" onload='javascript:resizeIframe(this);'>
                        <xsl:attribute name="data">
                            <xsl:value-of
                                select="concat('data:text/html;base64,',//n1:observationMedia[@ID=$imageRef]/n1:value/text())"
                            />
                        </xsl:attribute>                        
                    </object>

                </xsl:if>

            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--    Stylecode processing   
    Supports Bold, Underline and Italics display
    -->
    <xsl:template match="@styleCode">
        <xsl:attribute name="class"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>
    <!--    Superscript or Subscript   -->
    <xsl:template match="n1:sup">
        <xsl:element name="sup">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="n1:sub">
        <xsl:element name="sub">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <!-- show-signature -->
    <xsl:template name="show-sig">
        <xsl:param name="sig"/>
        <xsl:choose>
            <xsl:when test="$sig/@code =&apos;S&apos;">
                <xsl:text>signed</xsl:text>
            </xsl:when>
            <xsl:when test="$sig/@code=&apos;I&apos;">
                <xsl:text>intended</xsl:text>
            </xsl:when>
            <xsl:when test="$sig/@code=&apos;X&apos;">
                <xsl:text>signature required</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!--  show-id -->
    <xsl:template name="show-id">
        <xsl:param name="id"/>
        <xsl:choose>
            <xsl:when test="not($id)">
                <xsl:if test="not(@nullFlavor)">
                    <xsl:if test="@extension">
                        <xsl:value-of select="@extension"/>
                    </xsl:if>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="@root"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not($id/@nullFlavor)">
                    <xsl:if test="$id/@extension">
                        <xsl:value-of select="$id/@extension"/>
                    </xsl:if>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$id/@root"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- show-name  -->
    <xsl:template name="show-name">
        <xsl:param name="name"/>
        <xsl:choose>
            <xsl:when test="$name/n1:family">
                <xsl:if test="$name/n1:prefix">
                    <xsl:value-of select="$name/n1:prefix"/>
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:value-of select="$name/n1:given"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$name/n1:family"/>
                <xsl:if test="$name/n1:suffix">
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$name/n1:suffix"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$name"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- show-gender  -->
    <xsl:template name="show-gender">
        <xsl:choose>
            <xsl:when test="@code   = &apos;M&apos;">
                <xsl:text>Male</xsl:text>
            </xsl:when>
            <xsl:when test="@code  = &apos;F&apos;">
                <xsl:text>Female</xsl:text>
            </xsl:when>
            <xsl:when test="@code  = &apos;U&apos;">
                <xsl:text>Undifferentiated</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show-race-ethnicity  -->
    <xsl:template name="show-race-ethnicity">
        <xsl:choose>
            <xsl:when test="@displayName">
                <xsl:value-of select="@displayName"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@code"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- show-contactInfo -->
    <xsl:template name="show-contactInfo">
        <xsl:param name="contact"/>
        <xsl:call-template name="show-address">
            <xsl:with-param name="address" select="$contact/n1:addr"/>
        </xsl:call-template>
        <xsl:call-template name="show-telecom">
            <xsl:with-param name="telecom" select="$contact/n1:telecom"/>
        </xsl:call-template>
    </xsl:template>
    <!-- show-address -->
    <xsl:template name="show-address">
        <xsl:param name="address"/>
        <xsl:choose>
            <xsl:when test="$address">
                <xsl:if test="$address/@use">
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="translateTelecomCode">
                        <xsl:with-param name="code" select="$address/@use"/>
                    </xsl:call-template>
                    <xsl:text>:</xsl:text>
                    <br/>
                </xsl:if>
                <xsl:for-each select="$address/n1:streetAddressLine">
                    <xsl:value-of select="."/>
                    <br/>
                </xsl:for-each>
                <xsl:if test="$address/n1:streetName">
                    <xsl:value-of select="$address/n1:streetName"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$address/n1:houseNumber"/>
                    <br/>
                </xsl:if>
                <xsl:if test="string-length($address/n1:city)>0">
                    <xsl:value-of select="$address/n1:city"/>
                </xsl:if>
                <xsl:if test="string-length($address/n1:state)>0">
                    <xsl:text>,&#160;</xsl:text>
                    <xsl:value-of select="$address/n1:state"/>
                </xsl:if>
                <xsl:if test="string-length($address/n1:postalCode)>0">
                    <xsl:text>&#160;</xsl:text>
                    <xsl:value-of select="$address/n1:postalCode"/>
                </xsl:if>
                <xsl:if test="string-length($address/n1:country)>0">
                    <xsl:text>,&#160;</xsl:text>
                    <xsl:value-of select="$address/n1:country"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>address not available</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <br/>
    </xsl:template>
    <!-- show-telecom -->
    <xsl:template name="show-telecom">
        <xsl:param name="telecom"/>
        <xsl:choose>
            <xsl:when test="$telecom">
                <xsl:variable name="type" select="substring-before($telecom/@value, ':')"/>
                <xsl:variable name="value" select="substring-after($telecom/@value, ':')"/>
                <xsl:if test="$type">
                    <xsl:variable name="ref">
                        <xsl:choose>
                            <xsl:when test="$type='tel' or $type='fax' or $type='H' or $type='HV' or $type='HP' or $type='WP'">
                                <xsl:text>tel://</xsl:text>
                            </xsl:when>
                            <xsl:when test="$type='mailto'">
                                <xsl:text>mailto://</xsl:text>
                            </xsl:when>
                            <xsl:when test="$type='http'">
                                <xsl:text>http://</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>//</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="concat($ref,translate($value,'()-,.',''))"/>
                        </xsl:attribute>
                    
                        <xsl:call-template name="translateTelecomCode">
                            <xsl:with-param name="code" select="$type"/>
                        </xsl:call-template>
                        <xsl:if test="@use">
                            <xsl:text> (</xsl:text>
                            <xsl:call-template name="translateTelecomCode">
                                <xsl:with-param name="code" select="@use"/>
                            </xsl:call-template>
                            <xsl:text>)</xsl:text>
                        </xsl:if>
                        <xsl:text>: </xsl:text>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$value"/>
                    </a>
                    
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Telecom information not available</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <br/>
    </xsl:template>
    <!-- show-recipientType -->
    <xsl:template name="show-recipientType">
        <xsl:param name="typeCode"/>
        <xsl:choose>
            <xsl:when test="$typeCode='PRCP'">Primary Recipient:</xsl:when>
            <xsl:when test="$typeCode='TRC'">Secondary Recipient:</xsl:when>
            <xsl:otherwise>Recipient:</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Convert Telecom URL to display text -->
    <xsl:template name="translateTelecomCode">
        <xsl:param name="code"/>
        <!--xsl:value-of select="document('voc.xml')/systems/system[@root=$code/@codeSystem]/code[@value=$code/@code]/@displayName"/-->
        <!--xsl:value-of select="document('codes.xml')/*/code[@code=$code]/@display"/-->
        <xsl:choose>
            <!-- lookup table Telecom URI -->
            <xsl:when test="$code='tel'">
                <xsl:text>Tel</xsl:text>
            </xsl:when>
            <xsl:when test="$code='fax'">
                <xsl:text>Fax</xsl:text>
            </xsl:when>
            <xsl:when test="$code='http'">
                <xsl:text>Web</xsl:text>
            </xsl:when>
            <xsl:when test="$code='mailto'">
                <xsl:text>Mail</xsl:text>
            </xsl:when>
            <xsl:when test="$code='H'">
                <xsl:text>Home</xsl:text>
            </xsl:when>
            <xsl:when test="$code='HV'">
                <xsl:text>Vacation Home</xsl:text>
            </xsl:when>
            <xsl:when test="$code='HP'">
                <xsl:text>Primary Home</xsl:text>
            </xsl:when>
            <xsl:when test="$code='WP'">
                <xsl:text>Work Place</xsl:text>
            </xsl:when>
            <xsl:when test="$code='PUB'">
                <xsl:text>Pub</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>{$code='</xsl:text>
                <xsl:value-of select="$code"/>
                <xsl:text>'?}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- convert RoleClassAssociative code to display text -->
    <xsl:template name="translateRoleAssoCode">
        <xsl:param name="classCode"/>
        <xsl:param name="code"/>
        <xsl:choose>
            <xsl:when test="$classCode='AFFL'">
                <xsl:text>affiliate</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='AGNT'">
                <xsl:text>agent</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='ASSIGNED'">
                <xsl:text>assigned entity</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='COMPAR'">
                <xsl:text>commissioning party</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='CON'">
                <xsl:text>contact</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='ECON'">
                <xsl:text>emergency contact</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='NOK'">
                <xsl:text>next of kin</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='SGNOFF'">
                <xsl:text>signing authority</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='GUARD'">
                <xsl:text>guardian</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='GUAR'">
                <xsl:text>guardian</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='CIT'">
                <xsl:text>citizen</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='COVPTY'">
                <xsl:text>covered party</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='PRS'">
                <xsl:text>personal relationship</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='CAREGIVER'">
                <xsl:text>care giver</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='PROV'">
                <xsl:text>provider</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>{$classCode='</xsl:text>
                <xsl:value-of select="$classCode"/>
                <xsl:text>'?}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="($code/@code) and ($code/@codeSystem='2.16.840.1.113883.5.111')">
            <xsl:text> </xsl:text>
            <xsl:choose>
                <xsl:when test="$code/@code='FTH'">
                    <xsl:text>(Father)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='MTH'">
                    <xsl:text>(Mother)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='NPRN'">
                    <xsl:text>(Natural parent)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='STPPRN'">
                    <xsl:text>(Step parent)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='SONC'">
                    <xsl:text>(Son)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='DAUC'">
                    <xsl:text>(Daughter)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='CHILD'">
                    <xsl:text>(Child)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='EXT'">
                    <xsl:text>(Extended family member)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='NBOR'">
                    <xsl:text>(Neighbor)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='SIGOTHR'">
                    <xsl:text>(Significant other)</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>{$code/@code='</xsl:text>
                    <xsl:value-of select="$code/@code"/>
                    <xsl:text>'?}</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <!-- show time -->
    <xsl:template name="show-time">
        <xsl:param name="datetime"/>
        <xsl:choose>
            <xsl:when test="not($datetime)">
                <xsl:call-template name="formatDateTime">
                    <xsl:with-param name="date" select="@value"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="formatDateTime">
                    <xsl:with-param name="date" select="$datetime/@value"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- paticipant facility and date -->
    <xsl:template name="facilityAndDates">
        <table class="header_table moreinfo">
            <tbody>
                <!-- facility id -->
                <tr>
                    <td width="20%" bgcolor="#3399ff">
                        <span class="td_label">
                            <xsl:text>Facility ID</xsl:text>
                        </span>
                    </td>
                    <td colspan="3">
                        <xsl:choose>
                            <xsl:when
                                test="count(/n1:ClinicalDocument/n1:participant
                                      [@typeCode='LOC'][@contextControlCode='OP']
                                      /n1:associatedEntity[@classCode='SDLOC']/n1:id)&gt;0">
                                <!-- change context node -->
                                <xsl:for-each
                                    select="/n1:ClinicalDocument/n1:participant
                                      [@typeCode='LOC'][@contextControlCode='OP']
                                      /n1:associatedEntity[@classCode='SDLOC']/n1:id">
                                    <xsl:call-template name="show-id"/>
                                    <!-- change context node again, for the code -->
                                    <xsl:for-each select="../n1:code">
                                        <xsl:text> (</xsl:text>
                                        <xsl:call-template name="show-code">
                                            <xsl:with-param name="code" select="."/>
                                        </xsl:call-template>
                                        <xsl:text>)</xsl:text>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise> Not available </xsl:otherwise>
                        </xsl:choose>
                    </td>
                </tr>
                <!-- Period reported -->
                <tr>
                    <td width="20%" bgcolor="#3399ff">
                        <span class="td_label">
                            <xsl:text>First day of period reported</xsl:text>
                        </span>
                    </td>
                    <td colspan="3">
                        <xsl:call-template name="show-time">
                            <xsl:with-param name="datetime"
                                select="/n1:ClinicalDocument/n1:documentationOf
                                      /n1:serviceEvent/n1:effectiveTime/n1:low"
                            />
                        </xsl:call-template>
                    </td>
                </tr>
                <tr>
                    <td width="20%" bgcolor="#3399ff">
                        <span class="td_label">
                            <xsl:text>Last day of period reported</xsl:text>
                        </span>
                    </td>
                    <td colspan="3">
                        <xsl:call-template name="show-time">
                            <xsl:with-param name="datetime"
                                select="/n1:ClinicalDocument/n1:documentationOf
                                      /n1:serviceEvent/n1:effectiveTime/n1:high"
                            />
                        </xsl:call-template>
                    </td>
                </tr>
            </tbody>
        </table>
    </xsl:template>
    <!-- show assignedEntity -->
    <xsl:template name="show-assignedEntity">
        <xsl:param name="asgnEntity"/>
        <xsl:choose>
            <xsl:when test="$asgnEntity/n1:assignedPerson/n1:name">
                <xsl:call-template name="show-name">
                    <xsl:with-param name="name" select="$asgnEntity/n1:assignedPerson/n1:name"/>
                </xsl:call-template>
                <xsl:if test="$asgnEntity/n1:representedOrganization/n1:name">
                    <xsl:text> of </xsl:text>
                    <xsl:value-of select="$asgnEntity/n1:representedOrganization/n1:name"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$asgnEntity/n1:representedOrganization">
                <xsl:value-of select="$asgnEntity/n1:representedOrganization/n1:name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$asgnEntity/n1:id">
                    <xsl:call-template name="show-id"/>
                    <xsl:choose>
                        <xsl:when test="position()!=last()">
                            <xsl:text>, </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <br/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- show relatedEntity -->
    <xsl:template name="show-relatedEntity">
        <xsl:param name="relatedEntity"/>
        <xsl:choose>
            <xsl:when test="$relatedEntity/n1:relatedPerson/n1:name">
                <xsl:call-template name="show-name">
                    <xsl:with-param name="name" select="$relatedEntity/n1:relatedPerson/n1:name"/>
                </xsl:call-template>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show associatedEntity -->
    <xsl:template name="show-associatedEntity">
        <xsl:param name="assoEntity"/>
        <xsl:choose>
            <xsl:when test="$assoEntity/n1:associatedPerson">
                <xsl:for-each select="$assoEntity/n1:associatedPerson/n1:name">
                    <xsl:call-template name="show-name">
                        <xsl:with-param name="name" select="."/>
                    </xsl:call-template>
                    <br/>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$assoEntity/n1:scopingOrganization">
                <xsl:for-each select="$assoEntity/n1:scopingOrganization">
                    <xsl:if test="n1:name">
                        <xsl:call-template name="show-name">
                            <xsl:with-param name="name" select="n1:name"/>
                        </xsl:call-template>
                        <br/>
                    </xsl:if>
                    <xsl:if test="n1:standardIndustryClassCode">
                        <xsl:value-of select="n1:standardIndustryClassCode/@displayName"/>
                        <xsl:text> code:</xsl:text>
                        <xsl:value-of select="n1:standardIndustryClassCode/@code"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$assoEntity/n1:code">
                <xsl:call-template name="show-code">
                    <xsl:with-param name="code" select="$assoEntity/n1:code"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$assoEntity/n1:id">
                <xsl:value-of select="$assoEntity/n1:id/@extension"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$assoEntity/n1:id/@root"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show code 
    if originalText present, return it, otherwise, check and return attribute: display name
    -->
    <xsl:template name="show-code">
        <xsl:param name="code"/>
        <xsl:variable name="this-codeSystem">
            <xsl:value-of select="$code/@codeSystem"/>
        </xsl:variable>
        <xsl:variable name="this-code">
            <xsl:value-of select="$code/@code"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$code/n1:originalText">
                <xsl:value-of select="$code/n1:originalText"/>
            </xsl:when>
            <xsl:when test="$code/@displayName">
                <xsl:value-of select="$code/@displayName"/>
            </xsl:when>
            <!--
      <xsl:when test="$the-valuesets/*/voc:system[@root=$this-codeSystem]/voc:code[@value=$this-code]/@displayName">
        <xsl:value-of select="$the-valuesets/*/voc:system[@root=$this-codeSystem]/voc:code[@value=$this-code]/@displayName"/>
      </xsl:when>
      -->
            <xsl:otherwise>
                <xsl:value-of select="$this-code"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- show classCode -->
    <xsl:template name="show-actClassCode">
        <xsl:param name="clsCode"/>
        <xsl:choose>
            <xsl:when test=" $clsCode = 'ACT' ">
                <xsl:text>healthcare service</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ACCM' ">
                <xsl:text>accommodation</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ACCT' ">
                <xsl:text>account</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ACSN' ">
                <xsl:text>accession</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ADJUD' ">
                <xsl:text>financial adjudication</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'CONS' ">
                <xsl:text>consent</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'CONTREG' ">
                <xsl:text>container registration</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'CTTEVENT' ">
                <xsl:text>clinical trial timepoint event</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'DISPACT' ">
                <xsl:text>disciplinary action</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ENC' ">
                <xsl:text>encounter</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'INC' ">
                <xsl:text>incident</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'INFRM' ">
                <xsl:text>inform</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'INVE' ">
                <xsl:text>invoice element</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'LIST' ">
                <xsl:text>working list</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'MPROT' ">
                <xsl:text>monitoring program</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'PCPR' ">
                <xsl:text>care provision</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'PROC' ">
                <xsl:text>procedure</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'REG' ">
                <xsl:text>registration</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'REV' ">
                <xsl:text>review</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'SBADM' ">
                <xsl:text>substance administration</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'SPCTRT' ">
                <xsl:text>speciment treatment</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'SUBST' ">
                <xsl:text>substitution</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'TRNS' ">
                <xsl:text>transportation</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'VERIF' ">
                <xsl:text>verification</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'XACT' ">
                <xsl:text>financial transaction</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show participationType -->
    <xsl:template name="show-participationType">
        <xsl:param name="ptype"/>
        <xsl:choose>
            <xsl:when test=" $ptype='PPRF' ">
                <xsl:text>primary performer</xsl:text>
            </xsl:when>
            <xsl:when test=" $ptype='PRF' ">
                <xsl:text>performer</xsl:text>
            </xsl:when>
            <xsl:when test=" $ptype='VRF' ">
                <xsl:text>verifier</xsl:text>
            </xsl:when>
            <xsl:when test=" $ptype='SPRF' ">
                <xsl:text>secondary performer</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show participationFunction -->
    <xsl:template name="show-participationFunction">
        <xsl:param name="pFunction"/>
        <xsl:choose>
            <!-- From the HL7 v3 ParticipationFunction code system -->
            <xsl:when test=" $pFunction = 'ADMPHYS' ">
                <xsl:text>(admitting physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'ANEST' ">
                <xsl:text>(anesthesist)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'ANRS' ">
                <xsl:text>(anesthesia nurse)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'ATTPHYS' ">
                <xsl:text>(attending physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'DISPHYS' ">
                <xsl:text>(discharging physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'FASST' ">
                <xsl:text>(first assistant surgeon)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'MDWF' ">
                <xsl:text>(midwife)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'NASST' ">
                <xsl:text>(nurse assistant)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'PCP' ">
                <xsl:text>(primary care physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'PRISURG' ">
                <xsl:text>(primary surgeon)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'RNDPHYS' ">
                <xsl:text>(rounding physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'SASST' ">
                <xsl:text>(second assistant surgeon)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'SNRS' ">
                <xsl:text>(scrub nurse)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'TASST' ">
                <xsl:text>(third assistant)</xsl:text>
            </xsl:when>
            <!-- From the HL7 v2 Provider Role code system (2.16.840.1.113883.12.443) which is used by HITSP -->
            <xsl:when test=" $pFunction = 'CP' ">
                <xsl:text>(consulting provider)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'PP' ">
                <xsl:text>(primary care provider)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'RP' ">
                <xsl:text>(referring provider)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'MP' ">
                <xsl:text>(medical home provider)</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="formatDateTime">
        <xsl:param name="date"/>
        <!-- month -->
        <xsl:variable name="month" select="substring ($date, 5, 2)"/>
        <xsl:choose>
            <xsl:when test="$month='01'">
                <xsl:text>January </xsl:text>
            </xsl:when>
            <xsl:when test="$month='02'">
                <xsl:text>February </xsl:text>
            </xsl:when>
            <xsl:when test="$month='03'">
                <xsl:text>March </xsl:text>
            </xsl:when>
            <xsl:when test="$month='04'">
                <xsl:text>April </xsl:text>
            </xsl:when>
            <xsl:when test="$month='05'">
                <xsl:text>May </xsl:text>
            </xsl:when>
            <xsl:when test="$month='06'">
                <xsl:text>June </xsl:text>
            </xsl:when>
            <xsl:when test="$month='07'">
                <xsl:text>July </xsl:text>
            </xsl:when>
            <xsl:when test="$month='08'">
                <xsl:text>August </xsl:text>
            </xsl:when>
            <xsl:when test="$month='09'">
                <xsl:text>September </xsl:text>
            </xsl:when>
            <xsl:when test="$month='10'">
                <xsl:text>October </xsl:text>
            </xsl:when>
            <xsl:when test="$month='11'">
                <xsl:text>November </xsl:text>
            </xsl:when>
            <xsl:when test="$month='12'">
                <xsl:text>December </xsl:text>
            </xsl:when>
        </xsl:choose>
        <!-- day -->
        <xsl:choose>
            <xsl:when test='substring ($date, 7, 1)="0"'>
                <xsl:value-of select="substring ($date, 8, 1)"/>
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="substring ($date, 7, 2)"/>
                <xsl:text>, </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- year -->
        <xsl:value-of select="substring ($date, 1, 4)"/>
    </xsl:template>
    <!-- convert to lower case -->
    <xsl:template name="caseDown">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:value-of
                select="translate($data, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"
            />
        </xsl:if>
    </xsl:template>
    <!-- convert to upper case -->
    <xsl:template name="caseUp">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:value-of
                select="translate($data,'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"
            />
        </xsl:if>
    </xsl:template>
    <!-- convert first character to upper case -->
    <xsl:template name="firstCharCaseUp">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:call-template name="caseUp">
                <xsl:with-param name="data" select="substring($data,1,1)"/>
            </xsl:call-template>
            <xsl:value-of select="substring($data,2)"/>
        </xsl:if>
    </xsl:template>
    <!-- show-noneFlavor -->
    <xsl:template name="show-noneFlavor">
        <xsl:param name="nf"/>
        <xsl:choose>
            <xsl:when test=" $nf = 'NI' ">
                <xsl:text>no information</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'INV' ">
                <xsl:text>invalid</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'MSK' ">
                <xsl:text>masked</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'NA' ">
                <xsl:text>not applicable</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'UNK' ">
                <xsl:text>unknown</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'OTH' ">
                <xsl:text>other</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <!-- copy attributes and translate them form source to target (to allow user defined CSS -->
    <xsl:template name="output-attrs">
        <xsl:variable name="elem-name" select="local-name(.)"/>
        <xsl:for-each select="@*">
            <xsl:variable name="attr-name" select="local-name(.)"/>
            <xsl:variable name="source" select="."/>
            <xsl:variable name="lcSource" select="translate($source, $uc, $lc)"/>
            <xsl:variable name="scrubbedSource" select="translate($source, $simple-sanitizer-match, $simple-sanitizer-replace)"/>
            <xsl:choose>
                <xsl:when test="contains($lcSource,'javascript')">
                    <p><xsl:value-of select="$javascript-injection-warning"/></p>
                    <xsl:message terminate="yes"><xsl:value-of select="$javascript-injection-warning"/></xsl:message>
                </xsl:when>
                <xsl:when test="$attr-name='styleCode'">
                    <xsl:apply-templates select="."/>
                </xsl:when>
                <xsl:when test="not(document('')/xsl:stylesheet/xsl:variable[@name='table-elem-attrs']/in:tableElems/in:elem[@name=$elem-name]/in:attr[@name=$attr-name])">
                    <xsl:message><xsl:value-of select="$attr-name"/> is not legal in <xsl:value-of select="$elem-name"/></xsl:message>
                </xsl:when>
                <xsl:when test="not($source = $scrubbedSource)">
                    <p><xsl:value-of select="$malicious-content-warning"/> </p>
                    <xsl:message><xsl:value-of select="$malicious-content-warning"/></xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Allowed table attributes -->
    <xsl:variable name="table-elem-attrs">
        <in:tableElems>
            <in:elem name="table">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="summary"/>
                <in:attr name="width"/>
                <in:attr name="border"/>
                <in:attr name="frame"/>
                <in:attr name="rules"/>
                <in:attr name="cellspacing"/>
                <in:attr name="cellpadding"/>
            </in:elem>
            <in:elem name="thead">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="tfoot">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="tbody">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="colgroup">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="span"/>
                <in:attr name="width"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="col">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="span"/>
                <in:attr name="width"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="tr">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="th">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="abbr"/>
                <in:attr name="axis"/>
                <in:attr name="headers"/>
                <in:attr name="scope"/>
                <in:attr name="rowspan"/>
                <in:attr name="colspan"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="td">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="abbr"/>
                <in:attr name="axis"/>
                <in:attr name="headers"/>
                <in:attr name="scope"/>
                <in:attr name="rowspan"/>
                <in:attr name="colspan"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
        </in:tableElems>
    </xsl:variable>
    
    <!-- Add OpenCDE Viewer CSS -->
    <xsl:template name="addCSS">
            <link href="./assets/css/font-awesome.min.css" rel="stylesheet" type="text/css"/>
            <link href="./assets/css/font-health.css" rel="stylesheet" type="text/css"/>
            <link href="./assets/css/bootstrap.min.css" rel="stylesheet" type="text/css"/>
            <link href="./assets/css/style.css" rel="stylesheet" type="text/css"/>
            <link href="./config/custom.css" rel="stylesheet" type="text/css"/>
    </xsl:template>

    
    <!-- Include Java Scripts to improve user expirience -->
    <xsl:template name="addJSScripts">
        <script src="./assets/js/jquery.min.js" type="text/javascript"></script>
        <script src="./assets/js/bootstrap.min.js" type="text/javascript"></script>
        <script src="./assets/js/jquery.slimscroll.min.js" type="text/javascript"></script>
        <script src="./assets/js/jquery.highlight.js" type="text/javascript"></script>
        <script src="./assets/js/visor.js"></script>
        <script type="text/javascript">

        <xsl:call-template name="initialSections">
            <xsl:with-param name="content" select="n1:component/n1:structuredBody"/>
        </xsl:call-template>
        <xsl:call-template name="keywordsToSearch"/>

        <![CDATA[
        $( window ).load(function() {
            Visor.init();
            Visor.summary(summaryList);
            Visor.search(keyToSearch);            
        });

        function resizeIframe(f) {
            var cont =  f.contentWindow.document.body   
            console.log(cont.scrollHeight);      
            console.log(cont.scrollHeight);      
            f.height = (cont.offsetHeight+35) + "px";
        }
        ]]>
        </script>
    </xsl:template>
    
    <!-- Template urlencode, used to Urlencode DICOM Wado URL, maintaining XSLT version 1.0 -->
    <xsl:template name="url-encode">
    <xsl:param name="str"/>   
    <xsl:if test="$str">
      <xsl:variable name="first-char" select="substring($str,1,1)"/>
      <xsl:choose>
        <xsl:when test="contains($safe,$first-char)">
          <xsl:value-of select="$first-char"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="codepoint">
            <xsl:choose>
              <xsl:when test="contains($ascii,$first-char)">
                <xsl:value-of select="string-length(substring-before($ascii,$first-char)) + 32"/>
              </xsl:when>
              <xsl:when test="contains($latin1,$first-char)">
                <xsl:value-of select="string-length(substring-before($latin1,$first-char)) + 160"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:message terminate="no">Warning: string contains a character that is out of range! Substituting "?".</xsl:message>
                <xsl:text>63</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
        <xsl:variable name="hex-digit1" select="substring($hex,floor($codepoint div 16) + 1,1)"/>
        <xsl:variable name="hex-digit2" select="substring($hex,$codepoint mod 16 + 1,1)"/>
        <xsl:value-of select="concat('%',$hex-digit1,$hex-digit2)"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="string-length($str) &gt; 1">
        <xsl:call-template name="url-encode">
          <xsl:with-param name="str" select="substring($str,2)"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
    </xsl:template>
    <!-- end urlencode -->
</xsl:stylesheet>
