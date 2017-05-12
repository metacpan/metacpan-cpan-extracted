#!perl

use strict;
use warnings;

use Cwd        qw/cwd abs_path/;
use File::Spec (); # catdir, catfile
use File::Temp qw/tempfile tempdir/;

use Test::More;

use App::Rgit::Utils qw/:codes/;
use App::Rgit;

use lib 't/lib';

use App::Rgit::TestUtils qw/can_run_git/;
use App::Rgit::Policy::Callback;

my ($can_run, $reason) = can_run_git;
if ($can_run) {
 plan tests    => 2 + 2 * 4 + 12 * (3 + 1 + 3 + 6);
} else {
 plan skip_all => "Can't run the mock git executable on this system: $reason";
}

sub build {
 my ($tree, $prefix) = @_;

 my @ret;

 my $r = delete $tree->{_};

 while (my ($d, $v) = each %$tree) {
  if (ref $v) {
   my $dir = File::Spec->catdir($prefix, $d);
   mkdir $dir or die "mkdir($dir): $!";

   my @r = build($v, $dir);

   unless ($r) {
    for (@r) {
     push @ret, [
      $_->[0],
      ref eq 'main' ? @{$_}[1 .. 3]
                    : map File::Spec->catdir($d, $_), @{$_}[1 .. 3]
     ];
    }
   }
  } else {
   my $file = File::Spec->catfile($prefix, $d);
   open my $fh, '>', $file or die "open($file): $!";
   print $fh $v;
   close $fh;
  }
 }

 return $r ? bless $r, 'main' : @ret;
}

my $repogit = {
 HEAD    => 1,
 refs    => { dummy => 1 },
 objects => { dummy => 1 },
};

sub repo {
 my ($n, $bare) = @_;

 return $bare ? [ $n, "$n.git",                       "$n.git", "$n.git" ]
              : [ $n, File::Spec->catdir($n, '.git'), $n,       "$n.git" ]
}

my $tmpdir = tempdir(CLEANUP => 1);
my $cwd    = cwd;

chdir $tmpdir or die "chdir($tmpdir): $!";

my @expected = sort { $a->[1] cmp $b->[1] } build({
 x => {
  a => {
   _      => repo('a', 0),
   '.git' => $repogit,
  },
  z => {
   '.git' => {
    refs => { dummy => 1 },
   },
  },
 },
 y => {
  'b.git' => {
   _ => repo('b', 1),
   %$repogit,
  },
  't' => {
   't.git' => {
    refs    => { dummy => 1 },
    objects => { dummy => 1 },
   },
  },
 },
 c => {
  _      => repo('c', 0),
  '.git' => $repogit,
 },
}, '.');

chdir $cwd or die "chdir($cwd): $!";

is @expected,                          3, 'only three valid git repos';
is grep({ ref eq 'ARRAY' } @expected), 3, 'all of them are array references';

@expected = map [
 @$_,
 map(File::Spec->catdir($tmpdir, $_), @{$_}[1 .. 3]),
 $tmpdir,
 '%n', '%x'
], @expected;

sub try {
 my ($cmd, $exp) = @_;

 my ($fh, $filename) = tempfile(UNLINK => 1);

 my $policy = App::Rgit::Policy->new(
  @_ > 2 ? (policy => 'Callback', callback => $_[2])
         : (policy => 'Default')
 );

 my $ar = App::Rgit->new(
  git    => 't/bin/git',
  root   => $tmpdir,
  cmd    => $cmd,
  args   => [ abs_path($filename), $cmd, qw/%n %g %w %b %G %W %B %R %%n %x/ ],
  policy => $policy,
 );
 isa_ok $ar, 'App::Rgit', "each $cmd is an App::Rgit object";

 my $exit;
 my $fail = $cmd eq 'FAIL' ? 1 : 0;
 if ($fail) {
  ($exit, undef) = $ar->run;
 } else {
  $exit = $ar->run;
 }
 is $exit, $fail, "each $cmd returned $fail";

 my @lines = split /\n/, do { local $/; <$fh> };
 my $res   = [ map [ split /\|/, $_ ], @lines ];
 $exp      = [ map [ $cmd, @$_ ], @$exp ];

 for my $i (0 .. $#$exp) {
  my $e = $exp->[$i];
  my $r = shift @$res;
  isnt $r, undef, "each $cmd visited repository $i";

SKIP:
  {
   skip 'didn\'t visited that repo' => 11 unless defined $r;

   s/[\r\n]*$// for @$r;
   for (0 .. 10) {
    is $r->[$_], $e->[$_], "each $cmd argument $_ for repository $i is ok";
   }
  }
 }
}

try 'commit', [ @expected ];
try 'FAIL',   [ $expected[0] ];
try 'FAIL',   [ @expected ],
              sub { NEXT | SAVE };
my $c = 0;
try 'FAIL',   [ map { ($expected[$_]) x 2 } 0 .. $#expected ],
              sub { my $ret = $c ? undef : REDO; $c = 1 - $c; $ret };
