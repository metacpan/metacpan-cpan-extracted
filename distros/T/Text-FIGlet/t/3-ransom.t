BEGIN{
  #Test characters instead of bytes if possible
  if( $] >= 5.006 ){
    eval "use utf8";
    utf8::import();
  }
  $|=1;
  my $t = 4;
  $] < 5.006 ? do{ print "1..$t\n"; require 't/5005-lib.pm'} :
    eval "use Test::More tests => $t; use Test::Differences";
}
use Text::FIGlet;


#1 Known mix, top
$font = Text::FIGlet->new(-d=>'share', -v=>"top",
			  -f=>{undef=>'mini', standard=>qr/[A-Z]/});
#-f{undef=>'future', emboss=>qr/[A-Z]/} is nicer, but requires ZIP

my $pinky = <<'PINKY';
  _____                 
 |_   _| ._   _   _   | 
   | |   |   (_)  /_  o 
   | |                  
   |_|                  
                        
PINKY
eq_or_diff(~~$font->figify(-A=>'Troz!'), $pinky, 'QR FIGlet, TOP');


#2 Known mix, default center
$font = Text::FIGlet->new(-d=>'share',
			  -f=>{undef=>'mini', standard=>qr/[A-Z]/});
#-f{undef=>'future', emboss=>qr/[A-Z]/} is nicer, but requires ZIP

my $brain = <<'BRAIN';
  _____                 
 |_   _|                
   | |   ._   _   _   | 
   | |   |   (_)  /_  o 
   |_|                  
                        
BRAIN
eq_or_diff(~~$font->figify(-A=>'Troz!'), $brain, 'QR FIGlet, CENTER');


#3 Known mix, baseline
$font = Text::FIGlet->new(-d=>'share', -v=>"baseline",
			  -f=>{undef=>'future', standard=>qr/[A-Z]/});
my $cheezes = <<'CHEEZES';
  _____           
 |_   _|          
   | |  ┏━┓┏━┓╺━┓╻
   | |  ┣┳┛┃ ┃┏━┛╹
   |_|  ╹┗╸┗━┛┗━╸╹
                  
CHEEZES
eq_or_diff(~~$font->figify(-A=>'Troz!'), $cheezes, 'QR TOIlet+FIGlet, BASELINE');


#4 Known mix, baseline
$font = Text::FIGlet->new(-d=>'share', -v=>"bottom",
			  -f=>{undef=>'future', standard=>qr/[A-Z]/});
my $plots = <<'PLOTS';
  _____           
 |_   _|          
   | |            
   | |  ┏━┓┏━┓╺━┓╻
   |_|  ┣┳┛┃ ┃┏━┛╹
        ╹┗╸┗━┛┗━╸╹
PLOTS
eq_or_diff(~~$font->figify(-A=>'Troz!'), $plots, 'QR TOIlet+FIGlet, BOTTOM');
#do{y/ /./; print STDERR} foreach (~~$font->figify(-A=>'Troz!'), $plots);
