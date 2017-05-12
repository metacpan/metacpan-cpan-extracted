#
# $Id: 1-autoload.t,v 0.2 2007/03/25 21:39:11 dankogai Exp $
#

use strict;
our %Method;
BEGIN { 
    opendir my $dh, "srctxt" or die "srctxt:$!";
    my %keys = ();
    for my $f (readdir($dh)){
	$f =~ s/\.txt$//o or next;
	$Method{$f}++;
    }
    closedir $dh;
}
use Test::More tests => (scalar keys %Method) * 2;

use Unicode::Unihan;
my $db = new Unicode::Unihan;

for my $k (sort keys %Method){
    my $v;
    eval { $v = $db->$k(" "); };
    is($@, "",    qq{\$db->$k});
    is($v, undef, qq{\$db->$k(" ")});
}
__END__
print join("\n", $db->JapaneseKun("\x{5c0f}\x{98fc}\x{3000}\x{5f3e}")), "\n";

