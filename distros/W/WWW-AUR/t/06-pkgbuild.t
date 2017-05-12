#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More tests => 13;

use WWW::AUR::PKGBUILD;
use WWW::AUR::Package;
use Scalar::Util qw(blessed);

*unquote_bash = *WWW::AUR::PKGBUILD::_unquote_bash;

my ($empty) = unquote_bash( q{ <-- Space should fail!} );
is $empty, q{};

my $str;
($str) = unquote_bash( "HI" );
is $str, q{HI};

($str) = unquote_bash( q{"Hello, World!"} );
is $str, q{Hello, World!};

sub pbtext_ok
{
    my ($pbtext, $expect_ref, $test_name) = @_;

    my ($line) = reverse caller;

    my $pbobj = WWW::AUR::PKGBUILD->new( $pbtext );
    my %parsed = $pbobj->fields;
    is_deeply( \%parsed, $expect_ref, "line $line: $test_name" );
    return;
}

my $pbtext = <<'END_PKGBUILD';
pkgname='perl-cpanplus-dist-arch-git'
pkgver='20100530'
pkgrel='1'
pkgdesc='Developer release for CPANPLUS::Dist::Arch perl module'
arch=('any')
license=('PerlArtistic' 'GPL')
options=('!emptydirs')
makedepends=('perl-test-pod-coverage' 'perl-test-pod')
depends=('perl')
provides=('perl-cpanplus-dist-arch')
url='http://github.com/juster/perl-cpanplus-dist-arch'
md5sums=()
source=()
END_PKGBUILD

pbtext_ok( $pbtext,
           { 'pkgname'  => 'perl-cpanplus-dist-arch-git',
             'pkgver'   => '20100530',
             'pkgrel'   => '1',
             'pkgdesc'  => ( 'Developer release for CPANPLUS::Dist::Arch '
                             . 'perl module' ),
             'arch'     => [ 'any' ],
             'license'  => [ 'PerlArtistic', 'GPL' ],
             'options'  => [ '!emptydirs' ],
             'makedepends' => [ { 'pkg' => 'perl-test-pod-coverage',
                                  'cmp' => undef,
                                  'ver' => undef,
                                  'str' => 'perl-test-pod-coverage' },
                                { 'pkg' => 'perl-test-pod',
                                  'cmp' => undef,
                                  'ver' => undef,
                                  'str' => 'perl-test-pod' },
                               ],
             'depends'  => [ { 'pkg' => 'perl',
                               'cmp' => undef,
                               'ver' => undef,
                               'str' => 'perl', } ],
             'provides' => [ { 'pkg' => 'perl-cpanplus-dist-arch',
                               'ver' => undef,
                               'str' => 'perl-cpanplus-dist-arch' } ],
             'url'      => 'http://github.com/juster/perl-cpanplus-dist-arch',
             ( map { ( $_ => [] ) }
               qw { md5sums sha1sums sha256sums sha384sums sha512sums
                    noextract source replaces conflicts groups backup
                    optdepends } ),
            },
           'perl-cpanplus-dist-arch-git PKGBUILD parses' );

$pbtext = <<'END_PKGBUILD';
pkgname='depends-string-test'
depends=('dep>=0.01' 'dep-two')
conflicts=('conflict<999.999' 'conflict-two')
END_PKGBUILD

my %parsed = WWW::AUR::PKGBUILD->new( $pbtext )->fields;
is_deeply( $parsed{depends}, [ { 'pkg' => 'dep',
                                 'ver' => '0.01',
                                 'cmp' => '>=',
                                 'str' => 'dep>=0.01',
                                },
                               { 'pkg' => 'dep-two',
                                 'ver' => undef,
                                 'cmp' => undef,
                                 'str' => 'dep-two',
                                }]);
is_deeply( $parsed{conflicts}, [ { 'pkg' => 'conflict',
                                   'ver' => '999.999',
                                   'cmp' => '<',
                                   'str' => 'conflict<999.999',
                                  },
                                 { 'pkg' => 'conflict-two',
                                   'ver' => undef,
                                   'cmp' => undef,
                                   'str' => 'conflict-two',
                                  }]);

my $pkg      = WWW::AUR::Package->new( 'perl-alpm', basepath => 't/tmp' );
my $pkgbuild = $pkg->pkgbuild;
is blessed( $pkgbuild ), 'WWW::AUR::PKGBUILD';

is $pkgbuild->pkgname, 'perl-alpm';

ok $pkg->extract;
$pkgbuild = $pkg->pkgbuild;
is blessed( $pkgbuild ), 'WWW::AUR::PKGBUILD';
is $pkgbuild->pkgname, 'perl-alpm';
is $pkgbuild->pkgdesc, 'ArchLinux Package Manager backend library.';

$pbtext = <<'END_PKGBUILD';
arch=(''i686' 'x86_64'')
END_PKGBUILD
$pkgbuild = WWW::AUR::PKGBUILD->new( $pbtext );
is_deeply $pkgbuild->arch, [ qw/ i686 x86_64 / ];

