use strict;
use warnings;
use Test::More;
use Test::MobileAgent ':all';
use HTTP::MobileAgent;

my $has_plack = eval "require Plack::Request; 1";

our @callbacks = (
    sub {
        local %ENV;
        test_mobile_agent(@_);
        HTTP::MobileAgent->new;
    },
    sub {
        my $headers = test_mobile_agent_headers(@_);
        HTTP::MobileAgent->new($headers);
    },
    $has_plack ? sub {
        my %env = test_mobile_agent_env(@_);
        my $r = Plack::Request->new(\%env);
        HTTP::MobileAgent->new($r->headers);
    } : (),
);

for my $cb (@callbacks) {
    for (test_mobile_agent_list('nonmobile')) {
        my $agent = $cb->($_);
        isa_ok $agent, 'HTTP::MobileAgent::NonMobile';
        ok ! $agent->is_docomo;
        ok ! $agent->is_j_phone;
        ok ! $agent->is_ezweb;
        ok $agent->is_non_mobile;
        ok $agent->model eq '';
        ok $agent->device_id eq '';
        ok $agent->carrier eq 'N';
        ok $agent->carrier_longname eq 'NonMobile';
        ok $agent->xhtml_compliant;
    }
}

done_testing;
