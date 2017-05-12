#!/usr/bin/perl
# $Id: test.t 2282 2011-01-22 10:36:48Z guillomovitch $

use strict;
use File::Basename;
use File::Path;
use File::Temp qw/tempdir/;
use Test::More tests => 6;
use Test::Exception;
use Youri::Package::RPM;

my $wrapper_class = Youri::Package::RPM->get_wrapper_class();
my $header_class =
    $wrapper_class eq 'Youri::Package::RPM::RPM4' ? 'RPM4::Header' :
    $wrapper_class eq 'Youri::Package::RPM::RPM'  ? 'RPM::Header'  :
                                                    undef          ;

BEGIN {
    use_ok('Youri::Package::RPM::Builder');
}

my $source = dirname($0) . '/perl-File-HomeDir-0.58-1mdv2007.0.src.rpm';

my $topdir = tempdir(cleanup => 1);
foreach my $dir qw/BUILD SPECS SOURCES SRPMS RPMS tmp/ {
    mkpath(["$topdir/$dir"]);
};
foreach my $arch qw/noarch/ {
    mkpath(["$topdir/RPMS/$arch"]);
};

$wrapper_class->set_verbosity(4);
$wrapper_class->add_macro("_topdir $topdir");
my ($spec_file) = $wrapper_class->install_srpm($source);

my $builder = Youri::Package::RPM::Builder->new(
    topdir => $topdir,
);
isa_ok($builder, 'Youri::Package::RPM::Builder');

lives_ok {
    $builder->build($spec_file);
} 'building';

my @binaries = <$topdir/RPMS/noarch/*.rpm>;
is(scalar @binaries, 1, 'one binary package');
my @sources = <$topdir/SRPMS/*.rpm>;
is(scalar @sources, 1, 'one source package');

my $package = $wrapper_class->new_header($sources[0]);
isa_ok($package, $header_class);
