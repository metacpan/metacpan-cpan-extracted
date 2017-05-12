use strict;
use warnings;
use Test::More;
use Test::MobileAgent ':all';
use HTTP::MobileAgent;

my @Tests = (
    # ua, version, device_id, server, xhtml_compliant, comment, is_wap1, is_wap2
    [ 'UP.Browser/3.01-HI01 UP.Link/3.4.5.2',
      '3.01', 'HI01', 'UP.Link/3.4.5.2', undef, undef, 1, undef ],
    [ 'KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1',
      '6.0.2.276 (GUI)', 'TS21', 'MMP/1.1', 1, undef, undef, 1 ],
    [ 'UP.Browser/3.04-TS14 UP.Link/3.4.4 (Google WAP Proxy/1.0)',
      '3.04', 'TS14', 'UP.Link/3.4.4', undef, 'Google WAP Proxy/1.0', 1, undef ],
    [ 'UP.Browser/3.04-TST4 UP.Link/3.4.5.6',
      '3.04', 'TST4', 'UP.Link/3.4.5.6', undef, undef, 1, undef ],
    [ 'KDDI-KCU1 UP.Browser/6.2.0.5.1 (GUI) MMP/2.0',
      '6.2.0.5.1 (GUI)', 'KCU1', 'MMP/2.0', 1, undef, undef, 1 ],
    [ 'KDDI-SN31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0',
      '6.2.0.7.3.129 (GUI)','SN31','MMP/2.0', 1, undef, undef, 1 ],
);

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
    for (@Tests) {
        my($ua, @data) = @$_;

        my $agent = $cb->($ua);
        isa_ok $agent, 'HTTP::MobileAgent';
        isa_ok $agent, 'HTTP::MobileAgent::EZweb';
        is $agent->name, 'UP.Browser';
        ok !$agent->is_docomo && !$agent->is_j_phone && !$agent->is_vodafone && $agent->is_ezweb;
        is $agent->user_agent, $ua, "ua is $ua";

        is $agent->version, $data[0];
        is $agent->device_id, $data[1];
        is $agent->server, $data[2];
        is $agent->xhtml_compliant, $data[3];
        is $agent->comment, $data[4];
        ok $agent->is_wap1 if $data[5];
        ok $agent->is_wap2 if $data[6];

        if ($ua eq 'UP.Browser/3.04-TST4 UP.Link/3.4.5.6' 
            or $ua eq 'KDDI-KCU1 UP.Browser/6.2.0.5.1 (GUI) MMP/2.0'){
            ok $agent->is_tuka;
        } else {
            ok !$agent->is_tuka;
        }

        if ($ua eq 'KDDI-SN31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0'){
            ok $agent->is_win;
        } else {
            ok !$agent->is_win;
        }
    }

    for (test_mobile_agent_list('ezweb')) {
        my $agent = $cb->($_);
        isa_ok $agent, 'HTTP::MobileAgent', "$_";
        is $agent->name, 'UP.Browser';
        ok !$agent->is_docomo && !$agent->is_j_phone && !$agent->is_vodafone && $agent->is_ezweb;
    }

    for (qw{ezweb}) {
        my $user_id = 'userid';

        my $agent = $cb->($_,
            _user_id => $user_id,
        );
        like $agent->user_id => qr/^$user_id/, 'correct user_id';
    }
}

done_testing;
