### AUTO-GENERATED FILE ###
### DO NOT EDIT. YOUR CHANGES WILL BE LOST. ###
package WebService::Bonusly::Rewards;
$WebService::Bonusly::Rewards::VERSION = '1.001';
use v5.14;
use Moose;
use Carp;

extends 'WebService::Bonusly::Service';

# ABSTRACT: Implements the bonus.ly rewards service



sub get {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for rewards->get"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
    
    
    return $self->_perform_action(
        'GET',
        'rewards/:id',
        \%clean,
        
    );
}

sub list {
    my ($self, %params) = @_;

    my %clean;
            
    $clean{catalog_country} = delete $params{catalog_country}
        if defined $params{catalog_country};
            
    $clean{request_country} = delete $params{request_country}
        if defined $params{request_country};
            
    $clean{personalize_for} = delete $params{personalize_for}
        if defined $params{personalize_for};
    
    
    return $self->_perform_action(
        'GET',
        'rewards',
        \%clean,
        
    );
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bonusly::Rewards - Implements the bonus.ly rewards service

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
