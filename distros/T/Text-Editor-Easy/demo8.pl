#
# Dynamic designing glance
# and dynamic application glance
# or another thing that can be done
# with a dynamic langage such as perl
#
# What to do with this demo :
# as usual, press F5 first
# (this will clean macro instructions
# and insert correct ones), then :
#
#  1 - change the text of what is inserted
#       in the $self object received by the
#       following anonymous sub (or any
#       other change if you are not afraid of
#       the interface of the Text::Editor::Easy module)
#
#  2 - then add space characters to the macro
#       panel at the bottom to force a new
#       execution of the macro instructions
#       or ... press F5
#
#  3 - then restart step 1 and 2 as much as
#       you want ... and read the comments
#       after this sub if you are not convinced.
#
sub {
    my ( $self, @param ) = @_;

    print "\nIn method 'demo8' of Text::Editor::Easy object $self\n";
    print " received param : @param\n\n";

    $self->deselect;

    my $demo = $param[0] || 2;

    $self->insert("\n\nThe last $demo demos were a bit tricky\n");
    $self->insert("But are you still there ?\n");
    print "A line object : ", $self->insert("Good bye for now"), "\n\n";

    $self->cursor->make_visible;

    return $self->last->previous->previous->select( -6, 8 );
  }

  # And what ?
  # You don't see the point ?
  # This file is in fact the "dynamic"
  # method "demo8" of the Text::Editor::Easy object.
  #
  # Here you are designing your own
  # application from whithin your application :
  # that is to say, you don't have to stop it
  # and restart it to test the sub you are writing.
  #
  # Then, isn't perl faster than C ?
  # In short, perl lacks designing tools that
  # could use all its potential.
  #
  # Imagine you are executing a file explorer,
  # the right clic doesn't please you.
  # You access the code during the execution,
  # and use it just after having modified it,
  # in the same state you were in before
  # the change. Open source with automatic
  # positionning in the code you are interested in,
  # with a trivial object interface you can learn
  # just reading it... what a dream !
  #
  # Well, with the constant increase
  # of the power of computers, why do we still
  # design our programs in machine code ?
  # Sorry, why do we still design our
  # programs statically ?
  # And why are our applications so static ?
  #
  # "Very, very dangerous ! This idea is the
  # stupidest ever heard !!"
  # No ! Very powerful... If you are cautious,
  # perhaps you shouldn't drive a car.
  # Well, this Editor is open source, but, please,
  # it shouldn't be used to control an airplane...
  #