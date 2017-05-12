#!perl -w
use utf8;
use WordLists::Common ('reverse_punct');
use Test::More;
is(reverse_punct('(') , ')', 'Simple reversing brackets');
is(reverse_punct('‘') , '’', 'Simple reversing non-ascii chars');
is(reverse_punct('<i>') , '</i>', 'Reversing XML-like tag');
is(reverse_punct('[sense-head]') , '[/sense-head]', 'Reversing XML-like tag (not angle-brackets)');

done_testing();
