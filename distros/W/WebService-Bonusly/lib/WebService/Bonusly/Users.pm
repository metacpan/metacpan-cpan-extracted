### AUTO-GENERATED FILE ###
### DO NOT EDIT. YOUR CHANGES WILL BE LOST. ###
package WebService::Bonusly::Users;
$WebService::Bonusly::Users::VERSION = '1.001';
use v5.14;
use Moose;
use Carp;

extends 'WebService::Bonusly::Service';

# ABSTRACT: Implements the bonus.ly users service



sub add {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter email is required for users->add"
        unless defined $params{email};
    
    $clean{email} = delete $params{email}
        if defined $params{email};
            
    croak "parameter first_name is required for users->add"
        unless defined $params{first_name};
    
    $clean{first_name} = delete $params{first_name}
        if defined $params{first_name};
            
    croak "parameter last_name is required for users->add"
        unless defined $params{last_name};
    
    $clean{last_name} = delete $params{last_name}
        if defined $params{last_name};
        
    croak "parameter custom_properties must be a HASH for users->add"
        if defined $params{custom_properties} and ref($params{custom_properties}) ne 'HASH';
        
    $clean{custom_properties} = delete $params{custom_properties}
        if defined $params{custom_properties};
            
    $clean{user_mode} = delete $params{user_mode}
        if defined $params{user_mode};
            
    $clean{budget_boost} = delete $params{budget_boost}
        if defined $params{budget_boost};
            
    $clean{external_unique_id} = delete $params{external_unique_id}
        if defined $params{external_unique_id};
    
    
    return $self->_perform_action(
        'POST',
        'users',
        \%clean,
        
    );
}

sub autocomplete {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter search is required for users->autocomplete"
        unless defined $params{search};
    
    $clean{search} = delete $params{search}
        if defined $params{search};
    
    
    return $self->_perform_action(
        'GET',
        'users/autocomplete',
        \%clean,
        
    );
}

sub bonuses {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for users->bonuses"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
            
    $clean{skip} = delete $params{skip}
        if defined $params{skip};
            
    $clean{start_time} = delete $params{start_time}
        if defined $params{start_time};
            
    $clean{hashtag} = delete $params{hashtag}
        if defined $params{hashtag};
            
    $clean{end_time} = delete $params{end_time}
        if defined $params{end_time};
            
    $clean{include_children} = delete $params{include_children}
        if defined $params{include_children};
            
    $clean{limit} = delete $params{limit}
        if defined $params{limit};
            
    $clean{role} = delete $params{role}
        if defined $params{role};
    
    
    $clean{$_} = $params{$_} for keys %params;
    
    return $self->_perform_action(
        'GET',
        'users/:id/bonuses',
        \%clean,
        
    );
}

sub create_redemption {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for users->create_redemption"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
            
    croak "parameter denomination_id is required for users->create_redemption"
        unless defined $params{denomination_id};
    
    $clean{denomination_id} = delete $params{denomination_id}
        if defined $params{denomination_id};
    
    
    return $self->_perform_action(
        'POST',
        'users/:id/redemptions',
        \%clean,
        
    );
}

sub delete {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for users->delete"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
    
    
    return $self->_perform_action(
        'DELETE',
        'users/:id',
        \%clean,
        
    );
}

sub get {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for users->get"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
    
    
    return $self->_perform_action(
        'GET',
        'users/:id',
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
            
    $clean{email} = delete $params{email}
        if defined $params{email};
            
    $clean{sort} = delete $params{sort}
        if defined $params{sort};
    
    
    $clean{$_} = $params{$_} for keys %params;
    
    return $self->_perform_action(
        'GET',
        'users',
        \%clean,
        
    );
}

sub me {
    my ($self, %params) = @_;

    my %clean;
    
    
    return $self->_perform_action(
        'GET',
        'users/me',
        \%clean,
        
    );
}

sub neighborhood {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for users->neighborhood"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
            
    $clean{days} = delete $params{days}
        if defined $params{days};
    
    
    return $self->_perform_action(
        'GET',
        'users/:id/neighborhood',
        \%clean,
        
    );
}

sub redemptions {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for users->redemptions"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
            
    $clean{limit} = delete $params{limit}
        if defined $params{limit};
            
    $clean{skip} = delete $params{skip}
        if defined $params{skip};
    
    
    return $self->_perform_action(
        'GET',
        'users/:id/redemptions',
        \%clean,
        
    );
}

sub update {
    my ($self, %params) = @_;

    my %clean;
            
    croak "parameter id is required for users->update"
        unless defined $params{id};
    
    $clean{id} = delete $params{id}
        if defined $params{id};
            
    $clean{email} = delete $params{email}
        if defined $params{email};
            
    $clean{first_name} = delete $params{first_name}
        if defined $params{first_name};
            
    $clean{last_name} = delete $params{last_name}
        if defined $params{last_name};
        
    croak "parameter custom_properties must be a HASH for users->update"
        if defined $params{custom_properties} and ref($params{custom_properties}) ne 'HASH';
        
    $clean{custom_properties} = delete $params{custom_properties}
        if defined $params{custom_properties};
            
    $clean{user_mode} = delete $params{user_mode}
        if defined $params{user_mode};
            
    $clean{budget_boost} = delete $params{budget_boost}
        if defined $params{budget_boost};
            
    $clean{external_unique_id} = delete $params{external_unique_id}
        if defined $params{external_unique_id};
    
    
    return $self->_perform_action(
        'PUT',
        'users/:id',
        \%clean,
        
    );
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bonusly::Users - Implements the bonus.ly users service

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
