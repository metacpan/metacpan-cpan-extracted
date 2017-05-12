package WWW::Postini::Exception;

use strict;
use warnings;

use Exception::Class;

use vars qw( @ISA $VERSION );

@ISA = qw( Exception::Class::Base );
$VERSION = '0.01';

#################
## initializer ##
#################

sub _initialize {

	my $self = shift;
	my %params;
	
	if (@_ == 1) {
	
		# passing an exception object as a cause
		
		if (UNIVERSAL::isa($_[0], 'WWW::Postini::Exception')) {
			
			$params{'cause'} = shift;
			
		# passing error text
		
		} else {
		
			$params{'error'} = shift;
		
		}
	
	} else {
	
		%params = @_;
	
	}
	
	# cause object is defined
	
	if (defined $params{'cause'}) {
	
		# set cause and remove parameter unsupported by base class		
		my $cause = $self->cause(delete $params{'cause'});

		# call superclass initializer
		$self->SUPER::_initialize(@_);

		# prohibit superclass from using $! as the default message
		$self->{'message'} = ref $cause unless defined $params{'message'};
		
		my $trace = $self->trace();
		my $cause_trace = $cause->trace();
		my $frame_count = $trace->frame_count();

		# strip any frames already present in cause stack trace
		
		for my $idx (0..$frame_count - 1) {

			my $frame = $trace->frame($idx);

			if (grep $_->filename() eq $frame->filename()
				&& $_->line() == $frame->line(),
				@{$cause_trace->{'frames'}}
			) {
			
				splice @{$trace->{'frames'}}, $idx;
				last;
			
			}	
		
		}
		
	} else {
	
		$self->SUPER::_initialize(%params);
		
	}

}

######################
## accessor methods ##
######################

# cause

sub cause {

	my $self = shift;
	
	if (@_) {
	
		$self->{'cause'} = shift
		
	}
	
	$self->{'cause'};

}

1;

__END__

=head1 NAME

WWW::Postini::Exception - Enhanced exception class

=head1 SYNOPSIS

  use WWW::Postini::Exception;
  throw WWW::Postini::Exception('The sky is falling!');

=head1 DESCRIPTION

Based on L<Exception::Class|Exception::Class>, this module adds support for
recursive exception throwing.  This permits exceptions to be caused by other
exceptions, in a way very similar to Java's exceptions.

=head1 OBJECT METHODS

=over 4

=item throw($arg)

=item throw(%args)

Creates a new WWW::Postini::Exception object and C<die()>s with it.  If
C<$arg> is an instance of L<Exception::Class::Base|Exception::Class>,
either directly or by way of subclassing, C<$arg> will be set as the
C<cause> of the existing exception object.

Alternatively, if C<%args> is passed with a C<cause> attribute, that value
will be set to the C<cause> of the exception object.

For all other parameter-passing conventions of the C<throw()> method, please
refer to L<Exception::Class>.

=item cause()

=item cause($object)

Get or set the cause of the exception.

Returns the exception object that caused the current exception.  If C<$object>
is set, the original exception's C<cause> is updated to reflect the new
value.

=back

=head1 SEE ALSO

L<WWW::Postini>, L<Exception::Class>

=head1 AUTHOR

Peter Guzis, E<lt>pguzis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Peter Guzis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

Postini, the Postini logo, Postini Perimeter Manager and preEMPT are
trademarks, registered trademarks or service marks of Postini, Inc. All
other trademarks are the property of their respective owners.

=cut