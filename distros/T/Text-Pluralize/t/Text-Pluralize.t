##==============================================================================
## Test script for Text::Pluralize
##==============================================================================
## $Id: Text-Pluralize.t,v 1.0 2004/05/23 05:33:14 kevin Exp $
##==============================================================================
use Test::More tests => 26;
BEGIN { use_ok('Text::Pluralize') };

for ('item') {
	ok(pluralize($_, 0) eq 'items');
	ok(pluralize($_, 1) eq 'item');
	ok(pluralize($_, 2) eq 'items');
	ok(pluralize($_, -1) eq 'items');
}

for ('item(s) (is|are)') {
	ok(pluralize($_, 0) eq 'items are');
	ok(pluralize($_, 1) eq 'item is');
	ok(pluralize($_, 2) eq 'items are');
	ok(pluralize($_, -1) eq 'items are');
}

for ('%d item(s) need{|s|} explaining') {
	ok(pluralize($_, 0) eq '0 items need explaining');
	ok(pluralize($_, 1) eq '1 item needs explaining');
	ok(pluralize($_, 2) eq '2 items need explaining');
	ok(pluralize($_, -1) eq '-1 items need explaining');
}

for ('{No|%d} quer(y|ies) (is|are)') {
	ok(pluralize($_, 0) eq 'No queries are');
	ok(pluralize($_, 1) eq '1 query is');
	ok(pluralize($_, 2) eq '2 queries are');
	ok(pluralize($_, -1) eq '-1 queries are');
}

for ('{No|One|Two|Three|%d} quer(y|ies) (is|are)') {
	ok(pluralize($_, 0) eq 'No queries are');
	ok(pluralize($_, 1) eq 'One query is');
	ok(pluralize($_, 2) eq 'Two queries are');
	ok(pluralize($_, 3) eq 'Three queries are');
	ok(pluralize($_, 4) eq '4 queries are');
	ok(pluralize($_, -1) eq '-1 queries are');
}

for ('item(s}') {
	ok(pluralize($_, 0) eq 'items');
	ok(pluralize($_, 1) eq 'item');
	ok(pluralize($_, 2) eq 'items');
}

##==============================================================================
## $Log: Text-Pluralize.t,v $
## Revision 1.0  2004/05/23 05:33:14  kevin
## Initial revision
##
##==============================================================================
