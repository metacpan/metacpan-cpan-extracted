package XML::XMetaL::Base;

use 5.008;
use strict;
use warnings;

use Hash::Util qw(lock_keys);
use Win32::OLE;

use XML::XMetaL::Utilities;

use constant TRUE  => 1;
use constant FALSE => 0;


sub new {
    my ($class, %args) = @_;
    my $self;
    eval {
        lock_keys(%args,qw(-application));
        $self = bless {
            _utilities   => XML::XMetaL::Utilities->new(-application => $args{-application}),
        }, ref($class) || $class;
        lock_keys(%$self, keys %$self);
    };
    croak $@ if $@;
    return $self;
}

sub _get_application {$_[0]->_get_utilities()->get_application()}
sub _get_documents {$_[0]->_get_application()->{Documents}}
sub _get_active_document {$_[0]->_get_utilities()->get_active_document()}
sub _get_utilities {$_[0]->{_utilities}}

# ======================================================================
# Default handlers
# ======================================================================

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self, @args) = @_;
    my ($class, $method) = $AUTOLOAD =~ /^(.*)::(.*)$/;
    return if $method eq 'DESTROY';
    no strict 'refs';
    *{$AUTOLOAD} = sub {
        my ($self) = @_;
        my $application = $self->_get_application();
        $application->SetStatusText("No handler implemented for $method events");
        return $application->{DisplayAlerts};
    };
    $self->$method();
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

XML::XMetaL::Base - Base class for customization package handlers

=head1 SYNOPSIS

 package XML::XMetaL::Custom::Bingo;

 use strict;
 use warnings;

 use base qw(XML::XMetaL::Base);
 ...

In the C<On_Macro_file_load> macro in an .mcr file:

 ...
 use XML::XMetaL::Bingo;
 ...
 $handler = XML::XMetaL::Bingo->new(-application => $Application);
 ...
 $dispatcher->add_handler(
     -system_identifier  => "bingo.dtd",
     -handler            => $handler
 );
 # The dispather forwards the method call to the handler:
 $dispatcher->On_Macro_File_Load();


=head1 DESCRIPTION

The XML::XMetaL::Base class is a base class for XMetaL customization
package handlers.

Subclasses of XML::XMetaL::Base must implement handlers for XMetaL events.
There are two types of events triggered by XMetaL:

=over 4

=item *

Macro Events

=item *

On Insert Events

=back

Both event types are described in more detail below.

=head2 Macro Events

This is the most common type of events. They are triggered by actions
such as opening and closing documents, dragging and dropping objects, etc.
They are described in the I<Event Macros> section of the XMetaL
Programmer's Guide.

Macro events have names like C<On_Document_Open_Complete>, and
C<On_Double_Click>. When a macro event is triggered, a macro of
the same name in the .mcr file is run. Which .mcr file that is used
is determined by the system identifier in the DOCTYPE declaration of the
currently active document. For example, if the system identifier points
to the file C<bingo.dtd>, then event macros in the file C<bingo.mcr>
will be triggered.

When I<not> using XML::XMetaL, the code in a macro can grow quite complex.
This macro code has several drawbacks. For example, a macro cannot be
reused by other customization packages, unless you put it in the global
macro file C<xmetal.mcr>. On the other hand, if you do that, then your
application cannot be easily distributed, because your updated
C<xmetal.mcr> may overwrite someone elses updated C<xmetal.mcr>.

With XML::XMetaL, macros are used in a different manner. Each macro,
except the C<On_Macro_File_Load> macro, where the XML::XMetaL framework
is instantiated, contains only a single line of code, of the form:

 $dispatcher->Some_Macro();

where C<Some_Macro> is the name of the macro triggered by XMetaL.
The dispatcher forwards the method call to an event handler.

For example, the handler called by macros in C<bingo.mcr> could be
XML::XMetaL::Custom::Bingo. XML::XMetaL::Custom::Bingo would be a
subclass of XML::XMetaL::Base.

XML::XMetaL::Custom::Bingo is a front end, a I<Facade> (if you are into
design patterns) for all the code that makes up the Bingo customization
package.

Behind the facade, you can hide as much functionality as you like, you can
develop as many classes as you like, you can develop using OO techniques
and you can reuse as much as you like, without XMetaL knowing about it.

You no longer have any need to modify C<xmetal.mcr>, you don't have to
worry about global variables spilling over from other customization
packages and fritzing things up.

In all, if you are doing heavy customization, or implementing
customization packages for many different DTDs, using XML::XMetaL will
speed up your work and help you keep your code nicely structured.

You can also take external control of XMetaL, for example with a test
script, that runs automated unit or function tests.


=head2 On Insert Events

On insert events are triggered whenever a user inserts a new element in a
document. By default, XMetaL inserts a tag pair, specified in a .ctm
file. It is also possible to have an on insert event trigger a macro.
This macro is also specified in the .ctm file. There is one .ctm file per
customization package, so for the Bingo package used as an example above,
there would be a C<bingo.ctm> file.

When using XML::XMetaL, each on insert event macro should trigger a call
to the event handler, as usual via the dispatcher. The XML::XMetaL
convention is to prefix all methods processing on insert macros with the
prefix C<ctm_> followed by the name of the element to be inserted. A
method call for inserting the element C<list> would thus look like this:

 $dispatcher->ctm_list();

If you stick to this convention, future versions of XML::XMetaL will be
able to use introspection techniques to automatically update .ctm
files when methods are added or removed from a handler.


=head2 Constructor and initialization

 $handler = XML::XMetaL::Bingo->new(-application => $Application);

Note that XML::XMetaL::Bingo is a fictive subclass of XML::XMetaL::Base.
XML::XMetaL::Base, being a base class, is never instantiated directly.

Handlers are always instantiated in an C<On_Macro_File_Load> macro,
because this ensures that a handler will be instantiated the first time
a document of a particular document type is opened.

See L<XML::XMetaL> for more information.

=head2 Class Methods

None.

=head2 Public Methods

None, but see the C<AUTOLOAD> section below.

=head2 C<AUTOLOAD> Method

The C<AUTOLOAD> method provides default event handlers for all events not
explicitly specified. These default handlers are a major reason for
subclassing event handlers from XML::XMetaL::Base in the first place.

The default event handler will open an XMetaL alert box and display a
message telling that no handler has been implemented for this event.
This provides a more graceful way to handle missing event handlers than
just raising an exception and crashing out of the application.


=head1 ENVIRONMENT

The Corel XMetaL XML editor must be installed.

=head1 BUGS

A lot, I am sure.

Please send bug reports to E<lt>henrik.martensson@bostream.nuE<gt>.


=head1 SEE ALSO

See L<XML::XMetaL>.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@bostream.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
