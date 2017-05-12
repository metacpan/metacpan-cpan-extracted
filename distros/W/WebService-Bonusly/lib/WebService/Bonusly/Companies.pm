### AUTO-GENERATED FILE ###
### DO NOT EDIT. YOUR CHANGES WILL BE LOST. ###
package WebService::Bonusly::Companies;
$WebService::Bonusly::Companies::VERSION = '1.001';
use v5.14;
use Moose;
use Carp;

extends 'WebService::Bonusly::Service';

# ABSTRACT: Implements the bonus.ly companies service



sub show {
    my ($self, %params) = @_;

    my %clean;
    
    
    return $self->_perform_action(
        'GET',
        'companies/show',
        \%clean,
        
    );
}

sub update {
    my ($self, %params) = @_;

    my %clean;
            
    $clean{name} = delete $params{name}
        if defined $params{name};
        
    croak "parameter custom_properties must be a HASH for companies->update"
        if defined $params{custom_properties} and ref($params{custom_properties}) ne 'HASH';
        
    $clean{custom_properties} = delete $params{custom_properties}
        if defined $params{custom_properties};
    
    
    return $self->_perform_action(
        'PUT',
        'companies/update',
        \%clean,
        
    );
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bonusly::Companies - Implements the bonus.ly companies service

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
