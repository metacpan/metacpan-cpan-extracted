package Virani::Client;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common;
use File::Slurp;

=head1 NAME

Virani::Client - Client for remotely accessing Virani vis HTTP or HTTPS.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Virani::Client;

    my $virani_client = Virani::Client->new(url=>$url);


=head1 METHODS


=head2 new

Initiates the object.

    - url :: The URL to use to contact mojo-virani by.
        Default :: undef

    - apikey :: The API key if needed.
        Default :: undef

    - timeout :: Timeout for fetching it in seconds.
        Default :: 60

    - verify_hostname :: Check the cert if using HTTPS.
        Default :: 1

Of the above keys, only 'url' is a requirement.

If verify_hostname is undef, the following enviromental variables are
checked in the following order.

    VIRANI_VERIFY_HOSTNAME
    HTTPS_VERIFY_HOSTNAME
    PERL_LWP_VERIFY_HOSTNAME

=cut

sub new {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{url} ) ) {
		die('No url defined');
	}

	if ( !defined( $opts{verify_hostname} ) ) {
		if ( defined( $ENV{VIRANI_VERIFY_HOSTNAME} ) ) {
			$opts{verify_hostname} = $ENV{VIRANI_VERIFY_HOSTNAME};
		}
		elsif ( defined( $ENV{HTTPS_VERIFY_HOSTNAME} ) ) {
			$opts{verify_hostname} = $ENV{HTTPS_VERIFY_HOSTNAME};

		}
		elsif ( defined( $ENV{PERL_LWP_VERIFY_HOSTNAME} ) ) {
			$opts{verify_hostname} = $ENV{PERL_LWP_VERIFY_HOSTNAME};
		}
		else {
			$opts{verify_hostname} = 1;
		}
	}

	my $self = {
		apikey          => $opts{apikey},
		url             => $opts{url},
		timeout         => 60,
		verify_hostname => $opts{verify_hostname},
	};
	bless $self;

	return $self;
}

=head2 fetch

Reaches out via HTTP or HTTPS and fetches the PCAP and JSON metadata.

    - start :: A L<Time::Piece> object of when to start looking.
        - Default :: undef

    - end :: A L<Time::Piece> object of when to stop looking.
        - Default :: undef

    - filter :: The BPF or tshark filter to use.
        - Default :: undef

    - set :: The PCAP set to use. Will use what ever the default is set to if undef or blank.
        - Default :: undef

    - file :: The file to output to. The metadata writen to a file of the same name
              with '.json' appended.
        - Default :: out.pcap

    - type :: 'tcpdump', 'bpf2tshark', or 'tshark', depending on what one wants the filter todo.
              If not set, the remote system uses what ever is defined as the default for that set.
        - Default :: undef

The following are required

    start
    end
    filter

IF the command success the raw unparsed JSON of the metadata is returned.

    my $raw_metadata_json=$virani_client->(start=>$start, end=>$end, filter=>$filter);

=cut

sub fetch {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{filter} ) ) {
		die('Nothing specified for $opts{filter}');
	}

	if ( !defined( $opts{file} ) ) {
		$opts{file} = 'out.pcap';
	}

	# basic sanity checking
	if ( !defined( $opts{start} ) ) {
		die('$opts{start} not defined');
	}
	elsif ( !defined( $opts{end} ) ) {
		die('$opts{start} not defined');
	}
	elsif ( ref( $opts{start} ) ne 'Time::Piece' ) {
		die('$opts{start} is not a Time::Piece object');
	}
	elsif ( ref( $opts{end} ) ne 'Time::Piece' ) {
		die('$opts{end} is not a Time::Piece object');
	}

	my $ua = LWP::UserAgent->new(
		protocols_allowed => [ 'http', 'https' ],
		timeout           => $self->{timeout},
	);
	if ( $self->{verify_hostname} ) {
		$ua->ssl_opts( verify_hostname => 1 );
	}
	else {
		$ua->ssl_opts( verify_hostname => 0, SSL_verify_mode => 0 );
	}

	$opts{filter} =~ s/\ /\%20/g;

	# put the url together
	my $url = $self->{url} . '?start=' . $opts{start}->epoch . '&end=' . $opts{end}->epoch;
	if (defined($opts{type})) {
		$url = $url . '&type=' . $opts{type};
	}
	if ( defined( $self->{apikey} ) ) {
		$url = $url . '&apikey=' . $self->{apikey};
	}
	if ( defined( $opts{set} ) ) {
		$url = $url . '&set=' . $opts{set};
	}
	$url = $url . '&bpf=' . $opts{filter};

	# get the PCAP
	my $res;
	eval { $res = $ua->request( GET $url); };
	if ($@) {
		die( 'Fetch failed... ' . $@ );
	}
	if ( $res->is_success ) {
		my $pcap = $res->decoded_content;
		write_file( $opts{file}, $pcap ) || die( 'PCAP write to "' . $opts{file} . '" failed... ' . $@ );
	}
	else {
		die( 'Fetch failed... ' . $url . ' ... ' . $res->status_line . ' ... ' . $res->decoded_content );
	}

	# get the meta
	$url = $url . '&get_meta=1';
	my $raw_json;
	eval { $res = $ua->request( GET $url); };
	if ($@) {
		die( 'Fetch failed... ' . $@ );
	}
	if ( $res->is_success ) {
		$raw_json = $res->decoded_content;
		print "Metadata...\n" . $raw_json;
	}
	else {
		die( 'Fetch failed... ' . $url . ' ... ' . $res->status_line . ' ... ' . $res->decoded_content );
	}

	return $raw_json;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-virani at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Virani>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Virani::Client


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Virani>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Virani>

=item * Search CPAN

L<https://metacpan.org/release/Virani>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Virani::Client
