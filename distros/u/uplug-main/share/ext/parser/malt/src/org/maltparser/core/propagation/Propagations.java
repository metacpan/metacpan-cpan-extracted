package org.maltparser.core.propagation;

import java.util.ArrayList;

import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.propagation.spec.PropagationSpec;
import org.maltparser.core.propagation.spec.PropagationSpecs;
import org.maltparser.core.symbol.SymbolTableHandler;
import org.maltparser.core.syntaxgraph.edge.Edge;

public class Propagations {
	private ArrayList<Propagation> propagations;
	private SymbolTableHandler symbolTables;
	
	public Propagations(PropagationSpecs specs, SymbolTableHandler symbolTables) throws MaltChainedException {
		setSymbolTables(symbolTables);
		propagations = new ArrayList<Propagation>(specs.size());
		for (PropagationSpec spec : specs) {
			propagations.add(new Propagation(spec, symbolTables));
		}
	}

	public void propagate(Edge e) throws MaltChainedException {
		for (Propagation propagation : propagations) {
			propagation.propagate(e);
		}
	}
	
	public SymbolTableHandler getSymbolTables() {
		return symbolTables;
	}

	public void setSymbolTables(SymbolTableHandler symbolTables) {
		this.symbolTables = symbolTables;
	}

	public ArrayList<Propagation> getPropagations() {
		return propagations;
	}

	@Override
	public String toString() {
		return "Propagations [propagations=" + propagations + "]";
	}
	
	
}
