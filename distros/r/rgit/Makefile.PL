use 5.008;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'rgit';

(my $name = $dist) =~ s{-}{::}g;

my %PREREQ_PM = (
 'Carp'       => 0,
 'Cwd'        => 0,
 'Exporter'   => 0,
 'File::Find' => 0,
 'File::Spec' => 0,
 'POSIX'      => 0,
 'base'       => 0,
);

my %META = (
 configure_requires => {
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'Cwd'                 => 0,
  'ExtUtils::MakeMaker' => 0,
  'Exporter'            => 0,
  'File::Spec'          => 0,
  'File::Temp'          => 0,
  'POSIX'               => 0,
  'Test::More'          => 0,
  'base'                => 0,
  %PREREQ_PM,
 },
 recommends => {
  'Term::ReadKey' => 0,
 },
 dynamic_config => 0,
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => 'lib/App/Rgit.pm',
 ABSTRACT         => 'Recursively execute a command on all the git repositories in a directory tree.',
 PL_FILES         => { },
 EXE_FILES        => [ 'bin/rgit' ],
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => 5.008,
 META_MERGE       => \%META,
 dist             => {
  PREOP    => 'pod2text bin/rgit > $(DISTVNAME)/README',
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
 }
);
