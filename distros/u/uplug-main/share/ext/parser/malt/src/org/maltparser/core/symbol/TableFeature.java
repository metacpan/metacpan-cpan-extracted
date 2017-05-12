package org.maltparser.core.symbol;

import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.feature.function.FeatureFunction;
import org.maltparser.core.feature.function.Modifiable;
import org.maltparser.core.feature.value.FeatureValue;
import org.maltparser.core.feature.value.SingleFeatureValue;
import org.maltparser.core.symbol.nullvalue.NullValues.NullValueId;

public abstract class TableFeature implements FeatureFunction, Modifiable {
	protected SingleFeatureValue featureValue;
	protected SymbolTable table;
	protected String tableName;
	protected SymbolTableHandler tableHandler;
	
	public TableFeature() throws MaltChainedException {
		featureValue = new SingleFeatureValue(this);
	}
	
	public abstract void update() throws MaltChainedException;
	public abstract void initialize(Object[] arguments) throws MaltChainedException;
	public abstract Class<?>[] getParameterTypes();
	
	public String getSymbol(int value) throws MaltChainedException {
		return table.getSymbolCodeToString(value);
	}
	
	public int getCode(String value) throws MaltChainedException {
		return table.getSymbolStringToCode(value);
	}
	
	public SymbolTable getSymbolTable() {
		return table;
	}

	public void setSymbolTable(SymbolTable table) {
		this.table = table;
	}
	
	public void updateCardinality() {
		if (table != null) {
			featureValue.setCardinality(table.getValueCounter());
		} else {
			featureValue.setCardinality(0);
		}
	}
	
	public void setFeatureValue(int value) throws MaltChainedException {
		if (table.getSymbolCodeToString(value) == null) {
			featureValue.setCode(value);
			featureValue.setKnown(table.getKnown(value));
			featureValue.setSymbol(table.getNullValueSymbol(NullValueId.NO_NODE));
			featureValue.setNullValue(true);
		} else {
			featureValue.setCode(value);
			featureValue.setKnown(table.getKnown(value));
			featureValue.setSymbol(table.getSymbolCodeToString(value));
			featureValue.setNullValue(table.isNullValue(value));
		}
	}
	
	public void setFeatureValue(String value) throws MaltChainedException {
		if (table.getSymbolStringToCode(value) < 0) {
			featureValue.setCode(table.getNullValueCode(NullValueId.NO_NODE));
			featureValue.setKnown(table.getKnown(value));
			featureValue.setSymbol(value);
			featureValue.setNullValue(true);
		} else {
			featureValue.setCode(table.getSymbolStringToCode(value));
			featureValue.setKnown(table.getKnown(value));
			featureValue.setSymbol(value);
			featureValue.setNullValue(table.isNullValue(value));
		}
	}
	
	public FeatureValue getFeatureValue() {
		return featureValue;
	}
	
	public SymbolTableHandler getTableHandler() {
		return tableHandler;
	}

	public void setTableHandler(SymbolTableHandler tableHandler) {
		this.tableHandler = tableHandler;
	}
	
	public boolean equals(Object obj) {
		if (!(obj instanceof TableFeature)) {
			return false;
		}
		if (!obj.toString().equals(this.toString())) {
			return false;
		}
		return true;
	}

	public void setTableName(String name) {
		this.tableName = name;
	}
	
	public String getTableName() {
		return tableName;
	}
	
	public String toString() {
		return tableName;
	}
}
