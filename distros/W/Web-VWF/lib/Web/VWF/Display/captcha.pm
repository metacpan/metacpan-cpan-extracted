package Web::VWF::Display::captcha;

use strict;
use warnings;

use version; our $VERSION = version->declare('0.003.1');
use parent 'Web::VWF::Display';

sub html {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $config = $self->{'config'} or die "Missing 'config' handle";
	$self->{'info'} or die "Missing 'info' handle";

	# Get reCAPTCHA configuration
	my $recaptcha_config = $config->recaptcha();
	unless ($recaptcha_config && $recaptcha_config->{enabled}) {
		die 'reCAPTCHA is not enabled in configuration';
	}

	my $site_key = $recaptcha_config->{site_key};
	my $script_name = $ENV{'SCRIPT_NAME'} || '/cgi-bin/page.fcgi';

	# Get rate limit info for display
	my $soft_limit = $config->{'security'}->{'rate_limiting'}->{'max_requests'} || 100;
	my $time_window = $config->{'security'}->{'rate_limiting'}->{'time_window'} || '60s';
	$time_window =~ s/s$//;	# Remove 's' suffix

	# Determine if this is a hard block or soft limit
	my $is_hard_block = $args{'hard_block'} || 0;
	my $request_count = $args{'request_count'} || 0;

	if ($self->{'logger'}) {
		$self->{'logger'}->debug('Displaying CAPTCHA page for ' . ($is_hard_block ? 'hard block' : 'soft limit'));
	}

	return $self->SUPER::html({
		site_key => $site_key,
		script_name => $script_name,
		soft_limit => $soft_limit,
		time_window => $time_window,
		is_hard_block => $is_hard_block,
		request_count => $request_count,
	});
}

1;

=encoding utf8

=head1 NAME

Web::VWF::Display::captcha - The page that asks a client to prove it is a person

=head1 VERSION

Version 0.003.1

=head1 DESCRIPTION

Shown by L<Web::VWF> and not by C<?page=>, when a client goes over the soft rate
limit (see C<security.rate_limiting> in L<Web::VWF/CONFIGURATION>), and again,
with C<hard_block> set, with the hard limit's warning when reCAPTCHA is enabled.
The answer comes back as C<g-recaptcha-response>, which L<Web::VWF::CAPTCHA>
checks.

=head1 METHODS

=head2 html

Takes C<hard_block> and C<request_count>, both optional, which are only shown to
the client.  Dies when reCAPTCHA is not enabled or the object has no C<config> or
C<info>.  The template is F<captcha.tmpl>; it is given C<site_key>,
C<script_name> and the limits.

=head3 API SPECIFICATION

=head4 INPUT

	{ hard_block => { type => 'boolean', optional => 1 }, request_count => { type => 'integer', optional => 1 } }

=head4 OUTPUT

	{ type => 'string' }	# the HTML

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
