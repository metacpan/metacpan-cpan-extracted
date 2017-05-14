# -*- coding: ISO-8859-1 -*-
#
#  Beata Megyesi
#  bea@speech.kth.se
#  Centre for Speech Technology, 
#  KTH, Stockholm, Sweden
#
#  Copyright (c) Beata Megyesi
#  
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this program and associated documentation files to deal in 
#  the program including the rights to use, modify, 
#  and merge of the program, and to permit persons to whom the program is 
#  furnished to do so, subject to the following conditions:
#  
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the program.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


from string import split, join
from sys import stdin, stderr, exit
from sys import argv
from spark import GenericScanner, _namelist
from tokenastdot import AST as genericAST
from sparkgen import GenericGeneratorParser as GenericParser
from popen2 import popen2

# -----------------------------------------------------------------
#
# Token class
#

class Token:
	def __init__(self, type, attr=None):
		self.type = type
		self.attr = attr

	def __cmp__(self, o):
		return cmp(self.type, o)

	def __str__(self): # Added for Bea's parser
		res = self.type
		if self.attr:
			res = res + " = " + self.attr[0] + "/" + self.attr[1]


# -----------------------------------------------------------------
#
# AST (Abstract Syntax Tree) class
#

class AST(genericAST):

	def __init__(self, type, kids=None):
		genericAST.__init__(self, type, kids)
		

	def label(self): # Override this method to get specific labels
		return buildLabel(self.type, self.attr)
		if self.attr:
			return r"%s:\n%s" % (self.type.upper(), self.attr[0])
		else:
			return "%s" % self.type
	

# -----------------------------------------------------------------

#
#	SCANNING
#

def word_tag(s):
    l = split(s, "/")
    word = join(l[:-1], "/")
    tag = l[-1]
    return (word,tag)


class GeneralScanner(GenericScanner):
    def __init__(self):
        GenericScanner.__init__(self)
    
    def tokenize(self, input):
        self.rv = []
        GenericScanner.tokenize(self, input)
        return self.rv

    def t_White(self, s):
        r" \s+ "
        pass

    def t_Det(self,s):
        r" \S+ / D...... "
        self.rv.append(Token(type="det", attr=word_tag(s)))
        
    def t_NGen(self,s):
        r" \S+ / NC..G@.S "
        self.rv.append(Token(type="n_gen", attr=word_tag(s)))
        
    def t_PropNGen(self,s):
        r" \S+ / NP00G@0S "
        self.rv.append(Token(type="prop_n_gen", attr=word_tag(s)))
        
    def t_Adv(self,s):
        r" \S+ / R... "
        self.rv.append(Token(type="adv", attr=word_tag(s)))
        
    def t_Konj(self,s):
        r" \S+ / CC. "
        self.rv.append(Token(type="konj", attr=word_tag(s)))
        
    def t_Subj(self,s):
        r" \S+ / CSS "
        self.rv.append(Token(type="subj", attr=word_tag(s)))
        
    def t_Prep(self,s):
        r" \S+ / SP. "
        self.rv.append(Token(type="prep", attr=word_tag(s)))
        
    def t_AdjSing(self,s): #to handle agreement in MaxAP
        r" \S+ / A...S... "
        self.rv.append(Token(type="adj_sing", attr=word_tag(s)))
       
    def t_AdjPlur(self,s): #to handle agreement in MaxAP
        r" \S+ / A...P... "
        self.rv.append(Token(type="adj_plur", attr=word_tag(s)))
       
    def t_AdjSingPlur(self,s): #to handle agreement in MaxAP
        r" \S+ / A...0... "
        self.rv.append(Token(type="adj_sing_plur", attr=word_tag(s)))
       
    def t_Num(self,s):
        r" \S+ / M...... "
        self.rv.append(Token(type="num", attr=word_tag(s)))
        
    def t_Pron(self,s):
        r" \S+ / P[FEHI]...... "
        self.rv.append(Token(type="pron", attr=word_tag(s)))
        
    def t_PossPron(self,s):
        r" \S+ / PS...... "
        self.rv.append(Token(type="poss_pron", attr=word_tag(s)))
        
    def t_CompNoun(self,s):
        r" \S+ - / ( NC...@.C | V@000C )"
        self.rv.append(Token(type="comp_noun", attr=word_tag(s)))
        
    def t_PropCompNoun(self,s):
        r" \S+ - / NP000@0C "
        self.rv.append(Token(type="prop_comp_noun", attr=word_tag(s)))
        
    def t_PropNoun(self,s):
        r" \S+ / NP00N@.S "
        self.rv.append(Token(type="prop_noun", attr=word_tag(s)))
        
    def t_ComNoun(self,s):
        r" \S+ / NC..[N0]@.[SA] "
        self.rv.append(Token(type="com_noun", attr=word_tag(s)))
        
    def t_Inf(self,s):
        r" \S+ / CIS"
        self.rv.append(Token(type="inf", attr=word_tag(s)))
      
    def t_InfVerb(self,s):
        r" \S+ / V@N... "
        self.rv.append(Token(type="inf_verb", attr=word_tag(s)))
        
    def t_Part(self,s):
        r" \S+ / QS "
        self.rv.append(Token(type="part", attr=word_tag(s)))
        
    def t_FinVerb(self,s):
        r" \S+ / V@I[IP].. "
        self.rv.append(Token(type="fin_verb", attr=word_tag(s)))
        
    def t_SupVerb(self,s):
        r" \S+ / V@IU.. "
        self.rv.append(Token(type="sup_verb", attr=word_tag(s)))
        
    def t_ImpVerb(self,s):
        r" \S+ / ( V@M... | V@000A )"
        self.rv.append(Token(type="imp_verb", attr=word_tag(s)))
        
    def t_ConjVerb(self,s):
        r" \S+ / V@S... "
        self.rv.append(Token(type="subjnct_verb", attr=word_tag(s)))
        
    def t_DelMin(self,s):
        r" \S+ / FI "
        self.rv.append(Token(type="del_min", attr=word_tag(s)))
        
    def t_DelMaj(self,s):
        r" \S+ / FE "
        self.rv.append(Token(type="del_maj", attr=word_tag(s)))

    def t_DelParen(self,s): # ", (, ), &apos;,
        r" \S+ / FP "
        self.rv.append(Token(type="del_paren", attr=word_tag(s)))
        
    def t_Interj(self,s):
        r" \S+ / I "
        self.rv.append(Token(type="interj", attr=word_tag(s)))
        
    def t_UO(self,s):
        r" \S+ / XF "
        self.rv.append(Token(type="u_o", attr=word_tag(s)))
        
    def t_default(self, s): # Do not accept lexical errors!
        pass

##     # print items that are not defined
##     def t_default(self, s): # Accept and print lexical errors!
##         r" \S+ / [^\s/]+ "
##         word, tag = word_tag(s)
##         stderr.write(word + "/" + tag + "\n")
##         self.rv.append(Token(type="default", attr=(word, tag)))


        
class SpecialScanner(GeneralScanner):
    def __init__(self):
        GeneralScanner.__init__(self)
        
    def t_SentAdv(self,s):
        r" [aA]ldrig/R...|[aA]lltid/R...|[aA]lltså/R...|[bB]ara/R...|[dD]it/R...|[dD]ock/R...|[dD]ärför/R...|[fF]aktiskt/R...|[gG]enast/R...|[gG]ivetvis/R...|[hH]eller/R...|[hH]it/R...|[hH]ittills/R...|[hH]ur/R...|[iI]från/R...|[iI]nte/R...|[jJ]u/R...|[kK]anske/R...|[nN]aturligtvis/R...|[nN]u/R...|[nN]og/R...|[nN]ämligen/R...|[nN]är/R...|[nN]ödvändigtvis/R...|[oO]ckså/R...|[oO]fta/R...|[pP]lötsligt/R...|[sS]äkert/R...|[uU]pp/R...|[vV]ad/R...|[vV]arför/R...|[vV]isserligen/R...|[äÄ]ndå/R...|[äÄ]ven/R... "
        self.rv.append(Token(type="sent_adv", attr=word_tag(s)))

    def t_HereThere(self,s):
        r" [HhDd]är/RG0S "
        self.rv.append(Token(type="here_there", attr=word_tag(s)))
        
    def t_PrepMellan(self,s):
        r" [Mm]ellan/SPS "
        self.rv.append(Token(type="prep_mellan", attr=word_tag(s)))
        
    def t_RelPron(self,s): #added by bohag
        r" \S+/PH@000@S|vilket/PH@NS0@S|vilken/PH@US0@S|vilka/PH@0P0@S|vars/PE@000@S|vilkas/PE@000@S "
        self.rv.append(Token(type="rel_pron", attr=word_tag(s)))

    def t_RelAdv(self,s):  #added by bohag
	r" där/RH0S "
	self.rv.append(Token(type="rel_adv", attr=word_tag(s)))


##     def t_Particip(self,s):
##         r" \S+ / A[FP]...... "
##         self.rv.append(Token(type="particip", attr=word_tag(s)))
        

def scan(input):
    scanner = SpecialScanner()
    return scanner.tokenize(input)

#
#	PARSING
#

class PhraseParser(GenericParser):
    def __init__(self, start='SENT', print_ambigous=0):
        GenericParser.__init__(self, start)
        self.print_ambigous = print_ambigous

    def resolve(self, list): # Handle ambiguities, or eg. print them (se documentation)
        if self.print_ambigous:
            stderr.write("Ambigous:" + `list` + "\n")
        prio_list = []
        for w in list:
            try:
                prio = int(split(w, "_")[-1])
            except ValueError:
                raise SystemExit, "The rule: %s does not contain a priority" % ("p_" + w)
            prio_list.append((prio, w))
        return max(prio_list)[1]

    def typestring(self, token): # Increases efficiency, see documentation!
        return token.type

    def error(self, token): # Overides method in GenericParser
        raise SystemExit, "Syntax error at or near `%s' token" % token

# -------------------------------------------------------- 
# ------------------------ RULES ------------------------- 
# -------------------------------------------------------- 

    def p_sent_0(self, args):
        '''
        SENT ::= PHRASE_S PHRASE
        '''
        return AST(type=Token(type="sent"), kids=args[0]._kids + [args[1]])


# ---------------------- STAR RULES ---------------------- 

    def p_S_base1_20(self, args):
        '''
        ADVP_S ::=
        SADVP_S ::=
        INFVERB_S ::=
        APMINSING_S ::=
        APMINPLUR_S ::=
        APMINSINGCONT_S ::=
        APMINPLURCONT_S ::=
        AP_S ::=
        NUM_S ::=
        PROPCOMPNOUNCONT_S ::=
        COMPNOUNCONT_S ::=
        PROPNOUN_S ::=
        COMPNOUN_S ::=
        COMNOUN_S ::=
        NUM_S ::=
        NP_S ::=
        PP_S ::=
        '''
        return AST(type=Token(type="star"), kids=[])

    def p_S_base2_10(self, args):
        '''
        PHRASE_S ::=
	EK_S ::=
        '''
        return AST(type=Token(type="star"), kids=[])


    def p_S_term_30(self, args):
        '''
        SADVP_S ::= sent_adv SADVP_S
        INFVERB_S ::= inf_verb INFVERB_S
        NUM_S ::= num NUM_S
        PROPNOUN_S ::= prop_noun PROPNOUN_S
        COMPNOUN_S ::= comp_noun COMPNOUN_S
        COMNOUN_S ::= com_noun COMNOUN_S
        '''
        return AST(type=Token(type="star"), kids=[AST(type=args[0])] + args[1]._kids)

    def p_S_nonterm_30(self, args):
        '''
        ADVP_S ::= ADVP ADVP_S
        APMINSINGCONT_S ::= APMINSINGCONT_L APMINSINGCONT_S
        APMINPLURCONT_S ::= APMINPLURCONT_L APMINPLURCONT_S
        AP_S ::= AP AP_S
        PROPCOMPNOUNCONT_S ::= PROPCOMPNOUNCONT_L PROPCOMPNOUNCONT_S
        COMPNOUNCONT_S ::= COMPNOUNCONT_L COMPNOUNCONT_S
        NUM_S ::= NUMP NUM_S
        NP_S ::= NP NP_S
        PP_S ::= PP PP_S
        '''
        return AST(type=Token(type="star"), kids=[args[0]] + args[1]._kids)

    def p_S_nonterm1_30(self, args):
        '''
        APMINSING_S ::= APMINSING_L APMINSING_S
        '''
        return AST(type=Token(type="star"), kids=[args[0]] + args[1]._kids)
    
    def p_S_nonterm2_30(self, args):
        '''
        APMINPLUR_S ::= APMINPLUR_L APMINPLUR_S
        '''
        return AST(type=Token(type="star"), kids=[args[0]] + args[1]._kids)

    def p_S_nonterm3_500(self, args):
        '''
        PHRASE_S ::= PHRASE_S PHRASE
        '''
        return AST(type=Token(type="star"), kids=args[0]._kids + [args[1]])

    def p_eks_1_10(self, args): #bohag
        '''
        EK_S ::= EK_S EK
        '''
        return AST(type=Token(type="star"), kids=args[0]._kids + [args[1]])




# ---------------------- OPTIONAL RULES ---------------------- 

    def p_Q_0_20(self, args):
        '''
        DET_Q ::=
        DETPOSSPRON_Q ::=
        ADVP_Q ::=
        PART_Q ::=
        PP_Q ::=
        AP_Q ::=
        KONJ_Q ::=
        DELMIN_Q ::=
        NGEN_Q ::=
        NUM_Q ::=
        HERETHERE_Q ::=
        '''
        return AST(type=Token(type="optional"), kids=[])

    def p_Q_1_term_30(self, args):
        '''
        PART_Q ::= part
        KONJ_Q ::= konj
        DELMIN_Q ::= del_min
        NGEN_Q ::= n_gen
        HERETHERE_Q ::= here_there
        '''
        return AST(type=Token(type="optional"), kids=[AST(type=args[0])])

    def p_Q_1_nonterm_30(self, args):
        '''
        DET_Q ::= DET
        DETPOSSPRON_Q ::= DETPOSSPRON
        ADVP_Q ::= ADVP
        PP_Q ::= PP
        AP_Q ::= AP
        NUM_Q ::= NUMP
        '''
        return AST(type=Token(type="optional"), kids=[args[0]])

    def p_default_10(self, args):
        '''
        PHRASE ::= here_there
        PHRASE ::= particip
        PHRASE ::= prep_mellan
        PHRASE ::= sent_adv
	EK     ::= sent_adv
        PHRASE ::= adj_plur
        PHRASE ::= adj_sing
        PHRASE ::= adj_sing_plur
        PHRASE ::= adv
        PHRASE ::= com_noun
        PHRASE ::= comp_noun
        PHRASE ::= subjnct_verb
        PHRASE ::= del_maj
        PHRASE ::= del_min
        PHRASE ::= del_paren
        PHRASE ::= det
        PHRASE ::= fin_verb
        PHRASE ::= imp_verb
        PHRASE ::= inf
        PHRASE ::= inf_verb
        PHRASE ::= interj
        PHRASE ::= konj
        PHRASE ::= n_gen
        PHRASE ::= num
        PHRASE ::= part
        PHRASE ::= poss_pron
        PHRASE ::= prep
        PHRASE ::= pron
        PHRASE ::= prop_comp_noun
        PHRASE ::= prop_n_gen
        PHRASE ::= prop_noun
        PHRASE ::= subj
        PHRASE ::= sup_verb
        PHRASE ::= u_o
	PHRASE ::= rel_pron
	PHRASE ::= rel_adv
        '''
        return AST(type=args[0])

    def p_phrase_2a_30(self, args):
        '''
        PHRASE ::= DETPOSSPRON
        '''
        return args[0]

    def p_phrase_2a_40(self, args):
        '''
        PHRASE ::= ADVP
	EK     ::= ADVP
        '''
        return args[0]

    def p_phrase_2b_40(self, args):
        '''
        PHRASE ::= VC
        '''
        return args[0]

    def p_phrase_3a_50(self, args):
        '''
        PHRASE ::= AP
	EK     ::= AP
        '''
        return args[0]

    def p_phrase_3b_50(self, args):
        '''
        PHRASE ::= INFP
	EK     ::= INFP
        '''
        return args[0]

    def p_phrase_3c_50(self, args):
        '''
        PHRASE ::= NUMP
	EK     ::= NUMP
        '''
        return args[0]

    def p_phrase_4_60(self, args):
        '''
        PHRASE ::= NP
	EK     ::= NP
        '''
        return args[0]

    def p_phrase_5_70(self, args):
        '''
        PHRASE ::= PP
	EK     ::= PP
        '''
        return args[0]

    def p_phrase_6_80(self, args):
        '''
        PHRASE ::= NPMAX
	EK     ::= NPMAX
        '''
        return args[0]

    def p_phrase_7_10(self, args): #added by bohag phrase::=rp
        '''
        PHRASE ::= RP
        '''
        return args[0]

    def p_phrase_7_11(self, args): #added by bohag phrase::=ra
	'''
	PHRASE ::= RA
	'''
	return args[0]


    def p_phrase_7_20(self, args): #added by bohag phrase::=relcl
        '''
        PHRASE ::= RELCL
        '''
        return args[0]


# ---------------- NON PHRASE RULES ---------------------

    def p_relcl_xx2_10(self, args): #added by bohag relcl::=rp ek_s vc ek_s
        '''
        RELCL ::= RP EK_S VC EK_S
	RELCL ::= RA EK_S VC EK_S
        '''
        return AST(type=Token(type="RELCL"), kids=[args[0]]+args[1]._kids+[args[2]]+args[3]._kids)

    def p_relcl_xx3_10(self, args): #added by bohag relcl::=rp ek_s vc ek_s prep
        '''
        RELCL ::= RP EK_S VC EK_S prep
        '''
        return AST(type=Token(type="RELCL"), kids=[args[0]]+
                args[1]._kids+[args[2]]+args[3]._kids+[AST(type=args[4])])

    def p_relcl_xx4_10(self, args): #added by bohag relcl::=prep rp ek_s vc ek_s
        '''
        RELCL ::= prep RP EK_S VC EK_S
        '''
        return AST(type=Token(type="RELCL"), kids=[AST(type=args[0])]+
                [args[1]]+args[2]._kids + [args[3]] + args[4]._kids)

    def p_rp_xx2_10(self, args): #added by bohag rp::=rel_pron
        '''
        RP ::= rel_pron
        '''
        return AST(type=Token(type="NP"), kids=[AST(type=args[0])])

    def p_ra_xxx_10(self, args): #added by bohag ra::=rel_adv
	'''
	RA ::= rel_adv
	'''
	return AST(type=Token(type="ADVP"), kids=[AST(type=args[0])])


    def p_advp_term_90(self, args):
        '''
        ADVP ::= adv
        ADVP ::= here_there
        '''
        return AST(type=Token(type="ADVP") , kids=[AST(type=args[0])])

    def p_det_90(self, args):
        '''
        DET ::= det
        DET ::= n_gen
        DET ::= prop_n_gen
        '''
        return AST(type=args[0])

    def p_det_poss_pron_term_90(self, args):
        '''
        DETPOSSPRON ::= poss_pron
        '''
        return AST(type=args[0])

    def p_det_poss_pron_nonterm_90(self, args):
        '''
        DETPOSSPRON ::= DET
        '''
        return args[0]

    def p_adj_sing_plur_100(self, args):
        '''
        ADJSING ::= adj_sing
        ADJSING ::= adj_sing_plur
        ADJPLUR ::= adj_plur
        ADJPLUR ::= adj_sing_plur
        '''
        return AST(type=args[0])

    def p_ap_min_sing_plur_110(self, args):
        '''
        APMINSING_L ::= ADVP_S PP_Q ADJSING
        APMINPLUR_L ::= ADVP_S PP_Q ADJPLUR
        '''
        return AST(type=Token(type="list") , kids=args[0]._kids + args[1]._kids + [args[2]])

    def p_ap_min_120(self, args):
        '''
        APMIN ::= APMINSING_L
        APMIN ::= APMINPLUR_L
        '''
        return AST(type=Token(type="APMIN") , kids=args[0]._kids)

    def p_ap_min_sing_cont_130(self, args):
        '''
        APMINSINGCONT_L ::= del_min APMINSING_L
        APMINSINGCONT_L ::= konj APMINSING_L
        APMINPLURCONT_L ::= del_min APMINPLUR_L
        APMINPLURCONT_L ::= konj APMINPLUR_L

        '''
        return AST(type=Token(type="list") , kids=[AST(type=args[0])] + args[1]._kids)

    def p_ap1_140(self, args):
        '''
        AP ::= APMIN
        '''
        return args[0]

    def p_ap2_150(self, args):
        '''
        AP ::= APMAX
        '''
        return args[0]

    def p_ap_max_150(self, args):
        '''
        APMAX ::= APMINPLUR_L APMINPLUR_S APMINPLURCONT_L APMINPLURCONT_S
        APMAX ::= APMINSING_L APMINSING_S APMINSINGCONT_L APMINSINGCONT_S
        '''
        return AST(type=Token(type="APMAX") ,
                   kids=args[0]._kids + args[1]._kids + args[2]._kids + args[3]._kids)

    def p_conj_del_minq_160(self, args):
        '''
        KONJDELMINQ ::= DELMIN_Q
        KONJDELMINQ ::= KONJ_Q
        '''
        return args[0]

    def p_prop_comp_noun_cont_170(self, args):
        '''
        PROPCOMPNOUNCONT_L ::= KONJDELMINQ AP_Q prop_comp_noun
        '''
        return AST(type=Token(type="list"),
                   kids=args[0]._kids + args[1]._kids + [AST(type=args[2])])

    def p_comp_noun_cont_170(self, args):
        '''
        COMPNOUNCONT_L ::= KONJDELMINQ comp_noun
        '''
        return AST(type=Token(type="list"), kids=args[0]._kids + [AST(type=args[1])])

    def p_siffer_170(self, args):
        '''
        NUMP ::= AP_S num NUM_S
        NUMP ::= ADVP_S num NUM_S
        '''
        return AST(type=Token(type="NUMP"),
                   kids=args[0]._kids + [AST(type=args[1])] + args[2]._kids)

    def p_np1_180(self, args):
        '''
        NP ::= NPREST_L
        '''
        return AST(type=Token(type="NP"), kids=args[0]._kids)

    def p_np_rest_180(self, args):
        '''
        NPREST_L ::= DETPOSSPRON AP_Q
        '''
        return AST(type=Token(type="list"), kids=\
                   [args[0]] + \
                   args[1]._kids)

    def p_np2_190(self, args):
        '''
        NP ::= NPNUM_L
        '''
        return AST(type=Token(type="NP"), kids=args[0]._kids)

    def p_np_sif_190(self, args):
        '''
        NPNUM_L ::= DETPOSSPRON_Q ADVP_Q NUMP
        '''
        return AST(type=Token(type="list"), kids=\
                   args[0]._kids + \
                   args[1]._kids + \
                   [args[2]])

    def p_np_com_1_200(self, args):
        '''
        NPCOM1_L ::= pron HERETHERE_Q
        '''
        return AST(type=Token(type="list"), kids=[AST(type=args[0])] + args[1]._kids)

    def p_np_com_2_200(self, args):
        '''
        NPCOM2_L ::= DET_Q poss_pron AP_Q NGEN_Q AP_S NUM_Q AP_Q com_noun COMNOUN_S
        '''
        return AST(type=Token(type="list"), kids=\
                   args[0]._kids + \
                   [AST(type=args[1])] + \
                   args[2]._kids + \
                   args[3]._kids + \
                   args[4]._kids + \
                   args[5]._kids + \
                   args[6]._kids + \
                   [AST(type=args[7])] + \
                   args[8]._kids)

    def p_np_com_3_200(self, args):
        '''
        NPCOM3_L ::= DET_Q HERETHERE_Q NUM_S AP_Q NGEN_Q AP_S NUM_S com_noun COMNOUN_S
        '''
        return AST(type=Token(type="list"), kids=\
                   args[0]._kids + \
                   args[1]._kids + \
                   args[2]._kids + \
                   args[3]._kids + \
                   args[4]._kids + \
                   args[5]._kids + \
                   args[6]._kids + \
                   [AST(type=args[7])] + \
                   args[8]._kids)

    def p_np3_210(self, args):
        '''
        NP ::= NPPC_L
        NP ::= NPCOMP_L
        NP ::= NPCOM_L
        NP ::= NPPROP_L
        '''
        return AST(type=Token(type="NP"), kids=args[0]._kids)

    def p_np_com_210(self, args):
        '''
        NPCOM_L ::= NPCOM1_L
        NPCOM_L ::= NPCOM2_L
        NPCOM_L ::= NPCOM3_L
        '''
        return args[0]

    def p_np_prop_210(self, args):
        '''
        NPPROP_L ::= DET_Q NUM_Q AP_Q prop_noun PROPNOUN_S
        '''
        return AST(type=Token(type="list"), kids=\
                   args[0]._kids + \
                   args[1]._kids + \
                   args[2]._kids + \
                   [AST(type=args[3])] + \
                   args[4]._kids)

    def p_nppc_210(self, args):
        '''
        NPPC_L ::= prop_comp_noun PROPCOMPNOUNCONT_S KONJ_Q prop_noun PROPNOUN_S
        NPPC_L ::= prop_comp_noun PROPCOMPNOUNCONT_S KONJ_Q com_noun COMNOUN_S
        '''
        return AST(type=Token(type="list"), kids=\
                   [AST(type=args[0])] + \
                   args[1]._kids + \
                   args[2]._kids + \
                   [AST(type=args[3])] + \
                   args[4]._kids)

    def p_np_comp_210(self, args):
        '''
        NPCOMP_L ::= DET_Q AP_Q comp_noun COMPNOUNCONT_S konj NGEN_Q NUM_Q AP_Q com_noun COMNOUN_S
        '''
        return AST(type=Token(type="list"), kids=\
                   args[0]._kids + \
                   args[1]._kids + \
                   [AST(type=args[2])] + \
                   args[3]._kids + \
                   [AST(type=args[4])] + \
                   args[5]._kids + \
                   args[6]._kids + \
                   args[7]._kids + \
                   [AST(type=args[8])] + \
                   args[9]._kids)

    def p_pp1_220(self, args):
        '''
        PP ::= prep AP
        '''
        return AST(type=Token(type="PP"), kids=[AST(type=args[0]), args[1]])

    def p_vc_term_220(self, args): # is a phrase #modified by bohag VC
        '''
        VC ::= imp_verb PART_Q
        VC ::= inf_verb PART_Q
        VC ::= sup_verb PART_Q
        VC ::= subjnct_verb PART_Q 
        '''
        return AST(type=Token(type="VC") , kids=[AST(type=args[0])]+args[1]._kids)

    def p_pp2_230(self, args):
        '''
        PP ::= prep NP
        '''
        return AST(type=Token(type="PP"), kids=[AST(type=args[0]), args[1]])

    def p_vc_term_list_230(self, args): # is a phrase # modified by bohag
        '''
        VC ::= fin_verb INFVERB_S PART_Q
        '''
        return AST(type=Token(type="VC") , kids=[AST(type=args[0])] + \
	args[1]._kids + args[2]._kids )

    def p_pp_mellan_240(self, args):
        '''
        PP ::= prep_mellan NP konj NP
        '''
        return AST(type=Token(type="PP"), kids=[\
                   AST(type=args[0]),
                   args[1],
                   AST(type=args[2]),
                   args[3]                   
                   ])

    def p_pp_konj_240(self, args):
        '''
        PP ::= prep konj prep NP
        '''
        return AST(type=Token(type="PP"), kids=[\
                   AST(type=args[0]),
                   AST(type=args[1]),
                   AST(type=args[2]),
                   args[3]                   
                   ])

    def p_pp_npmax_240(self, args):
        '''
        PP ::= prep NPMAX
        '''
        return AST(type=Token(type="PP"), kids=[AST(type=args[0]), args[1]])
        
    def p_vc_term_list_sv_240(self, args): # is a phrase #modified by bohag
        '''
        VC ::= fin_verb INFVERB_S sup_verb PART_Q
        '''
        return AST(type=Token(type="VC") ,
                   kids=[AST(type=args[0])] + args[1]._kids + \
	[AST(type=args[2])] + args[3]._kids)

    def p_np_max_2_10(self,args): #added by bohag npmax::=np delmin_q relcl
        '''
        NPMAX ::= NP DELMIN_Q RELCL
        '''
        return AST(type=Token(type="NPMAX"), kids=[args[0]]+args[1]._kids+[args[2]])

    def p_np_max_250(self, args): #modified by bohag,NPMAX::=NP PP
        '''
        NPMAX ::= NP PP 
        '''
        return AST(type=Token(type="NPMAX"), kids=\
                   [args[0]] + \
                   [args[1]])

    def p_infp_250(self, args):
        '''
        INFP ::= inf ADVP_S inf_verb PART_Q
        INFP ::= inf SADVP_S inf_verb PART_Q
        '''
        return AST(type=Token(type="INFP") ,
                   kids=[AST(type=args[0])] + args[1]._kids + \
                   [AST(type=args[2])] + args[3]._kids)

    def p_fnuttar_10(self, args): #test bohag
        '''
        AP ::= del_paren AP del_paren
        ADVP ::= del_paren ADVP del_paren
        NP ::= del_paren NP del_paren
        NPMAX ::= del_paren NPMAX del_paren
        PP ::= del_paren PP del_paren
        VC ::= del_paren VC del_paren
        INFP ::= del_paren INFP del_paren
        NUMP ::= del_paren NUMP del_paren
        RELCL ::= del_paren RELCL del_paren
        '''
        return AST(type=args[1], kids=[AST(type=args[0])] + \
                args[1]._kids + [AST(type=args[2])])

#
#    BUILD PARSER
#

# parser decides number of phrases
## def simple_parse(tokens, print_ambigous=0):
##     parser = PhraseParser(print_ambigous=print_ambigous)
##     return parser.parse(tokens)


def _new_parser(rule):
    s = '''\
class PhraseParser_1(PhraseParser):
    def __init__(self):
        PhraseParser.__init__(self)

    def p_sent_0(self, args):
        "%s"
        return AST(type=Token(type="sent"), kids=args)
''' % rule
    exec(s)
    return PhraseParser_1()

# minimal number phrases (longest match on phrase level)
def parse(tokens):
    lhs = "SENT ::="
    fail = 1
    i = 0
    while fail and i < len(tokens):
        i = i + 1
        parser = _new_parser(lhs + " PHRASE" * i)
        try:
            pt = parser.parse(tokens)
        except:
            continue
        else:
            fail = 0
    if fail:
        raise SystemExit, "Could not parse tokens"
    return pt


#
#	OUTPUT GENERATION
#

def _build_indent(ast, indent):
    s = " " * indent + ast.type
    if ast.attr:
        word, tag = ast.attr
        s = s + " = " + word + "/" + tag
    s = s + "\n"
    return s

def _indent_repr(ast, indent=0):
    s = _build_indent(ast, indent)
    for t in ast._kids:
        s = s + _indent_repr(t, indent + 4)
    return s

#def _build_perlhash(ast, indent):
#    s = " " * indent + "{ " + ast.type
#    if ast.attr:
#        word, tag = ast.attr
#        s = s + " => '" + word + "/" + tag + "'"
#    else:
#        s = s + " => "
#    s = s + "\n"
#    return s
#
#def _perlhash_repr(ast, indent=0):
#    s = _build_perlhash(ast, indent)
#    for t in ast._kids:
#        s = s + _perlhash_repr(t, indent + 4)
#    s = s + " " * indent + "}\n"
#    return s


# Prints the parse tree
def indent_repr(ast):
    return _indent_repr(ast)[:-1]

## Prints the parse tree
#def perlhash_repr(ast):
#    return _perlhash_repr(ast)[:-1]

## leaves = ["here_there", "particip", "prep_mellan", "sent_adv", "adj_plur",
##           "adj_sing", "adj_sing_plur", "adv", "com_noun", "comp_noun",
##           "subjnct_verb", "del_maj", "del_min", "del_paren", "det", "fin_verb", #mod.by bohag
##           "imp_verb", "inf", "inf_verb", "interj", "konj", "n_gen", "num",
##           "part", "poss_pron", "prep", "pron", "prop_comp_noun", "prop_n_gen",
##           "prop_noun", "subj", "sup_verb", "u_o"]


# Computes the depth of the tree 'ast'
def depth(ast):
        if ast._kids == []:
            return 0
        else:
            depth_list = []
            for t in ast:
                depth_list.append(depth(t))
            return 1 + max(depth_list)

# Generates a parenthesis repr. of a sentence
def parenthesis_repr(sent):
    from string import strip
    s = ""
    for phrase in sent:
        s = s + _parenthesis_repr(phrase)
    s = strip(s)
    return join(split(s)," ")


def _parenthesis_repr(ast):
        if ast._kids == []:
            word, tag = ast.attr
            return " " + word + "/" + tag + " "
        else:
            s = " [" + ast.type + "*" 
            for t in ast:
                s = s + _parenthesis_repr(t)
            s = s + "*" + ast.type + "] " 
            return s

# Generates a parse tag repr. of a sentence
def tagged_repr(sent):
    from string import strip
    s = ""
    for phrase in sent:
        s = s + _tagged_repr(phrase, "")
    s = strip(s)
    return join(split(s)," ")


def _tagged_repr(ast, parse_tag):
        if ast._kids == []:
	    if parse_tag =="":
		parse_tag = "_O"
            word, tag = ast.attr
            return " " + word + "/" + tag + parse_tag + " "
        else:
            new_B_parse_tag = "_" + ast.type + "B" + parse_tag
            new_I_parse_tag = "_" + ast.type + "I" + parse_tag
            s = _tagged_repr(ast[0], new_B_parse_tag)
            for t in ast._kids[1:]:
                s = s + _tagged_repr(t,new_I_parse_tag)
            return s

    

#
#	UTILITY FUNCTIONS
#

# Generates token list output from SpecialScanner (type = word, tag)
def token_list(tok_list):
    s = ""
    for tok in tok_list:
        word, tag = tok.attr
        s = s + tok.type + " = " + word + "/" + tag + "\n"
    return s[:-1]



# Assumes S is the name of a 't_' scanner method with 't_' deleted
def _big2small(S):
    from string import uppercase, lower
    dst = lower(S[0])
    for i in xrange(1, len(S)):
        if S[i] in uppercase:
            dst = dst + "_" + lower(S[i])
        else:
            dst = dst + S[i]
    return dst

# The inverse of _big2small()
def _small2big(s):
    from string import upper
    dst = upper(s[0])
    for i in xrange(1, len(s)):
        if s[i-1] == "_":
            dst = dst + upper(s[i])
        elif s[i] != "_":
            dst = dst + s[i]
    return dst

# Generates lexical rules
def lex_rules(scanner):
    t_meth_list = filter(lambda n: n[:2] == "t_" and n[2:] != "default", _namelist(scanner))
    meth_list = map(lambda n, s=scanner: (n[2:], getattr(s, n).__doc__), t_meth_list)
    type_list = map(lambda n, f=_big2small: (f(n[0]), n[1]), meth_list)
    res = ""
    for type, rule in type_list:
        res = res + type + " = '" + rule + "'\n"
    return res[:-1]
# Print lexical rules
def print_lex_rules():
    s = "-" * 30 + "\n     The Lexical Rules     \n" + "-" * 30 + "\n\n"
    s = s + lex_rules(SpecialScanner())
    print s

# Generate grammar rules
def grammar_rules(parser, Star=1, Opt=1):
    from string import uppercase, lower, strip
    p_meth_list = filter(lambda n: n[:2] == "p_", _namelist(parser))
    accum_rule_list = map(\
        lambda n, s=parser: (int(split(n, "_")[-1]), getattr(s, n).__doc__), p_meth_list)
    rule_list = []
    for ar in accum_rule_list:
        rule_list = rule_list + map(lambda w, a=ar[0]: (a, w), split(strip(ar[1]), "\n"))
    rule_list = map(lambda r, f=strip: (r[0], f(r[1])), rule_list)
    max_prio_len = max(map(lambda r: len(`r[0]`), rule_list))
    lhsyms = []
    rhsyms = []
    for prio, rule in rule_list:
        s = split(rule, "::=")
        lhsyms.append(strip(s[0]))
        if len(s) > 1:
            rhsyms = rhsyms + split(strip(s[1]))
    max_lhs = max(map(lambda s: len(s), lhsyms))
    non_terminal = []
    for sym in lhsyms:
        if not sym in non_terminal:
            non_terminal.append(sym)
    non_terminal.sort()
    terminal = []
    for sym in rhsyms:
        if not sym in terminal and not sym in non_terminal:
            terminal.append(sym)
    terminal.sort()
    if not Star:
        rule_list = filter(lambda rule, s=split: s(rule[1])[0][-2:] != "_S", rule_list)
        non_terminal = filter(lambda sym: sym[-2:] != "_S", non_terminal)
    if not Opt:
        rule_list = filter(lambda rule, s=split: s(rule[1])[0][-2:] != "_Q", rule_list)
        non_terminal = filter(lambda sym: sym[-2:] != "_Q", non_terminal)
    rule_list.sort()
    
    rule_list = map(lambda r, ml=max_lhs, mp=max_prio_len: " " * (mp - len(`r[0]`)) +\
                    `r[0]` + ": " + split(r[1])[0] + " " * (ml - len(split(r[1])[0])) +\
                    " ::=   " + join(split(r[1])[2:], " "), rule_list)
    return join(rule_list, "\n"), join(non_terminal, "\n"), join(terminal, "\n")

# Print grammar rules
def print_grammar_rules():
    r_list, nt_list, t_list = grammar_rules(PhraseParser(), Star=1, Opt=1)
    s = "-" * 41 + "\n          The Grammatical Rules\n" + "-" * 41 + "\n\n"
    s = s + r_list + "\n\n" + "-" * 30 + "\n       Non Final Tokens\n" + "-" * 30 + "\n\n"
    s = s + nt_list + "\n\n" + "-" * 30 + "\n         Final Tokens\n" + "-" * 30 + "\n\n"
    s = s + t_list
    print s

# Processes the list of parse trees from standard input with the function do(line_no, tree)
def parse_input(do=None, start=1, no_of_lines_to_read=0):
    start = start - 1
    input = stdin.read()
    input_lines = split(input, "\n")
    if no_of_lines_to_read == 0:
        no_of_lines_to_read = len(input_lines) - start + 1
    i = start
    for line in input_lines[start:start + no_of_lines_to_read]:
        i = i + 1
        if split(line) == []:
            continue
        try:
            tokens = scan(line)
        except:
            stderr.write("Line no. %d could not be tokenized\n" % i)
	    continue
	try:
	    parse_tree = parse(tokens)
	except:
	    stderr.write("Line no. %d could not be parsed\n" % i)
	    continue
	do(i, parse_tree)
	stderr.write("Line %d parsed\n" % i)


#
#	MAIN
#



# BEA! det är denna funktion som skriver ut trädet för varje rad.
# Du har alltså tillgång till trädet ('tree') och radens nummer
# ('row_number'). Du kan använda 'row_number' om du vill!
def t(row_number, tree):
    print tagged_repr(tree)

def p(row_number, tree):
    print parenthesis_repr(tree)

def i(row_number, tree):
    print indent_repr(tree)

def h(row_number, tree):
    print perlhash_repr(tree)

def d(row_number, tree):
    header = 'digraph pvn {\n    ordering=out;\n\n'
    dotFile = tree.makeDotFile(header=header)
    # Run result through 'dot'
    outFile, inFile = popen2("dot -Tps -Gfontname=latin1 -l isofonts.ps | python fixdot.py")
    inFile.write(dotFile)
    inFile.close()
    psFile = outFile.read()
    outFile.close()
    print psFile
    
def buildLabel(astType, astAttr):
    if astAttr:
        return r"%s:\n%s" % (astType.upper(), seFilter(astAttr[0]))
    else:
        return "%s" % astType

def seFilter(word):
    word = word.replace("å", "aa")
    word = word.replace("ä", "ae")
    word = word.replace("ö", "oe")
    word = word.replace("Å", "AA")
    word = word.replace("Ä", "AE")
    word = word.replace("Ö", "OE")
    return word

# Om du bara vill skriva ut de lexikala eller grammatiska reglerna
# måste du kommentera bort denna rad och i stället köra DETTA program
# utan argument. Dessutom måste du ta bort kommentar tecknet/tecknen
# framför 'print_lex_rules()' och/eller 'print_grammar_rules()' nedan.

if argv[1] == "-r":
    print_lex_rules()
    print_grammar_rules()
    exit(0)

if argv[1] == "-t":
    fun = t
elif argv[1] == "-p":
    fun = p
elif argv[1] == "-i":
    fun = i
#elif argv[1] == "-h":
#    fun = h
elif argv[1] == "-d":
    fun = d

parse_input(do=fun, start=int(argv[2]), no_of_lines_to_read=int(argv[3]))

#for (line, tree) in parse_list:
#    print "\n\n\n\n%s\n   Line no. %d:\n%s\n\n" % ("-"*22, line, "-"*22)
#    print
#    print indent_repr(tree)
#    print
#    print "depth = %s" % depth(tree)
#    print 

#tl = scan(stdin.read())
#print token_list(tl)

#pt = parse(tl)

#print indent_repr(pt)
#print parenthesis_repr(pt)
#print tagged_repr(pt)

#print_lex_rules()
#print_grammar_rules()






