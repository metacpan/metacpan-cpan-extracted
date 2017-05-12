#!perl -w
use strict;

use Test::More tests => 12;

use lib ("lib", "../lib", "t", "../t");
use_ok( 'WordTest' );
ok(WordTest::chdirT(), "Change to t dir");
ok(WordTest::delDoc(), "Pre-delete doc files");
print "\n";





use_ok( 'Win32::Word::Writer' );

ok(my $oWriter = Win32::Word::Writer->new(), "new ok");
ok(my $oWriter2 = Win32::Word::Writer->new(), "new second instance ok");

is($oWriter->SaveAs("01.doc"), 1, "SaveAs ok");
ok(-f "01.doc", " file exists");

is($oWriter->SaveAs("01.doc"), 1, "SaveAs to same file ok");
ok(-f "01.doc", " file exists");

is($oWriter->SaveAs("02.doc"), 1, "SaveAs to other file ok");
ok(-f "02.doc", " file exists");




__END__
