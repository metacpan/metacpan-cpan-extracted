-Q2.F.3- create a scrollable window of buttons?
***********************************************

From: -II-  Tk Questions and Answers - How can I:

A2.F.3. There are at least two ways to do this.  First, there is a hypertext
widget that one can get from the Tcl User Contributed Code Archive -
(See tcl-faq/part4) and (See tcl-faq/part5) for details -
 which provides such a facility.

And here is some sample code from 
"Michael Moore" <mdm@stegosaur.cis.ohio-state.edu> which shows a way to 
do this using just Tk.

#! /bin/wish -f
#
# This demonstrates how to create a scrollable canvas with multiple
# buttons.
#
# Author : Michael Moore
# Date   : November 17, 1992
#

#
# This procedure obtains all the items with the tag "active"
# and prints out their ids.

proc multi_action {} {
    set list [.frame.canvas find withtag "active"]
    puts stdout "Active Item Ids : "
    foreach item $list {
        puts stdout $item
    }
}

# 
# This simulates the toggling of a command button...
# Note that it only works on a color display as is right now
# but the principle is the same for b&w screens.
# 
proc multi_activate {num id} {
    
    set tags [.frame.canvas gettags $id]
    if {[lsearch $tags "active"] != -1} {
        .frame.canvas dtag $id "active"
        .frame.canvas.button$num configure \
            -background "#060" \
            -activebackground "#080" 
    } else {
        .frame.canvas addtag "active" withtag $id
        .frame.canvas.button$num configure \
            -background "#600" \
            -activebackground "#800"
    }
} 

proc setup {} {
     frame .frame

     scrollbar .frame.scroll \
         -command ".frame.canvas yview" \
         -relief raised

     canvas .frame.canvas \
         -yscroll ".frame.scroll set" \
         -scrollregion {0 0 0 650} \
         -relief raised \
         -confine false \
         -scrollincrement 25

     pack append .frame \
         .frame.scroll    {left frame center filly} \
         .frame.canvas    {left frame center fillx filly}

     pack append .\
         .frame   {left frame center fillx filly}

     button .frame.canvas.action  \
         -relief raised \
         -text "Action" \
         -command "multi_action"
     .frame.canvas create window 1 25 \
         -anchor w \
         -window .frame.canvas.action
     for {set i 2} {$i < 26} {incr i} {
         button .frame.canvas.button$i  \
            -relief raised \
            -background "#060" \
            -foreground wheat \
            -activebackground "#080" \
            -activeforeground wheat \
            -text "Button $i" 
         set id [.frame.canvas create window 1 [expr $i*25] \
            -anchor w \
            -window .frame.canvas.button$i]
         .frame.canvas.button$i configure \
            -command "multi_activate $i $id"
    }
}

setup


Parent document is top of "FAQ: comp.lang.tcl Tk Toolkit Usage Questions And Answers (1/1)"
Previous document is "-Q2.F.2- get -relief to work on my text widgets?"
Next document is "-Q2.F.4- pack a text widget so that it can be resized interactively?"
