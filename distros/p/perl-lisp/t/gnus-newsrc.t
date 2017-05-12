if (-f "newsrc.eld") {
   print "1..4\n";
} else {
   print "1..0\n";
   exit;
}

use strict;
use Gnus::Newsrc;

my $newsrc = Gnus::Newsrc->new("newsrc.eld");

print "not " unless $newsrc->file_version eq "Gnus v5.5";
print "ok 1\n";

print "not " unless $newsrc->last_checked_date eq "Sat Oct 18 14:05:53 1997";
print "ok 2\n";

my $alist = $newsrc->alist;

my @groups;
for (@$alist) {
   push(@groups, $_->[0]);
}
#print "@groups\n";

print "not " unless join(",", @groups) eq "comp.arch,comp.infosystems.www.authoring.cgi,comp.lang.c++.moderated,comp.lang.c.moderated,comp.lang.perl.announce,nnml+private:mail.perl,comp.lang.perl.misc,comp.lang.perl.modules,comp.lang.perl.tk,comp.lang.python";
print "ok 3\n";

my $p5p = $newsrc->alist_hash->{"nnml+private:mail.perl"};
print "not " unless $p5p->[0] == 2 &&
                    $p5p->[1] eq "1-3667" &&
                    $p5p->[4]{'to-list'} eq "perl5-porters\@perl.org";
print "ok 4\n";

#use Data::Dumper;
#print Dumper($p5p);
