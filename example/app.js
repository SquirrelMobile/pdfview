var win = Ti.UI.createWindow();
win.open();
import pv from 'fr.squirrel.pdfview';

var pdfView = pv.createView({
	height: Ti.UI.FILL,
	width: Ti.UI.FILL,
	url: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
});
win.addEventListener("open", function() {
	pdfView.minZoom = 0.5;
	pdfView.maxZoom = 10;
})
win.add(pdfView);
