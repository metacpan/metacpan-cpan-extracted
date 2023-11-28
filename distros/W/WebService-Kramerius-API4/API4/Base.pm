package WebService::Kramerius::API4::Base;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use LWP::UserAgent;

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Library URL.
	$self->{'library_url'} = undef;

	# LWP::UserAgent instance.
	$self->{'lwp_ua'} = undef;

	# Output dispatch.
	$self->{'output_dispatch'} = {};

	# Verbose output.
	$self->{'verbose'} = 0;

	# Process params.
	set_params($self, @params);

	# Check library URL.
	if (! defined $self->{'library_url'}) {
		err "Parameter 'library_url' is required.";
	}

	# LWP::UserAgent.
	if (! $self->{'lwp_ua'}) {
		$self->{'lwp_ua'} = LWP::UserAgent->new;
		$self->{'lwp_ua'}->agent('WebService::Kramerius::API4/'.$VERSION);
	}

	# Object.
	return $self;
}

sub _construct_opts {
	my ($self, $opts_hr) = @_;

	# TODO Use URI?

	my $opts = '';
	foreach my $key (keys %{$opts_hr}) {
		if ($opts) {
			$opts .= '&';
		}
		my $ref = ref $opts_hr->{$key};
		if ($ref eq 'ARRAY') {
			$opts .= $key.'='.(join ',', @{$opts_hr->{$key}});
		} elsif ($ref eq '') {
			$opts .= $key.'='.$opts_hr->{$key};
		} else {
			err "Reference to '$ref' doesn't supported.";
		}
	}
	if ($opts) {
		$opts = '?'.$opts;
	}

	return $opts;
}

sub _get_data {
	my ($self, $url) = @_;

	if ($self->{'verbose'}) {
		print "URL: $url\n";
	}
	my $req = HTTP::Request->new('GET' => $url);
	my $res = $self->{'lwp_ua'}->request($req);
	if (! $res->is_success) {
		err "Cannot get '$url' URL.",
			'HTTP code', $res->code,
			'message', $res->message,
		;
	}
	my $content_type = $res->headers->content_type;

	# XXX Hack for forced content type.
	if (exists $self->{'_force_content_type'}) {
		$content_type = delete $self->{'_force_content_type'};
	}

	my $ret = $res->content;
	if (exists $self->{'output_dispatch'}->{$content_type}) {
		$ret = $self->{'output_dispatch'}->{$content_type}->($ret);
	}

	return $ret;
}

sub _validate_opts {
	my ($self, $opts_hr, $valid_opts_ar) = @_;

	foreach my $opt_key (keys %{$opts_hr}) {
		if (none { $opt_key eq $_ } @{$valid_opts_ar}) {
			err "Option '$opt_key' doesn't supported.";
		}
	}

	return;
}

1;

__END__

