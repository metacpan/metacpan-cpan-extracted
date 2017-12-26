package WebService::PayPal::PaymentsAdvanced::Mocker;

use Moo;

use namespace::autoclean;

our $VERSION = '0.000024';

use Types::Standard qw( Bool CodeRef InstanceOf );
use WebService::PayPal::PaymentsAdvanced::Mocker::PayflowLink;
use WebService::PayPal::PaymentsAdvanced::Mocker::PayflowPro;

has mocked_ua => (
    is       => 'ro',
    isa      => InstanceOf ['Test::LWP::UserAgent'],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_mocked_ua',
);

# The app builders return different things under different conditions.  The
# return a CodeRef under Plack.  They return a Mojolicious::Lite object when
# deployed via morbo.  They return a "1" when not run via Plack, using the test
# suite.

has payflow_link => (
    is       => 'ro',
    isa      => CodeRef | InstanceOf ['Mojolicious::Lite'] | Bool,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_payflow_link',
);

has payflow_pro => (
    is       => 'ro',
    isa      => CodeRef | InstanceOf ['Mojolicious::Lite'] | Bool,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_payflow_pro',
);

has plack => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'plack',
    default  => 0,
);

has _ua => (
    is       => 'ro',
    isa      => InstanceOf ['Test::LWP::UserAgent'],
    init_arg => 'ua',
    lazy     => 1,
    builder  => '_build_ua',
);

sub _build_ua {
    my $self = shift;

    die 'plack => 1 is required for mocking via useragent'
        unless $self->plack;

    require Test::LWP::UserAgent;

    my $ua = Test::LWP::UserAgent->new( network_fallback => 0 );
    return $ua;
}

sub _build_mocked_ua {
    my $self = shift;

    require HTTP::Message::PSGI;

    my $link = $self->payflow_link;
    my $pro  = $self->payflow_pro;

    $self->_ua->register_psgi( 'payflowlink.paypal.com',       $link );
    $self->_ua->register_psgi( 'payflowpro.paypal.com',        $pro );
    $self->_ua->register_psgi( 'pilot-payflowlink.paypal.com', $link );
    $self->_ua->register_psgi( 'pilot-payflowpro.paypal.com',  $pro );

    return $self->_ua;
}

sub _build_payflow_link {
    my $self = shift;

    local $ENV{PLACK_ENV} = 'development' if $self->plack;
    return WebService::PayPal::PaymentsAdvanced::Mocker::PayflowLink->to_app;
}

sub _build_payflow_pro {
    my $self = shift;

    local $ENV{PLACK_ENV} = 'development' if $self->plack;
    return WebService::PayPal::PaymentsAdvanced::Mocker::PayflowPro->to_app;
}

1;

# ABSTRACT: A class which returns mocked PPA apps.

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Mocker - A class which returns mocked PPA apps.

=head1 VERSION

version 0.000024

=head1 SYNOPSIS

    use WebService::PayPal::PaymentsAdvanced::Mocker;
    my $mocker = WebService::PayPal::PaymentsAdvanced::Mocker->new( plack => 1 );
    my $app = $mocker->payflow_pro; # returns a PSGI app

    # OR, to use with a mocking UserAgent
    use Test::LWP::UserAgent;
    use HTTP::Message::PSGI;

    my $ua = Test::LWP::UserAgent->new;
    my $mocker = WebService::PayPal::PaymentsAdvanced::Mocker->new( plack => 1 );
    $ua->register_psgi( 'pilot-payflowpro.paypal.com', $mocker->payflow_pro );
    $ua->register_psgi( 'pilot-payflowlink.paypal.com', $mocker->payflow_link );

    my $ppa = WebService::PayPal::PaymentsAdvanced->new(
        ua => $ua,
        ...
    );

=head1 DESCRIPTION

You can use this class to facilitate mocking your PPA integration.  When
running under $ENV{HARNESS_ACTIVE}, you can pass a Test::LWP::UserAgent to
L<WebService::PayPal::PaymentsAdvanced> as in the SYNOPSIS above.  Adjust the
hostnames as necessary.

=head1 CONSTRUCTOR OPTIONS

=head2 plack => [0|1]

If you require a PSGI app to be returned, you'll need to enable this option.
Disabled by default.

    use WebService::PayPal::PaymentsAdvanced::Mocker;
    my $mocker = WebService::PayPal::PaymentsAdvanced::Mocker->new( plack => 1 );
    my $app = $mocker->payflow_pro; # returns a PSGI app

=head2 ua

If may provide your own UserAgent object to this class.  This is only
necessary if you intend to call the C<mocked_ua> method and need to provide
your own customized UserAgent.  The object must be L<Test::LWP::UserAgent>
object, or a subclass of it.

=head2 payflow_link

Returns a Mojolicious::Lite app which mocks the Payflow Link web service.

=head2 payflow_pro

Returns a Mojolicious::Lite app which mocks the Payflow Pro web service.

=head2 mocked_ua

Returns a UserAgent object mocking already enabled for both live and sandbox
PayPal hostnames.  The UserAgent will either be the object which you passed via
the C<ua> option when you created the object or a vanilla
L<Test::LWP::UserAgent> object which this class will create.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/webservice-paypal-paymentsadvanced/issues>.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
