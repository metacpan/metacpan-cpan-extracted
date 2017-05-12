#!perl -w

use strict;

=head1 NAME

00build.t - Tests that the build phase (perl Makefile.PL; make) went OK.

=head1 DESCRIPTION

There is just a small quirk to test: we use
dist/rewrite-default-xml-parser to rewrite the source code of
XPathScript.pm. Let us just check that it worked.

=cut

use Test;

plan tests => 1;

open(ORIGFILE, "<", "lib/XML/XPathScript.pm");
open(COPY, "<", "blib/lib/XML/XPathScript.pm");
my $difflines = 0;
while(<ORIGFILE>) {
    my $copyline = <COPY>;
    $difflines++ if $copyline ne $_;
}

ok($difflines <= 1);

