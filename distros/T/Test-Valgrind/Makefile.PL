use 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

use Config;
use File::Spec;

sub validate_exe {
 my ($name, $preferred_path) = @_;

 my (@candidates, @args);
 if (File::Spec->file_name_is_absolute($name)) {
  # No need to look for args if the name is absolute.
  @candidates = $name;
 } else {
  my @path;
  if (defined $preferred_path) {
   @path = ($preferred_path, grep { $_ ne $preferred_path } File::Spec->path);
  } else {
   @path = File::Spec->path;
  }

  (my $base, @args) = split ' ', $name;
  for my $path_entry (@path) {
   my ($vol, $dir, $file) = File::Spec->splitpath($path_entry, 1);
   next if defined $file and length $file;
   push @candidates, File::Spec->catpath($vol, $dir, $base);
  }
 }

 for my $path (@candidates) {
  my $command = MM->maybe_command($path);
  if (defined $command) {
   $command .= " @args" if @args;
   return $command;
  }
 }

 return;
}

sub check_exe {
 my (%args) = @_;

 my $desc           = delete $args{desc};
 my $arg_var        = delete $args{arg_var};
 my $tries          = delete $args{try};
 my $preferred_path = delete $args{preferred_path};

 my $exe;

 for (@ARGV) {
  if (/^\Q$arg_var\E=(.*)/) {
   $exe = validate_exe($1, $preferred_path);
   last if defined $exe;
  }
 }

 if (defined $exe) {
  print "Forcing the use of $exe as the $desc.\n";
 } else {
  print "Checking for a valid $desc in the PATH... ";
  for my $try (@$tries) {
   next unless defined $try;
   $exe = validate_exe($try, $preferred_path);
   last if defined $exe;
  }
  if (defined $exe) {
   print "$exe\n";
  } else {
   print "none\n";
  }
 }

 return $exe;
}

my %PARAMS;

my $cc = check_exe(
 desc    => 'C compiler',
 arg_var => 'CC',
 try     => [ $Config{cc}, $ENV{CC}, 'cc' ],
);
if (defined $cc) {
 my ($vol, $dir, $file) = File::Spec->splitpath($cc);
 my $preferred_path = File::Spec->catpath($vol, $dir, '');
 my $ld = check_exe(
  desc           => 'linker',
  arg_var        => 'LD',
  try            => [ $Config{ld}, $ENV{LD}, 'ld' ],
  preferred_path => $preferred_path,
 );
 if (defined $ld) {
  my $xs  = 'Valgrind.xs';
  (my $c  = $xs) =~ s/\.xs$/.c/;
  my $opt = $Config{optimize};
  $opt    =~ s/-O\S*//g;
  $opt   .= ' -O0 -g';
  $PARAMS{C}        = [ $c ];
  $PARAMS{XS}       = { $xs => $c };
  $PARAMS{CC}       = $cc;
  $PARAMS{LD}       = $ld;
  $PARAMS{OPTIMIZE} = $opt;
 }
}

unless ($PARAMS{C}) {
 $PARAMS{C}      = [ ];
 $PARAMS{XS}     = { };
 $PARAMS{OBJECT} = '';
}

my $dist = 'Test-Valgrind';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my %PREREQ_PM = (
 'Carp'                  => 0,
 'Digest::MD5'           => 0,
 'Env::Sanctify'         => 0,
 'ExtUtils::MM'          => 0,
 'File::HomeDir'         => '0.86',
 'File::Path'            => 0,
 'File::Spec'            => 0,
 'File::Temp'            => '0.19', # ->newdir in tests
 'Filter::Util::Call'    => 0,
 'Fcntl'                 => 0,
 'IO::Select'            => 0,
 'List::Util'            => 0,
 'POSIX'                 => 0,
 'Perl::Destruct::Level' => 0,
 'Scalar::Util'          => 0,
 'Test::Builder'         => 0,
 'Test::More'            => 0,
 'XML::Twig'             => 0,
 'base'                  => 0,
 'overload'              => 0,
);

my %CONFIGURE_REQUIRES = (
 'Config'              => 0,
 'ExtUtils::MakeMaker' => 0,
 'File::Spec'          => 0,
);

my %BUILD_REQUIRES = (
 %CONFIGURE_REQUIRES,
 'File::Temp'          => '0.19', # ->newdir in tests
 'IO::Handle'          => 0,
 'IO::Select'          => 0,
 'IPC::Open3'          => 0,
 'Socket'              => 0,
 'Test::More'          => 0,
 'base'                => 0,
 'lib'                 => 0,
 %PREREQ_PM,
);

my %META = (
 configure_requires => {
  %CONFIGURE_REQUIRES,
 },
 build_requires => {
  %BUILD_REQUIRES,
 },
 recommends => {
  'DynaLoader' => 0,
  'XSLoader'   => 0,
 },
 dynamic_config => 1,
 resources => {
  bugtracker => "http://rt.cpan.org/Dist/Display.html?Name=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 BUILD_REQUIRES   => \%BUILD_REQUIRES,
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => '5.006',
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text -u $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz',
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt*"
 },
 %PARAMS,
);
