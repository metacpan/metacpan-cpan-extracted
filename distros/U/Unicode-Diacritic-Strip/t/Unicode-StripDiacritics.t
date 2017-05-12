# This is a test for module Unicode::StripDiacritics.

use warnings;
use strict;
use Test::More;
use Unicode::Diacritic::Strip ':all';
use utf8;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
my $stuff = <<EOF;
Bên cnh ngoi hình a nhìn, Aguilera còn có mt cht ging mnh m và cao vút. Điu này giúp Aguilera liên tc gt hái các gii thng danh giá, đc bit là 4 [[gii Grammy]] và 1 [[gii Latin Grammy]]. Aguilera là mt trong các ngh sĩ bán đĩa chy nht vi 50 triu bn album và 52 triu đĩa đn đc tiêu th trên th gii
EOF
my ($stripped, $list) = strip_alphabet ($stuff);
ok ($stripped, "Got the text returned");
ok ($list->{ì}, "Got a value for ì");
done_testing ();
# Local variables:
# mode: perl
# End:
