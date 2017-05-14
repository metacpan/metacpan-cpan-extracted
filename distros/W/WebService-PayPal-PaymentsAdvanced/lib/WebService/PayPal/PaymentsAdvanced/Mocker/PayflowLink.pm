package WebService::PayPal::PaymentsAdvanced::Mocker::PayflowLink;

use Mojolicious::Lite;

our $VERSION = '0.000022';

# A GET request will be a request for the hosted form.

get '/' => sub {
    my $c = shift;
    $c->render( text => 'Hosted form would be here' );
};

sub to_app {
    ## no critic (RequireExplicitInclusion)
    app->secrets( ['Tempus fugit'] );
    app->start;
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Mocker::PayflowLink - A simple app to enable easy Payflow Link (hosted form) mocking

=head1 VERSION

version 0.000022

=head1 DESCRIPTION

A simple app to enable easy Payflow Link (hosted form) mocking.

=head2 to_app

    use WebService::PayPal::PaymentsAdvanced::Mocker::PayflowLink;
    my $app = WebService::PayPal::PaymentsAdvanced::Mocker::PayflowLink->to_app;

If you require a Plack app to be returned, you'll need to give Mojo the correct
hint:

    use WebService::PayPal::PaymentsAdvanced::Mocker::PayflowLink;

    local $ENV{PLACK_ENV} = 'development'; #
    my $app = WebService::PayPal::PaymentsAdvanced::Mocker::PayflowLink->to_app;

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

# ABSTRACT: A simple app to enable easy Payflow Link (hosted form) mocking

