package VPIT::TestHelpers;

use strict;
use warnings;

use Config ();

my %exports = (
 load_or_skip     => \&load_or_skip,
 load_or_skip_all => \&load_or_skip_all,
 run_perl         => \&run_perl,
 skip_all         => \&skip_all,
);

sub import {
 my $pkg = caller;

 while (my ($name, $code) = each %exports) {
  no strict 'refs';
  *{$pkg.'::'.$name} = $code;
 }
}

my $test_sub = sub {
 my $sub = shift;

 my $stash;
 if ($INC{'Test/Leaner.pm'}) {
  $stash = \%Test::Leaner::;
 } else {
  require Test::More;
  $stash = \%Test::More::;
 }

 my $glob = $stash->{$sub};
 return $glob ? *$glob{CODE} : undef;
};

sub skip { $test_sub->('skip')->(@_) }

sub skip_all { $test_sub->('plan')->(skip_all => $_[0]) }

sub diag {
 my $diag = $test_sub->('diag');
 $diag->($_) for @_;
}

our $TODO;
local $TODO;

sub load {
 my ($pkg, $ver, $imports) = @_;

 my $spec = $ver && $ver !~ /^[0._]*$/ ? "$pkg $ver" : $pkg;
 my $err;

 local $@;
 if (eval "use $spec (); 1") {
  $ver = do { no strict 'refs'; ${"${pkg}::VERSION"} };
  $ver = 'undef' unless defined $ver;

  if ($imports) {
   my @imports = @$imports;
   my $caller  = (caller 1)[0];
   local $@;
   my $res = eval <<"IMPORTER";
package
        $caller;
BEGIN { \$pkg->import(\@imports) }
1;
IMPORTER
   $err = "Could not import '@imports' from $pkg $ver: $@" unless $res;
  }
 } else {
  (my $file = "$pkg.pm") =~ s{::}{/}g;
  delete $INC{$file};
  $err = "Could not load $spec";
 }

 if ($err) {
  return wantarray ? (0, $err) : 0;
 } else {
  diag "Using $pkg $ver";
  return 1;
 }
}

sub load_or_skip {
 my ($pkg, $ver, $imports, $tests) = @_;

 die 'You must specify how many tests to skip' unless defined $tests;

 my ($loaded, $err) = load($pkg, $ver, $imports);
 skip $err => $tests unless $loaded;

 return $loaded;
}

sub load_or_skip_all {
 my ($pkg, $ver, $imports) = @_;

 my ($loaded, $err) = load($pkg, $ver, $imports);
 skip_all $err unless $loaded;

 return $loaded;
}

sub run_perl {
 my $code = shift;

 my ($SystemRoot, $PATH) = @ENV{qw<SystemRoot PATH>};
 my $ld_name  = $Config::Config{ldlibpthname};
 my $ldlibpth = $ENV{$ld_name};

 local %ENV;
 $ENV{SystemRoot} = $SystemRoot if $^O eq 'MSWin32' and defined $SystemRoot;
 $ENV{PATH}       = $PATH       if $^O eq 'cygwin'  and defined $PATH;
 $ENV{$ld_name}   = $ldlibpth   if $^O eq 'android' and defined $ldlibpth;

 system { $^X } $^X, '-T', map("-I$_", @INC), '-e', $code;
}

package VPIT::TestHelpers::Guard;

sub new {
 my ($class, $code) = @_;

 bless { code => $code }, $class;
}

sub DESTROY { $_[0]->{code}->() }

1;
