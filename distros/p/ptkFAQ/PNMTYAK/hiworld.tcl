#!/usr/local/X11/wish -f
canvas .c -width 300 -height 200
pack .c ; # Adapted from Example 19-1 of Brent Welch's book
.c create text 40 50 -text "Hello World!" -tag movable
bind .c <Button-1> {%W create text %x %y -text "Hi."}
bind . <Any-KeyPress> { exit }
