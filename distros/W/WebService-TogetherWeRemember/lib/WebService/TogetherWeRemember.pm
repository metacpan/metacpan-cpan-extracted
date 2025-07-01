package WebService::TogetherWeRemember;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

use Moo;
use LWP::UserAgent;
use HTTP::CookieJar::LWP;

has ua => (
	is => 'ro',
	default => sub {
		my $jar = HTTP::CookieJar::LWP->new;
		my $ua = LWP::UserAgent->new(cookie_jar => $jar);
		return $ua;
	}
);

has host => (
	is => 'ro',
	default => sub {
		return 'https://togetherweremember.com';
	} 
);

has version => (
	is => 'ro',
	default => sub {
		return 'v0';
	}
);

sub login {
	my $self = shift;
	my $api_version = $self->version;
	my $api_host = $self->host;
	my $api_class = "WebService::TogetherWeRemember::${api_version}::API";
	eval "require $api_class";
	if ($@) {
		die "Could not load API class $api_class: $@";
	}
	my $api = $api_class->new(
		ua => $self->ua,
		host => $api_host,
	);
	my $res = $api->login(@_);

	if ($res->{ok}) {
		return $api;
	}

	die "Login failed: $res->{error}";
}

=head1 NAME

WebService::TogetherWeRemember - Together We Remember!

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	use WebService::TogetherWeRemember;

	my $twr = WebService::TogetherWeRemember->new();

	my $api = $twr->login($email, $password);

	my $timeline = $api->timeline_create({
		name => "My First Timeline",
		description => $markdown_text,
		image => '/path/to/image.png',
		related_links => [
			{ label => "lnation", url => "https//lnation.org" }
		],
		passphrase => "123",
		is_public => 1,
		is_published => 0,
		is_open => 0,
	});

	my $memory = $api->memory_create($timline->{timeline}->{id}, {
		title => "My First Memory",
		content => $markdown_text,
		date => time,
		related_links => [
			{ label => "lnation", url => "https//lnation.org" }
		],
	});

	$api->memory_asset($timeline->{timeline}->{id}, $memory->{memory}->{id}, '/path/to/asset.mp4', 5 * 1024 * 1024);

	$api->logout();

See L<WebService::TogetherWeRemember::v0::API> for documentation.

L<Together We Remember|https://togetherweremember.com>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-togetherweremember at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-TogetherWeRemember>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::TogetherWeRemember

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-TogetherWeRemember>

=item * Search CPAN

L<https://metacpan.org/release/WebService-TogetherWeRemember>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of WebService::TogetherWeRemember
