package XML::XMetaL;

use strict;
use warnings;

use Carp;
use Hash::Util qw(lock_keys);


our $VERSION = '0.52';

our $singleton;
our $application;
our %custom_handlers;

sub new {
    my ($class, %args) = @_;
    my $self;
    eval {
        lock_keys(%args,qw(-application));
        if ($singleton) {
            $self = $singleton;
        } else {
            $application = $args{-application} ||
                croak "-application argument missing or undefined";
            $self = bless {}, ref($class) || $class;
            lock_keys(%$self, keys %$self);
            $singleton = $self;
        }
    };
    croak $@ if $@;
    return $self;
}

sub _get_application {
    return $application ||
        croak "Application object does not exist";
}

sub get_handler {
    my ($self, $key) = @_;
    return $custom_handlers{$key} || croak "Handler ".($key || "UNDEF")." does not exist";
}


sub add_handler {
    my ($self, %args) = @_;
    my $handler_exists_exception = "Handler is registered already";
    eval {
        lock_keys(%args, qw(-system_identifier -handler));
        my $dtd_name = $self->_base_path($args{-system_identifier});
        die $handler_exists_exception if exists $custom_handlers{$dtd_name};
        $custom_handlers{$args{-system_identifier}} = $args{-handler};
    };
    if ($@ eq $handler_exists_exception) {
        return;
    } elsif ($@) {
        croak $@;
    }
}

sub _base_path {
    my ($self, $system_identifier) = @_;
    my ($base_name) = $system_identifier =~ /([^\\\/]+)$/;
    return $base_name;
}

# ======================================================================
# Dispatcher
#
# The AUTOLOAD method generates dispatch methods automatically,
# and installs them in the symbol table
# ======================================================================

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self, @args) = @_;
    my ($class, $method) = $AUTOLOAD =~ /^(.*)::(.*)$/;
    return if $method eq 'DESTROY';
    no strict 'refs';
    *{$AUTOLOAD} = sub {
        my ($self, @args) = @_;
        my $application;
        my @return_values;
        eval {
            $application = $self->_get_application() ||
                die "Dispatch method $method called, but there is no application object";
            my $active_document = $application->{ActiveDocument} ||
                die "Dispatch method $method called, but there is no active document";
            my $doctype = $active_document->{doctype} ||
                die "The active document had no doctype";
            my $system_identifier = $doctype->{systemId} ||
                die "The doctype declaration of the active document had no system identifier";
            my $handler = $self->get_handler($system_identifier) ||
                die "Handler for system identifier $system_identifier could not be found";
            @return_values = $handler->$method(@args);
        };
        if ($@ && $application) {
            $application->Alert("$@");
        } elsif ($@) {
            croak $@;
        }
        return wantarray ? @return_values : $return_values[0];
    };
    $self->$method(@args);
}




1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::XMetaL - Dispatch class for XML::XMetaL development framework

=head1 VERSION

This document refers to version 0.50 of XML::XMetaL, released 1st of August
2003.

=head1 SYNOPSIS

In XMetal .mcr files:

    ...
    <MACROS>
        <MACRO name="On_Macro_File_Load" key="" lang="PerlScript">
            <![CDATA[
                use XML::XMetaL;
                use XML::XMetaL::Custom::Bingo;
                my $handler = XML::XMetaL::Custom::Bingo->new(-application => $Application);
                $dispatcher = XML::XMetaL->new(-application => $Application);
                $dispatcher->add_handler(
                                            -system_identifier  => "bingo.dtd",
                                            -handler            => $handler
                );
                $dispatcher->On_Macro_File_Load();
            ]]>
        </MACRO>
        <MACRO name="On_Document_Save" key="" lang="PerlScript">
            <![CDATA[
                $dispatcher->On_Document_Save();
            ]]>
        </MACRO>
        ...
    </MACROS>

In XMetaL .ctm files:

    ...
    <OnInsertElementList>
        <OnInsertElement>
            <Name>section</Name>
            <Lang>PerlScript</Lang>
            <InsertElemScript>
                <![CDATA[$dispatcher->ctm_section()]]>
            </InsertElemScript>
        </OnInsertElement>
        ...
    </OnInsertElementList>
    ...


=head1 ABSTRACT

XML::XMetaL is a framework for object oriented XMetaL development using Perl.
The framework makes it easy to write Perl classes that customize XMetaL.
The advantages of using the framework are:

=over 4

=item *

Object oriented development.

Object oriented XMetaL application development, with nearly all code
moved from XMetaL .mcr and .ctm files to Perl modules.

In addition to the advantages of object oriented development, this
makes it possible to use any editor for XMetaL development, not just
Visual Studio (XMetaL 4+), or the built in editor (XMetaL 1.0 - 3.1).

=item *

Better control over shared functions and code reuse.

There is no longer any need to use global customization files, such as
xmetal.mcr to share functionality over several customization packages.
Instead, common functionality is factored out into Perl modules and
reused only by those customizations that need them.

This reduces the risk of conflicts between different customizations
installed on the same XMetaL client.

=item *

Automated unit and function testing.

Using the framework it is possible to write automated unit and function
tests for XMetaL applications using Test::More and other test frameworks.

=item *

Utility functions.

Useful utility functions, including a word counter, id generator,
common XMetaL constants, node iterator, and more.

=back


=head1 DESCRIPTION

The XML::XMetaL class is a dispatcher for XMetaL customization handlers.
XML:XMetaL objects are singletons. There can be only one XML::XMetaL
object instantiated at any one time.

If an XML::XMetaL object already exists, the constructor (C<new>) will
just return the already existing object.

Customization handlers are registered and associated with a system
identifier with the C<add_handler> method.

When a method is called on a dispatcher (XML::XMetaL object), the
dispatcher figures out which handler that should handle the call,
and forwards the method call to the handler.

For example, calling C<On_Document_Save> on the dispatcher, will make the
dispatcher call the C<On_Document_Save> method for the handler associated
with the system identifier of the currently active document.

When the dispatcher calls a handler, the call is wrapped in an C<eval>
block. If an exception is thrown by the handler, it will be caught by
the dispatcher and the error message will be shown in an XMetaL Alert
box.

=head2 Constructor and initialization

    <MACRO name="On_Macro_File_Load" key="" lang="PerlScript">
        <![CDATA[
            use XML::XMetaL;
            use XML::XMetaL::Custom::Bingo;
            my $handler = XML::XMetaL::Custom::Bingo->new(-application => $xmetal);
            $dispatcher = XML::XMetaL->new(-application => $Application);
            $dispatcher->add_handler(
                                        -system_identifier  => "bingo.dtd",
                                        -handler            => $handler
            );
            $dispatcher->On_Macro_File_Load();
        ]]>
    </MACRO>

The constructor call must be placed in the C<On_Macro_File_Load> macro in the
.mcr file of an XMetaL customization package. This macro is executed when
the XMetaL macro file is first loaded.

=over 4

=item C<new>

    C<new(-application => $Application)>

The constructor takes a single argument, the XMetaL application object. The
C<$Application> variable is instantiated automatically by XMetaL.

The XML::XMetaL objects are singletons, i.e. only one XML::XMetaL object can
be instantiated. If the constructor is called a second time, it will just
return the existing object.

=item C<add_handler>

    $dispatcher->add_handler(
                                -system_identifier  => "bingo.dtd",
                                -handler            => "XML::XMetaL::Custom::Bingo"
    );

The C<add_handler> method adds a handler for a particular XMetaL customization
package. The handler must be a subclass of L<XML::XMetaL::Base>. The handler
is associated with a system identifier.

The system identifier is used to determine which handler to use with a
particular document instance.

=back

=head2 Class Methods

None.

=head2 Public Methods

None, but see the C<AUTOLOAD> subsection below.


=head2 C<AUTOLOAD> Method

Whenever a method is called on the dispatcher that does not exist, it is
assumed that this is a method call that should be forwarded to a handler
object.

C<AUTOLOAD> generates a wrapper method that can forward the call to a
handler and installs it in the symbol table. It then calls the newly
created wrapper method.

The next time the method is called, it will already exist, and is
executed directly, without going through the C<AUTOLOAD> method.

The dispatch methods generated by C<AUTOLOAD> will wrap calls to handlers
in C<eval> blocks. Errors trapped by the dispatch method will be
displayed in an XMetaL Alert box. Handlers should preferably handle
their own errors in a more graceful manner, but this provides a last
ditch failsafe mechanism.

=head1 ENVIRONMENT

The Corel XMetaL XML editor must be installed.

=head1 BUGS

A lot, I am sure.

Please send bug reports to E<lt>henrik.martensson@bostream.nuE<gt>.

=head1 UTILITIES

=head2 C<gmcr.pl>

Setting up macro files in XMetaL can be tedious. The C<gmcr.pl> script
automatically generates .mcr files containing the most common macro calls.

Output is to STDOUT by default, so it must be redirected to a file using
the standard MSDOS redirection mechanism.

Example:

 gmcr.pl bingo.dtd XML::XMetaL::Custom::Bingo >bingo.mcr

Synopsis:

 gmcr.pl [-m] [-g] [-h] sysid module >outfile.mcr

 sysid       = The system identifier of the documents to be customized
               using the module
 module      - The Perl module used to customize XMetaL
 -f          - Add file events (Replaces XMetaL's default file open
               and save operations)
 -m          - Add mouse events (may slow XMetaL down)
 -g          - Add global macro events
 -h          - Print this help message
 outfile.mcr - An XMetaL macro file

The following event types can not be generated using gmcr.pl:

=over 4

=item *

C<On_Drop_format>

=item *

C<On_Drag_Over_format>

=back

=head1 TO DO

There are lots of things in the pipeline. The following list is just a
few highlights. Whether they will ever be anything more than neat
ideas depends on two things: how much time I have to work on them, and
whether anyone is interested. (If you are, drop me an email. It will
definitely improve your chance of seeing these features anytime soon.)

=over 4

=item .ctm call generator

With XMetaL it is possible to trigger a script when tags are to be inserted.
This is a very powerful mechanism, allowing such things as automated id
generation and the insertion of complex, context dependent markup structures.

However, this requires customizing .ctm files. Up to XMetaL 3.1, a
customization editor was included with XMetaL. In XMetaL 4.0, the
customization editor is available only in the developer version.
Furthermore, the customization editor is now a Visual Studio plug-in.

This is bad news for everyone that does not use Visual Studio. It is also
bad news for Visual Studio users that want to do object oriented, and/or
Perl development, because the XMetaL plug-ins for Visual Studio support
neither.

Fortunately, .ctm files are just XML files, and can be edited in XMetaL, just
like any other XML file. Adding calls to the dispather manually is tedious
though. It is also time consuming. Even worse, it is error prone, because
if the handler methods change, the .ctm file isn't updated automatically.
It is very easy to add code for handling an element, or class of
elements, and then forget to add calls to the code. It is even easier
to remove code, and then forget to remove the calls.

Enter the .ctm call generator. It will analyse handlers, look for
methods named C<ctm_elementname> and add or remove method calls in the
.ctm file as appropriate.

Whether the call generator will be just a Perl script, or a full blown
XMetaL customization package in its own right, is still undecided.
Whichever it will be, I hope to be able to include it in the next release.

=item XLink support

Eventually, there will be some sort of support for Simple XLink, and
possibly even Extended XLink support.

=item Public Identifier Support

I will add the capability to identify handlers based on public identifiers
as an alternative to identification by system identifier.

This is useful because, unlike system identifiers, public identifiers
are not tied to a physical location. (Well, this is fibbing a bit.
System identifiers can be either URLs or URNs. URLs point to a location.
URNs identify DTDs by name, much as public identifiers do. Unfortunately,
URNs aren't very well supported by most XML applications.)

=item Dispatcher XML Schema Support

Currently, the dispatcher can't handle documents using XML Schema and
XML Schema Instance (XSI). This is because the dispatcher looks in the
doctype node to get the system identifier, but it does not know about
XSI and C<xsi:schemaLocation> attributes.

=item XML SchemaLocation Remapping

The C<xsi:schemaLocation> attribute suffers from the same problems as the
system identifier in a doctype: if it is a URL, pointing at a physical file,
the document will not validate if the location of the schema is changed.
If the URL is relative, even moving the document from one computer
to another may make it impossible to validate.

URNs don't have this problem, but on the other hand, support for them isn't
implemented in XMetaL.

The schemaLocation remapping functionality will make it possible to remap a URI
that can't be resolved by XMetaL to a URL that can be resolved.

This might be done by implementing catalog file support in the remapping
mechanism, or by some other mechanism.

=item C<XML::XMetaL::Utilities::TreeWalker>

A treewalker for XMetaL. The treewalker will be able to process nodes
while traversing them top-down or bottom-up.

=item Formatting Object Interface

The Formatting object interface in XMetaL 4.0 is accessible
through JScript only. This is unfortunate, but it can be fixed.

I plan to implement access to the following functions through Perl:

=over 4

=item previewHTML 

=item previewPDF 

=item saveAsHTML 

=item saveAsPDF 

=item XMLToHTMLSetup 

=item XMLToPDFSetup 

=back

=item C<Class::Wrapper::XMetaL::*>

This will be a set of decorator objects that wrap XMetaL objects and
add new functionality to them.

For example C<Class::Wrapper::XMetaL::Documents> could add the capability
to handle Perl file handles to the C<Open> method. It would be possible
to add XLink and XInclude capabilities and other functionality that
appear as if they are part of the standard XMetaL API.

=item Deployment

Currently there is no standardised way to deploy XML::XMetaL itself,
or XML::XMetaL based module packages at the same time as deploying
the XMetaL application (.dtd, .css, .mcr, .ctm, .tbr, and other files).

So far, I have just cobbled together a Perl script for handling the
installation on a case by case basis.

A better solution is needed, particularly where there are a lot of
clients to be updated.

PerlMSI might be the thing to use, but there are other alternatives.
When I come up with a generic deployment solution, it will certainly make
its way into an XML::XMetaL update.

=item XInclude Support

XInclude support is more of a "could come in handy" than a must have.
At least for now.

=back


=head1 SEE ALSO

See L<XML::XMetaL::Base>, L<XML::XMetaL::Factory>, L<XML::XMetaL::Registry>,
L<XML::XMetaL::Utilities>, L<XML::XMetaL::Iterator>,
L<XML::XMetaL::Filter::Base>.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@bostream.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
