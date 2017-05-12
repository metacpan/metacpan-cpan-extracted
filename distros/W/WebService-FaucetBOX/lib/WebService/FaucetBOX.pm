use strict;
use warnings;
package WebService::FaucetBOX;
$WebService::FaucetBOX::VERSION = '0.01';
# ABSTRACT: WebService::FaucetBOX - FaucetBOX (faucetbox.com) API bindings

use Moo;
with 'WebService::Client';

use Function::Parameters;


# sub BUILD {
#   my ($self) = @_;
#   $self->ua->add_handler("request_send",  sub { shift->dump; return });
#   $self->ua->add_handler("response_done", sub { shift->dump; return });
# }

around post => fun($orig, $self, $path, $params, %args) {
    $params->{api_key}               = $self->api_key;
    $params->{currency}              = $self->currency;
    $args{headers}->{'Content-Type'} = 'application/x-www-form-urlencoded';
    return $self->$orig($path, $params, %args);
};


has '+base_url' => ( default => 'https://faucetbox.com/api/v1' );


has currency => ( is => 'rw', default => 'BTC' );


has api_key => ( is => 'ro', required => 1 );



method send($to, $amount, :$referral = 'false') {
  return $self->post("/send", {
    to       => $to,
    amount   => $amount,
    referral => $referral
  });
}


method getBalance {
  return $self->post( "/balance" );
}


method getCurrencies {
  return $self->post( "/currencies" );
}


method getPayouts( $count ) {
  return $self->post( "/payouts", { count => $count } );
}


method sendReferralEarnings( $to, $amount ) {
  return $self->send($to, $amount, 'true');
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::FaucetBOX - WebService::FaucetBOX - FaucetBOX (faucetbox.com) API bindings

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $faucetbox = WebService::FaucetBOX->new(
        api_key    => 'abc',
        currency   => 'BTC', # optional, defaults to BTC
        logger     => Log::Tiny->new('/tmp/foo.log'), # optional
        log_method => 'info', # optional, defaults to 'DEBUG'
        timeout    => 10, # optional, defaults to 10
        retries    => 0,  # optional, defaults to 0
    );

    # To send 500 satoshi to address
    my $result = $faucetbox->send("1asdbitcoinaddressheredsa", 500);

See L<https://faucetbox.com/en/api> for call arguments

=head1 METHODS

=head2 base_url

=head2 currency

=head2 auth_token

=head2 send

=head2 getBalance

=head2 getBalance

=head2 getPayouts

=head2 sendReferralEarnings

=head1 SEE ALSO

=over 4

=item *

L<WebService::Client>

=back

=head1 AUTHOR

Todd Wade <waveright@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Todd Wade.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
