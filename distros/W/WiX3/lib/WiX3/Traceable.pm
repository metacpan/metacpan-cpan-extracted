package WiX3::Traceable;

use 5.008003;

#use metaclass (
#	base_class  => 'MooseX::Singleton::Object',
#	metaclass   => 'MooseX::Singleton::Meta::Class',
#	error_class => 'WiX3::Util::Error',
#);
use MooseX::Singleton;
use WiX3::Util::StrictConstructor;
use WiX3::Trace::Object 0.011;
use WiX3::Types qw( TraceObject );

our $VERSION = '0.011';

with 'WiX3::Role::Traceable';

has _traceobject => (
	is       => 'bare',
	isa      => TraceObject,
	init_arg => 'options',
	weak_ref => 1,
	default  => sub { WiX3::Trace::Object->new() },
);

sub BUILDARGS {
	my $class = shift;
	my %args;

	if ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{ $_[0] };
	} else {
		%args = (@_);
	}

	##no critic ( RequireCarping RequireUseOfExceptions ProtectPrivateSubs )
	my $obj;
	eval {
		$obj = WiX3::Trace::Object->new(%args);
		1;
	} || eval {
		WiX3::Trace::Object->_clear_instance();
		$obj = WiX3::Trace::Object->new(%args);
		1;
	} || die 'Could not create trace object';

	return { options => $obj };
} ## end sub BUILDARGS

sub BUILD {
	my $self = shift;

	# Necessary for the option to carry through.
	$self->get_testing();

	return;
}

1;

__END__

=head1 NAME

WiX3::Traceable - "Cheat Class" in order to initialize a Traceable object.

=head1 VERSION

This document describes WiX3::Traceable version 0.009100

=head1 SYNOPSIS

	WiX3::Traceable->new(
		tracelevel => 2,
		testing => 0,
	);
  
=head1 DESCRIPTION

TODO

=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

TODO

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

