use strict;
use warnings;
package WebService::SendGrid::Newsletter::Lists::Email;

use JSON;
use parent 'WebService::SendGrid::Newsletter::Base';


sub new {
    my ($class, %args) = @_;
    
    my $self = {};
    bless($self, $class);
    
    $self->{sgn} = $args{sgn};
    
    return $self;    
}


sub add {
    my ($self, %args) = @_;
    
    $self->_check_required_args([ qw( list data ) ], %args);

    if (ref $args{data} eq 'HASH') {
        # Data is a hashref -- turn it into JSON
        $args{data} = to_json($args{data}, $self->{sgn}{json_options});
    }
    elsif (ref $args{data} eq 'ARRAY') {
        # Data is an arrayref of hashrefs -- turn each item into JSON
        $args{data} = [
            map { to_json($_, $self->{sgn}{json_options}); } @{$args{data}}
        ];
    }
    
    return $self->{sgn}->_send_request('lists/email/add', %args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SendGrid::Newsletter::Lists::Email

=head1 VERSION

version 0.02

=head1 METHODS

=head2 new

Creates a new instance of WebService::SendGrid::Newsletter::Lists::Email.

    my $email = WebService::SendGrid::Newsletter::Lists::Email->new(
        sgn => $sgn
    );

Parameters:

=over 4

=item * C<sgn>

An instance of WebService::SendGrid::Newsletter.

=back

=head2 add

Adds one or more emails to a recipient list.

Parameters:

=over 4

=item * C<list>

B<(Required)> The name of the list to which to add the email address.

=item * C<data>

B<(Required)> A reference to an array or a hash that specifies the name,
email address, and additional fields to add to the specified recipient list.

=back

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
