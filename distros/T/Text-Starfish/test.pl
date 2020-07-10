# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#########################

use Test;
BEGIN { plan tests => 46 };
use Text::Starfish;
use File::Copy;
use Carp;
use Cwd;

my $comment_width = 14;
sub cmt_print { my $c=shift; while (length($c)<$comment_width) {
  $c.='.'; } print "$c: "; }

&my_mkdir('tmp', 'tmp/Text');
copy('Starfish.pm','tmp/Text/Starfish.pm');
{
    my $f = getfile('starfish');
    $f =~ s<^#!/usr/bin/perl>{#!/usr/bin/perl -I../blib/lib} or die;
    putfile('tmp/starfish', $f);
}
chdir 'tmp' or die;

&cmt_print("01-use test"); ok(1);

# Slash hack was added because the Windows terminal evaluates does not
# evaluate $vars (the use a %varname% form instead) and therefore would
# not require the extra escape character at the beginning of the variable.
my $slash_hack;
if ($^O =~ m/MSWin/) { $slash_hack = '';   }
else                 { $slash_hack = '\\'; }

&testcase('02-simple_java'); # a simple Java example
&testcase('03-simple_java'); # a simple Java example, related to previous
&testcase('04-simple_java', 'replace'); # a simple Java example, replace mode
&testcase('05-simple_java', 'replace'); # a simple Java example, replace mode
&testcase('06-addHook', 'replace'); # 01->06-addHook

if (&is_module_available('CGI')) {
  &testcase('07-html-cgi', 'replace'); # requires CGI module
} else {
  &cmt_print('07-html-cgi'); ok(1);
  print "\t07-html-cgi skipped - CGI module not available\n"; }

&testcase('08-tex', 'replace');
&testcase('09-text', 'replace');
&testcase('10-tex');
&testcase('11-make');
&testcase('12-make');
&testcase('13-html', 'replace');
&testcase('14-text');
&testcase('15-text');
&testcase('16-rmHook');
&testcase('17-A_java');
&testcase('18-p_t_java', 'out');
&testcase('19-p_t_java', 'out', '-e=$Release=1');
&testcase('20-simple_html');

$testnum = '21-make'; &prep_dir_cd($testnum);
my $testdir = "test-$testnum";
my $testfilesdir = "../../testfiles/$testnum";
my $insource = "$testfilesdir/Makefile.in"; my $inorig = "Makefile.in";
my $procfile = "Makefile";
my $outsource = "$testfilesdir/Makefile.out";
my $outExpected = "Makefile.out-expected";
mycopy($insource, $inorig);
mycopy($insource, $procfile);
mycopy($outsource, $outExpected);
for (qw(A B C)) { mycopy("$testfilesdir/$_.java", "$_.java"); }
my @sfishArgs = ( $procfile );
my $outNew = $procfile;
putfile('test-description', '# CWD: '.getcwd()."\n".
	"# Test preparation:\n".
	"# cp $insource $inorig\n".
	"# cp $insource $procfile\n".
	"# cp $outsource $outExpected\n".
	"# cp $testfilesdir/A.java A.java\n".
	"# cp $testfilesdir/B.java B.java\n".
	"# cp $testfilesdir/C.java C.java\n".
	"# #option: perl -I. -- starfish @sfishArgs\n".
	"# starfish_cmd( @sfishArgs );\n".
	"# diff $outExpected $outNew\n".
	"# If test needs to be updated, input:\n".
	"# cp $inorig $insource\n".
	"# Output:\n".
	"# cp $outNew $outsource\n");
starfish_cmd( @sfishArgs );
comparefiles($outExpected, $outNew);
chdir '..' or die;

$testnum = '22-hooks'; &prep_dir_cd($testnum);
my $testfilesdir = "../../testfiles/$testnum";
my $insource = "$testfilesdir/text.in"; my $inorig = "text.in";
my $procfile = "text.txt";
my $outsource = "$testfilesdir/text.out";
my $outExpected = "text.out-expected";
my $outsourceR = "$testfilesdir/text-replace.out";
my $outExpectedR = "text-replace.out-expected";
my $procReplace = "text-replace.out";
mycopy($insource, $inorig);
mycopy($insource, $procfile);
mycopy($outsource, $outExpected);
mycopy($outsourceR, $outExpectedR);
mycopy("$testfilesdir/Makefile", "Makefile");
my @sfishArgs = ( $procfile );
my @sfishArgs1 = ( $procfile, '-replace', "-o=$procReplace");
my $outNew = $procfile;
putfile('test-description', '# CWD: '.getcwd()."\n".
	"# Test preparation:\n".
	"# cp $insource $inorig\n".
	"# cp $insource $procfile\n".
	"# cp $outsource $outExpected\n".
	"# cp $testfilesdir/text-replace.out text-replace.out-expected\n".
	"# #option: perl -I. -- starfish @sfishArgs\n".
	"# starfish_cmd( @sfishArgs );\n".
	"# diff $outExpected $outNew\n".
	"# #option: perl -I. -- starfish @sfishArgs1\n".
	"# starfish_cmd( @sfishArgs1 );\n".
	"# diff $outExpectedR $procReplace\n".
	"# If test needs to be updated, input:\n".
	"# cp $inorig $insource\n".
	"# Output:\n".
	"# cp $outNew $outsource\n".
        "# cp $procReplace $outsourceR\n");
starfish_cmd( @sfishArgs );
comparefiles($outExpected, $outNew);
&cmt_print('22-hooks(2)');
starfish_cmd( @sfishArgs1 );
comparefiles('text-replace.out-expected', 'text-replace.out');
&cmt_print('22-hooks(3)'); # Running second time
starfish_cmd( @sfishArgs );
comparefiles($outExpected, $outNew);
&cmt_print('22-hooks(4)');
starfish_cmd( @sfishArgs1 );
comparefiles('text-replace.out-expected', 'text-replace.out');
chdir '..' or die;

&testcase(6, 'out');
&testcase(8);
&testcase(9, 'out');
&testcase(30); # html.sfish to html (16 ok)

&cmt_print('(ok 26)');
copy('../testfiles/9_java.out', '9_java.out');
starfish_cmd(qw(-o=10_java.out -e=$Starfish::HideMacros=1 9_java.out));
ok(getfile('10_java.out'),
   getfile("../testfiles/10_java.out"));

&cmt_print('(ok 27)'); # Macros testing
copy('../testfiles/10_java.out', '10.java');
starfish_cmd(qw(-o=11_java.out 10.java));
ok(getfile('11_java.out'),
   getfile("../testfiles/11_java.out"));

&cmt_print('(ok 28)'); # option mode testing
`echo "OSNAME | $OSNAME |"`;
# Skip if it is windows
if ($^O =~ m/MSWin/) {
  skip('Skipped under windows...');
}
else {
  copy('../testfiles/10_java.out', '12.java');
  #`perl -I. -- starfish -o=12.out -mode=0444 12.java`;
  starfish_cmd(qw(-o=12.out -mode=0444 12.java));
  #my $tmp = `ls -l 12.out|sed 's/ .*//'`;
  #my $tmp = `stat -c %a 12.out`;
  # checking permissions
  my $tmp = sprintf("%o", 0777 & (stat '12.out')[2]);
  chmod 0600, '12.out';
  ok($tmp, "444");
}

&testcase(13, 'out'); # ok 24 # macros

# 14
&cmt_print('(ok 30)');
copy('../testfiles/13_java.in','14.java');
#`perl -I. -- starfish -o=14.out -e="$slash_hack\$Star::HideMacros=1" 14.java`;
starfish_cmd(qw(-o=14.out -e=$Star::HideMacros=1 14.java));
comparefiles('../testfiles/14.out', '14.out');

# 15,16
&cmt_print('(ok 31)');
copy('../testfiles/15.java','tmp.java');
`$^X -I. -- starfish -o=tmp.ERR -e="$slash_hack\$Star::HideMacros=1" tmp.java>tmp1 2>&1`;
ok($? != 0);
&cmt_print('(ok 32)');
okfiles('../testfiles/15.out', 'tmp1');

# 17, old 16 # multiple files
$testnum='37-tex-multif'; &prep_dir_cd($testnum);
my $testfilesdir = "../../testfiles";
mycopy("$testfilesdir/16develop.SLeP", 'tmp.SLeP');
mycopy("$testfilesdir/16develop.SLeP", 'orig-tmp.SLeP');
mycopy("$testfilesdir/16.tex", 'tmp.tex');
mycopy("$testfilesdir/16.tex", 'orig-tmp.tex');
mycopy("$testfilesdir/16.out", '16.out');
my @sfishArgs= qw(tmp.SLeP tmp.tex);
# `$^X -I. -- ../starfish tmp.SLeP tmp.tex`;
putfile('test-description', '# CWD: '.getcwd()."\n".
	"# Test preparation:\n".
	"# cp $testfilesdir/16develop.SLeP tmp.SLeP\n".
	"# cp $testfilesdir/16develop.SLeP orig-tmp.SLeP\n".
	"# cp $testfilesdir/16.tex tmp.tex\n".
	"# cp $testfilesdir/16.tex orig-tmp.tex\n".
	"# cp $testfilesdir/16.out 16.out\n".
	"# opt: $^X -I. -- ../starfish tmp.SLeP tmp.tex\n".
	"# starfish_cmd( @sfishArgs ); \n".
	"# cat tmp.SLeP tmp.tex > tmp1\n".
	"# diff 16.out tmp1\n");
starfish_cmd( @sfishArgs );
#if ($^O =~ m/MSWin/) {
#  `copy /B /Y tmp.SLeP+tmp.tex tmp1`;
#}
#else {
#  `cat tmp.SLeP tmp.tex>tmp1`;
#}
putfile "tmp1", (getfile("tmp.SLeP").getfile("tmp.tex"));
okfiles("16.out", 'tmp1');
chdir '..' or die;

# 20, old 19
&cmt_print('(ok 38)');
if ($^O =~ m/MSWin/) {
  skip('Skipped under windows...');
} else {
  copy('../testfiles/19.html', 'tmp.html');
  #`$^X -I. -- starfish -replace -o=tmp2 -mode=0644 tmp.html`;
  starfish_cmd(qw(-replace -o=tmp2 -mode=0644 tmp.html));
  # checking permissions
  #`ls -l tmp2|sed 's/ .*//'>tmp1`;
  my $tmp = sprintf("%o", 0777 & (stat 'tmp2')[2]);
  ok($tmp, "644");
}

# 21, old 20 has to be done after previous
&cmt_print('(ok 39)');
if ($^O =~ m/MSWin/) {
  skip('Skipped under windows...');
} else {
  #`$^X -I. -- starfish -replace -o=tmp2 tmp.html`;
  starfish_cmd(qw(-replace -o=tmp2 tmp.html));
  # checking permissions
  #`ls -l tmp2|sed 's/ .*//'>tmp1`;
  my $tmp = sprintf("%o", 0777 & (stat 'tmp2')[2]);
  ok($tmp, "644");
}

# 22, old 21
&cmt_print('(ok 40)');
copy('../testfiles/21.html','tmp2.html');
`$^X -I. -- starfish -replace -o=tmp1 tmp2.html`;
okfiles('../testfiles/21.out', 'tmp1');

&testcase(22);    
&testcase(24);

#copy('../testfiles/24.py','24.py');
#`$^X -I. -- starfish 24.py`;
#okfiles('../testfiles/24.py.out', '24.py');

# 26
&cmt_print('(ok 43)');
copy('../testfiles/26_include_example.html','26_include_example.html');
copy('../testfiles/26_include_example1.html','26_include_example1.html');
starfish_cmd(qw(-replace -o=26-out.html 26_include_example.html));
okfiles('../testfiles/26-out.html', '26-out.html');

# 33
&testcase(33, 'in:33_tex.in->33.tex -replace -o=33-lecture.tex');
&testcase(34, 'in:33_tex.in->34.tex -replace -o=34-slides.tex');
&testcase(35, 'in:35_tex.in->35.tex -replace -o=35-slides.tex');

########################################################################
# Subroutines used in testing script

sub prep_dir_cd {
  my $testnum = shift; &cmt_print($testnum); my $testdir = "test-$testnum";
  # comment out next line for testcase debugging
  if (-d $testdir) { &rm_dir_recursively($testdir) }
  &my_mkdir($testdir); chdir $testdir or die; }

sub okfiles {
  my $f1 = shift;
  while (@_) {
    my $f2 = shift;
    if (!-f $f1)
    { die "file $f1 does not exist (to be compared to tmp/$f2)"	}
    if (! ok(getfile($f2), getfile($f1)) )
    { print TESTLOG "cwd=".getcwd()."Files: $f1 and $f2\n" }}}

# $testnum  - test id, starting with number, but could have a suffix; e.g. 01-a
# $infile   - name of the original input test file (in testdir)
# $procfile - name of the input file when starfish is run on it
# $outfile  - name of the expected outfile in the testdir
# @args     - additional sfish arguments
sub testcase {
  my $testnum = shift; &prep_dir_cd($testnum);
  my ($infile, $procfile, $replace, $out, $outfile, @args);
  my $testdir = "test-$testnum";
  my $testfilesdir = '../../testfiles';

  # example: &testcase(34, 'in:33_tex.in->34.tex -replace -o=34-slides.tex');
  if ($#_==0 && $_[0] =~ /^in:(\S*)->(\S*) -replace -o=(\S*)$/) {
    $infile = $1; $procfile = $2; $outfile = $replace = $3;
  }
  elsif ( -e "$testfilesdir/$testnum.in" and $#_==-1) {
    $infile   = "$testnum.in";
    $procfile = "$testnum.in";
    $outfile  = "$testnum.out";
    if ($testnum =~ /_(java|html)$/) {
      my $ext = $1; $procfile = "$`.$ext"; }
  }
  elsif ( -e "$testfilesdir/$testnum.in" and $#_==0 and $_[0] eq 'out') {
    $infile   = "$testnum.in";
    $procfile = "$testnum.in";
    $outfile  = "$testnum.out";
    $out = $outfile;
    if ($testnum =~ /^\d+-(\w.*)_java$/) {
      $procfile = "$1.java"; $out = "$1_out.java" }
  }
  elsif ( -e "$testfilesdir/$testnum.in" and $#_==1 and $_[0] eq 'out'
	  and $_[1]=~ /^-e=/) {
    $infile   = "$testnum.in";
    $procfile = "$testnum.in";
    $outfile  = "$testnum.out";
    $out = $outfile;
    push @args, $_[1];
    if ($testnum =~ /^\d+-(\w.*)_java$/) {
      $procfile = "$1.java"; $out = "$1_out.java" }
  }
  elsif ( -e "$testfilesdir/$testnum.in" and
	    $#_==0 and $_[0] eq 'out' ) {
	$infile   = "$testnum.in";
	$procfile = "$testnum.in";
	$outfile  = "$testnum.out";
	$out      = "$testnum.out";
    }
    elsif ( -e "$testfilesdir/$testnum.in" and
	    $#_==0 and $_[0] eq 'replace' ) {
      $infile   = "$testnum.in";
      $procfile = "$testnum.in";
      $outfile  = "$testnum.out";
      $replace  = "$testnum.out";
      if ($testnum =~ /_java$/) {
	$procfile = "$`.java";
	$replace = "$`_out.java";
      }
    }
    elsif ( -e "$testfilesdir/${testnum}_html.in" ) {
	$infile = "${testnum}_html.in";
	$procfile = "$testnum.html";
	$outfile = "${testnum}_html.out";
        if ($#_ > -1 and $_[0] eq 'replace')
	{  $replace = "${testnum}_out.html" }
    }
    elsif ( -e "$testfilesdir/${testnum}_Makefile.in" ) {
	$infile = "${testnum}_Makefile.in";
	$procfile = "Makefile";
	$outfile = "${testnum}_Makefile.out";
        if ($#_ > -1 and $_[0] eq 'replace')
	{  $replace = "${testnum}_Makefile.out" }
    }
    elsif ( -e "$testfilesdir/${testnum}_tex.in" ) {
	my $ext = $1;
	$infile = "${testnum}_tex.in";
	$procfile = "$testnum.tex";
	$outfile = "${testnum}_tex.out";
        if ($#_ > -1 and $_[0] eq 'replace')
	{  $replace = "${testnum}_out.tex" }
    }
    elsif ( -e "$testfilesdir/${testnum}.html.sfish" ) {
      $infile = "${testnum}.html.sfish";
      $procfile = "$testnum.html.sfish";
      $replace = "$testnum.html";
      $outfile = "${testnum}_html.out";
    }
    elsif ( -e "$testfilesdir/${testnum}_java.in" and
	    $#_==0 and $_[0] eq 'out' ) {
	$infile = "${testnum}_java.in";
	$procfile = "$testnum.java";
	$outfile = "${testnum}_java.out";
	$out     = "${testnum}_java.out";
    }
    elsif ( -e "$testfilesdir/${testnum}.py" and
	    -e "$testfilesdir/${testnum}.py.out" ) {
	$infile = "${testnum}.py";
	$procfile = "$testnum.py";
	$outfile = "${testnum}.py.out";
    }
    else { die "Test files not found" }

  mycopy("$testfilesdir/$infile", "$infile-orig");
  mycopy("$testfilesdir/$infile", $infile);
  if ($infile ne $procfile) { mycopy("$testfilesdir/$infile", $procfile); }
  my $outExpected = "$outfile-expected";
  my $outfile_masked = $outfile;
  $outfile_masked =~ s/\.tex$/_tex.out/;
  if (!-f "$testfilesdir/$outfile" && -f "$testfilesdir/$outfile_masked")
  { mycopy("$testfilesdir/$outfile_masked", "$outfile-expected"); }
  else
  { mycopy("$testfilesdir/$outfile", "$outfile-expected"); }
    my $outNew      = $procfile;
    my @sfishArgs = ( '-e=$ver="testver"', $procfile );
    if ($replace) {
      @sfishArgs = ('-e=$ver="testver"', '-replace', "-o=$replace", $procfile);
      $outNew = $replace;
    }
    elsif ($out) {
      @sfishArgs = ('-e=$ver="testver"', "-o=$out", @args, $procfile);
      $outNew = $out;
    }

    putfile('test-description', '# CWD: '.getcwd()."\n".
	    "# Test preparation:\n".
	    "# cp $testfilesdir/$infile $infile-orig\n".
	    "# cp $testfilesdir/$infile $procfile\n".
	    "# cp $testfilesdir/$outfile $outfile-expected\n".
	    "# #option: perl -I. -- starfish @sfishArgs\n".
	    "# starfish_cmd( @sfishArgs );\n".
	    "# diff $outExpected $outNew\n".
	    "# If test needs to be updated, input:\n".
	    "# cp $infile-orig $testfilesdir/$infile\n".
	    "# Output:\n".
	    "# cp $outNew $testfilesdir/$outfile\n");
    starfish_cmd( @sfishArgs );
    comparefiles($outExpected, $outNew);
    
    chdir '..' or die;
}

sub comparefiles {
  my $f1 = shift;
  if (!-f $f1)
  { print STDERR "Error: file $f1 does not exist\n"; ok(0); return; }
  my $fc1 = getfile($f1);
  while (@_) {
    my $f2 = shift;
    if (!-f $f2)
    { print STDERR "Error: file $f2 does not exist\n"; ok(0); return; }
    my $fc2 = getfile($f2);
    if ($fc1 eq $fc2) { next; }
    print STDERR "CWD: ".getcwd()."\nDifference between $f1 and $f2:\n";
    while ($fc1 ne '' or $fc2 ne '') {
      $fc1=~/^.*\n/; my $l1=$&; my $fc1r=$';
      $fc2=~/^.*\n/; my $l2=$&; my $fc2r=$';
      if ($l1 eq '' and $l2 eq '') {
      print STDERR "$f1:$fc1", "$f2:$fc2"; last; }
      if ($l1 ne $l2) { print STDERR "$f1:$l1", "$f2:$l2" }
      $fc1=$fc1r; $fc2=$fc2r;
    }
    print STDERR "Test failed.\n";
    ok(0); # File comparison failed
    return;
  }
  ok(1);
}

sub is_module_available {
  my $module = shift; eval qq{require $module};
  return '' if $@; return 1;
}

sub rm_dir_recursively { my $d=shift; system('rm', '-rf', $d); }

sub my_mkdir {
  for my $d (@_) { next if -d $d;
    mkdir $d, 0700 or die "can't mkdir $d: $!" } }

sub mycopy {
  my $f1 = shift; my $f2 = shift;
  if (!-f $f1) { die "File $f1 does not exist." }
  copy($f1, $f2);
}

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}
