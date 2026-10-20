#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural::Words;

# The word tables' matcher, at the edges 0.01's regexes drew: case folded
# as /i folds (Greek capitals), either apostrophe, the spaces a phrase
# needs around it, and a newline the framed text may not hold.
my $W = 'Time::Keeper::Natural::Words';
my %w = map { $_ => $W->for($_) } qw(el fr de bn en);

is_deeply([ $w{el}->frame('ΤΈΛΟΣ ΟΚΤΩΒΡΊΟΥ', 'end_of') ], [ 'ΟΚΤΩΒΡΊΟΥ', 'τέλος' ], 'el: a Greek capital final sigma folds to the table\'s');
is_deeply([ $w{el}->frame('ΑΡΧΈΣ ΤΟΥ 2027', 'start_of') ], [ 'ΤΟΥ 2027', 'αρχές' ], 'el: start of, in capitals');
is_deeply([ $w{fr}->frame("fin d\x{2019}octobre", 'end_of') ], [ 'octobre', "fin d'" ], 'fr: a curly apostrophe reads as the plain one');
is_deeply([ $w{fr}->frame("fin d'octobre", 'end_of') ], [ 'octobre', "fin d'" ], 'fr: and the plain one');
is_deeply([ $w{fr}->split_on("fin de l\x{2019}année", 'skip') ], [ 'fin de', 'année', "l'" ], 'fr: split on an elided article');
is_deeply([ $w{de}->split_on('next week zum Ende friday', 'at') ], [], 'de: a phrase inside a word is not a split');
is_deeply([ $w{bn}->frame("গত\nমাসের শেষ", 'end_of') ], [], 'bn: the framed text may not hold a newline');
is_deeply([ $w{bn}->frame("গত মাসের শেষ", 'end_of') ], [ 'গত মাস', '{0}ের শেষ' ], 'bn: a postposed frame');
is_deeply([ $w{en}->frame("  END   OF\tlast month ", 'end_of') ], [ 'last month', 'end of' ], 'en: padded, spaced and in capitals');
is(scalar $w{en}->frame('end of last month', 'end_of'), 'end of', 'frame in scalar context is the phrase, as 0.01\'s list was');
is(scalar $w{en}->frame('nothing here', 'end_of'), undef, 'and undef for none');

done_testing;
