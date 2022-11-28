package fr.squirrel.pdfview;

import android.R;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.RelativeLayout;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiFileProxy;
import org.appcelerator.titanium.io.TiFile;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.util.TiRHelper;
import org.appcelerator.titanium.util.TiRHelper.ResourceNotFoundException;
import org.appcelerator.titanium.view.TiUIView;

import com.github.barteksc.pdfviewer.PDFView;
import com.github.barteksc.pdfviewer.listener.OnDrawListener;
import com.github.barteksc.pdfviewer.listener.OnErrorListener;
import com.shockwave.pdfium.PdfPasswordException;

public class PdfViewer extends TiUIView implements OnErrorListener {

	int MODE_URL = 0;
	int MODE_FILE = 1;


	PDFView pdfView;
	int space = 20;
	int layout_drawer_main = 0;
	int mode = MODE_URL;
	String currentUrl;
	File currentFile;
	String path;
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
		}
		catch (ResourceNotFoundException e) {
			Log.e("TESTMODULE", "XML resources could not be found!!!");
		}
		Resources resources = proxy.getActivity().getResources();
		String packageName = proxy.getActivity().getPackageName();
		LayoutInflater inflater = LayoutInflater.from(proxy.getActivity());
		int resId_ratingBar = resources.getIdentifier("pdfView","id", packageName);
		RelativeLayout rl = (RelativeLayout) inflater.inflate(layout_drawer_main, null, false);
		pdfView = (PDFView)rl.findViewById(resId_ratingBar);
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
			setUrl(TiConvert.toString(arg0.equals("url")));
		}
		if (arg0.equals("spacing")) {
			this.space = TiConvert.toInt(arg0.equals("spacing"));
			reload();
		}
		if (arg0.equals("file")) {
			setFile(arg0.equals("file"));
		}
	}

	public void setMaxZoom(Float value){
		maxZoom = value;
		pdfView.setMaxZoom(maxZoom);
	}

	public void setMinZoom(Float value){
		minZoom = value;
		pdfView.setMinZoom(minZoom);
	}

	public void setMidZoom(Float value){
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
		Object file = f;
		TiFileProxy tiFile = (TiFileProxy) file;
		String absolutePath = tiFile.getBaseFile().getNativeFile().getAbsolutePath();
		this.currentFile = new File(absolutePath);
		reload();
	}


	private void reload() {
		if (mode == MODE_URL) {
			if(this.currentUrl != null) {
				new RetrivePDFStream().execute(this.currentUrl);
			}
		}
		else if(mode == MODE_FILE) {
			if(this.currentFile != null) {
				pdfView.fromFile(this.currentFile)
						.password(password)
						.pageSnap(pageSnap)
						.pageFling(pageFling)
						.onError(this)
						.swipeHorizontal(swipeHorizontal)
						.nightMode(nightMode)
						.spacing(space)
						.load();
				if (nestedScrolling) {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
						pdfView.setNestedScrollingEnabled(nestedScrolling);
					}
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
					.swipeHorizontal(swipeHorizontal)
					.nightMode(nightMode)
					.spacing(space)
					.load();
			if (nestedScrolling) {
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
					pdfView.setNestedScrollingEnabled(nestedScrolling);
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
	}


}
