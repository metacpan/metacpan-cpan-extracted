package XUL::Gui::Manual;

=head1 XUL::Gui Manual

Note: at times this document may fall behind what is written in XUL::Gui, in
that case, XUL::Gui is right.

gui programming has always been hard, be it a simple form, or a complex dynamic
interface, the learning curve has always been steep, the boilerplate painful,
and the design patterns, well, they have been quite tedious. then came HTML, and
with it a clean, clear, and concise nested programming style, that has, for the
most part, logical and intuitive functions and styling. it has taken some time
for web browsers to support user interfaces on a par with the native gui in most
operating systems but that time has come. firefox, available for all major
operating systems, provides a rich and extensible framework for developing cross
platform gui applications. these applications are written in XUL, Mozilla's gui
development language, the same language that firefox itself is written in. HTML
is also fully supported, and can be freely intermixed with XUL. as powerful as
XUL and HTML are, they are fundamentally bound to javascript, which if you're
anything like me, just isn't a suitable replacement for perl.

XUL::Gui seeks not only to fully integrate all of the features of the XUL and
HTML markup languages, in both XML and functional forms, but to also proxy every
property, attribute and method from javascript to perl and back enabling
transparent manipulation of the DOM in pure perl.

as functional as XUL and the DOM are, they aren't always the most convenient,
otherwise the various javascript frameworks would not exist. the XUL::Gui proxy
aims to smooth some of the DOM's rough edges by abstracting away the difference
between properties and attributes, and adding plural versions of many functions
(you can also use any javascript framework with XUL::Gui by simply including it
in a <script> tag as you normally would: SCRIPT( src=>"myframework.js" ), but I
hope in most cases that you won't have to)

=head2 tag objects

the primary way of assembling your gui and submitting large updates

    Label( value=>'Hello World' )
    Button( label=>'Click', oncommand=>\&eventhandler )

the parenthesis are optional in simple contexts

    $someparent->appendChild(Label value=>"$count");

but are of course needed for nested objects

    display Window(
        Hbox(
            Label( value=>'Hello, World!' ),
            Button( label=>'Click Me' )
        )
    );

or if you're golfing

    display Hbox
        Label( value=>'hello, world!' ),
        Button label=>'Click Me';

every XUL and HTML tag is imported into your namespace with the following
spellings:

    Somexulname and SomeXulName
    SOMEHTMLNAME and html_somehtmlname

the nesting of tags can be arbitrarily deep and complex and functions of course
follow all the same nesting rules as XML. however unlike XML, the attributes,
properties and children of a tag can be distributed in any order, but its
probably best for readability to keep them at the front of the @_ list. of
course all arguments, children most usefully, are processed in order

    Hbox(
        Vbox( id=>'hbox1',
            Label( value=>'vbox1' ),
            Button( label=>'vbox2', oncommand=>\&eventhandler )
        ),
        Label( value=>'hbox2' ),
        Button( id=>'btn', label=>'hbox3', oncommand=>sub{
            my ($self, $event) = @_;
            print "$self->{ID} received event: ", $event->type, "\n";
            # prints "btn received event: command"
        })
    )

in a tag, to set a property at creation time (if it makes sense), prepend a
single underscore

    Sometag( attributename=>'val', _property=>4 )

tag functions generate an XUL::Gui::Object hashref object that knows how to
create itself and then proxy interaction between perl and javascript for every
attribute, property and method that the corresponding XUL or HTML object has in
javascript. all of the names are mirrored into perl with the exact spelling and
capitalization, however all three are condensed into a single namespace, a perl
$object->method; call

L<http://developer.mozilla.org/en/XUL> serves as the official documentation of
tags and their attributes, properties and methods

inside the hashref itself, all UPPERCASE keys are reserved, but feel free to use
any other keys as you want. a few useful reserved keys to know are:

    ID      the supplied or auto generated id
    TAG     the XUL or HTML tag name
    A       a hashref containing creation time attribute and _property settings
    C       an array ref containing the creation time children
    M       a hashref for user defined methods
    W       the parent widget if it exists

all tags are loaded into the exported C< %ID > hash with their specified id or
an auto generated one. all reserved ids match C</^xul_\d+/>

tag objects are accessed as follows:

    js:     ID.btn = document.createElement('button');
            ID.btn.setAttribute('id', 'btn');
            ID.btn.setAttribute('label', 'Click Me');
            ID.btn.setAttribute('oncommand', handler);
            ID.someparent.appendChild(ID.btn);

    perl:   Button( id=>'btn', label=>'Click Me', oncommand=>\&handler );
            $ID{someparent}->appendChild($ID{btn});

            or all in one line:
            $ID{someparent}->appendChild
                (Button id=>'btn', label=>'Click Me', oncommand=>\&handler);

    js:     ID.btn.getAttribute('attribute')
            ID.btn.setAttribute('attribute', value);

    perl:   $ID{btn}->attribute
            $ID{btn}->attribute = $value;

    js:     ID.btn.property = 5;
    perl:   $ID{btn}->property = 5;

in the event of a namespace collision, the attribute is returned, to get the
property, simply prepend a C<_> to the name. in most cases setting the attribute
works better.

    perl:   $ID{btn}->_forcedproperty = $value;
    js:     ID.btn._prop = 5;     // a property that starts with _
    perl:   $ID{btn}->__prop = 5;  # only the first _ is shifted off

attributes don't start with underscores so they are safe, in the rare event of
an attribute that is not a perl C<\w>, just use the normal
C<(get|set)Attribute()> call

    js:     ID.btn.callMethod();
            ID.btn.callMethod(arg1, arg2);

    perl:   $ID{btn}->callMethod;
            $ID{btn}->callMethod($arg1, $arg2);

here is as good a time as any to explain the DWIM details of how one namespace
in perl maps to three in javascript (and abstracts away the tedious
C<(set|get)Attribute()> calls)

    $ID{btn}->callMethod;           # void context is always a method call
    $ID{btn}->callMethod('@_ > 0'); # any arguments is obvious

    $ID{btn}->somename = 5          # the following selection order is used
        unless $ID{btn}->somename;  #   attribute if hasAttribute(...)
                                    #   function if typeof is function
                                    #   property if has property
                                    #   undef or warn if :lvalue

    $ID{btn}->_somename = 10;       # forced property   ID.btn.somename = 10;
    print $ID{btn}->method_(...);   # forced method     ID.btn.method(...);


the returned value of all -> calls is either a scalar, or a reference to an
appropriate proxy object.

if javascript returns an array, access the object as a perl array reference.

    my $array = gui 'new Array(1, 2, 3)';

    print "@$array";  # prints 1 2 3

    $array->reverse;

    print "@$array";  # prints 3 2 1

the bidirectional translation between perl and javascript is:

        JavaScript      |           Perl
    --------------------|-------------------------
        Array           |   ARRAY ref
        Object          |   Tag Object
        undefined      /|   undef
        null       <--/ |   undef
                        |
    String, Number,     |   SCALAR
    any other scalar    |

the same attribute, property, and method call syntax from tags apply to returned
values as well.

all C<< -> >> operations are atomic and execute immediately unless inside a
pragmatic block.

this is fine for most events, but there are occasions when large changes need to
be made to the gui that would be too slow to send individually to the client.

if you need to add many elements to the gui, you could write it in javascript
with the gui('javascript here') call, but that would be tedious, and Larry tells
us we should be lazy. so use the preferred method of generating your objects
with the tag subs, and utilize map to factor out some of XML's repetition. since
tag objects are not written to the client until they are used in a method call,
such as appendChild(), and then are written in one large message, they are very
fast. a side effect of this means that attempting to set attributes, properties,
or to call javascript methods before using the object in a method call will
result in errors.

that is all well and good, but what about if you need to make many changes to
existing objects such as loading thousands of lines into a list, as with all
Perl, TIMTOWTDI:

    $ID{list}->removeItemAt(0)
        for 1..$ID{list}->getRowCount;             # simple but slow
    $ID{list}->appendItem($_, $_) for @items;      # mirrors the JS solution


    buffered {                                     # a touch longer than the
        $ID{list}->removeItemAt(0) for 1..shift;   # first but easily as clean,
        $ID{list}->appendItem($_, $_) for @items;  # and much faster. keep in
    } $ID{list}->getRowCount;                      # mind that dependent values,
                                           # such as the row count, need to be
                                           # passed in or placed in a now block

    $ID{list}->removeItems              # for a few common tasks, XUL::Gui adds
             ->appendItems(@items);     # plural methods which are easiest and
                                        # fastest of all


=head2 Pragmatic Blocks

    buffered { CODE } LIST;
    # buffer SCALAR, sub{ CODE }, LIST; not implemented
    cached { CODE };
    now { CODE };

buffered accepts a code block that defers proxying all commands to the gui until
the block ends. it also accepts a list in case you need to pass in any
non-defered attributes, as in the last section.

cached accepts a code block that performs set calls normally, but only performs
a particular get once, and then afterward always returns the same value.
javascript function calls behave normally

now is provided as a way to temporarily escape a buffered or cached block
without causing a buffer flush or a cache reset. it does nothing outside of a
pragmatic block.

buffered returns the value of the combined javascript call, useful for testing
for errors. cached and now return the result of their last perl expression.

buffered and cached can be nested in either order. when inside both, get calls
are cached, and set calls are buffered

there is only one buffer and cache, so nesting multiple buffered or cached
blocks has no effect. neither will work inside of a now block.

note that all subroutines called from within a pragmatic block retain that
pragma.

=head3 Event Handler Subs

    sub {
        my ($self, $event) = @_;  # $_ == $self
        $self->someattribute = 'something';
        print $event->type, "\n";
    }


=head3 Widgets

XUL::Gui has a robust widget system designed to group tag patterns and other
widgets. it offers functionality similar to XBL, but entirely in perl, and with
what at least I think is an easier syntax.

    *MyWidget = widget {     # a simple widget
        Hbox(
            Label( value=>'Labeled Button: ' ),
            Button( label=>'OK' )
        )
    };

inside of each widget, the following variables are defined:

    %{ $_{A} }   the attributes passed in to the widget
    @{ $_{C} }   the children passed into the widget
    %{ $_{M} }   a hash containing widget methods, which can be added to
    $_ and $_{W} the widget itself

    $_->mymethod   is the same as  $_{M}{mymethod}($_)

    *MyWidget = widget{     # a widget that accepts attributes and children
        Hbox(
            Label( $_->has('label->value!') ),
            Button( label=>'OK', $_->has('oncommand!') ),
            $_->children
        )
    };
    MyWidget( label=>'My Button: ', oncommand=>\&action, SomeChildObject() );

=head3 Methods and Event Handlers:

    *BetterWidget = widget{
        Hbox
            Label( id=>'lbl', $_->has('label->value!') ),
            Button( id=>'btn' label=>'OK', $_->has('oncommand!') ),
            Button( id=>'exit', label=>'Exit', oncommand=>sub{
                my $self = shift;
                $self->{lbl}->label = 'Goodbye';
                $self->blur;
                quit;
            }),
            $_->children
        }
        mymethod => sub{
            my $self = shift;
            say $self->{lbl}->value;
            $self->{btn}->focus;
        };

     BetterWidget( id=>'better' label=>'Better: ', oncommand=>\&action);
     .....
     $ID{better}->mymethod;  #prints the label's value and focuses the OK button

You may be wondering what happens when you create a second BetterWidget now that
the internal elements have id's. As we have seen, all id's get loaded into the
%ID hash for later reference. However, if widgets behaved the same way, you
could never reuse a widget, and what would be the point? Rather, inside of a
widget, all id's are in their own private lexical space.

After instantiating the widget with an id of 'better':

     $ID{lbl} does not exist, but
     $ID{better}{lbl} does, and can be interacted with as normal.

Inside of a widget's method handlers, $_[0] contains no native methods of its
own, but contains hash keys of all of the id's defined within the widget

Inside of a widget's event handlers, $_[0] contains widget methods that affect
the current object, as well as containing hash keys of all of the id's defined
within the widget, in addition to all of its ordinary attributes, properties,
and methods that go along with Tag objects

Since widgets define their own namespace and methods and behave externally the
same way as normal Tag objects, it is possible to create complex interaction
without much repeated coding.

Widgets also can be nested within each other without limit. Each nested widget
is again its own lexical id space.

    $ID{mainwidget}{subwidget}{lbl}->value = 'something';

=head3 Widgets As Classes

previously we have seen that widgets behave like Tag objects, but Widgets can
also behave like classes, using the extends method.

    *SuperClass = widget{
        Vbox( $_->has('width'),
            Label( value=>'SuperClass' ),
            Button( id=>'btn', oncommand=>sub{...})
        )}
        supermethod = sub{ ... };

    *SubClass = widget{ $_->extends( &SuperClass )}
        submethod = sub{ ... };

any SubClass objects now have both the 'submethod' and 'supermethod' methods,
and SubClass creates the same gui elements as SuperClass. It does this because
extends returns the results from the &SuperClass call. This also means that you
are free to rearrange, add, or dismiss objects from the SuperClass as you see
fit. Named ID's from the superclass are also in the subclass.

    *ReverseClass = widget{
       my @super = $_->extends( SubClass( width=>50, @_ ) );   #add a default value
       reverse @super
    };

    *AnotherClass = widget{
        $_->extends( &ReverseClass );  #throw away super class's objects
        Vbox(
            Label( 'Only the button from SuperClass' ),
            $ID{btn},   #grab the btn
        )
    };


when you call a widget, you need to always use parenthesis due to its runtime
definition, to get around this:

    sub MyWidget;
    *MyWidget = widget{ ... };
    # or
    BEGIN{ *MyWidget = widget{ ... } }

MyWidget can then be called like any native tag object


=head3 inline methods

any key value pair in a tag's argument list with a coderef value and a key that
doesn't match /^on/ is entered into that tag's method table, as if it were a
widget.


=cut

1;
