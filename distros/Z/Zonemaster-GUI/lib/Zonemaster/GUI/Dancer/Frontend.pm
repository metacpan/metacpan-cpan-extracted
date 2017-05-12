package Zonemaster::GUI::Dancer::Frontend;

use 5.14.2;
use warnings;

use Encode qw[decode_utf8];

our $VERSION = '1.0.7';

###
### Fetch the FAQ source documents
###

use Text::Markdown 'markdown';
use HTTP::Tiny;

my $faq_url_base = 'https://raw.githubusercontent.com/dotse/zonemaster-gui/master/docs/FAQ/gui-faq-%s.md';
my %faqs;
my $http = HTTP::Tiny->new;
for my $lang ( qw[sv en fr] ) {
    my $r = $http->get( sprintf( $faq_url_base, $lang ) );
    if ( $r->{success} and $r->{headers}{'content-type'} eq 'text/plain; charset=utf-8' ) {
        $faqs{$lang} = markdown( decode_utf8( $r->{content} ) );
        $faqs{$lang} =~ s/<a/<a style="color: white;"/isg;
        $faqs{$lang} =~ s/<h4/<br><h4/isg;
    }
    elsif ( $r->{success} ) {
        $faqs{$lang} = 'Unexpected content-type for FAQ: ' . $r->{headers}{'content-type'};
    }
    else {
        $faqs{$lang} = 'FAQ content missing.';
    }
}

###
### Proceed with Dancer stuff
###

use Dancer ':syntax';
use Zonemaster::GUI::Dancer::Client;

my $backend_port = 5000;
$backend_port = $ENV{ZONEMASTER_BACKEND_PORT} if ($ENV{ZONEMASTER_BACKEND_PORT});
my $url = "http://localhost:$backend_port";
my $client = Zonemaster::GUI::Dancer::Client->new( { url => $url } );
set logger => 'console';

set logger => 'console';

get '/' => sub {
    template 'index';
};

get '/test/:id' => sub {
    my $lang = request->{'accept_language'};
    $lang =~ s/,.*$//;
    my $result = $client->get_test_results( { params, language => $lang } );
    template 'index', { test_id => param( 'id' ) };
};

get '/parent' => sub {
    my $result = $client->get_data_from_parent_zone( param( 'domain' ) );
    content_type 'application/json';
    return to_json( { result => $result } );
};

sub get_ip {
    my $ip = request->address;
    $ip = request->header('X-Forwarded-For') if (($ip =~ /127\.0\.0\.1/ || $ip =~ /::1/) && request->header('X-Forwarded-For'));
    $ip =~ s/::ffff:// if ( $ip =~ /::ffff:/ );
    
    return $ip;
}

get '/version' => sub {
    my $data = $client->version_info( {} );
    my $ip = get_ip();
    content_type 'application/json';
    my $version;
    if ($ENV{ZONEMASTER_ENVIRONMENT}) {
		$version = $ENV{ZONEMASTER_ENVIRONMENT}." [Engine:".$data->{zonemaster_engine} . " / Frontend:$VERSION / Backend:".$data->{zonemaster_backend} . " / IP address: $ip]";
	}
	else {
		$version = "Zonemaster Test Engine Version:".$data->{zonemaster_engine} . ", IP address: $ip";
	}
	
    return to_json( { result => $version } );
};

get '/check_syntax' => sub {
    my $data = from_json( param( 'data' ), { utf8 => 0 } );
    my $result = $client->validate_syntax( {%$data} );
    content_type 'application/json';
    return to_json( { result => $result } );
};

get '/history' => sub {
    my $data = from_json( param( 'data' ), { utf8 => 0 } );
    my $result = $client->get_test_history( { frontend_params => {%$data}, limit => 200, offset => 0 } );
    content_type 'application/json';
    return to_json( { result => $result } );
};

get '/resolve' => sub {
    my $data   = param( 'data' );
    my $result = $client->get_ns_ips( $data );
    content_type 'application/json';
    return to_json( { result => $result } );
};

post '/run' => sub {
    my $data = from_json( param( 'data' ), { utf8 => 0 } );
    $data->{client_id}      = 'Zonemaster Dancer Frontend';
    $data->{client_version} = __PACKAGE__->VERSION;

    $data->{user_ip} = get_ip();
    
    my $job_id = $client->start_domain_test( {%$data} );
    content_type 'application/json';
    return to_json( { job_id => $job_id } );
};

get '/progress' => sub {
    my $progress = $client->test_progress( param( 'id' ) );
    header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );
    content_type 'application/json';
    return to_json( { progress => $progress } );
};

get '/result' => sub {
    my $result = $client->get_test_results( {params} );
    content_type 'application/json';
    return to_json( { result => $result } );
};

get '/faq' => sub {
    return to_json( { FAQ_CONTENT => $faqs{ param('lang') } } );
};

true;
