#!perl -T

use strict;
use warnings;

use Test::More tests => 8;

my $invalid = qr/Invalid\s+package\s+name/;

eval "use subs::auto qw<a b c>";
like($@, qr|Optional\s+arguments\s+must\s+be\s+passed\s+as\s+keys?\s*/\s*values?\s+pairs?|, 'no even number of args');

eval "use subs::auto in => \\( q{foo::bar} )";
like($@, $invalid, 'no ref as package name');

eval "use subs::auto in => qq{foo\\nbar}";
like($@, $invalid, 'no newline in package name');

eval "use subs::auto in => q{foo-bar}";
like($@, $invalid, 'no dash in package name');

eval "use subs::auto in => q{foo:bar}";
like($@, $invalid, 'no single colon in package name');

eval "use subs::auto in => q{foo:::bar}";
like($@, $invalid, 'no three colons in package name');

eval "use subs::auto in => q{1foo::bar}";
like($@, $invalid, 'no package name starting by a digit');

eval "use subs::auto in => q{foo::2bar}";
like($@, $invalid, 'no package name with a digit inside');
