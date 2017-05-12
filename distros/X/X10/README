
Copyright (c) 1999-2017 Rob Fugina <robf@fugina.com>
Distributed under the terms of the GNU Public License, Version 3.0

This code is hosted at Github at https://github.com/fugina-hackery/perl-x10


For now, here's my post to comp.lang.perl.modules about this package,
explaining what I have in mind...

---

I've been writing software for myself to control X10 devices in my home
for the past 6 years.  Up until the last 6 months, it had all been in C.

About 6 months ago, I started from scratch in Perl, and I think it's
time to start publishing my results so I can get some serious feedback.

I code is entirely object-oriented, including several X10 
computer-interface modules inherited from a common abstract module,
support for event scheduling, event callbacks (event-driven), and an
abstracted client-server interface over TCP sockets.  Some of these
capabilities are limited for computer-interface hardware that is 
transmit-only.

Hardware support already exists for the Firecracker, ActiveHome, and
TwoWay/TW523 interfaces, though not all features of these interfaces
are currently used.

I'd like to get this code uploaded to CPAN some time soon, so please voice
your opinions on the namespace ASAP, here on comp.lang.perl.modules or
to me directly at robf@fugina.com.

---


Here's some info regarding the object model, so that you can, if so inclined,
extend this package to support additional hardware devices (X10 <-> computer
interfaces).

All of the modules in this package represent classes -- the package is
entirely object-oriented.

The 'X10' module is designed to set up all the other modules in a
relationship that would implement an X10 daemon process, with scheduler,
macro processor, network listener, etc.

The X10::Controller module is not designed to be used directly -- it's
an abstract class from which other controller modules are derived.
It provides X10 event queueing, compiling of X10 events into X10
instructions (the actual words that go over the wire), and optimization
of the X10 instruction sequences.  It also provides the framework for an
event callback mechanism, whereby any other object may monitor X10 events.

Derived from X10::Controller are several classes that implement the
specifics for several X10 controllers.  Currently implemented are
X10::ActiveHome, X10::TwoWay (for the two-way/TW523 combination),
X10::FireCracker, and X10::Network.  The first three are for actual
interfaces, and the last is for a 'virtual' X10 controller accessed
via a TCP socket.  The other end of X10::Network's TCP connection is
implemented in X10::Server.  The X10::FireCracker has limited capabilities
since the FireCracker device can only send, and not receive, X10 events.

A couple other modules written in support of an X10 server daemon are
X10::Scheduler and X10::MacroProc.  These modules implement an event
scheduler and macro processor, respectively.  The latter relies on
event callbacks to trigger macros, so a bidirectional computer interface
is required.  Macros themselves can be X10 events, or perl code refs,
which means you can control just about anything via X10 -- anything that
you can do in perl.

The remaining modules are for general support of the other modules:
X10::Macro, X10::SchedEvent, X10::Event, X10::EventList...

X10::Device represents a physical device controlled via X10:  a light or
appliance, for example.  My intention is to render this an abstract class,
and the inheriting classes would somehow implement specific behaviours
of certain types of devices and/or X10 modules.  For example, a device
might be configured to be momentary.  Or a device may be pollable to
determine its on/off status or dim level.



PLEASE send feedback/suggestions to me at robf@fugina.com.


