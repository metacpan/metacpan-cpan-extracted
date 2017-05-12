use strict;
use Win32::Script;
my  @res;
my  @tmp;

tst('!Win32::Script::Echo','running','Win32::Script','tests','...');
tst('FileWrite','test.txt','[sect1]','aa=0',"bb\t=cc",'[sect2]','aa=1','bb = qq');
tst('FileCopy','-f','test.txt','test1.txt');
tst('!FileCompare','test.txt','test1.txt');
tst('FileCRC','test.txt');
tst('FileCwd');
tst('FileEdit','test.txt',sub{s/(aa *= *)(.*)/${1}9/i});
tst('FileFind','*',sub{print " $_,"});
tst('FileGlob','*');
tst('FileHandle','<test.txt',sub{print STDOUT <HANDLE>});
tst('FileIni','test.txt','[sect1]',[aa=>1],[ee=>2,'i'],[ff=>'xx','o']);
tst('FileMkDir','test.dir');
tst('FileWrite','test.dir/aa1.1.txt','xx');
tst('FileWrite','test.dir/bb2.1.txt','xx');
tst('FileWrite','test.dir/cc2.3.txt','xx');
tst('FileNameMax','test.dir/*');
tst('FileNameMin','test.dir/*');
tst('FileRead','test.txt');
tst('FileSize','test.dir');
tst('FileSpace');
tst('FileMkDir','test1.dir');
tst('FileTrack','test.dir','test1.dir');
#
tst('Pause','Press a key and [Enter]');
tst('Platform','os');
tst('Platform','osname');
tst('Platform','ver');
tst('Platform','patch');
tst('Platform','lang');
tst('Platform','prodid');
tst('Platform','windir');
tst('Platform','name');
tst('Platform','host');
tst('Platform','hostdomain');
tst('Platform','user');
tst('Platform','userdomain');
tst('UserPath','');
#
tst('Run','');
#
#
tst('FileDelete','test.txt');
tst('FileDelete','test1.txt');
tst('FileDelete','-r','test.dir');
tst('FileDelete','-r','test1.dir');

####################################################
print "\nTest results\n";
print "-------------\n";
my $errc =0;
foreach my $s (@res) {
  print "$s\n";
  $errc +=1 if $s =~/error:/i;
}
print ($errc ? "-------------\nErrors: $errc\n" : "");

sub tst {
 my $c =shift;
 my $s ="$c\t(" .join(', ',@_) .") ";
 my $e;
 my $r;
 print "[test] $c\t(", join(', ',@_),") ";
 eval("\$r =$c(\@_); \$e =\$@");
 push @res, $s ."\t-> " .($e ? "Error: $e" :$r);
 print "->$r",($e ? "\tError: $e" :''),"\n";
 Pause('----------[Enter]') if $e;
}