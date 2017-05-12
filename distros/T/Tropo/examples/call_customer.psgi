#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Mojolicious::Lite;
use Mojolicious::Plugin::Database;
use Mojolicious::Plugin::Util::RandomString;
use JSON;

use Tropo;
use Tropo::RestAPI::Session;

$ENV{MOJO_MODE} = 'development';

plugin database => {
    dsn => 'DBI:SQLite:tropo',
};

plugin 'Util::RandomString';

my $token = 'your_api_token';

# show form and ask user to submit
# her phone number
get '/' => sub {
    my $self = shift;

    $self->app->log->error( 'form requested' );

    $self->stash( WILL_CALL => 0 );
    $self->render( 'form' );
};

# save phone number in db and 
# create new tropo session
post '/' => sub {
    my $self = shift;

    $self->app->log->error( 'form submitted' );

    $self->stash( WILL_CALL => 0 );
    my $phone = $self->param( 'phone' );

    if ( !$phone ) {
        $self->stash( PHONE_ERROR => 1 );
    }
    else {
        my $id = $self->random_string;

        my $insert = qq~
            INSERT INTO
                calls (phone, session)
                VALUES (?,?)~;

        $self->db->do(
            $insert,
            undef,
            $phone,
            $id,
        );

        my $session = Tropo::RestAPI::Session->new(
            url => 'https://tropo.developergarden.com/api/',
        );

        my $data    = $session->create(
            token        => $token,
            call_session => $id,
        ) or $self->app->log->error( $session->err );

        $self->stash( WILL_CALL => 1 );
    }

    $self->render( 'form' );
};

# called by tropo server
# deliver the json with instructions
# for tropo
any '/tropo/' => sub {
    my $self = shift;

    my $tropo_data = $self->req->json;
    my $session    = $tropo_data->{session}->{parameters}->{call_session};

    my $select = 'SELECT * FROM calls '
        . ' WHERE session = ?';
    my $sth    = $self->db->prepare(
        $select,
    );

    $sth->execute( $session );
    my $result = $sth->fetchall_arrayref({});

    my $data = {};

    if ( !$result || !$result->[0] ) {
        $result->[0]->{phone} = '+491804100100';
    }
    if ( $result->[0]->{phone} ) {
        my $tropo = Tropo->new;
        $tropo->call( $result->[0]->{phone} );
        $tropo->say(
            'your authentication code is ' . sprintf "%d", int rand (999)
        );
        $data = $tropo->perl;
    }

    $self->render( json => $data );
};

app->start;

__DATA__
@@ form.html.ep
<% if ( $WILL_CALL ) { %>
<span style="background-color: green">We will call you in a moment</span>
<% } %>
<form action="" method="post">
    Your phone number (international format, e.g. +4912345678):
    <input type="text" name="phone" /><br />
    <button type="submit" value="Call me!">Call me!</button>
</form>

