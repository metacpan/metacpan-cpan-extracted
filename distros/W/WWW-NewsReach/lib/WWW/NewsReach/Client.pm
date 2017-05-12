# ABSTRACT: LWP::UserAgent wrapper

package WWW::NewsReach::Client;

our $VERSION = '0.06';

use Moose;

use LWP::UserAgent;

has ua => (
    is          => 'ro',
    isa         => 'LWP::UserAgent',
    lazy_build  => 1,
);

sub _build_ua {
    my $self = shift;

    return LWP::UserAgent->new;
}


sub request {
    my $self    = shift;
    my ( $url ) = @_;

    my $res = $self->ua->get( $url );

    if ( $res->is_success ) {
        return $res->content;
    }
}

1;

__END__
=pod

=head1 NAME

WWW::NewsReach::Client - LWP::UserAgent wrapper

=head1 VERSION

version 0.06

=head1 NAME

WWW::NewsReach::Client - LWP::UserAgent wrapper for making GET requests

=head1 METHODS

=head2 WWW::NewsReach::Client->new()

=head2 $client->request( $url )

Make a LWP::UserAgent->get request to the specified URL and return the response

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

