package WWW::Noss::Curl;
use 5.016;
use strict;
use warnings;
our $VERSION = '1.04';

use Exporter qw(import);
our @EXPORT_OK = qw(curl curl_error);

our %CODES = (
	-1 => 'Failed to execute curl',
	0  => 'Success',
	1  => 'Unsupported protocol',
	2  => 'Failed to initialize curl',
	3  => 'Malformed URL',
	4  => 'Required feature disabled',
	5  => 'Could not resolve proxy',
	6  => 'Could not resolve host',
	7  => 'Failed to connect to host',
	8  => 'Weird server reply',
	9  => 'FTP access denied',
	10 => 'FTP accept failed',
	11 => 'Weird FTP PASS reply',
	12 => 'FTP session timeout expired',
	13 => 'Weird FTP PASV reply',
	14 => 'Weird FTP 227 reply',
	15 => 'Cannot use FTP host',
	16 => 'HTTP/2 error',
	17 => 'Failed to set FTP transfer to binary',
	18 => 'Could only receive partial file',
	19 => 'FTP file access error',
	21 => 'FTP quote error',
	22 => 'HTTP page not retrieved',
	23 => 'Write error',
	25 => 'FTP STOR error',
	26 => 'Read error',
	27 => 'Out of memory',
	28 => 'Operation timeout',
	30 => 'FTP PORT failed',
	31 => 'FTP REST failed',
	33 => 'HTTP range error',
	34 => 'HTTP post error',
	35 => 'SSL connection failed',
	36 => 'Failed to resume download',
	37 => 'Failed to open file',
	38 => 'LDAP bind failed',
	39 => 'LDAP search failed',
	41 => 'LDAP function not found',
	42 => 'Aborted',
	43 => 'Internal error',
	45 => 'Interface error',
	47 => 'Too many redirects',
	48 => 'Unknown option passed to libcurl',
	49 => 'Mailformed telnet option',
	52 => 'No server reply',
	53 => 'SSL crypto engine not found',
	54 => 'Cannot set SSL crypto engine as default',
	55 => 'Failed sending network data',
	56 => 'Failed to receive network data',
	58 => 'Problem with local certificate',
	59 => 'Could not use specified SSL cipher',
	60 => 'Peer certificate cannot be authenticated with known CA certificates',
	61 => 'Unrecognized transfer encoding',
	63 => 'Maximum file size exceeded',
	64 => 'Requested FTP SSL level failed',
	65 => 'Rewind failed',
	66 => 'Failed to initialize SSL engine',
	67 => 'Username or password not accepted',
	68 => 'TFTP file not found',
	69 => 'TFTP permission error',
	70 => 'TFTP out of disk space',
	71 => 'Illegal TFTP operation',
	72 => 'Unknown TFTP transfer ID',
	73 => 'TFTP file already exists',
	74 => 'TFTP no such user',
	77 => 'Problem reading SSL CA cert',
	78 => 'Resource referenced in URL does not exist',
	79 => 'Unspecified error occurred during SSH session',
	80 => 'Failed to shut down SSL connection',
	82 => 'Could not load CRL file',
	83 => 'Issuer check failed',
	84 => 'FTP PRET failed',
	85 => 'RTSP CSeq number mismatch',
	86 => 'RTSP Session ID mismatch',
	87 => 'Failed to parse FTP file list',
	88 => 'FTP chunk callback error',
	89 => 'No connection available',
	90 => 'SSL public key does not match pinned public key',
	91 => 'Invalid SSL certificate status',
	92 => 'Stream error in HTTP/2 framing layer',
	93 => 'API function called from inside callback',
	94 => 'Authentication function returned error',
	95 => 'Error detected in HTTP/3 layer',
	96 => 'QUIC connection error',
	# and maybe some more in the future...
);

sub curl_error {

	my ($code) = @_;

	return $CODES{ $code } // 'Unknown error';

}

sub curl {

	my ($link, $output, %param) = @_;
	my $verbose      = $param{ verbose      } // 0;
	my $agent        = $param{ agent        } // undef;
	my $time_cond    = $param{ time_cond    } // undef;
	my $remote_time  = $param{ remote_time  } // 0;
	my $etag_save    = $param{ etag_save    } // undef;
	my $etag_compare = $param{ etag_compare } // undef;
	my $limit_rate   = $param{ limit_rate   } // undef;
	my $user_agent   = $param{ user_agent   } // undef;
	my $timeout      = $param{ timeout      } // undef;
	my $fail         = $param{ fail         } // 0;
	my $proxy        = $param{ proxy        } // undef;
	my $proxy_user   = $param{ proxy_user   } // undef;

	my @cmd = ('curl', '-o', $output);

	if (!$verbose) {
		push @cmd, '-s';
	}

	if (defined $agent) {
		push @cmd, '-A', $agent;
	}

	if (defined $time_cond) {
		push @cmd, '-z', $time_cond;
	}

	if ($remote_time) {
		push @cmd, '-R';
	}

	if (defined $etag_save) {
		push @cmd, '--etag-save', $etag_save;
	}

	if (defined $etag_compare) {
		push @cmd, '--etag-compare', $etag_compare;
	}

	if (defined $limit_rate) {
		push @cmd, '--limit-rate', $limit_rate;
	}

	if (defined $user_agent) {
		push @cmd, '-A', $user_agent;
	}

	if (defined $timeout) {
		push @cmd, '-m', $timeout;
	}

	if ($fail) {
		push @cmd, '-f';
	}

	if (defined $proxy) {
		push @cmd, '-x', $proxy;
	}

	if (defined $proxy_user) {
		push @cmd, '-U', $proxy_user;
	}

	push @cmd, $link;

	system @cmd;

	return $? == -1 ? $? : $? >> 8;

}

1;

=head1 NAME

WWW::Noss::Curl - Interface to curl command

=head1 USAGE

  use WWW::Noss::Curl qw(curl);

  curl('https://url', 'output');

=head1 DESCRIPTION

B<WWW::Noss::Curl> is a module that provides an interface to the L<curl(1)>
command for fetching network resources. This is a private module, please
consult the L<noss> manual for user documentation.

=head1 SUBROUTINES

Subroutines are not automatically exported.

=over 4

=item $rt = curl($link, $output, [ %param ])

L<curl(1)> C<$link> and download it to C<$output>. C<%param> is an optional
hash argument of additional parameters to pass.

Returns the exit code of L<curl(1)>. A return value of C<0> means
success, non-zero means failure. C<curl_error()> can be used to describe
the return value.

The following are valid fields for the C<%param> hash:

=over 4

=item verbose

Boolean determining whether to enable verbose output or not. Corresponds to
L<curl(1)>'s C<--silent> option. Defaults to false.

=item agent

String to use as user agent. Corresponds to L<curl(1)>'s C<--user-agent> option.
Defaults to none.

=item time_cond

Only download a file if it has been modified past the given time. Can either
be a timestamp or file. Corresponds to L<curl(1)>'s C<--time-cond> option.
Defaults to none.

=item remote_time

Copy the remote file's modification time when downloading a file. Corresponds
to L<curl(1)>'s C<--remote-time> option. Defaults to false.

=item etag_save

Path to file to write remote file's etag to, if it has one. Corresponds to
L<curl(1)>'s C<--etag-save> option. Defaults to none.

=item etag_compare

Path to file to compare remote file's etag to, only downloading the remote file
if the etags differ. Corresponds to L<curl(1)>'s C<--etag-compare> option.
Defaults to none.

=item limit_rate

Download rate to limit L<curl(1)> to. Corresponds to L<curl(1)>'s
C<--limit-rate> option. Defaults to none.

=item user_agent

User agent string to send to server. Corresponds to L<curl(1)>'s
C<--user-agent> option. Defaults to none.

=item timeout

Maximum time in seconds a transfer is allowed to take. Corresponds to
L<curl(1)>'s C<--max-time> option. Defaults to no timeout.

=item fail

Boolean determining if L<curl(1)> should fail with no output on server errors.
Corresponds to L<curl(1)>'s C<--fail> option. Defaults to false.

=item proxy

Host to use as proxy. Corresponds to L<curl(1)>'s C<--proxy> option. Defaults
to none.

=item proxy_user

Username and password to use for proxy, seperated by a colon (C<user:pwd>).
Corresponds to L<curl(1)>'s C<--proxy-user> option. Defaults to none.

=back

=item $desc = curl_error($rt)

Returns the string description of the C<curl()> exit code C<$rt>.

=back

=head1 GLOBAL VARIABLES

=over 4

=item %WWW::Noss::Curl::CODES

Hash of C<curl()> exit codes and their corresponding string descriptions.
Use of the C<curl_error()> function is preferable.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/noss.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<curl(1)>, L<noss>

=cut

# vim: expandtab shiftwidth=4
