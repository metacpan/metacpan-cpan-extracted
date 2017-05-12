package rig::cmd::cpanm;
{
  $rig::cmd::cpanm::VERSION = '0.04';
}
use strict;
use base 'rig::cmd::cpan';

sub _install_module {
    my $self = shift;
    my $module = shift;
    `cpanm "$module"`;
}

1;

=head1 NAME

rig::cmd::cpanm - Command to install a rig with the cpanm command line

=head1 VERSION

version 0.04

=head1 SYNOPSYS

	rigup cpanm

=head1 DESCRIPTION

This is quite experimental yet.

Auto-install modules in a rig using L<App::cpanminus>

=head1 METHODS

=head2 run

Calls the L<App::cpanminus> shell to install rig modules. 

=cut 
