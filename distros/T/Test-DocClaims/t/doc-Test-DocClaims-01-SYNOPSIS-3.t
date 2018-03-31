#!perl

use strict;
use warnings;
use Test::More tests => 2;

use lib "t/lib";
use TestTester;

BEGIN { use_ok('Test::DocClaims'); }

=pod

If a source file (lib/Foo/Bar.pm) contains:

=cut

my $source = <<'END_SOURCE';

=begin DC_CODE

  =head2 add I<arg1> I<arg2>

  This adds two numbers.

  =cut

  sub add {
      return $_[0] + $_[1];
  }

=end DC_CODE

=cut

END_SOURCE

=pod

then the corresponding test (t/doc-Foo-Bar.t) might have:

=cut

my $test = <<'END_TEST';

=begin DC_CODE

  =head2 add I<arg1> I<arg2>

  This adds two numbers.

  =cut

  is( add(1,2), 3, "can add one and two" );
  is( add(2,3), 5, "can add two and three" );

=end DC_CODE

=cut

END_TEST

$source =~ s/^=(begin|end).*//mg;
$test   =~ s/^=(begin|end).*//mg;
findings_match( { "lib/Foo/Bar.pm" => $source, "t/doc-Foo-Bar.t" => $test },
    sub {
    	doc_claims( "lib/Foo/Bar.pm", "t/doc-Foo-Bar.t", "example" );
    },
    [
    	[ "ok", "example" ],
    ]);

=cut

