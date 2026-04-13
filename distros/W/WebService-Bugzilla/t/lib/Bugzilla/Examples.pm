#!perl
# ABSTRACT: Common setup for example scripts

package Bugzilla::Examples;

use v5.24;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use WebService::Bugzilla;

sub get_client {
    my %opts = @_;

    my ($api_key, $base_url);

    GetOptions(
        'api-key=s' => \$api_key,
        'url=s'     => \$base_url,
    );

    $api_key //= $ENV{BUGZILLA_API_KEY};
    $base_url //= $opts{default_url} // $ENV{BUGZILLA_BASE_URL}
        // die "No base URL specified. Set BUGZILLA_BASE_URL or use --url\n";

    unless ($api_key) {
        die "No API key specified. Set BUGZILLA_API_KEY or use --api-key\n";
    }

    my $bz = WebService::Bugzilla->new(
        base_url => $base_url,
        api_key  => $api_key,
    );

    # Pretending to be curl tends to work around where many CDNs would present a capture
    $bz->ua->default_header('User-Agent'      => 'curl/8.7.1');
    $bz->ua->default_header('Accept'          => '*/*');
    $bz->ua->default_header('Accept-Encoding' => 'gzip, deflate, br');
    $bz->ua->default_header('Connection'      => 'keep-alive');

    return $bz;
}

1;

__END__

=head1 SYNOPSIS

    use lib 'lib';
    use Bugzilla::Examples qw(get_client);

    my $bz = get_client(default_url => 'https://bugs.freebsd.org');

=head1 DESCRIPTION

Provides a common way to set up Bugzilla API clients for example scripts.

=head1 ENVIRONMENT

=over 4

=item BUGZILLA_API_KEY

Your Bugzilla API key.

=item BUGZILLA_BASE_URL

The base URL for the Bugzilla instance (e.g., C<https://bugs.freebsd.org>).

=back

=head1 OPTIONS

=over 4

=item --api-key <key>

Override the API key from environment.

=item --url <url>

Override the base URL from environment.

=back
