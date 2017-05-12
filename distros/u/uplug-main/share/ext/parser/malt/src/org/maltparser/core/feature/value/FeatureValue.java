package org.maltparser.core.feature.value;

import org.maltparser.core.feature.function.Function;

/**
 *  
 *
 * @author Johan Hall
 * @since 1.0
**/
public abstract class FeatureValue extends FunctionValue {
	protected boolean nullValue;
	protected int cardinality;
	
	public FeatureValue(Function function) {
		super(function);
		setNullValue(true);
		setCardinality(0);
	}
	
	public void reset() {
		setNullValue(true);
	}

	public boolean isNullValue() {
		return nullValue;
	}

	public void setNullValue(boolean nullValue) {
		this.nullValue = nullValue;
	}

	/**
	 * Returns the cardinality (the number of distinct values) of the feature 
	 * 
	 * @return the cardinality (the number of distinct values) of the feature 
	 */
	public int getCardinality() {
		return cardinality;
	}

	/**
	 * Sets the cardinality (the number of distinct values) of the feature
	 * 
	 * @param cardinality  the cardinality (the number of distinct values)
	 */
	public void setCardinality(int cardinality) {
		this.cardinality = cardinality;
	}

	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		return super.equals(obj);
	}
	
	public String toString() {
		return super.toString()+ "[ null=" + nullValue + ", cardinality="+cardinality+" ] ";
	}
}