use strict;
use warnings;
use Test::More;
use WWW::Google::ClientLogin;

subtest 'email must be specified' => sub {
    eval { WWW::Google::ClientLogin->new() };
    like $@, qr/Usage: /;
};

subtest 'password must be specified' => sub {
    eval { WWW::Google::ClientLogin->new(email => 'foo', password => 'bar') };
    like $@, qr/Usage: /;
};

subtest 'service must be specified' => sub {
    eval { WWW::Google::ClientLogin->new(email => 'foo', password => 'bar') };
    like $@, qr/Usage: /;
};

subtest 'new ok' => sub {
    my $client = WWW::Google::ClientLogin->new(
        email    => 'foo',
        password => 'bar',
        service  => 'ac2dm',
    );

    isa_ok $client, 'WWW::Google::ClientLogin';
    is $client->{email}, 'foo';
    is $client->{password}, 'bar';
    is $client->{service}, 'ac2dm';
    is $client->{type}, 'HOSTED_OR_GOOGLE';
    is $client->{source}, "WWW::Google::ClientLogin_$WWW::Google::ClientLogin::VERSION";
    isa_ok $client->{ua}, 'LWP::UserAgent';
};

subtest 'all params' => sub {
    my $client = WWW::Google::ClientLogin->new(
        email    => 'foo',
        password => 'bar',
        service  => 'ac2dm',
        type     => 'GOOGLE',
        source   => 'foo_bar_0.1',
        ua       => LWP::UserAgent->new(),
    );

    isa_ok $client, 'WWW::Google::ClientLogin';
    is $client->{email}, 'foo';
    is $client->{password}, 'bar';
    is $client->{service}, 'ac2dm';
    is $client->{type}, 'GOOGLE';
    is $client->{source}, "foo_bar_0.1";
    isa_ok $client->{ua}, 'LWP::UserAgent';
};

done_testing;
