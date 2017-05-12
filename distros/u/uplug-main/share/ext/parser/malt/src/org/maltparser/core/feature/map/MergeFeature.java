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
public class MergeFeature implements FeatureMapFunction {
	protected FeatureFunction firstFeature;
	protected FeatureFunction secondFeature;
	protected SymbolTableHandler tableHandler;
	protected SymbolTable table;
	protected SingleFeatureValue singleFeatureValue;
	
	public MergeFeature(SymbolTableHandler tableHandler) throws MaltChainedException {
		super();
		setTableHandler(tableHandler);
		singleFeatureValue = new SingleFeatureValue(this);
	}
	
	public void initialize(Object[] arguments) throws MaltChainedException {
		if (arguments.length != 2) {
			throw new FeatureException("Could not initialize MergeFeature: number of arguments are not correct. ");
		}
		if (!(arguments[0] instanceof FeatureFunction)) {
			throw new FeatureException("Could not initialize MergeFeature: the first argument is not a feature. ");
		}
		if (!(arguments[1] instanceof FeatureFunction)) {
			throw new FeatureException("Could not initialize MergeFeature: the second argument is not a feature. ");
		}
		setFirstFeature((FeatureFunction)arguments[0]);
		setSecondFeature((FeatureFunction)arguments[1]);
		setSymbolTable(tableHandler.addSymbolTable("MERGE2_"+firstFeature.getSymbolTable().getName()+"_"+secondFeature.getSymbolTable().getName(), firstFeature.getSymbolTable()));
	}
	
	public void update() throws MaltChainedException {
//		multipleFeatureValue.reset();
		singleFeatureValue.reset();
		firstFeature.update();
		secondFeature.update();
		FunctionValue firstValue = firstFeature.getFeatureValue();
		FunctionValue secondValue = secondFeature.getFeatureValue();
		if (firstValue instanceof SingleFeatureValue && secondValue instanceof SingleFeatureValue) {
			String symbol = ((SingleFeatureValue)firstValue).getSymbol();
			if (((FeatureValue)firstValue).isNullValue() && ((FeatureValue)secondValue).isNullValue()) {
				singleFeatureValue.setCode(firstFeature.getSymbolTable().getSymbolStringToCode(symbol));
				singleFeatureValue.setKnown(firstFeature.getSymbolTable().getKnown(symbol));
				singleFeatureValue.setSymbol(symbol);
				singleFeatureValue.setNullValue(true);
//				multipleFeatureValue.addFeatureValue(firstFeature.getSymbolTable().getSymbolStringToCode(symbol), symbol, true);
//				multipleFeatureValue.setNullValue(true);
			} else {
				StringBuilder mergedValue = new StringBuilder();
				mergedValue.append(((SingleFeatureValue)firstValue).getSymbol());
				mergedValue.append('~');
				mergedValue.append(((SingleFeatureValue)secondValue).getSymbol());
				
				singleFeatureValue.setCode(table.addSymbol(mergedValue.toString()));
				singleFeatureValue.setKnown(table.getKnown(mergedValue.toString()));
				singleFeatureValue.setSymbol(mergedValue.toString());
				singleFeatureValue.setNullValue(false);
//				multipleFeatureValue.addFeatureValue(table.addSymbol(mergedValue.toString()), mergedValue.toString(), table.getKnown(mergedValue.toString()));
//				multipleFeatureValue.setNullValue(false);
			}
		} else {
			throw new FeatureException("It is not possible to merge Split-features. ");
		}
	}
	
	public Class<?>[] getParameterTypes() {
		Class<?>[] paramTypes = { org.maltparser.core.feature.function.FeatureFunction.class, org.maltparser.core.feature.function.FeatureFunction.class };
		return paramTypes; 
	}

	public FeatureValue getFeatureValue() {
		return singleFeatureValue;
//		return multipleFeatureValue;
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
		singleFeatureValue.setCardinality(table.getValueCounter());
//		multipleFeatureValue.setCardinality(table.getValueCounter()); 
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
		sb.append("Merge(");
		sb.append(firstFeature.toString());
		sb.append(", ");
		sb.append(secondFeature.toString());
		sb.append(')');
		return sb.toString();
	}
	
}
