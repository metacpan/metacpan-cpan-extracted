package org.maltparser.core.symbol.trie;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.util.Set;
import java.util.SortedMap;
import java.util.TreeMap;

import org.apache.log4j.Logger;
import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.io.dataformat.ColumnDescription;
import org.maltparser.core.symbol.SymbolException;
import org.maltparser.core.symbol.SymbolTable;
import org.maltparser.core.symbol.nullvalue.InputNullValues;
import org.maltparser.core.symbol.nullvalue.NullValues;
import org.maltparser.core.symbol.nullvalue.OutputNullValues;
import org.maltparser.core.symbol.nullvalue.NullValues.NullValueId;
/**

@author Johan Hall
@since 1.0
*/
public class TrieSymbolTable implements SymbolTable {
	private final String name;
	private final Trie trie;
	private final SortedMap<Integer, TrieNode> codeTable;
	private int columnCategory;
	private NullValues nullValues;
	private int valueCounter;
    /** Cache the hash code for the symbol table */
    private int cachedHash;
    
	public TrieSymbolTable(String name, Trie trie, int columnCategory, String nullValueStrategy) throws MaltChainedException {
		this.name = name;
		this.trie = trie;
		this.columnCategory = columnCategory;
		codeTable = new TreeMap<Integer, TrieNode>();
		if (columnCategory == ColumnDescription.INPUT) {
			nullValues = new InputNullValues(nullValueStrategy, this);
		} else if (columnCategory == ColumnDescription.DEPENDENCY_EDGE_LABEL) {
			nullValues = new OutputNullValues(nullValueStrategy, this, null);
		} else {
			nullValues = new InputNullValues(nullValueStrategy, this);
		}
		valueCounter = nullValues.getNextCode();
	}

	public TrieSymbolTable(String name,  Trie trie, int columnCategory, String nullValueStrategy, String rootLabel) throws MaltChainedException {
		this.name = name;
		this.trie = trie;
		this.columnCategory = columnCategory;
		codeTable = new TreeMap<Integer, TrieNode>();
		if (columnCategory == ColumnDescription.INPUT) {
			nullValues = new InputNullValues(nullValueStrategy, this);
		} else if (columnCategory == ColumnDescription.DEPENDENCY_EDGE_LABEL) {
			nullValues = new OutputNullValues(nullValueStrategy, this, rootLabel);
		}
		valueCounter = nullValues.getNextCode();
	}
	
	public TrieSymbolTable(String name, Trie trie) {
		this.name = name;
		this.trie = trie;
		codeTable = new TreeMap<Integer, TrieNode>();
		nullValues = new InputNullValues("one", this);
		//nullValues = null;
		valueCounter = 1;
	}
	
	public int addSymbol(String symbol) throws MaltChainedException {
		if (nullValues == null || !nullValues.isNullValue(symbol)) {
			final TrieNode node = trie.addValue(symbol, this, -1);
			final int code = node.getEntry(this).getCode();
			if (!codeTable.containsKey(code)) {
				codeTable.put(code, node);
			}
			return code;
		} else {
			return nullValues.symbolToCode(symbol);
		}
	}
	
	public int addSymbol(StringBuilder symbol) throws MaltChainedException {
		if (nullValues == null || !nullValues.isNullValue(symbol)) {
			final TrieNode node = trie.addValue(symbol, this, -1);
			final int code = node.getEntry(this).getCode();
			if (!codeTable.containsKey(code)) {
				codeTable.put(code, node);
			}
			return code;
		} else {
			return nullValues.symbolToCode(symbol);
		}
	}
	
	public String getSymbolCodeToString(int code) throws MaltChainedException {
		if (code >= 0) {
			if (nullValues == null || !nullValues.isNullValue(code)) {
				if (trie == null) {
					throw new SymbolException("The symbol table is corrupt. ");
				}
				return trie.getValue(codeTable.get(code), this);
			} else {
				return nullValues.codeToSymbol(code);
			}
		} else {
			throw new SymbolException("The symbol code '"+code+"' cannot be found in the symbol table. ");
		}
	}
	
	public int getSymbolStringToCode(String symbol) throws MaltChainedException {
		if (symbol != null) {
			if (nullValues == null || !nullValues.isNullValue(symbol)) {
				if (trie == null) {
					throw new SymbolException("The symbol table is corrupt. ");
				} 
				final TrieEntry entry = trie.getEntry(symbol, this);
				if (entry == null) {
					throw new SymbolException("Could not find the symbol '"+symbol+"' in the symbol table. ");
				}
				return entry.getCode();				
			} else {
				return nullValues.symbolToCode(symbol);
			}
		} else {
			throw new SymbolException("The symbol code '"+symbol+"' cannot be found in the symbol table. ");
		}
	}

	public String getNullValueStrategy() {
		if (nullValues == null) {
			return null;
		}
		return nullValues.getNullValueStrategy();
	}
	
	
	public int getColumnCategory() {
		return columnCategory;
	}

	public boolean getKnown(int code) {
		if (code >= 0) {
			if (nullValues == null || !nullValues.isNullValue(code)) {
				return codeTable.get(code).getEntry(this).isKnown();
			} else {
				return true;
			}
		} else {
			return false;
		}
	}

	public boolean getKnown(String symbol) {
		if (nullValues == null || !nullValues.isNullValue(symbol)) {
			final TrieEntry entry = trie.getEntry(symbol, this);
			if (entry == null) {
				return false;
			}
			return entry.isKnown();
		} else {
			return true;
		}
	}
	
	public void makeKnown(int code) {
		if (code >= 0) {
			if (nullValues == null || !nullValues.isNullValue(code)) {
				codeTable.get(code).getEntry(this).setKnown(true);
			} 
		}
	}
	
	public void printSymbolTable(Logger logger) throws MaltChainedException {
		for (Integer code : codeTable.keySet()) {
			logger.info(code+"\t"+trie.getValue(codeTable.get(code), this)+"\n");
		}
	}
	
	public void saveHeader(BufferedWriter out) throws MaltChainedException  {
		try {
			out.append('\t');
			out.append(getName());
			out.append('\t');
			out.append(Integer.toString(getColumnCategory()));
			out.append('\t');
			out.append(getNullValueStrategy());
			out.append('\t');
			if (nullValues instanceof OutputNullValues && ((OutputNullValues)nullValues).getRootLabel() != null) {
				out.append(((OutputNullValues)nullValues).getRootLabel());
			} else {
				out.append("#DUMMY#");
			}
			out.append('\n');
		} catch (IOException e) {
			throw new SymbolException("Could not save the symbol table. ", e);
		}
	}
	
	public int size() {
		return codeTable.size();
	}
	
	public void save(BufferedWriter out) throws MaltChainedException  {
		try {
			out.write(name);
			out.write('\n');
			for (Integer code : codeTable.keySet()) {
				out.write(code+"");
				out.write('\t');
				out.write(trie.getValue(codeTable.get(code), this));
				out.write('\n');
			}
			out.write('\n');
		} catch (IOException e) {
			throw new SymbolException("Could not save the symbol table. ", e);
		}
	}
	
	public void load(BufferedReader in) throws MaltChainedException {
		int max = 0;
		int index = 0;
		String fileLine;
		try {
			while ((fileLine = in.readLine()) != null) {
				if (fileLine.length() == 0 || (index = fileLine.indexOf('\t')) == -1) {
					setValueCounter(max+1);
					break;
				}
				int code = Integer.parseInt(fileLine.substring(0,index));
				final String str = fileLine.substring(index+1);
				final TrieNode node = trie.addValue(str, this, code);
				codeTable.put(node.getEntry(this).getCode(), node);
				if (max < code) {
					max = code;
				}
			}
		} catch (NumberFormatException e) {
			throw new SymbolException("The symbol table file (.sym) contains a non-integer value in the first column. ", e);
		} catch (IOException e) {
			throw new SymbolException("Could not load the symbol table. ", e);
		}
	}
	
	public String getName() {
		return name;
	}

	public int getValueCounter() {
		return valueCounter;
	}

	private void setValueCounter(int valueCounter) {
		this.valueCounter = valueCounter;
	}
	
	protected void updateValueCounter(int code) {
		if (code > valueCounter) {
			valueCounter = code;
		}
	}
	
	protected int increaseValueCounter() {
		return valueCounter++;
	}
	
	public int getNullValueCode(NullValueId nullValueIdentifier) throws MaltChainedException {
		if (nullValues == null) {
			throw new SymbolException("The symbol table does not have any null-values. ");
		}
		return nullValues.nullvalueToCode(nullValueIdentifier);
	}
	
	public String getNullValueSymbol(NullValueId nullValueIdentifier) throws MaltChainedException {
		if (nullValues == null) {
			throw new SymbolException("The symbol table does not have any null-values. ");
		}
		return nullValues.nullvalueToSymbol(nullValueIdentifier);
	}
	
	public boolean isNullValue(String symbol) throws MaltChainedException {
		if (nullValues != null) {
			return nullValues.isNullValue(symbol);
		} 
		return false;
	}
	
	public boolean isNullValue(int code) throws MaltChainedException {
		if (nullValues != null) {
			return nullValues.isNullValue(code);
		} 
		return false;
	}
	
	public void copy(SymbolTable fromTable) throws MaltChainedException {
		final SortedMap<Integer, TrieNode> fromCodeTable =  ((TrieSymbolTable)fromTable).getCodeTable();
		int max = getValueCounter()-1;
		for (Integer code : fromCodeTable.keySet()) {
			final String str = trie.getValue(fromCodeTable.get(code), this);
			final TrieNode node = trie.addValue(str, this, code);
			codeTable.put(node.getEntry(this).getCode(), node);
			if (max < code) {
				max = code;
			}
		}
		setValueCounter(max+1);
	}

	public SortedMap<Integer, TrieNode> getCodeTable() {
		return codeTable;
	}
	
	public Set<Integer> getCodes() {
		return codeTable.keySet();
	}
	
	protected Trie getTrie() {
		return trie;
	}
	
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		return ((name == null) ? ((TrieSymbolTable)obj).name == null : name.equals(((TrieSymbolTable)obj).name));
	}

	public int hashCode() {
		if (cachedHash == 0) {
			cachedHash = 31 * 7 + (null == name ? 0 : name.hashCode());
		}
		return cachedHash;
	}
	
	public String toString() {
		final StringBuilder sb = new StringBuilder();
		sb.append(name);
		sb.append(" ");
		sb.append(valueCounter);
		return sb.toString();
	}
}
