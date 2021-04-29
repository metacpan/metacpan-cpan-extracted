# This is a test for module Unicode::Confusables.

use warnings;
use strict;
use utf8;
use Test::More;
use_ok ('Unicode::Confuse');
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use Unicode::Confuse ':all';

ok (confusable ('Æ'), "Æ is confusable");
is (canonical ('Æ'), 'AE', "Got canonical form for Æ");

ok (confusable ('㈝'), "㈝ is confusable");
is (canonical ('㈝'), '(오전)', "Got canonical form for ㈝");

ok (confusable ('−'), "Minus sign is confusable");
is (canonical ('–'), '-', "Got canonical form for −");
ok (confusable ('~'), "Tildes");
is (canonical ('∼'), '~', "Tildes");
done_testing ();

# Local variables:
# mode: perl
# End:
