package org.maltparser.core.feature.map;

import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.feature.FeatureException;
import org.maltparser.core.feature.function.FeatureFunction;
import org.maltparser.core.feature.function.FeatureMapFunction;
import org.maltparser.core.feature.value.FeatureValue;
import org.maltparser.core.feature.value.FunctionValue;
import org.maltparser.core.feature.value.SingleFeatureValue;
import org.maltparser.core.symbol.SymbolTable;
import org.maltparser.core.symbol.SymbolTableHandler;
/**
*
*
* @author Johan Hall
*/
public class Merge3Feature implements FeatureMapFunction {
	protected FeatureFunction firstFeature;
	protected FeatureFunction secondFeature;
	protected FeatureFunction thirdFeature;
	protected SymbolTableHandler tableHandler;
	protected SymbolTable table;
	protected SingleFeatureValue singleFeatureValue;
	
	public Merge3Feature(SymbolTableHandler tableHandler) throws MaltChainedException {
		super();
		setTableHandler(tableHandler);
		singleFeatureValue = new SingleFeatureValue(this);
	}
	
	public void initialize(Object[] arguments) throws MaltChainedException {
		if (arguments.length != 3) {
			throw new FeatureException("Could not initialize Merge3Feature: number of arguments are not correct. ");
		}
		if (!(arguments[0] instanceof FeatureFunction)) {
			throw new FeatureException("Could not initialize Merge3Feature: the first argument is not a feature. ");
		}
		if (!(arguments[1] instanceof FeatureFunction)) {
			throw new FeatureException("Could not initialize Merge3Feature: the second argument is not a feature. ");
		}
		if (!(arguments[2] instanceof FeatureFunction)) {
			throw new FeatureException("Could not initialize Merge3Feature: the third argument is not a feature. ");
		}
		setFirstFeature((FeatureFunction)arguments[0]);
		setSecondFeature((FeatureFunction)arguments[1]);
		setThirdFeature((FeatureFunction)arguments[2]);
		setSymbolTable(tableHandler.addSymbolTable("MERGE3_"+firstFeature.getSymbolTable().getName()+"_"+secondFeature.getSymbolTable().getName()+"_"+thirdFeature.getSymbolTable().getName(), 
				firstFeature.getSymbolTable()));
	}
	
	public void update() throws MaltChainedException {
		singleFeatureValue.reset();
		firstFeature.update();
		secondFeature.update();
		thirdFeature.update();
		FunctionValue firstValue = firstFeature.getFeatureValue();
		FunctionValue secondValue = secondFeature.getFeatureValue();
		FunctionValue thirdValue = thirdFeature.getFeatureValue();
		if (firstValue instanceof SingleFeatureValue && secondValue instanceof SingleFeatureValue && thirdValue instanceof SingleFeatureValue) {
			String symbol = ((SingleFeatureValue)firstValue).getSymbol();
			if (((FeatureValue)firstValue).isNullValue() && ((FeatureValue)secondValue).isNullValue() && ((FeatureValue)thirdValue).isNullValue()) {
				singleFeatureValue.setCode(firstFeature.getSymbolTable().getSymbolStringToCode(symbol));
				singleFeatureValue.setKnown(firstFeature.getSymbolTable().getKnown(symbol));
				singleFeatureValue.setSymbol(symbol);
				singleFeatureValue.setNullValue(true);
			} else {
				StringBuilder mergedValue = new StringBuilder();
				mergedValue.append(((SingleFeatureValue)firstValue).getSymbol());
				mergedValue.append('~');
				mergedValue.append(((SingleFeatureValue)secondValue).getSymbol());
				mergedValue.append('~');
				mergedValue.append(((SingleFeatureValue)thirdValue).getSymbol());
				singleFeatureValue.setCode(table.addSymbol(mergedValue.toString()));
				singleFeatureValue.setKnown(table.getKnown(mergedValue.toString()));
				singleFeatureValue.setSymbol(mergedValue.toString());
				singleFeatureValue.setNullValue(false);
			}
		} else {
			throw new FeatureException("It is not possible to merge Split features. ");
		}
	}
	
	public Class<?>[] getParameterTypes() {
		Class<?>[] paramTypes = { 	org.maltparser.core.feature.function.FeatureFunction.class, 
				org.maltparser.core.feature.function.FeatureFunction.class, 
				org.maltparser.core.feature.function.FeatureFunction.class };
		return paramTypes; 
	}

	public FeatureValue getFeatureValue() {
		return singleFeatureValue;
	}

	public String getSymbol(int code) throws MaltChainedException {
		return table.getSymbolCodeToString(code);
	}
	
	public int getCode(String symbol) throws MaltChainedException {
		return table.getSymbolStringToCode(symbol);
	}
	
	public void updateCardinality() throws MaltChainedException {
		firstFeature.updateCardinality();
		secondFeature.updateCardinality();
		thirdFeature.updateCardinality();
		singleFeatureValue.setCardinality(table.getValueCounter()); 
	}
	
	public FeatureFunction getFirstFeature() {
		return firstFeature;
	}

	public void setFirstFeature(FeatureFunction firstFeature) {
		this.firstFeature = firstFeature;
	}

	public FeatureFunction getSecondFeature() {
		return secondFeature;
	}

	public void setSecondFeature(FeatureFunction secondFeature) {
		this.secondFeature = secondFeature;
	}

	public FeatureFunction getThirdFeature() {
		return thirdFeature;
	}

	public void setThirdFeature(FeatureFunction thirdFeature) {
		this.thirdFeature = thirdFeature;
	}
	
	public SymbolTableHandler getTableHandler() {
		return tableHandler;
	}

	public void setTableHandler(SymbolTableHandler tableHandler) {
		this.tableHandler = tableHandler;
	}

	public SymbolTable getSymbolTable() {
		return table;
	}

	public void setSymbolTable(SymbolTable table) {
		this.table = table;
	}
	
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		return obj.toString().equals(this.toString());
	}
	
	public String toString() {
		final StringBuilder sb = new StringBuilder();
		sb.append("Merge3(");
		sb.append(firstFeature.toString());
		sb.append(", ");
		sb.append(secondFeature.toString());
		sb.append(", ");
		sb.append(thirdFeature.toString());
		sb.append(')');
		return sb.toString();
	}
}
