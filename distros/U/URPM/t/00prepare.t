#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use URPM;
use Cwd;

chdir 't' if -d 't';
mkdir "tmp";
for (qw(BUILD SOURCES SRPMS RPMS RPMS/noarch)) {
    mkdir "tmp/".$_;
}
# locally build a test rpm
system(rpmbuild => '--define', '_topdir '. Cwd::cwd() . "/tmp/", '-ba', 'test-rpm.spec');
ok( -f 'tmp/RPMS/noarch/test-rpm-1.0-1mdk.noarch.rpm', 'rpm created' );
ok( -f 'tmp/SRPMS/test-rpm-1.0-1mdk.src.rpm', 'srpm created' );

