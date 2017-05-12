use strict;
use warnings;
use Test::More;
use Test::MobileAgent ':all';
use HTTP::MobileAgent;

my @Tests = (
    # ua, version, html_version, model, cache_size, is_foma, vendor, series, options, xhtml_compliant
    [ "DoCoMo/1.0/D501i", '1.0', '1.0', 'D501i', 5, undef, 'D', '501i', {}, 0 ],
    [ "DoCoMo/1.0/D502i", '1.0', '2.0', 'D502i', 5, undef, 'D', '502i', {}, 0 ],
    [ "DoCoMo/1.0/D502i/c10", '1.0', '2.0', 'D502i', 10, undef, 'D', '502i', {}, 0 ],
    [ "DoCoMo/1.0/D210i/c10", '1.0', '3.0', 'D210i', 10, undef, 'D', '210i', {}, 0 ],
    [ "DoCoMo/1.0/SO503i/c10", '1.0', '3.0', 'SO503i', 10, undef, 'SO', '503i', {}, 0 ],
    [ "DoCoMo/1.0/D211i/c10", '1.0', '3.0', 'D211i', 10, undef, 'D', '211i', {}, 0 ],
    [ "DoCoMo/1.0/SH251i/c10", '1.0', '3.0', 'SH251i', 10, undef, 'SH', '251i', {}, 0 ],
    [ "DoCoMo/1.0/R692i/c10", '1.0', '3.0', 'R692i', 10, undef, 'R', '692i', {}, 0 ],
    [ "DoCoMo/2.0 P2101V(c100)", '2.0', '3.0', 'P2101V', 100, 1, 'P', 'FOMA', {}, 0 ],
    [ "DoCoMo/2.0 N2001(c10)", '2.0', '3.0', 'N2001', 10, 1, 'N', 'FOMA', {}, 0 ],
    [ "DoCoMo/2.0 N2002(c100)", '2.0', '3.0', 'N2002', 100, 1, 'N', 'FOMA', {}, 0 ],
    [ "DoCoMo/2.0 D2101V(c100)", '2.0', '3.0', 'D2101V', 100, 1, 'D', 'FOMA', {}, 0 ],
    [ "DoCoMo/2.0 P2002(c100)", '2.0', '3.0', 'P2002', 100, 1, 'P', 'FOMA', {}, 0 ],
    [ "DoCoMo/2.0 MST_v_SH2101V(c100)", '2.0', '3.0', 'SH2101V', 100, 1, 'SH', 'FOMA', {}, 0 ],
    [ "DoCoMo/2.0 T2101V(c100)", '2.0', '3.0', 'T2101V', 100, 1, 'T', 'FOMA', {}, 0 ],
    [ "DoCoMo/1.0/D504i/c10", '1.0', '4.0', 'D504i', 10, undef, 'D', '504i', {}, 0 ],
    [ "DoCoMo/1.0/D504i/c30/TD", '1.0', '4.0', 'D504i', 30, undef, 'D', '504i', { status => 'TD' }, 0 ],
    [ "DoCoMo/1.0/D504i/c10/TJ", '1.0', '4.0', 'D504i', 10, undef, 'D', '504i', { status => 'TJ' }, 0 ],
    [ "DoCoMo/1.0/F504i/c10/TB", '1.0', '4.0', 'F504i', 10, undef, 'F', '504i', { status => 'TB' }, 0 ],
    [ "DoCoMo/1.0/D251i/c10", '1.0', '4.0', 'D251i', 10, undef, 'D', '251i', {}, 0 ],
    [ "DoCoMo/1.0/F251i/c10/TB", '1.0', '4.0', 'F251i', 10, undef, 'F', '251i', { status => 'TB' }, 0 ],
    [ "DoCoMo/1.0/F671iS/c10/TB", '1.0', '4.0', 'F671iS', 10, undef, 'F', '671i', { status => 'TB' }, 0 ],
    [ "DoCoMo/1.0/P503i/c10/serNMABH200331", '1.0', '3.0', 'P503i', 10, undef, 'P', '503i', { serial_number => 'NMABH200331' }, 0 ],
    [ "DoCoMo/2.0 N2001(c10;ser0123456789abcde;icc01234567890123456789)",
      '2.0', '3.0', 'N2001', 10, 1, 'N', 'FOMA', { serial_number => '0123456789abcde', card_id => '01234567890123456789' }, 0 ],
    [ "DoCoMo/1.0/eggy/c300/s32/kPHS-K", '1.0', '3.2', 'eggy', 300, undef, undef, undef, { bandwidth => 32 }, 0 ],
    [ "DoCoMo/1.0/P751v/c100/s64/kPHS-K", '1.0', '3.2', 'P751v', 100, undef, 'P', undef, { bandwidth => 64 }, 0 ],
    [ "DoCoMo/1.0/P209is (Google CHTML Proxy/1.0)", '1.0', '2.0', 'P209is', 5, undef, 'P', '209i', { comment => 'Google CHTML Proxy/1.0' }, 0 ],
    [ "DoCoMo/1.0/F212i/c10/TB", '1.0', '4.0', 'F212i', 10, undef, 'F', '212i', {}, 0 ],
    [ "DoCoMo/2.0 N2051(c100;TB)", '2.0', '4.0', 'N2051', 100, 1, 'N', 'FOMA', {}, 1 ],
    [ "DoCoMo/1.0/D505i/c20/TC/W20H10", '1.0', '5.0', 'D505i', 20, undef, 'D', '505i', { status => 'TC' }, 0 ],
    [ "DoCoMo/1.0/SH505i2/c20/TB/W20H10", '1.0', '5.0', 'SH505i', 20, undef, 'SH', '505i', { status => 'TB' }, 0 ],
    [ "DoCoMo/1.0/F661i/c10/TB", '1.0', '4.0', 'F661i', 10, undef, 'F', '661i', { is_gps => 1 }, 0 ],
    [ "DoCoMo/2.0 P07A3(c500;TB;W24H15)", '2.0', undef, 'P07A3', 500, 1, 'P', 'FOMA', { is_gps => 1, browser_version => '2.0' }, 1 ],
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
        isa_ok $agent, 'HTTP::MobileAgent::DoCoMo';
        ok $agent->is_docomo && ! $agent->is_j_phone && !$agent->is_vodafone && ! $agent->is_ezweb;
        is $agent->name, 'DoCoMo';
        is $agent->user_agent, $ua, "ua is $ua";
        is $agent->version, $data[0], "version";
        is $agent->html_version, $data[1], "HTML version";
        is $agent->model, $data[2], "model";
        is $agent->cache_size, $data[3], "cache size";
        is $agent->is_foma, $data[4], "is_foma";
        is $agent->vendor, $data[5], "vendor";
        is $agent->series, $data[6], "series";
        is $agent->xhtml_compliant, $data[8], "xhtml compliant $ua";
        if ($data[7]) {
            is $agent->$_(), $data[7]->{$_},"testing $_" for keys %{$data[7]};
        }
        is $agent->carrier, 'I' , "carrier is I";
        is $agent->carrier_longname, 'DoCoMo' ,  "carrier longname is DoCoMo";
    }

    {
        # SH905i is XHTML Compliant.
        my $agent = $cb->('DoCoMo/2.0 SH905i(c100;TB;W24H12)');
        is $agent->xhtml_compliant, 1;
    }

    for (test_mobile_agent_list('docomo')) {
        my $agent = $cb->($_);
        isa_ok $agent, 'HTTP::MobileAgent', "$_";
        is $agent->name, 'DoCoMo';
        ok $agent->is_docomo && ! $agent->is_j_phone && ! $agent->is_ezweb;
    }

    for (qw{docomo DoCoMo/1.0/SO503i/c10 docomo.N2001}) {
        my $user_id = 'userid';
        my $serial  = 'serial';
        my $card_id = 'cardid';

        my $agent = $cb->($_,
            _user_id       => $user_id,
            _serial_number => $serial,
            _card_id       => $card_id,
        );
        like $agent->user_id => qr/^$user_id/, 'correct user_id';
        like $agent->serial_number => qr/^$serial/,  'correct serial';
        if ($agent->is_foma) {
            like $agent->card_id => qr/^$card_id/, 'correct card id';
        }
    }
}

done_testing;
