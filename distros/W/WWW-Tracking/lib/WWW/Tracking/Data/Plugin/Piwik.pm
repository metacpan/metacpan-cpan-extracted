package WWW::Tracking::Data::Plugin::Piwik;

use strict;
use warnings;

our $VERSION = '0.05';

use WWW::Tracking::Data;
use URI::Escape 'uri_escape';
use LWP::UserAgent;
use URI;
use URI::QueryParam;
use Carp::Clan 'croak';
use List::MoreUtils 'natatime';

our $PK_VERSION = 1;
our @URL_PAIRS = (
	'cip'   => 'remote_ip',             #
	'cid'   => 'visitor_id',            #
	'cdt'   => 'timestamp',             #
	'fla'   => 'flash_version',         #
	'java'  => 'java_version',
	'qt'    => 'quicktime_version',
	'realp' => 'realplayer_version',
	'pdf'   => 'pdf_support',
	'wma'   => 'mediaplayer_version',
	'gears' => 'gears_version',
	'ag'    => 'silverlight_version',
	'h'     => 'request_hour',
	'm'     => 'request_minute',
	's'     => 'request_second',
	'res'    => 'screen_resolution',
	'cookie' => 'cookie_support',
	'url'    => 'full_request_url',
	'urlref' => 'referer',
	'action_name' => 'request_uri',
);

sub _piwik_url {
	my $class         = shift;
	my $tracking_data = shift;
	
	my $pk_tracking_data = bless $tracking_data, 'WWW::Tracking::Data::Plugin::Piwik::DataFilter';
	my $tracker_account = $pk_tracking_data->_tracking->tracker_account;
	my $tracker_url     = $pk_tracking_data->_tracking->tracker_url;
	croak 'no tracker url set'
		unless $tracker_url;
	$tracker_url = URI->new($tracker_url);
	
	my $tracker_token;
	if ($tracker_account =~ m/^(\d):(.+)$/) {
		$tracker_account = $1;
		$tracker_token   = $2;
	}
	
	$tracker_url->query_param('idsite' => $tracker_account);
	$tracker_url->query_param('token_auth' => $tracker_token)
		if defined $tracker_token;
	$tracker_url->query_param('rec' => 1);
	$tracker_url->query_param('apiv' => $PK_VERSION);
	$tracker_url->query_param('rand' => $class->_uniq_rand_id);
	
	my $url_pair_it = natatime 2, @URL_PAIRS;
	while (my ($param_name, $prop) = $url_pair_it->()) {
		my $value = $pk_tracking_data->$prop;
		$tracker_url->query_param($param_name => $value)
			if defined $value;
	}

	return $tracker_url->as_string;
}

sub _uniq_rand_id {
	return int(rand(0x7fffffff));
}

1;

package WWW::Tracking::Data::Plugin::Piwik::DataFilter;

use base 'WWW::Tracking::Data';

use DateTime;

sub browser_language {
	my $self = shift;
	my $lang = $self->SUPER::browser_language(@_);
	
	return unless $lang;
	$lang =~ s/^( [a-zA-Z\-]{2,5} ) .* $/$1/xms;    # return only first language that can be either two letter or "en-GB" format
	return unless $lang;
	return $lang;
}

sub timestamp {
	my $self = shift;
	my $timestamp = $self->SUPER::timestamp(@_);
	
	return unless $timestamp;
	return DateTime->from_epoch( epoch => $timestamp )->strftime('%Y-%m-%d %H:%M:%S');
}

sub request_hour {
	my $self = shift;
	my $timestamp = $self->SUPER::timestamp;
	return unless $timestamp;
	return DateTime->from_epoch( epoch => $timestamp )->strftime('%H');
}

sub request_minute {
	my $self = shift;
	my $timestamp = $self->SUPER::timestamp;
	return unless $timestamp;
	return DateTime->from_epoch( epoch => $timestamp )->strftime('%M');
}
sub request_second {
	my $self = shift;
	my $timestamp = $self->SUPER::timestamp;
	return unless $timestamp;
	return DateTime->from_epoch( epoch => $timestamp )->strftime('%S');
}

sub flash_version {
	my $self = shift;
	my $flash_version = $self->SUPER::flash_version(@_);
	
	return unless defined $flash_version;
	return ($flash_version ? 1 : 0);
}

sub java_version {
	my $self = shift;
	my $java_version = $self->SUPER::java_version(@_);
	
	return unless defined $java_version;
	return ($java_version ? 1 : 0);
}

sub quicktime_version {
	my $self = shift;
	my $quicktime_version = $self->SUPER::quicktime_version(@_);
	
	return unless defined $quicktime_version;
	return ($quicktime_version ? 1 : 0);
}

sub realplayer_version {
	my $self = shift;
	my $realplayer_version = $self->SUPER::realplayer_version(@_);
	
	return unless defined $realplayer_version;
	return ($realplayer_version ? 1 : 0);
}

sub pdf_support {
	my $self = shift;
	my $pdf_support = $self->SUPER::pdf_support(@_);
	
	return unless defined $pdf_support;
	return ($pdf_support ? 1 : 0);
}

sub mediaplayer_version {
	my $self = shift;
	my $mediaplayer_version = $self->SUPER::mediaplayer_version(@_);
	
	return unless defined $mediaplayer_version;
	return ($mediaplayer_version ? 1 : 0);
}

sub gears_version {
	my $self = shift;
	my $gears_version = $self->SUPER::gears_version(@_);
	
	return unless defined $gears_version;
	return ($gears_version ? 1 : 0);
}

sub silverlight_version {
	my $self = shift;
	my $silverlight_version = $self->SUPER::silverlight_version(@_);
	
	return unless defined $silverlight_version;
	return ($silverlight_version ? 1 : 0);
}

sub visitor_id {
	my $self = shift;
	my $visitor_id = $self->SUPER::visitor_id(@_);
	
	return unless defined $visitor_id;
	return substr($visitor_id,0,16);
}

1;

package WWW::Tracking::Data;

use Carp::Clan 'croak';

sub as_piwik {
	my $self = shift;
	
	return WWW::Tracking::Data::Plugin::Piwik->_piwik_url($self);
}

sub make_tracking_request_piwik {
	my $self = shift;
	
	my $ua = LWP::UserAgent->new;
	$ua->default_header('Accept-Language' => $self->browser_language);
	$ua->agent($self->user_agent);
	my $ga_output = $ua->get($self->as_piwik);

	croak $ga_output->status_line
  		unless $ga_output->is_success;
	
	return $self;
}

1;

__END__

=head1 NAME

WWW::Tracking::Data::Plugin::Piwik - serialize to Piwik Tracking URL

=head1 SYNOPSIS

	use WWW::Tracking;
	use WWW::Tracking::Data::Plugin::Piwik;
	
    my $wt = WWW::Tracking->new(
        'tracker_account' => 5,
        'tracker_type'    => 'piwick',
		'tracker_url'     => 'http://stats.meon.eu/piwik.php',
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
