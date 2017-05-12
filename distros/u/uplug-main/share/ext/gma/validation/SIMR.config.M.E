# configuration file for Malay/English SIMR
# Copyright (C) 2000 by I. Dan Melamed

# All parameters are mandatory unless otherwise indicated.
# Lines starting with '#' like this one are comments and will be ignored.
# Other lines should have the parameter name and value separated by whitespace.

# This is the master configuration file, but it can "include" other
# configuration files like this: #INCLUDE	another_config_file_name
# This is useful if you want to, e.g., separate out the numeric parameters for optimization.

#############################################################################

## ----- word matching parameters -----



####################
##
## matching predicate
##
## criterion for matching words
## possible values are gma.simr.ExactMatching, gma.simr.LcsrMatching, gma.simr.DictMatching, gma.simr.DictExactMatching, gma.simr.LcsrLexMatching
##
####################

matchingPredicate = gma.simr.LcsrLexMatching


####################
##
## minimum longest common subsequence ratio
##
## threshold for matching words with LCSR criterion
## this value must be set when "matchPredicate" is set to "gma.simr.LcsrMatching"
##
####################

lcsrThreshold = 0.71



####################
##
## minimum word length for lcsr matching
##
## any word of length less than this value is dropped from LCSR matching
## this value must be set when "matchPredicate" is set to "gma.simr.LcsrMatching"
##
####################

minimumWordLength = 4



####################
##
## translation lexicon file
##
## this value must be set when "matchPredicate" is set to "gma.simr.TranslationLexiconMatching"
##
####################

translationLexicon = ./rc/ME.tralex



## ----- chain selection parameters -----



####################
##
## default slope value
##
## default to main diagonal of the bitext space if commented
##
####################

slope = 0.91



####################
##
## chain size threshold
##
## number of match points to form a match chain
##
####################

chainSize = 8



####################
##
## maximum chain point ambiguity
##
## threshold for chain point ambiguity
##
####################

chainPointAmbiguity = 8



####################
##
## maximum angle deviation
##
## threshold for angle deviation in selecting best chain
##
####################

angleDeviation = 0.17



####################
##
## maximum linear regression error
##
## threshold for linear regression error in selecting best chain
##
####################

linearRegressionError = 21


 