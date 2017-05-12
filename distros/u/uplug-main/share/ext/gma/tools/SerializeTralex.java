/**
 * <p>Title: SerializeTralex.java</p>
 * <p>Description: Convert a translation lexicon to serialized form</p>
 * <p>Copyright: Copyright (C) 2004 Ali Argyle</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Ali Argyle
 * @version 0.2
 *
 */

// To cut down the time that it takes to run a large number of files
// through GMA, a serialized version of the translation lexicon can
// be provided to GMA (optional).  This program takes in a tralex and
// creates the serialized version.

// Step 1. You will need to run from the main gma directory 
//         cd pathtogma/GMA/
// Step 2. Setup your classpath so gma utilities and tools dir
//         can be reached:
//         export CLASSPATH=lib/gma.jar:tools/
// Step 3. compile the code
//         javac tools/SerializeTralex.java
// Step 4. Run with a tralex(required) and stopfiles(optional)
//         java SerializeTralex -tralex rc/ME.tralex -xstop 
//             rc/malay.stoplist -ystop rc/english.stoplist
// Step 5. The new tralex file will be placed in the same dir
//         as the original with .serial extension.  You can now 
//         modify the config file to use the .serial file
// Note:  Do not change the extension, if the file does not end 
//        in .serial GMA will treat it as a regular file.
import java.io.*;
import java.util.Properties;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import gma.util.ByteInputFileHandler;
import gma.util.ByteParser;


public class SerializeTralex {
    //constants for command line arguments and property file
    public static final String DASH = "-";
    public static final String SPACE = " ";
    public static final String TRALEX = "tralex";
    public static final String XSTOP = "xstop";
    public static final String YSTOP = "ystop";
    public static final String SERIAL_FILE = "serialFile";

    public static final String TRANSLATION_LEXICON = "translationLexicon";
    public Map hTrans = new HashMap(); // non-english keys
    public Map vTrans = new HashMap();   // english keys
    public List xStopWords = new ArrayList();
    public List yStopWords = new ArrayList();
    public Properties properties = new Properties(); //properties
    public String translationLexiconFile = new String();
    public boolean hasxstop = false;
    public boolean hasystop = false;
    

    /**
     * Constructor.
     * @param args                  command line arguments
     */
    public SerializeTralex(String[] args) {
	try {
	    parseArguments(args);
	} catch (IllegalArgumentException e) {
	    printUsage();
	    System.out.println(e.getMessage());
	    System.exit(1);
	}
    }
	
    /**
     * Constructor.
     * @param properties            properties
     */
    public SerializeTralex(Properties properties) {
	this.properties = properties;
    }


    /**
     * Parses command line arguments.
     * @param args                              command line arguments
     * @throws IllegalArgumentException
     */
    private void parseArguments(String[] args) throws IllegalArgumentException {
	boolean gotTralex = false;
	if ((args.length % 2 ) != 0) {
	    throw new IllegalArgumentException("The number of arguments must be even.");
	}	
	for (int index = 0; index < args.length; index++) {

	    if (args[index].equals(DASH + TRALEX)) {
		properties.put(TRALEX, args[++index]);
		gotTralex = true;

	    } else if (args[index].equals(DASH + XSTOP)) {
		properties.put(XSTOP, args[++index]);
		
	    } else if (args[index].equals(DASH + YSTOP)) {
		properties.put(YSTOP, args[++index]);
	    
	    } else if (args[index].equals(DASH + SERIAL_FILE)) {
		properties.put(SERIAL_FILE, args[++index]);

	    } else {
		throw new IllegalArgumentException(args[index] + " is an invalid argument.");
	    }
	}
	if (gotTralex == false) {
	    throw new IllegalArgumentException("Tralex file must be specified at the command line.");
	}

    }

    /**
     * Forms command line argument usage.
     * @param argument              command line argument
     * @param isRequired            true for required argument
     * @param example               example command line argument
     * @return                      command line argument usage
     */
    private String formArgumentUsage(String argument, boolean isRequired, String example) {
	StringBuffer buffer = new StringBuffer();
	buffer.append("\t").append(SerializeTralex.DASH).append(argument).append(SerializeTralex.SPACE).append(argument).append("\n");
	if (isRequired) {
	    buffer.append("\t").append("required argument; ");
	} else {
	    buffer.append("\t").append("optional argument; ");
	}
	buffer.append("e.g., ").append(SerializeTralex.DASH).append(argument).append(SerializeTralex.SPACE).append(example).append("\n\n");
	return buffer.toString();
    }



    /**
     * Prints command usage.
     */
    private void printUsage() {
	StringBuffer buffer = new StringBuffer("Usage: java SerializeTralex [arguments]\n\n");
	buffer.append("where [arguments] are:\n\n");
	buffer.append(formArgumentUsage(SerializeTralex.TRALEX, true, "./tralex.O.E"));
	buffer.append(formArgumentUsage(SerializeTralex.XSTOP, false, "./french.stoplist"));
	buffer.append(formArgumentUsage(SerializeTralex.YSTOP, false, "./english.stoplist"));
	//	buffer.append(formArgumentUsage(SIMR.SIMR + "." + SIMR.OUTPUT_FILE, false, "./simrOutput.txt"));
	System.err.println(buffer.toString());
    }




    /**
     * Loads stop word list.
     * @param properties                  properties
     * @param propertyName                property name for stop word file
     * @return
     */
    private List loadStopWordList(Properties properties, String propertyName) {
	String stopWordFile = properties.getProperty(propertyName);
	ByteInputFileHandler input = new ByteInputFileHandler(stopWordFile);
	return input.readWordList();
    }

    public void readFiles() {
	System.err.println("Reading in the lexicon...(may take a while)");
	if (properties.getProperty(XSTOP) != null) {
	    xStopWords = loadStopWordList(properties, XSTOP);
	} 

	if (properties.getProperty(YSTOP) != null) {
	    yStopWords = loadStopWordList(properties, YSTOP);
	}
	translationLexiconFile = properties.getProperty(TRALEX);
	ByteInputFileHandler input = new ByteInputFileHandler(translationLexiconFile);

	// go through each line in the dictionary
	OUTER: while (input.hasLine()) {
	    List dictLine = input.nextLine();
	    ByteParser bParser = new ByteParser(dictLine);
	    List pairList = bParser.parseDictionaryLine();
	
	    if (pairList.size() != 2) {
		System.err.println("The input file is not in the correct translation lexicon format.");
		input.close();
		System.exit(1);
	    }
	    List from = (List)pairList.get(0);

	if (xStopWords.contains(from)) {
	    continue OUTER;
	} else {
	    // put second word in 'to' as a list
	    List to = (List)pairList.get(1);
	    if (!yStopWords.contains(to)) {
		//         add the pair to the dictionary
		//         hTrans (non-english keys)
		//         ------------------------------
		if ((List)hTrans.get(from) ==null) {
		    List toList = new ArrayList();
		    toList.add(to);
		    hTrans.put(from,toList);
		} else {
		    List largerList = (List)hTrans.get(from);
		    if (!largerList.contains(to)) {
			largerList.add(to);
			hTrans.put(from,largerList);
		    }
		}
		//         add the pair to the dictionary
		//         vTrans  (in the other direction)
		//         ------------------------------
		if ((List)vTrans.get(to) ==null) {
		    List fromList = new ArrayList();
		    fromList.add(from);
		    vTrans.put(to,fromList);
		} else {
		    List largerList = (List)vTrans.get(to);
		    if (!largerList.contains(from)) {
			//List largerList = new ArrayList();
			
			largerList.add(from);
			vTrans.put(to,largerList);
		    }
		}
	    } 
	}
	
	} // Matches OUTER: while
    }


    public void writeFile() {

	System.err.println("Now putting the lexicon into serial form (YUM ...  cereal!)");
	File serializedFile = new File(translationLexiconFile + ".serial");
	System.err.println("Writting to file : " + serializedFile);
	FileOutputStream outStream;
	ObjectOutputStream objStream; 
	try {
	    // setup a stream to a physical file on the filesystem
	    outStream = new FileOutputStream(serializedFile);

	    // attach a stream capable of writing objects to the stream that is
	    // connected to the file
	    objStream = new ObjectOutputStream(outStream);
	
	    // write out the two lexicon data structures
	    objStream.writeObject(hTrans);
	    objStream.writeObject(vTrans);
	
	    // close down the streams
	    objStream.close();
	    outStream.close();

	}  catch(IOException e) {
	    System.err.println("Serialized lexicon not in the right format.");
	    e.printStackTrace();
	} catch(ClassCastException e) {
	    // end up here if one of the objects were read wrong
	    System.err.println("Cast didn't work quite right.");
	    e.printStackTrace();
	}   // catch  

	System.err.println("Done with serialize operation");
    }

    /**
     * Main method.
     * @param args                        command line arguments
     */
    public static void main (String[] args) {
	SerializeTralex serialize = new SerializeTralex(args);
	serialize.readFiles();
	serialize.writeFile();
	System.exit(1);
	


}


}
