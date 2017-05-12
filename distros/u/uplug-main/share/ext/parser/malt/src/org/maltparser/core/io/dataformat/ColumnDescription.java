package org.maltparser.core.io.dataformat;

import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.symbol.SymbolTable;
import org.maltparser.core.symbol.SymbolTableHandler;

/**
 *  
 *
 * @author Johan Hall
 * @since 1.0
**/
public class ColumnDescription implements Comparable<ColumnDescription> {
	// Categories
	public static final int INPUT = 1;
	public static final int HEAD = 2;
	public static final int DEPENDENCY_EDGE_LABEL = 3;
	public static final int PHRASE_STRUCTURE_EDGE_LABEL = 4;
	public static final int PHRASE_STRUCTURE_NODE_LABEL = 5;
	public static final int SECONDARY_EDGE_LABEL = 6;
	
	// Types
	public static final int STRING = 1;
	public static final int INTEGER = 2;
	public static final int BOOLEAN = 3;
	public static final int ECHO = 4;
	public static final int IGNORE = 5;
	
	private int position;
	private String name;
	private int category;
	private int type;
	private String defaultOutput;
	private SymbolTable symbolTable;
	private int cachedHash;
	
	public ColumnDescription(int position, String name, String category, String type, String defaultOutput, SymbolTableHandler symbolTables, String specialSymbolsfileName, String rootLabel) throws MaltChainedException {
		setPosition(position);
		setName(name);
		setCategory(category);
		setType(type);
		setDefaultOutput(defaultOutput);
		createSymbolTable(symbolTables, specialSymbolsfileName, rootLabel);
	}
	
	private void createSymbolTable(SymbolTableHandler symbolTables, String nullValueStrategy, String rootLabel) throws MaltChainedException {
		if (type == ColumnDescription.STRING || type == ColumnDescription.INTEGER || type == ColumnDescription.BOOLEAN) {
			if (category == ColumnDescription.DEPENDENCY_EDGE_LABEL) {
				symbolTable = symbolTables.addSymbolTable(name, category, nullValueStrategy, rootLabel);
			} else {
				symbolTable = symbolTables.addSymbolTable(name, category, nullValueStrategy);
			}
		} else {
			symbolTable = null;
		}
	}
	
	public int getPosition() {
		return position;
	}

	public String getName() {
		return name;
	}

	public int getCategory() {
		return category;
	}
	
	public int getType() {
		return type;
	}
	
	public String getDefaultOutput() {
		return defaultOutput;
	}
	
	public SymbolTable getSymbolTable() {
		return symbolTable;
	}
	
	private void setPosition(int position) throws MaltChainedException {
		if (position >= 0) {
			this.position = position;
		} else {
			throw new DataFormatException("Position value for column must be a non-negative value. ");
		}
	}

	private void setName(String name) {
		this.name = name.toUpperCase();
	}
	
	private void setCategory(String category) throws MaltChainedException {
		if (category.toUpperCase().equals("INPUT")) {
			this.category = ColumnDescription.INPUT;
		} else if (category.toUpperCase().equals("HEAD")) {
			this.category = ColumnDescription.HEAD;
		} else if (category.toUpperCase().equals("OUTPUT")) {
			this.category = ColumnDescription.DEPENDENCY_EDGE_LABEL;
		} else if (category.toUpperCase().equals("DEPENDENCY_EDGE_LABEL")) {
			this.category = ColumnDescription.DEPENDENCY_EDGE_LABEL;
		} else if (category.toUpperCase().equals("PHRASE_STRUCTURE_EDGE_LABEL")) {
			this.category = ColumnDescription.PHRASE_STRUCTURE_EDGE_LABEL;
		} else if (category.toUpperCase().equals("PHRASE_STRUCTURE_NODE_LABEL")) {
			this.category = ColumnDescription.PHRASE_STRUCTURE_NODE_LABEL;
		} else if (category.toUpperCase().equals("SECONDARY_EDGE_LABEL")) {
			this.category = ColumnDescription.SECONDARY_EDGE_LABEL;
		} else {
			throw new DataFormatException("The category '"+category+"' is not allowed. ");
		}
	}
	
	private void setType(String type) throws MaltChainedException {
		if (type.toUpperCase().equals("STRING")) {
			this.type = ColumnDescription.STRING;
		} else if (type.toUpperCase().equals("INTEGER")) {
			this.type = ColumnDescription.INTEGER;
		} else if (type.toUpperCase().equals("BOOLEAN")) {
			this.type = ColumnDescription.BOOLEAN;
		} else if (type.toUpperCase().equals("ECHO")) {
			this.type = ColumnDescription.ECHO;
			//this.type = ColumnDescription.STRING;
		} else if (type.toUpperCase().equals("IGNORE")) {
			this.type = ColumnDescription.IGNORE;
		} else {
			throw new DataFormatException("The column type '"+type+"' is not allowed. ");
		}	
	}
	
	public void setSymbolTable(SymbolTable symbolTable) {
		if (type == ColumnDescription.STRING) {
			this.symbolTable = symbolTable;
		}
	}

	public void setDefaultOutput(String defaultOutput) {
		this.defaultOutput = defaultOutput;
	}
	
	public int compareTo(ColumnDescription that) {
		final int BEFORE = -1;
	    final int EQUAL = 0;
	    final int AFTER = 1;
	    if (this == that) return EQUAL;
	    if (this.position < that.position) return BEFORE;
	    if (this.position > that.position) return AFTER;
	    return EQUAL;
	}

	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		ColumnDescription objC = (ColumnDescription)obj;
		return type == objC.type && category == objC.category &&((name == null) ? objC.name == null : name.equals(objC.name));
	}

	public int hashCode() {
		if (cachedHash == 0) {
			int hash = 31*7 + type;
			hash = 31*hash + category;
			hash = 31*hash + (null == name ? 0 : name.hashCode());
			cachedHash = hash;
		}
		return cachedHash;
	}


	public String toString() {
		final StringBuilder sb = new StringBuilder();
		sb.append(name);
		sb.append('\t');
		sb.append(category);
		sb.append('\t');
		sb.append(type);
		if (defaultOutput != null) {
			sb.append('\t');
			sb.append(defaultOutput);
		}
		return sb.toString();
	}
}
