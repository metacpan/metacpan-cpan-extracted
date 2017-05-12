BEGIN{
  #Test characters instead of bytes if possible
  if( $] >= 5.006 ){
    eval "use utf8";
    utf8::import();
  }
  $|=1;
  my $t = 7;
  $] < 5.006 ? do{ print "1..$t\n"; require 't/5005-lib.pm'} :
    eval "use Test::More tests => $t; use Test::Differences";
}
use Text::FIGlet;


#0 implicit -d test
my $font = Text::FIGlet->new(-d=>'t/', -f=>'2', -U=>1, -m=>0);

#1A
my $txt1=<<'UNICODE';
 _\_/_ _ \\//
|__  /| | \/ 
  / / | |    
 / /_ | |___ 
/____||_____|
             
UNICODE
$] < 5.006 ? ok(-1, 'SKIPPING Unicode \x in pre-5.6 perl') :
eq_or_diff scalar $font->figify(-A=>"\x{17d}\x{13d}", -U=>1), $txt1, "UTF8 \\x";

#1B
eq_or_diff scalar $font->figify(-A=>"ŽĽ", -U=>1), $txt1, "UTF8 LITERAL";


#2
if( $] < 5.006 ){
  ok(-1, "SKIPPING negative character mapping in pre-5.6 perl"); }
else{
  $ctrl = Text::FIGlet->new(-d=>'t/', -C=>'2.flc') ||
    warn("#Failed to load negative character mapping control file: $!\n");
  my $txt2 = <<'-CHAR';
   
   
 o 
/|/
/| 
\| 
-CHAR
  eq_or_diff scalar $font->figify(-U=>1, -A=>$ctrl->tr('~')), $txt2, "-CHAR";
}


#3 Clean TOIlet
$font = Text::FIGlet->new(-d=>'share', -f=>'future');
my $txt3 = <<'CLEAN';
┏━┓┏━┓┏━┓┏━╸┏━┓
┣━┛┣━┫┣━┛┣╸ ┣┳┛
╹  ╹ ╹╹  ┗━╸╹┗╸
CLEAN
eq_or_diff(~~$font->figify(-A=>'Paper'), $txt3, 'CLEAN TOIlet');


#4 Wrapped TOIlet
#If 3 fails, 4 probably will too
my $txt4 = <<'WRAP';
╻ ╻┏━╸╻  ╻  ┏━┓   ╻ ╻┏━┓┏━┓╻  ╺┳┓
┣━┫┣╸ ┃  ┃  ┃ ┃   ┃╻┃┃ ┃┣┳┛┃   ┃┃
╹ ╹┗━╸┗━╸┗━╸┗━┛   ┗┻┛┗━┛╹┗╸┗━╸╺┻┛
WRAP
my $out = ~~$font->figify(-A=>'Hello World',-w=>240);
eq_or_diff($out, $txt4, 'TOIlet WRAP');


#5&6 Compressed TOIlet
#If 3 fails, 5&6 probably will too
eval {$font = Text::FIGlet->new(-d=>'share', -f=>'emboss') };
exists($INC{'IO/Uncompress/Unzip.pm'}) ?
  ok(ref($font->{_fh}) eq 'IO::Uncompress::Unzip', 'IO::Uncompress:Unzip') :
  ok(                  -1,     "SKIPPING IO::Uncompress:Unzip"); #$@

my $txt6 = <<'TOIlet';
┃ ┃┏━┛┃  ┃  ┏━┃  ┃┃┃┏━┃┏━┃┃  ┏━ 
┏━┃┏━┛┃  ┃  ┃ ┃  ┃┃┃┃ ┃┏┏┛┃  ┃ ┃
┛ ┛━━┛━━┛━━┛━━┛  ━━┛━━┛┛ ┛━━┛━━ 
TOIlet
exists($INC{'IO/Uncompress/Unzip.pm'}) ?
  eq_or_diff(scalar $font->figify(-A=>'Hello World'), $txt6, 'TOIlet Zip') :
  ok(-1, "SKIPPING IO::Uncompress:Unzip");


#7 XXX Compressed FIGlet
