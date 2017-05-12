=head1 NAME

XML::XMLWriter - Module for creating a XML document object oriented
with on the fly validating towards the given DTD.

=cut

######################################################################

package XML::XMLWriter;
require 5.8.0;

# Copyright (c) 2003, Moritz Sinn. This module is free software;
# you can redistribute it and/or modify it under the terms of the
# GNU GENERAL PUBLIC LICENSE, see COPYING for more information.

use strict;
use vars qw($VERSION);
$VERSION = '0.1';

######################################################################

=head1 DEPENDENCIES

=head2 Perl Version

	5.004

=head2 Standard Modules

        Carp 1.01
        Encode 1.98

=head2 Nonstandard Modules

        XML::ParseDTD 0.1.3

=cut

######################################################################

use Carp;
use Encode;
use XML::ParseDTD;
use XML::XMLWriter::Element;

######################################################################

=head1 SYNOPSIS

=head2 Example Code

        #!/usr/bin/perl

        use XML::XMLWriter;

	my @data=(['Name', 'Adress', 'Email', 'Sex'],
		  ['Herbert', 'BeerAvenue 45', 'herbert@names.org', 'Male'],
		  ['Anelise', 'SchmidtStreet 21', 'foo@bar.com', 'Female'],
		  ['XYZ', 'ZYX', 'ZY', 'XZ'],
		  ['etc...']);

	my $doc = new XML::XMLWriter(system => 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd',
			             public => '-//W3C//DTD XHTML 1.0 Transitional//EN');

	my $html = $doc->createRoot;
	$html->head->title->_pcdata('A Table');
	my $body = $html->body;
	$body->h1->_pcdata('Here is a table!');
	my $table = $body->table({align => 'center', cellspacing => 1, cellpadding => 2, border => 1});
	for(my $i=0; $i<@data; $i++) {
	  my $tr = $table->tr;
	  foreach $_ (@{$data[$i]}) {
	    $i==0 ? $tr->th->_pcdata($_) : $tr->td->_pcdata($_);
	  }
	}
	$body->b->_pcdata("that's it!");
	$doc->print();

=head2 Example Output

	<?xml version="1.0" encoding="ISO-8859-15" standalone="no"?>
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" SYSTEM "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	<html><head><title>A Table</title></head><body><h1>Here is a table!</h1><table align="center" cellspacing="1" cellpadding="2" border="1"><tr><th>Name</th><th>Adress</th><th>Email</th><th>Sex</th></tr><tr><td>Herbert</td><td>BeerAvenue 45</td><td>herbert@names.org</td><td>Male</td></tr><tr><td>Anelise</td><td>SchmidtStree 21</td><td>foo@bar.com</td><td>Female</td></tr><tr><td>XYZ</td><td>ZYX</td><td>ZY</td><td>XZ</td></tr><tr><td>etc...</td></tr></table><b>that's it!</b></body></html>

=head1 DESCRIPTION

XMLWriter is a Perl 5 object class, its purpose is to make writing XML
documents easier, cleaner, safer and standard conform. Its easier
because of the object oriented way XML documents are written with
XMLWriter. Its cleaner because of the simple but logical API and its
safe and standard conform because of the automatically done checking
against the the DTD.

But still: it might be a matter of taste whether one finds XMLWriter
usefull or not and it probably has some bugs (i would appreciate a lot
if you report them to me), many usefull features are missing, not
implemented or not even thought of and perhaps the API with all its
simpleness might be confusing though. So please tell me your opinion
and tell me the way how you would make XMLWriter better. Its not so
easy to develop a good API for this matter.

XMLWriter contains 3 packages: XMLWriter.pm which gives you the
document object, Element.pm which provides the element/tag objects and
PCData.pm which represents the parsed character data the document
contains. There'll probably come more objects in feature releases.
The most interesting class is Element.pm. It provides some methods you
can call on every document element, but besides those methods it uses
the I<AUTOLOAD> feature of perl to expect every not known method name
to be the name of a tag that should be added to the list of child tags
of the element the method is called on. So calling C<$html-E<gt>head>
will simply add a new element (the head element) to the list of child
tags of the html element. The head object is returned.  Have a look at
the examples for better understanding. You should also read the POD of
Element.pm and PCdata.pm.

=head1 USING XML::XMLWriter

=head2 Encoding

All methods expect the data you pass them to be encoded in UTF8. So if
you take data with diffrent encoding call
I<Encode::decode(yourencoding,$data)> to make it UTF8. Finally the
whole document will be encoded in the document encoding (default:
UTF8) before being returned.

=head2 The Constructor

=head3 new ([ %conf ])

The only argument can be a hash setting some configuration options:

=over

=item

version - XML version, defaults to I<1.0>, shouldn't be changed.

=item

encoding - Character encoding. Defaults to I<UTF8>.

=item

public - PUBLIC IDENTIFIER. Defaults to I<-//W3C//DTD XHTML 1.0
Strict//EN>.

=item

system - SYSTEM IDENTIFIER (must always be a path/url pointing
to a valid dtd). Defaults to
I<http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd>.

=item

standalone - sets the I<standalone> option of the XML
declaration. Defaults to I<no>, the only other possible value is
I<yes>.

=item

root - sets the name of the root element. Defaults to I<html>.

=item

rootArgs - sets the list of arguments and their values for the
root element. Defaults to I<{}> (empty hash reference).

=item

intend - sets whether intentation should be done and if so how
many spaces per level. Defaults to 0, is not implemented yet, that
means setting it won't have any effect.

=item

checklm - the value of this option is passed to XML::ParseDTD
for setting its I<checklm> parameter. Please the the documentation of
XML::ParseDTD for more information. Defaults to I<-1>.

=back

=cut

######################################################################

sub new {
  my ($class, %conf) = @_;
  my $self = bless({}, ref($class) || $class);
  $self->{Conf} = {
		   version => '1.0',
		   encoding => 'UTF8',
		   #encoding => 'ISO-8859-15',
		   public => '-//W3C//DTD XHTML 1.0 Strict//EN',
		   system => 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd',
		   standalone => 'no',
		   root => 'html',
		   rootArgs => {},
		   #intend => 2,
		   intend => 0,
		   checklm => -1,
		  };
  local $_;
  foreach $_ (keys(%conf)) {
    $self->{Conf}->{$_} = $conf{$_};
  }
  return $self;
}

######################################################################

=head2 Methods

=head3 createRoot ([$rootelem, %arguments, $character_data])

Creates the root element and returns a I<XML::XMLWriter::Element>
object representing it.

Possible parameters:

=over

=item

1. The root elements name. Defaults to the value of the I<root>
configuration option (see the C<new> method).

=item

2. A hash of arguments for the root element and their
values. Defaults to the value of the I<rootArgs> configuration option
(see the C<new> method).

=item

3. A string of character data which will be appended right after
the start tag. Defaults to undef, which means no data will be added.

=back

Instead of passing the third argument you can also just do a
C<$root-E<gt>_pcdata(yourdata)>, its exactly the same.

=cut

######################################################################

sub createRoot {
  my ($self,$root,%args,$text) = @_;
  $self->{dtd} = XML::ParseDTD->new($self->{Conf}->{system},checklm => $self->{Conf}->{checklm}) if($self->{Conf}->{system});
  $self->{root} = XML::XMLWriter::Element->new(($root||$self->{Conf}->{root}),$self->{dtd},(\%args||$self->{Conf}->{rootArgs}),$text);
  return $self->{root};
}

######################################################################

=head3 get ()

Returns the XML document as a string.  Every elements child list is
checked and a warning is produce if its not allowed by the DTD.

=cut

######################################################################

sub get {
  my ($self) = @_;
  local $_ = '<?xml version="' . $self->{Conf}->{version} . '" encoding="' . $self->{Conf}->{encoding} . '" standalone="' . $self->{Conf}->{standalone} . '"?>' . "\n";
  $_ .= '<!DOCTYPE ' . $self->{Conf}->{root} . ($self->{Conf}->{public} ? ' PUBLIC "' . $self->{Conf}->{public} . '"' : '') . ($self->{Conf}->{system} ? ' SYSTEM "' . $self->{Conf}->{system} . '"' : '') . ">\n";
  return encode($self->{Conf}->{encoding},$_ . $self->{root}->_get());
}

######################################################################

=head3 print ()

Prints the XML document to STDOUT.

=cut

######################################################################

sub print {
  my ($self,$html) = @_;
  print $self->get($html);
}

######################################################################

=head3 get_dtd ()

Returns the internally used C<XML::ParseDTD> object.

=cut

######################################################################

sub get_dtd {
  my($self) = @_;
  return $self->{dtd};
}

return 1;

__END__

#sub get_doc {
#  my($self) = @_;
#  return $self->{doc};
#}

#sub validate {
#  my($self) = @_;
#  return $self->{doc}->validate();
#}

#sub is_valid {
#  my($self) = @_;
#  return $self->{doc}->is_valid();
#}
