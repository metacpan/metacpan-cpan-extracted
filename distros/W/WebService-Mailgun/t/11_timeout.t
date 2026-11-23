use strict;
use warnings;
use Test::More 0.98;
use WebService::Mailgun;

# This test never reaches a real API server: it looks only at what Furl->new is given.
my @args;
{
    no warnings 'redefine';
    my $new = \&Furl::new;
    *Furl::new = sub { my $class = shift; @args = @_; $new->($class, @_) };
}

sub furl_args_of {
    my (%new) = @_;
    @args = ();
    WebService::Mailgun->new(api_key => 'dummy-api-key', domain => 'example.com', %new)->client;
    return {@args};
}

is furl_args_of()->{timeout}, undef, 'without timeout, the default of Furl';
ok !exists furl_args_of()->{timeout}, 'timeout is not given to Furl at all';
is furl_args_of(timeout => 120)->{timeout}, 120, 'timeout is given to Furl';
like furl_args_of(timeout => 120)->{agent}, qr{^WebService::Mailgun/}, 'with the agent as before';

subtest 'set before the first request' => sub {
    my $mailgun = WebService::Mailgun->new(api_key => 'dummy-api-key', domain => 'example.com');
    $mailgun->timeout(30);
    @args = ();
    $mailgun->client;
    is {@args}->{timeout}, 30;
};

done_testing;
