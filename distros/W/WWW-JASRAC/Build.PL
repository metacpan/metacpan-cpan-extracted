# $Id$
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

my $class = 'Module::Build';
my $build = $class->new(
    dist_name => 'WWW-JASRAC',
    dist_version_from => 'lib/WWW/JASRAC.pm',
    requires => {
        'Encode'            => 0,
        'HTML::TreeBuilder' => 0,
        'LWP::UserAgent'    => 0,
    },
    license => 'perl',
    create_readme => 1,
    create_makefile_pl => 'traditional',
);

$build->create_build_script();