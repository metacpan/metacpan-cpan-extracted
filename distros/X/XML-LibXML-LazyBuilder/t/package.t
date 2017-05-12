# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-LibXML-LazyBuilder.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use XML::LibXML::LazyBuilder; # do not import

sub E {}
sub DOM {}

{
    package XML::LibXML::LazyBuilder;
    my $d = DOM (E A => {at1 => "val1", at2 => "val2", E => "EEE!"},
		 ((E B => {}, ((E "C"),
			       (E "D"))),
		  (E E => {}, ((E "F"),
			       (E "G")))));

    package main;
    is ($d->firstChild->firstChild->nextSibling->firstChild->nextSibling->tagName,
	"G", "package");
    is ($d->firstChild->getAttribute ("E"), "EEE!", "package");
}

{
    package XML::LibXML::LazyBuilder;
    my $d = DOM (E A => {at2 => "val1", at1 => "val2"},
		 ((E B => {}, ((E "C"),
			       (E D => {}, "Content of D"))),
		  (E E => {}, ((E F => {}, "Content of F"),
			       (E "G")))));

    package main;
    is ($d->toStringC14N,
        (qq[<A at1="val2" at2="val1"><B><C></C><D>Content of D</D></B>]
         . qq[<E><F>Content of F</F><G></G></E></A>]), "example");
}
