use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lf.pl";

BEGIN { plan tests => 15 + 3 }

foreach my $lang (qw(fr ja quotes)) {
    do5tests($lang, $lang);
}    

my $in = <<EOF;
This is a very long piece of text that wraps appropriately to have a From at the start of the line. From should be space indented.
 It never wraps at a space so let us start this paragraph with one so that the behaviour there can be observed; it should have two spaces.
EOF
my $out = <<EOF;
This is a very long piece of text that wraps appropriately to have a  
 From at the start of the line. From should be space indented. 

  It never wraps at a space so let us start this paragraph with one so  
that the behaviour there can be observed; it should have two spaces. 

EOF
my $lf = Text::LineFold->new(ColMax => 72);
is($lf->fold($in, 'FLOWED'), $out, 'CPAN RT 115146');
is($lf->unfold($out, 'FLOWED'), $in, 'reversal');

# Multiple Prep options (fixed on 2018.012).
my $lf = Text::LineFold->new(ColMax => 7,
    Prep=>"NONBREAKURI", Prep=>[qr/[-\w]+\@[-.\w]+/,sub{shift;@_}]);
my $in = "https://www-www.example.org/, user-user\@example.org";
my $out = "https://www-www.example.org/,\nuser-user\@example.org\n\n";
is($lf->fold($in, 'FIXED'), $out, 'Multiple Prep options are allowed');

1;

