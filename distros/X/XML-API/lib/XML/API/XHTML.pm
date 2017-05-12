package XML::API::XHTML;
use strict;
use warnings;
use base qw(XML::API);

our $VERSION = '0.30';

use constant DOCTYPE =>
qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">};

use constant XSD          => {};
use constant ROOT_ELEMENT => 'html';
use constant ROOT_ATTRS   => { xmlns => 'http://www.w3.org/1999/xhtml' };

my $xsd = {};

sub _doctype {
    return
q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">};
}

sub _xsd {
    return $xsd;
}

sub _root_element {
    return 'html';
}

sub _root_attrs {
    return { xmlns => 'http://www.w3.org/1999/xhtml' };
}

sub _content_type {
    return 'application/xhtml+xml';
}

1;

__END__


=head1 NAME

XML::API::XHTML - XHTML generation through an object API

=head1 VERSION

0.30 (2016-04-11)

=head1 SYNOPSIS

As a simple example the following perl code:

  use XML::API::XHTML;
  my $x = new XML::API::XHTML();
  
  $x->head_open();
  $x->title('Test Page');
  $x->head_close();

  $x->body_open();
  $x->div_open({id => 'content'});
  $x->p('A test paragraph');
  $x->div_close();
  $x->body_close();

  $x->_print;

will produce the following nicely rendered output:

  <?xml version="1.0" encoding="ISO-8859-1"?>
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html>
    <head>
      <title>Test Page</title>
    </head>
    <body>
      <div id="content">
        <p>A test paragraph</p>
      </div>
    </body>
  </html>

There are more complicated and flexible ways to use this module. Read
on.

=head1 DESCRIPTION

B<XML::API::XHTML> is a perl object class for creating XHTML documents.
The methods of a B<XML::API::XHTML> object are derived directly from
the XHTML specification. A document author uses the methods to define
the structure and content of their document, which can then be printed
and sent somewhere or saved as desired.

The first step is to create an object:

  use XML::API::XHTML;
  my $x = new XML::API::XHTML();

$x is the only object we need for our entire XHTML document. By default
$x consists initially of only the root element ('html') which should be
thought of as the 'current' or 'containing' element. The next step
might be to add a 'head' element. We do this by calling the head_open()
method:

  $x->head_open();

Because we have called a *_open() function all further elements will be
added inside the 'head' element. So lets add the title element and the
title itself ('Document Title') to our object:

  $x->title('Document Title');

The 'title()' method on its own (ie not 'title_open()') indicates that
we are finished with the title element. Further methods will continue
to place elements inside the 'head' element until we specifiy we want
to move on by calling the _close method:

  $x->head_close();

We are now back inside the 'html' element.

So, basic elements seem relatively easy. How do we create elements with
attributes? When either the element() or element_open() methods are
called with a hashref argument the keys and values of the hashref
become the attributes:

  $x->body_open({id => 'bodyid'}, 'Content', 'more content');

By the way, both the element() and element_open() methods take
arbitrary numbers of content arguments as shown above. However if you
don't want to specify the content of the element at the time you open
it up you can use the _add() utility method later on:

  $x->div_open();
  $x->_add('Content added afterwards');

The final thing is to close out the elements and render our docment. It
is not strictly necessary to close out all elements, but consider it
good practice.

  $x->div_close();
  $x->body_close();
  print $x->_as_string();

=head1 SCHEMA CONFORMANCE

If you attempt to call a method that would create a document that
doesn't conform to the schema an error will be printed to STDERR and
the method will fail.

=head1 METHODS

B<XML::API::XHTML> inherits directly from B<XML::API> and actually
provides no methods of its own. All utility methods (new(), _print(),
_add etc) and advanced functionality such as adding content in a
non-linear fashion are base properties of B<XML::API> and users are
directed there for details. The important B<XML::API> methods are only
summarised here for convenience.

=head2 B<new()>

All elements of the XHTML specification (with the exception of 'html')
are available as the following function forms:

  $x->element_open({attribute => $value}, $content)

  $x->element({attribute => $value}, $content)

  $x->element_close({attribute => $value}, $content)


This module has no control functions of its own. See the documentation
for L<XML::API> for useful functions (such as _print).


=head2 EXPORT

None.

=head2 REQUIRES

Perl5.6.0, Carp, XML::API

=head1 SEE ALSO

XML::API and XML::API::XHTML were both written for the Rekudos
framework which is housed at http://rekudos.net/.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004,2015,2016 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut

