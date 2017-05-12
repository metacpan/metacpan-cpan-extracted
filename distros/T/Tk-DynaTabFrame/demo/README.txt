README for Tk::DynaTabFrame 0.20 Demo Script

This demo script exersizes most of DynaTabFrames (aka DTF)
functionality. You can configure some things from the
command line:

-s <side> : set the tab side; <side> is any of 
	nw, ne, sw, se, wn, ws, en,es, n, s, e, w

-c <color> : set the tab color; <color> is any
	valid Tk color name

-r <color> : set the tab raised color; <color> is any
	valid Tk color name

Several buttons are available:

Ok : exits the demo

Flash : starts flash() on the currently raised tab

Tab Side browser : selects the tab side. Note that
this must be set before any tabs have been created

Flip Tab: exersizes pagecget()/pageconfigure() by reading the
raised tab's label, reversing it, and setting it back

Get Tabs: exersizes cget(-tabs); displays the captions
of all the tabs

Raise... : exersizes programmatic raise; opens a dialog
in which to enter a page name; note that the label text
is different than the page name; use 'Get Tabs' to list
the available page names

Lock/Unlock : locks/unlocks the tabs from being rearranged
on window resize

Toggle Rotate : enables/disables tab row rotation on
raise events

Toggle Text Align : switches between aligned, and
unaligned text in buttons (aligned => horizontal
text for top/bottom tabs, vertical text for side tabs;
unaligned in opposite)

Remove Tab : removes the currently raised tab

Add Image Tab : adds a tab with -image

Add Text Tab : adds a tab with -label

Hide : hides the currently raised tab, and adds its 
	caption to the "Hidden" dropdown box

Reveal: a dropdown box listing currently hidden
	pages. Selecting an entry and clicking the
	"Reveal" button will restore the page to the display

