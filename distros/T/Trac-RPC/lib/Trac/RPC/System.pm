package Trac::RPC::System;
{
  $Trac::RPC::System::VERSION = '1.0.0';
}



use strict;
use warnings;

use base qw(Trac::RPC::Base);



sub list_methods {
    my ($self) = @_;

    return $self->call('system.listMethods');
}

1;

__END__

=pod

=head1 NAME

Trac::RPC::System

=head1 VERSION

version 1.0.0

=encoding UTF-8

=head1 NAME

Trac::RPC::Wiki - access to Trac System methods via Trac XML-RPC Plugin

=head1 GENERAL FUNCTIONS

=head2 list_methods

B<Get:> 1) $self

B<Return:> 1) ref to the array with list of all avaliable methods via XML::RPC

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
