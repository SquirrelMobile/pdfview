
# pdfView for Android

Module for display pdf in a view in titanium, with zoom + scroll.


<img src="https://github.com/SquirrelMobile/pdfview/blob/master/screen/gifExample.gif?raw=true" width="200" >

## Module Naming

	fr.squirrel.pdfview

## Example usage
Load a pdf with "url" property

```js
var pdfView = require("fr.squirrel.pdfview").createView({
 height : Ti.UI.FILL,
 width : Ti.UI.FILL,
 url : "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
});
$.container.add(pdfView);
```

Or by "file" property

```js
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
```

opening a password protected local file
```js
const win = Ti.UI.createWindow();

var file = Ti.Filesystem.getFile(Ti.Filesystem.externalStorageDirectory, "pwd.pdf");

if (!file.exists()) {
	// copy it from /assets/ to the external storage
	var source = Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, "pwd.pdf");
	file.write(source.read());
}

var pdfView = require("fr.squirrel.pdfview").createView({
	height: Ti.UI.FILL,
	width: Ti.UI.FILL,
	password: "yourPassword",
	file: file
});

win.add(pdfView);
win.open();
```

## Properties

- <b>url (string)</b> : this property is for load a pdf directly by url.
- <b>file (Ti.Filesystem.File)</b> : this property is for load a pdf directly by a file.
- <b>spacing</b> : this property is for edit the spacing between pages in dp.
- <b>password (string)</b> : password for a protected PDF file
- <b>nightMode (boolean)</b> : night mode
- <b>pageFling (boolean)</b> : make a fling change only a single page like ViewPager
- <b>pageSnap (boolean)</b> : snap pages to screen boundaries at the end of a scroll
- <b>swipeHorizontal (boolean)</b> : horizontal swipe
- <b>minZoom (float)</b> : sets min zoom level (default 1)
- <b>midZoom (float)</b> : sets mid zoom level (default 1.75)
- <b>maxZoom (float)</b> : sets max zoom level (default 3)
* <b>nestedScrolling (boolean)</b> : enabled nested srcolling (default: false)
- <b>pageNumber (int)</b> : sets the initial page number to display (default 0)

## Events

- <b>error</b>: with `message`, `passwordError` (true if password is wrong)
