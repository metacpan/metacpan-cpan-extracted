######################################################################
# Makefile.PL for Test::Inter
######################################################################

use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker 6.30;

my %IsWin32 = map { $_ => 1 } qw( MSWin32 NetWare symbian );
my $IsWin32 = 1   if ($IsWin32{ $^O });
my $Pvers   = $];
my $ConvVers= $ExtUtils::MakeMaker::VERSION;

my %module_prereq = (
   'Cwd'                      => '0',
   'File::Basename'           => '0',
   'IO::File'                 => '0',
);

my %script_prereq = (
);

my %test_prereq = (
   'File::Find::Rule'         => '0',
   'Test::More'               => '0',
   'Test::Pod'                => '1.00',
   'Test::Pod::Coverage'      => '1.00',
);

my %config_prereq = (
   'ExtUtils::MakeMaker'      => '6.30',
);

%module_prereq = (%module_prereq,%script_prereq);
my $EU_MM_V    = $ExtUtils::MakeMaker::VERSION;
$EU_MM_V       =~ s/_//g;
if ($EU_MM_V < 6.64) {
   %config_prereq = (%config_prereq,%test_prereq);
}

WriteMakefile(
   NAME             => "Test::Inter",
   VERSION          => "1.09",
   ABSTRACT         => "framework for more readable interactive test scripts",
   LICENSE          => "perl",
   ($EU_MM_V >= 6.48
    ? (MIN_PERL_VERSION => "5.006")
    : ()),
   AUTHOR           => "Sullivan Beck (sbeck\@cpan.org)",
   "dist"           => {COMPRESS=>"gzip",SUFFIX=>"gz"},
   PL_FILES         => {},
   PREREQ_PM        => \%module_prereq,
   ($EU_MM_V >= 6.52
    ? (CONFIGURE_REQUIRES => \%config_prereq)
    : ()),
   ($EU_MM_V >= 6.64
    ? (TEST_REQUIRES   => \%test_prereq)
    : ()),
   ($EU_MM_V > 6.45
    ? (META_ADD => {
          provides     => {
             'Test::Inter' => {
                file    => 'lib/Test/Inter.pm',
                version => '1.09',
             },

          },
       }
      )
    : ()),

   ($EU_MM_V > 6.46
    ? (META_MERGE => {
          'meta-spec'  => {
             version   => 2,
          },
          resources    => {
             repository => {
                type => 'git',
                web  => 'https://github.com/SBECK-github/Test-Inter',
                url  => 'git://github.com/SBECK-github/Test-Inter.git',
             },
          },
       }
      )
    : ()),




);
