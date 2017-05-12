package WWW::Scripter::Plugin::JavaScript;

use strict;   # :-(
use warnings; # :-(

use Encode 'decode_utf8';
use LWP'UserAgent 5.815;
use Scalar::Util qw'weaken';
use URI::Escape 'uri_unescape';
use Hash::Util::FieldHash::Compat 'fieldhash';
use WWW::Scripter 0.022; # screen

our $VERSION = '0.009';

# Attribute constants (array indices)
sub mech() { 0 }
sub jsbe() { 1 } # JavaScript back-end (field hash of objects, keyed
sub benm() { 2 } # Back-end name  # by document)
sub init_cb() { 3 } # callback routine that's called whenever a new js
                    # environment is created
sub alert()   { 4 }
sub confirm() { 5 }
sub prompt()  { 6 }
sub cb() { 7 } # class bindings
sub tmout() { 8 } # timeouts
sub f()       { 9 } # functions
sub g()        { 10 } # guard objects for back ends, to destroy
                      # them forcibly

{no warnings; no strict;
undef *$_ for qw/mech jsbe benm init_cb g cb
              f alert confirm prompt tmout/} # These are PRIVATE constants!

sub init {

	my ($package, $mech) = @_;

	my $self = bless [$mech], $package;
	weaken $self->[mech];

	$mech->script_handler( default => $self );
	$mech->script_handler(
	 qr/(?:^|\/)(?:x-)?(?:ecma|j(?:ava)?)script[\d.]*\z/i => $self
	);

	$mech->set_my_handler(request_preprepare => sub {
		my($request,$mech) = @_;
		$self->eval(
		 $mech, decode_utf8 uri_unescape opaque {uri $request}
		);
		$@ and $mech->warn($@);
		WWW'Scripter'abort;
	}, m_scheme => 'javascript');

	# stop closures from preventing destruction
	weaken $mech;
	my $life_raft = $self;
	weaken $self;

	$self;
}

sub options {
	my $self = shift;
	my %opts = @_;

	my $w;
	for(keys %opts) {
		if($_ eq 'engine') {
			if($self->[jsbe] &&
			   $self->[benm] ne $opts{$_}
			) {
			    $self->[mech]->die(
			        "Can't set JavaScript engine to " .
			        "'$opts{$_}' since $self->[benm] is " .
			        "already loaded.");;
			}
			$self->[benm] = $opts{$_};;
		}
		elsif($_ eq 'init') {
			$self->[init_cb] = $opts{$_};
		}
		else {
			$self->[mech]->die(
			    "JavaScript plugin: Unrecognized option '$_'"
			);
		}
	}
}

sub eval {
	my($plugin,$mech,$code,$url,$line,$inline) = @_;

	if(
	 $code =~ s/^(\s*)<!--[^\cm\cj\x{2028}\x{2029}]*(?x:
	         )(?:\cm\cj?|[\cj\x{2028}\x{2029}])//
	) {
		$line += 1 + (()= $1 =~ /(\cm\cj?|[\cj\x{2028}\x{2029}])/g)
	}
	$code =~ s/-->\s*\z//;
		
	my $be = $plugin->back_end($mech);

	$be->eval($code, $url, $line);
}

sub event2sub {
		my($self,$mech,$elem,undef,$code,$url,$line) = @_;

		$self->
		  back_end($mech)->event2sub($code,$elem,$url,$line);
}

# We have to associate each JS environment with a response object. While
# writing this logic, I initially tried to use the document, but not all
# URLs have documents (e.g., plain text files).
sub back_end {
	my $self = shift;
ref $_[0] or require Carp, Carp'cluck();
	my $res = (my $w = shift)->res;
	return $self->[jsbe]{$res}
	 if ($self->[jsbe] ||= &fieldhash({}))->{$res};
	
	if(!$self->[benm]) {
# When wspjssm is stable enough, these lines can be uncommented:
#	    # try this one first, since it's faster:
#	    eval{require WWW::Scripter::Plugin::JavaScript::SpiderMonkey};
#	    if($@) {
	        require 
	            WWW::Scripter::Plugin::JavaScript::JE;
                $self->[benm] = 'JE'
#            }
#	    else { $self->[benm] = 'SpiderMonkey' };
	}
	else {
		require "WWW/Scripter/Plugin/JavaScript/" .
			"$$self[benm].pm";
	}

	($self->[g] ||= &fieldhash({}))->{$res}
	 = new WWW'Scripter'Plugin'JavaScript'Guard
	my $back_end = $self->[jsbe]{$res}
	 = "WWW::Scripter::Plugin::JavaScript::$$self[benm]" -> new( $w );
	require HTML::DOM::Interface;
	require CSS::DOM::Interface;
	for ($back_end) {
		for my $class_info( $self->[mech]->class_info ) {
		 $_->bind_classes($class_info) ;
		}
		for my $__(@{$self->[cb]||[]}){
			$_->bind_classes($__)
		}
		for my $__(@{$self->[f]||[]}){
			$_->new_function(@$__)
		}
	} # for $back_end;
	{ ($self->[init_cb]||next)->($w); }
	weaken $self; # closures
	return $back_end;
}

sub bind_classes {
	my $plugin = shift;
	push @{$plugin->[cb]}, $_[0];
	if($plugin->[jsbe]) {
		$_ && $_->bind_classes($_[0])
		 for values %{ $plugin->[jsbe] };
	}
}

sub set { shift->back_end( shift )->set(@_) }

sub new_function {
	my $plugin = shift;
	push @{$plugin->[f]}, \@_;
	if($plugin->[jsbe]) {
		$_ && $_->new_function(@_)
		 for values %{ $plugin->[jsbe] };
	}
}


# ~~~ This is experimental. The purposed for this is that code that relies
#     on a particular version of a JS back end can check to see which back
#     end is being used before doing Foo->VERSION($bar). The problem with
#     it is that it returns nothing unless the JS environment has already
#     been loaded. If we have it start the JS engine, we may load it and
#     then not use it.
sub engine { shift->[benm] }


package WWW::Scripter::Plugin::JavaScript::Guard;

sub new { bless \(my $object = pop) }
DESTROY { local $@; eval { ${$_[0]}->destroy } }


# ------------------ DOCS --------------------#

1;


=head1 NAME

WWW::Scripter::Plugin::JavaScript - JavaScript plugin for WWW::Scripter

=head1 VERSION

Version 0.009 (alpha)

=head1 SYNOPSIS

  use WWW::Scripter;
  $w = new WWW::Scripter;
  
  $w->use_plugin('JavaScript');
  $w->get('http://www.cpan.org/');
  $w->get('javascript:alert("Hello!")'); # prints Hello!
  
  $w->use_plugin(JavaScript =>
          engine  => 'SpiderMonkey',
          init    => \&init, # initialisation function
  );                         # for the JS environment
  
=head1 DESCRIPTION

This module is a plugin for L<WWW::Scripter> that provides JavaScript
capabilities (who would have guessed?).

To load the plugin, just use L<WWW::Scripter>'s C<use_plugin> method:

  $w = new WWW::Scripter;
  $w->use_plugin('JavaScript');

You can pass options to the plugin via the C<use_plugin> method. It takes
hash-style arguments and they are as follows:

=over 4

=item engine

Which JavaScript back end to use. Currently, the only two back ends
available are L<JE>, a pure-Perl JavaScript interpreter, and
L<WWW::Scripter::Plugin::SpiderMonkey> (that back end is bundled
separately). The SpiderMonkey back end is just a proof-of-concept as of
July, 2010, but may become the default in a future version. JE is now the
default.

If this option is
not specified, either JE or SpiderMonkey will be used, whichever is
available. It is possible to
write one's own bindings for a particular JavaScript engine. See below,
under L</BACK ENDS>. 

=item init

Pass to this option a reference to a subroutine and it will be run every
time a new JavaScript environment is initialised. This happens after the
functions above have been created. The first argument will
be the WWW::Scripter object. You can use this, for instance, 
to make your
own functions available to JavaScript.

=back

=head1 METHODS

L<WWW::Scripter>'s C<use_plugin> method will return a plugin object. The
same object can be retrieved via C<< $w->plugin('JavaScript') >> after the
plugin is loaded. The same plugin object is used for every page and frame,
and for every new window derived from the WWW::Scripter object. The
following methods can be called on that object:

=over 4

=item eval

This evaluates the JavaScript code passed to it. The WWW::Scripter object
is the first argument; the string of code the second. You can optionally
pass
two more arguments: the file name or URL, and the first line number.

This method sets C<$@> and returns C<undef> if there is an error.

=item set

Sets the named variable to the value given. The first argument is the
WWW::Scripter object. The last argument is the value. The intervening
arguments are the names of properties, so if you want to assign to a
property of a property ... of a global property, you can pass each property
name separately like this:

  $w->plugin('JavaScript')->set(
      $w, 'document', 'location', 'href' => 'http://www.perl.org/'
  );

=item new_function

This creates a new global JavaScript function out of a coderef. This
function is added to every JavaScript environment the plugin has access to. Pass the WWW::Scripter object as the first argument, the 
name as
the second and the code ref as the third.

=item bind_classes

Instead of using this method, you might consider L<WWW::Scripter>'s
C<class_info> method, which is more general-purpose (it applies also to
whatever other scripting languages might be available).

With this you can bind Perl classes to JavaScript, so that JavaScript can
handle objects of those classes. These class bindings will persist from one
page to the next.

You should pass a hash ref that has the
structure described in L<HTML::DOM::Interface>, except that this method
also accepts a C<< _constructor >> hash element, which should be set to the
name of the method to be called when the constructor function is called
within JavaScript; e.g., C<< _constructor => 'new' >>.

=item back_end

This returns the back end corresponding to the WWW::Scripter object passed
to it, creating it if necessary. This is intended mostly for back ends
themselves to use, for accessing frames, etc.

=back

=head1 FEATURES AVAILABLE TO JAVASCRIPT

The members of the HTML DOM that are available depend on the versions of
L<HTML::DOM> and L<CSS::DOM> installed. See L<HTML::DOM::Interface> and
L<CSS::DOM::Interface>.

For a list of the properties of the window object, see 
L<WWW::Scripter>.

=head1 BACK ENDS

A back end has to be in the WWW::Scripter::Plugin::JavaScript:: name
space. It will be C<require>d by this plugin implicitly when its name is
passed to the C<engine> option.

The following methods must be implemented:

=head2 Class methods

=over 4

=item new

This method is passed a window (L<WWW::Scripter>)
object.

It has to create a JavaScript environment, in which the global object
delegates to the window object for the members listed in 
L<C<%WWW::Scripter::WindowInterface>| WWW::Scripter::WindowInterface/THE C<%WindowInterface> HASH>.

When the window object or its frames collection (WWW::Scripter::Frames
object) is passed to the JavaScript 
environment, the global
object must be returned instead.

This method can optionally create C<window>, C<self> and C<frames>
properties
that refer to the global object, but this is not necessary. It might make
things a little more efficient.

Finally, it has to return an object that implements the interface below.

The back end has to do some magic to make sure that, when the global object
is passed to another JS environment, references to it automatically point
to a new global object when the user (or calling code) browses to another
page.

For instance, it could wrap up the global object in a proxy object
that delegates to whichever global object corresponds to the document.

=back

=head2 Object Methods

=over 4

=item eval

This should accept up to three arguments: a string of code, the file name
or URL, and the first line number.

It must set C<$@> and return C<undef> if there is an error.

=item new_function

=item set

=item bind_classes

These correspond to those 
listed above for
the plugin object. Unlike the above, though, this C<set> is not passed a
window as its first argument. Also, C<bind_classes> and C<new_function> are
only expected to act on a single JavaScript environment. The plugin's own
methods of the same names make sure every JavaScript environment's methods
are called.

C<new_function> must also accept a third argument, indicating the return
type. This (when specified) will be the name of a JavaScript function that
does the type conversion. Only 'Number' is used right now.
This requirement may be removed before version 1.

=item event2sub ($code, $elem, $url, $first_line)

This method needs to turn the
event handler code in C<$code> into an object with a C<call_with> method
and then return it. That object's C<call_with>
method will be
called with the event target and the event
object as its two arguments. Its return 
value, if
defined, will be used to determine whether the event's C<preventDefault>
method is called.

The function's scope must contain the following objects: the global object,
the document, the element's form (if there is one) and the element itself.

If the C<$code> could not be compiled, this method must set C<$@> and
return C<undef>, just like C<eval>.

=item define_setter

This will be called
with a list of property names representing the 'path' to the property. The
last argument will be a coderef that must be called with the value assigned
to the property.

B<Note:> This is actually not used right now. The requirement for this may
be removed some time before version 1.

=head1 PREREQUISITES

perl 5.8.4 or higher

HTML::DOM 0.032 or higher

JE 0.056 or later (if the SpiderMonkey binding even becomes stable enough
it will 
become optional)

CSS::DOM

WWW::Scripter 0.022 or higher

URI

Hash::Util::FieldHash::Compat

LWP 5.815 or higher

=head1 BUGS

=for comment
(See also L<WWW::Scripter::Plugin::JavaScript::JE/Bugs>.)

There is currently no system in place for preventing pages from different
sites from communicating with each other.

To report bugs, please e-mail
L<bug-WWW-Scripter-Plugin-JavaScript@rt.cpan.org/mailto:bug-WWW-Scripter-Plugin-JavaScript@rt.cpan.org>.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2009-16 Father Chrysostomos
<C<< join '@', sprout => join '.', reverse org => 'cpan' >>E<gt>

This program is free software; you may redistribute it and/or modify
it under the same terms as perl.

=head1 ACKNOWLEDGEMENTS

Thanks to Oleg G for providing a bug fix.

=head1 SEE ALSO

=over 4

=item -

L<WWW::Scripter>

=item -

L<HTML::DOM>

=item -

L<JE>

=item -

L<WWW::Scripter::Plugin::JavaScript::SpiderMonkey>

=item -

L<JavaScript.pm|JavaScript>

=item -

L<JavaScript::SpiderMonkey>

=item -

L<WWW::Mechanize::Plugin::JavaScript> (the original version of this module)

=back
