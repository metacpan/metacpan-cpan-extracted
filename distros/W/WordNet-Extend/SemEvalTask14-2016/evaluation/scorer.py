from nltk.corpus import wordnet as wn
import sys

def wup_sim(syn1, other, height_correction):
    need_root = syn1.pos() == wn.VERB
    subsumers = syn1.lowest_common_hypernyms( \
                other, need_root, use_min_depth=True)

    subsumer = subsumers[0]

    # Get the longest path from the LCS to the root,
    # including a correction:
    # - add one because the calculations include both the start and end
    #   nodes
    depth = subsumer.max_depth() + 1

    # Get the shortest path from the LCS to each of the synsets it is
    # subsuming.  Add this to the LCS path length to get the path
    # length from each synset to the root.
    len1 = syn1.shortest_path_distance(subsumer, need_root)
    len2 = other.shortest_path_distance(subsumer, need_root)

    # When the system's answer file differs in the operation (e.g., says attach
    # instead of merge), then the height correction is 1, indicating the
    # effective-depth of the synset differs from its actual location.  
    len1 += depth + height_correction
    len2 += depth

    return (2.0 * depth) / (len1 + len2)


if len(sys.argv) != 3:
    print 'usage: python scorer.py gold.key system.key'
    sys.exit(0)


instance_to_gold_ans = {}
instance_to_sys_ans = {}


with open(sys.argv[1]) as gold_file:
    for line in gold_file:
        cols = line.strip().split('\t')
        inst = cols[0]
        sense = cols[1].replace('#', '.').replace(' ', '_')
        wn.synset(sense)
        op = cols[2]
        instance_to_gold_ans[inst] = (sense, op)

with open(sys.argv[2]) as sys_file:
    for line in sys_file:
        cols = line.strip().split('\t')
        if len(cols) != 3:
            print 'bad line in %s, expected 3 columns, got %d' \
                % (sys.argv[2], len(cols))
            sys.exit(1)
        inst = cols[0]
        sense = cols[1].replace('#', '.').replace(' ', '_')
        op = cols[2]
        instance_to_sys_ans[inst] = (sense, op)


wup_sum = 0.0
lemma_matches = 0
num_items = len(instance_to_gold_ans)
num_answered = 0

for inst, (sense, op) in instance_to_gold_ans.iteritems():
    if inst not in instance_to_sys_ans:
        continue
    num_answered += 1
    sys_sense, sys_op = instance_to_sys_ans[inst]

    gold_wn_synset = wn.synset(sense)
    system_wn_synset = wn.synset(sys_sense)

    gold_lemmas = set(str(lemma.name()) for lemma in gold_wn_synset.lemmas())
    system_lemmas = set(str(lemma.name()) for lemma in system_wn_synset.lemmas())

    # Eval 1: is the system identify the right lemma (regardless of operation
    # and sense) on which this operation should be performed
    for lemma in gold_lemmas:
        if lemma in system_lemmas:
            lemma_matches += 1
            break

    # Eval 2: how similar is the attachment point for this synset
    correction = 0
    if op[0] != sys_op[0]:
        correction = 1
        
    sim = wup_sim(gold_wn_synset, system_wn_synset, correction)
    wup_sum += sim

recall = num_answered / float(num_items)
lemma_acc = 0
wup_acc = 0
if num_answered > 0:
    lemma_acc = lemma_matches / float(num_answered)
    wup_acc = wup_sum / float(num_answered)

print ("Results for %s\nMean Wu&Palmer: %f\n" + \
    "Mean Lemma-match: %f\nRecall: %f") % \
    (sys.argv[2], wup_acc, lemma_acc, recall)
