package WebService::MyGengo::Test::Util::Client;

use strict;
use warnings;

use WebService::MyGengo::Client;            # The API library
use WebService::MyGengo::Test::Mock::LWP;   # The mock LWP::UserAgent
use WebService::MyGengo::Test::Util::Config;

use Exporter;

use vars qw(@ISA @EXPORT);
use base qw(Exporter);

@EXPORT = qw(client);

=head1 NAME

WebService::MyGengo::Test::Util::Client - Basic access to the WebService::MyGengo::Client with simple mocking

=head1 SYNOPSIS

    # t/some-test.t
    use WebService::MyGengo::Test::Util:Client;:

    # use_sandbox = 0 ~ Production API access. Client will die if you use this.
    # use_sandbox = 1 ~ Sandbox API access.
    # use_sandbox = 2 ~ No API access at all (uses a mocked LWP::UserAgent)
    my %config = { public_key => 'pub', private_key => 'priv', use_sandbox => 2 };
    my $m = client( \%config );
    my $job = $m->getTranslationJob( $id ); # A mock Job

    # You can use the live version as well, just be careful of throttling
    $config{use_sandbox} = 1;
    my $m = client( \%config );
    my $job = $m->getTranslationJob( $id ); # A mock Job

=head1 METHODS

=head2 client( \%user_args? )

Returns an instance of the myGengo client library.

Supply \%user_args to override defaults.

See L<SYNOPSIS> for usage.

=cut
sub client {
    my ( $user_args ) = ( shift );

    my %args = %{config()};
    $user_args and @args{ keys %$user_args } = values %$user_args;

    !$args{use_sandbox} and die "Will not allow live API access from tests.";

    my $client;
    if ( $args{use_sandbox} == 2 ) {
        $args{use_sandbox} = 1;
        $client = WebService::MyGengo::Client->new( \%args );

        # A mock LWP to simulate real API access
        my $ua = WebService::MyGengo::Test::Mock::LWP->new( %args );
        $client->_set_user_agent( $ua );
    }
    else {
        $client = WebService::MyGengo::Client->new( \%args );
    }

    return $client;
}

1;

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
