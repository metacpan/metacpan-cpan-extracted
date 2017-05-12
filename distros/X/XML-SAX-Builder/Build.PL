# @(#) $Id: Build.PL,v 1.2 2003/04/24 12:49:28 dom Exp $
use strict;
use Module::Build;

Module::Build->new(
    module_name       => 'XML::SAX::Builder',
    license           => 'perl',
    requires          => {
        'Test::More'            => 0,
        'XML::NamespaceSupport' => 0,
        'XML::SAX::Writer'      => 0,
    },
)->create_build_script;
