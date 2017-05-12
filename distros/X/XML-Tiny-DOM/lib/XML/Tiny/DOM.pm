package XML::Tiny::DOM;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '1.1';

use XML::Tiny;
use XML::Tiny::DOM::Element;

=head1 NAME

XML::Tiny::DOM - wrapper for XML::Tiny to provide a DOMmish interface

=head1 DESCRIPTION

This is a small simple wrapper for XML::Tiny that makes it much easier
to access information in the data structures returned by XML::Tiny.

=head1 SYNOPSIS

    use XML::Tiny::DOM;
    my $document = XML::Tiny::DOM->new(...);

=head1 METHODS

=head2 new

This is the constructor.  It takes exactly the same parameters as
C<XML::Tiny>'s C<parsefile> function, but instead of returning a naked
and rather complex data structure, it returns a XML::Tiny::DOM::Element
object representing the root element of the document.

There are no other methods.

=cut

sub new {
    shift;
    return XML::Tiny::DOM::Element->_new(XML::Tiny::parsefile(@_)->[0]);
}

=head1 LIMITATIONS

This module is subject to all the limitations of XML::Tiny.  However,
no effort has been made to make this module work with perl versions
prior to 5.6.2.

=head1 BUGS and FEEDBACK

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<http://rt.cpan.org/> or by email,
and should include the smallest possible chunk of code, along with
any necessary XML data, which demonstrates the bug.  Ideally, this
will be in the form of a file which I can drop in to the module's
test suite.

=head1 SEE ALSO

L<XML::Tiny>

L<XML::Tiny::DOM::Element>

=head1 AUTHOR, COPYRIGHT and LICENCE

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

Copyright 2009 David Cantrell E<lt>david@cantrell.org.ukE<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

'<one>zero</one>';
