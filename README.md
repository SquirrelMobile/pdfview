
# pdfView for Android and iOS

Module for display pdf in a view in titanium, with zoom + scroll.

Uses [AndroidPdfViewer](https://github.com/barteksc/AndroidPdfViewer) on Android and [PDFKit](https://developer.apple.com/documentation/pdfkit) (PDFView) on iOS.


<img src="https://github.com/SquirrelMobile/pdfview/blob/master/screen/gifExample.gif?raw=true" width="200" >

## Module Naming

	fr.squirrel.pdfview

## Requirements (Android):
* Titanium 13.3.0
* add the following lines to your app/platform/android/build.gradle file:
```
repositories {
	maven { url 'https://jitpack.io' }
}
```

## Requirements (iOS):
* Titanium 13.3.0.GA+
* iOS 12+

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
- <b>file (Ti.Filesystem.File or Ti.Blob)</b> : this property is for load a pdf directly by a file.
- <b>spacing</b> : this property is for edit the spacing between pages in dp.
- <b>password (string)</b> : password for a protected PDF file
- <b>nightMode (boolean)</b> : night mode (iOS: only darkens the background, page content is not inverted)
- <b>pageFling (boolean)</b> : make a fling change only a single page like ViewPager
- <b>pageSnap (boolean)</b> : snap pages to screen boundaries at the end of a scroll
- <b>swipeHorizontal (boolean)</b> : horizontal swipe
- <b>fitPolicy (string)</b> : how a page is scaled to the view: `"width"` fits the page width (default), `"height"` fits the page height, `"both"` fits the whole page into the view. The fit uses the largest page of the document, so all pages share one scale. `minZoom` and `maxZoom` are relative to this fit.
- <b>minZoom (float)</b> : sets min zoom level (default 1)
- <b>midZoom (float)</b> : sets mid zoom level (default 1.75, Android only)
- <b>maxZoom (float)</b> : sets max zoom level (default 3)
* <b>nestedScrolling (boolean)</b> : enabled nested srcolling (default: false, Android only)
- <b>pageNumber (int)</b> : sets the initial page number to display (default 0). Number is the page index starting with 0 (page 1).
- <b>pageCount (int, read-only)</b> : total number of pages of the loaded document. The value is 0 before the document loads and after `clear()`. Use the `load` event to know when the document is loaded.
- <b>textSelection (boolean)</b> : allow selecting text in the PDF with a long-press (default: false, iOS only - Android renders pages as bitmaps and has no text selection). When enabled, a long-press on text starts the selection <i>and</i> fires the `longpress` event; keep it disabled if you only want the event.

## Events

- <b>error</b>: with `message`, `passwordError` (true if password is wrong)
- <b>load</b>: fired once when a document is loaded, with `pageCount` (total number of pages). It fires before the first `pageChanged` event. A load failure fires `error` instead.
- <b>pageChanged</b>: fired when the displayed page changes, with `currentPage` (0-based page index) and `pageCount` (total number of pages)
- <b>link</b>: fired when a link inside the PDF is tapped, with `url` (the link is not opened automatically)
- <b>longpress</b>: fired when the user long-presses the PDF, with `x` and `y` (view-relative coordinates in dp/points). If the press hits a link inside the PDF, `url` contains its target (otherwise `url` is not set).

```js
pdfView.addEventListener("longpress", function(e) {
	if (e.url) {
		console.log("longpress on link " + e.url);
	} else {
		console.log("longpress at " + e.x + "/" + e.y);
	}
});
```

## Methods

- <b>clear()</b>: clear the pdfview
