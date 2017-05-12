### AUTO-GENERATED FILE ###
### DO NOT EDIT. YOUR CHANGES WILL BE LOST. ###
package WebService::Bonusly::Bonuses;
$WebService::Bonusly::Bonuses::VERSION = '1.001';
use v5.14;
use Moose;
use Carp;

extends 'WebService::Bonusly::Service';

# ABSTRACT: Implements the bonus.ly bonuses service



sub get {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for bonuses->get"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
    
    
    return $self->_perform_action(
        'GET',
        'bonuses/:id',
        \%clean,
        
    );
}

sub give {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter reason is required for bonuses->give"
        unless defined $params{reason};
    
    $clean{reason} = delete $params{reason}
        if defined $params{reason};
            
    $clean{giver_email} = delete $params{giver_email}
        if defined $params{giver_email};
            
    $clean{parent_bonus_id} = delete $params{parent_bonus_id}
        if defined $params{parent_bonus_id};
            
    $clean{receiver_email} = delete $params{receiver_email}
        if defined $params{receiver_email};
            
    $clean{amount} = delete $params{amount}
        if defined $params{amount};
    
    
    return $self->_perform_action(
        'POST',
        'bonuses',
        \%clean,
        
    );
}

sub list {
    my ($self, %params) = @_;

    my %clean;
            
    $clean{limit} = delete $params{limit}
        if defined $params{limit};
            
    $clean{skip} = delete $params{skip}
        if defined $params{skip};
            
    $clean{start_time} = delete $params{start_time}
        if defined $params{start_time};
            
    $clean{end_time} = delete $params{end_time}
        if defined $params{end_time};
            
    $clean{non_zero} = delete $params{non_zero}
        if defined $params{non_zero};
            
    $clean{top_level} = delete $params{top_level}
        if defined $params{top_level};
            
    $clean{giver_email} = delete $params{giver_email}
        if defined $params{giver_email};
            
    $clean{receiver_email} = delete $params{receiver_email}
        if defined $params{receiver_email};
            
    $clean{user_email} = delete $params{user_email}
        if defined $params{user_email};
            
    $clean{hashtag} = delete $params{hashtag}
        if defined $params{hashtag};
            
    $clean{include_children} = delete $params{include_children}
        if defined $params{include_children};
    
    
    $clean{$_} = $params{$_} for keys %params;
    
    return $self->_perform_action(
        'GET',
        'bonuses',
        \%clean,
        
    );
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bonusly::Bonuses - Implements the bonus.ly bonuses service

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
