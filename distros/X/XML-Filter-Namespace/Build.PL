# @(#) $Id: Build.PL,v 1.1 2003/04/24 13:44:54 dom Exp $
use strict;
use Module::Build;

Module::Build->new(
    module_name  => 'XML::Filter::Namespace',
    license      => 'perl',
    script_files => [qw( filtns )],
    requires     => {
        'perl'             => '5.6.1',
        'Class::Accessor'  => 0.17,
        'XML::SAX::Base'   => 0,
        'XML::SAX::Writer' => 0.44,
    },
    build_requires => { 'Test::More' => 0 },
)->create_build_script;
