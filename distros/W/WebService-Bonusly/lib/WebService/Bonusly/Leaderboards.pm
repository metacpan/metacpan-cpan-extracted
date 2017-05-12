### AUTO-GENERATED FILE ###
### DO NOT EDIT. YOUR CHANGES WILL BE LOST. ###
package WebService::Bonusly::Leaderboards;
$WebService::Bonusly::Leaderboards::VERSION = '1.001';
use v5.14;
use Moose;
use Carp;

extends 'WebService::Bonusly::Service';

# ABSTRACT: Implements the bonus.ly leaderboards service



sub standouts {
    my ($self, %params) = @_;

    my %clean;
            
    $clean{role} = delete $params{role}
        if defined $params{role};
            
    $clean{value} = delete $params{value}
        if defined $params{value};
            
    $clean{limit} = delete $params{limit}
        if defined $params{limit};
            
    $clean{period} = delete $params{period}
        if defined $params{period};
            
    $clean{custom_property_name} = delete $params{custom_property_name}
        if defined $params{custom_property_name};
            
    $clean{custom_property_value} = delete $params{custom_property_value}
        if defined $params{custom_property_value};
    
    
    return $self->_perform_action(
        'GET',
        'analytics/standouts',
        \%clean,
        
    );
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bonusly::Leaderboards - Implements the bonus.ly leaderboards service

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
