package fr.squirrel.pdfview;

import android.content.res.Resources;
import android.os.AsyncTask;
import android.view.LayoutInflater;
import android.widget.RelativeLayout;

import com.github.barteksc.pdfviewer.PDFView;
import com.github.barteksc.pdfviewer.link.LinkHandler;
import com.github.barteksc.pdfviewer.listener.OnErrorListener;
import com.github.barteksc.pdfviewer.model.LinkTapEvent;
import com.shockwave.pdfium.PdfPasswordException;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiBlob;
import org.appcelerator.titanium.TiFileProxy;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.util.TiRHelper;
import org.appcelerator.titanium.util.TiRHelper.ResourceNotFoundException;
import org.appcelerator.titanium.view.TiUIView;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class PdfViewer extends TiUIView implements OnErrorListener, LinkHandler {


    int MODE_URL = 0;
    int MODE_FILE = 1;
    int MODE_BLOB = 2;

    PDFView pdfView;
    int space = 20;
    int pageNumber = 0;
    int layout_drawer_main = 0;
    int mode = MODE_URL;
    String currentUrl;
    File currentFile;
    byte[] currentStream;
    String password = null;
    boolean pageSnap = false;
    boolean nightMode = false;
    boolean pageFling = false;
    boolean swipeHorizontal = false;
    boolean nestedScrolling = false;
    float maxZoom = 3.0f;
    float minZoom = 1.0f;
    float midZoom = 1.75f;

    public PdfViewer(TiViewProxy proxy) {
        super(proxy);
        try {
            layout_drawer_main = TiRHelper.getResource("layout.pdfview");
        } catch (ResourceNotFoundException e) {
            Log.e("pdfviewer", "XML resources could not be found!!!");
        }
        Resources resources = proxy.getActivity().getResources();
        String packageName = proxy.getActivity().getPackageName();
        LayoutInflater inflater = LayoutInflater.from(proxy.getActivity());
        int resId_ratingBar = resources.getIdentifier("pdfView", "id", packageName);
        RelativeLayout rl = (RelativeLayout) inflater.inflate(layout_drawer_main, null, false);
        pdfView = rl.findViewById(resId_ratingBar);
        pdfView.setMaxZoom(maxZoom);
        pdfView.setMinZoom(minZoom);
        pdfView.setMidZoom(midZoom);
        setNativeView(rl);
    }

    // TODO Auto-generated constructor stub
    @Override
    public void propertyChanged(String arg0, Object arg1, Object arg2, KrollProxy arg3) {
        // TODO Auto-generated method stub

        if (arg0.equals("url")) {
            setUrl(TiConvert.toString(arg0));
        }
        if (arg0.equals("spacing")) {
            this.space = TiConvert.toInt(arg0);
            reload();
        }
        if (arg0.equals("file")) {
            setFile(arg0);
        }
        if (arg0.equals("pageNumber")) {
            this.pageNumber = TiConvert.toInt(arg2);
            try {
                pdfView.jumpTo(pageNumber, true);
            } catch (Exception e) {
                reload();
            }
        }
    }

    public void setMaxZoom(Float value) {
        maxZoom = value;
        pdfView.setMaxZoom(maxZoom);
    }

    public void setMinZoom(Float value) {
        minZoom = value;
        pdfView.setMinZoom(minZoom);
    }

    public void setMidZoom(Float value) {
        midZoom = value;
        pdfView.setMidZoom(midZoom);
    }


    @Override
    public void processProperties(KrollDict props) {
        // TODO Auto-generated method stub
        super.processProperties(props);
        if (props.containsKey("password")) {
            password = TiConvert.toString(proxy.getProperty("password"), "");
        }
        if (props.containsKey("maxZoom")) {
            maxZoom = TiConvert.toFloat(proxy.getProperty("maxZoom"));
            pdfView.setMaxZoom(maxZoom);
        }
        if (props.containsKey("minZoom")) {
            minZoom = TiConvert.toFloat(proxy.getProperty("minZoom"));
            pdfView.setMinZoom(minZoom);
        }
        if (props.containsKey("midZoom")) {
            midZoom = TiConvert.toFloat(proxy.getProperty("midZoom"));
            pdfView.setMidZoom(midZoom);
        }
        if (props.containsKey("nightMode")) {
            nightMode = TiConvert.toBoolean(proxy.getProperty("nightMode"), false);
        }
        if (props.containsKey("pageFling")) {
            pageFling = TiConvert.toBoolean(proxy.getProperty("pageFling"), false);
        }
        if (props.containsKey("swipeHorizontal")) {
            swipeHorizontal = TiConvert.toBoolean(proxy.getProperty("swipeHorizontal"), false);
        }
        if (props.containsKey("pageSnap")) {
            pageSnap = TiConvert.toBoolean(proxy.getProperty("pageSnap"), false);
        }

        if (props.containsKey("url")) {
            setUrl(TiConvert.toString(proxy.getProperty("url")));
        }
        if (props.containsKey("spacing")) {
            this.space = TiConvert.toInt(proxy.getProperty("spacing"));
            reload();
        }
        if (props.containsKey("pageNumber")) {
            this.pageNumber = TiConvert.toInt(proxy.getProperty("pageNumber"));
        }

        if (props.containsKey("file")) {
            setFile(proxy.getProperty("file"));
        }

        if (props.containsKey("nestedScrolling")) {
            nestedScrolling = TiConvert.toBoolean(proxy.getProperty("nestedScrolling"), false);
        }
    }

    public void setUrl(String s) {
        mode = MODE_URL;
        this.currentUrl = s;
        reload();
    }


    public void setFile(Object f) {
        mode = MODE_FILE;
        if (f instanceof TiBlob) {
            mode = MODE_BLOB;
            TiBlob blob = TiConvert.toBlob(f);
            this.currentStream = blob.getBytes();
            reload();
        } else {
            TiFileProxy tiFile = (TiFileProxy) f;
            String absolutePath = tiFile.getBaseFile().getNativeFile().getAbsolutePath();
            this.currentFile = new File(absolutePath);
            reload();
        }
    }


    private void reload() {
        if (mode == MODE_URL) {
            if (this.currentUrl != null) {
                new RetrivePDFStream().execute(this.currentUrl);
            }
        } else if (mode == MODE_FILE) {
            if (this.currentFile != null) {
                pdfView.fromFile(this.currentFile)
                        .password(password)
                        .pageSnap(pageSnap)
                        .pageFling(pageFling)
                        .onError(this)
                        .swipeHorizontal(swipeHorizontal)
                        .nightMode(nightMode)
                        .linkHandler(this)
                        .defaultPage(pageNumber)
                        .spacing(space)
                        .load();
                if (nestedScrolling) {
                    pdfView.setNestedScrollingEnabled(nestedScrolling);
                }
            }
        } else if (mode == MODE_BLOB) {
            if (this.currentStream != null) {
                pdfView.fromBytes(this.currentStream)
                        .password(password)
                        .pageSnap(pageSnap)
                        .pageFling(pageFling)
                        .onError(this)
                        .swipeHorizontal(swipeHorizontal)
                        .nightMode(nightMode)
                        .defaultPage(pageNumber)
                        .spacing(space)
                        .linkHandler(this)
                        .load();
                if (nestedScrolling) {
                    pdfView.setNestedScrollingEnabled(nestedScrolling);
                }
            }
        }
    }

    @Override
    public void onError(Throwable t) {
        KrollDict kd = new KrollDict();
        kd.put("message", t.getMessage());
        if (t instanceof PdfPasswordException) {
            kd.put("passwordError", true);
        }
        fireEvent("error", kd);
        Log.e("pdfview", t.getMessage());
    }

    @Override
    public void handleLinkEvent(LinkTapEvent event) {
        String uri = event.getLink().getUri();
        KrollDict kd = new KrollDict();
        kd.put("url", uri);
        fireEvent("link", kd);
    }


    class RetrivePDFStream extends AsyncTask<String, Void, InputStream> implements OnErrorListener {

        protected InputStream doInBackground(String... strings) {
            InputStream inputStream = null;
            try {
                URL uri = new URL(strings[0]);
                HttpURLConnection urlConnection = (HttpURLConnection) uri.openConnection();
                if (urlConnection.getResponseCode() == 200) {
                    inputStream = new BufferedInputStream(urlConnection.getInputStream());
                }
            } catch (IOException e) {
                return null;
            }
            return inputStream;
        }

        protected void onPostExecute(InputStream inputStream) {
            pdfView.fromStream(inputStream)
                    .password(password)
                    .pageSnap(pageSnap)
                    .onError(this)
                    .pageFling(pageFling)
                    .linkHandler(PdfViewer.this)
                    .swipeHorizontal(swipeHorizontal)
                    .nightMode(nightMode)
                    .defaultPage(pageNumber)
                    .spacing(space)
                    .load();
            if (nestedScrolling) {
                pdfView.setNestedScrollingEnabled(nestedScrolling);
            }
        }

        @Override
        public void onError(Throwable t) {
            KrollDict kd = new KrollDict();
            kd.put("message", t.getMessage());
            if (t instanceof PdfPasswordException) {
                kd.put("passwordError", true);
            }
            fireEvent("error", kd);
            Log.e("pdfview", t.getMessage());
        }
    }


}
