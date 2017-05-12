package WWW::USF::Directory::Exception::UnknownResponse;

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
# BASE CLASS
extends q{WWW::USF::Directory::Exception};

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# ATTRIBUTES
has ajax_response => (
	is  => 'ro',
	isa => Str,

	documentation => q{The scalar returned by the JavaScript AJAX request},
	required      => 1,
);

###########################################################################
# MAKE MOOSE OBJECT IMMUTABLE
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WWW::USF::Directory::Exception::UnknownResponse - Exception object for unknown
response.

=head1 VERSION

This documentation refers to version 0.003001

=head1 SYNOPSIS

  use WWW::USF::Directory::Exception::UnknownResponse;

  WWW::USF::Directory::Exception::UnknownResponse->throw(
    message       => 'This response has no handler',
    ajax_response => $object,
  );

=head1 DESCRIPTION

This is an exception class for exceptions where the directory will not return
any results because the search was not specific enough in the
L<WWW::USF::Directory|WWW::USF::Directory> library.

=head1 INHERITANCE

This class inherits from the base class of
L<WWW::USF::Directory::Exception|WWW::USF::Directory::Exception> and all
attributes and methods in that class are also in this class.

=head1 ATTRIBUTES

=head2 ajax_response

B<Required>. This is the scalar that was returned by the AJAX request to the
directory site.

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
