package WWW::NHKProgram::API;
use 5.008005;
use strict;
use warnings;
use Furl;
use WWW::NHKProgram::API::Area qw/fetch_area_id/;
use WWW::NHKProgram::API::Date;
use WWW::NHKProgram::API::Service qw/fetch_service_id/;
use WWW::NHKProgram::API::Provider;
use Class::Accessor::Lite::Lazy (
    new     => 1,
    ro      => [qw/api_key/],
    ro_lazy => [qw/provider/],
);

our $VERSION = "0.03";

sub list {
    my $self = shift;
    $self->provider->dispatch('list', @_);
}

sub list_raw {
    my $self = shift;
    $self->provider->dispatch('list', @_, 1);
}

sub genre {
    my $self = shift;
    $self->provider->dispatch('genre', @_);
}

sub genre_raw {
    my $self = shift;
    $self->provider->dispatch('genre', @_, 1);
}

sub info {
    my $self = shift;
    $self->provider->dispatch('info', @_);
}

sub info_raw {
    my $self = shift;
    $self->provider->dispatch('info', @_, 1);
}

sub now_on_air {
    my $self = shift;
    $self->provider->dispatch('now', @_);
}

sub now_on_air_raw {
    my $self = shift;
    $self->provider->dispatch('now', @_, 1);
}

sub _build_provider {
    my $self = shift;
    return WWW::NHKProgram::API::Provider->new(
        furl => Furl->new(
            agent   => 'WWW::NHKProgram::API (Perl)',
            timeout => 10,
        ),
        api_key => $self->api_key,
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::NHKProgram::API - API client for NHK program API

=head1 SYNOPSIS

    use WWW::NHKProgram::API;

    my $client = WWW::NHKProgram::API->new(api_key => '__YOUR_API_KEY__');

    # Get program list
    my $program_list = $client->list({
        area    => 130,
        service => 'g1',
        date    => '2014-02-02',
    });

    # Get program list by genre
    my $program_genre = $client->genre({
        area    => 130,
        service => 'g1',
        genre   => '0000',
        date    => '2014-02-02',
    });

    # Get program information
    my $program_info = $client->info({
        area    => 130,
        service => 'g1',
        id      => '2014020334199',
    });

    # Get information of program that is on air now
    my $program_now = $client->now_on_air({
        area    => 130,
        service => 'g1',
    });

=head1 DESCRIPTION

WWW::NHKProgram::API is the API client for NHK program API.

Please refer L<http://api-portal.nhk.or.jp>
if you want to get information about NHK program API.

=head1 METHODS

=over 4

=item * WWW::NHKProgram::API->new();

Constructor. You must give API_KEY through this method.

e.g.

    my $client = WWW::NHKProgram::API->new(
        api_key => '__YOUR_API_KEY__', # <= MUST!
    );

=item * $client->list()

Get program list.

    my $program_list = $client->list({
        area    => 130,
        service => 'g1',
        date    => '2014-02-04',
    });

And following the same;

    my $program_list = $client->list({
        area    => '東京',
        service => 'ＮＨＫ総合１',
        date    => '2014-02-04',
    });

You can specify Japanese area name and service name as arguments.
If you want to know more details, please refer to the following;

L<http://api-portal.nhk.or.jp/doc-request>

=item * $client->genre()

Get program list by genre.

    my $genre_list = $client->genre({
        area    => 130,
        service => 'g1',
        genre   => '0000',
        date    => '2014-02-04',
    });

Yes! you can also specify following;

    my $genre_list = $client->genre({
        area    => '東京',
        service => 'ＮＨＫ総合１',
        genre   => '定時・総合',
        date    => '2014-02-04',
    });

=item * $client->info()

Get information of program.

    my $program_info = $client->info({
        area    => 130,
        service => 'g1',
        id      => '2014020402027',
    });

Also;

    my $program_info = $client->info({
        area    => '東京',
        service => 'ＮＨＫ総合１',
        id      => '2014020402027',
    });

=item * $client->now_on_air()

Get information of program that is on air now.

    my $program_now = $client->now_on_air({
        area    => 130,
        service => 'g1',
    });

Yes,

    my $program_now = $client->now_on_air({
        area    => '東京',
        service => 'ＮＨＫ総合１',
    });

=item * $client->list_raw()

=item * $client->genre_raw()

=item * $client->info_raw()

=item * $client->now_on_air_raw()

Returns raw JSON response of each API.

=back

=head1 FOR DEVELOPERS

Tests which are calling web API directly in F<xt/webapi>. If you want to run these tests, please execute like so;

    $ NHK_PROGRAM_API_KEY=__YOUR_API_KEY__ prove xt/webapi

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

