package XUL::Gui::Tutorial;

=head1 XUL::Gui Tutorial

=head2 first steps

after ensuring that a recent (3+ if possible) version of firefox is properly
installed

    use XUL::Gui;    # loads all the XUL and HTML tags into your namespace
                     # along with functions to work with the gui

or if you prefer to use the object oriented interface

    use XUL::Gui 'g->*';  # package 'g' now has XUL::Gui's functions as methods

=head2 hello world

    use XUL::Gui;

    display P 'hello, world!';

    oo: g->display(g->p('hello, world!'));

the C<display> function starts the gui, and then loads any tags it contains.

our call to C<display> contains one tag, an html paragraph C<< <P> >> tag, which
then contains the text.

if you are familiar with XUL, you may be wondering where the C< Window > is.
XUL::Gui attempts to do what you mean as much as possible, so if you don't need
to set any of the window's attributes, omit the window and a default one is
added.

=head2 a little more complicated

    use XUL::Gui;

    display Window title=>'my window',
        H2('events!'),
        Button(
            label => 'click me',
            oncommand => sub {
                my ($self, $event) = @_;

                $self->label = 'ouch!';
            }
        );

    # this is the last oo example
    use XUL::Gui 'g->';

    g->display( g->Window( title=>'my window',
        g->H2('events!'),
        g->Button(
            label => 'click me',
            oncommand => sub {
                my ($self, $event) = @_;

                $self->label = 'ouch!';
            }
        )
    ));

here, we specify the window's title, and in the window place two elements, an
html C<< <H2> >> tag, and an XUL button. the html is old news, so onto the
button. the button's label is initially set to 'click me' and an event handler
is added to the button. 'onclick' or other handlers are also available, but
'oncommand' is the most generic (will catch mouse clicks, keyboard clicks...).

the event handler is an ordinary perl coderef, which, like a method, has its
object passed in as the first argument. the second argument is the event object,
which we don't need here. as you can see, the label method of the button is an
lvalue, so simply assign it a new value.

after C<display> creates the window and its elements, it sits waiting for events
from the gui.

all tags exist both on the perl side and the javascript side, a shared object of
sorts which is hidden behind the scenes. when you click the button, the
'oncommand' event handler in javascript sends the event to perl, which calls the
'oncommand' method of our button. inside the event handler, we call the label
method of the same object. since the label method is not defined in perl,
XUL::Gui assumes it must be over in javascript land, and sets sends an
instruction to set the button's label to 'ouch!'.

the basic rule of thumb with methods is if you define it in perl, it will be
called in perl, otherwise it will be passed to javascript. in other words, all
objects on the perl side override their paired object on the javascript side.

=head2 a simple gui for a command line application

    use XUL::Gui;

    display Window
        title     => 'Foo Processor',
        minheight => 300,
        Hbox( MIDDLE,
            (map {
                my $id = $_;
                CheckBox
                    id     => $id,
                    label  => "use $id",
                    option => sub {
                        shift->checked eq 'true' ? " -$id" : ()
                    }
            } qw/foo bar baz/),
            Label(
                value => 'num: '
            ),
            TextBox(
                id     => 'num',
                type   => 'number',
                option => sub {' -num ' . shift->value}
            ),
            Button(
                label     => 'run',
                oncommand => sub {
                    my @opts = map {ID($_)->option} qw/foo bar baz num/;

                    ID(txt)->value = "fooproc @opts";
                }
            ),
        ),
        TextBox( FILL SCROLL id => 'txt', multiline => 'true' );

breaking that apart, we start with a window and give it a title and minimum
height.  the window contains two elements, an hbox which holds the controls,
and then a textbox which will hold the output of the command.  the textbox has
its 'fill' attribute set, so it will expand to all available space in its parent
window.

our foo processor takes three switches, which are implemented here as
check boxes.  these are followed by a numeric input box, and finally the "run"
button to launch fooproc.

to make the coding of the run button simpler, each of the elements representing
a command line option has been given an 'option' method which returns its
portion of the command line.  there is no special syntax needed to add this
interface to each element.  simply declaring an attribute with a coderef value
creates a method on that object.

if the attribute's name happens to match C< /^on/ > then XUL::Gui will treat it
as an event handler, which is just a special type of method that gets called
from the gui when an event happens.  the button's C< oncommand > attribute is an
example of an event handler.


    ----


several simple example programs have been added to the 'examples' folder of this
distribution.

more in the next update...

=cut

1;
