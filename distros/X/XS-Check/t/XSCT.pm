package XSCT;
use warnings;
use strict;
use utf8;
use Carp;
require Exporter;
use XS::Check;
use Test::More;
our @ISA = qw(Exporter);
our @EXPORT = (
    'got_warning',
    @Test::More::EXPORT,
    @XS::Check::EXPORT_OK,
);

sub import
{
    strict->import ();
    utf8->import ();
    warnings->import ();

    Test::More->import ();
    XS::Check->import (':all');

    XSCT->export_to_level (1);
}

my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

sub got_warning
{
    my ($xs, $msg, $want, $re) = @_;
    if ($re && ! $want) {
	die "Regex with negative test";
    }
    my $checker = XS::Check->new ();
    my $warning;
    $SIG{__WARN__} = sub {
	$warning = shift;
    };
    $checker->check ($xs);
    if ($want) {
	ok ($warning, "Got warning with $msg");
	note ($warning);
	if ($re) {
	    like ($warning, $re, "warning looks ok for $msg");
	}
    }
    else {
	ok (! $warning, "Did not get warning with $msg");
    }
    delete $SIG{__WARN__};
    # Do any further checks
    return $warning;
}

1;
