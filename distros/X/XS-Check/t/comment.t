use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use XS::Check;
my $warning;
$SIG{__WARN__} = sub {
    $warning = shift;
};
my $check = XS::Check->new ();
my $text = <<EOF;
# Comment

#ifdef NOTHING

#line
EOF
$check->check ($text);
like ($warning, qr!1: Put whitespace before # in comments!, "Warn about comments");
unlike ($warning, qr!^[2-9]!sm, "no false positives with C preprocessor directives");
done_testing ();
