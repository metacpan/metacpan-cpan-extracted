package WebService::Snapcard;
use Moose;
with 'WebService::Client';

use Crypt::Mac::HMAC qw(hmac hmac_hex);
use Function::Parameters;
use Time::HiRes qw(time);

has api_key => (
    is       => 'ro',
    required => 1,
);

has api_secret => (
    is       => 'ro',
    required => 1,
);

has '+base_url' => (
    is      => 'ro',
    default => 'https://www.snapcard.io/api/v1',
);

sub BUILD {
    my ($self) = @_;
    $self->ua->default_header(':AUTH_API_KEY' => $self->api_key);
    $self->ua->agent(__PACKAGE__);
}

sub _nonce { time * 1e5 }

around req => fun($orig, $self, $req, @rest) {
    my $nonce = time * 1e5;
    my $signature =
        hmac_hex 'SHA256', $self->api_secret, $req->uri, $req->content;
    $req->header(':AUTH_SIG' => $signature);
    return $self->$orig($req, @rest);
};

around get => fun($orig, $self, $path, $params, @rest) {
    $params ||= {};
    $params->{NONCE} = $self->_nonce();
    return $self->$orig($path, $params, @rest);
};

method get_merchant_balance { $self->get('/merchant/balance') }

method get_invoices { $self->get('/invoices') }

# ABSTRACT: Snapcard (http://www.snapcard.io) API bindings


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Snapcard - Snapcard (http://www.snapcard.io) API bindings

=head1 VERSION

version 0.0001

=head1 SYNOPSIS

    use WebService::Snapcard;

    my $snap = WebService::Snapcard->new(
        api_key    => 'API_KEY',
        api_secret => 'API_SECRET',
        logger     => Log::Tiny->new('/tmp/snap.log'), # optional
    );
    my $balance = $snap->get_merchant_balance()->{balances}{usd};

=head1 METHODS

=head2 get_merchant_balance

    get_merchant_balance()

Get merchant account balance.

=head2 get_invoices

    get_invoices()

Get a list of all invoices on account.

=head1 AUTHOR

Naveed Massjouni <naveed@vt.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
