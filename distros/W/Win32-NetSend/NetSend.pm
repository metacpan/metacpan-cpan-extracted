package Win32::NetSend;

our $VERSION="0.02";
#our $ABSTRACT="Sends message from NT to NT or Win9x running winpopup";

#use strict;
use warnings;
use Carp;
use Fcntl qw(:DEFAULT :flock);

sub new
{
	my ($to,%options)=@_;

	if ( $^O ne 'MSWin32' ) {
		carp "ERROR: Invalid. Module only for Windows.";
		return 0;
	}

	use Win32;
	if (! Win32::IsWinNT()) {
		carp "ERROR: Invalid. Module only for Windows NT.";
		return 0;
	}

	my $self = {
		to => $options{to},
		message => $options{message}
	};
	return bless $self;
}

sub Send
{
	my ($self,%options)=@_;

	if (exists $options{to}) {
		$self->{to} = $options{to};
	}

	if (exists $options{message}) {
		$self->{message} = $options{message};
	}

	if ( $self->{to} eq "" or $self->{message} eq "" ) {
		carp "ERROR: Invalid type. You should use to and message";
		return 0;
	}

	# Message... Convert to Unicode
	my($message_w) = "$self->{message}";
	$message_w =~ s/./$&\0/g;
	$message_w .= "\0";

	# To... Convert to Unicode
	my($to_w) = "$self->{to}";
	$to_w =~ s/./$&\0/g;
	$to_w .= "\0";

	# Get DLL Function Entry Point
	use Win32::API;
	my($NetSend) = new Win32::API('netapi32.dll', 'NetMessageBufferSend', [P,P,P,P,I], I);
	if(not defined $NetSend) {
		carp "ERROR: Invalid. Can't import API NetMessageBufferSend:";
		return 0;
	}

	# And Send!!!
	my($CallNetSend) = $NetSend->Call(
		0,						# Servername
		"$to_w",				# msgName
		0,						# FromName
		"$message_w",			# Buff
		length("$message_w"));	# Length Buff

	return $CallNetSend;
}

1;

=head1 NAME

Win32::NetSend - Sends message from NT to NT or Win9x running winpopup

Version 0.2

=head1 SYNOPSIS

	use Win32::NetSend;

	my $NetSend = Win32::NetSend->new(
		to => "user",
		message => "hello world!");
	$NetSend->Send();

Or can use it:

	my $NetSend = Win32::NetSend->new();
	$NetSend->Send(
		to => "user",
		message => "hello world");

=head1 DESCRIPTION

	This module sends message from NT to NT or Win9x running winpopup.

	This module is a small and simple Perl GUI utility to send messages
	via MS LAN Manager to lists of recipients. It works in the same
	manner as "net send" command.

	The utility can be used if you need to send the same message to
	groups of people. For instance, you are going to update some server
	software and have to ask the users who work with the software to log
	off.

=head1 PLATAFORMS

	This module work in:

	Win95	- Only receive if running winpopup
	Win98	- Only receive if running winpopup
	WinMe	- Only receive if running winpopup

	WinNT4	- Full support, send an receive
	Win2000	- Full support, send an receive
	WinXP	- Full support, send an receive


=head1 Functions

=over 4

=item Send

	Send(
		to => "user",
		message => "hello world");

Send a message to user, machine, domain. For actual domain use *

=back

=head1 SEE ALSO

B<Win32::NetSend> requires L<Win32::API> .

=head1 STATUS

This version (0.02) is a beta version. You can use it but interface may change.

=head1 AUTHOR

Victor Sanchez <vsanchez@cpan.org>

=head2 THANKS

Thanks to people of Perl-ES ( htpp://perl-es.sf.net )

=head1 COPYRIGHT

(c) Copyright 2002, 2003 Victor Sanchez <vsanchez@cpan.org>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
