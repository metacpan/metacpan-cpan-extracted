# -*- Mode: CPerl -*-
# t/02_basic.t; test basic functionality

use lib qw(. ..); ##-- for debugging

use Test::More tests=>58;
use Tie::File::Indexed;

##-- common variables
my $TEST_DIR = ".";
my $file = "$TEST_DIR/test_basic.dat";
my $n    = 4; ##-- number of elements
my (@a,@w,$w);

##-- 1+1: tie (truncate)
ok(tie(@a, 'Tie::File::Indexed', $file, mode=>'rw'), "tie: rw");

##-- 2+1: batch-store & fetch
@a = @w = map {"val$_"} (0..($n-1));
is_deeply(\@a,\@w, "assign: content");

##-- 3+4: append
ok(untie(@a), "append: untie");
ok(tie(@a, 'Tie::File::Indexed', $file, mode=>'rwa'), "append: tie: rwa");
is(push(@a,'appended'), push(@w,'appended'), "append: push");
is_deeply(\@a,\@w, "append: content");

##-- 7+3: read-only
untie(@a);
ok(untie(@a), "read-only: untie");
ok(tie(@a, 'Tie::File::Indexed', $file, mode=>'r'), "read-only: tie");
is_deeply(\@a,\@w, "read-only: content");

##-- 10+4: index-gaps
untie(@a);
tie(@a, 'Tie::File::Indexed', $file, mode=>'rw');
$a[8]  = 'days a week';
$a[24] = 'hours to go';
is($#a, 24, "gaps: \$#a == 24");
is($a[8], 'days a week', "gaps: \$a[8] eq 'days a week'");
is($a[24], 'hours to go', "gaps: \$a[24] eq 'hours to go'");
is($a[7], '', "gaps: \$a[7] eq ''");

##-- 14+1: overwrite
untie(@a);
tie(@a, 'Tie::File::Indexed', $file, mode=>'rw');
@a = qw(foo bar baz);
$a[1] = 'bonk';
$a[0] = 'blip';
@w    = qw(blip bonk baz);
is_deeply(\@a,\@w, "overwrite: content");

##-- 15+4: consolidate
ok(tied(@a)->consolidate(), "consolidate");
ok(tied(@a)->flush, "consolidate: flush");
is((-s $file), 11, "consolidate: file-size");
is_deeply(\@a,\@w, "consolidate: content");

##-- 19+4: pop
is(pop(@a), pop(@w), "pop");
is(@a, 2, "post-pop: size");
is((-s $file), 8, "post-pop: file-size");
is_deeply(\@a,\@w, "post-pop: content");

##-- 23+3: shift
is(shift(@a), shift(@w), "shift");
is(@a, 1, "post-shift: size");
is_deeply(\@a,\@w, "post-shift: content");

##-- 26+6: splice
@a = @w = (0..3);
is_deeply([splice(@a,1,0,qw(x y))], [splice(@w,1,0,qw(x y))], "splice: add");
is_deeply(\@a,\@w, "splice: add: content");

is_deeply([splice(@a,1,3)], [splice(@w,1,3)], "splice: remove");
is_deeply(\@a,\@w, "splice: remove: content");

is_deeply([splice(@a,1,1,qw(w v))], [splice(@w,1,1,qw(w v))], "slice: add+remove");
is_deeply(\@a,\@w, "slice: add+remove: content");

##-- 32+4: unlink
my @suffs = ('','.idx','.hdr');
sub diskfiles { return [grep {-e $_} @{tiefiles(@_)}] }
sub tiefiles  { my $base=$_[0]//$file; return [map  { "$base$_"} @suffs] }
sub tmpfiles  { my $base=$_[0]//$file; return [map  { "$base$_"} grep {$_ ne '.hdr'} @suffs] }
ok( tied(@a)->unlink, "unlink");
is( tied(@a)->unlink, undef, "unlink2: undef");
is_deeply(diskfiles(), [], "unlink: files");
ok(untie(@a), "unlink: untie");

##-- 36+4: temp
ok(tie(@a, 'Tie::File::Indexed', $file, mode=>'rw', temp=>1) , "temp: tie: rw");
is_deeply(diskfiles(), tmpfiles(), "temp: tie: files");
ok(untie(@a), "temp: untie");
is_deeply(diskfiles(), [], "temp: untie: files");

##-- 40+3: copy: file
tie(@a, 'Tie::File::Indexed', $file, mode=>'rw');
@a = @w = qw(wink wonk whack wallop);
my $bfile = "${file}2";
ok(tied(@a)->copy($bfile), "copy: file");
ok(tie(@b, ref(tied(@a)), $bfile, mode=>'rwa', temp=>1), "copy: file: tie");
is_deeply(\@a,\@b, "copy: file: content");

##-- 43+2: copy: object
untie(@b);  # if (tied(@b)); ##--> untie attempted while 1 inner references still exist at t/02_basic.t line 109.
my $bobj = Tie::File::Indexed->new($bfile, mode=>'rw',temp=>1);
ok(tied(@a)->copy($bobj), "copy: obj");
is_deeply(\@a,[map {$bobj->FETCH($_)} (0..($bobj->FETCHSIZE-1))], "copy: obj: content");
undef $bobj;

##-- 45+4: rename (a->b)
ok(tied(@a)->rename($bfile), "rename");
is(tied(@a)->{file}, $bfile, "rename: filename");
is_deeply(\@a,\@w, "rename: content");
#is_deeply(diskfiles($file),  tiefiles($file),  "rename: files: old"); ##-- no
is_deeply(diskfiles($bfile), tiefiles($bfile), "rename: files: new");

##-- 48+3: move (b->a)
ok(tied(@a)->move($file), "move");
is(tied(@a)->{file}, $file, "move: filename");
is_deeply(\@a,\@w, "move: content");
#is_deeply(diskfiles($bfile), tiefiles($bfile), "move: files: old"); ##-- no
is_deeply(diskfiles($file),  tiefiles($file),  "move: files: new");

##-- 52+4: reopen
ok(tied(@a)->reopen, "reopen/rw");
is(tied(@a)->{file}, $file, "reopen/rw: filename");
is_deeply(\@a,\@w, "reopen/rw: content");

ok(tie(@b, 'Tie::File::Indexed', tied(@a)->{file}, mode=>'r'), "reopen/r: tie");
ok(tied(@b)->reopen, "reopen/r");
is_deeply(\@b,\@a, "reopen/r: content");

# end of t/02_basic.t
