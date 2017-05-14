#! /usr/local/bin/python -tO
# from __future__ import nested_scopes as _nested_scopes

from spark import GenericParser
import types
from random import randrange
from operator import __add__
from random import random, choice, randrange

class RHS:

    def __init__(self, probs, rhs, default, fname):
        try:
            if len(probs) > 2:
                raise SystemExit, "To many prio-params in method %s" % fname
            elif len(probs) == 2:
                prob, fact = [ float(x) for x in probs]
            elif len(probs) == 1:
                prob, fact = float(probs[0]), default
            else:
                prob, fact = 1.0, default
        except ValueError:
            raise SystemExit, "Non floating-point convertable prios in %s" % fname
        self.start_prob = prob
        self.prob_fact = fact
        self.rhs = rhs.split()

class Generator:

    _EOL = "=::"
    default_empty_prio_factor = 0.8

    def __init__(self, parser, start, default_prio_factor=None):
        # Initialise attributes
        if default_prio_factor == None:
            self.default_factor = Generator.default_empty_prio_factor
        else:
            self.default_factor = float(default_prio_factor)
        self.start = start
        # Parse and modfiy the doc-strings of "p_"-methods
        self.rules = self.extract_prio_rules(parser)

    def extract_prio_rules(self, parser):
        D = parser.__class__.__dict__
        rule_funcs = [x for x in D.keys() if x[:2] == "p_" and \
                      type(D[x]) == types.FunctionType]
        rules = {}
        for fname in rule_funcs:
            rule_lines = []
            for lhs, rhs in self.split_lines(D[fname].__doc__):
                # Extract the prio string
                l = rhs.split(Generator._EOL)
                if len(l) > 2:
                    raise SystemExit, \
                          "To many '%s'-symbols in method %s" % (Generator._EOL, fname)
                elif len(l) == 2:
                    rhs, prio = l
                else:
                    rhs, prio = l[0], ""
                # Save doc part without prio string
                rule_lines.append((lhs, rhs))
                # Get parsed, formated and initialised rule elements
                O = RHS(prio.split(), rhs, self.default_factor, fname)
                # Add result to rules
                if not rules.has_key(lhs):
                    rules[lhs] = [[], []]
                rules[lhs][0].append(O.start_prob)
                rules[lhs][1].append(O)
            # Delete prio part from "p_"-method doc strings
            D[fname].__doc__ = self.join_lines(rule_lines)
        return rules

    def split_lines(self, doc_string):
        l = doc_string.split("::=")
        L = [l[0]]
        for s in l[1:-1]:
            parts = s.split()
            L += [" ".join(parts[:-1]), parts[-1]]
        L += [" ".join(l[-1].split())]
        return [ (L[i].strip(), L[i+1]) for i in range(0, len(L), 2)]
        
    def join_lines(self, rule_pairs):
        return "\n".join(["%s ::= %s" % (lhs, rhs) for lhs, rhs in rule_pairs])
        
    def prio_choice(self, lhs):
        prio_list, L = self.rules[lhs]
        val = random() * reduce(__add__, prio_list)
        s = 0.0
        for i in range(len(prio_list)):
            s += prio_list[i]
            if val <= s:
                break
        prio_list[i] *= L[i].prob_fact
        return L[i].rhs

    def reset_prio(self):
        for key in self.rules.keys():
            prio_list, L = self.rules[key]
            for i in range(len(prio_list)):
                prio_list[i] = L[i].start_prob

    def old_generate(self): # Slow!
        "Returns a list of token types"
        so_far = [self.start]
        while 1:
            print len(so_far), ":",
            to_do = [i for i in range(len(so_far)) if self.rules.has_key(so_far[i])]
            print len(to_do)
            if to_do == []:
                self.reset_prio()
                return so_far
            pos = choice(to_do)
            so_far = so_far[:pos] + self.prio_choice(so_far[pos]) + so_far[pos + 1:]

    def generate(self):
        "Returns a list of token types"
        so_far = [self.start]
        to_do = [0]
        has_key = self.rules.has_key
        prio_choice = self.prio_choice
        while to_do:
            #print len(so_far), ":", # VALO
            #print len(to_do)        # VALO
            index = randrange(len(to_do))
            pos = to_do[index]
            so_far_mid = prio_choice(so_far[pos])
            len_mid_1 = len(so_far_mid) - 1
            for i in range(index + 1, len(to_do)):
                to_do[i] += len_mid_1
            to_do[index:index + 1] = [i + pos for i in range(len(so_far_mid)) \
                                      if has_key(so_far_mid[i])]
            so_far[pos:pos + 1] = so_far_mid
        self.reset_prio()
        return so_far


class GenericGeneratorParser(GenericParser):

    def __init__(self, start, default_prio_factor=None):
        self._generator = Generator(self, start, default_prio_factor)
        GenericParser.__init__(self, start)

    def generate(self, token_dict=None):
        "token_dict maps terminal strings onto lists containing of tokens"
        L = self._generator.generate()
        if token_dict == None:
            return L
        else:
            l = []
            for s in L:
                if token_dict.has_key(s):
                    l.append(choice(token_dict[s]))
                else:
                    l.append(s)
            return l


if __name__ == "__main__":
    p = GenericGeneratorParser("expr")
    db = {"number":[str(n) + "L" for n in range(256)],
          "+":["+"],
          "*":["*"],
          "(":["("],
          ")":[")"]}
    for i in range(1):
        s = "".join(p.generate(db))
        print s, "=", eval(s)
