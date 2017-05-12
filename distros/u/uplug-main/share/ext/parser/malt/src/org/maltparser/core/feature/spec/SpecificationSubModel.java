package org.maltparser.core.feature.spec;

import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;

/**
*
*
* @author Johan Hall
*/
public class SpecificationSubModel implements Iterable<String> {
	private Map<String, Integer> featureSpec2IndexMap;
	private int counter;
	private String name;
	
	public SpecificationSubModel() {
		this("MAIN");
	}
	
	public SpecificationSubModel(String name) {
		setSubModelName(name);
		featureSpec2IndexMap = new LinkedHashMap<String, Integer>();
		counter = 0;
	}
	
	public void add(String featureSpec) {
		if (!featureSpec2IndexMap.containsKey(featureSpec)) {
			featureSpec2IndexMap.put(featureSpec, counter++);
		}
	}
	
	public int getFeatureIndex(String featureSpec) {
		if (featureSpec2IndexMap.containsKey(featureSpec)) {
			return -1;
		}
		return featureSpec2IndexMap.get(featureSpec);
	}
	
	public String getFeatureSpec(int featureId) {
		if (featureId < 0 || featureId >= featureSpec2IndexMap.size()) {
			return null;
		}
		return featureSpec2IndexMap.keySet().toArray(new String[]{})[featureId];
	}

	public String getSubModelName() {
		return name;
	}

	public void setSubModelName(String name) {
		this.name = name;
	}

	public int size() {
		return featureSpec2IndexMap.size();
	}
	
	public Iterator<String> iterator() {
		return featureSpec2IndexMap.keySet().iterator();
	}
	
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		if (featureSpec2IndexMap.size() != ((SpecificationSubModel)obj).size()) { return false; }
		for (String str : this) {
			if (!str.equals(((SpecificationSubModel)obj).getFeatureSpec(featureSpec2IndexMap.get(str)))) {
				return false;
			}
		}
		return true;
	}

	public String toString() {
		StringBuilder sb = new StringBuilder();
		for (String str : this) {
			sb.append(featureSpec2IndexMap.get(str));
			sb.append('\t');
			sb.append(str);
			sb.append('\n');
		}
		return sb.toString();
	}
}
