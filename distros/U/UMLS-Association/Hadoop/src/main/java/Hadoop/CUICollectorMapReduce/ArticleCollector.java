package Hadoop.CUICollectorMapReduce;

import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.HashMap;

import org.apache.commons.cli.*;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;


/**
 * ArticleCollector processes MetaMap output files in order to condense all utterances from the same 
 * article together into one record for processing by CUICollector.  I does this by processing each
 * utterance as a record and maps all utterance text to the pubmed ID as the KEY. All utterance records
 * with the same KEY value are then collected in the Reducer and concatenated into one record delimited
 * by a new string "@@@@@@@".  This also concatenates all MetaMap files into one large file for processing
 * by the CUICollector.
 * 
 * @author Amy Olex
 * @version 1.0
 * 
 */
public class ArticleCollector {
/*
	public static class TextArrayWritable extends ArrayWritable{
		public TextArrayWritable(){
			super(Text.class);
		}
		public TextArrayWritable(Text[] values){
			super(Text.class, values);
		}
	}
	*/
	
	/**
	 * The ArticleMapper class extends <code>Mapper</code> and implements the <code>map</code> method.
	 * Input into the ArticleMapper is of type <code><Object, Text></code> for the input <K,V> pair.
	 * Output is of type <code><Text, Text></code> for the output <K,V> pair.
	 * 
	 * @author Amy Olex
	 *
	 */
	public static class ArticleMapper extends Mapper<Object, Text, Text, Text>{

		public static final Log log = LogFactory.getLog(ArticleMapper.class);
		public static final boolean DEBUG = false;
		
		private Text pubmed_id = new Text();
		private Text word = new Text();

		/**
		 * Parses out pubmed ID as KEY and maps all utterance text to the VALUE, then writes <KEY,VALUE> pair
		 * to Hadoop context for use by the Reducer.
		 * 
		 * @param key The KEY automatically set by the RecordReader.
		 * @param value The record value (i.e. the text for a single utterance).
		 * @param context The Hadoop context object.
		 * 
		 */
		public void map(Object key, Text value, Context context) throws IOException, InterruptedException {
			
			String thisString = value.toString();
			String pattern = "utterance[(']{2}([0-9]*)\\.([a-z]{2})\\.([0-9]*)',";
			Pattern r = Pattern.compile(pattern);
			Matcher m = r.matcher(thisString);
			StringBuilder newString = new StringBuilder(thisString.length()+10);
			
			//if(DEBUG){log.info("THIS STRING: " + thisString);}
			while(m.find()){
				newString.append(m.group(2).toString());
				newString.append("::");
				newString.append(m.group(3).toString());
				if(DEBUG){log.info("MAPPER: " + m.group(1).toString() + "::" + newString.toString());}
				newString.append("::");
				newString.append(thisString);
				word.set(newString.toString());
				
				pubmed_id.set(m.group(1).toString());
				
				context.write(pubmed_id, word);
			}
		}
	}

	/**
	 * The ArticleReducer extends <code>Reducer</code> and implements the <code>reduce</code> method.
	 * Input into the ArticleReducer is of type <code><Text, Text></code> for the input <K,V> pair.  
	 * Output is of type <code><Text, Text></code> for the output <K,V> pair.
	 * 
	 * @author Amy Olex
	 *
	 */
	public static class ArticleReducer extends Reducer<Text,Text,Text,Text> {
		
		private Text result = new Text();
		public static final Log log = LogFactory.getLog(ArticleMapper.class);
		public static final boolean DEBUG = false;
		
		/**
		 * Collects, sorts, and concatenates all utterance records with the same pubmed ID into a single record.
		 * The pubmed ID is still the KEY, and the VALUE is now the concatenated article record.
		 * <Key,Value> pairs are then written to the Hadoop context for output by the RecordWriter.
		 * 
		 * @param key The unique pubmed ID identified by ArticleMapper of type <code>Text<\code>.
		 * @param values An Iterable of type <code>Text<\code> containing the set of Utterance records that had the same pubmed ID.
		 * @param context The Hadoop context object.
		 * 
		 */
		public void reduce(Text key, Iterable<Text> values, Context context) throws IOException, InterruptedException {
			StringBuilder articles = new StringBuilder(64);
			///Will need to change this to possibly be a nested hash, top level is ti/ai and second is the number 1, 2, 3 etc.
			HashMap<String,HashMap<Integer,String>> myStrings = new HashMap<String,HashMap<Integer,String>>();
			//init the title hash
			myStrings.put("ti", new HashMap<Integer,String>());
			myStrings.put("tx", new HashMap<Integer,String>());
			myStrings.put("ab", new HashMap<Integer,String>());
			
			for (Text val : values) {
				String toParse = val.toString();
				if(DEBUG){log.info("REDUCER INPUT: " + toParse);}
				String pattern = "([a-z]{2})::([0-9]*)::(.*)";
				Pattern r = Pattern.compile(pattern);
				Matcher m = r.matcher(toParse);
				m.find();
				try{
				myStrings.get(m.group(1)).put(Integer.parseInt(m.group(2)), toParse);
				}
				catch(IllegalStateException e){
					log.info("REDUCER ERROR String: " + toParse);
				}
			}
			//need to check for empty strings here.
			//parse out titles first, then old titles, then abstracts
			for(int i=1; i<=myStrings.get("ti").size(); i++){
				articles.append(myStrings.get("ti").get(i));
			}
			for(int i=1; i<=myStrings.get("tx").size(); i++){
				articles.append(myStrings.get("tx").get(i));
			}
			for(int i=1; i<=myStrings.get("ab").size(); i++){
				articles.append(myStrings.get("ab").get(i));
			}
			//append unique file delimiter
			articles.append("@@@@@@@");
			if(DEBUG){log.info("REDUCER: " + articles.toString());}
			result.set(articles.toString());
			context.write(key, result);
		}
	}

	/**
	 * The main method for running the ArticleCollector.  Sets up job configuration, defines classes to use,
	 * Sets output values and formats, and executes the MapReduce job.
	 * 
	 * @param args Input arguments from the command line. arg[0] is the path to the input file/directory. arg[1] is the name of the output directory.
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
		
		
		CommandLineParser parser = new GnuParser();
		HelpFormatter formatter = new HelpFormatter();
		CommandLine cmd;
		
		try{
			cmd = parser.parse(options, args);
		} catch(ParseException e){
			System.out.println(e.getMessage());
			formatter.printHelp("hadoop jar <path/to/jar/file.jar> Hadoop.CUICollectorMapReduce.ArticleCollector -i <input> -o <outdir>", options);
			System.exit(1);
			return;
		}
				
		Configuration conf = new Configuration(true);
		conf.set("textinputformat.record.delimiter","'EOU'.");
		
		Job job = new Job(conf);
		
		job.setJarByClass(ArticleCollector.class);
		job.setMapperClass(ArticleMapper.class);
		job.setReducerClass(ArticleReducer.class);
		
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(Text.class);
		
		FileInputFormat.addInputPath(job, new Path(cmd.getOptionValue("input")));
		job.setInputFormatClass(TextInputFormat.class);
		FileOutputFormat.setOutputPath(job, new Path(cmd.getOptionValue("outdir")));
		
		System.exit(job.waitForCompletion(true) ? 0 : 1);
	}
}