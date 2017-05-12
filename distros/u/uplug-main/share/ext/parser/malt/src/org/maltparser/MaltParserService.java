package org.maltparser;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.Iterator;

import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.flow.FlowChartInstance;
import org.maltparser.core.helper.SystemInfo;
import org.maltparser.core.helper.Util;
import org.maltparser.core.io.dataformat.ColumnDescription;
import org.maltparser.core.io.dataformat.DataFormatInstance;
import org.maltparser.core.options.OptionManager;
import org.maltparser.core.syntaxgraph.DependencyGraph;
import org.maltparser.core.syntaxgraph.DependencyStructure;
import org.maltparser.core.syntaxgraph.node.DependencyNode;
import org.maltparser.parser.SingleMalt;

/**
 * The purpose of MaltParserService is to easily write third-party programs that uses MaltParser. 
 * 
 *  There are two ways to call the MaltParserService:
 *  1. By running experiments, which allow other programs to train a parser model or parse with a parser model. IO-handling is done by MaltParser.
 *  2. By first initialize a parser model and then call the method parse() with an array of tokens that MaltParser parses. IO-handling of the sentence is
 *  done by the third-party program.
 *  
 *  How to use MaltParserService, please see the examples provided in the directory 'examples/apiexamples/srcex'
 * 
 * @author Johan Hall
 */
public class MaltParserService {
	private URL urlMaltJar;
	private Engine engine;
	private FlowChartInstance flowChartInstance;
	private DataFormatInstance dataFormatInstance;
	private SingleMalt singleMalt;
	private int optionContainer;
	private boolean initialized = false;
	
	/**
	 * Creates a MaltParserService with the option container 0
	 * 
	 * @throws MaltChainedException
	 */
	public MaltParserService() throws MaltChainedException {
		this(0);
	}
	
	/**
	 * Creates a MaltParserService with the specified option container. To use different option containers allows the calling program 
	 * to load several parser models or several experiments. The option management in MaltParser uses the singleton design pattern, which means that there can only
	 * be one instance of the option manager. To be able to have several parser models or experiments at same time please use different option containers.
	 * 
	 * @param optionContainer an integer from 0 to max value of data type Integer
	 * @throws MaltChainedException
	 */
	public MaltParserService(int optionContainer) throws MaltChainedException {
		initialize();
		setOptionContainer(optionContainer);
	}
	
	/**
	 * Runs a MaltParser experiment. The experiment is controlled by a commandLine string, please see the documentation of MaltParser to see all available options.
	 * 
	 * @param commandLine a commandLine string that controls the MaltParser.
	 * @throws MaltChainedException
	 */
	public void runExperiment(String commandLine) throws MaltChainedException {
		OptionManager.instance().parseCommandLine(commandLine, optionContainer);
		engine = new Engine();
		engine.initialize(optionContainer);
		engine.process(optionContainer);
		engine.terminate(optionContainer);
	}
	
	/**
	 * Initialize a parser model that later can by used to parse sentences. MaltParser is controlled by a commandLine string, please see the documentation of MaltParser to see all available options.
	 * 
	 * @param commandLine a commandLine string that controls the MaltParser
	 * @throws MaltChainedException
	 */
	public void initializeParserModel(String commandLine) throws MaltChainedException {
		OptionManager.instance().parseCommandLine(commandLine, optionContainer);
		// Creates an engine
		engine = new Engine();
		// Initialize the engine with option container and gets a flow chart instance
		flowChartInstance = engine.initialize(optionContainer);
		// Runs the preprocess chart items of the "parse" flow chart
		if (flowChartInstance.hasPreProcessChartItems()) {
			flowChartInstance.preprocess();
		}
		singleMalt = (SingleMalt)flowChartInstance.getFlowChartRegistry(org.maltparser.parser.SingleMalt.class, "singlemalt");
		singleMalt.getConfigurationDir().initDataFormat();
		dataFormatInstance = singleMalt.getConfigurationDir().getDataFormatManager().getInputDataFormatSpec().createDataFormatInstance(
				singleMalt.getSymbolTables(),
				OptionManager.instance().getOptionValueString(optionContainer, "singlemalt", "null_value"), 
				OptionManager.instance().getOptionValueString(optionContainer, "graph", "root_label"));
		initialized = true;
	}
	
	/**
	 * Parses an array of tokens and returns a dependency structure. 
	 * 
	 * Note: To call this method requires that a parser model has been initialized by using the initializeParserModel(). 
	 * 
	 * @param tokens an array of tokens 
	 * @return a dependency structure
	 * @throws MaltChainedException
	 */
	public DependencyStructure parse(String[] tokens) throws MaltChainedException {
		if (!initialized) {
			throw new MaltChainedException("No parser model has been initialized. Please use the method initializeParserModel() before invoking this method.");
		}
		if (tokens == null || tokens.length == 0) {
			throw new MaltChainedException("Nothing to parse. ");
		}

		DependencyStructure outputGraph = new DependencyGraph(singleMalt.getSymbolTables());
		
		for (int i = 0; i < tokens.length; i++) {
			Iterator<ColumnDescription> columns = dataFormatInstance.iterator();
			DependencyNode node = outputGraph.addDependencyNode(i+1);
			String[] items = tokens[i].split("\t");
			for (int j = 0; j < items.length; j++) {
				if (columns.hasNext()) {
					ColumnDescription column = columns.next();
					if (column.getCategory() == ColumnDescription.INPUT && node != null) {
						outputGraph.addLabel(node, column.getName(), items[j]);
					}
				}
			}
		}
		outputGraph.setDefaultRootEdgeLabel(outputGraph.getSymbolTables().getSymbolTable("DEPREL"), "ROOT");
		// Invoke parse with the output graph
		singleMalt.parse(outputGraph);
		return outputGraph;
	}
	
	/**
	 * Terminates the parser model.
	 * 
	 * @throws MaltChainedException
	 */
	public void terminateParserModel() throws MaltChainedException {
		// Runs the postprocess chart items of the "parse" flow chart
		if (flowChartInstance.hasPostProcessChartItems()) {
			flowChartInstance.postprocess();
		}
		
		// Terminate the flow chart with an option container
		engine.terminate(optionContainer);
	}
	
	private void initialize() throws MaltChainedException {
		if (OptionManager.instance().getOptionDescriptions().getOptionGroupNameSet().size() > 0) {
			return; // OptionManager is already initialized
		}
		String maltpath = getMaltJarPath();
		if (maltpath == null) {
			new MaltChainedException("malt.jar could not be found. ");
		}
		urlMaltJar = Util.findURL(maltpath);
		try {
			OptionManager.instance().loadOptionDescriptionFile(new URL("jar:"+urlMaltJar.toString()+"!/appdata/options.xml"));
			
		} catch (MalformedURLException e) {
			throw new MaltChainedException("MaltParser couldn't find its options 'malt.jar!/appdata/options.xml'", e);
		}
		OptionManager.instance().generateMaps();
	}
	
	
	/**
	 * Returns the option container index
	 * 
	 * @return the option container index
	 */
	public int getOptionContainer() {
		return optionContainer;
	}

	private void setOptionContainer(int optionContainer) {
		this.optionContainer = optionContainer;
	}

	/**
	 * Returns the path of malt.jar file
	 * 
	 * @return the path of malt.jar file
	 */
	public static String getMaltJarPath() {
		if (SystemInfo.getMaltJarPath() != null) {
			return SystemInfo.getMaltJarPath().toString();
		}
		return null;
	}
	
	
}
