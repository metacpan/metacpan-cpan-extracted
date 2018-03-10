package Webservice::GAMSTOP::Response;

use strict;
use warnings;

our $VERSION = '0.001';    # VERSION

=head1 NAME

Webservice::GAMSTOP::Response - Response object for get_exclusion_for sub

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Webservice::GAMSTOP;
    my $instance = Webservice::GAMSTOP->new(
        api_url => 'gamstop_api_url',
        api_key => 'gamstop_api_key',
        # optional (defaults to 5 seconds)
        timeout => 10,
    );

    my $response = $instance->get_exclusion_for(
        first_name    => 'Harry',
        last_name     => 'Potter',
        email         => 'harry.potter@example.com',
        date_of_birth => '1970-01-01',
        postcode      => 'hp11aa',
    );

    $response->is_excluded;
    $response->get_date;
    $response->get_unique_id;
    $response->get_exclusion;

=head1 DESCRIPTION

This object is returned as response for get_exclusion_for.

=cut

=head1 METHODS

Constructor

=head2 new

    use Webservice::GAMSTOP::Response;
    my $response = Webservice::GAMSTOP::Response->new(
        exclusion => '',
        date      => '',
        unique_id => '',
    );

=head3 Return value

A new Webservice::GAMSTOP::Response object

=cut

sub new {
    my ($class, %args) = @_;

    return bless {}, $class unless %args;

    return bless \%args, $class;
}

=head2 get_exclusion

Exclusion flag provided in response headers

GAMSTOP Response:

- When GAMSTOP returns a Y response the user is registered with the GAMSTOP
service with a valid current self-exclusion.

- When GAMSTOP returns an N response the user is not registered with the GAMSTOP
service.

- When GAMSTOP returns a P response the user was previously self-excluded using
the GAMSTOP service but their chosen minimum period of exclusion has lapsed
and they have requested to have their self-exclusion removed

=head3 Return value

returns GAMSTOP exclusion flag or undef if not present

=over 4

=back

=cut

sub get_exclusion {
    return shift->{exclusion};
}

=head2 get_unique_id

Unique id provided in response headers

=head3 Return value

=over 4

returns GAMSTOP unique id for request or undef if not present

=back

=cut

sub get_unique_id {
    return shift->{unique_id};
}

=head2 get_date

Date provided in response headers. Format: Tue, 27 Feb 2018 02:42:01 GMT

=head3 Return value

=over 4

returns GAMSTOP response date or undef if not present

=back

=cut

sub get_date {
    return shift->{date};
}

=head2 is_excluded

Indicates whether user is self excluded or not

=head3 Return value

=over 4

True if user is excluded on GAMSTOP i.e GAMSTOP return a Y response else false

=back

=cut

sub is_excluded {
    my $flag = shift->{exclusion};

    return ($flag // '') eq 'Y' ? 1 : 0;
}

1;
__END__

=head1 AUTHOR

binary.com <cpan@binary.com>

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
