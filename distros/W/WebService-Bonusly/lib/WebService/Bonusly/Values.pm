### AUTO-GENERATED FILE ###
### DO NOT EDIT. YOUR CHANGES WILL BE LOST. ###
package WebService::Bonusly::Values;
$WebService::Bonusly::Values::VERSION = '1.001';
use v5.14;
use Moose;
use Carp;

extends 'WebService::Bonusly::Service';

# ABSTRACT: Implements the bonus.ly values service



sub get {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for values->get"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
    
    
    return $self->_perform_action(
        'GET',
        'values/:id',
        \%clean,
        
    );
}

sub list {
    my ($self, %params) = @_;

    my %clean;
    
    
    return $self->_perform_action(
        'GET',
        'values',
        \%clean,
        
    );
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bonusly::Values - Implements the bonus.ly values service

=head1 VERSION

version 1.001

=head1 DESCRIPTION

This module implements the service. For documentation of this service, see L<WebService::Bonusly>

=for Pod::Coverage *EVERYTHING*

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
