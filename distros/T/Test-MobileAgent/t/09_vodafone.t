use strict;
use warnings;
use Test::More;
use Test::MobileAgent ':all';
use HTTP::MobileAgent;

my @Tests = (
    [ 'Vodafone/1.0/V802SE/SEJ001/SNXXXXXXXXX Browser/SEMC-Browser/4.1 Profile/MIDP-2.0 Configuration/CLDC-1.10', 
      '1.0', 'V802SE',1,'XXXXXXXXX',undef,undef, {
      Profile => 'MIDP-2.0',
      Configuration => 'CLDC-1.10',
      } ],
    [ 'MOT-V980/80.2B.04I MIB/2.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1',
      undef ,'V702MO',1,undef,undef,undef,{
      Profile => 'MIDP-2.0',
      Configuration => 'CLDC-1.1',
      }],
    [ 'Vodafone/1.0/V702NK/NKJ001 Series60/2.6 Profile/MIDP-2.0 Configuration/CLDC-1.1',
     '1.0','V702NK',1,undef,undef,undef,{
      Profile => 'MIDP-2.0',
      Configuration => 'CLDC-1.1',
      }],
    [ 'Nokia6820/2.0 (4.83) Profile/MIDP-1.0 Configuration/CLDC-1.0 (compatible; Googlebot-Mobile/2.1; +http://www.google.com/bot.html)',
      undef,'Nokia6820',undef,undef,undef,undef,{
          Profile => 'MIDP-1.0',
          Configuration => 'CLDC-1.0',
      }], # for funny googlebot
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

        # can't get the 3GC's "model" from user-agent.
        local $ENV{'HTTP_X_JPHONE_MSNAME'} = $data[1];
        my $agent = $cb->($ua);
        isa_ok $agent, 'HTTP::MobileAgent';
        isa_ok $agent, 'HTTP::MobileAgent::JPhone';
        ok !$agent->is_docomo && $agent->is_j_phone && $agent->is_vodafone && !$agent->is_ezweb;
        ok $agent->name eq 'Vodafone' || $agent->name =~ /^MOT/ ;

        is $agent->user_agent, $ua, "ua";
        is $agent->version, $data[0], "version";
        is $agent->model, $data[1], "model";
        is $agent->packet_compliant, $data[2], "packet compliant";

        is $agent->serial_number, $data[3], "serial";
        is $agent->vendor, $data[4], "vendor";
        is $agent->vendor_version, $data[5], "vendor version";
        is_deeply $agent->java_info, $data[6];

        ok $agent->is_type_3gc && !$agent->is_type_c && !$agent->is_type_p && !$agent->is_type_w;
    }


    for (test_mobile_agent_list('vodafone')) {
        my $agent = $cb->($_);
        isa_ok $agent, 'HTTP::MobileAgent', $_;
        ok $agent->name && ($agent->name,'Vodafone' || $agent->name =~ /^MOT/);
        ok !$agent->is_docomo && $agent->is_vodafone && !$agent->is_ezweb;
        ok $agent->is_type_3gc;
    }

    for (qw{vodafone}) {
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
