##
#
#    Copyright 2001 AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Pkg::Textsearch::Preprocessor;

##
#
# Abstract class that child pre-processors can inherit from or use as
# a template.
#
##

#
# Global variable specifying the maximum word length that we consider
# a "real" word. Index tables use this to figure out their SQL
# definitions, and other code should make sure to accomodate words of
# this length.
#
$XML::Comma::Pkg::Textsearch::Preprocessor::max_word_length = 16;

#
#   1/0 = XML::Comma::Pkg::Textsearch::Preprocessor->is_stopword($word)
#
sub is_stopword {
  die "abstract method";
}

#
# @list_of_stemmed_words =
#  XML::Comma::Pkg::Textsearch::Preprocessor->stem ( $text )
#
sub stem {
  die "abstract method";
}

# %hash_of_stemmed_words_and_count_of_each =
#  XML::Comma::Pkg::Textsearch::Preprocessor->stem_and_count ( $text )
sub stem_and_count {
  die "abstract method";
}

