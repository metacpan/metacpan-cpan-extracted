#!perl

use strict;
use warnings;
use Test::More tests => 2;

use lib "t/lib";
use TestTester;

use Test::DocClaims;

=pod

Or, for more control over the POD files and which tests correspond to them:

=cut

findings_match( sub {

=begin DC_CODE

=cut

  use Test::More;
  eval "use Test::DocClaims";
  plan skip_all => "Test::DocClaims not found" if $@;
  plan tests => 2;
  doc_claims( "lib/Foo/Bar.pm", "t/doc-Foo-Bar.t",
    "doc claims in Foo/Bar.pm" );
  doc_claims( "lib/Foo/Bar/Baz.pm", "t/doc-Foo-Bar-Baz.t",
    "doc claims in Foo/Bar/Baz.pm" );

=end DC_CODE

=cut

}, [
    ["ok", "doc claims in Foo/Bar.pm"],
    ["ok", "doc claims in Foo/Bar/Baz.pm"],
]);

# The example code above plans two tests, but findings_match() intercepts the
# tests so it can verify them. findings_match() actually only performs one
# test, so this provides the second test so Test::More will be happy. It might
# be better if findings_match() ran the code in a subtest, but this works for
# now.
ok 1;

__END__

FILE:<lib/Foo/Bar.pm>----------------------------
1;
FILE:<t/doc-Foo-Bar.t>----------------------------
1;
FILE:<lib/Foo/Bar/Baz.pm>-------------------------------
1;
FILE:<t/doc-Foo-Bar-Baz.t>-------------------------------
1;
