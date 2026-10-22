#!/usr/bin/perl
package oEdtk::FatalsToEmail;
use strict;
use warnings;

our $VERSION = '2.1131';

# by Randal L. Schwartz http://www.stonehenge.com/merlyn/LinuxMag/col14.html

#require oEdtk::FatalsToEmail;
#use oEdtk::FatalsToEmail	qw(
#					Address gu@mnt0.fr
#					Mailhost srv.smnt0.fr
#				);

my %config = (
	Address  => "webmaster",    # email address
	Mailhost => "localhost",    # mail server
	Cache    => undef,          # undef means don't use
	Seconds  => 60,
);

sub import {
	my $package = shift;
	while (@_) {
		my $key = ucfirst lc shift;
		die "ERROR: missing argument to $key" unless @_;
		die "ERROR: unknown argument $key"    unless exists $config{$key};
		$config{$key} = shift;
	}
}

$SIG{__DIE__} = \&trapper;

sub trapper {
	my $message = shift;
	my $time    = localtime;
	my ( $pack, $file, $line ) = caller;

	my $prefix = localtime;
	$prefix .= ":$$:$file:$line: ";
	$message =~ s/^/$prefix/mig;

	print STDOUT <<END;
	Content-Type: text/html

	<h1>Sorry!</h1>
	<p>An error has occurred; details have been logged.
	Please try your request again later.
	
END

	send_mail($message);

	die "ERROR: ${prefix}died - email sent to $config{Address} via $config{Mailhost}\n";
}

sub send_mail {
	my $message = shift;

	eval {
		## do I need to cache this?
		if ( defined( my $cache = $config{Cache} ) ) {
			my $cache_fh;
			if ( open( $cache_fh, '+<', $cache ) ) {
				flock $cache_fh, 2;
				## it's mine, see if it's old enough
				if ( time - ( stat($cache_fh) )[9] > $config{Seconds} ) {
					## yes, suck any content, and zero the file
					my $buf;
					$buf .= "\n...[truncated]...\n" if read( $cache_fh, $buf, 8192 ) >= 8192;
					$message = $buf . $message;
					seek $cache_fh, 0, 0;
					truncate $cache_fh, 0;
					close $cache_fh;
				}
				else {
					## no, so just drop the stuff at the end
					seek $cache_fh, 0, 2;
					print $cache_fh $message;
					close $cache_fh;
					return;
				}
			}
			else {
				## it doesn't exist, so create an empty file for stamping, and email
				open( $cache_fh, '>>', $cache ) or die "ERROR: Cannot create $cache: $!";
				close $cache_fh;
			}
		}
		eval { require Net::SMTP; 1 } or die "ERROR: no Net::SMTP";
		my $mail = Net::SMTP->new( $config{Mailhost} )
			or die "Net::SMTP->new returned $@";
		$mail->mail( $config{Address} ) or die "ERROR: from= $@";
		$mail->to( $config{Address} )   or die "ERROR: to= $@";
		$mail->data( "Subject: CGI FATAL ERROR in $0\n\n", $message )
			or die "ERROR: data= $@";
		$mail->quit or die "ERROR: quit said $@";
	};

	if ($@) {
		die "ERROR: $message(send_mail saw $@)\n";
	}
}

=head1 NAME

oEdtk::FatalsToEmail - turn fatal errors into an email

=head1 SYNOPSIS

    use oEdtk::FatalsToEmail
        Address  => 'admin@example.com',
        Mailhost => 'smtp.example.com';

=head1 DESCRIPTION

Installs a C<__DIE__> handler that prefixes the fatal message with its location,
prints a short apology, mails the details and then re-dies. The C<Address>,
C<Mailhost>, C<Cache> and C<Seconds> parameters are given at load time; when a
C<Cache> file is set, messages that arrive within C<Seconds> are coalesced into a
single email. Adapted from Randal L. Schwartz (Stonehenge).

=head1 FUNCTIONS

=head2 import

    use oEdtk::FatalsToEmail Address => $address, Mailhost => $smtp;

Set the module parameters at load time. An unknown key or a missing value is an
error.

=head2 send_mail

    send_mail($message);

Email C<$message> to the configured address through C<Net::SMTP>, optionally
through the cache file. Dies when the transfer fails.

The C<trapper> sub is the internal handler installed as C<$SIG{__DIE__}>; it is
not part of the public API.

=head1 AUTHOR

The oEdtk team.

=cut
