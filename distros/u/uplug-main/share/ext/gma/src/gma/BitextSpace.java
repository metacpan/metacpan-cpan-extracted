package gma;

/**
 * <p>Title: </p>
 * <p>Description: BitextSpace represents the space formed by two translation texts.</p>
 * <p>Copyright: Copyright (C) 2004 I. Dan Melamed</p>
 * <p>Company: Department of Computer Science, New York University</p>
 * @author Luke Shen
 */

import gma.simr.MappingChain;
import gma.simr.SIMR;
import gma.util.InputFileHandler;
import gma.util.ByteInputFileHandler;
import gma.util.ByteParser;
import gma.util.StringUtil;

import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Properties;
import java.util.StringTokenizer;

public class BitextSpace {

  //constants in the config file

  public static final String EOS_MARKER = "eosMarker";

  private static final String DOT = ".";
  private static final String AXIS_FILE_SUFFIX = "axisFileSuffix";
  private static final String DEFAULT_SUFFIX = "axis";

  public static final String X_STOP_WORD_FILE = "xStopWordFile";
  public static final String Y_STOP_WORD_FILE = "yStopWordFile";

  public boolean debug = false;

  private static final String X_AXIS_NORM = "xAxisNorm";
  private static final String Y_AXIS_NORM = "yAxisNorm";
  private static final boolean DEFAULT_NORM_MODE = false;

  private Properties properties = null;   //properties

  private List xAxisTicks = null;   //x axis ticks
  private List yAxisTicks = null;   //y axis ticks


  /**
   * Constructor.
   * @param properties        properties
   */
  public BitextSpace(Properties properties) {
    this.properties = properties;
  }

  /**
   * Generates x axis and y axis of the bitext space.
   */
  public void generateAxes() {

    String suffix = DEFAULT_SUFFIX;

    if (properties.containsKey(AXIS_FILE_SUFFIX)) {
      suffix = properties.getProperty(AXIS_FILE_SUFFIX);
    }

    xAxisTicks = generateAxis(suffix, SIMR.X_AXIS_FILE, X_STOP_WORD_FILE, X_AXIS_NORM);
    yAxisTicks = generateAxis(suffix, SIMR.Y_AXIS_FILE, Y_STOP_WORD_FILE, Y_AXIS_NORM);
  }

  /**
   * Generates axis.
   * @param suffix                  suffix denotes axis file
   * @param axisFileProperty        property name for axis file
   * @param stopWordProperty        property name for stop word file
   * @param normProperty            property name for normalization
   * @return                        list of axis ticks
   */
  private List generateAxis(String suffix, String axisFileProperty,
                    String stopWordProperty, String normProperty) {

    boolean needNormalization = DEFAULT_NORM_MODE;
    if (properties.containsKey(normProperty)) {
      needNormalization = Boolean.valueOf(properties.getProperty(normProperty)).booleanValue();
    }

    List stopWords = loadStopWordList(stopWordProperty);
    String axisFile = properties.getProperty(axisFileProperty);

    return doGenerateAxis(axisFile, suffix, needNormalization, stopWords);
  }

  /**
   * Loads stop words.
   * @param propertyName                property name for stop word file
   * @return                            list of stop words
   */
  private List loadStopWordList(String propertyName) {
    String stopWordFile = properties.getProperty(propertyName);
    ByteInputFileHandler input = new ByteInputFileHandler(stopWordFile);
    return input.readWordList();
  }

  /**
   * Does generate axis.
   * @param axisFile                    axis file
   * @param axisFileSuffix              suffix for axis file
   * @param needNormalization           true if words need normalization
   * @param stopWords                   list of stop words
   * @return                            list of axis ticks
   */
  private List doGenerateAxis(String axisFile, String axisFileSuffix,
                              boolean needNormalization, List stopWords) {
    generateAxisFile(axisFile, axisFileSuffix);
    return generateAxisTicks(axisFile, needNormalization, stopWords);
  }

  /**
   * Converts text file to axis file.
   * @param axisFile                text file
   * @param axisFileSuffix          suffix for axis file
   */
  private void generateAxisFile(String axisFile, String axisFileSuffix) {
    if (!axisFile.toLowerCase().endsWith(DOT + axisFileSuffix.toLowerCase())) {
      axisFile.concat(DOT).concat(axisFileSuffix.toLowerCase());
      /**
       * @todo convert txt file to axis file
       */
    }
  }

  /**
   * Generates axis ticks.
   * @param axisFormatFile                  axis file
   * @param needNormalization               true for word normalization
   * @param stopWords                       list of stop words
   * @return                                list of axis ticks
   */
  private List generateAxisTicks(String axisFormatFile, boolean needNormalization,
                                                  List stopWords) {

    List axisTicks = new LinkedList();
    int counter = -1;

    ByteInputFileHandler input = new ByteInputFileHandler(axisFormatFile);
    
    while (input.hasLine()) {

      counter++;

      List arrayLine = input.nextLine();
      if (debug) { System.err.println("arrayLine " + arrayLine); }
      ByteParser bParser = new ByteParser(arrayLine);

      /* now we need to break up the arrayLine into 2 portions */
      List line = bParser.parseAxisLine();  
      
      /* StringTokenizer tokenizer = new StringTokenizer(line); */ 
      if (line.size() != 2) {
        System.err.println("The input file is not in the axis format.");
        input.close();
        System.exit(1);
      }



      /* first translate the position from byte to String */
      StringBuffer sb = new StringBuffer();
      Iterator li = ((List)line.get(0)).iterator();
      while (li.hasNext()) {
      	  sb.append( (char)((Integer)li.next()).intValue() );
      }

      String str = new String(sb);
      float position = Float.parseFloat(str);
      List word = (List)line.get(1);
      
      /*
        //remove tags
        int tagIndex = word.indexOf("::");
        if (tagIndex != -1) {
          word = word.substring(0, tagIndex);
        }
	
        //the original Perl implementation is case sensitive
        if (stopWords.contains(word)) {
          continue;
        } else if (word.equals(properties.getProperty(EOS_MARKER))) {
          continue;
        }

        if (needNormalization) {
          word = StringUtil.norm(word).toLowerCase();
        }
      */
      
      // need to make sure that the word list itn't the EOS_MARKER
      ByteParser wParser = new ByteParser(word);
      
      String wString = new String(wParser.listToString());
      //if (debug) { System.err.println(position + "  " + wString); }
      if (!wString.equals(properties.getProperty(EOS_MARKER))) {
	  if (!stopWords.contains(word)) {
	      AxisTick axisTick = new AxisTick(counter, position, word);
	      //if (debug) { System.err.println(axisTick); }
	      axisTicks.add(axisTick);
	  }
      } 
      
    }
    input.close();
  return axisTicks;
  }

  /**
   * Updates slope property.
   */
  public void updateSlopeProperty() {
    if (properties.getProperty(MappingChain.SLOPE) != null) {
      return;
    } else {
	//System.err.println("num " + ((AxisTick)yAxisTicks.get(yAxisTicks.size() - 1)).getPosition());
	//System.err.println("den " + ((AxisTick)xAxisTicks.get(xAxisTicks.size() - 1)).getPosition());
      double slope = (double)((AxisTick)yAxisTicks.get(yAxisTicks.size() - 1)).getPosition()
          / (double)((AxisTick)xAxisTicks.get(xAxisTicks.size() - 1)).getPosition();
      properties.put(MappingChain.SLOPE, String.valueOf(slope));
      //System.err.println("SLOPE=" + slope);
    }
  }

  /**
   * Gets axis tick at the indexed position.
   * @param index                 indexed position
   * @param isXAxis               true for x axis
   * @return                      indexed axis tick
   */
  public AxisTick getAxisTick(int index, boolean isXAxis) {
    if (isXAxis) {
      return (AxisTick)xAxisTicks.get(0);
    } else {
      return (AxisTick)yAxisTicks.get(0);
    }
  }

  /**
   * Gets iterator for axis ticks.
   * @param axisTick            axis tick after which the iterator starts
   * @param isXAxis             true for iterator on x axis
   * @return                    iterator for axis ticks
   */
  public Iterator getAxisIterator(AxisTick axisTick, boolean isXAxis, int offset) {
    if (isXAxis) {
	// changed to lastIndexOf on 03/04/04 to handle multiple instances
	// of the same axis point
	int maxXAxisIndex = xAxisTicks.indexOf(axisTick) + offset;

	//int maxXAxisIndex = xAxisTicks.lastIndexOf(axisTick);
	//System.err.println("XAxisTicks " + xAxisTicks.subList(maxXAxisIndex + 1,xAxisTicks.size()-1));
      return xAxisTicks.listIterator(maxXAxisIndex + 1);
    } else {
	int maxYAxisIndex = yAxisTicks.indexOf(axisTick) + offset;
	//int maxYAxisIndex = yAxisTicks.lastIndexOf(axisTick);
	//System.err.println("YAxisTicks " + yAxisTicks.subList(maxYAxisIndex + 1,yAxisTicks.size()-1));
      return yAxisTicks.listIterator(maxYAxisIndex + 1);
    }
  }
}
