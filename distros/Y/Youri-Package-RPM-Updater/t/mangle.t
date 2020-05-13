#!/usr/bin/perl
# $Id$

use strict;
use Test::More;
use Youri::Package::RPM::Updater;

my @tests = (
    [
        { url => 'ftp://ftp.gnome.org/pub/GNOME/sources/ORbit2/ORbit2-2.10.0.tar.bz2', bzme => 0 },
        '2.10',
        { url => 'ftp://ftp.gnome.org/pub/GNOME/sources/ORbit2/2.10/ORbit2-2.10.0.tar.bz2', bzme => 0 },
        'gnome, no version in URL'
    ],
    [
        { url => 'ftp://ftp.gnome.org/pub/GNOME/sources/ORbit2/2.9/ORbit2-2.10.0.tar.bz2', bzme => 0 },
        '2.10',
        { url => 'ftp://ftp.gnome.org/pub/GNOME/sources/ORbit2/2.10/ORbit2-2.10.0.tar.bz2', bzme => 0 },
        'gnome, old version in URL'
    ],
    [
        { url => 'ftp://ftp.gnome.org/pub/GNOME/sources/ORbit2/2.10/ORbit2-2.10.0.tar.bz2', bzme => 0 },
        '2.10',
        { url => 'ftp://ftp.gnome.org/pub/GNOME/sources/ORbit2/2.10/ORbit2-2.10.0.tar.bz2', bzme => 0 },
        'gnome, current version in URL'
    ],
    [ 
        { url => 'ftp://ftp.cpan.org/pub/CPAN/modules/by-module/Acme/Acme-Ook-0.11.tar.gz', bzme => 0 },
        '0.11',
        { url => 'http://www.cpan.org/modules/by-module/Acme/Acme-Ook-0.11.tar.gz', bzme => 0 },
        'cpan, ftp scheme and tar.gz'
    ],
    [ 
        { url => 'ftp://ftp.cpan.org/pub/CPAN/modules/by-module/Acme/Acme-Ook-0.11.tar.bz2', bzme => 0 },
        '0.11',
        { url => 'http://www.cpan.org/modules/by-module/Acme/Acme-Ook-0.11.tar.gz', bzme => 1 },
        'cpan, ftp scheme and tar.bz2'
    ],
    [ 
        { url => 'http://www.cpan.org/modules/by-module/Acme/Acme-Ook-0.11.tar.bz2', bzme => 0 },
        '0.11',
        { url => 'http://www.cpan.org/modules/by-module/Acme/Acme-Ook-0.11.tar.gz',  bzme => 1 },
        'cpan, http scheme and tar.bz2'
    ],
    [ 
        { url => 'http://download.pear.php.net/package/Benchmark-0.11.tar.bz2', bzme => 0 },
        '0.11',
        { url => 'http://download.pear.php.net/package/Benchmark-0.11.tgz',  bzme => 1 },
        'pear, tar.bz2'
    ],
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    is_deeply(
       Youri::Package::RPM::Updater::_fix_source($test->[0], $test->[1]),
       $test->[2],
       $test->[3],
   );
};
