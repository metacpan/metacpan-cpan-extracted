#
# XPC.pm - XML Procedure Call Classes
#
# Designed to work in conjunction with the XML::Parser Style => 'Object'.
#
# Copyright (C) 2001 Gregor N. Purdy.
# All rights reserved.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#


package XPC;

#use XML::Writer;
use XML::Parser;

use vars qw($VERSION);

$VERSION = 0.2;


#
# new()
#

sub new
{
  my $class = shift;
  my $self;

  if (@_) {
    my $xml = shift;

    my $parser = new XML::Parser(Style => 'Objects');
    eval {
      $self = $parser->parse($xml);
    };

    if ($@) {
      print STDERR "XPC: XML =\n";
      print STDERR $xml;
      print STDERR "\n";
      die "XPC: Unable to parse XML into XPC instance!\n";
    }
  } else {
    $self = new XPC::xpc;
  }

  return $self;
}


#
# new_call()
#

sub new_call
{
  my $class = shift;
  my $self  = $class->new();
  $self->add_call(@_);
  return $self;
}


##############################################################################
#
# CHARACTER DATA:
#
##############################################################################


#
# XPC::Characters
#

package XPC::Characters;

sub data
{
  my $self = shift;

  return $self->{Text};
}

sub new
{
  my ($class, $data) = @_;

  return bless { Text => $data }, $class;
}


##############################################################################
#
# ROOT: <xpc>
#
##############################################################################

package XPC::xpc;


#
# version()
#

sub version
{
  my $self = shift;
  return $self->{version} if defined $self->{version};
}


#
# new()
#

sub new
{
  my ($class, $version) = @_;
  my $self = bless { Kids => [ ] }, $class;
  $self->{version} = $version if defined $version;
  return $self;
}


#
# add_call()
#

sub add_call
{
  my ($self) = shift;

  $self->add_request(XPC::call->new(@_));
}


#
# add_response()
#

sub add_response
{
  my ($self, $response) = @_;

  die "XPC::xpc::add_response(): Cannod add undef response!\n" unless defined $response;

  push @{$self->{Kids}}, $response;
}


#
# add_request()
#

sub add_request
{
  my ($self, $request) = @_;

  push @{$self->{Kids}}, $request;
}


#
# as_string()
#

sub as_string
{
  my $self = shift;

#  print STDERR "XPC::xpc:as_string(): Generating string...\n";

  my $version = $self->version;
  my @kids    = @{$self->{Kids}};

  my $body;

  foreach my $kid (@kids) {
    next unless defined $kid; # TODO: How does this happen?
    $body .= $kid->as_string;
  }

  if (defined $version and $version ne '') {
    if (defined $body) {
      return "<xpc version='$version'>\n$body</xpc>\n";
    } else {
      return "<xpc version='$version'/>\n"; # TODO: Degenerate case
    }
  } else {
    if (defined $body) {
      return "<xpc>\n$body</xpc>\n";
    } else {
      return "<xpc/>\n"; # TODO: Degenerate case
    }
  }
}


#
# results()
#

sub results
{
  my ($self, $index) = @_;

  my @kids    = @{$self->{Kids}};
  my @results = grep { ref $_ eq 'XPC::result'; } @kids;
  return @results;
}


#
# result()
#

sub result
{
  my ($self, $index) = @_;
  return ($self->results)[$index];
}


#
# faults()
#

sub faults
{
  my ($self, $index) = @_;

  my @kids    = @{$self->{Kids}};
  my @faults = grep { ref $_ eq 'XPC::fault'; } @kids;
  return @faults;
}


#
# fault()
#

sub fault
{
  my ($self, $index) = @_;
  return ($self->faults)[$index];
}


##############################################################################
#
# QUERIES: <query>
#
##############################################################################

package XPC::query;


#
# procedure()
#
# OPTIONAL
#

sub procedure
{
  my $self = shift;
  return $self->{procedure} if defined $self->{procedure};
}


#
# id()
#

sub id
{
  my $self = shift;
  return $self->{id} if defined $self->{id};
}


#
# new()
#

sub new
{
  my ($class, $procedure, $id) = @_;
  my $self = bless { Kids => [ ] }, $class;
  $self->{id} = $id if defined $id;
  $self->{procedure} = $procedure if defined $procedure;
  return $self;
}


##############################################################################
#
# CALLS: <call>
#
##############################################################################

package XPC::call;


#
# procedure()
#
# MANDATORY
#

sub procedure
{
  shift->{procedure};
}


#
# id()
#
# OPTIONAL
#

sub id
{
  my $self = shift;
  return $self->{id} if defined $self->{id};
}


#
# new()
#

sub new
{
  my ($class, $procedure, $id) = @_;
  my $self = bless { procedure => $procedure, Kids => [ ] }, $class;
  $self->{id} = $id if defined $id;
  return $self;
}


#
# add_param()
#
# TODO
#


#
# as_string()
#

sub as_string
{
  my $self = shift;

  my $procedure = $self->procedure;

  my $body;

  foreach my $kid (@kids) {
    $body .= $kid->as_string;
  }

  if (defined $body) {
    return "  <call procedure='$procedure'>\n$body  </call>\n";
  } else {
    return "  <call procedure='$procedure'/>\n";
  }
}


##############################################################################
#
# CALL PARAMETERS: <param>
#
##############################################################################

package XPC::param;


#
# name()
#
# OPTIONAL
#

sub name
{
  shift->{name};
}


#
# new()
#

sub new
{
  my ($class, $name) = @_;
  my $self = bless { Kids => [ ] }, $class;
  $self->{name} = $name if defined $name;
  return $self;
}


##############################################################################
#
# PROTOTYPES: <prototype>
#
##############################################################################

package XPC::prototype;


#
# id()
#
# OPTIONAL
#

sub id
{
  shift->{id};
}


#
# procedure()
#
# REQUIRED
#

sub procedure
{
  shift->{procedure};
}


#
# comment()
#
# TODO:
#


##############################################################################
#
# PROTOTYPE PARAMETER DEFINITIONS: <param-def>
#
##############################################################################

package XPC::param_def;


#
# name()
#
# OPTIONAL
#

sub name
{
  shift->{name};
}


#
# type()
#
# REQUIRED
#

sub type
{
  shift->{type};
}


#
# subtype()
#

sub subtype
{
  shift->{subtype};
}


##############################################################################
#
# PROTOTYPE RESULT DEFINITIONS: <result-def>
#
# TODO
#
##############################################################################

package XPC::result_def;



##############################################################################
#
# RESULTS: <result>
#
##############################################################################

package XPC::result;


#
# id()
#
# OPTIONAL
#

sub id
{
  shift->{id};
}


#
# name()
#
# OPTIONAL
#
# TODO: Get rid of this?
#

sub name
{
  shift->{name};
}


#
# new_scalar()
#

sub new_scalar
{
  my $class = shift;

  my $self = bless { Kids => [ ] }, $class;

  die sprintf("XPC::result::new_scalar(): Cannot create scalar result with %d arguments!\n", scalar @_) if (@_ != 1);

  push @{$self->{Kids}}, XPC::scalar->new(@_);

  return $self;
}


#
# as_string()
#

sub as_string
{
  my $self = shift;

  my $value;
  foreach my $kid (@{$self->{Kids}}) {
    next if ref $kid eq 'XPC::Characters';

    $value .= $kid->as_string;
  } 

  if (defined $value) {
    return "  <result>\n    $value\n  </result>\n";
  } else {
    die "XPC::result::as_string(): Mystery! No Kids!\n";
  }
}


#
# value()
#
# TODO: Return structs and arrays, too.
#

sub value 
{
  my $self = shift;

  my @kids = grep { ref $_ eq 'XPC::scalar' } @{$self->{Kids}};
  return '' unless @kids;
  return $kids[0]->value;
}



##############################################################################
#
# FAULTS: <fault>
#
##############################################################################

package XPC::fault;


#
# id()
#
# OPTIONAL
#

sub id
{
  shift->{id};
}


#
# code()
#
# MANDATORY
#

sub code
{
  shift->{code};
}


#
# message()
#

sub message
{
  my $self = shift;
  my $data = $self->{Kids}->[0]->data;

  $data =~ s/^\s*//;
  $data =~ s/\s*$//;

  return $data;
}


#
# new()
#

sub new
{
  my ($class, $code, $message, $id) = @_;

  $message =~ s/^\s*//;
  $message =~ s/\s*$//;

  my $self =  bless { code => $code,
    Kids => [ XPC::Characters->new($message) ]
  }, $class;

  $self->{id} = $id if defined $id;

  die "Hah!" unless $message eq $self->message;

  return $self;
}


#
# as_string()
#

sub as_string
{
  my $self    = shift;
  my $id      = $self->id;
  my $code    = $self->code;
  my $message = $self->message;

  if (defined $id) {
    return "  <fault code='$code' id='$id'>\n    $message\n    </fault>\n";
  } else {
    return "  <fault code='$code'>\n    $message\n  </fault>\n";
  }
}


##############################################################################
#
# SCALAR VALUES: <scalar>
#
##############################################################################

package XPC::scalar;


#
# type()
#

sub type
{
  shift->{type};
}


#
# new()
#

sub new
{
  my ($class, $value, $type) = @_;

  my $self = bless { Kids => [ ] }, $class;

  push @{$self->{Kids}}, XPC::Characters->new($value);

  $self->{type} = $type if defined $type;

  return $self;
}


#
# as_string()
#

sub as_string
{
  my $self = shift;
  my $type = $self->type;

  my $attrs = '';

  $attrs .= " type='$type'" if defined $type;

  return "<scalar$attrs>" . $self->{Kids}[0]->data . "</scalar>";
}


#
# value()
#

sub value
{
  my $self = shift;
  return $self->{Kids}[0]->data;
}


##############################################################################
#
# ARRAY VALUES: <array>
#
# TODO
#
##############################################################################

package XPC::array;


##############################################################################
#
# STRUCTURE VALUES: <struct>
#
# TODO
#
##############################################################################

package XPC::struct;


##############################################################################
#
# STRUCTURE MEMBER VALUES: <member>
#
# TODO
#
##############################################################################

package XPC::member;


#
# name()
#

sub name
{
  shift->{name};
}



##############################################################################
#
# XML VALUES: <xml>
#
# TODO: This presents a problem for this style of parsing, since we could have
# any elements whatsoever here.
#
##############################################################################

package XPC::xml;


##############################################################################
#
# COMMENTS: <comment>
#
# TODO
#
##############################################################################

package XPC::comment;



##############################################################################
##############################################################################

1;


=head1 NAME

XPC - XML Procedure Call


=head1 SYNOPSIS

  use XPC;

and then

  my $xpc = XPC->new(<<END_XPC);
  <?xml version='1.0' encoding='UTF-8'?>
  <xpc>
    <call procedure='localtime'/>
  </xpc>
  END_XPC

or

  my $xpc = XPC->new();
  $xpc->add_call('localtime');

or

  my $xpc = XPC->new_call('localtime');

and then later

  print XML_FILE $xpc->as_string();


=head1 DESCRIPTION

This class represents an XPC request or response. It uses XML::Parser to
parse XML passed to its constructor.


=head1 MOTIVATION

A Commentary on the XML-RPC Specification and Definition of XPC Version 0.2


=head2 Introduction

The following commentary is based upon the specification from the UserLand web
site. The version referenced for this commentary has a notation on it that it
was "Updated 10/16/99 DW" (see L<http://www.xmlrpc.com/spec>).

These comments are stylistic in nature, and it is well recognized by the
author that style in program and protocol design are very personal. This
commentary will, however, point out the rationale of the proposed changes to
the specification's design.


=head2 Procedure Call Structural Simplifications

The example in the "Request example" section looks like this:

  <methodCall>
    <methodName>examples.getStateName</methodName>
    <params>
      <param>
        <value><i4>41</i4></value>
      </param>
    </params>
  </methodCall>

We note by looking at the remainder of the specification that there are only
two top-level elements allowed in XML-RPC: C<methodCall> and C<methodResponse>.
Since methods are I<the> subject of RPC, and since all top-level elements
in the design are about methods, there is no need to have the redundant
qualifier "method" in the names of these elements. Thus, the example would
be modified to look like this:

  <call>
    <methodName>examples.getStateName</methodName>
    <params>
      <param>
        <value><i4>41</i4></value>
      </param>
    </params>
  </call>

Now, the content of the C<methodName> element is constrained to be very simple
text (from the "Payload format" section, which says "... identifier characters,
upper and lower-case A-Z, the numeric characters, 0-9, underscore, dot, colon
and slash"). It is also mandatory. This is precisely the reason XML includes
the ability to add attributes to elements (it is technically redundant, but
very convenient). So, we really should turn this example into:

  <call method='examples.getStateName'>
    <params>
      <param>
        <value><i4>41</i4></value>
      </param>
    </params>
  </call>

Once the C<methodName> element has been removed from the design, the C<params>
element becomes superfluous, since its only purpose was to group the
parameters and separate them from the method name. Now, the C<call> element
I<is> the element that groups the parameters, leaving us with:

  <call method='examples.getStateName'>
    <param>
      <value><i4>41</i4></value>
    </param>
  </call>


=head2 Header Nomenclature

One final comment on terminology: RPC stands for Remote I<Procedure> Call, so
we should probably not use the term "method" when we mean "procedure" or
something else. Since the "procedures" can return values, which corresponds
in some languages to the term "function", we have a rivalry for the term to
use. "Procedure" matches the acronym nicely, but for some folks "Function"
would have a better connotation. Fans of Eiffel might even prefer "Feature",
or "Query" for calls returning a value and "Routine" or "Command" for those
not. Given the variety of possibilities, here we stay with the simple
policy of matching the acronym:

  <call procedure='examples.getStateName'>
    <param>
      <value><i4>41</i4></value>
    </param>
  </call>


=head2 Scalar Values

Typically, an interface definition determines the number, names and types of
parameters to a procedure call. It is incumbent upon the caller to conform
to that specification. Therefore, the declaration for any procedure to be
called as part of an interface I<should> indicate the expected types of the
parameters, which means that the caller should not have to indicate the type
of value it is passing (and, the value I<itself> isn't passed in general, but
rather a I<textual representation> of the value is passed). XML-RPC should not
be blind to typing issues. These issues should not appear in the calling
standard, but rather in an interface definition standard (about which more
later). Removing the type information from the example results in:

  <call procedure='examples.getStateName'>
    <param>
      <value>41</value>
    </param>
  </call>

Since the <value> element really now just means "scalar" (see the specification
section "Scalar E<lt>valueE<gt>s"), let's call it that:

  <call procedure='examples.getStateName'>
    <param>
      <scalar>41</scalar>
    </param>
  </call>

If for some reason not contemplated here type information is necessary for
scalars, then having a simple C<type> attribute of the C<scalar> element
would suffice, especially since the set of allowable values is fixed,
small, and consists of only short string values (C<i4>, C<int>, C<boolean>,
C<string>, C<double>, C<dateTime.iso8601>, and C<base64>).

If we only ever expected simple, short scalar values, we could make one more
change, to:

  <!-- NOTE: This is NOT a proposed change -->
  <call procedure='examples.getStateName'>
    <param>
      <scalar value='41'/>
    </param>
  </call>

but, it is presumed that it would be possible to have a very long scalar
string value, for which the former representation would be better.


=head2 Named Parameters

Some procedures may be implemented in a language that makes it very easy to
implement named parameters. Supporting this would be easy:

  <call procedure='examples.getStateName'>
    <param name='stateNum'>
      <scalar>41</scalar>
    </param>
  </call>


=head2 Scalar Types

Whether types apply to calls and interfaces or just to interfaces, they are
an important part of the specification.

The specification defines C<i4> and C<int> to be synonyms for a 'four-byte
signed integer'. Since the value will be represented in the call as text,
this description really isn't an appropriate specification, since it is
written in terms of a binary representation. We suggest here a single term
for this data type, C<integer>, and that it be defined in terms of a range
of acceptable values: -2,147,483,648 to +2,147,483,647 (just the range of
vales that can be stored in a two's complement 32-bit binary representation).

The C<boolean> data type is distinct from the C<integer> data type, yet its
domain {C<0>, C<1>} is a subset of the C<integer> domain instead of the more
consistent {C<false>, C<true>}. If C<boolean> is going to be treated as its own
type, it should have its own domain.

The specification defines C<double> to be 'double-precision signed floating
point number'. Note that in the 1999-01-21 questions-and-answers section
near the end of the document, it is revealed that the full generality of
the data type commonly meant by such a description is not available. Niether
infinities, nor C<NaN> (the Not-a-Number value) are permitted. Not even
exponential notation is allowed. Very simple strings matching the Perl
regular expression:

  /^([+-])(\d*)(\.)(\d*)$/

are the only ones permitted according to the answer given, although one
suspects that what was meant was something closer to this:

  /^([+-])?(\d*)((\.)(\d*))?$/

because the first expression requires the sign to be present, and permits
"C<+.>" and "C<-.>" as valid strings (although to what values they would map is
a mystery).

Note: The second expression makes the leading sign and trailing decimal point
and digits optional, but still isn't perfect, since it allows the empty string
as a value.

This type should be called C<rational> instead of C<double> to get away
from the physical description. C<decimal> is another potentially reasonable
name for this type.

Also, the FAQ answer says the range of allowable values is implementation-
dependant, but the specification refers to "double-precision
floating-point", which does have an expected set of behaviors for most people.

The specification mentions "ASCII" in the type definition for string, but
XML permits all of Unicode. Shouldn't one expect to be able to pass around
string values with all the characters thus permitted? Shouldn't servers and
clients be written to handle this broader character set, and convert as
necessary internally? Otherwise, we are taking a big step back from the
promise of XML and the web.

The C<dateTime.iso8601> data type name is awkward. They didn't refer to the
IEEE 754 floating point standard in the name of the C<double> type (which
would have been C<double.ieee754> if they had). Unless the specification
is going to allow multiple C<dateTime> variants, the qualifier is just an
annoyance. In addition, most people call this type C<timestamp>, even if their
computer languages sometimes just call it C<DATE> (as in many SQL
implementations). So, here we propose that this type just be called C<timestamp>
and that the type description refer to the ISO 8601 standard.

Finally, the C<base64> type (added 1999-01-21) really should be C<binary> with
the encoding standard (Base-64) referenced in the type description.


=head2 Structures

Structures continue the same idiom used elsewhere in the specification: the
avoidance of element attributes. Here is the example used in the specification
(modified to acommodate the recommendations already made here):

  <struct>
    <member>
      <name>lowerBound</name>
      <scalar>18</scalar>
    </member>
    <member>
      <name>upperBound</name>
      <scalar>139</scalar>
    </member>
  </struct>

The C<name> element here should be converted into an attribute of the C<member>
element, leaving:

  <struct>
    <member name='lowerBound'>
      <scalar>18</scalar>
    </member>
    <member name='upperBound'>
      <scalar>139</scalar>
    </member>
  </struct>


=head2 Arrays

The C<array> element is defined with a superfluous C<data> child element. This
element serves no function, so it should be removed. Here is the example from
the specification (again, modified based on previous recommendations):

  <array>
    <data>
      <scalar>12</scalar>
      <scalar>Egypt</scalar>
      <scalar>false</scalar>
      <scalar>-31</scalar>
    </data>
  </array>

Removing the unneeded C<data> element leaves us with:

  <array>
    <scalar>12</scalar>
    <scalar>Egypt</scalar>
    <scalar>false</scalar>
    <scalar>-31</scalar>
  </array>

We have recommended getting rid of C<value> and using C<scalar>, but the
specification allows a C<value> to contain a scalar value I<or> a C<struct>
I<or> an C<array>. We can still do without the C<value> element, though:

  <array>
    <scalar>12</scalar>
    <array>
      <scalar>Egypt</scalar>
      <scalar>false</scalar>
      <scalar>-31</scalar>
    </array>
  </array>


=head2 Responses

The example in the document is:

  <?xml version="1.0"?>
  <methodResponse>
    <fault>
      <value>
        <struct>
          <member>
            <name>faultCode</name>
            <value><int>4</int></value>
          </member>
          <member>
            <name>faultString</name>
            <value><string>Too many parameters.</string></value>
          </member>
        </struct>
      </value>
    </fault>
  </methodResponse>

This has much unnecessary nesting. It is I<much> simpler to store the fault
code as an attribute of the C<fault> element and to have the fault description
be the body of the C<fault> element:

  <?xml version="1.0"?>
  <methodResponse>
    <fault code='4'>
      Too many parameters.
    </fault>
  </methodResponse>


=head2 Adding a Consistent Top-Level Element

It would be nice if one could always be sure that XML data involved in the
XML-RPC protocol had a particular root element.

Another benefit of doing this is that a given request I<could> include
multiple calls, which for certain types of interactions could be of great
performance benefit. If you need to make many related calls, the network
latency would be a real drag on performance, but batching up the calls into
one big bundle amortizes the transport time, increasing performance. A top-
level element of C<xpc> is used here to stand for "XML Procedure Call".

  <xpc>
    <call> ...  </call>
    <call> ...  </call>
    <call> ...  </call>
  </xpc>

As soon as we decide to put multiple calls in a transmission, it begs the
issue of tieing responses to calls. We could use order for this, but we
could also provide an attribute to C<call> and C<response> called C<id> that
is optionally provided by the caller, and if present, is copied into the
response element for that call.

HTTP POST REQUEST CONTENT:

  <xpc>
    <call ... id='1'> ...  </call>
    <call ... id='foo'> ...  </call>
    <call ... id='some_guid'> ...  </call>
  </xpc

HTTP RESPONSE CONTENT:

  <xpc>
    <response id='1'> ...  </call>
    <response id='foo'> ...  </call>
    <response id='some_guid'> ...  </call>
  </xpc

Another benefit of having a consistent top-level element is that we can use
it to specify the protocol version:

  <xpc version='0.2'>
    <call ...> ...  </call>
  </xpc

Finally, using a consistent top-level element permits the response to contain
a copy of the request if desired.

HTTP POST REQUEST CONTENT:

  <xpc>
    <call ... id='1'> ...  </call>
    <call ... id='foo'> ...  </call>
    <call ... id='some_guid'> ...  </call>
  </xpc

HTTP RESPONSE CONTENT:

  <xpc>
    <call ... id='1'> ...  </call>
    <call ... id='foo'> ...  </call>
    <call ... id='some_guid'> ...  </call>
    <response id='1'> ...  </call>
    <response id='foo'> ...  </call>
    <response id='some_guid'> ...  </call>
  </xpc


=head2 Extended Types

Given that XML-RPC is an XML application, it is disconcerting to see its
design be so blind to XML issues such as Unicode values (discussed above) and
tree-structured data. Suppose a procedure was to accept XML as a parameter or
to return XML as its result. How would this be accomplished with XML-RPC? The
answer seems to be "stuff it in a string scalar". But, to be a proper string,
all the markup would have to be escaped:

  <call procedure='foo'>
    <param>
      <scalar>
        &lt;bar&gt;Here's some text in an element.&lt;/bar&gt;
      </scalar>
    </param>
  </call>

However, if we add to the C<scalar>, C<array> and C<struct> types a new
type C<xml>, then we can do the natural thing:

  <call procedure='foo'>
    <param>
      <xml>
        <bar>Here's some text in an element.</bar>
      </xml>
    </param>
  </call>

We could even use XML Namespaces if needed to resolve element name collisions
if they arise (namespaces are commonly used for this reason in XSLT
transforms).

Technically speaking, allowing parameters and results to contain XML makes the
other XML-RPC types redundant, but providing shortcuts for these common cases
does make sense.


=head2 Interface Specifications

In order to provide true discoverability, there needs to be a way for a client
to ask the server what operations it supports, and to get back interface
information for the supported procedures.

Sending an empty C<query> element should cause the server to return an array
of procedure names:

HTTP POST REQUEST CONTENT:

  <xpc>
    <query/>
  </xpc>

HTTP RESPONSE CONTENT:

  <xpc>
    <result>
      <array>
        <scalar>foo</scalar>
        <scalar>bar</scalar>
      </array>
    </result>
  </xpc>

Sending a C<query> element with a procedure name filled in should return a
response containing a prototype:

HTTP POST REQUEST CONTENT:

  <xpc>
    <query procedure='foo'/>
  </xpc>

HTTP RESPONSE CONTENT:

  <xpc>
    <prototype procedure='foo'>
      <comment>
        The 'foo' procedure! Given an integer, returns an array with that
        many elements, with each element containing the integer number of
        its position within the array.
      </comment>
      <param-def name='splee' type='scalar' subtype='integer'/>
      <result-def type='array'/>
    </prototype>
  </xpc>

Requesting information on an unknown procedure results in a C<fault> return:

HTTP POST REQUEST CONTENT:

  <xpc>
    <query procedure='quux'/>
  </xpc>

HTTP RESPONSE CONTENT:

  <xpc>
    <fault code='42'>
      Unknown procedure name 'quux'!
    </fault>
  </xpc>


=head2 Conclusion

The "Strategies/Goals" section of the specification lists these items
(paraphrased):


=over 4

=item *

Leverage the ability of CGI to pass many firewalls to build an RPC
mechanism that can cross many platforms and many network boundaries.

=item *

Cleanliness.

=item *

Extensibility.

=item *

Easy implementation.

=back


The first of these seems to be met without difficulty by leveraging the HTTP
protocol.

Cleanliness is of course a subjective measure, and this document has pointed
out many points on which we think cleanliness can be improved.

The original specification doesn't seem to address extensibility other than
to list it as a goal. This document's addition of the XML type provides much
extensibility.

Ease of implementation should not be radically decreased by the modified
version of XML-RPC proposed here, except in the handling of Unicode text.
This is likely the main reason ASCII was specified in the original protocol
definition.


=head1 ADDITIONAL INFORMATION

The following sections provide details behind the proposed XPC.

=head2 Document Type Definition for Proposed XPC

This appendix shows the complete simple DTD for XPC. It is no more complicated
than the XML-RPC DTD (see L<http://www.ipso-facto.demon.co.uk/xml-rpc-inline.html>
or L<http://www.ontosys.com/xml-rpc/xml-rpc.dtd>).

  <!-- We are going to use this parameter entity to refer to the value      -->
  <!-- element types.                                                       -->
  <!ENTITY % value "(scalar|array|struct|xml)" >
  <!ENTITY % request "(query|call)" >
  <!ENTITY % response "(prototype|result|fault)" >

  <!-- We can have any number of calls and responses inside the top-level   -->
  <!-- element (but at least one).                                          -->
  <!ELEMENT xpc ( %request; | %response; )+ >
  <!ATTLIST xpc version CDATA #IMPLIED >

  <!-- A query is always empty, and it has an optional procedure attribute. -->
  <!-- It can also have an id attribute to distinguish it from other        -->
  <!-- requests in the same transaction.                                    -->
  <!ELEMENT query EMPTY >
  <!ATTLIST query procedure CDATA #IMPLIED >
  <!ATTLIST query id ID #IMPLIED > <!-- TODO: Can it be ID *and* #IMPLIED? -->

  <!-- A call can have zero or more parameters.                             -->
  <!ELEMENT call (param)* >
  <!ATTLIST call procedure CDATA #REQUIRED >
  <!ATTLIST call id ID #IMPLIED > <!-- TODO: Can it be ID *and* #IMPLIED? -->

  <!-- A param *must* have one of the value elements as a child.            -->
  <!ELEMENT param %value; >
  <!ATTLIST param name CDATA #IMPLIED >

  <!-- Types for scalars are shown here as optional, but they may not need  -->
  <!-- to be part of the design.                                            -->
  <!ELEMENT scalar (#PCDATA) >
  <!ATTLIST scalar type (boolean|integer|rational|string|timestamp|binary)
    #IMPLIED >

  <!-- An array has any number of elements, each of which is of one of the  -->
  <!-- value elements.                                                      -->
  <!ELEMENT array (scalar|array|struct)* >

  <!-- A structure has one or more members.                                 -->
  <!ELEMENT struct (member+) >

  <!-- A member has a name and *must* contain one of the value elements as  -->
  <!-- a child.                                                             -->
  <!ELEMENT member %value; >
  <!ATTLIST member name CDATA #REQUIRED >

  <!-- An xml value element can contain any XML data.                       -->
  <!ELEMENT xml ANY >


  <!-- A fault has a name and contains text.                                -->
  <!ELEMENT fault (#PCDATA) >
  <!ATTLIST fault code CDATA #REQUIRED >
  <!ATTLIST fault id ID #IMPLIED > <!-- TODO: Can it be ID *and* #IMPLIED? -->

  <!-- A result is like a param, and  *must* have one of the value elements -->
  <!-- as a child.                                                          -->
  <!ELEMENT result %value; >
  <!ATTLIST result name CDATA #IMPLIED >
  <!ATTLIST result id ID #IMPLIED > <!-- TODO: Can it be ID *and* #IMPLIED? -->

  <!-- A prototype gives the calling convention for a procedure.            -->
  <!ELEMENT prototype (comment?, (param-def|result-def)*) >
  <!ATTLIST prototype procedure CDATA #REQUIRED >
  <!ATTLIST prototype id ID #IMPLIED > <!-- TODO: Can it be ID *and* #IMPLIED? -->

  <!-- A param-def defines an optional name, type and subtype for the       -->
  <!-- parameter. It may also contain a comment about the parameter.        -->
  <!ELEMENT param-def (comment?) >
  <!ATTLIST param-def name CDATA #IMPLIED >
  <!ATTLIST param-def type (scalar|array|struct|xml) #IMPLIED >
  <!ATTLIST param-def subtype (boolean|integer|rational|string|timestamp|binary) #IMPLIED >

  <!-- A result-def defines an optional name, type and subtype for the      -->
  <!-- result. It may also contain a comment about the result.              -->
  <!ELEMENT result-def (comment?) >
  <!ATTLIST param-def name CDATA #IMPLIED >
  <!ATTLIST param-def type (scalar|array|struct|xml) #IMPLIED >
  <!ATTLIST param-def subtype (boolean|integer|rational|string|timestamp|binary) #IMPLIED >

  <!ELEMENT comment (#PCDATA) >


=head2 XML Schema for Proposed XPC

  <!-- TODO -->


=head2 An XML-RPC E<lt>---E<gt> XPC Gateway

The following XSLT transform will convert XML-RPC requests into XPC requests:

  <!-- TODO -->


The following XSLT transform will convert XPC responses into XML-RPC responses
(where it is possible):

  <!-- TODO -->


The following XSLT transform will convert XPC requests into XML-RPC requests
(where it is possible):

  <!-- TODO -->


The following XSLT transform will convert XML-RPC responses into XPC responses:

  <!-- TODO -->


=head1 AUTHOR

Gregor N. Purdy E<lt>gregor@focusresearch.comE<gt>


=head1 COPYRIGHT

Copyright (C) 2001 Gregor N. Purdy. All rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

