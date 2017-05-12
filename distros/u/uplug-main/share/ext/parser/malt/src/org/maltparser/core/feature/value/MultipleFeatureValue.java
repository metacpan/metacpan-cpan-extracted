package org.maltparser.core.feature.value;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.SortedMap;
import java.util.TreeMap;

import org.maltparser.core.feature.function.Function;
/**
 *  
 *
 * @author Johan Hall
 * @since 1.0
**/
public class MultipleFeatureValue extends FeatureValue {
	protected SortedMap<Integer, String> featureValues;
	protected Map<Integer, Boolean> featureKnown;
	
	public MultipleFeatureValue(Function function) {
		super(function);
		setFeatureValues(new TreeMap<Integer, String>(), new HashMap<Integer, Boolean>());
	}
	
	public void reset() {
		super.reset();
		featureValues.clear();
		featureKnown.clear();
	}
	
	public void addFeatureValue(int code, String Symbol, boolean known) {
		featureValues.put(code, Symbol);
		featureKnown.put(code, known);
	}
	
	protected void setFeatureValues(SortedMap<Integer, String> featureValues, Map<Integer, Boolean> featureKnown) {
		this.featureValues = featureValues;
		this.featureKnown = featureKnown;
	}
	
	public Set<Integer> getCodes() {
		return (Set<Integer>)featureValues.keySet();
	}
	
	public int getFirstCode() {
		return featureValues.firstKey();
	}
	
	public Set<String> getSymbols() {
		return new HashSet<String>(featureValues.values());
	}
	
	public String getFirstSymbol() {
		return featureValues.get(featureValues.firstKey());
	}	
	
	public boolean isKnown(int value) {
		return featureKnown.get(value);
	}
	
	public String toString() {
		final StringBuilder sb = new StringBuilder();
		sb.append(super.toString()+ "{ ");
		for (Integer code : featureValues.keySet()) {
			sb.append("{"+featureValues.get(code) + "->" +code + ", known="+featureKnown.get(code)+"} ");
		}
		sb.append("}");
		return sb.toString();
	}
}
