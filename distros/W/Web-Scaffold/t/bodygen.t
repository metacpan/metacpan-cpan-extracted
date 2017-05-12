# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Web::Scaffold;
*bodygen = \&Web::Scaffold::bodygen;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

umask 027;
foreach my $dir (qw(tmp)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep($_ ne '.' && $_ ne '..', readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;       # remove files of this name as well
}

my $dir = './tmp';
mkdir $dir,0755;

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

sub gotexp {
  my($got,$exp) = @_;
  if ($exp =~ /\D/) {
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
  } else {
    print "got: $got, exp: $exp\nnot "
        unless $got == $exp;
  }
  &ok;
}

################################################################
################################################################

my $pages = {
    TEST2	=> {
	column	=> [10,20,590],
    },
    TEST3	=> {
    },
};

## test 2	check multi column generation
my $exp = q|<table cellspacing=5 cellpadding=0 border=0 width="1234">
  <tr><td width=10>&nbsp;</td><td width=20>&nbsp;</td><td width=590>&nbsp;</td></tr>
  <tr><td colspan=3>&nbsp;</td></tr>
  <tr><td valign=top class=PT>&nbsp;</td><td valign=top class=PT>&nbsp;</td><td valign=top class=PT>&nbsp;</td></tr></table>|;
my $width = 1234;
my $got = bodygen(undef,$pages,'TEST2',$width,$dir);
gotexp($got,$exp);

## test 3	check default column generation
$exp = q|<table cellspacing=5 cellpadding=0 border=0 width="1234">
  <tr><td width=1234>&nbsp;</td></tr>
  <tr><td colspan=1>&nbsp;</td></tr>
  <tr><td valign=top class=PT>&nbsp;</td></tr></table>|;
$got = bodygen(undef,$pages,'TEST3',$width,$dir);
gotexp($got,$exp);
