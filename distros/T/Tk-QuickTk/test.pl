# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk::QuickTk;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use Tk;
my $t1=['m MainWindow      title:\'QuickTk Minimal Demo\'',[
         ['mb Frame        side:top fill:x              :',[
           ['f Menubutton  side:left                    : text:File',[
             ['o c         label:Open sub:my($wid)=@_;'
                .'my $out=$$w{mts};my $tf=$$w{mtf};'
                .'$$gl{efile}=$tf->Show;$$gl{eww}=0;'
                .'my $fh=new FileHandle "<$$gl{efile}";'
                .'while(<$fh>) { $out->insert(\'end\',$_); }'
                .'close $fh;$out->yview(\'1.0\');'
                .'print "ok 2\n";',[]],
             ['q c          label:Quit sub:print "ok 8\n";exit;',[]],]],
           ['t Menubutton   side:left                   : text:Tool',[
             ['d c          label:\'Directory Listing\''
               .' sub:$$gl{widgets}{mts}->insert(\'end\','
               .' `pwd`);$$gl{widgets}{mts}->insert(\'end\','
               .' `ls -alF`);print "ok 3\n";',[]],
             ['s c          label:Satisfaction sub:print "ok 4\n";',[]],]],
           ['h Menubutton   side:right                  : text:Help',[
             ['a c          label:About sub:$$gl{widgets}{mts}->insert(\'end\','
               .' \'this is a demo of perl module Tk::QuickTk\');'
               .' print "ok 5\n";',[]],]],]],
         ['tb Frame         side:top fill:x             :',[
           ['d Button       side:left                   : text:Dir'
             .' sub:$$w{mts}->insert(\'end\',`ls -alF`);'
             .' print "ok 6\n";',[]],
           ['q Button       side:left                   : text:Geom'
             .' sub:$$w{mts}->insert(\'end\','
             .' "geom: ".$$w{m}->geometry."\n");'
             .' print "ok 7\n";',[]],]],
         ['ts Scrolled      side:top fill:both expand:1 : Text:'
           .' scrollbars:osoe',[]],
         ['tf FileSelect    nopack                      : '
           .'directory:.',[]],]];
my $t2=<<EOS;

  To complete the test of this module, do the following interactive steps.
Most of them will add information to the bottom of this scrolled window,
which you can view by scrolling down to the end.

  (1) Click on "File", in the menu bar, then on "Open" in the file menu,
      then click on one of the files you see in the FileSelect dialog,
      e.g. "MANIFEST", and then click on the "Accept" button.

  (2) Click on "Tool", in the menu bar, then on "Directory Listing"
      in the tool menu.

  (3) Click on "Tool", in the menu bar, then on "Satisfaction" in the
      tool menu.

  (4) Click on "Help" in the menu bar, then on "About" in the help menu.

  (5) Click on the "Dir" button, in the task bar.

  (6) Click on the "Geom" button, in the task bar.

  (7) Click on "File", in the menu bar, then on "Quit" in the file menu.
EOS
my $app=Tk::QuickTk->new($t1);
$$app{widgets}{mts}->insert('end',$t2);
MainLoop;
print "not ok 8\n";
