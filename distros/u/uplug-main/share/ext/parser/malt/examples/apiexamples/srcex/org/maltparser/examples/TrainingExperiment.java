package org.maltparser.examples;

import java.io.File;

import org.maltparser.MaltParserService;
import org.maltparser.core.exception.MaltChainedException;

/**
 * This example creates two Single Malt configurations files (model0.mco and model1.mco) by training the models using the small training data file 
 * ../data/talbanken05_train.conll 
 * 
 * @author Johan Hall
 */
public class TrainingExperiment {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		try {
			String trainingDataFile = ".."+File.separator+"data"+File.separator+"talbanken05_train.conll";
			// Trains the parser model model0.mco and uses the option container 0
			new MaltParserService(0).runExperiment("-c model0 -i "+trainingDataFile+" -m learn");
			// Trains the parser model model1.mco and uses the option container 1
			new MaltParserService(1).runExperiment("-c model1 -i "+trainingDataFile+" -m learn");
		} catch (MaltChainedException e) {
			System.err.println("MaltParser exception : " + e.getMessage());
		}
	}

}
