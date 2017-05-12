# Declare our package
package Test::Reporter::POEGateway::Mailer::SMTP;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# Load some necessary modules
use POE::Filter::Reference;
use Email::Simple;
use Email::MessageID;

# The mailer config we use
my $config = undef;

# The smtp object
my $smtp = undef;

# This is the subroutine that will get executed upon the fork() call by our parent
sub main {
	# Autoflush to avoid weirdness
	$|++;

	# set binmode, thanks RT #43442
	binmode( STDIN );

	# Our Filter object
	my $filter = POE::Filter::Reference->new();

	# Sysread error hits
	my $sysreaderr = 0;

	MAINLOOP:

	# Okay, now we listen for commands from our parent :)
	while ( sysread( STDIN, my $buffer = '', 1024 ) ) {
		# Feed the line into the filter
		my $data = $filter->get( [ $buffer ] );

		# INPUT STRUCTURE IS:
		# $d->{'ACTION'}	= SCALAR	->	WHAT WE SHOULD DO
		# $d->{'DATA'}		= HASH		->	DATA FOR THE ACTION

		# Process each data structure
		foreach my $input ( @$data ) {
			## no critic ( ProhibitAccessOfPrivateData )
			# Now, we do the actual work depending on what kind of query it was
			if ( $input->{'ACTION'} eq 'CONFIG' ) {
				# Setup the config
				DO_CONFIG( $input->{'DATA'} );
			} elsif ( $input->{'ACTION'} eq 'SEND' ) {
				# Send a report!
				my $ret = DO_SEND( $input->{'DATA'} );
				if ( $ret->[0] ) {
					print "OK $ret->[1]\n";
				} else {
					print "NOK $ret->[1]\n";
				}
			} else {
				# Unrecognized action!
				print "ERROR Unknown action ($input->{'ACTION'})\n";
			}
		}
	}

	# Arrived here due to error in sysread/etc
	print "ERROR SYSREAD\n";

	# If we got more than 5 sysread errors, abort!
	if ( ++$sysreaderr == 5 ) {
		exit 0;
	} else {
		goto MAINLOOP;
	}

	return;
}

# initializes our config
sub DO_CONFIG {
	$config = shift;

	# set some sane defaults
	## no critic ( ProhibitAccessOfPrivateData )
	$config->{'to'} = 'cpan-testers@perl.org' if ! exists $config->{'to'};
	$config->{'smtp_host'} = 'localhost' if ! exists $config->{'smtp_host'};
	$config->{'smtp_opts'} = {} if ! exists $config->{'smtp_opts'};

	# Get rid of our old smtp if needed
	undef $smtp;

	return;
}

sub setup_smtp {
	return if defined $smtp;
	## no critic ( ProhibitAccessOfPrivateData )

	# Do we want ssl?
	my $pkg = 'Net::SMTP';
	if ( exists $config->{'ssl'} ) {
		$pkg .= '::SSL';
	}

	eval "require $pkg"; die $@ if $@;	## no critic ( ProhibitStringyEval )

	$smtp = $pkg->new(
		$config->{'smtp_host'},
		%{ $config->{'smtp_opts'} },
	);

	if ( ! defined $smtp ) {
		return "Unable to connect to the smtp server";
	}

	# Do AUTH if needed
	if ( exists $config->{'auth_user'} ) {
		if ( ! $smtp->auth( $config->{'auth_user'}, $config->{'auth_pass'} ) ) {
			return smtp_error( "Unable to AUTH to the smtp server" );
		}
	}

	return;
}

# return an error and cleanup smtp
sub smtp_error {
	my $err = shift;

	my $msg = $smtp->message;
	$msg =~ s/\s+\z//;				# damn Net::SMTP/Cmd not chomping it!
	$err .= ": '$msg' (" . $smtp->code() . ")";

	$smtp->quit;
	undef $smtp;

	return $err;
}

sub DO_SEND {
	my $data = shift;

	# init the smtp if needed
	my $ret = setup_smtp();
	if ( defined $ret ) {
		return [ 0, $ret ];
	}

	# send it!
	## no critic ( ProhibitAccessOfPrivateData )
	if ( ! $smtp->mail( $data->{'from'} ) ) {
		return [ 0, smtp_error( "Unable to set 'from' address" ) ];
	}

	if ( ! $smtp->to( $config->{'to'} ) ) {
		return [ 0, smtp_error( "Unable to set 'to' address" ) ];
	}

	# Prepare the data
	my $id = Email::MessageID->new->as_string;
	my $email = Email::Simple->create(
		'body'		=> $data->{'report'},
		'header'	=> [
			'To'			=> $config->{'to'},
			'From'			=> $data->{'from'},
			'Subject'		=> $data->{'subject'},
			'X-Reported-Via'	=> $data->{'via'},
			'Message-ID'		=> '<' . $id . '>',	# required, look at Email::MessageID for the note!
		],
	);

	if ( ! $smtp->data( $email->as_string ) ) {
		return [ 0, smtp_error( "Unable to send message" ) ];
	}

	# Successful send of message!
	return [ 1, $id ];
}

1;
__END__

=for stopwords AUTH smtp ssl

=head1 NAME

Test::Reporter::POEGateway::Mailer::SMTP - Sends reports via Net::SMTP

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;
	use Test::Reporter::POEGateway::Mailer;

	# let it do the work!
	Test::Reporter::POEGateway::Mailer->spawn(
		'mailer'	=> 'SMTP',
		'mailer_conf'	=> {
			'smtp_host'	=> 'smtp.mydomain.com',
			'smtp_opts'	=> {
				'Port'	=> '465',
				'Hello'	=> 'mydomain.com',
			},
			'ssl'		=> 1,
			'auth_user'	=> 'myuser',
			'auth_pass'	=> 'mypass',
		},
	);

	# run the kernel!
	POE::Kernel->run();

=head1 ABSTRACT

This module sends reports via Net::SMTP with some extra options.

=head1 DESCRIPTION

You normally use this module via the L<Test::Reporter::POEGateway::Mailer> module. You would need to configure the 'mailer' to 'SMTP' and
set any 'mailer_conf' options if needed.

The config this module accepts is:

=head3 smtp_host

The smtp server we will use to send emails.

The default is: localhost

=head3 smtp_opts

Extra options to pass to Net::SMTP if needed. Useful to set the port, for example.

The default is: {}

=head3 to

The destination address we will send reports to.

The default is: cpan-testers@perl.org

=head3 ssl

If enabled, this module will use Net::SMTP::SSL and attempt a secure connection to the host.

The default is: false

=head3 auth_user

The user to use for SMTP AUTH to the server. If defined, we will issue an AUTH command to the server. If not, we will skip this step on connection.

The default is: undef

=head3 auth_pass

The password to use for SMTP AUTH to the server.

The default is: undef

=head1 SEE ALSO

L<Test::Reporter::POEGateway::Mailer>

L<Net::SMTP>

L<Net::SMTP::SSL>

L<Authen::SASL>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
