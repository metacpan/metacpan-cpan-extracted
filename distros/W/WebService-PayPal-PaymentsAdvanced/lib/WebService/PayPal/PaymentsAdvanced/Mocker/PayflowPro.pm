package WebService::PayPal::PaymentsAdvanced::Mocker::PayflowPro;

use Mojolicious::Lite;

use namespace::autoclean;

our $VERSION = '0.000022';

use feature qw( state );

use Data::GUID ();
use List::AllUtils qw( none );
use URI::FromHash qw( uri_object );
use WebService::PayPal::PaymentsAdvanced::Mocker::Helper;

my $helper = WebService::PayPal::PaymentsAdvanced::Mocker::Helper->new;

## no critic (RequireExplicitInclusion)
app->types->type( nvp => 'text/namevalue' );

post '/' => sub {
    my $c      = shift;
    my $params = _filter_params($c);

    if ( $params->{CREATESECURETOKEN} && $params->{CREATESECURETOKEN} eq 'Y' )
    {
        my %return = (
            RESULT        => 0,
            RESPMSG       => 'Approved',
            SECURETOKENID => $params->{SECURETOKENID},
            SECURETOKEN   => Data::GUID->new->as_string,
        );

        _render_response( $c, \%return );
        return;
    }

    if (
        !$params->{TRXTYPE}
        || none { $params->{TRXTYPE} eq $_ }
        ( 'A', 'C', 'D', 'I', 'S', 'V', )
        ) {
        $c->render( text => 'Mocked URL not found', status => 404 );
        return;
    }

    if ( $params->{TRXTYPE} eq 'A' ) {
        my %return;

        if ( $params->{TENDER} eq 'C' ) {

            %return = (
                ACCT          => 1762,
                AMT           => $params->{AMT},
                AUTHCODE      => 111111,
                AVSADDR       => 'Y',
                AVSZIP        => 'Y',
                CARDTYPE      => 3,
                CORRELATIONID => $helper->correlationid,
                CVV2MATCH     => 'Y',
                EXPDATE       => 1221,
                IAVS          => 'N',
                LASTNAME      => 'NotProvided',
                PNREF         => $helper->pnref,
                PPREF         => $helper->ppref,
                PROCAVS       => 'X',
                PROCCVV2      => 'M',
                RESPMSG       => 'Approved',
                RESULT        => 0,
                TRANSTIME     => $helper->transtime,
            );

        }
        elsif ( $params->{TENDER} eq 'P' ) {
            %return = (
                AMT           => $params->{AMT},
                BAID          => $helper->baid,
                CORRELATIONID => $helper->correlationid,
                PAYMENTTYPE   => 'instant',
                PENDINGREASON => 'authorization',
                PNREF         => $helper->pnref,
                PPREF         => $helper->ppref,
                RESPMSG       => 'Approved',
                RESULT        => 0,
                TRANSTIME     => $helper->transtime,
            );
        }
        _render_response( $c, \%return );
        return;
    }

    if ( $params->{TRXTYPE} eq 'D' ) {
        my %return = (
            CORRELATIONID => $helper->correlationid,
            FEEAMT        => 1.75,
            PAYMENTTYPE   => 'instant',
            PENDINGREASON => 'completed',
            PNREF         => $helper->pnref,
            PPREF         => $helper->ppref,
            RESPMSG       => 'Approved',
            RESULT        => 0,
            TRANSTIME     => $helper->transtime,
        );

        _render_response( $c, \%return );
        return;
    }

    if ( $params->{TRXTYPE} eq 'I' ) {
        my %return = (
            ACCT          => 7603,
            AMT           => 50.00,
            CARDTYPE      => 1,
            CORRELATIONID => $helper->correlationid,
            EXPDATE       => 1221,
            LASTNAME      => 'NotProvided',
            ORIGPNREF     => $params->{ORIGID},
            ORIGPPREF     => $helper->ppref,
            ORIGRESULT    => 0,
            PNREF         => $helper->pnref,
            RESPMSG       => 'Approved',
            RESULT        => 0,
            SETTLE_DATE   => $helper->transtime,
            TRANSSTATE    => 8,
            TRANSTIME     => $helper->transtime,
        );

        _render_response( $c, \%return );
        return;
    }

    if ( $params->{TRXTYPE} eq 'S' ) {

        if ( $params->{TENDER} && $params->{TENDER} eq 'C' ) {

            my %return = (
                ACCT          => 4482,
                AMT           => $params->{AMT},
                AUTHCODE      => 111111,
                AVSADDR       => 'Y',
                AVSZIP        => 'Y',
                CARDTYPE      => 3,
                CORRELATIONID => $helper->correlationid,
                CVV2MATCH     => 'Y',
                EXPDATE       => 1221,
                IAVS          => 'N',
                LASTNAME      => 'NotProvided',
                PNREF         => $helper->pnref,
                PPREF         => $helper->ppref,
                PROCAVS       => 'X',
                PROCCVV2      => 'M',
                RESPMSG       => 'Approved',
                RESULT        => 0,
                TRANSTIME     => $helper->transtime,
            );
            _render_response( $c, \%return );
            return;
        }

        if ( $params->{TENDER} && $params->{TENDER} eq 'P' ) {
            my %return = (
                AMT           => $params->{AMT},
                BAID          => $helper->baid,
                CORRELATIONID => $helper->correlationid,
                CVV2MATCH     => 'Y',
                PNREF         => $helper->pnref,
                PPREF         => $helper->ppref,
                PROCAVS       => 'X',
                PROCCVV2      => 'M',
                RESPMSG       => 'Approved',
                RESULT        => 0,
                TRANSTIME     => $helper->transtime,
            );
            _render_response( $c, \%return );
            return;
        }
    }

    if ( $params->{TRXTYPE} eq 'C' ) {
        my %return = (
            CORRELATIONID => $helper->correlationid,
            PNREF         => $helper->pnref,
            PPREF         => $helper->ppref,
            RESPMSG       => 'Approved',
            RESULT        => 0,
            TRANSTIME     => $helper->transtime,
        );
        _render_response( $c, \%return );
        return;
    }

    if ( $params->{TRXTYPE} eq 'V' ) {
        my %return = (
            CORRELATIONID => $helper->correlationid,
            PENDINGREASON => 'authorization',
            PNREF         => $helper->pnref,
            PPREF         => $helper->ppref,
            RESPMSG       => 'Approved',
            RESULT        => 0,
            TRANSTIME     => $helper->transtime,
        );
        _render_response( $c, \%return );
        return;
    }

    $c->render( text => 'Mocked URL not found', status => 404 );
};

sub _render_response {
    my $c        = shift;
    my $response = shift;
    my $params   = _filter_params($c);

    # Echo some params back to make the responses more DRY
    if (
        (
            $params->{TRXTYPE}
            && ( $params->{TRXTYPE} eq 'A' || $params->{TRXTYPE} eq 'S' )
        )
        && $params->{INVNUM}
        ) {
        $response->{INVNUM}  = $params->{INVNUM};
        $response->{INVOICE} = $params->{INVNUM};
    }

    my $response_as_uri = uri_object( query => $response );
    $c->render( text => $response_as_uri->query, format => 'nvp' );
}

sub _filter_params {
    my $c      = shift;
    my $params = $c->req->params->to_hash;
    my %filtered;
    foreach my $key ( keys %{$params} ) {
        my $value = $params->{$key};
        $key =~ s{\[\d*\]}{};
        $filtered{$key} = $value;
    }
    return \%filtered;
}

sub to_app {
    app->secrets( ['Tempus fugit'] );
    app->start;
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Mocker::PayflowPro - A simple app to enable easy PPA mocking

=head1 VERSION

version 0.000022

=head1 DESCRIPTION

A simple app to enable easy PPA mocking.

=head2 to_app

    use WebService::PayPal::PaymentsAdvanced::Mocker::PayflowPro;
    my $app = WebService::PayPal::PaymentsAdvanced::Mocker::PayflowPro->to_app;

If you require a Plack app to be returned, you'll need to give Mojo the correct
hint:

    use WebService::PayPal::PaymentsAdvanced::Mocker::PayflowPro;

    local $ENV{PLACK_ENV} = 'development'; #
    my $app = WebService::PayPal::PaymentsAdvanced::Mocker::PayflowPro->to_app;

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A simple app to enable easy PPA mocking

