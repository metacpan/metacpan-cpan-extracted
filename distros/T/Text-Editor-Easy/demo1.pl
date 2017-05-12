#
# How ugly !
#
# These demos will introduce you to :
#   - the perl Editor program
#       (in which you should be now, if my
#       readme is readable)
#   - the editor perl module which is
#       intensively used by the program
#       (a few objects created by this
#       "full of bugs" module should be
#       running silently now, be careful of
#       unpredictable effects !)
#
#
# As a perl programmer, and in the future
# (of course), you might be interested
# by these 2 elements  :
#
#   - by the program used to edit your code
#     and execute it. You'll have :
#         - powerful perl regular search
#         - maybe one of the most powerful
#           macro langage (this langage,
#           perl of course, is indeed the same
#           that is used to write the program)
#           It didn't cost me a lot since perl
#           has a powerful "eval".
#
#   - by the module itself to write very
#     quickly interactive graphical
#     applications :
#         - you'll be able to write your own
#           "highlight" subs
#         - you'll be able to redirect events,
#           keys... knowing nothing about Tk
#           (a knowledge of perl
#           would help, though)
#
# Let's start now !
#
# You can move your mouse over the
# "Editor" tab on the right
# This will show you the first displays
# that this program has made.
#
# This log is "interactive" : moving
# your mouse over one display
# WITH THE SHIFT KEY PRESSED
# will send you to the line of the file
# that generated it.
#
# The "Eval" tab will be used later.
#
#    In the same way, when you run a perl
# program that you are editing,
# all displays are traced.
#    To see that, press F5 : a new editor will be
# created on the right (with the name "demo1").
# It will contain the displays made by this program 
# (that has been run by F5) :

print "Hello\n";

say ( "Welcome to Text::Editor::Easy"
      . "\n"
      . "introduction" );

sub say {
    print @_;
        print STDERR "....",
    "\n#\n#Writing 'manually' on STDERR...\n";
}

# Again, if you want to check the origin of these prints, move
# your mouse over one display with shift key pressed.
# As you can see, the complete stack call at the time of the print
# is stored (in your ./tmp directory).

# Now, this demo is finished, you can
# mouve you mouse over "demo2.pl"
#