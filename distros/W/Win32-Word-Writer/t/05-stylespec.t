#!perl -w
use strict;

use Test::More tests => 9;
use Test::Exception;

use lib ("lib", "../lib", "t", "../t");




use_ok( 'Win32::Word::Writer' );

ok(my $oWriter = Win32::Word::Writer->new(), "new ok");

is($oWriter->StyleSpec(), "Normal", "No spec");

is($oWriter->StyleSpec(heading => 1), "Heading 1", "heading 1");
is($oWriter->StyleSpec(heading => 2), "Heading 2", "heading 2");
is($oWriter->StyleSpec(heading => 6), "Heading 6", "heading 6");

is($oWriter->StyleSpec(style => "Normal"), "Normal", "style Normal");
is($oWriter->StyleSpec(style => "Pellefant"), "Pellefant", "style Pellefant");

is($oWriter->StyleSpec(style => "Pellefant", heading => 2), "Pellefant", "style + heading, style wins");




__END__
