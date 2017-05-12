package rig::cmd::cpan;
{
  $rig::cmd::cpan::VERSION = '0.04';
}
use strict;
use CPAN;
use CPAN::Shell;
use base 'rig::CmdBase';
use rig '-load';

sub run {
    my $self = shift;
    my $parser = $rig::opts{parser};
    my $data = $parser->parse;
    #return unless ref $data eq 'HASH';
    for my $task ( keys %$data ) {
        print "Loaded task $task...\n";
		next unless exists $data->{$task}->{use};
        for my $module ( @{ $data->{$task}->{use} } ) {
            ref $module eq 'HASH' and $module = (keys %$module)[0];
            $module =~ s/^\++//g;
            print "Checking $module...";
            my ($name, $version) = split /\s+/, $module;
            eval "require $name";
            if( $@ ) {
                die $@ unless $@ =~ /can.t locate /i;
            } elsif( $version ) {
                no strict 'refs';
                my $module_version = ${$name.'::VERSION'};
                next unless defined $module_version;
                require version;
                print( "ok\n"),next
                    if version->parse($module_version) >= version->parse($version);
                print "version mismatch ($module_version < $version ): ";
            } else {
                print( "ok\n");
                next;
            }
            print "installing $name.\n";
            $self->_install_module($name);
            print "\n";
        }
    }
}

sub _install_module {
    my $self = shift;
    my $module = shift;
    CPAN::Shell->install( $module );
}

1;

=head1 NAME

rig::cmd::cpan - Command to install a rig with the cpan command line

=head1 VERSION

version 0.04

=head1 SYNOPSYS

	rigup cpan

=head1 DESCRIPTION

This is quite experimental yet.

=head1 METHODS

=head2 run

Calls the CPAN shell to install rig modules. 

=cut 
