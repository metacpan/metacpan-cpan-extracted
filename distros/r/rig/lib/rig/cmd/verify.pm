package rig::cmd::verify;
{
  $rig::cmd::verify::VERSION = '0.04';
}
use strict qw/vars/;

sub run {
    require rig;
    my $engine_import = rig->_setup_engine;
    rig->_setup_parser;
    &$engine_import('rig::engine::base');
}

1;

=head1 NAME

rig::cmd::verify - Check that your rig is installed in the system

=head1 VERSION

version 0.04

=head1 SYNOPSYS

	rigup verify

=head1 DESCRIPTION

This is quite experimental yet. 

The idea is to check that all your rigs are fully usable. 

More to come.

=head1 METHODS

=head2 run

Tries to use all available file rigs. 

=cut 
