package gma;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 *
 * Example run:
 * java -Xms128m -Xmx512m gma/GMA -properties bin/GMA.properties.CH.E.tl -xAxisFile /home/argyle/cpp~1004.c.mixed.space.axis -yAxisFile /home/argyle/cpp~1004.e.stemok.axis -simr.outputFile cpp~1004.simr -gsa.outputFile cpp~1004.align
 */

import gma.gsa.GSA;
import gma.simr.SIMR;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.IOException;

import java.util.List;
import java.util.Properties;
import java.util.SortedSet;
import java.util.StringTokenizer;

public class GMA {

  public Properties properties = new Properties();  //properties

  /**
   * Constructor.
   * @param args                  command line arguments
   */
  public GMA(String[] args) {
    try {
      parseArguments(args);
    } catch (IllegalArgumentException e) {
      printUsage();
      System.exit(1);
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
    buffer.append("\t").append(SIMR.DASH).append(argument).append(SIMR.SPACE).append(argument).append("\n");
    if (isRequired) {
      buffer.append("\t").append("required argument; ");
    } else {
      buffer.append("\t").append("optional argument; ");
    }
    buffer.append("e.g., ").append(SIMR.DASH).append(argument).append(SIMR.SPACE).append(example).append("\n\n");
    return buffer.toString();
  }

  /**
   * Prints command usage.
   */
  private void printUsage() {
    StringBuffer buffer = new StringBuffer("Usage: java gma.GMA [arguments]\n\n");
    buffer.append("where [arguments] are:\n\n");
    buffer.append(formArgumentUsage(SIMR.PROPERTIES, true, "./GMA.properties"));
    buffer.append(formArgumentUsage(SIMR.X_AXIS_FILE, false, "./french.txt"));
    buffer.append(formArgumentUsage(SIMR.Y_AXIS_FILE, false, "./english.txt"));
    buffer.append(formArgumentUsage(SIMR.SIMR + "." + SIMR.OUTPUT_FILE, false, "./simrOutput.txt"));
    buffer.append(formArgumentUsage(GSA.GSA + "." + SIMR.OUTPUT_FILE, false, "./gsaOutput.txt"));
    System.err.println(buffer.toString());
  }


  /**
   * Recursively reads in property files
   */
  private void readProperties(String fileName) {
      InputStream in = null;
      try {
	  in = new BufferedInputStream(new FileInputStream(fileName));
	  properties.load(in);
	  BufferedReader reader = new BufferedReader(new FileReader(fileName));
	  String inc = new String("#INCLUDE");
	  String line;
	  while ((line = reader.readLine()) != null) {
	      if( (!line.equals("")) && (line.startsWith(inc)) ) {
		  String[] tok = line.split(" +");
		  InputStream in2 = null;
		  readProperties(tok[1]);
	      }
	  }
      } catch (FileNotFoundException e) {
	  e.printStackTrace();
	  System.exit(1);
      } catch (IOException e) {
          e.printStackTrace();
          System.exit(1);
      } finally {
          if (in != null) {
	      try {
		  in.close();
	      } catch (IOException e) {
		  e.printStackTrace();
	      }
          }
      }
  
  }
  /**
   * Parses command line arguments.
   * @param args                              command line arguments
   * @throws IllegalArgumentException
   */
  private void parseArguments(String[] args) throws IllegalArgumentException {
      boolean gotProp = false;
      boolean gotOut = false;

    if ((args.length % 2) != 0) {
      throw new IllegalArgumentException("The number of arguments must be even.");
    }

   for (int index = 0; index < args.length; index++) {
      if ( (args[index].equals(SIMR.DASH + SIMR.PROPERTIES)) || (args[index].equals(SIMR.PLUS + SIMR.PROPERTIES)) ){
	  readProperties(args[++index]);
	  gotProp = true;

      } else if ( (args[index].equals(SIMR.DASH + SIMR.X_AXIS_FILE)) || (args[index].equals(SIMR.PLUS + SIMR.X_AXIS_FILE)) ){
        properties.put(SIMR.X_AXIS_FILE, args[++index]);

      } else if ( (args[index].equals(SIMR.DASH + SIMR.Y_AXIS_FILE)) || (args[index].equals(SIMR.PLUS + SIMR.Y_AXIS_FILE)) ){
        properties.put(SIMR.Y_AXIS_FILE, args[++index]);

      } else if (args[index].equals(SIMR.DASH + SIMR.VERBOSE)) {
        properties.put(SIMR.VERBOSE, args[++index]);

      } else if ( (args[index].equals(SIMR.DASH + SIMR.SIMR + "." + SIMR.OUTPUT_FILE)) || (args[index].equals(SIMR.PLUS + SIMR.SIMR + "." + SIMR.OUTPUT_FILE)) ){
        properties.put(SIMR.SIMR + "." + SIMR.OUTPUT_FILE, args[++index]);

      } else if ( (args[index].equals(SIMR.DASH + GSA.GSA + "." + SIMR.OUTPUT_FILE)) || (args[index].equals(SIMR.PLUS + GSA.GSA + "." + SIMR.OUTPUT_FILE)) ){
        properties.put(GSA.GSA + "." + SIMR.OUTPUT_FILE, args[++index]);

      } else {
        throw new IllegalArgumentException(args[index] + "is an invalid argument.");
      }
    }

   if (gotProp == false) {
       throw new IllegalArgumentException("Property file must be specified at the command line.");
   }

  }


  public boolean isJDK14only() {
      // check to make sure the user is running with at least versoin 1.4.x
      String v = System.getProperty("java.class.version","48.0");
      System.err.println("version " + v);
      return ("48.0".compareTo(v) <= 0);
  }
    
    public void setDefaults(){
	String pathGMA = System.getProperty("GMApath");
	System.err.println("pathGMA " + pathGMA);
	
	if (!properties.containsKey("simr.outputFile")) {
	    System.err.println("no simr file specified.. writting to /tmp/temp.map");
	    properties.put("simr.outputFile","/tmp/temp.map");
	}
	if (!properties.containsKey("gsa.outputFile")) {
	    System.err.println("no gsa file specified write alignment to std out");
	}
	//System.err.println("all properties " + properties);
    }

  public void execute() {

    // simr part
    SIMR simr = new SIMR(properties);
    SortedSet mapPoints = simr.generateBitextCorrespondence();
    simr.printMapPoints(mapPoints);

    // gsa part
    GSA gsa = new GSA(properties);
    List alignedBlocks = gsa.generateAlignedBlocks();
    gsa.printAlignedBlocks(alignedBlocks);
  }

  public static void main(String[] args) {
    GMA gma = new GMA(args);
    gma.setDefaults();
    boolean v = gma.isJDK14only();
    if (v==true) {
	System.err.println("Java version test...pass");
    } else {
	System.err.println("Java version test...fail");
	System.err.println("please use Java version 1.4.x");
	System.exit(1);
    }
    System.err.println("v" + v);
    gma.execute();
    System.exit(0);
  }
}
