#!/usr/bin/perl -w
# $File: //member/autrijus/XML-RSS-Aggregate/Build.PL $ 
# $Revision: #1 $ $Change: 2920 $ $DateTime: 2002/12/25 14:43:18 $

use strict;
use Module::Build;

my $m = Module::Build->new(
    module_name         => 'XML::RSS::Aggregate',
    license             => 'perl',

    requires            => {
	'LWP'                   => '5.60',
	'XML::RSS'              => '0.90',
        'Date::Parse'           => '2.00',
        'HTML::Entities'        => '0.00',
    },
);

$m->create_build_script;

__END__
# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
