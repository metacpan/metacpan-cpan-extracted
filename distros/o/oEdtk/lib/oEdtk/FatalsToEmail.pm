#!/usr/bin/perl
package oEdtk::FatalsToEmail;
use strict;
use warnings;

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
