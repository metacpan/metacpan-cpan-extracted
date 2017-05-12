package VPIT::TestHelpers;

use strict;
use warnings;

use Config ();

sub export_to_pkg {
 my ($subs, $pkg) = @_;

 while (my ($name, $code) = each %$subs) {
  no strict 'refs';
  *{$pkg.'::'.$name} = $code;
 }

 return 1;
}

my %default_exports = (
 load_or_skip     => \&load_or_skip,
 load_or_skip_all => \&load_or_skip_all,
 run_perl         => \&run_perl,
 skip_all         => \&skip_all,
);

my %features = (
 threads => \&init_threads,
 usleep  => \&init_usleep,
);

sub import {
 shift;
 my @opts = @_;

 my %exports = %default_exports;

 for (my $i = 0; $i <= $#opts; ++$i) {
  my $feature = $opts[$i];
  next unless defined $feature;

  my $args;
  if ($i < $#opts and defined $opts[$i+1] and ref $opts[$i+1] eq 'ARRAY') {
   ++$i;
   $args = $opts[$i];
  } else {
   $args = [ ];
  }

  my $handler = $features{$feature};
  die "Unknown feature '$feature'" unless defined $handler;

  my %syms = $handler->(@$args);

  $exports{$_} = $syms{$_} for sort keys %syms;
 }

 export_to_pkg \%exports => scalar caller;
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

 if ($code =~ /"/) {
  die 'Double quotes in evaluated code are not portable';
 }

 my ($SystemRoot, $PATH) = @ENV{qw<SystemRoot PATH>};
 my $ld_name  = $Config::Config{ldlibpthname};
 my $ldlibpth = $ENV{$ld_name};

 local %ENV;
 $ENV{$ld_name}   = $ldlibpth   if                      defined $ldlibpth;
 $ENV{SystemRoot} = $SystemRoot if $^O eq 'MSWin32' and defined $SystemRoot;
 $ENV{PATH}       = $PATH       if $^O eq 'cygwin'  and defined $PATH;

 my $perl = $^X;
 unless (-e $perl and -x $perl) {
  $perl = $Config::Config{perlpath};
  unless (-e $perl and -x $perl) {
   return undef;
  }
 }

 system { $perl } $perl, '-T', map("-I$_", @INC), '-e', $code;
}

sub init_threads {
 my ($pkg, $threadsafe, $force_var) = @_;

 skip_all 'This perl wasn\'t built to support threads'
                                            unless $Config::Config{useithreads};

 $pkg = 'package' unless defined $pkg;
 skip_all "This $pkg isn't thread safe" if defined $threadsafe and !$threadsafe;

 $force_var = 'PERL_FORCE_TEST_THREADS' unless defined $force_var;
 my $force  = $ENV{$force_var} ? 1 : !1;
 skip_all 'perl 5.13.4 required to test thread safety'
                                             unless $force or "$]" >= 5.013_004;

 if (($INC{'Test/More.pm'} || $INC{'Test/Leaner.pm'}) && !$INC{'threads.pm'}) {
  die 'Test::More/Test::Leaner was loaded too soon';
 }

 load_or_skip_all 'threads',         $force ? '0' : '1.67', [ ];
 load_or_skip_all 'threads::shared', $force ? '0' : '1.14', [ ];

 require Test::Leaner;

 diag "Threads testing forced by \$ENV{$force_var}" if $force;

 return spawn => \&spawn;
}

sub init_usleep {
 my $usleep;

 if (do { local $@; eval { require Time::HiRes; 1 } }) {
  defined and diag "Using usleep() from Time::HiRes $_"
                                                      for $Time::HiRes::VERSION;
  $usleep = \&Time::HiRes::usleep;
 } else {
  diag 'Using fallback usleep()';
  $usleep = sub {
   my $s = int($_[0] / 2.5e5);
   sleep $s if $s;
  };
 }

 return usleep => $usleep;
}

sub spawn {
 local $@;
 my @diag;
 my $thread = eval {
  local $SIG{__WARN__} = sub { push @diag, "Thread creation warning: @_" };
  threads->create(@_);
 };
 push @diag, "Thread creation error: $@" if $@;
 diag @diag;
 return $thread ? $thread : ();
}

package VPIT::TestHelpers::Guard;

sub new {
 my ($class, $code) = @_;

 bless { code => $code }, $class;
}

sub DESTROY { $_[0]->{code}->() }

1;
