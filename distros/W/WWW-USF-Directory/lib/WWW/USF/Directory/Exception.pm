package WWW::USF::Directory::Exception;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.003001';

###########################################################################
# MOOSE
use Moose 0.89;
use MooseX::StrictConstructor 0.08;

###########################################################################
# MOOSE TYPES
use MooseX::Types::Moose qw(
	Str
);

###########################################################################
# MODULE IMPORTS
use Carp qw(croak);
use Class::Load qw(load_class);

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# OVERLOADED FUNCTIONS
__PACKAGE__->meta->add_package_symbol(q{&()}  => sub {                  });
__PACKAGE__->meta->add_package_symbol(q{&(""} => sub { shift->stringify });

###########################################################################
# ATTRIBUTES
has message => (
	is  => 'ro',
	isa => Str,

	documentation => q{The error message},
	required      => 1,
);

###########################################################################
# METHODS
sub stringify {
	my ($self) = @_;

	# The default stringify method just returns the contents of the message
	# attribute.
	return $self->message;
}
sub throw {
	my ($class, %args) = @_;

	if (blessed $class) {
		# Since $class is blessed, this was probably called as a method, so
		# make $class the class name.
		$class = blessed $class;
	}

	# Get the class to make the exception in
	my $exception_class = delete $args{class};

	if (!defined $exception_class) {
		# The class was not specified, so just make it in our class
		croak $class->new(%args);
	}

	# Prefix this class to the beginning of the exception class
	$exception_class = sprintf '%s::%s', $class, $exception_class;

	# Load the exception class
	load_class($exception_class);

	croak $exception_class->new(%args);
}

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WWW::USF::Directory::Exception - Basic exception object for WWW::USF::Directory

=head1 VERSION

This documentation refers to version 0.003001

=head1 SYNOPSIS

  use WWW::USF::Directory::Exception;

  # Throw a generic error message
  WWW::USF::Directory::Exception->throw(
    message => 'This is some error message',
  );

=head1 DESCRIPTION

This is a basic exception class for the
L<WWW::USF::Directory|WWW::USF::Directory> library.

=head1 ATTRIBUTES

=head2 message

B<Required>. This is a string that contains the error message for the exception.

=head1 METHODS

=head2 stringify

This method is used to return a string that will be given when this object is
used in a string context. Classes inheriting from this class are welcome to
override this method. By default (as in, in this class) this method simply
returns the contents of the message attribute.

  my $error = WWW::USF::Directory::Exception->new(message => 'Error message');

  print $error; # Prints "Error message"

=head2 throw

This method will take a HASH as the argument and will pass this HASH to the
constructor of the class, and then throw the newly constructed object. An extra
option that will be stripped is C<class>. This option will actually construct a
different class, where this class is in the package space below the specified
class.

  eval {
    WWW::USF::Directory->throw(
      class   => 'ClassName',
      message => 'An error occurred',
    );
  };

  print ref $@; # Prints WWW::USF::Directory::Exception::ClassName

=head1 DEPENDENCIES

=over

=item * L<Carp|Carp>

=item * L<Class::Load|Class::Load>

=item * L<Moose|Moose> 0.89

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<namespace::clean|namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-www-usf-directory at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW::USF::Directory>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I highly encourage the submission of bugs and enhancements to my modules.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Douglas Christopher Wilson.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
