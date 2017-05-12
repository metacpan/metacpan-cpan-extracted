# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s): Nicolas Trebst and Anselm Kruis, science+computing ag
#                 n.trebst@science-computing.de
#                 a.kruis@science-computing.de
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package XML::Sablotron;

use strict;
use Carp;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );

require Exporter;
require DynaLoader;

use XML::Sablotron::Processor;
use XML::Sablotron::Situation;

@ISA = qw( Exporter DynaLoader );

$VERSION = '1.01';

my @functions = qw (
SablotProcessStrings 
SablotProcess 
ProcessStrings 
Process
);

#deprecated export functions
#RegMessageHandler
#UnregMessageHandler
#SablotRegMessageHandler
#SablotUnregMessageHandler

@EXPORT_OK = @functions;
%EXPORT_TAGS = ( all => [@functions] );

use constant HLR_MESSAGE => 0;
use constant HLR_SCHEME => 1;
use constant HLR_SAX => 2;
use constant HLR_MISC => 3;
use constant HLR_ENC => 4;

BEGIN {

}

############################################################
# function for backward compatibility (non-object functions)
############################################################

sub SablotProcessStrings {
    ProcessStrings(@_);
}

sub SablotProcess {
    Process(@_);
}

#sub SablotRegMessageHandler {
#    RegMessageHandler(@_);
#}

#sub SablotUnregMessageHandler {
#    UnregMessageHandler(@_);

sub new (@) {
    my $class = shift;
    $class = (ref $class) || $class;
    my $self = {};
    bless $self, $class;
	my $foo = new XML::Sablotron::Processor( @_ );
    $self->{_processor} = $foo;
    #used to keep references to trees passed in via AddArgTree
    #needed for autodisposed trees
    $self->{_trees} = []; 
    return $self;
}

#############################################
# I've choosen this way (no AUTOLOAD)
# to avoid problems in the future
sub RunProcessor {
    my $self = shift;
    return $self->{_processor}->RunProcessor(@_);
}

sub runProcessor {
    my $self = shift;
    return $self->{_processor}->RunProcessor(@_);
}

sub RunProcessorTie {
    my ($self, $t, $d, $o, $params, $args, $tieclass) = @_;
    my (@params, @args);
    eval "require $tieclass;";
    tie @params, $tieclass, $params;
    tie @args, $tieclass, $args;
    my $ret =  $self->{_processor}->RunProcessor($t, $d, $o, \@params, \@args);
    untie @params;
    untie @args;
    return $ret;
}

sub runProcessorTie {
    my ($self, $t, $d, $o, $params, $args, $tieclass) = @_;
    my (@params, @args);
    eval "require $tieclass;";
    tie @params, $tieclass, $params;
    tie @args, $tieclass, $args;
    my $ret =  $self->{_processor}->RunProcessor($t, $d, $o, \@params, \@args);
    untie @params;
    untie @args;
    return $ret;
}

##############

sub addArg {
    my $self = shift;
    return $self->{_processor}->addArg(@_);
}

sub addArgTree {
    my ($self, $sit, $name, $tree) = @_;
    push @{$self->{_trees}}, $tree;
    return $self->{_processor}->addArgTree($sit, $name, $tree);
}

sub addParam {
    my $self = shift;
    return $self->{_processor}->addParam(@_);
}


sub process {
    my $self = shift;

	if ( ref $_[2] ) {
		return $self->{_processor}->processExt(@_);
	} else {
		return $self->{_processor}->process(@_);
	}
}

##############

sub GetResultArg {
    my $self = shift;
    return $self->{_processor}->GetResultArg(@_);
}

sub getResultArg {
    my $self = shift;
    return $self->{_processor}->GetResultArg(@_);
}

sub RegHandler {
    my $self = shift;
    return $self->{_processor}->RegHandler(@_);
}

sub regHandler {
    my $self = shift;
    return $self->{_processor}->RegHandler(@_);
}

sub UnregHandler {
    my $self = shift;
    return $self->{_processor}->UnregHandler(@_);
}

sub unregHandler {
    my $self = shift;
    return $self->{_processor}->UnregHandler(@_);
}

sub FreeResultArgs {
    my $self = shift;
    return $self->{_processor}->FreeResultArgs(@_);
}

sub freeResultArgs {
    my $self = shift;
    return $self->{_processor}->FreeResultArgs(@_);
}

sub SetBase {
    my $self = shift;
    return $self->{_processor}->SetBase(@_);
}

sub setBase {
    my $self = shift;
    return $self->{_processor}->SetBase(@_);
}

sub SetLog {
    my $self = shift;
    return $self->{_processor}->SetLog(@_);
}

sub setLog {
    my $self = shift;
    return $self->{_processor}->SetLog(@_);
}

sub ClearError {
    my $self = shift;
    return $self->{_processor}->ClearError(@_);
}

sub clearError {
    my $self = shift;
    return $self->{_processor}->ClearError(@_);
}


sub SetContentType {
    my $self = shift;
    return $self->{_processor}->SetContentType(@_);
}

sub setContentType {
    my $self = shift;
    return $self->{_processor}->SetContentType(@_);
}

sub GetContentType {
    my $self = shift;
    return $self->{_processor}->GetContentType(@_);
}

sub getContentType {
    my $self = shift;
    return $self->{_processor}->GetContentType(@_);
}

sub SetEncoding {
    my $self = shift;
    return $self->{_processor}->SetEncoding(@_);
}

sub setEncoding {
    my $self = shift;
    return $self->{_processor}->SetEncoding(@_);
}

sub GetEncoding {
    my $self = shift;
    return $self->{_processor}->GetEncoding(@_);
}

sub getEncoding {
    my $self = shift;
    return $self->{_processor}->GetEncoding(@_);
}

sub SetOutputEncoding {
    my $self = shift;
    $self->{_processor}->SetOutputEncoding(@_);
}

sub setOutputEncoding {
    my $self = shift;
    $self->{_processor}->SetOutputEncoding(@_);
}

DESTROY {
    my $self = shift;
    if (defined $self->{_processor}) {
	#break circular reference in XML::Sablotron::Processor
	$self->{_processor}->_release();
	undef $self->{_processor};
    }
}

eval {
    bootstrap XML::Sablotron $VERSION;
};

if ($@) {
    warn <<"eol";
It seems, that the Sablotron library couldn't be found. Please, check,
whether you have installed this library on your system, and whether it is
visible to the current process. Check the LD_LIBRARY_PATH on *nix
platforms or PATH on Windows.

To install Sablotron visit 
http://www.gingerall.org/charlie/ga/xml/d_sab.xml

eol
    die "Sablotron library could not be loaded ($@)";
}



package XML::Sablotron::Common;

#############################################
# Nicolas:
# Do some error reporting; called usually 
# from C (just a proposal, I found this handy 
# in other projects)
sub _report_err {
    my ($pkg, $file, $line, $func) = caller 1;

    my $message = shift;

    printf STDERR "ERROR in $pkg:\n";
    printf STDERR "      \"$message\"\n";
    printf STDERR "      in $func, $file:$line\n";
}



1;


__END__

=head1 NAME

XML::Sablotron - a Perl interface to the Sablotron XSLT processor

=head1 SYNOPSIS

  use XML::Sablotron qw (:all);
  Process(.....);

If you prefer an object approach, you can use the object wrapper:

  $sab = new XML::Sablotron();
  $sab->runProcessor($template_url, $data_url, $output_url, 
                  \@params, \@arguments);
  $result = $sab->getResultArg($output_url);

Note, that the Process function as well as the SablotProcess function
are deprecated. See the L<"USAGE"> section for more details.

=head1 DESCRIPTION

This package is a interface to the Sablotron API. 

Sablotron is an XSLT processor implemented in C++ based on the Expat
XML parser.

If want to run this package, you need download and install Sablotron
from the
http://www.gingerall.cz/charlie-bin/get/webGA/act/download.act
page. The Expat XML parser is needed by Sablotron
(http://expat.sourceforge.net)

See Sablotron documentation for more details.

You do _not_ need to download any other Perl packages to run
the XML::Sablotron package.

Since version 0.60 Sablotron supports DOM Level2 methods to
access parsed trees, modify them and process them, as well as 
serialize them into files etc. The DOM trees are not dependent 
on the processor object, so you may use them for data or
stylesheet caching.

=head1 USAGE

Generally there are two modes how you may use Sablotron. The first
one (and the simplest one) is based on procedural calls, the second
one is based on object oriented interface.

Note, that the original procedural interface is deprecated and should
not be used.

=head2 Procedural Model

There are two methods exported from the XML::sablotron package:
ProcessString and Process. As we mentioned above, these function are
deprecated and shouldn't be used. Many Sablotron features as
miscellaneous handlers, DOM model etc. are not available trough this
interface. See the L<Exported Function> for the usage of these
procedures. 

=head2 Object Interface

There are two classes defined to deal with the Sablotron processor object.

C<XML::Sablotron::Processor> is a class implementing an interface to
the Sablotron processor object. Multiple concurrent processors are
supported, so you may use Sablotron in multithreaded programs easily.

Implementation of this class contains a circular reference inside Perl
structures, which has to be broken calling the C<_release> method. If
you aren't going to do some hacks to this package, you don't need to
use this mechanism directly.

C<XML::Sablotron> is often the only thing you need. It's a wrapper
around the XML::Sablotron::Processor object. The only quest of this class is to
keep track of life-cycle of the processor, so you don't have to deal with
a reference counting inside the processor class. All calls to this class are
redirected to an inner instance of the XML::Sablotron::Processor object.

As an addition to previous version of XML::Sablotron, there are new
interface methods. We strongly recommend you to use that new
methods. Previous versions used the RunProcessor method, which had
been called with many parameters specifying XSL params, processed
buffers and URLs. New interface methods are more intuitive to use and,
and this is extremely important, they allow to process preparsed DOM
document as well as the new ones.

New methods are:

=over 4

=item * addArg

=item * addArgTree

=item * addParam

=item * process

=back

See references for more.

=head1 API NAME CHANGES

Since the release 0.60 all API uses unique naming convention. Names
starts with lower case letter, first letters of following words are
capitalized. Older user don't have to panic, since old names are kept
for the compatibility.



=head1 SITUATION

Since the release 0.60 there is new object (user internally in
previous versions) used for several tasks. In this Perl module is
represented by the XML::Sablotron::Situation package.

At this time the situation is used only for error tracking, but in
further releases its usage will become quite extensive. (It will be
used for all handlers etc.)

So far you don't have (and it is not even possible many times) to use
the Situation object for processing the data. There is one exception
to this. If you use the DOM interface (XML::Sablotron::DOM module),
you have to create and use the situation object like this:

 $situa = new XML::Sablotron::Situation;

=head1 EXPORTED FUNCTIONS

=head2 ProcessStrings - deprecated

C<ProcessStrings($template, $data, $result);>

where...

=over 4

=item  $template 

contains an XSL stylesheet

=item  $data 

contains an XML data to be processed

=item  $result 

is filled with the desired output

=back

This function returns the Sablotron error code.

=head2 Process - deprecated

This function provides a more general interface to Sablotron. You may
find its usage a little bit tricky but it offers a variety of ways how
to modify the Sablotron behavior.

  Process($template_uri, $data_uri, $result_uri,
          $params, $buffers, $result);

where...

=over 4

=item  $template_uri 

is a URI of XSL stylesheet

=item  $data_uri 

is a URI of processed data

=item  $result_uri 

is a URI of destination buffer. Currently, the arg: scheme
is supported only. Use the value arg:/result. (the name of the
$result variable without "$" sign)

=item  $params 

is a reference to array of global stylesheet parameters

=item  $buffers 

is a reference to array of named buffers

=item  $result 

receives the result. It requires $result_uri to be set to arg:/result.

=back

The following example should make it clear.

  Process("arg:/template", "arg:/data", "arg:/result", 
          undef, 
          ["template", $template, "data", $data], 
          $result);>

does exactly the same as

  ProcessStrings($template, $data, $result);>

Why is it so complicated? Please, see the Sablotron documentation for
details.

This function returns the Sablotron error code.

=head2 RegMessageHandler - canceled

This function is deprecated and no longer supported. See the description of
object interface later in this document.

=head2 UnregMessageHandler - canceled

This function is deprecated and no longer supported. See the description of
object interface later in this document.


=head1 XML::Sablotron

=head2 new

The constructor of the XML::Sablotron object takes no arguments, so
you can create new instance simply like this:

  $sab = new XML::Sablotron();

=head2 addArg

Add an argument to the processor. Nothing (almost) happened at the time
of call, but this argument may be processed later by the C<process>
function. 

  $sab->addArg($situa, $name, $data);

=over 4

=item $situa

The situation to be used.

=item $name

The name of the buffer in the "arg:" scheme.

=item $data

The literal XML data to be parsed and remembered.

=back

=head2 addArgTree

Add a DOM document to the processor. This document may be processed
later with the C<process> call.

  $sab->addArgTree($situa, $name, $doc);

=over 4

=item $situa

The situation to be used.

=item $name

The name of the buffer in the "arg:" scheme.

=item $doc

The DOM document. Must be a XML::Sablotron::DOM::Document instance.

=back

=head2 addParam

Adds the XSL parameter to the processor. The parameter may be accessed
later by the C<process> call.

  $sab->addParam($situa, $name, $value);

=over 4

=item $situa

The situation to be used.

=item $name

The name of the parameter.

=item $value

The value of the parameter.

=back

=head2 process

This function starts the XSLT processing over the formerly specified
data. Data are added to the processor using C<addArg>, C<addArgTree>
and C<addParam> methods.

  $sab->process($situa, $template_uri, $data_uri, $result_uri);

=over 4

=item $situa

The situation to be used.

=item  $template_uri 

The  URI of XSL stylesheet

=item  $data_uri 

The URI of processed data

=item  $result_uri 

The a URI of destination buffer

=back

=head2 runProcessor

The RunProcessor is the older method analogous to the Process
function. You may find it useful, but the use of the C<process>
method is recommended.

  $code = $sab->runProcessor($template_uri, $data_uri, $result_uri,
                             $params, $buffers);

where...

=over 4

=item  $template_uri 

is a URI of XSL stylesheet

=item  $data_uri 

is a URI of processed data

=item  $result_uri 

is a URI of destination buffer

=item  $params 

is a reference to array of global stylesheet parameters

=item  $buffers 

is a reference to array of named buffers

=back

URIs passed to this function may be from schemes supported internally
(file:, arg:) of from any scheme handled by registered handler (see
L<"HANDLERS"> section).

Note the difference between the RunProcessor method and the Process
function. RunProcessor doesn't return the output buffer ($result parameter
is missing).

To obtain the result buffer(s) you have to call the L<"getResultArg"> method.

Example of use:

  $sab->runProcessor("arg:/template", "arg:/data", "arg:/result", 
          undef, 
          ["template", $template, "data", $data] );

=head2 getResultArg

Call this function to obtain the result buffer after processing. The goal
of this approach is to enable multiple output buffers. 

  $result = $sab->getResultArg($output_url);

This method returns a desired output buffer specified by its
url. Specifying the "arg:" scheme in URI is optional.

The recent example of the runProcessor method should continue:

  $return = $sab->getResultArg("result");

=head2 freeResultArgs

  $sab->freeResultArgs();

This call frees up all output buffers allocated by Sablotron. You do not
have to call this function as these buffers are managed by the processor
internally.

Use this function to release huge chunks of memory while an instance of
processor stays idle for a longer time.

=head2 regHandler

Set particular type of an external handler. The processor can use the
handler for miscellaneous tasks such log and error hooking etc.

For more details on handlers see the L<"HANDLERS"> section of this
document. 

There are two ways how to call the RegHandler method:

  $sab->regHandler($type, $handler);

where...

=over 4

=item $type 

is the handler type (see L<"HANDLERS">)

=item $handler 

is an object implementing the handler interface

=back

The second way allows to create anonymous handlers defined as a set of
function calls:

  $sab->regHandler($type, { handler_stub1 => \&my_proc1,
                          handlerstub2 => \&my_proc2.... });

However, this form is very simple. It disallows to unregister the handler
later. 

For the detailed description of handler interface see the Handlers section.

=head2 unregHandler

  $sab->unregHandler($type, $handler);

This method unregisters a registered handler.

Remember, that anonymously registered handlers can't be
unregistered. 

=head2 set/getEncoding

  $sab->setEncoding($encoding);

Calling these methods has no effect. They are valuable for
miscellaneous handler, which may store received values together with
the processor instance.

=head2 set/getContentType

  $sab->setEContentType($content_type);

Calling these methods has no effect. They are valuable for
miscellaneous handler, which may store received values together with
the processor instance.


=head2 setOutputEncoding

  $sab->setOutputEncoding($encoding);

This methods allows to override the encoding specified in the
<xsl:output> instruction. It enables to produce differently encoded
outputs using one template.

=head2 setBase

  $sab->setBase($base_url);

Call this method to make processor to use the C<$base_url> base URI while
resolving any relative URI within a data or template.

=head2 setBaseForScheme

  $sab->setBaseForScheme($scheme, $base);

Like C<SetBase>, but given base URL is used only for specified scheme.

=head2 setLog

  $sab->setLog($filename, $level);

This methods sets the log file name, and the log level. See L<Messages
handler - overview> for details on log levels.

=head2 clearError

  $sab->clearError();

This methods clears the last internal error of processor.

=head1 XML::Sablotron::Situation

Sablotron performs almost all operations in very special context used
for the error tracing. This is useful for multithreaded programing or
if you need called Sablotron in the reentrant way.

The tax you have to pay for it is the need of specifying this context
in many calls. Using DOM access to Sablotron structures requires this
approach almost for every call.

The C<XML::Sablotron::Situation> object represents the execution
context.

E.g. if you want to create new DOM document, you have to do following:

  $situa = new XML::Sablotron::Situation();
  $doc = new XML::Sablotron::DOM::Document(SITUATION => $situa);

The situation object supports several methods you may use if you want
to get more details on error happened.

(Note: In upcoming releases the Situation object will be used for
more tasks like handler registering etc.)

=head2 setOptions

  $sit->setOptions($options);

Control some processing features. The $options parameter may be any
combination of following constants:

=over 4

=item * SAB_NO_ERROR_REPORTING

supress error reporting

=item * SAB_PARSE_PUBLIC_ENTITIES

forces parser to parse all external entities (even public ones)

=item * SAB_DISABLE_ADDING_META

suppress outputting of the meta tag (html method)

=back

=head2 getDOMExceptionCode

Returns the last error code.

=head2 getDOMExceptionMessage

Returns the string characterizing the last occurred error.

=head2 getDOMExceptionDetails

Returns ARRAYREF with several details on the most recent error. See
example: 

  $arr = $situa->getExceptionDetails();
  ($code, $message, $uri, $line) = @$arr;

=head1 HANDLERS

Currently, Sablotron supports four types of handlers.

=over 4

=item * messages handler (0)

=item * scheme handler (1)

=item * SAX-like output handler (2)

=item * miscellaneous handler (3)

=back

=head2 General interface format

Call-back functions implementing handlers are of different prototypes
(not a prototypes in the Perl meaning) but the first two parameters are
always the same:

=over

=item $self

is a reference to registered object, so you can implement handlers the
common object way. If you register a handler with a hash reference (see
L<"RegHandler">, this parameter refers to a hidden object, which is
useless for you.

=item $processor

is reference to the processor, which is actually calling your handler. It
allows you to use one handler for more than one processor.

=back

=head2 Messages handler - overview

The goal of this handler is to deal with all messages produced by
a processor.

Each state reported by the processor is composed of the following data:

=over 4

=item * severity

zero means: not so bad thing; 1 means: OOPS, bad thing

=item * facility

Helps to determine who is reporting in larger systems. Sablotron
always sets this value to 2.

=item * code

An internal Sablotron code.

=back

Each reported event falls into one of predefined categories, which
define the event level. The valid levels include:

=over 4

=item * debug (0)

all stuff

=item * info (1)

informations for curious people

=item * warn (2)

warnings on suspicious things

=item * error (3)

huh, something is wrong

=item * critical (4)

very, very bad day...

=back

The numbers in the parentheses are the internal level codes.

=head2 Messages handler - interface

To define a messages handler, you have to define the following functions (or
methods, depending on kind of registration, see L<"RegHandler">).

=over

=item MHMakeCode($self, $processor, $severity, $facility, $code)

This function is called whenever Sablotron needs display any
message. It helps you to convert the internal codes into your own space of
numbers. After this call Sablotron forgets its code and use the yours.

To understand parameters of this call see: 
L<"Messages handler - overview">

=item MHLog($self, $processor, $code, $level, @fields)

A Sablotron request to log some event.

=over

=item  $code 

is the code previously returned by MHMakeCode

=item  $level 

is the event level (see L<"Messages handler - overview">)

=item  @fields 

are text fields in format of "fldname: following text"

=back

=item MHError($self, $processor, $code, $level, @fields)

is very similar to the MHLog function but it is called only when a bad thing
happens (error and critical levels).

=back

=head2 Messages handler - example

A very simple message handler could look like this:

  sub myMHMakeCode {
      my ($self, $processor, $severity, $facility, $code);
      return $code; # I can deal with internal numbers
  }

  sub myMHLog {
      my ($self, $processor, $code, $level, @fields);
      print LOGHANDLE "[Sablot: $code]\n" . (join "\n", @fields, "");
  }

  sub myMHError {
      myMHlog(@_);
      die "Dying from Sablotron errors, see log\n";
  }

  $sab = new XML::Sablotron();
  $sab->RegHandler(0, { MHMakeCode => \&myMHMakeCode,
                        MHLog => \&myMHLog,
                        MHError => \&myMHError });

That's all, folks.

=head2 Scheme handler - overview

One of great features of Sablotron is the possibility of Scheme
handlers. This feature allows to reference data from any URL
scheme. Every time the processor is asked for some URI
(e.g. using the document() function), it looks for a handler, 
which can resolve the required document.

Sablotron asks the handler for all the document at once. If the handler
refuses this request, Sablotron "opens" a connection to the handler and tries
to read the data "per partes".

A handler can be used for the output buffers as well, so this mechanism also 
supports the "put" method.

=head2 Scheme handler - interface

=over

=item SHGetAll($self, $processor, $scheme, $rest)

This function is called, when the processor is trying to resolve
a document. It supposes, that the MHGetAll function returns the whole document. 

If you're going to use the second way (giving chunks of the document), simply
don't implement this function or return the C<undef> value from it. 

  $scheme parameter holds the scheme extracted from a URI
  $rest holds the rest of the URI

=item SHOpen($self, $processor, $scheme, $rest)

This function is called immediately after SHGet or SHPut is called. Use it
to pass some "handle" (I mean a user data) to the processor. This data will
be a part of each following request (SHGet, SHPut).

=item SHGet($self, $processor, $handle, $size)

This function returns the following chunk of data. The size of the data
MUST NOT be greater then the $size parameter.

$handle is the value previously returned from the SHOpen function.

Return the C<undef> value to say "No more data".

=item SHPut($self, $processor, $handle, $data)

This function stores a chunk of data given in the $data parameter.

=item SHClose($self, $processor, $handle)

You can close you internal connections, files, etc. using this function.

=back

=head2 Scheme handler - example

See the test script (test.pl) included in this distribution.

=head2 SAX handler - overview

Sablotron supports both of physical (file, buffer) and event based
output methods. SAX handler is a bit confusing name, because events
produced by the engine are of a bit different flavors then 'real' SAX
events; think about this feature as about SAX-like handler.

You may set this handler if you want to catch output events and
process them as you wish. Note, that there is XML::SAXDriver::Sablotron
module available, so you don't need to deal with the SAX-like handler, 
if you want to use Sablotron as standard SAX driver.

=head2 SAX handler - interface

=over

=item SAXStartDocument($self, $proc)

Event called at the very beginning of the output.

=item SAXStartNamespace($self, $proc, $prefix, $uri)

Event called when a new namespace declaration occurs.

=item SAXEndNamespace($self, $proc, $prefix)

Event called when a namespace declaration runs out of the scope. Note,
that introducing and canceling namespaces don't have to be properly
nested.

=item SAXStartElement($self, $proc, $name, %atts)

Event called when an element is started. Name and attribute values are
provided.

=item SAXEndElement($self, $proc, $name)

Event called when an element is closed. Called before namespaces run
out of the scope.

=item SAXCharacters($self, $proc, $data)

Event called when data are output.

=item SAXComment($self, $proc, $data)

Event called when a comment occurs.

=item SAXPI($self, $proc, $target, $data)

Event called when processing instruction occurs.

=item SAXEndDocument($self, $proc)

Event called at the very end of the document.

=back

=head2 Miscellaneous handler - overview

This handler was introduced in version 0.42 and could be subject of
change in the near future. For the namespace collision with message
handler misc. handler uses prefix 'XS' (like extended features).

=head2 Miscellaneous handler - interface

=over

=item XHDocumentInfo($self, $processor, $contentType, $encoding)

This function is called, when document attributes are specified via
<xsl:output> instruction. C<$contentType> holds value of "media-type"
attribute, C<$encoding> holds value of "encoding attribute.

Return value of this callback is discarded.

=back

=head2 Miscellaneous handler - example

Suppose template like this:

  <?xml version='1.0'?>
  ...
  <xsl:output media-type="text/html" encoding="iso-8859-2"/>
  ...

In this case XSDocumentInfo callback function is called with values of
"text/html" and "iso-8859-2".

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

The same licensing applies for Sablotron.


=head1 AUTHOR

Pavel Hlavnicka; pavel@gingerall.cz

=head1 SEE ALSO

perl(1).

=cut
