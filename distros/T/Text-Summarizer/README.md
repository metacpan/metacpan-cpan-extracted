# NAME

Text::Summarizer - Summarize Bodies of Text



# SYNOPSIS
	use Text::Summarizer;
	
	# all constructor arguments shown are OPTIONAL and reflect the DEFAULT VALUES of each attribute
	$summarizer = Text::Summarizer->new(
		articles_path  => 'articles/*',
		permanent_path => 'data/permanent.stop',
		stopwords_path => 'data/stopwrods.stop',
		store_scanner  => 0,
		print_scanner  => 0,
		print_summary  => 0,
		return_count   => 20,
		phrase_thresh  => 2,
		phrase_radius  => 5,
		freq_constant  => 0.004,
	);
	
	$summarizer = Text::Summarizer->new();
		# to summarize a string
	$stopwords = $summarizer->scan_text( 'this is a sample text' );
	$summary   = $summarizer->summ_text( 'this is a sample text' );
	    # or to summarize an entire file
	$stopwords = $summarizer->scan_file("some/file.txt");
	$summary   = $summarizer->summ_file("some/file.txt");
		# or to summarize in bulk
	@stopwords = $summarizer->scan_each("/directory/glob/*");  # if no argument provided, defaults to the 'articles_path' attribute
	@summaries = $summarizer->summ_each("/directory/glob/*");  # if no argument provided, defaults to the 'articles_path' attribute



# DESCRIPTION
This module allows you to summarize bodies of text into a scored hash of  _sentences_,  _phrase-fragments_, and  _individual words_ from the provided text. These scores reflect the weight (or precedence) of the relative text-fragments, i.e. how well they summarize or reflect the overall nature of the text. All of the sentences and phrase-fragments are drawn from within the existing text, and are NOT proceedurally generated.



# ATTRIBUTES
**The following constructor attributes are available to the user, and can be accessed/modified at any time via `$summarizer->[attribute]`:**
* `articles_path`  - [directory] folder containing some text-files you wish to summarize
* `permanent_path` - [filepath] file containing a base set of universal stopwords (defaults to English stopwords)
* `stopwords_path` - [filepath] file containing a list of new stopwords identified by the `scan` function
* `store_scanner`  - [boolean] flag for storing new stopwords in the file indicated by `stopwords_path`
* `print_scanner`  - [boolean] flag that enables visual graphing of scanner activity (prints to `STDOUT`)
* `print_summary`  - [boolean] flag that enables visual charting of summary activity (prints to `STDOUT`)
* `return_count`   - [int] number of items to list when printing summary list
* `phrase_thresh`  - [int] minimum number of word tokens allowed in a phrase
* `phrase_radius`  - [int] distance iterated backward and forward from a given word when establishing a phrase (i.e. maximum length of phrase divided by 2)
* `freq_constant`  - [float] mathematical constant for establishing minimum threshold of occurence for frequently occuring words (defaults to `0.004`)


**These attributes are read-only, and can be accessed via `$summarizer->[attribute]`:**
* `full_text` - [string] all the lines of the provided text, joined together
* `sentences` - [array-ref] list of each sentence from the `full_text`
* `sen_words` - [array-ref] list that, for each sentence, contains an array of each word in order
* `word_list` - [array-ref] each individual word of the entire text, in order (token stream)
* `freq_hash` - [hash-ref] all words that occur more than a specified threshold, paired with their frequency of occurence
* `clst_hash` - [hash-ref] for each word in the text, specifies the position of each occurence of the word, both relative to the sentence it occurs in and absolute within the text
* `phrs_hash` - [hash-ref] for each word in the text, contains a phrase of radius _r_ centered around the given word, and references the sentence from which the phrase was gathered
* `sigma_hash` - [hash-ref] gives the population standard deviation of the clustering of each word in the text
* `inter_hash` - [hash-ref] list of each chosen phrase-fragment-scrap, paired with its score
* `score_hash` - [hash-ref] list of each word in the text, paired with its score
* `phrs_list`  - [hash-ref] list of complete sentences that each scrap was drawn from, paired with its score
* `frag_list`  - [array-ref] for each chosen scrap, contains a hash of: the pivot word of the scrap; the sentence containing the scrap; the number of occurences of each word in the sentence; an ordered list of the words in the phrase from which the scrap was derived
* `file_name` - [string] the filename of the current text-source (if text was extracted from a file)
* `text_hint` - [string] brief snippet of text containing the first 50 and the final 30 characters of the current text
* `summary` - [hash-ref] scored lists of each summary sentence, each chosen scrap, and each frequently-occuring word
* `stopwords` - [hash-ref] list of all stopwords, both permanent and proceedural
* `watchlist` - [hash-ref] list of proceedurally generated stopwords, derived by the `scan` function


# FUNCTIONS
## scan
Scan is a utility that allows the Text::Summarizer to parse through a body of text to find words that occur with unusually high frequency. These words are then stored as new stopwords via the provided `stopwords_path`. Additionally, calling any of the three `scan_[...]` subroutines will return a reference (or array of references) to an unordered list containing the new stopwords.

	$stopwords = $summarizer->scan_text( 'this is a sample text' );
	$stopwords = $summarizer->scan_file( 'some/file/path.txt' );
	@stopwords = $summarizer->scan_each( 'some/directory/*' );  # if no argument provided, defaults to the 'articles_path' attribute

## summarize
Summarizing is, not surprisingly, the heart of the Text::Summarizer. Summarizing a body of text provides three distinct categories of information drawn from the existing text and ordered by relevance to the summary: full sentences, phrase-fragments / context-free token streams, and a list of frequently occuring words.

There are three provided functions for summarizing text documents:

	$summary   = $summarizer->summarize_text( 'this is a sample text' );
	$summary   = $summarizer->summarize_file( 'some/file/path.txt' );
	@summaries = $summarizer->summarize_each( 'some/directory/*' );  # if no argument provided, defaults to the 'articles_path' attribute
		# or their short forms
	$summary   = $summarizer->summ_text('...');
	$summary   = $summarizer->summ_file('...');
	@sumamries = $summarizer->summ_each('...');  # if no argument provided, defaults to the 'articles_path' attribute

`summarize_text` and `summarize_file` each return a summary hash-ref containing three array-refs, while `summarize_each` returns a list of these hash-refs. These summary hashes take the following form:
- `sentences` => a list of full sentences from the given text, with composite scores of the words contained therein

- `fragments` => a list of phrase fragments from the given text, scored similarly to sentences

- `words`     => a list of all words in the text, scored by a three-factor system consisting of  _frequency of appearance_,  _population standard deviation_, and  _use in important phrase fragments_.


### About Fragments
Phrase fragments are in actuallity short "scraps" of text (usually only two or three words) that are derived from the text via the following process:
1. the entirety of the text is tokenized and scored into a `frequency` table, with a high-pass threshold of frequencies above `# of tokens * user-defined scaling factor`
2. each sentence is tokenized and stored in an array
3. for each word within the `frequency` table, a table of phrase-fragments is derived by finding each occurance of said word and tracking forward and backward by a user-defined "radius" of tokens (defaults to `radius = 5`, does not include the central key-word) — each phrase-fragment is thus compiled of (by default) an 11-token string
4. all fragments for a given key-word are then compared to each other, and each word is deleted if it appears only once amongst all of the fragments
(leaving only <code>_A_ ∪ _B_ ∪ ... ∪ _S_</code> where _A_, _B_,..., _S_ are the phrase-fragments)
5. what remains of each fragment is a list of "scraps" — strings of consecutive tokens — from which the longest scrap is chosen as a representation of the given phrase-fragment
6. when a shorter fragment-scrap (_A_) is included in the text of a longer scrap (_B_) such that _A_ ⊂ _B_, the shorter is deleted and its score is added to that of the longer
7. when multiple fragments are equivalent (i.e. they consist of the same list of tokens when stopwords are excluded), they are condensed into a single scrap in the form of `"(some|word|tokens)"` such that the fragment now represents the tokens of the scrap (excluding stopwords) regardless of order (refered to as a "context-free token stream")



# SUPPORT

Bugs should always be submitted via the project hosting bug tracker

https://github.com/faelin/text-summarizer/issues

For other issues, contact the maintainer.



# AUTHOR

Faelin Landy <faelin.landy@gmail.com> (current maintainer)



# CONTRIBUTORS

* Michael McClennen <michaelm@umich.edu>



# COPYRIGHT AND LICENSE

Copyright (C) 2018 by the AUTHOR as listed above

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
