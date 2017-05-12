# This -*- perl -*- script writes the Makefile for this package.

use strict;
use ExtUtils::MakeMaker;

# Subroutine to check for installed modules.
sub check_version
{
  my ($pkg, $wanted, $msg) = @_;

  local($|) = 1;
  print "Checking for $pkg $wanted...";

  eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };

  no strict 'refs';

  my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
                                 : "not found";
  my $vnum = ${"${pkg}::VERSION"} || 0;

  print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

  $vnum >= $wanted;
}

# Check for needed modules.
check_version('Digest::MD5' => '2.06') or
  warn   "\n"
       . "*** For WebFS::FileCopy you require version 2.06, or later, of\n"
       . "    MD5 from CPAN/authors/id/G/GA/GAAS/Digest-MD5-x.x.tar.gz\n\n";

check_version('Data::Dumper' => '2.081') or
  warn   "\n"
       . "*** For WebFS::FileCopy you require version 2.081, or later, of\n"
       . "    Data::Dumper from CPAN/authors/id/G/GS/GSAR/Data-Dumper-x.x.tar.gz\n\n";

check_version('Net::FTP' => '2.56') or
  warn   "\n"
       . "*** For WebFS::FileCopy you require version 2.56, or later, of\n"
       . "    Net::FTP from CPAN/authors/id/G/GB/GBARR/libnet-1.xxxx.tar.gz\n\n";

check_version('MIME::Base64' => '2.05') or
  warn   "\n"
       . "*** For WebFS::FileCopy you require version 2.05, or later, of\n"
       . "    MIME::Base64 from CPAN/authors/id/G/GA/GAAS/MIME-Base64-x.x.tar.gz.\n\n";

check_version('HTML::Parser' => '2.20') or
  warn   "\n"
       . "*** For WebFS::FileCopy you require version 2.20, or later, of\n"
       . "    HTML::Parser from CPAN/authors/id/G/GA/GAAS/HTML-Parser-x.x.tar.gz.\n\n";

check_version('LWP' => '5.48') or
  warn   "\n"
       . "*** For WebFS::FileCopy you require version 5.48, or later, of\n"
       . "    LWP from CPAN/authors/id/G/GA/GAAS/libwww-perl-x.x.tar.gz.\n\n";

check_version('LWP::Version' => '0.24') or
  warn   "\n"
       . "*** For WebFS::FileCopy you require version 0.24, or later, of\n"
       . "    LWP::Version from CPAN/authors/id/G/GA/GAAS/LWPng-alpha-x.x.tar.gz.\n\n";

check_version('URI' => '1.09') or
  warn   "\n"
       . "*** For WebFS::FileCopy you require version 1.09, or later, of\n"
       . "    URI from CPAN/authors/id/G/GA/GAAS/URI-x.x.tar.gz.\n\n";

WriteMakefile(
  'NAME'	 => 'WebFS::FileCopy',
  'VERSION_FROM' => 'lib/WebFS/FileCopy.pm', # finds $VERSION
  'dist'         => {
    'COMPRESS'   => 'gzip',
    'SUFFIX'     => 'gz'
  },
);	
