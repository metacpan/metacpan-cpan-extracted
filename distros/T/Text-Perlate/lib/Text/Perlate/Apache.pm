package Text::Perlate::Apache;

use 5.006;
use strict;
use warnings;

=pod

=head1 NAME

Text::Perlate::Apache - An Apache handler for Text::Perlate.

=head1 SYNOPSIS

Add the following to httpd.conf:

	<IfModule mod_perl.c>
		PerlTaintCheck On
		PerlWarn On
		PerlModule Text::Perlate::Apache
		<Files *.pl>
			SetHandler perl-script
			PerlHandler Text::Perlate::Apache
			PerlSendHeader On
		</Files>
	</IfModule>

=head1 DESCRIPTION

This module provides a way of calling perlates directly from Apache.  That is,
instead of writing a Perl program that calls Text::Perlate to run another file,
Apache can call the perlate directly using the filename in the URL.  PHP users
will find this approach familiar, except that this approach must include the
Content-Type header at the top of the file.  This passes the $r request object
as a parameter called $_params->{r}.

=head1 OPTIONS

The same options are available as in Text::Perlate.  A PerlRequire'd file can
specify defaults for these options in $Text::Perlate::defaults.

=cut

use Apache::Constants "OK", "DECLINED", "FORBIDDEN", "NOT_FOUND";
use Text::Perlate;

sub handler {
	my ($r) = @_;

	# Filename of the program to execute.
	my $filename = $r->filename();

	# Sanity checks for opening the file.
	unless(stat $filename) {
		$r->log_reason($!);
		return NOT_FOUND;
	}
	return DECLINED unless -f _;  # $filename isn't a plain file.  (It's probably a directory.)

	$r->print(Text::Perlate::main({
		input_file => $filename,
		params => {
			r => $r,
		},
		skip_path => 1,
	}));

	return OK;
}

1
