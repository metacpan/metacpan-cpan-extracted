use strict;
use warnings;
use Test::More;
use Test::MobileAgent ':all';
use HTTP::MobileAgent;

my @Tests = (
    # ua, version, model, packet_compliant, serial_number, vendor, vendor_version, java_infos
    [ 'J-PHONE/2.0/J-DN02', '2.0', 'J-DN02', undef ],
    [ 'J-PHONE/3.0/J-PE03_a', '3.0', 'J-PE03_a', undef ],
    [ 'J-PHONE/4.0/J-SH51/SNJSHA3029293 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0',
      '4.0', 'J-SH51', 1, 'JSHA3029293', 'SH', '0001aa', {
          Profile =>'MIDP-1.0',
          Configuration => 'CLDC-1.0',
          'Ext-Profile' => 'JSCL-1.1.0',
      } ],
    [ 'J-PHONE/4.0/J-SH51/SNXXXXXXXXX SH/0001a Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0',
      '4.0', 'J-SH51', 1, 'XXXXXXXXX', 'SH', '0001a', {
          Profile => 'MIDP-1.0',
          Configuration => 'CLDC-1.0',
          'Ext-Profile' => 'JSCL-1.1.0',
      }],
    [ 'J-PHONE/5.0/V801SA', '5.0', 'V801SA', undef ],
    [ 'J-Phone/5.0/J-SH03 (compatible; Mozilla 4.0; MSIE 5.5; YahooSeeker)', '5.0', 'J-SH03', undef ],
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
        isa_ok $agent, 'HTTP::MobileAgent::JPhone';
        ok !$agent->is_docomo && $agent->is_j_phone && $agent->is_vodafone && !$agent->is_ezweb;
        is $agent->name ,'J-PHONE';

        is $agent->user_agent, $ua, "ua is $ua";
        is $agent->version, $data[0], "version is $data[0]";
        is $agent->model, $data[1], "model is $data[1]";
        is $agent->packet_compliant, $data[2], "packet compliant?";
        if (@data > 3) {
            is $agent->serial_number, $data[3], "serial is $data[3]";
            is $agent->vendor, $data[4], "vendor is $data[4]";
            is $agent->vendor_version, $data[5], "vendor version is $data[5]";
            is_deeply $agent->java_info, $data[6];
        }

        if($ua eq 'J-PHONE/2.0/J-DN02'){
                ok $agent->is_type_c && ! $agent->is_type_p && ! $agent->is_type_w;
        }
        if($ua eq 'J-PHONE/3.0/J-PE03_a'){
                ok $agent->is_type_c && ! $agent->is_type_p && ! $agent->is_type_w;
        }
        if($ua eq 'J-PHONE/4.0/J-SH51/SNJSHA3029293 SH/0001aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.1.0') {
                ok !$agent->is_type_c && $agent->is_type_p && !$agent->is_type_w;
        }
        if($ua eq 'J-PHONE/5.0/V801SA'){
                ok !$agent->is_type_c && !$agent->is_type_p && $agent->is_type_w;
        }

        is $agent->carrier, 'V' , "carrier is V";
        is $agent->carrier_longname, 'Vodafone' ,  "carrier longname is Vodafone";
    }

    for (test_mobile_agent_list('jphone')) {
        my $agent = $cb->($_);
        isa_ok $agent, 'HTTP::MobileAgent', "$_";
        is $agent->name, 'J-PHONE';
        ok !$agent->is_docomo && $agent->is_j_phone && !$agent->is_ezweb;
    }

    for (qw{jphone.V501SH}) {
        my $user_id = 'userid';
        my $serial  = 'serial';

        my $agent = $cb->($_,
            _user_id       => $user_id,
            _serial_number => $serial,
        );
        like $agent->user_id => qr/^$user_id/, 'correct user_id';
        like $agent->serial_number => qr/^$serial/, 'correct serial';
    }
}

done_testing;
