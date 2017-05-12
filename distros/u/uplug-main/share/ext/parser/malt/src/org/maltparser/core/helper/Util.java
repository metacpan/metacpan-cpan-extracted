package org.maltparser.core.helper;


import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;

import org.apache.log4j.Logger;
import org.maltparser.core.config.ConfigurationException;
import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.plugin.Plugin;
import org.maltparser.core.plugin.PluginLoader;

/**
*
*
* @author Johan Hall
*/
public class Util {
	  private static final int BUFFER = 4096;
	  private static final char AMP_CHAR = '&';
	  private static final char LT_CHAR = '<';
	  private static final char GT_CHAR = '>';
	  private static final char QUOT_CHAR = '"';
	  private static final char APOS_CHAR = '\'';
	
	  public static String xmlEscape(String str) {
		  boolean needEscape = false;
		  char c;
		  for (int i = 0; i < str.length(); i++) {
			  c = str.charAt(i);
			  if (c == AMP_CHAR || c == LT_CHAR || c == GT_CHAR || c == QUOT_CHAR || c == APOS_CHAR) {
				  needEscape = true;
				  break;
			  }
		  }
		  if (!needEscape) {
			  return str;
		  }
		  final StringBuilder sb = new StringBuilder();
		  for (int i = 0; i < str.length(); i++) {
			  c = str.charAt(i);
			  if (str.charAt(i) == AMP_CHAR) {
				  sb.append("&amp;");
			  } else if ( str.charAt(i) == LT_CHAR) {
				  sb.append("&lt;");
			  } else if (str.charAt(i) == GT_CHAR) {
				  sb.append("&gt;");
			  } else if (str.charAt(i) == QUOT_CHAR) {
				  sb.append("&quot;");
			  } else if (str.charAt(i) == APOS_CHAR) {
				  sb.append("&apos;");
			  } else {
				  sb.append(c);
			  }
		  }
		  return sb.toString();
	  }

	/**
	 * Search for a file according the following priority:
	 * <ol>
	 * <li>The local file system
	 * <li>Specified as an URL (starting with http:, file:, ftp: or jar:
	 * <li>MaltParser distribution file (malt.jar)
	 * <li>MaltParser plugins
	 * </ol>
	 * 
	 * If the file string is found, an URL object is returned, otherwise <b>null</b>
	 * 
	 * @param fileString	the file string to convert into an URL.
	 * @return an URL object, if the file string is found, otherwise <b>null</b>
	 * @throws MaltChainedException
	 */
	public static URL findURL(String fileString) throws MaltChainedException {
		File specFile = new File(fileString);

		try {
			if (specFile.exists()) {
				// found the file in the file system
				return new URL("file:///"+specFile.getAbsolutePath());
			} else if (fileString.startsWith("http:") || fileString.startsWith("file:") || fileString.startsWith("ftp:") || fileString.startsWith("jar:")) {
				// the input string is an URL string starting with http, file, ftp or jar
				return new URL(fileString);
			} else {
				return findURLinJars(fileString);
			} 
		} catch (MalformedURLException e) {
			throw new MaltChainedException("Malformed URL: "+fileString, e);
		}
	}
	
	public static URL findURLinJars(String fileString) throws MaltChainedException {
		try {
			// search in malt.jar and its plugins
			if (Thread.currentThread().getClass().getResource(fileString) != null) {
				// found the input string in the malt.jar file
				return Thread.currentThread().getClass().getResource(fileString);
			} else { 
				 for (Plugin plugin : PluginLoader.instance()) {
					URL url = null;
					if (!fileString.startsWith("/")) {
						url = new URL("jar:"+plugin.getUrl() + "!/" + fileString);
					} else {
						url = new URL("jar:"+plugin.getUrl() + "!" + fileString);
					}
					
					try { 
						InputStream is = url.openStream();
						is.close();
					} catch (IOException e) {
						continue;
					}
					// found the input string in one of the plugins
					return url;
				} 
				// could not convert the input string into an URL
				return null; 
			}
		} catch (MalformedURLException e) {
			throw new MaltChainedException("Malformed URL: "+fileString, e);
		}
	}
	
	public static int simpleTicer(Logger logger, long startTime, int nTicxRow, int inTic, int subject) {
		logger.info(".");
		int tic = inTic + 1;
		if (tic >= nTicxRow) {
			ticInfo(logger, startTime, subject);
			tic = 0;
		}
		return tic;
	}
	
	public static void startTicer(Logger logger, long startTime, int nTicxRow, int subject) {
		logger.info(".");
		for (int i = 1; i <= nTicxRow; i++) {
			logger.info(" ");
		}
		ticInfo(logger, startTime, subject);
	}
	
	public static void endTicer(Logger logger, long startTime, int nTicxRow, int inTic, int subject) {
		for (int i = inTic; i <= nTicxRow; i++) {
			logger.info(" ");
		}
		ticInfo(logger, startTime, subject);
	}
	
	private static void ticInfo(Logger logger, long startTime, int subject) {
		logger.info("\t");
		int a = 1000000;
		if (subject != 0) {
			while (subject/a == 0) {
				logger.info(" ");
				a /= 10;
			}
		} else {
			logger.info("      ");
		}
		logger.info(subject);
		logger.info("\t");
		long time = (System.currentTimeMillis()-startTime)/1000;
		a = 1000000;
		if (time != 0) {
			while (time/a == 0 ) {
				logger.info(" ");
				a /= 10;
			}
			logger.info(time);
			logger.info("s");
		} else {
			logger.info("      0s");
		}
		logger.info("\t");
		long memory =  (Runtime.getRuntime().totalMemory() -  Runtime.getRuntime().freeMemory())/1000000;
		a = 1000000;
		if (memory != 0) {
			while (memory/a == 0 ) {
				logger.info(" ");
				a /= 10;
			}
			logger.info(memory);
			logger.info("MB\n");
		} else {
			logger.info("      0MB\n");
		}
	}
	
	public static void copyfile(String source, String destination) throws MaltChainedException {
    	try {
    		byte[] readBuffer = new byte[BUFFER];
	    	BufferedInputStream bis = new BufferedInputStream(new FileInputStream(source));
	        BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(destination), BUFFER);
	        int n = 0;
		    while ((n = bis.read(readBuffer, 0, BUFFER)) != -1) {
		    	bos.write(readBuffer, 0, n);
		    }
	        bos.flush();
	        bos.close();
	        bis.close();
		} catch (FileNotFoundException e) {
			throw new MaltChainedException("The destination file '"+destination+"' cannot be created when coping the file. ", e);
		} catch (IOException e) {
			throw new MaltChainedException("The source file '"+source+"' cannot be copied to destination '"+destination+"'. ", e);
		}
	}

}
