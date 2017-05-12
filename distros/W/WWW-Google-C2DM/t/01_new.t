use strict;
use warnings;
use Test::More;
use WWW::Google::C2DM;

subtest 'auth_token required' => sub {
    eval { WWW::Google::C2DM->new() };
    like $@, qr/Usage: WWW::Google::C2DM->new\(auth_token => \$auth_token\)/;
};

subtest 'success' => sub {
    my $c2dm = WWW::Google::C2DM->new(auth_token => 'auth_token');
    isa_ok $c2dm, 'WWW::Google::C2DM';
    isa_ok $c2dm->{ua}, 'LWP::UserAgent';
};

subtest 'sets ua' => sub {
    my $c2dm = WWW::Google::C2DM->new(auth_token => 'auth_token', ua => 'Mypp::UserAgent');
    isa_ok $c2dm, 'WWW::Google::C2DM';
    is $c2dm->{ua}, 'Mypp::UserAgent';
};

done_testing;
