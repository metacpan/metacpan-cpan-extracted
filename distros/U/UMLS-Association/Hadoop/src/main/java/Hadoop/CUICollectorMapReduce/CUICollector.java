package Hadoop.CUICollectorMapReduce;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.List;
import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.HashMap;

import org.apache.commons.cli.*;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;


/**
 * CUICollector identifies CUI bigrams from either MetaMap files or the output from ArticleCollector.
 * Depending on the selected mode, the RecordReader splits the file on the string "'EOU.'" or "@@@@@@@" so that
 * each mapper processes all utterances between the record delimiters (multiple utterances per record if processing ArticleCollector output).
 * This method improves the original CUICollector.pl by enabling CUI bigrams to be found across utterances when using Article Collector output.
 * If using the "cui" mode it duplicates the original CUICollector.pl output.
 * The output is one file that contains counts of all CUI bigrams found in the MetaMap database.
 * 
 * @author Amy Olex
 * @version 1.0
 * 
 */
public class CUICollector {
	/**
	 * The CUIMapper class extends <code>Mapper</code> and implements the <code>map</code> method.
	 * Input into the CUIMapper is of type <code><Object, Text></code> for the input <K,V> pair.
	 * Output is of type <code><Text, IntWritable></code> for the output <K,V> pair.
	 * 
	 * @author Amy Olex
	 *
	 */
	public static class CUIMapper extends Mapper<Object, Text, Text, IntWritable>{

		public static final Log log = LogFactory.getLog(CUIMapper.class);
		public static final boolean DEBUG = false;
		public static final boolean DEBUG2 = false;
		
		private final static IntWritable one = new IntWritable(1);
		private Text word = new Text();

		/**
		 * Parses out all CUI bigrams from each utterance and assigns the CUI bigram string as the
		 * KEY and the IntWritable value 1 to the VALUE. The <KEY,VALUE> pair is written
		 * to the Hadoop context for use by the Reducer.
		 * 
		 * @param key The KEY automatically set by the RecordReader.
		 * @param value The record value (i.e. the text for an ArticleCollector record).
		 * @param context The Hadoop context object.
		 * 
		 */
		public void map(Object key, Text value, Context context) throws IOException, InterruptedException {
			String thisString = value.toString();
			
			Configuration conf = context.getConfiguration();
			int window = Integer.parseInt(conf.get("window"));
			
			/*
			 * http://stackoverflow.com/questions/8603788/hadoop-jobconf-class-is-deprecated-need-updated-example
			 * https://hadoopi.wordpress.com/2013/05/31/custom-recordreader-processing-string-pattern-delimited-records/
			 */

			//Create the phrases pattern
			String phrases_pattern = "mappings(.*)";
			Pattern p1 = Pattern.compile(phrases_pattern);
			Matcher m_p1 = p1.matcher(thisString);
			
			//Create the CUI pattern
			String cui_pattern = "C[0-9]{7}";
			Pattern c1 = Pattern.compile(cui_pattern);
			
			List<List<List<String>>> my_phrases = new ArrayList<List<List<String>>>();
			//Now iterate through the utterances
			//while we still have utterances being found
			while(m_p1.find()){
				//get the current utterance string
				String thisPhrase = m_p1.group(1);
				if(DEBUG){log.info("PHRASE: " + thisPhrase);}
				String[] maps = thisPhrase.split("map\\(");
				//create a vector to store phrases
				List<List<String>> my_maps = new ArrayList<List<String>>();
				if(DEBUG){log.info("MAPSIZE: " + maps.toString() + maps.length);}
				//loop through all matched phrases			
				for(int i=0; i<maps.length; i++){
					//get phrase
					String thisMap = maps[i];
					if(DEBUG){log.info("THISMAP: " + thisMap);}
					//StringBuilder CUIs = new StringBuilder(64);
					List<String> CUIs = new ArrayList<String>();
					//create the CUI matcher on this map
					Matcher m_c1 = c1.matcher(thisMap);
					while(m_c1.find()){			//only executes this if there is a match
						String thisCUI = m_c1.group(0);
						
						CUIs.add(thisCUI);
						//CUIs.append(" ");
						
					}
					//this ensures that the string CUIs is not empty.  Otherwise would add an empty string to the list.
					if(!CUIs.isEmpty()){  
						if(DEBUG){log.info("MAP: " + CUIs.toString() + CUIs.size());}
						my_maps.add(CUIs);
					}
					
				}
				if(!my_maps.isEmpty()){
					if(DEBUG){log.info("MAP LIST: " + my_maps.toString() + my_maps.size());}
					my_phrases.add(my_maps);
					if(DEBUG){log.info("PHRASE LIST: " + my_phrases.toString() + my_phrases.size());}
				}
				
			} //end find phrase
			
			//Now we have our phrases.  I need to concatenate them, then find the CUI bigrams
			//Need to create a hashmap where the keys are the index position of the CUI in the sentence
			//each entry in my_phrases will be a mapping, which can contain one or more maps to the phrase.
			//looping through each phrase will enter in cuis at the same range of hid locations.
			//I will need to increment the hid by the length of the current phrase array
			
			//Hashmap that will hold all CUIs in utterance, without duplicates.
			//Multiple cuis will be in the same hash position
			HashMap<Integer,ArrayList<String>> cuihash = new HashMap<Integer,ArrayList<String>>();
			int hid = 0; //will keep track of the current hash id location
			
			if(!my_phrases.isEmpty()){
				if(DEBUG2){log.info("my_phrases size: " + my_phrases.size() + " : " + my_phrases.toString());}
				
				//loop over each phrase
				for(int i = 0; i < my_phrases.size(); i++){
					//get phrase
					List<List<String>> this_phrase =  my_phrases.get(i);
					if(DEBUG2){log.info("this_phrase before: " + this_phrase.toString());}
					//get number of CUIs in the first map of this_phrase
					//this_phrase.get(0).size();
					
					//loop through all maps in this_phrase and and add to cuihash
					//at positions hid to local_hid
					for(int j=0; j<this_phrase.size(); j++){
						List<String> this_map = this_phrase.get(j);
						//loop through CUIs in the map
						for(int m=0; m<this_map.size(); m++){
							int cuihash_idx = hid+m;
							//check to see if the cuihash has anything at the current index (hid+m)
							//if no then add the element.  If yes, then get the element and append this cui to that position.
							if(cuihash.get(cuihash_idx)==null){
								cuihash.put(cuihash_idx, new ArrayList<String>());
								cuihash.get(cuihash_idx).add(this_map.get(m));
							}
							else{ 
								//checks to see if cui is already in the array list.  
								//if no then it adds it, if yes then it does nothing.
								//this removes all duplicates automatically!
								if(!cuihash.get(cuihash_idx).contains(this_map.get(m))){
									cuihash.get(cuihash_idx).add(this_map.get(m));
								}
							}
								
						} //end loop through cuis
						
					} //end loop through maps
					
					if(DEBUG2){log.info("HASHMAP CONDENSED MAPS: " + cuihash.toString() );}
					
					//finished processing all maps in this_phrase so move to the next 
					//phrase, which increments the global hash idx.
					if(DEBUG2){log.info("HID Before: " + hid + "map size:" + this_phrase.get(0).size());}
					hid = hid+this_phrase.get(0).size();
					if(DEBUG2){log.info("this_phrase_after: " + this_phrase.get(0).toString());}
					
				}
			}
			
			//Now I supposidly have all phrases in the utterance condensed into a hashmap.
			//Now loop through the hashmap and pull out all CUI bigrams based on a window.
			//int window=2; //this needs to be user input
			
			//loop through hashmap
			for(int h=0; h<cuihash.size(); h++){
				//this is the first cui in the bigram
				List<String> cui1 = cuihash.get(h);
				//get all cui bigrams for each hashmap position
				for(int w=1; w<=window; w++){
					//for each window size get the second cui
					//only loop if the second cuis index is less than the length of the hash.
					int cui2_idx = h+w;
					if(cui2_idx < cuihash.size()){
						List<String> cui2 = cuihash.get(h+w);
						if(DEBUG2){log.info("h:" + h + " w:" + w);}
						//pair each cui in cui1 to each cui in cui2
						for(int c_1=0; c_1<cui1.size(); c_1++){
							for(int c_2=0; c_2<cui2.size(); c_2++){
								StringBuilder bigram2 = new StringBuilder(15);
								bigram2.append(cui1.get(c_1));  
								bigram2.append("\t");
								bigram2.append(cui2.get(c_2)); 
								word.set(bigram2.toString());
								if(DEBUG2){log.info("Bigram2: " + bigram2.toString());}
								context.write(word, one);
							}
							
						}
					}
					
					
				}
				
			}	
			
		} //end public void reduce.
	} //end class

	
	/**
	 * The CUIReducer extends <code>Reducer</code> and implements the <code>reduce</code> method.
	 * Input into the ArticleReducer is of type <code><Text, IntWritable></code> for the input <K,V> pair.  
	 * Output is of type <code><Text, IntWritable></code> for the output <K,V> pair.
	 * 
	 * @author Amy Olex
	 *
	 */
	public static class CUIReducer extends Reducer<Text,IntWritable,Text,IntWritable> {
		private IntWritable result = new IntWritable();

		/**
		 * Sums all instances of a CUI bigram and writes the CUI bigrams string as the KEY and
		 * the total number of occurences as the VALUE to the Hadoop context for output by the 
		 * RecordWriter.
		 * 
		 * @param key The CUI bigram string.
		 * @param values An Iterable IntWritable containing the integer 1 for each instance of a CUI bigram.
		 * @param context The Hadoop context object.
		 * 
		 */
		public void reduce(Text key, Iterable<IntWritable> values, Context context) throws IOException, InterruptedException {
			int sum = 0;
			for (IntWritable val : values) {
				sum += val.get();
			}
			result.set(sum);
			context.write(key, result);
		}
	}

	/**
	 * The main method for running the CUIollector.  Sets up job configuration, defines classes to use,
	 * Sets output values and formats, and executes the MapReduce job.
	 * CUICollector can be run in one of two modes, specified by the last command line argument.
	 * ArticleCollector Mode: type "article" for the last argument to process ArticleCollector output.
	 * CUICollector Mode: type "cui" to process MetaMap files directly (Note: in this mode each 
	 * utterance is processed individually).
	 * 
	 * @param args Input arguments from the command line. arg[0] is the path to the input file/directory. arg[1] is the name of the output directory. args[2] specifies which mode to run CUICollector in.
	 * @throws Exception
	 */
	public static void main(String[] args) throws Exception {
		
		//Parsing commandline options before initiating Hadoop
		Options options = new Options();
		//old arg[0]
		Option input = new Option("i", "input", true, "Path to directory or file to be used as input.");
		input.setRequired(true);
		options.addOption(input);
		//old arg[1]
		Option outdir = new Option("o", "outdir", true, "Path to directory where output should be saved. Directory should not already exist!");
		outdir.setRequired(true);
		options.addOption(outdir);
		//old arg[2]
		Option mode = new Option("m", "mode", true, "CUICollector mode. Options are cui or article");
		mode.setRequired(true);
		options.addOption(mode);
		//old arg[3]
		Option window = new Option("w", "window", true, "Bigram window size.");
		window.setRequired(true);
		options.addOption(window);
		
		Option list = new Option("l", "list", true, "OPTIONAL: List of pmids to process from input directory.");
		list.setRequired(false);
		options.addOption(list);
		
		CommandLineParser parser = new GnuParser();
		HelpFormatter formatter = new HelpFormatter();
		CommandLine cmd;
		
		try{
			cmd = parser.parse(options, args);
		} catch(ParseException e){
			System.out.println(e.getMessage());
			formatter.printHelp("hadoop jar <path/to/jar/file.jar> Hadoop.CUICollectorMapReduce.CUICollector -i <input> -o <outdir> -m <mode> -w <window> -l <pmid list>", options);
			System.exit(1);
			return;
		}
		
		
		//Determine if a list of pmids was provided.  If yes concatenate those with the input directory
		//into a list of paths seperated by a comma.  Otherwise use the input path.
		StringBuilder inputPath = new StringBuilder();
		String inputList = cmd.getOptionValue("list");
		String inputdir = cmd.getOptionValue("input");
		if( inputList != null ){
			FileInputStream fis = new FileInputStream(inputList);
			BufferedReader br = new BufferedReader(new InputStreamReader(fis));
			String line = null;
			while( (line = br.readLine()) != null){
				inputPath.append(inputdir);
				inputPath.append(line);
				inputPath.append(".gz,");
			}
			br.close();
			inputPath.setLength(inputPath.length()-1);
			System.out.println(inputPath.toString());
		}
		else{
			inputPath.append(cmd.getOptionValue("input"));
		}
		
		
		//Start Hadoop configuration
		Configuration conf = new Configuration(true);
		
		if(cmd.getOptionValue("mode").equals("article")){
			conf.set("textinputformat.record.delimiter","@@@@@@@");
		}
		else{
			conf.set("textinputformat.record.delimiter","'EOU'.");
		}
		conf.set("window", cmd.getOptionValue("window"));
		
		Job job = new Job(conf);
	
		job.setJarByClass(CUICollector.class);
		job.setMapperClass(CUIMapper.class);
		job.setCombinerClass(CUIReducer.class);
		job.setReducerClass(CUIReducer.class);
		
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(IntWritable.class);
		
		FileInputFormat.addInputPaths(job, inputPath.toString());
		job.setInputFormatClass(TextInputFormat.class);
		FileOutputFormat.setOutputPath(job, new Path(cmd.getOptionValue("outdir")));
		
		System.exit(job.waitForCompletion(true) ? 0 : 1); 
		
		
	}
}