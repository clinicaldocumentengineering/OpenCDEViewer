![logo](http://clinicaldocumentengineering.com/assets/logo/OpenCDA_logo_grey.png) OpenCDE Viewer
=======
__OpenCDE Viewer__ is a web based component, that just requires a web browser to display HL7 CDA documents. 

### Getting Started
  *  OpenCDE Viewer is a lightweight CDA viewer, that only requires a Web Browser to display these kind of documents.
  *  OpenCDE Viewer works as a standalone component or is easily embedded into existing solutions.
  *  OpenCDE Viewer does not require any software installation, once source files are copied, just double click on CDA files. 

### Documentation
For documentation on OpenCDE Viewer please review /doc folder. It includes:
  * PDF slides documentation.
  * Youtube video URL: https://youtu.be/Hw5yRqcPbyE 

### Main features
  * HL7 CDA.xsl rendering plus: 
    * PDF Documents, embedded as a base64.
    * Structured documents where sections text is included as base64 encoded HTML.
    * ObservationMedia elements that include base64 encoded jpeg or gif images.
    * User defined style sheets.
  * One line header summary plus a full header view.
  * Sections explorer/navigation tree.
  * Notifications: relationships & keywords.

### Download and Test
To test OpenCDE Viewer, just click on "Clone or Download" at [GitHub repository]( https://github.com/clinicaldocumentengineering/OpenCDEViewer), and download zip. Sample documents included at /src are already associated with OpenCDEViewer.xsl, so just open at your web browser and enjoy.
To test with your CDA, copy it to /src folder and include the following processing instructions into: <?xml-stylesheet type='text/xsl' href='OpenCDEViewer.xsl' ?>

### Browsers Compatibility
Due to most browsers security restrictions, OpenCDEViewer.xsl and input CDAs documents must be at the same folder (specially when working in local mode), these the reason why source xslt and sample documents are at the same folder.
Provided source code is prepared to be tested locally, without needing a web server.
 * __Firefox__: all features run in both local/server mode.
 * __Chrome__: regarding some security restrictions on referencing local xslt (see: http://stackoverflow.com/questions/3828898/can-chrome-be-made-to-perform-an-xsl-transform-on-a-local-file) by default OpenCDE Viewer won't run on Firefox, to overcome that, just runt Chrome with --allow-file-access-from-files parameter. Inside a web browser OpenCDE Viewer runs perfect.
 * __Safari__: all features run in both local/server mode.
 * __Internet explorer__: all features run in both local/server mode except embedded PDF and HTML narrative text, as for a browser restriction as described at http://stackoverflow.com/questions/18627370/workaround-of-showing-a-base64-pdf-on-ie9.

### More on OpenCDE platform
OpenCDE Viewer component, is part of a full solution for sharing clinical documents, from the OpenCDE platform. You can find more information on that, at company web site (http://clinicaldocumentengineering.com/)
![logo](http://clinicaldocumentengineering.com/assets/logo/OpenCDE_Logo_grey.png)
