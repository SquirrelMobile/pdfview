
# pdfView for Android

Module for display pdf in a view in titanium, with zoom + scroll.


<img src="https://github.com/SquirrelMobile/pdfview/blob/master/screen/ScreenshotExample.jpg?raw=true" width="200" >

## Module Naming

	fr.squirrel.pdfview

## Example usage
Load a pdf with "url" property

	  var pdfView = require("fr.squirrel.pdfview").createView({
	   height : Ti.UI.FILL,
	   width : Ti.UI.FILL,
	   url : "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
	  });
	  $.container.add(pdfView);

Or by "file" property

	 var downloadingFileUrl = "https://monurl/sample.pdf"
	 var file = Titanium.Filesystem.getFile(Titanium.Filesystem.externalStorageDirectory,"./sample.pdf");
	 var httpC = Ti.Network.createHTTPClient();

	 httpC.onload = function(httpClient){

	  var pdfView = require("fr.squirrel.pdfview").createView({
	    height : Ti.UI.FILL,
	    width : Ti.UI.FILL,
	    file : file
	  });
	  $.container.add(pdfView);
	 };
	 httpC.open("GET", downloadingFileUrl);
	 httpC.setFile(file.getNativePath());
	 httpC.send(null);


## Properties

- url (string) : this property is for load a pdf directly by url.
- file (Ti.Filesystem.File) : this property is for load a pdf directly by a file.
- spacing : this property is for edit the spacing between pages in dp.
