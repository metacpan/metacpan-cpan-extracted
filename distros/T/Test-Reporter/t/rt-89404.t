use Test::More tests => 1;

use File::Temp;
use Test::Reporter;
my($ft) = File::Temp->new(TEMPLATE => "bugdemo-XXXX", SUFFIX=>".rpt");
print $ft <<EOF;
From: andreas.koenig.gmwojprw@franz.ak.mind.de
X-Test-Reporter-Distfile: DLAND/BSD-Process-0.07.tar.gz
X-Test-Reporter-Perl: v5.18.0
Subject: FAIL BSD-Process-0.07 amd64-freebsd 9.2-release
Report: This distribution has been tested as part of the CPAN Testers
project, supporting the Perl programming language.  See
http://wiki.cpantesters.org/ for more information or email
questions to cpan-testers-discuss@perl.org


--
Dear David Landgren,
[...]
Summary of my perl5 (revision 5 version 18 subversion 0) configuration:
  Commit id: a9acda3b5f74585852a57b51b724804ac586cb0b
  Platform:
    osname=freebsd, osvers=9.2-release, archname=amd64-freebsd
EOF
$ft->flush;
my $file = $ft->filename;
my $r = Test::Reporter->new(
                            transport => 'Null',
)->read($file);
is $r->{_perl_version}{_archname}, "amd64-freebsd";
