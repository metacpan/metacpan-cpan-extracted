#line 1
##
# name:      Module::Package
# abstract:  Postmodern Perl Module Packaging
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - Module::Package::Plugin
# - Module::Install::Package
# - Module::Package::Tutorial

package Module::Package;
use 5.005;
use strict;

BEGIN {
    $Module::Package::VERSION = '0.19';
    $inc::Module::Package::VERSION ||= $Module::Package::VERSION;
    @inc::Module::Package::ISA = __PACKAGE__;
}

sub import {
    eval "use inc::Module::Install 1.01 (); 1" or die $@;

    my $class = shift;
    package main;
    inc::Module::Install->import();
    eval {
        module_package_internals_version_check($Module::Package::VERSION);
        module_package_internals_init(@_);
    };
    if ($@) {
        $Module::Package::ERROR = $@;
        die $@;
    }
}

1;

