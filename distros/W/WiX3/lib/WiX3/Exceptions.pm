package WiX3::Exceptions;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.011';

use Exception::Class 1.29 (
	'WiX3::Exception' => {
		'description' => 'WiX3 error',
		'fields'      => [qw(message longmess)],
	},
	'WiX3::Exception::Unimplemented' => {
		'description' => 'Routine unimplemented',
		'isa'         => 'WiX3::Exception',
	},
	'WiX3::Exception::Parameter' => {
		'description' => 'Parameter missing or invalid',
		'isa'         => 'WiX3::Exception',
	},
	'WiX3::Exception::Parameter::Missing' => {
		'description' => 'Parameter missing',
		'isa'         => 'WiX3::Exception::Parameter',
	},
	'WiX3::Exception::Parameter::Invalid' => {
		'description' => 'Parameter invalid',
		'isa'         => 'WiX3::Exception::Parameter',
	},
	'WiX3::Exception::Parameter::Odd' => {
		'description' => 'Odd number of parameters when pairs required',
		'isa'         => 'WiX3::Exception::Parameter',
	},
	'WiX3::Exception::Parameter::Validation' => {
		'description' => 'Validation error',
		'isa'         => 'WiX3::Exception::Parameter',
		'fields'      => [qw(attribute type value)],
	},
	'WiX3::Exception::Caught' => {
		'description' => 'Error caught by WiX3 from other module',
		'isa'         => 'WiX3::Exception',
		'fields'      => [qw(message info longmess)],
	},

);

#sub WiX3::Exception::as_string {
#	return q{};
#}

sub WiX3::Exception::full_message {
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message() . "\n"
	  . '  Time error caught: '
	  . localtime() . "\n";
	require WiX3::Traceable;
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( ( $tracelevel > 1 ) or ( $self->longmess() ) ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	$misc->trace_line( 0, $string );

	return $string;
} ## end sub WiX3::Exception::full_message

sub WiX3::Exception::Unimplemented::full_message {
	my $self = shift;

	my $string =
	    'WiX3 error: '
	  . $self->description() . q{: }
	  . $self->message() . "\n"
	  . '  Time error caught: '
	  . localtime() . "\n";
	require WiX3::Traceable;
	my $misc = WiX3::Traceable->new();

	# Add trace to it.
	$string .= "\n" . $self->trace() . "\n";

	$misc->trace_line( 0, $string );

	return $string;
} ## end sub WiX3::Exception::Unimplemented::full_message

sub WiX3::Exception::Parameter::full_message {
	my $self = shift;

	my $string =
	    'WiX3 error: '
	  . $self->description() . ': '
	  . $self->message() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	require WiX3::Traceable;
	my $misc = WiX3::Traceable->new();

	# Add trace to it. (We automatically dump trace for parameter errors.)
	$string .= "\n" . $self->trace() . "\n";

	$misc->trace_line( 0, $string );

	return $string;
} ## end sub WiX3::Exception::Parameter::full_message

sub WiX3::Exception::Parameter::Validation::full_message {
	my $self = shift;

	my $string =
	    'WiX3 error: '
	  . $self->description()
	  . qq{:\n  '}
	  . $self->attribute()
	  . q{' not }
	  . $self->type()
	  . q{ (value passed in: '}
	  . $self->value
	  . qq{')\n}
	  . '  Time error caught: '
	  . localtime() . "\n";
	require WiX3::Traceable;
	my $misc = WiX3::Traceable->new();

	# Add trace to it. (We automatically dump trace for parameter errors.)
	$string .= "\n" . $self->trace() . "\n";

	$misc->trace_line( 0, $string );

	return $string;
} ## end sub WiX3::Exception::Parameter::Validation::full_message



sub WiX3::Exception::Caught::full_message {
	my $self = shift;

	my $string =
	    'WiX3 error: '
	  . $self->description() . ': '
	  . $self->message() . "\n"
	  . $self->info() . "\n"
	  . '  Time error caught: '
	  . localtime() . "\n";
	require WiX3::Traceable;
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( ( $tracelevel > 1 ) or ( $self->longmess() ) ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	$misc->trace_line( 0, $string );

	return $string;
} ## end sub WiX3::Exception::Caught::full_message

1;

__END__

=head1 NAME

WiX3::Exceptions - Exceptions used in the WiX3 distribution.

=head1 VERSION

This document describes WiX3::Exceptions version 0.009100

=head1 SYNOPSIS

    eval { new WiX3::XML::RegistryKey() };
	if ( my $e = WiX3::Exception::Parameter->caught() ) {

		my $parameter = $e->parameter;
		die "Bad Parameter $e passed in.";
	
	}
  
=head1 DESCRIPTION

This module defines the exceptions used by the WiX3 distribution.  All 
exceptions used are L<Exception::Class|Exception::Class> objects.

Note that uncaught exceptions will try to print out an understandable
error message, and if a high enough tracelevel is available, will print
out a stack trace, as well.

=head1 INTERFACE 

=head2 ::Parameter

Parameter exceptions will always print a stack trace.

=head3 $e->parameter()

The name of the parameter with the error.

=head3 $e->info()

Information about how the parameter was bad.

=head3 $e->where()

Information about what routine had the bad parameter.

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

This module provides the error diagnostics for the XML::WiX3::Objects 
distribution.  It has no diagnostics of its own.

=head1 CONFIGURATION AND ENVIRONMENT
  
XML::WiX3::Classes::Exceptions requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Exception::Class|Exception::Class> version 1.22 or later.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-wix3@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<Exception::Class|Exception::Class>

=head1 LICENCE AND COPYRIGHT

Copyright 2009, 2010 Curtis Jewell C<< <csjewell@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.1 itself. See L<perlartistic|perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

