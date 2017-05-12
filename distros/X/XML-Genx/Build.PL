#!/usr/bin/perl -w
# @(#) $Id: Build.PL 1268 2006-10-08 17:24:54Z dom $

use strict;
use Module::Build;

my %build_requires;
if ($^O eq 'MSWin32') {
    # This release of Module::Build contains a fix that we need.
    # http://sourceforge.net/mailarchive/forum.php?thread_id=6080058&forum_id=10905
    $build_requires{ 'Module::Build' } = 0.2606;
}

Module::Build->new(
    module_name => 'XML::Genx',
    license     => 'bsd',
    dist_author => 'Dominic Mitchell <cpan(at)happygiraffe.net>',
    requires    => { perl => '5.6.1' },
    recommends  => {
        'XML::SAX::Base'      => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
    },
    build_requires     => \%build_requires,
    create_makefile_pl => 'passthrough',
    c_source           => 'src',
    add_to_cleanup     => ['XML-Genx-*'],
)->create_build_script;
