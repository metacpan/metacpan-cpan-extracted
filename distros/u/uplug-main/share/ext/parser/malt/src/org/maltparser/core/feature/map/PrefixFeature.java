package org.maltparser.core.feature.map;

import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.feature.FeatureException;
import org.maltparser.core.feature.function.FeatureFunction;
import org.maltparser.core.feature.function.FeatureMapFunction;
import org.maltparser.core.feature.value.FeatureValue;
import org.maltparser.core.feature.value.MultipleFeatureValue;
import org.maltparser.core.feature.value.SingleFeatureValue;
import org.maltparser.core.symbol.SymbolTable;
import org.maltparser.core.symbol.SymbolTableHandler;
/**
*
*
* @author Johan Hall
*/
public class PrefixFeature implements FeatureMapFunction {
	protected FeatureFunction parentFeature;
	protected MultipleFeatureValue multipleFeatureValue;
	protected SymbolTableHandler tableHandler;
	protected SymbolTable table;
	protected int prefixLength;

	public PrefixFeature(SymbolTableHandler tableHandler) throws MaltChainedException {
		super();
		setTableHandler(tableHandler);
		multipleFeatureValue = new MultipleFeatureValue(this);
	}
	
	public void initialize(Object[] arguments) throws MaltChainedException {
		if (arguments.length != 2) {
			throw new FeatureException("Could not initialize PrefixFeature: number of arguments are not correct. ");
		}
		if (!(arguments[0] instanceof FeatureFunction)) {
			throw new FeatureException("Could not initialize PrefixFeature: the first argument is not a feature. ");
		}
		if (!(arguments[1] instanceof Integer)) {
			throw new FeatureException("Could not initialize PrefixFeature: the second argument is not a string. ");
		}
		setParentFeature((FeatureFunction)arguments[0]);
		setPrefixLength(((Integer)arguments[1]).intValue());
		setSymbolTable(tableHandler.addSymbolTable("PREFIX_"+prefixLength+"_"+parentFeature.getSymbolTable().getName(), parentFeature.getSymbolTable()));
	}
	
	public Class<?>[] getParameterTypes() {
		Class<?>[] paramTypes = { org.maltparser.core.syntaxgraph.feature.InputColumnFeature.class, java.lang.Integer.class };
		return paramTypes; 
	}
	
	public FeatureValue getFeatureValue() {
		return multipleFeatureValue;
	}
	
	public int getCode(String symbol) throws MaltChainedException {
		return table.getSymbolStringToCode(symbol);
	}

	public String getSymbol(int code) throws MaltChainedException {
		return table.getSymbolCodeToString(code);
	}

	public void update() throws MaltChainedException {
		parentFeature.update();
		FeatureValue value = parentFeature.getFeatureValue();
		if (value instanceof SingleFeatureValue) {
			String symbol = ((SingleFeatureValue)value).getSymbol();
			if (((FeatureValue)value).isNullValue()) {
				multipleFeatureValue.addFeatureValue(parentFeature.getSymbolTable().getSymbolStringToCode(symbol), symbol, true);
				multipleFeatureValue.setNullValue(true);
			} else {
				String prefixStr;
				if (symbol.length()-prefixLength > 0) {
					prefixStr = symbol.substring(0, prefixLength);
				} else {
					prefixStr = symbol;
				}
				int code = table.addSymbol(prefixStr);
				multipleFeatureValue.addFeatureValue(code, prefixStr, table.getKnown(prefixStr));
				multipleFeatureValue.setNullValue(false);
			}
		} else if (value instanceof MultipleFeatureValue) {
			multipleFeatureValue.reset();
			if (((MultipleFeatureValue)value).isNullValue()) {
				multipleFeatureValue.addFeatureValue(parentFeature.getSymbolTable().getSymbolStringToCode(((MultipleFeatureValue)value).getFirstSymbol()), ((MultipleFeatureValue)value).getFirstSymbol(), true);
				multipleFeatureValue.setNullValue(true);
			} else {
				for (String symbol : ((MultipleFeatureValue)value).getSymbols()) {
					String prefixStr;
					if (symbol.length()-prefixLength > 0) {
						prefixStr = symbol.substring(0, prefixLength);
					} else {
						prefixStr = symbol;
					}
					int code = table.addSymbol(prefixStr);
					multipleFeatureValue.addFeatureValue(code, prefixStr, table.getKnown(prefixStr));
					multipleFeatureValue.setNullValue(true);
				}
			}
		}
	}
	
	public void updateCardinality() throws MaltChainedException {
		parentFeature.updateCardinality();
		multipleFeatureValue.setCardinality(table.getValueCounter()); 
	}
	
	public FeatureFunction getParentFeature() {
		return parentFeature;
	} 
	
	public void setParentFeature(FeatureFunction feature) {
		this.parentFeature = feature;
	}
	
	public int getPrefixLength() {
		return prefixLength;
	}

	public void setPrefixLength(int prefixLength) {
		this.prefixLength = prefixLength;
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
		sb.append("Prefix(");
		sb.append(parentFeature.toString());
		sb.append(", ");
		sb.append(prefixLength);
		sb.append(')');
		return sb.toString();
	}
}

