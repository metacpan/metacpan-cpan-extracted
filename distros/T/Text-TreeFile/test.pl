# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Text::TreeFile;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub treecmp;

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $t1fn='demodata/treetest.tre';
my $t1a=
  ['I. Top node in first (or only) tree',[
    ['A. first child of top node in first tree',[
      ['1. first child of first child of top node in first tree',[]],]],
    ['B. second child of top node in first tree',[]],]];
my $t1b=
  [$t1a,
    ['II. Top node in second tree, if in "mult" mode',[
      ['A. first child of top node in second tree',[]],
      ['B. second child of top node in second tree',[
        ['1. first child of second child of top node in second tree',[]],
        ['2. second child of second child of top node in second tree',[]],]],
      ['C. third child of top node in second tree',[]],]],];
my $t2fn='demodata/testfile.tre';
my $t2=
  ['line 01, level 0, yyyyy',[
    ['line 02, level 1, yyyyy',[
      ['line 03, level 2, yyyyy',[]],
      ['line 04, level 2, yyyyy',[]],]],
    ['line 05, level 1, yyyyy',[]],
    ['line 06, level 1, yyyyy',[
      ['line 07, level 2, locallevel 0, xxxxx',[
        ['line 08, level 3, locallevel 1, xxxxx',[]],
        ['line 09, level 3, locallevel 1, xxxxx',[
          ['line 10, level 4, locallevel 2, xxxxx',[]],
          ['line 11, level 4, locallevel 2, xxxxx',[]],]],
        ['line 12, level 3, locallevel 1, xxxxx',[]],]],
      ['line 13, level 2, yyyyy',[]],]],
    ['line 14, level 1, yyyyy',[]],]];

my ($tf,$t,$ret);
$tf=Text::TreeFile->new($t1fn       );$t=$$tf{top};$ret=treecmp(0,$t1a,$t);
print $ret?'':'not ',"ok 2\n";
$t=undef;$tf=undef;
$tf=Text::TreeFile->new($t1fn,'mult');$t=$$tf{top};$ret=treecmp(0,$t1b,$t);
print $ret?'':'not ',"ok 3\n";
$t=undef;$tf=undef;
$tf=Text::TreeFile->new($t2fn       );$t=$$tf{top};$ret=treecmp(0,$t2,$t);
print $ret?'':'not ',"ok 4\n";

sub treecmp { my ($level,$tr1,$tr2)=@_;
  my ($s1,$c1,@c1,$s2,$c2,@c2);
  my $ret=1;my ($bigger,$siz,$diff);my $single=1;my $indent='  'x$level;
  if($level==0) { my ($t1t,$t2t)='node'x2;
    # test for multi-tree top levels and test like children of a normal node
    if(@$tr1 != 2 or ref $$tr1[0] or ref $$tr1[1] ne 'ARRAY') {
      $t1t='list';$single=0; }
    if(@$tr2 != 2 or ref $$tr2[0] or ref $$tr2[1] ne 'ARRAY') {
      $t2t='list';$single=0; }
    if(not $single and ($t1t ne 'node') and ($t2t ne 'node')) {
      ($c1,$c2)=($tr1,$tr2);@c1=@$c1;@c2=@$c2; }
    elsif(not $single) { $ret=0; } }
  if($single) {
    ($s1,$c1,$s2,$c2)=($$tr1[0],$$tr1[1],$$tr2[0],$$tr2[1]);
    @c1=@$c1;@c2=@$c2;
    if($$tr1[0] ne $$tr2[0]) { return 0; } }
  # test count of children and print if no match, but go on
  $diff=0;$bigger='(--oops!--)';$siz=@c1;
  if((scalar @c1) != (scalar @c2)) {
    # note diff and which is bigger
    $diff=@c2-@c1;if($diff<0) { $diff=(-$diff);$siz=@c2;$bigger='first'; }
    else { $siz=@c1;$bigger='second'; } }
  # test each corresp pair of children and note leftovers
  for(my $idx=0;$idx<$siz;++$idx) {
    $ret=0 if not treecmp($level+1,$c1[$idx],$c2[$idx]); } return $ret; }

1;
