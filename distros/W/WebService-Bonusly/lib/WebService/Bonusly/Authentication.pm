### AUTO-GENERATED FILE ###
### DO NOT EDIT. YOUR CHANGES WILL BE LOST. ###
package WebService::Bonusly::Authentication;
$WebService::Bonusly::Authentication::VERSION = '1.001';
use v5.14;
use Moose;
use Carp;

extends 'WebService::Bonusly::Service';

# ABSTRACT: Implements the bonus.ly authentication service



sub sessions {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter email is required for authentication->sessions"
        unless defined $params{email};
    
    $clean{email} = delete $params{email}
        if defined $params{email};
            
    croak "parameter password is required for authentication->sessions"
        unless defined $params{password};
    
    $clean{password} = delete $params{password}
        if defined $params{password};
    
    
    return $self->_perform_action(
        'POST',
        'sessions',
        \%clean,
        'tokenless',
    );
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bonusly::Authentication - Implements the bonus.ly authentication service

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
