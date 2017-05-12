#!/usr/bin/perl

use warnings 'FATAL' => 'all';
use strict;
use Test::More tests => 4;
use File::Spec::Functions qw(rel2abs splitpath catdir);

my (undef, $tmpdir, undef) = splitpath( $0 );
$tmpdir = rel2abs( $tmpdir );
$tmpdir = catdir( $tmpdir, 'tmp' );

use WWW::AUR::Package;
my $pkg = WWW::AUR::Package->new( 'perl-alpm', 'basepath' => $tmpdir );
ok $pkg;

my $srcpkgdir = $pkg->extract();
ok $srcpkgdir, 'extract appears to succeed';
is $srcpkgdir, $pkg->src_dir_path(), 'extract() result matches src_dir_path()';

ok -d $srcpkgdir, "source directory $srcpkgdir exists";
