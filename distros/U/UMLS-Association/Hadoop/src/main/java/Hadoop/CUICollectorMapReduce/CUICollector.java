package Hadoop.CUICollectorMapReduce;

import java.io.IOException;
import java.util.List;
import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.HashMap;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
//import org.apache.hadoop.mapred.TextInputFormat;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
//import org.apache.hadoop.mapreduce.Mapper.Context;
//import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
//import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
//import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
//import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
//import org.hsqldb.lib.Iterator;

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
			/*
			 * http://stackoverflow.com/questions/8603788/hadoop-jobconf-class-is-deprecated-need-updated-example
			 * https://hadoopi.wordpress.com/2013/05/31/custom-recordreader-processing-string-pattern-delimited-records/
			 */

			//Create the phrases pattern
			String phrases_pattern = "mappings(.*)";
			Pattern p1 = Pattern.compile(phrases_pattern);
			Matcher m_p1 = p1.matcher(thisString);
			
			//Create the map pattern
			//String map_pattern = "(map\\(.*),map\\(|,map\\((.*)";
			//Pattern m1 = Pattern.compile(map_pattern);
			
			//Create the CUI pattern
			String cui_pattern = "C[0-9]{7}";
			Pattern c1 = Pattern.compile(cui_pattern);
			
			List<List<String>> my_phrases = new ArrayList<List<String>>();
			//Now iterate through the utterances
			//while we still have utterances being found
			while(m_p1.find()){
				//get the current utterance string
				String thisPhrase = m_p1.group(1);
				if(DEBUG){log.info("PHRASE: " + thisPhrase);}
				String[] maps = thisPhrase.split("map\\(");
				//create a vector to store phrases
				List<String> my_maps = new ArrayList<String>();
				if(DEBUG){log.info("MAPSIZE: " + maps.toString() + maps.length);}
				//loop through all matched phrases			
				for(int i=0; i<maps.length; i++){
					//get phrase
					String thisMap = maps[i];
					if(DEBUG){log.info("THISMAP: " + thisMap);}
					StringBuilder CUIs = new StringBuilder(64);
					//create the CUI matcher on this map
					Matcher m_c1 = c1.matcher(thisMap);
					while(m_c1.find()){			//only executes this if there is a match
						String thisCUI = m_c1.group(0);
						
						CUIs.append(thisCUI);
						CUIs.append(" ");
						
					}
					//this ensures that the string CUIs is not empty.  Otherwise would add an empty string to the list.
					if(!CUIs.toString().isEmpty()){  
						if(DEBUG){log.info("MAP: " + CUIs + CUIs.length());}
						my_maps.add(CUIs.toString());
					}
					
				}
				if(!my_maps.isEmpty()){
					if(DEBUG){log.info("MAP LIST: " + my_maps.toString() + my_maps.size());}
					my_phrases.add(my_maps);
					if(DEBUG){log.info("PHRASE LIST: " + my_phrases.toString() + my_phrases.size());}
				}
				
			} //end find phrase
			
			//now we have our phrases.  I need to concatenate them, then find the CUI bigrams
			
			if(!my_phrases.isEmpty()){
				//loop over each phrase and phrase+1
				for(int i = 0; i < my_phrases.size(); i++){
					
					//Create prior hashmap to track duplicates per phrase pair
					//So we want a new hashmap for each new phrase 1
					HashMap<String,String> prior = new HashMap<String,String>();
					
					//get phrase 1
					List<String> phrase_1 = (List<String>) my_phrases.get(i);
					List<String> phrase_2 = null;
					if(DEBUG){log.info("Phrase 1: " + " is: " + phrase_1.toString());}
					//get phrase 2 if it exists
					if(i+1 < my_phrases.size()){
						phrase_2 = (List<String>) my_phrases.get(i+1);
						if(DEBUG){log.info("Phrase 2: " + " is: " + phrase_2.toString());}
						
					}
					
					//loop through all maps in phrase 1 to get CUIs
					for(int j=0; j<phrase_1.size(); j++){
						//populate list of CUI strings from this mapping
						List<String> cuiList = new ArrayList<String>();
						Matcher m_c1 = c1.matcher(phrase_1.get(j).toString());
						while(m_c1.find()){
							cuiList.add(m_c1.group(0));
						}
						//now loop through CUI list and write out bigram pairs
						for(int h=0; h < cuiList.size()-1; h++){
							StringBuilder bigram = new StringBuilder(15);
							bigram.append(cuiList.get(h));  //cui1
							bigram.append(" ");
							bigram.append(cuiList.get(h+1)); //cui2
							
							//test to see if in prior
							if(DEBUG){log.info("PRIOR: " + prior.get(bigram.toString()) );}
							if( prior.get(bigram.toString()) == null ){
								word.set(bigram.toString());
								if(DEBUG){log.info("Bigram: " + bigram.toString());}
								context.write(word, one);
								prior.put(bigram.toString(), "1");
							}
							
						}
						//If there is a phrase2 add the last CUI of phrase 1 to the first CUI of phrase 2
						if(i+1 < my_phrases.size()){
							//loop through all phrase 2 mappings and link to this phrase 1 mapping
							for(int k=0; k<phrase_2.size(); k++){
								List<String> cuiList2 = new ArrayList<String>();
								Matcher m_c2 = c1.matcher(phrase_2.get(k).toString());
								while(m_c2.find()){
									cuiList2.add(m_c2.group(0));
								}
								
								StringBuilder bigram2 = new StringBuilder(15);
								bigram2.append(cuiList.get(cuiList.size()-1));  //cui1 is last cui of the current phrase 1
								bigram2.append(" ");
								bigram2.append(cuiList2.get(0)); //cui2 is first cui of the current phrase 2
								if( prior.get(bigram2.toString()) == null ){
									word.set(bigram2.toString());
									if(DEBUG){log.info("Bigram2: " + bigram2.toString());}
									context.write(word, one);
									prior.put(bigram2.toString(), "1");
								} //end if prior
								
								
							} //end for k in phrase 2
						} //end in phrase 2 exists
					} //end for each mapping in phrase 1
					
					
					
				} //for each phrase in the utterance
				
			} //end if we have phrases

			
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
		Configuration conf = new Configuration(true);
		
		if(args[2].equals("article")){
			conf.set("textinputformat.record.delimiter","@@@@@@@");
		}
		else{
			conf.set("textinputformat.record.delimiter","'EOU'.");
		}
		
		Job job = new Job(conf);
	
		job.setJarByClass(CUICollector.class);
		job.setMapperClass(CUIMapper.class);
		job.setCombinerClass(CUIReducer.class);
		job.setReducerClass(CUIReducer.class);
		
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(IntWritable.class);
		
		FileInputFormat.addInputPath(job, new Path(args[0]));
		job.setInputFormatClass(TextInputFormat.class);
		FileOutputFormat.setOutputPath(job, new Path(args[1]));
		
		System.exit(job.waitForCompletion(true) ? 0 : 1);
	}
}