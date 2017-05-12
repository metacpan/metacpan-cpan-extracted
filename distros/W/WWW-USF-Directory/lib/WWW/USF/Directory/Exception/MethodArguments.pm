package WWW::USF::Directory::Exception::MethodArguments;

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
# BASE CLASS
extends q{WWW::USF::Directory::Exception};

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# ATTRIBUTES
has argument => (
	is  => 'ro',
	isa => 'Str',

	documentation => q{The argument that was invalid},
	required      => 1,
);
has argument_value => (
	is => 'ro',

	clearer       => '_clear_argument_value',
	documentation => q{The invalid value of the argument},
	predicate     => 'has_argument_value',
);
has method => (
	is  => 'ro',
	isa => 'Str',

	documentation => q{The method in which the error occurred},
	required      => 1,
);

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WWW::USF::Directory::Exception::MethodArguments - Exception object for
exceptions that occur when bad arguments are provided to a method.

=head1 VERSION

This documentation refers to version 0.003001

=head1 SYNOPSIS

  use WWW::USF::Directory::Exception::MethodArguments;

  WWW::USF::Directory::Exception::MethodArguments->throw(
      message  => 'This is some error message',
      argument => 'some_argument',
      method   => 'cool_method',
  );

=head1 DESCRIPTION

This is an exception class for when a bad argument is provided to a method in
the L<WWW::USF::Directory|WWW::USF::Directory> library.

=head1 INHERITANCE

This class inherits from the base class of
L<WWW::USF::Directory::Exception|WWW::USF::Directory::Exception> and all
attributes and methods in that class are also in this class.

=head1 ATTRIBUTES

=head2 argument

B<Required>. This is a string that contains the name of the argument that
contained a bad value.

=head2 argument_value

This is the bad value the argument had. This can be any type. Use
L</has_argument_value> to determine if the argument value is present.

=head2 has_argument_value

Whether or not the L</argument_value> has been specified.

=head2 method

B<required>

This is a string that contains the name of the method that was called and the
the error occurred in.

=head1 METHODS

This class does not contain any methods.

=head1 DEPENDENCIES

=over

=item * L<Moose|Moose> 0.89

=item * L<MooseX::StrictConstructor|MooseX::StrictConstructor> 0.08

=item * L<WWW::USF::Directory::Exception|WWW::USF::Directory::Exception>

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
