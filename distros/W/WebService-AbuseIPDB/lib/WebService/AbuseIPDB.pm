package WebService::AbuseIPDB;

use 5.010;
use strict;
use warnings;

# use other modules
use IO::Socket::SSL;
use REST::Client;
use Carp;
use JSON::XS;
use URI;    # The GET requests need URI-escaping

our $VERSION = '0.03';

sub new {
	my ($class, %opts) = @_;
	croak "Only version 2 is supported."
	  if exists $opts{ver} && 2 != $opts{ver};
	croak "No key provided." unless exists $opts{key};

	# This is weird. If you don't set the outer timeout it goes to 300.
	# If you do set the outer timeout, it sets the inner one too so it's
	# effectively doubled. Setting the inner timeout has no effect.
	my $self = {
		ua => REST::Client->new (
			{   host    => 'https://api.abuseipdb.com',
				timeout => $opts{timeout} // 20,
				agent   => "WebService::AbuseIPDB/$VERSION",

#			useragent => LWP::UserAgent->new (ssl_opts => {
#					verify_hostname => 1,
#				},
#				#timeout => $opts{timeout} // 20,
#			)
			}
		),
		retry   => $opts{retry} // 0,
		api_ver => $opts{ver}   // 2,
		key     => $opts{key},
	};
	bless ($self, $class);
	return $self;
}

sub _send_receive {
	my ($self, $meth, $path, $data) = @_;

	$path = "/api/v$self->{api_ver}/$path";
	my $ct = {'Content-type' => 'application/json'};
	my $headers = {
		Accept => 'application/json',
		Key    => $self->{key}
	};
	if ($meth eq 'GET') {
		my $u = URI->new ($path);
		$u->query_form (%$data);
		$path = $u->as_string;
	}
	my $tries_left = $self->{retry} + 1;
	while ($tries_left) {

		if ($meth eq 'GET') {
			$self->{ua}->GET ($path, $headers);
		} elsif ($meth eq 'POST') {
			$headers->{'Content-type'} = 'application/json';
			$self->{ua}->POST ($path, encode_json ($data), $headers);
		} else {
			croak "Unrecognised method '$meth'";
		}

		if ($self->{ua}->responseCode !~ /[45]00/) {
			return decode_json $self->{ua}->responseContent
			  if $self->{ua}->responseHeader ('Content-type') eq
			  'application/json';
			return undef;
		}
		$tries_left--;
		carp "REST error " . $self->{ua}->responseCode;
	}

	carp "Problem with $meth $path";
	carp "Data was " . encode_json ($data);
	carp "Client warning: ", $self->{ua}->responseHeader ('Client-Warning');
	return undef;
}

sub check {
	my ($self, %args) = @_;
	unless (exists $args{ip}) {
		carp "No IP in argument hash";
		return;
	}

	# Validate this here TODO
	my $data = {ipAddress => $args{ip}};
	$data->{maxAgeInDays} = $args{max_age} if exists $args{max_age};
	# TODO $data->{verbose} = 1 if $args{verbose};
	require WebService::AbuseIPDB::CheckResponse;
	return WebService::AbuseIPDB::CheckResponse->new (
		$self->_send_receive ('GET', 'check', $data));

}

sub report {
	my ($self, %args) = @_;
	for my $mand (qw/ip categories/) {
		unless (exists $args{$mand}) {
			carp "No '$mand' key in argument hash";
			return;
		}
	}

	# More validation here
	my $data = {ip => $args{ip}};

	# Form the category string
	# More validation here too
	require WebService::AbuseIPDB::Category;
	my @categories =
	  map { WebService::AbuseIPDB::Category->new ($_) } @{$args{categories}};
	$data->{categories} = join (',', map { $_->id } @categories);

	# Trim the comment
	$data->{comment} = substr ($args{comment}, 0, 1024)
	  if defined $args{comment};

	# Run it
	require WebService::AbuseIPDB::ReportResponse;
	return WebService::AbuseIPDB::ReportResponse->new (
		$self->_send_receive ('POST', 'report', $data));
}

sub blacklist {
	my ($self, %args) = @_;
	my $data = {
		limit => 1000,
		confidenceMinimum => 75
	};

	if (exists $args{limit}) {
		unless ($args{limit} =~ /^[0-9]+$/) {
			carp "limit must be a whole number";
			return;
		}
		if ($args{limit} < 1) {
			carp "limit must be greater than zero";
			return;
		}
		$data->{limit} = $args{limit};
	}

	if (exists $args{min_abuse}) {
		unless ($args{min_abuse} =~ /^[0-9]+$/) {
			carp "min_abuse must be a whole number";
			return;
		}
		if ($args{min_abuse} < 25) {
			carp "min_abuse is $args{min_abuse} but must be greater than 24";
			return;
		}
		if ($args{min_abuse} > 100) {
			carp "min_abuse is $args{min_abuse} but must be less than 100";
			return;
		}
		$data->{confidenceMinimum} = $args{min_abuse};
	}

	require WebService::AbuseIPDB::BlacklistResponse;
	require WebService::AbuseIPDB::BlacklistMember;
	return WebService::AbuseIPDB::BlacklistResponse->new (
		$self->_send_receive ('GET', 'blacklist', $data));

}

1;

__END__

=pod

=encoding utf8


=head1 NAME

WebService::AbuseIPDB - Client for the API (version 2) of AbuseIPDB

=head1 SYNOPSIS

    use WebService::AbuseIPDB;

    my $ipdb = WebService::AbuseIPDB->new (key => 'abc123...');
    my $res = $ipdb->check (ip => '127.0.0.2');
    die unless defined $res;
    printf "There is a %i%% chance this address is up to no good.\n",
        $res->score;

=head1 DESCRIPTION

L<https://www.abuseipdb.com/|AbuseIPDB> maintains a database of reports
of bad actors on the net. Users may interface with the database through
a web browser using forms on their site. An alternative is to use their
API. Version 1 of this API is to be retired in 2020. This module serves
as a client for Version 2 of the API.

=head1 SUBROUTINES/METHODS

=head2 new

    my $ipdb = WebService::AbuseIPDB->new (%opts);

The constructor takes a hash of configuration details.

=over

=item ver

The API version - always set this as "2" to avoid potential problems
with mismatched versions.

=item key

Your key for the API as a scalar string. You must obtain one before
using this module.

=item timeout

The timeout in seconds to wait for the server to respond. Defaults to
20.

=item retry

The number of times to retry on timeout or network error. Defaults to 0
(ie. no retries).

=back

=head2 check

    my $res = $ipdb->check (ip => '127.0.0.2', max_age => 90);

This uses the C<check> endpoint and returns a
L<WebService::AbuseIPDB::CheckResponse> object to access the data held
in the database for the provided IP address. The argument is a hash with
these keys:

=over

=item ip

The IP address to be checked. This item is mandatory.

=item max_age

The age in integral days of the oldest report(s) to include. If
omitted the server default is used (currently 30).

=item verbose

If set to any true value, the data from each report itself is also returned.
B<Not yet impelemented>.

=back

=head2 report

    my $res = $ipdb->report (
        ip          => '127.0.0.2',
        categories  => [3, 4],
        comment     => 'This address is the worst'
    );

This uses the C<report> endpoint to report an abusive address. It takes a
single hash as the only argument with these elements:

=over 4

=item ip

The IP address to report. Must be a single, valid IPv4 or IPv6 address.
This element is mandatory.

=item categories

An arrayref of categories as either scalar IDs or scalar names or
L<WebService::AbuseIPDB::Category> objects.
This element is mandatory.

=item comment

A scalar string with details of the offence. This is optional but
recommended in most cases. It must be no more than 1024 characters.
and should be decoded.

=back

The method will return undef on client error and a
WebService::AbuseIPDB::ReportResponse object otherwise.

=head2 blacklist

    my $res = $ipdb->blacklist (
        min_abuse   => 90,
        limit       => 1000
    );
    print "As at " . $res->as_at . "\n";
    for my $bad ($res->list) {
        printf "Address %s has score %i%%\n", $bad->ip, $bad->score;
    }

This uses the C<blacklist> endpoint to retrieve a list of abusive
addresses. It takes a single hash as the only argument with these
elements:

=over 4

=item min_abuse

Only include addresses with an abuse confidence score of this level or
higher. Minimum is 25, maximum is 100 and default is 75.

=item limit

An integer giving the maximum quantity of addresses to return. Minimum
is 1, maximum is 10,000 for non-subscribers and default is 1000.

=back

The method will return undef on client error and a
WebService::AbuseIPDB::BlacklistResponse object otherwise.


=head1 STABILITY

This is currently alpha software. Be aware that both the internals and
the interface are liable to change.

=head1 TODO

Implement the C<verbose> option on the check method.

Add the other API endpoints: check-block and bulk-report. Allow for fast
blacklist-as-string response too.

More validation/sanitation of inputs.

Consider using objects for errors instead of AoH.

=head1 SEE ALSO

L<SendMail::AbuseIPDB> is a client for v1 of the API.

Full documentation for the API is at L<https://docs.abuseipdb.com/>.

=head1 AUTHOR

Pete Houston, C<< <cpan at openstrike.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-abuseipdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-AbuseIPDB>.  See the file CONTRIBUTING.md for further details.

=head1 ACKNOWLEDGEMENTS

Thanks to AbuseIPDB for making the database publicly available via this
API.

=head1 LICENCE AND COPYRIGHT

Copyright © 2020 Pete Houston.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=cut
