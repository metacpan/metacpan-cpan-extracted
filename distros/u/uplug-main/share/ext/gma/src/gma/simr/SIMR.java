package gma.simr;

/**
 * <p>Title: </p>
 * <p>Description: SIMR is the driver class for simr algorithm.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

import gma.AxisTick;
import gma.BitextSpace;
import gma.MapPoint;
import gma.util.InputFileHandler;
import gma.util.OutputFileHandler;

import java.io.BufferedInputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.IOException;
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.SortedSet;
import java.util.TreeSet;
import java.util.StringTokenizer;
import java.text.*;

public class SIMR {

  //constants for command line arguments and property file
  public static final String DASH = "-";
  public static final String PLUS = "+";
  public static final String SPACE = " ";
  public static final String SIMR = "simr";
  public static final String VERBOSE = "verbose";
  public static final String PROPERTIES = "properties";
  public static final String X_AXIS_FILE = "xAxisFile";
  public static final String Y_AXIS_FILE = "yAxisFile";
  public static final String OUTPUT_FILE = "outputFile";
  public static final String DEF_OUT = "/tmp/temp.simr";
  
  public boolean debug  = false;
  public String level  = "1"; // some output by default 
  public Integer verbose = new Integer(1);
  private Properties properties = new Properties(); //properties

  private BitextSpace bitextSpace = null; //bitext space

  private boolean isDone = false; //true when finish searching the whole bitext space
  
  /**
   * Constructor.
   * @param args                  command line arguments
   */
  public SIMR(String[] args) {
    try {
      parseArguments(args);
    } catch (IllegalArgumentException e) {
      printUsage();
      System.exit(1);
    }
  }

  /**
   * Constructor.
   * @param properties            properties
   */
  public SIMR(Properties properties) {
    this.properties = properties;
    level = properties.getProperty(VERBOSE,"1"); 
    verbose = new Integer(level);
  }

  /**
   * Prints command usage.
   */
  private void printUsage() {
    StringBuffer buffer = new StringBuffer("Usage: java gma.simr.SIMR [arguments]\n\n");
    buffer.append("where [arguments] are:\n\n");
    buffer.append(formArgumentUsage(PROPERTIES, true, "./SIMR.properties"));
    buffer.append(formArgumentUsage(X_AXIS_FILE, false, "./french.txt"));
    buffer.append(formArgumentUsage(Y_AXIS_FILE, false, "./english.txt"));
    buffer.append(formArgumentUsage(SIMR + "." + OUTPUT_FILE, false, "./simrOutput.txt"));
    System.err.println(buffer.toString());
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
    buffer.append("\t").append(DASH).append(argument).append(SPACE).append(argument).append("\n");
    if (isRequired) {
      buffer.append("\t").append("required argument; ");
    } else {
      buffer.append("\t").append("optional argument; ");
    }
    buffer.append("e.g., ").append(DASH).append(argument).append(SPACE).append(example).append("\n\n");
    return buffer.toString();
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

      if (args[index].equals(DASH + PROPERTIES)) {
	  readProperties(args[++index]);
	  gotProp = true;
      } else if (args[index].equals(DASH + X_AXIS_FILE)) {
        properties.put(X_AXIS_FILE, args[++index]);

      } else if (args[index].equals(DASH + Y_AXIS_FILE)) {
        properties.put(Y_AXIS_FILE, args[++index]);

      } else if (args[index].equals(DASH + VERBOSE)) {
        properties.put(VERBOSE, args[++index]);
	level = properties.getProperty(VERBOSE);
	verbose = new Integer(level);


      } else if (args[index].equals(DASH + SIMR + "." + OUTPUT_FILE)) {
        properties.put(SIMR + "." + OUTPUT_FILE, args[++index]);
	gotOut = true;
	System.err.println("out file = " + properties.getProperty(SIMR + "." + OUTPUT_FILE));

      } else {
        throw new IllegalArgumentException(args[index] + "is an invalid argument.");
      }
    }
   if (gotProp == false) {
       throw new IllegalArgumentException("Property file must be specified at the command line.");
   }
   if (gotOut == false) {
       properties.put(SIMR + "." + OUTPUT_FILE, DEF_OUT);
   }
  }


  /**
   * Generates bitext correspondence.
   * @return                  sortedset of bitext correspondence
   */
  public SortedSet generateBitextCorrespondence() {
    bitextSpace = new BitextSpace(properties);
    /** @todo load anchor file */
    bitextSpace.generateAxes(); /* reading in the axis files */
    bitextSpace.updateSlopeProperty();
    SortedSet mappingChains = generateMappingChains();
    // the printChain method will write the chains as they are before
    // disambiguation to a file named [simr output file].debug
    if (debug) {printChain(mappingChains);}
    List disambiguatedChains = disambiguateChains(mappingChains);
    return sortMapPoints(disambiguatedChains);
    /** @todo extra pass for those gaps caused by inversed mapping */
  }

  /**
   * Prints out a list of chains for debugging purposes
   * @param mappingChains            sorted set of map points of bitext correspondence
   */
  public void printChain(SortedSet mappingChains) {

      String outfile = properties.getProperty(SIMR + "." + OUTPUT_FILE);
      OutputFileHandler outdebug = new OutputFileHandler(outfile + ".debug");

    //********************************************************************************
    Iterator it = mappingChains.iterator();

    // Added by Ali to print out these mapping Chains before disambiguation starts
    
    while (it.hasNext()) {
	MappingChain itChain = (MappingChain)it.next();
	List newList = ((MappingChain)itChain.clone()).sort(itChain);
	
	Iterator lit = newList.iterator();
	outdebug.write(", " + lit.next() + "\n");
	while (lit.hasNext()) {
	    outdebug.write(lit.next()+"\n");
	}
    }

    //********************************************************************************
    outdebug.close();

  }


  /**
   * Generates mapping chains.
   * @return                      sorted set of mapping chains.
   */
  private SortedSet generateMappingChains() {
    if (verbose.intValue() >= 1 ) { System.err.println("Generating mapping chains"); }
    SortedSet mappingChains = new TreeSet();
    SearchRectangle searchRectangle = new SearchRectangle(properties);

    searchRectangle.expandSearchRectangle(bitextSpace.getAxisTick(0, true), true); //expand xAxis

    searchRectangle.expandSearchRectangle(bitextSpace.getAxisTick(0, false), false); //expand yAxis

    while (!isDone) {
      MappingChain mappingChain = searchMappingChains(searchRectangle);
      if (mappingChain == null) {
        break;
      }
      mappingChains.add(mappingChain);
      //System.err.println("CHAIN --> " + mappingChain);
      searchRectangle = searchRectangle.reduceSearchRectangle();
    }


    return mappingChains;
  }

  /**
   * Searches for mapping chains.
   * @param searchRectangle                 search rectangle
   * @return                                mapping chain
   */
  private MappingChain searchMappingChains(SearchRectangle searchRectangle) {
      AxisTick xTick = searchRectangle.getBoundaryAxisTick(true, false);
      AxisTick yTick = searchRectangle.getBoundaryAxisTick(false, false);
      int xoffset = searchRectangle.getNumInstances(true, xTick);
      int yoffset = searchRectangle.getNumInstances(false, yTick);


    Iterator xTickIterator = bitextSpace.getAxisIterator(searchRectangle.getBoundaryAxisTick(true, false), true, xoffset-1);
    Iterator yTickIterator = bitextSpace.getAxisIterator(searchRectangle.getBoundaryAxisTick(false, false), false, yoffset-1);

    boolean first = true;
    while (xTickIterator.hasNext()) {
      if (first || searchRectangle.hasNewPoint()) {
	  first = false;
	  if (searchRectangle.hasMappingChain()) {
	     return searchRectangle.getBestChain();
	  }

      }
      searchRectangle.expandSearchRectangle((AxisTick)xTickIterator.next(), true);
      while (yTickIterator.hasNext()) {
        if (searchRectangle.canExpandYAxis()) {
	    searchRectangle.expandSearchRectangle((AxisTick)yTickIterator.next(), false);
        } else {
          break;
        }
      }
    }

    // case changed by Ali get output to match Perl output, no longer mandating
    // a new point, will leave it this way (old line is commented out below)
    // if (searchRectangle.hasNewPoint() && searchRectangle.hasMappingChain()) {
    if (searchRectangle.hasMappingChain()) {
      return searchRectangle.getBestChain();
    }
    isDone = true;
    //we are here when no mappingChain is found
    return null;
  }

  /**
   * Removes conflictual chains.
   * @param mappingChains           sorted set of mapping chains
   * @return                        list of non-conflictual mapping chains
   */
  private List disambiguateChains(SortedSet mappingChains) {

    //separate non-conflictual mapping chains from conflictual mapping chains
    List nonConflictChains = new ArrayList();
    Map conflictWithChains = new HashMap();

    Iterator outerIterator = mappingChains.iterator();
    while (outerIterator.hasNext()) {
      List conflictChains = new ArrayList();
      MappingChain outerMappingChain = (MappingChain)outerIterator.next();
      
      Iterator innerIterator = mappingChains.iterator();
      while (innerIterator.hasNext()) {
        MappingChain innerMappingChain = (MappingChain)innerIterator.next();

        if (outerMappingChain == innerMappingChain) {
          //only check up to the outer mapping chain
          break;

        } else if (outerMappingChain.getEndMapPoint(true, false).isMaxMapPoint(innerMappingChain.getEndMapPoint(true, true), true) == -1
        && outerMappingChain.getEndMapPoint(false, false).isMaxMapPoint(innerMappingChain.getEndMapPoint(false, true), false) == -1) {
          //if the max index of outerMappingChain is smaller than the min index of innerMappingChain,
          //there is no need to continue comparing because the mappingChains are sorted by min xAxisTick index
          break;

        } else if (outerMappingChain.getEndMapPoint(true, true).isMaxMapPoint(innerMappingChain.getEndMapPoint(true, false), true) == 1
		   && outerMappingChain.getEndMapPoint(false, true).isMaxMapPoint(innerMappingChain.getEndMapPoint(false, false), false) == 1) {
          //if the min index of outerMappingChain is greater than the max index of innerMappingChain,
          //move on to the next one because there is no overlapping part between there two chains
	  continue;

        } else {
	  // do the overlapping parts match?
          if (outerMappingChain.isConflict(innerMappingChain)) {
            conflictChains.add(innerMappingChain);

            List reverseConflictChains = null;
            if ( !conflictWithChains.containsKey(innerMappingChain) ) {
              reverseConflictChains = new ArrayList();
            } else {
              reverseConflictChains = (List)conflictWithChains.get(innerMappingChain);
            }

            reverseConflictChains.add(outerMappingChain);
            conflictWithChains.put(innerMappingChain, reverseConflictChains);
          }
	}
      }//end of inner while loop

      if (!conflictChains.isEmpty()) {
        conflictWithChains.put(outerMappingChain, conflictChains);
      }
    }//end of outer while loop
    

    Iterator nonConflictIterator = mappingChains.iterator();
    while (nonConflictIterator.hasNext()) {
      MappingChain mappingChain = (MappingChain)nonConflictIterator.next();
      if ( !conflictWithChains.containsKey(mappingChain) ) {
        nonConflictChains.add(mappingChain);
      }
    }

    //remove most conflictual chain one at a time
    while (!conflictWithChains.isEmpty()) {

      int maxConflictCounter = 0;
      MappingChain mostConflictualChain = null;
      Set keys = conflictWithChains.keySet();
      Iterator iterator = keys.iterator();
      while (iterator.hasNext()) {

        MappingChain keyChain = (MappingChain)iterator.next();	
        List conflictChains = (List)conflictWithChains.get(keyChain);


        if ((mostConflictualChain == null) || (conflictChains.size() > maxConflictCounter)
        || ((conflictChains.size() == maxConflictCounter) && (mostConflictualChain.getSumSquareError() < keyChain.getSumSquareError()))) {

          maxConflictCounter = conflictChains.size();
          mostConflictualChain = keyChain;
	}
        
      } //end of inner while loop
      
      List conflictChains = (List)conflictWithChains.get(mostConflictualChain);
      Iterator conflictIterator = conflictChains.iterator();
      
      // clean up the reverse mapping of the conflicts 
      while (conflictIterator.hasNext()) {
        MappingChain conflictChain = (MappingChain)conflictIterator.next();
        List reversedConflictChains = (List)conflictWithChains.get(conflictChain);
        reversedConflictChains.remove(mostConflictualChain);

        if (reversedConflictChains.isEmpty()) {
          conflictIterator.remove();
          nonConflictChains.add(conflictChain);
          conflictWithChains.remove(conflictChain);
        }
      }
      
      conflictWithChains.remove(mostConflictualChain);
    }

    return nonConflictChains;
    }

  /**
   * Sorts map points from the non-conflictual mapping chains and removes duplicate map points
   * @param bestChains                list of non-conflictual mapping chains
   * @return                          sorted set of map points
   */
  private SortedSet sortMapPoints(List bestChains) {
    SortedSet mapPoints = new TreeSet();
    Iterator iterator = bestChains.iterator();
    while (iterator.hasNext()) {
      MappingChain mappingChain = (MappingChain)iterator.next();
      for (int index = 0; index < mappingChain.getChainSize(); index++) {
        MapPoint mapPoint = mappingChain.getMapPoint(index);
	//System.err.println("mapPoint " + mapPoint);
        mapPoints.add(mapPoint);
      }
    }
    return mapPoints;
  }


  /**
   * Adds the intro and terminus in to the map
   * @param bestPoints            sorted set of map points of bitext correspondence
   */ 
  public String getTerminus(SortedSet bestPoints){
    InputFileHandler xInput = new InputFileHandler(properties.getProperty(X_AXIS_FILE));
    String xLastLine = "null";
    while (xInput.hasLine()) {
      String line = xInput.nextLine();
      xLastLine = line;
    }	
    StringTokenizer xTokenizer = new StringTokenizer(xLastLine);
    float xEndPosition = Float.parseFloat(xTokenizer.nextToken());

    InputFileHandler yInput = new InputFileHandler(properties.getProperty(Y_AXIS_FILE));
    String yLastLine = "null";
    while (yInput.hasLine()) {
      String line = yInput.nextLine();
      yLastLine = line;
    }	
    StringTokenizer yTokenizer = new StringTokenizer(yLastLine);
    float yEndPosition = Float.parseFloat(yTokenizer.nextToken());
    String terminus = (xEndPosition + " " + yEndPosition);
    // does this terminus already exist in bestPoints?
    //System.err.println("mapPoint terminus >" + terminus + "<");
    //System.err.println("mapPoint last >" + bestPoints.last() + "<");
    //String last = mp.getXAxisTick

    return terminus;
  }
  /**
   * Prints out map points of bitext correspondence.
   * @param bestPoints            sorted set of map points of bitext correspondence
   */
  public void printMapPoints(SortedSet bestPoints) {
    OutputFileHandler out = new OutputFileHandler(properties.getProperty(SIMR + "." + OUTPUT_FILE));
    Iterator iterator = bestPoints.iterator();
    out.write ("0.0 0.0\n");
    String lastLine = getTerminus(bestPoints);
    if (iterator.hasNext()) {
	String first = (((MapPoint)iterator.next()).toString());
	if (!(first.equals("0.0 0.0"))) {
	    out.write(first + "\n");
	}
	while (iterator.hasNext()) {
	    out.write(((MapPoint)iterator.next()).toString() + "\n");
	}
	MapPoint mp = (MapPoint)bestPoints.last();
	// they are equal
	if (!(lastLine.equals(mp.toString())) ) {
	    out.write(lastLine);
	    out.write("\n");
	}
    } else {
	out.write(lastLine + "\n");
    }
    out.close();
    // Now also write to stdout if no output file was specified
    if ((properties.getProperty(SIMR + "." + OUTPUT_FILE)) == DEF_OUT) {
	try {
	    BufferedReader out2screen = new BufferedReader(new InputStreamReader(new FileInputStream(DEF_OUT)));

	    String line = "";
	    while((line = out2screen.readLine()) != null) {
		System.out.println(line);
	    }
	    out2screen.close();
	} catch (IOException e) {
	    e.printStackTrace();
	    System.exit(1);
	}
    }
  }

  /**
   * Main method.
   * @param args                        command line arguments
   */
  public static void main (String[] args) {
    SIMR simr = new SIMR(args);
    long start = System.currentTimeMillis();
    SortedSet mapPoints = simr.generateBitextCorrespondence();
    simr.printMapPoints(mapPoints);
    long end = System.currentTimeMillis();
    long elapsed = end - start; //time in msecs
    //System.err.println("SIMR took " + DecimalFormat.getInstance().format(elapsed/1000.) + " seconds."); 
    System.exit(0);
  }
}
