use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN { plan tests => 19 }

# break
foreach my $lang (qw(ar el fr ja ja-a ko ru zh)) {
    dotest_array($lang, $lang);
}    

# urgent
dotest_array('ecclesiazusae', 'ecclesiazusae');
dotest_array('ecclesiazusae', 'ecclesiazusae.ColumnsMax', Urgent => 'FORCE');
dotest_array('ecclesiazusae', 'ecclesiazusae.CharactersMax', CharMax => 79);
dotest_array('ecclesiazusae', 'ecclesiazusae.ColumnsMin',
       ColMin => 7, ColMax => 66, Urgent => 'FORCE');

eval {
    dotest_array('ecclesiazusae', 'ecclesiazusae', Urgent => 'CROAK');
};
ok($@ =~ /^Excessive line was found/, 'CROAK');

# format
foreach my $lang (qw(fr ja)) {
    dotest_array($lang, "$lang.format", Format => sub {
        return "    $_[1]>$_[2]" if $_[1] =~ /^so/;
        return "<$_[1]\n" if $_[1] =~ /^eo/;
        undef });
}
foreach my $lang (qw(fr ko)) {
    dotest_array($lang, "$lang.newline", Format => "NEWLINE");
}    
foreach my $lang (qw(fr ko)) {
    dotest_array($lang, "$lang.newline", Format => "TRIM");
}    


1;

