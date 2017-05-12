package WWW::Tracking::Data::Plugin::GoogleAnalytics;

use strict;
use warnings;

our $VERSION = '0.05';

use WWW::Tracking::Data;
use URI::Escape 'uri_escape';
use LWP::UserAgent;

our $UTM_GIF_LOCATION = 'http://www.google-analytics.com/__utm.gif';
our $GA_VERSION = '4.4sp';
our @URL_PAIRS = (
	'utmhn'  => 'hostname',              # Host Name, which is a URL-encoded string.
	'utmp'   => 'request_uri',           # Page request of the current page. 
	'utmr'   => 'referer',               # Referral, complete URL.
	'utmvid' => 'visitor_id',            #
	'utmip'  => 'remote_ip',             #
	'utmcs'  => 'encoding',              # Language encoding for the browser. Some browsers don't set this, in which case it is set to "-"
	'utmul'  => 'browser_language',      # Browser language.
	'utmje'  => 'java_version',          # Indicates if browser is Java-enabled. 1 is true.
	'utmsc'  => 'screen_color_depth',    # Screen color depth
	'utmsr'  => 'screen_resolution',     # Screen resolution
	'utmfl'  => 'flash_version',         # Flash Version
);

sub _map2(&@){ 
    my $code = shift; 
    map $code->( shift, shift ), 0 .. $#_/2 
}

sub _utm_url {
	my $class         = shift;
	my $tracking_data = shift;
	
	my $ga_tracking_data = bless $tracking_data, 'WWW::Tracking::Data::Plugin::GoogleAnalytics::DataFilter';
	my $tracker_account = $ga_tracking_data->_tracking->tracker_account;

	return
		$UTM_GIF_LOCATION
		.'?'
		.'utmwv='.$GA_VERSION
		.'&utmac='.$tracker_account                    # Account String. Appears on all requests.
		.'&utmn='.$class->_uniq_gif_id                 # Unique ID generated for each GIF request to prevent caching of the GIF image. 
		.'&utmcc=__utma%3D999.'.substr($ga_tracking_data->visitor_id,0,16).'.999.999.999.1%3B'    # Cookie values. This request parameter sends all the cookies requested from the page.
		.join(
			'',
			_map2 {
				my $prop = $_[1];
				my $value = $ga_tracking_data->$prop;
				(defined $value ? '&'.$_[0].'='.uri_escape($ga_tracking_data->$prop) : ())
			}
			@URL_PAIRS
		)
	;
}

sub _uniq_gif_id {
	return int(rand(0x7fffffff));
}

1;

package WWW::Tracking::Data::Plugin::GoogleAnalytics::DataFilter;

use base 'WWW::Tracking::Data';

sub browser_language {
	my $self = shift;
	my $lang = $self->SUPER::browser_language(@_);
	
	return unless $lang;
	$lang =~ s/^( [a-zA-Z\-]{2,5} ) .* $/$1/xms;    # return only first language that can be either two letter or "en-GB" format
	return unless $lang;
	return $lang;
}

sub remote_ip {
	my $self = shift;
	my $ip = $self->SUPER::remote_ip(@_);
	
	return unless $ip;
	return unless $ip =~ m/^( (?: \d{1,3} [.] ){3} ) \d{1,3} $/xms;    # capture only first 3 numbers from ip
	return $1.'0';
}

sub java_version {
	my $self = shift;
	my $java_version = $self->SUPER::java_version(@_);
	
	return unless defined $java_version;
	return ($java_version ? 1 : 0);
}

1;

package WWW::Tracking::Data;

use Carp::Clan 'croak';

sub as_ga {
	my $self = shift;
	
	return WWW::Tracking::Data::Plugin::GoogleAnalytics->_utm_url($self);
}

sub make_tracking_request_ga {
	my $self = shift;
	
	my $ua = LWP::UserAgent->new;
	$ua->default_header('Accept-Language' => $self->browser_language);
	$ua->agent($self->user_agent);
	my $ga_output = $ua->get($self->as_ga);

	croak $ga_output->status_line
  		unless $ga_output->is_success;
	
	return $self;
}

1;

__END__

=head1 NAME

WWW::Tracking::Data::Plugin::GoogleAnalytics - serialize to Google Analytics URL

=head1 SYNOPSIS

	use WWW::Tracking;
	use WWW::Tracking::Data::Plugin::GoogleAnalytics;
	
    my $wt = WWW::Tracking->new(
        'tracker_account' => 'MO-9226801-5',
        'tracker_type'    => 'ga',
    );
    $wt->from(
		'headers' => {
			'headers'     => $headers,
			'request_uri' => $request_uri,
			'remote_ip'   => $remote_ip,
			'visitor_cookie_name' => $VISITOR_COOKIE_NAME,
		},
    );
    
    my $visitor_id = $wt->data->visitor_id;    
    my $tracking_cookie = Apache2::Cookie->new(
        $apache,
        '-name'    => $VISITOR_COOKIE_NAME,
        '-value'   => $visitor_id,
        '-expires' =>  '+3M',
        '-path'    =>  '/',
    );
    $tracking_cookie->bake($apache);
    
    eval { $wt->make_tracking_request; };
    if ($@) {
        $logger->warn('failed to do request tracking - '.$@);
    }

=head1 DESCRIPTION

=cut
