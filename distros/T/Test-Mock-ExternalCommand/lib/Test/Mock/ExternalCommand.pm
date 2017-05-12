package Test::Mock::ExternalCommand;
use strict;
use warnings;
use Config;
use Carp;
use Variable::Expand::AnyLevel qw(expand_variable);

use 5.010;
our $VERSION = '0.03';

my $command_registry = {};
my $command_history = {};

BEGIN {
    sub _command_and_args {
        my ( $command, @args ) = @_;
        my ( $command_real, @args2 ) = split qr/\s+/, $command;
        my @args_real = (@args2, @args);
        return ($command_real, @args_real);
    }

    *CORE::GLOBAL::system = sub {
        my ( $command, @args ) = _command_and_args(@_);
        if ( defined $command_registry->{$command} ) {
            return $command_registry->{$command}->{system}->(@args);
        }
        CORE::system(@_);
    };

    *CORE::GLOBAL::readpipe = sub {
        # readpipe receives variable name if variable is used in backquote string ...
        # so it is need to expand using Variable::Expand::AnyLevel::expand_variable
        my @new_args = map { expand_variable($_, 1) } @_;
        my ( $command, @command_args ) = _command_and_args(@new_args);
        if ( defined $command_registry->{$command} ) {
            return $command_registry->{$command}->{readpipe}->(@command_args);
        }
        CORE::readpipe(@_);
    };
}


=head1 NAME

Test::Mock::ExternalCommand - Create mock external-command easily

=head1 SYNOPSIS

  use Test::Mock::ExternalCommand;
  my $m = Test::Mock::ExternalCommand->new();
  $m->set_command( 'my-command-aaa', 'command-output', 0);
  # use 'my-command-aaa' in your test.

=head1 DESCRIPTION

Test::Mock::ExternalCommand enable to make mock-external command in easy way.

=head1 Methods

=cut

=head2 new()

=cut

sub new {
    my ( $class ) = @_;
    my $self = {
        my_commands     => {},
    };
    bless $self, $class;
    my $address = $self + 0;
    $command_history->{$address} = [];
    return $self;
}

=head2 set_command( $command_name,  $command_output_string, $command_exit_status )

set mock external command command.

=cut

sub set_command {
    my ( $self, $command_name, $command_output, $command_exit_status ) = @_;

    carp "${command_name}: already defined\n" if ( defined $command_registry->{$command_name} );
    $self->{my_commands}->{$command_name} = $command_name;

    my $address = $self + 0; # address is calculated in this scope avoiding refcount increment

    $command_registry->{$command_name}->{system} = sub {
        my ( @args ) = @_;
        push @{ $command_history->{$address} }, [$command_name, @args];
        print $command_output;
        return $command_exit_status << 8;
    };

    $command_registry->{$command_name}->{readpipe} = sub {
        my ( @args ) = @_;
        push @{ $command_history->{$address} }, [$command_name, @args];
        return $command_output;
    };
}

=head2 set_command_by_coderef( $command_name,  $command_behavior_subref )

set mock external command command using subroutine reference(coderef).

=cut

sub set_command_by_coderef {
    my ( $self, $command_name, $command_behavior_subref ) = @_;

    carp "${command_name}: already defined\n" if ( defined $command_registry->{$command_name} );
    $self->{my_commands}->{$command_name} = $command_name;

    my $address = $self + 0; # address is calculated in this scope avoiding refcount increment

    $command_registry->{$command_name}->{system} = sub {
        my ( @args ) = @_;
        push @{ $command_history->{$address} }, [$command_name, @args];
        my $ret =  $command_behavior_subref->(@args);
        return $ret << 8;
    };
    $command_registry->{$command_name}->{readpipe} = sub {
        my ( @args ) = @_;
        push @{ $command_history->{$address} }, [$command_name, @args];
        return $command_behavior_subref->(@args);
    };
}

=head2 history()

return command history.

=cut

sub history {
    my ( $self ) = @_;
    my $address = $self + 0;
    return @{ $command_history->{$address} };
}

=head2 reset_history()

reset command history.

=cut

sub reset_history {
    my ( $self ) = @_;
    my $address = $self + 0;
    $command_history->{$address} = [];
}

=head2 commands()

return overridden command names

=cut

sub commands {
    my ( $self ) = @_;
    my @result =  sort keys %{ $self->{my_commands} };
    return @result;
}

# commands registered in global structure
sub _registered_commands {
    my @result =  sort keys %{ $command_registry };
    return @result;
}

sub _unset_all_commands {
    my ( $self ) = @_;
    for my $command ( $self->commands() ) {
        delete $command_registry->{$command};
    }
    $self->{my_commands} = {};
    $self->reset_history();
}

sub DESTROY {
    my ( $self ) = @_;
    $self->_unset_all_commands() if ( defined $self );
}

1;
__END__

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=head1 SEE ALSO

=head1 Copyright

Copyright (c) 2010-2013 Takuya Tsuchida

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
