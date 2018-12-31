use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN { plan tests => 6 }

foreach my $lang (qw(fr ja)) {
    dotest($lang, "$lang.format", Format => sub {
	return "    $_[1]>$_[2]" if $_[1] =~ /^so/;
	return "<$_[1]\n" if $_[1] =~ /^eo/;
	undef });
}
foreach my $lang (qw(fr ko)) {
    dotest($lang, "$lang.newline", Format => "NEWLINE");
}    
foreach my $lang (qw(fr ko)) {
    dotest($lang, "$lang.newline", Format => "TRIM");
}    

1;

