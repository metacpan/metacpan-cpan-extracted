#!/usr/bin/perl -w
# @(#) $Id: Build.PL 1007 2005-10-18 12:39:26Z dom $

use strict;
use Module::Build;

Module::Build->new(
    module_name => 'XML::Filter::Normalize',
    license     => 'bsd',
    requires    => {
        perl                    => '5.6.1',
        'XML::SAX::Base'        => 0,
        'XML::NamespaceSupport' => 0,
    },
    recommends         => { 'Test::Pod' => 0, },
    create_makefile_pl => 'passthrough',
    add_to_cleanup     => ['XML-Filter-Normalize-*'],
)->create_build_script;
