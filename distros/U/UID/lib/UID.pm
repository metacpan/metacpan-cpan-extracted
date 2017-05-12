package UID;


###############################################################################################################################

=head1 NAME

B<UID> E<8212> Create unique identifier constants

=cut

###############################################################################################################################

	
=head1 VERSION

Version 0.24 (April 16, 2009)

=cut

our $VERSION="0.24";

use strict; use warnings; use Carp; use utf8;
	

=head1 SYNOPSIS

  use UID "foo";              # define a unique ID
  use UID BAR=>BAZ=>QUX=>;    # define some more
  
  print foo==foo;             # true
  print foo==BAR;             # false
  print foo=="foo";           # false
  
  do_stuff(foo 42, BAR "bar", BAZ "foo");
  # similar to do_stuff(foo=>42, BAR=>"bar", BAZ=>"foo")
  # except the UID foo can be unambiguously distinguished from the string "foo"


=head1 DESCRIPTION

The C<UID> module lets you declare unique identifiers E<8212> values that you can be sure will not be coincidentally matched by some other value.
The values are not "universally" unique (UUIDs/GUIDs); they are unique for a single run of your program.

Define the identifiers with "C<use UID>" followed by one or more strings for the names of the IDs to be created.
"C<use UID I<foo>>" will create a unique constant called I<foo> that is a C<UID> object:
any value equal to I<foo> must be I<foo> itself (or a copy of it).  No other UID (in the same process) will be equal to I<foo>.
C<UID>s can be compared to each other (or to other values) using either C<==> or C<eq> (or C<!=> or C<ne>, of course).

A typical use of C<UID> objects is to form a named pair (like C<< FOO=>42 >>), but note that the pair-comma (C<< => >>) implicitly
quotes the preceding word, so C<< FOO=>42 >> really means C<< "FOO"=>42 >>, using the string C<"FOO"> rather than the UID C<FOO>.  
However, a comma is not always needed; you can say simply C<FOO 42> and often get the same effect as C<FOO, 42>.


=cut

	
	
#===========================================================================
#
# 	UID
#
#===========================================================================


#UIDs are scoped to the package that imports them; could assign "globals" by tracking them in this package (some hash to store the names or something?)  Is this really useful??? (other than for polluting namespaces)

sub import
#	Create a new UID of the given name
#	
#	We take a list of names and make subs out of them (like "use constant")
#	The subs don't do anything; they just return a unique reference (object) --
#	since the ref is anonymous, it will be unique (for this process)
#	Needs to happen at compile time, so Perl will parse the sub/uid names nicely
#	(our own "import" routine will export our identifiers at <use> time)
{
	my $class=shift;							# first arg will always be the package name
	
	for (@_)	# each name requested
	{
		carp "WARNING: Ignoring UID '$_' because it is a ref/object, not a plain string" and next if ref $_;		# UIDs can only be made out of plain strings (valid sub names)	 ###Should we allow this since the object will get stringified? or force the user to stringify it himself explicitly?
		carp "WARNING: Ignoring UID '$_' because that name is already being used" and next if caller()->can($_);	# hm, should be able to override this if using "no warnings redefine"!
		#die rather than warn, unless the existing sub is also a UID??
		
		my $name=(caller()."::$_");	                    	# fully qualified name
		my $ID=bless [$_, $name], $class;		        	# uniqueness: since the array-ref is lexically scoped here, we'll never get this exact ref any other way
		no strict 'refs';			                    	# because we're going to declare the sub using a name built out of a string
		*{$name}=sub {return $ID, @_ if wantarray; croak "ERROR: attempt to use args after UID $ID which is in scalar context (perhaps you need a comma after $ID?)" if @_; return $ID};	
			# if called in array context, return any args as well (allows us to use "UID x, y" without an extra comma); 
			# otherwise return just the UID ref itself; if we tried to pass args when being used in scalar context,
			# complain, because those args would effectively be lost (list in scalar context uses only the first item)
	}
}

# We bless our refs so we can do some useful objecty stuff:
use overload q(""), sub { "«$_[0][0]»" };		# stringifying will return the name so we can usefully print out our IDs in error messages, etc.
use overload '${}', sub {\ "«$_[0][1]»" };		# scalarly de-reffing also has the effect of stringifying, to return the fully qualified name

sub compare { ref($_[0]) eq ref($_[1]) and overload::StrVal($_[0]) eq overload::StrVal($_[1]) };	# for comparing two UIDs (note that first we compare the class -- if they're different kinds of objects, they can't match; if they are, then we compare the actual "memory address" values of the underlying refs, which can only be the same if both sides are in fact the same UID
use overload "==", \&compare;	use overload "!=", sub {not &compare};
use overload "eq", \&compare;	use overload "ne", sub {not &compare};

use overload nomethod=> sub { croak "ERROR: cannot use the '$_[3]' operator with a UID (in: ".($_[2]?"$_[1] $_[3] $_[0][0]":"$_[0][0]() $_[3] $_[1]").")" };

###TODO: add & or | for combining flags? 
###TODO: prolly should disallow redefining BEGIN, etc.!  (plagiarise some more from use-constant)



=head1 EXAMPLES

Here is an example that uses UIDs for the names of named parameters.  
Let's suppose we have a function (C<do_stuff>) that takes for its arguments a list of items to do stuff to,
and an optional list of filenames to log its actions to.  
Using ordinary strings to name the groups of arguments would look something like this:

  do_stuff(ITEMS=> $a, $b, $c, $d, $e, FILES=> $foo, $bar);

The function can go through all the args looking for our "ITEMS" and "FILES" keywords.
However, if one of the items happened to be the string "FILES", the function would get confused.

We could do something such as make the arguments take the form of a hash of array-refs 
(a perfectly good solution, albeit one that requires more punctuation).
Or we could use UIDs (which actually allows for slightly less punctuation):

  use UID qw/ITEMS FILES/;
  
  do_stuff(ITEMS $a, $b, $c, $d, $e, FILES $foo, $bar);

Now the function can check for the UID C<FILES> unambiguously; no string or other object will match it.
Of course, you can still use I<FILES> where it doesn't make sense (e.g., saying C<do_stuff(ITEMS $a, FILES, $c, $d, FILES $foo, $bar)>; 
but you can't make something else that is intended to be different but that accidentally turns out to be equal to I<FOO>.


=head1 TECHNICALITIES

C<UID>s work by defining a subroutine of the given name in the caller's namespace.  
The sub simply returns a UID object.
Any arguments that you feed to this sub are returned as well, which is why you can say C<FOO $bar> without a comma to separate the terms; 
that expression simply returns the list C<(FOO, $bar)>.
(However, beware of imposing list context where it's not wanted: C<FOO $bar> puts C<$bar> in list context, as opposed to C<FOO, $bar>.
Also, if you are passing UIDs as arguments to a function that has a prototype, a scalar prototype (C<$>) 
can force the UID to return only itself, and a subsequent arg will need to be separated with a comma.)

These subroutines work very much as do the constants you get from C<use L<constant>>.
Of course, this means that the names chosen must be valid symbols (actually, you can call things almost anything in Perl,
if you're prepared to refer to them using circumlocutions like C<&{"a bizarre\nname"}>!).

A UID overloads stringification to return a value consisting of its name when used as a string 
(so C<use UID foo; print foo> will display "C<«foo»>").
You can also treat it as a scalar-reference to get a string with the fully-qualified name 
(that is, including the name of the package in which it lives: C<print ${+foo} # e.g. "«main::foo»">).

The comparison operators C<==> and C<eq> and their negations are also overloaded for UID objects:
comparing a UID to anything will return false unless both sides are UIDs;
and if both are, their blessed references are compared.  
(Not the values the references are referring to, which are simply the UIDs' names, but rather the string-values of the refs,
which are based on their locations in memory E<8212>
since different references will always have different values, this guarantees uniqueness.)


=head1 ERROR MESSAGES

=over 1

=item WARNING: Ignoring UID '$_' because it is a ref/object, not a plain string

You tried to make a UID out of something like an array-ref or an object.
The module is looking for a string or strings that it can define in your namespace, and will skip over this arg.


=item WARNING: Ignoring UID '$_' because that name is already being used

A subroutine (or constant, or other UID, or anything else that really is also a sub)
has already been declared with the given name.  
UID prevents you from redefining that name and skips over it.


=item ERROR: attempt to use args after UID $_ which is in scalar context (perhaps you need a comma after $_?)

You put (what appear to be) arguments after a UID, but the UID is in scalar context, thus only a single value can be used
(not the UID plus its arguments).  The solution is probably to put a comma after the UID, or strategically place some parentheses,
to separate it from the following item, rather than letting it take that item as an argument.

=item ERROR: cannot use the '$_' operator with a UID

You tried to operate on a UID with an operator that doesn't apply (which is pretty much all of them).
UIDs can be compared with C<==> or C<eq>, but you can't add, subtract, divide, xor them, etc.

=back 


=head1 BUGS & OTHER ANNOYANCES

No particular bugs are known at the moment.  Please report any problems or other feedback
to C<< <bug-uid at rt.cpan.org> >>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=UID>.

Note that UIDs are less useful for hash keys, because the keys have to be strings, not objects.
You are able to use a UID as a key, but the stringified value (its name) will actually be used (and could conceivably
be accidentally duplicated).  
However, there are modules that can give you hash-like behaviour while allowing objects as keys,
such as L<Tie::RefHash> or L<Tie::Hash::Array> or L<Array::AsHash>.

There are other places where Perl will want to interpret a UID (like any other sub name) as a string rather than as a function call.
Sometimes you need to say things like C<+FOO> or C<FOO()> to make sure C<FOO> is evaluated as a UID and not as a string literal.
As mentioned, hash keys are one such situation; also C<< => >> implicitly quotes the preceding word.
Note that C<&FOO> will work to force the sub interpretation, but is actually shorthand for C<&FOO(@_)>, 
i.e. it re-passes the caller's C<@_>, which is probably not what you want.

Comparing a UID to something else (C<FOO==$something>) will correctly return true only if the C<$something> is
indeed (a copy of) the C<FOO> object; but comparing something to a UID (C<$something==FOO>) could return an unexpected result.
This is because of the way Perl works with overloaded operators: the value on the left gets to decide the meaning of C<==> (or C<eq>).
Thus putting the UID first will check for UID-equality; if some other object comes first, it could manhandle the UID and compare,
say, its string value instead.  
(It probably will work anyway, if the other code is well-behaved, but you should be aware of the possibility.)

=cut

			### Example of tricky object that deliberately confounds our UIDs:
			# 	use UID foo;
			# 	use overload q(==), sub {${$_[0]} eq ${$_[1]}}; use overload fallback=>1; 
			# 	my $x="«main::foo»"; 	my $o=bless \$x;
			# 
			# 	print foo==$o?"Y":"N";		# uses UID's comparison, correctly says no
			# 	print $o==&foo ?"Y":"N"; 	# uses cheater's comparison, says yes!

=pod

While C<FOO $stuff> is slightly cleaner than C<FOO($stuff)> or C<< FOO=>$stuff >> [which would be an auto-quoted bareword anyway],
remember that C<FOO $a, $b> is actually implemented as a function call taking C<$a> and C<$b> as arguments; 
thus it imposes list context on them.  Most of the time this doesn't matter, 
but if the item coming after a UID needs to be in scalar context, you may need to say something like C<FOO, $stuff> or C<FOO scalar $stuff>.

The user should have more control over the warnings and errors that C<UID.pm> spits out.



=head1 COLOPHONICS

Copyright 2007 David Green, C<< <plato aZ<>t cpan.org> >>

Thanks to Tom Phoenix and others who contributed to C<use constant>.

This module is free software; you may redistribute it or modify it under the same terms as Perl itself. See L<perlartistic>. 


=cut


AYPWIP: "I think so, Brain, but then my name would be 'Thumby'!"
