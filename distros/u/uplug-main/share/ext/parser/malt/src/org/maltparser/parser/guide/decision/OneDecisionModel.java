package org.maltparser.parser.guide.decision;

import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.feature.FeatureModel;
import org.maltparser.core.feature.FeatureVector;
import org.maltparser.core.syntaxgraph.DependencyStructure;
import org.maltparser.parser.DependencyParserConfig;
import org.maltparser.parser.guide.ClassifierGuide;
import org.maltparser.parser.guide.GuideException;
import org.maltparser.parser.guide.instance.AtomicModel;
import org.maltparser.parser.guide.instance.DecisionTreeModel;
import org.maltparser.parser.guide.instance.FeatureDivideModel;
import org.maltparser.parser.guide.instance.InstanceModel;
import org.maltparser.parser.history.action.GuideDecision;
import org.maltparser.parser.history.action.MultipleDecision;
import org.maltparser.parser.history.action.SingleDecision;
/**
*
* @author Johan Hall
* @since 1.1
**/
public class OneDecisionModel implements DecisionModel {
	private ClassifierGuide guide;
	private String modelName;
	private FeatureModel featureModel;
	private InstanceModel instanceModel;
	private int decisionIndex;
	private DecisionModel prevDecisionModel;
	private String branchedDecisionSymbols;
	private int nIteration;

	
	public OneDecisionModel(ClassifierGuide guide, FeatureModel featureModel) throws MaltChainedException {
		this.branchedDecisionSymbols = "";
		setGuide(guide);
		setFeatureModel(featureModel);
		setDecisionIndex(0);
		if (guide.getGuideName() == null || guide.getGuideName().equals("")) {
			setModelName("odm"+decisionIndex);
		} else {
			setModelName(guide.getGuideName()+".odm"+decisionIndex);
		}
		
		setPrevDecisionModel(null);
	}
	
	public OneDecisionModel(ClassifierGuide guide, DecisionModel prevDecisionModel, String branchedDecisionSymbol) throws MaltChainedException {
		if (branchedDecisionSymbol != null && branchedDecisionSymbol.length() > 0) {
			this.branchedDecisionSymbols = branchedDecisionSymbol;
		} else {
			this.branchedDecisionSymbols = "";
		}
		setGuide(guide);
		setFeatureModel(prevDecisionModel.getFeatureModel());
		setDecisionIndex(prevDecisionModel.getDecisionIndex() + 1);
		setPrevDecisionModel(prevDecisionModel);
		if (branchedDecisionSymbols != null && branchedDecisionSymbols.length() > 0) {
			setModelName("odm"+decisionIndex+branchedDecisionSymbols);
		} else {
			setModelName("odm"+decisionIndex);
		}
	}
	
	public void updateFeatureModel() throws MaltChainedException {
		featureModel.update();
	}
	
	public void updateCardinality() throws MaltChainedException {
		featureModel.updateCardinality();
	}
	

	public void finalizeSentence(DependencyStructure dependencyGraph) throws MaltChainedException {
		if (instanceModel != null) {
			instanceModel.finalizeSentence(dependencyGraph);
		}
	}
	
	public void noMoreInstances() throws MaltChainedException {
		if (guide.getGuideMode() == ClassifierGuide.GuideMode.CLASSIFY) {
			throw new GuideException("The decision model could not create it's model. ");
		}
		featureModel.updateCardinality();
		if (instanceModel != null) {
			instanceModel.noMoreInstances();
			instanceModel.train();
		}
	}

	public void terminate() throws MaltChainedException {
		if (instanceModel != null) {
			instanceModel.terminate();
			instanceModel = null;
		}
	}
	
	public void addInstance(GuideDecision decision) throws MaltChainedException {
		updateFeatureModel();
		final SingleDecision singleDecision = (decision instanceof SingleDecision)?(SingleDecision)decision:((MultipleDecision)decision).getSingleDecision(decisionIndex);
		
		if (instanceModel == null) {
			initInstanceModel(singleDecision.getTableContainer().getTableContainerName());
		}
		instanceModel.addInstance(singleDecision);
	}
	
	public boolean predict(GuideDecision decision) throws MaltChainedException {
		updateFeatureModel();
		final SingleDecision singleDecision = (decision instanceof SingleDecision)?(SingleDecision)decision:((MultipleDecision)decision).getSingleDecision(decisionIndex);

		if (instanceModel == null) {
			initInstanceModel(singleDecision.getTableContainer().getTableContainerName());
		}
		return instanceModel.predict(singleDecision);
	}
	
	public FeatureVector predictExtract(GuideDecision decision) throws MaltChainedException {
		updateFeatureModel();
		final SingleDecision singleDecision = (decision instanceof SingleDecision)?(SingleDecision)decision:((MultipleDecision)decision).getSingleDecision(decisionIndex);

		if (instanceModel == null) {
			initInstanceModel(singleDecision.getTableContainer().getTableContainerName());
		}
		return instanceModel.predictExtract(singleDecision);
	}
	
	public FeatureVector extract() throws MaltChainedException {
		updateFeatureModel();
		return instanceModel.extract();
	}
	
	public boolean predictFromKBestList(GuideDecision decision) throws MaltChainedException {
		if (decision instanceof SingleDecision) {
			return ((SingleDecision)decision).updateFromKBestList();
		} else {
			return ((MultipleDecision)decision).getSingleDecision(decisionIndex).updateFromKBestList();
		}
	}
	
	public ClassifierGuide getGuide() {
		return guide;
	}

	public String getModelName() {
		return modelName;
	}
	
	public FeatureModel getFeatureModel() {
		return featureModel;
	}

	public int getDecisionIndex() {
		return decisionIndex;
	}

	public DecisionModel getPrevDecisionModel() {
		return prevDecisionModel;
	}
	
	private void setPrevDecisionModel(DecisionModel prevDecisionModel) {
		this.prevDecisionModel = prevDecisionModel;
	}

	private void setFeatureModel(FeatureModel featureModel) {
		this.featureModel = featureModel;
	}
	
	private void setDecisionIndex(int decisionIndex) {
		this.decisionIndex = decisionIndex;
	}

	private void setModelName(String modelName) {
		this.modelName = modelName;
	}
	
	private void setGuide(ClassifierGuide guide) {
		this.guide = guide;
	}
	
	private final void initInstanceModel(String subModelName) throws MaltChainedException {
		FeatureVector fv = featureModel.getFeatureVector(branchedDecisionSymbols+"."+subModelName);
		if (fv == null) {
			fv = featureModel.getFeatureVector(subModelName);
		}
		if (fv == null) {
			fv = featureModel.getMainFeatureVector();
		}
		DependencyParserConfig c = guide.getConfiguration();
		
//		if (c.getOptionValue("guide", "tree_automatic_split_order").toString().equals("yes") ||
//				(c.getOptionValue("guide", "tree_split_columns")!=null &&
//			c.getOptionValue("guide", "tree_split_columns").toString().length() > 0) ||
//			(c.getOptionValue("guide", "tree_split_structures")!=null &&
//			c.getOptionValue("guide", "tree_split_structures").toString().length() > 0)) {
//			instanceModel = new DecisionTreeModel(fv, this); 
//		}else 
		if (c.getOptionValue("guide", "data_split_column").toString().length() == 0) {
			instanceModel = new AtomicModel(-1, fv, this);
		} else {
			instanceModel = new FeatureDivideModel(fv, this);
		}
	}
	
	public String toString() {		
		return modelName;
	}
}
