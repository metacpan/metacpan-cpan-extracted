package org.maltparser.parser.algorithm.stack;

import java.util.ArrayList;
import java.util.Stack;

import org.maltparser.core.exception.MaltChainedException;
import org.maltparser.core.syntaxgraph.DependencyStructure;
import org.maltparser.core.syntaxgraph.node.DependencyNode;
import org.maltparser.parser.DependencyParserConfig;
import org.maltparser.parser.Oracle;
import org.maltparser.parser.ParserConfiguration;
import org.maltparser.parser.history.GuideUserHistory;
import org.maltparser.parser.history.action.GuideUserAction;
/**
 * @author Johan Hall
 *
 */
public class SwapLazyOracle extends Oracle {
	private ArrayList<Integer> swapArray;
	private boolean swapArrayActive = false;
	
	public SwapLazyOracle(DependencyParserConfig manager, GuideUserHistory history) throws MaltChainedException {
		super(manager, history);
		setGuideName("swaplazy");
		swapArray = new ArrayList<Integer>();
	}
	
	public GuideUserAction predict(DependencyStructure gold, ParserConfiguration configuration) throws MaltChainedException {
		StackConfig config = (StackConfig)configuration;
		Stack<DependencyNode> stack = config.getStack();

		if (!swapArrayActive) {
			createSwapArray(gold);
			swapArrayActive = true;
		}
		if (stack.size() < 2) {
			return updateActionContainers(NonProjective.SHIFT, null);
		} else {
			DependencyNode left = stack.get(stack.size()-2);
			DependencyNode right = stack.get(stack.size()-1);
			int leftIndex = left.getIndex();
			int rightIndex = right.getIndex();
			if (swapArray.get(leftIndex) > swapArray.get(rightIndex) && necessarySwap(gold, config.getDependencyGraph(), right, config.getInput())) {
				return updateActionContainers(NonProjective.SWAP, null);
			} else if (!left.isRoot() && gold.getTokenNode(leftIndex).getHead().getIndex() == rightIndex 
					&& nodeComplete(gold, config.getDependencyGraph(), leftIndex)) {
				return updateActionContainers(NonProjective.LEFTARC, gold.getTokenNode(leftIndex).getHeadEdge().getLabelSet());
			} else if (gold.getTokenNode(rightIndex).getHead().getIndex() == leftIndex 
					&& nodeComplete(gold, config.getDependencyGraph(), rightIndex)) {
				return updateActionContainers(NonProjective.RIGHTARC, gold.getTokenNode(rightIndex).getHeadEdge().getLabelSet());
			} else {
				return updateActionContainers(NonProjective.SHIFT, null);
			}
		}
	}
	
	private boolean nodeComplete(DependencyStructure gold, DependencyStructure parseDependencyGraph, int nodeIndex) {
		if (gold.getTokenNode(nodeIndex).hasLeftDependent()) {
			if (!parseDependencyGraph.getTokenNode(nodeIndex).hasLeftDependent()) {
				return false;
			} else if (gold.getTokenNode(nodeIndex).getLeftmostDependent().getIndex() != parseDependencyGraph.getTokenNode(nodeIndex).getLeftmostDependent().getIndex()) {
				return false;
			}
		}
		if (gold.getTokenNode(nodeIndex).hasRightDependent()) {
			if (!parseDependencyGraph.getTokenNode(nodeIndex).hasRightDependent()) {
				return false;
			} else if (gold.getTokenNode(nodeIndex).getRightmostDependent().getIndex() != parseDependencyGraph.getTokenNode(nodeIndex).getRightmostDependent().getIndex()) {
				return false;
			}
		}
		return true;
	}
	
	private boolean necessarySwap(DependencyStructure gold, DependencyStructure parse, DependencyNode node, Stack<DependencyNode> input) throws MaltChainedException {
		DependencyNode left = node;
		int index = input.size() - 1;
		if (index < 0) {
			return true;
		}
		DependencyNode right = input.peek();
		
		int rc = -1;
		while (projectiveInterval(parse, left, right)) {
			if (rc == right.getIndex()) {
				return false;
			}
			if (gold.getDependencyNode(node.getIndex()).getHead().getIndex() == right.getIndex()) {
				return !leftComplete(gold, node);
			}
			if (gold.getDependencyNode(right.getIndex()).getHead().getIndex() == node.getIndex()) {
				if (gold.getDependencyNode(right.getIndex()).hasRightDependent()) {
					  rc = gold.getDependencyNode(right.getIndex()).getRightmostProperDescendantIndex();
				}
				else {
				  return false;
				} 
			}
			if (index > 0) {
				left = right;
				right = input.get(--index);
			} else {
				break;
			}
		}
		
		return true;
	}
	
	private boolean projectiveInterval(DependencyStructure parse, DependencyNode left, DependencyNode right) throws MaltChainedException {
		int l = swapArray.get(left.getIndex());
		int r = swapArray.get(right.getIndex());
		DependencyNode node = null;
		if (l > r) {
			return false;
		} else {
			for (int i = l + 1; i < r; i++) {
				for (int j = 0; j < swapArray.size(); j++) {
					if (swapArray.get(j) == i) {
						node = parse.getDependencyNode(j);
						break;
					}
				}
				while (node.hasHead()) {
					node = node.getHead();
				}
				if (!(node == left || node == right)) {
					return false; 
				}
			}
			return true;
		}
	}
	
	private boolean leftComplete(DependencyStructure gold, DependencyNode right) throws MaltChainedException {
		if (!gold.getDependencyNode(right.getIndex()).hasLeftDependent()) {
			return true;
		} else if (!right.hasLeftDependent()) {
			return false;
		} else if (gold.getDependencyNode(right.getIndex()).getLeftmostDependent().getIndex() == right.getLeftmostDependent().getIndex()) {
			return true;
		}
		return false;
	}
	
	public void finalizeSentence(DependencyStructure dependencyGraph) throws MaltChainedException {
		swapArrayActive = false;
	}
	
	public void terminate() throws MaltChainedException {
		
	}
	
	private void createSwapArray(DependencyStructure goldDependencyGraph) throws MaltChainedException {
		swapArray.clear();
		for (int i = 0; i <= goldDependencyGraph.getHighestDependencyNodeIndex(); i++) {
			swapArray.add(new Integer(i));
		}
		createSwapArray(goldDependencyGraph.getDependencyRoot(), 0);
	}
	
	private int createSwapArray(DependencyNode n, int order) {
		int o = order; 
		if (n != null) {
			for (int i=0; i < n.getLeftDependentCount(); i++) {
				o = createSwapArray(n.getLeftDependent(i), o);
			}
			swapArray.set(n.getIndex(), o++);
			for (int i=n.getRightDependentCount(); i >= 0; i--) {
				o = createSwapArray(n.getRightDependent(i), o);
			}
		}
		return o;
	}
}
