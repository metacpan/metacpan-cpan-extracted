# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Text-Unmunch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More   tests=> 12;
use Text::Unmunch;

my $unmunch = Text::Unmunch->new({
                       aff => "en_US.aff",
                       wf => "iren.dic", 
                       sfx => "-s",
                       pfx => "-p",
                       debug    => "-d=2"
                     });
                    
ok( defined $unmunch, "unmunch defined" );
ok( $unmunch->isa('Text::Unmunch'), "class all right");
is( $unmunch->get_aff, "en_US.aff", "aff all right");
is( $unmunch->get_wf,  "iren.dic", "wf all right");
is( $unmunch->get_sfx, "-s", "sfx all right");
is( $unmunch->get_pfx, "-p", "pfx all right");
is( $unmunch->get_debug, "-d=2", "debug all right");

my $var;

open(FH, "iren.dic")or die "Sorry!! couldn't open iren.dic";   
# Reading the file till FH reaches EOF 
while(<FH>) 
{ 
    # Printing one line at a time 
    $var .= $_;
} 
close FH; 

is($var, "civility/IMS\nbestseller/MS", "file iren.dic all right");

open(OLDOUT, ">&STDOUT");
close STDOUT;
open(STDOUT, '>', \$var) || die "Unable to open STDOUT: $!";
$unmunch->get_endings();
close (STDOUT);
open(STDOUT, ">&OLDOUT");
close OLDOUT;

my $cvar = "r_s:1 r_p:1 deb:-d=2 af:en_US.aff wf:iren.dic\ntag = I idx:1\ntag = M idx:20\ncivility's\ntag = S idx:18\ncivilities\nincivility's\nincivilities\ntag = M idx:20\nbestseller's\ntag = S idx:18\nbestsellers\n";


is( $var, $cvar, "civility result ok");

$unmunch->set_debug("-d=0");
close STDOUT;
open(STDOUT, '>', \$var) || die "Unable to open STDOUT: $!";
$unmunch->get_endings();
close (STDOUT);
open(STDOUT, ">&OLDOUT");

$cvar = "civility's\ncivilities\nincivility's\nincivilities\nbestseller's\nbestsellers\n";

is( $var, $cvar, "civility w/o debug result ok");

$unmunch->set_pfx("");
close STDOUT;
open(STDOUT, '>', \$var) || die "Unable to open STDOUT: $!";
$unmunch->get_endings();
close (STDOUT);
open(STDOUT, ">&OLDOUT");

$cvar = "civility's\ncivilities\nbestseller's\nbestsellers\n";

is( $var, $cvar, "civility w/o debug, w/o prefix result ok");

$unmunch->set_sfx("");
close STDOUT;
open(STDOUT, '>', \$var) || die "Unable to open STDOUT: $!";
$unmunch->get_endings();
close (STDOUT);
open(STDOUT, ">&OLDOUT");

$cvar = "civility's\ncivilities\nincivility's\nincivilities\nbestseller's\nbestsellers\n";
is( $var, $cvar, "civility w/o debug, w/o prefix w/o suffix result ok");
