BEGIN{
	$|=1;
	my $t = 9;
	$] < 5.006 ? do{ print "1..$t\n"; require 't/5005-lib.pm'} :
	eval "use Test::More tests => $t; use Test::Differences"; }
use Text::FIGlet;

$ENV{FIGLIB} = 'share';

#1
ok( defined(my $ctrl = Text::FIGlet->new(-C=>'upper.flc')), 'FIGLIB');


#2
eq_or_diff scalar $ctrl->tr('Hello World'), 'HELLO WORLD', "CTRL";


#3
my $font = Text::FIGlet->new(-m=>0);
my $txt3 = <<'MODE0';
                       _                ___  
 _ __ ___    ___    __| |  ___  _____  / _ \ 
| '_ ` _ \  / _ \  / _` | / _ \|_____|| | | |
| | | | | || (_) || (_| ||  __/|_____|| |_| |
|_| |_| |_| \___/  \__,_| \___|        \___/ 
                                             
MODE0
eq_or_diff scalar $font->figify(-A=>"mode=0"), $txt3, "-m=>0";


#4
my $txt4 = <<'CENTER';
                        ____              _              
                       / ___| ___  _ __  | |_  ___  _ __ 
                      | |    / _ \| '_ \ | __|/ _ \| '__|
                      | |___|  __/| | | || |_|  __/| |   
                       \____|\___||_| |_| \__|\___||_|   
                                                         
CENTER
eq_or_diff scalar $font->figify(-A=>'Center',-x=>'c'), $txt4, "CENTER";


#5
my $txt5 = <<'RIGHT';
                                                    ____   _         _      _   
                                                   |  _ \ (_)  __ _ | |__  | |_ 
                                                   | |_) || | / _` || '_ \ | __|
                                                   |  _ < | || (_| || | | || |_ 
                                                   |_| \_\|_| \__, ||_| |_| \__|
                                                              |___/             
RIGHT
eq_or_diff scalar $font->figify(-A=>'Right',-x=>'r'), $txt5, "RIGHT";


#6
my $txt6 = <<'R2L';
                   _     __        _          _     _    _             _  ____  
                  | |_  / _|  ___ | |   ___  | |_  | |_ | |__    __ _ (_)|  _ \ 
                  | __|| |_  / _ \| |  / _ \ | __| | __|| '_ \  / _` || || |_) |
                  | |_ |  _||  __/| | | (_) || |_  | |_ | | | || (_| || ||  _ < 
                   \__||_|   \___||_|  \___/  \__|  \__||_| |_| \__, ||_||_| \_\
                                                                |___/           
R2L
eq_or_diff scalar $font->figify(-A=>'Right to left',-X=>'R'), $txt6, "R2L";


#7
$font = Text::FIGlet->new(-m=>-1);
my $txt7 = <<'MODE-1';
                          _                          _ 
  _ __ ___     ___     __| |   ___   _____          / |
 | '_ ` _ \   / _ \   / _` |  / _ \ |_____|  _____  | |
 | | | | | | | (_) | | (_| | |  __/ |_____| |_____| | |
 |_| |_| |_|  \___/   \__,_|  \___|                 |_|
                                                       
MODE-1
eq_or_diff scalar $font->figify(-A=>"mode=-1"), $txt7, "-m=>-1";


#8
$font = Text::FIGlet->new(-m=>'-0');
my $txt8 = <<'MODE-0';
   _____         _                                     _    
  |  ___|       (_)        __  __        ___        __| |   
  | |_          | |        \ \/ /       / _ \      / _` |   
  |  _|         | |         >  <       |  __/     | (_| |   
  |_|           |_|        /_/\_\       \___|      \__,_|   
                                                            
__        __     _             _        _          _        
\ \      / /    (_)         __| |      | |_       | |__     
 \ \ /\ / /     | |        / _` |      | __|      | '_ \    
  \ V  V /      | |       | (_| |      | |_       | | | |   
   \_/\_/       |_|        \__,_|       \__|      |_| |_|   
                                                            
MODE-0
eq_or_diff scalar $font->figify(-A=>"Fixed Width"), $txt8, "-m=>-0";


#9
$font = Text::FIGlet->new(-m=>undef);
my $txt9 = <<'MODE-o';
  ___                 _             
 / _ \__   _____ _ __| | __ _ _ __  
| | | \ \ / / _ | '__| |/ _` | '_ \ 
| |_| |\ V |  __| |  | | (_| | |_) |
 \___/  \_/ \___|_|  |_|\__,_| .__/ 
                             |_|    
MODE-o
eq_or_diff scalar $font->figify(-A=>"Overlap"), $txt9, "-m=>undef";
