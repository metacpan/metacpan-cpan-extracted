package org.maltparser.core.helper;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.net.URLDecoder;
import java.util.jar.Attributes;
import java.util.jar.JarFile;
import java.util.jar.Manifest;

import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.options.OptionManager;
/**
*
*
* @author Johan Hall
*/
public class SystemInfo {
	private static SystemInfo uniqueInstance = new SystemInfo();
	private static String version;
	private static String buildDate;
	private static Attributes manifestAttributes;
	private static File maltJarPath;
	
	private SystemInfo() {
		try {
			getManifestInfo();
			
			String[] jarfiles = System.getProperty("java.class.path").split(File.pathSeparator);
			for (int i = 0; i < jarfiles.length; i++) {
				if (jarfiles[i].endsWith("malt.jar")) {
					maltJarPath = new File(new File(jarfiles[i]).getAbsolutePath());
				} 
			}
		} catch (MaltChainedException e) {
			if (SystemLogger.logger().isDebugEnabled()) {
				SystemLogger.logger().debug("",e);
			} else {
				SystemLogger.logger().error(e.getMessageChain());
			}
			System.exit(1);
		}
	}
	
	/**
	* Returns a reference to the single instance.
	*/
	public static SystemInfo instance() {
		return uniqueInstance;
	}
	
	/**
	 * Returns the application header
	 * 
	 * @return the application header
	 */
	public static String header() {
		StringBuilder sb = new StringBuilder();
		sb.append(
				"-----------------------------------------------------------------------------\n"+
				"                          MaltParser "+version+"                             \n"+
				"-----------------------------------------------------------------------------\n"+
				"         MALT (Models and Algorithms for Language Technology) Group          \n"+
				"             Vaxjo University and Uppsala University                         \n"+
				"                             Sweden                                          \n"+
				"-----------------------------------------------------------------------------\n");
		return sb.toString();
	}
	
	/**
	 * Returns a short version of the help
	 * 
	 * @return a short version of the help
	 */
	public static String shortHelp() {
		StringBuilder sb = new StringBuilder();
		sb.append("\n"+
				"Usage: \n"+
				"   java -jar malt.jar -f <path to option file> <options>\n"+
				"   java -jar malt.jar -h for more help and options\n\n"+
				OptionManager.instance().getOptionDescriptions().toStringOptionGroup("system")+
				"Documentation: docs/index.html\n");
		return sb.toString();
	}
	
	/**
	 * Returns a set of attributes present in the jar manifest file
	 * 
	 * @return a set of attributes present in the jar manifest file
	 */
	public static Attributes getManifestAttributes() {
		return manifestAttributes;
	}
	
	/**
	 * Returns the version number as string
	 * 
	 * @return the version number as string
	 */
	public static String getVersion() {
		return version;
	}
	
	/**
	 * Returns the build date
	 * 
	 * @return the build date
	 */
	public static String getBuildDate() {
		return buildDate;
	}
	
	public static File getMaltJarPath() {
		return maltJarPath;
	}
	
	/**
	 * Loads the manifest attributes from the manifest in the jar-file
	 * 
	 * @throws MaltChainedException
	 */
	private void getManifestInfo() throws MaltChainedException {
	   try {
            URL codeBase = SystemInfo.class.getProtectionDomain().getCodeSource().getLocation();
            if(codeBase != null && codeBase.getPath().endsWith(".jar")) {
            	JarFile jarfile = new JarFile(URLDecoder.decode(codeBase.getPath(),java.nio.charset.Charset.defaultCharset().name()));
                Manifest manifest = jarfile.getManifest();
                Attributes manifestAttributes = manifest.getMainAttributes();
                version = manifestAttributes.getValue("Implementation-Version");
                buildDate = manifestAttributes.getValue("Build-Date");
            }
        } catch(IOException e) {
        	version = "";
        	buildDate = "Not available";
        	e.printStackTrace();
        }
	}
}
