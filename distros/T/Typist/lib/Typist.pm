package Typist;
use strict;
use warnings;

use base 'Class::Accessor::Fast';

use Typist::L10N;

use vars qw( $typist $VERSION );
$VERSION = 0.02;

my @FIELDS = qw( prefix publish_charset timezone_offset tmpl_path );

Typist->mk_accessors(@FIELDS);

sub new {
    my ($class, %param) = @_;
    my $self = bless {}, $class;
    map { $self->$_($param{$_}) if $param{$_} } @FIELDS;
    $self->prefix('MT') unless $self->prefix;
    $typist = $self;
    $self;
}

sub instance {
    return $typist if $typist;
    my $class = shift;
    $typist = $class->new(@_);
}

my $has_encode = ($] > 5.007003) && (eval { require Encode; 1 });
my %encode_map = (
                  'shiftjis'    => 'shift_jis',
                  'iso-2022-jp' => 'jis',
                  'euc-jp'      => 'euc',
                  'utf-8'       => 'utf-8',
                  'utf8'        => 'utf-8',
                  'iso-8859-1'  => 'iso-8859-1',
);

my $LH;

sub set_language { $LH = Typist::L10N->get_handle($_[1]) }

sub translate {
    my $this   = shift;
    my $phrase = $LH->maketext(@_);
    return $phrase if $LH->ascii_only || !$has_encode;
    my $from = lc $LH->encoding;
    $from = $encode_map{$from} || $from;
    my $to = lc(Typist->instance->publish_charset || $from);
    $to = $encode_map{$to} || $to;
    Encode::from_to($phrase, $from, $to) if $to ne $from;
    $phrase;
}

sub current_language { $LH->language_tag }
sub language_handle  { $LH }

1;

__END__

=begin

=head1 NAME

Typist - A template engine and framework like the ones found
in Movable Type and TypePad

=head1 DESCRIPTION

Began as a prototype and mental exercise of the authors that
is inspired by the template engines from in MT and TypePad.

I spend most of my development time working with Movable
Type and to a lessor extent. The vast majority of my Perl
code is for Movable Type and when its not its creating an
open source module for CPAN that works like something in MT.

When I do have to develop something outside of Movable Type
I reach for L<CGI::Application> and L<Data::ObjectDriver>
which are quite similar to what MT provides. The one thing I
miss the though is MT's template engine.

MT's application screen are generated using
L<HTML::Template>. HTML::Template is fast, lightweight and
separates logic and layout. The problem is the separation of
logic from layout is done to the point where templates are
almost brain dead.  Almost everything but the most basic
logic must be done before processing a template in the
application code. Want to list 5 instead of 10 items here?
You have to go back to your coder. Want to change the sort
order. Back to your code. Want to pre-select a pulldown menu
item? Each option needs to be wrapped in an C<TMPL_IF>
statement. To me this makes development tedious and
difficult. It also makes reuse of template layouts difficult
if not impossible.

I've looked at other template engines too. My problem with
template engines such as Mason and Template Toolkit is that
it requires the template designer to know Perl or something
similar to it. It also makes writing crap code (a technical
term) too easy. Broaden the scope a moment PHP suffers from
this same issues.

To me the MT template engine is a great balance of
flexibility, power and ease of use. It keeps application
logic and layout neatly separated and can be (and has been)
used by many coding neophytes without knowing a line of Perl
code. With a bit of Perl code it can be extended using easy
to re-distribute plugins. The whole implementation of a tag
used throughout many templates can be easily swapped out and
a template developer wouldn't even know it.

Granted I'm biased by my background, but I think this style
of template engine provides and an option that is currently
missing from Perl programmer's toolkit.

In scratching my own itch and out of curiosity and
frustration I sat down one day and assembled Typist to see
what a standalone version would "look" like in addition to
working through a few ideas to improve what exists.

This distribution is the result of that work with just a bit
of polish.

=head2 CAVEATS

Typist is not a direct port of what is found in MT.
Differences do exist in making this more general purpose and
addressing some shortcomings. See L<DIFFERENCES FROM MT AND
TYPEPAD> below.

Currently Typist is optimized for dynamic page creation
though static publishing like MT and TypePad employ is quite
possible with some additional enhancement and an eventual
goal for this distribution.

=head1 METHODS

=over

=item Typist->new(%options)

The following options can be set when creating when calling
C<new>. See the methods of the same name for more
information on their use.

=over

=item prefix

=item publish_charset

=item timezone_offset

=item tmpl_path

=back

=item Typist->instance

Typist is designed to be a singleton object. Calling
instance returns that object.

=item $typist->prefix([$prefix])

Gets/sets the prefix all tags begins with. Some care needs
to be given so HTML or other output Typist is generating
isn't interpreted as a template markup. This should only be
set B<once> when initializing Typist and then not again. The
default is 'MT'.

=item $typist->publish_charset

=item $typist->timezone_offset

=item $typist->tmpl_path

=item $typist->current_language

=item $typist->language_handle

=back

=head1 DIFFERENCES FROM MT AND TYPEPAD

While this template engines functionality is quite similar
to that found in Movable and TypePad, some differences do
exist. Some of these differences come from making Typist
more general purpose. In other cases its in making a few
improvements and enhancements that as a developer quite
familiar with MT's internals thought was missing or needed.

=over

=item C<Typist::Builder::compile> uses a shallow parser instead
recursive descent.

I've yet to test this theory, but its my belief that a
shallow parser is more efficient then doing recursive
descent. Even once benchmarking can be performed, it will
be hard to say precisely since other changes were made that
would also impact performance.

I also went this route since I didn't want to simply
plagiarize MT's code. This was also begun as a mental
exercise on my own and I've always been intrigued by
Robert's Cameron REX XML Shallow Parser.

http://www.cs.sfu.ca/~cameron/REX.html

=item Variable tags MUST use $ notation.

While I'm all for flexibility, however the optional $
notation of variable tags found in MT and TypePad impacts
performance of the compiler. Further not using $ with
varaiable tags or worse being inconsistent with their
application makes markup harder to read.

=item The order of tag arguments is respected while post
processing.

This minor change which MT 3.3/MTE 1.01 introduced enables
the ability to create filter pipelines. I think that is a
really simple, but very handy thing.

=item C<Typist::Builder::compile> drops the uncompiled hash
element in tokens tree.

I never understood why MT did this because it makes the
tokens tree much larger in memory then it needs to be. In
the one or two instances that I've ever seen this used,
examining the tokens tree could have yielded the same
results as looking at the raw uncompiled markup of child
elements. Hence...

=item C<Typist::Build::compile> stashes the 'root' element of
the tokens tree in the context object when a build begins.

There have been times when I've needed to know what the
parent tags are of the one I'm developing. MT doesn't
provide any means of examining the token tree. By stashing
the root element developers this is possible. This was a bit
easier and less obtrusive then a parent element in the token
tree and having it deviate from MT's operation.

=item Tag handlers have class AND object scope in
C<Typist::Context> module.

Currently in MT (and presumably TypePad) tags are loaded in
the Context class and are available to all other templates
that get processed thereafter. This presents a scoping
problem implementing tags that need to have their use
restricted to a specific template or script. Using Typist
developers can control the scope of a tags use by enabling a
handler to be registered to a specific L<Typist::Context>
object.

=item Removed need for C<local> stash hack.

In MT the stash method is crucial to managing context and
passing values from one handler to the next. Things get
messy when container tag handler needs to stash a value with
a key that is already in use and needs to be maintain for
when the handler completes. One way to handle this issue is
to set the existing value to a temporary value and then set
the stash back once its run. Another way is to use Perl's
local command and manipulate the stash hash table directly.

Here is a real scenario from MT that demonstrates this
issue.

MT is generating a individual archive page for a specific
entry. The entry object gets loaded and stashed with the key
'entry'. Tags like C<MTEntryTitle> can then use this object
to insert its data into the template. This same template has
a unordered list of recent posts. This list of entries is
created using C<MTEntries> that also stashes an entry object
with the key 'entry.' If this loop were to simply set the
'entry' hash with the object, by the time it would get to
laying out the entry the page is for the last entry in the
recent posts list would be in the stash and not the entry
the page is supposed to be generated for. Essentially ever
individual archive page would be this same one over and over
again.

In Typist C<stash> works like a stack and pushes element
rather then overwriting an existing one. An C<unstash>
method to pop value off the stack. This not only avoids
breaking encapsulation to manipulate the stash hash
directly, but allows developers the ability to examine and
evaluate the stack something not possible with the use of
the C<local> hack.

Here is where the C<local> hack comes in. Instead of...

$ctx->stash('entry',$entry);

MT manipulates the underlying stash hash directly and uses
the local command to limit its scope to the current method
(enclosures) execution and maintain the previous value.

local $ctx->{__stash}{'entry'} = $entry;

Once this command is called I don't know if another entry
was in context and if so what it was. I also don't know how
"deep" I am in entry contexts.

Here is some pseudo code of how this would be handled in
Typist:

  # Application sets initial entry for template context
  $ctx->stash('entry',$start);
  
  # Some tag container tag handler that lists entries
  sub tag { 
    for @loop {
      $ctx->stash('entry',$other); 
      my @entries = $ctx->stash('entry'); 
        # @entries has $start and $other 
      my $e = $ctx->stash('entry'); 
        # $e is $other 
      # processing of other contained tags
      $ctx->unstash('entry'); # removes $other for next loop 
    } 
    # $ctx->stash('entry') is back to just $start
  }

Encapsulation is not broken and developers have the option
of examining the stack of elements in a particular stash
key. The downside is that you have to remember to unstash
stashed element as they are not automatically handled 
for you. I'm asserting that this is a small price to pay.

=item Added C<var> method to context for managing template
variables.

C<MT::Template::Context> manages a separate hash of
variables that template tags like C<MTSetVar> and
C<MTGetVar> can manipulate, but nothing in the API is
provided for such manipulations so one was added.

=item Template are file-based and have built in token
caching capabilities.

There is no guarantee that a template will be an object or
even stored in the database like MT and TypePad. A simple
file-based template mechanism has been included in Typist to
provide baseline template functionality. It's likely that
implementations will create their own more sophisticated
template management systems instead of the Typist::Template.

Token caching is something MT had not done until recently.
(Whether TypePad does this is unknown since its externals
are not exposed to developers.) Before a template was
compiled every time it was built.

=item Plugins are modules that register their resources on
import and/or initialization

MT has its own plugin loading mechanism that when introduced
was fine particularly given most MT users where not
developers and tag handlers were generally simple. A lot has
changed since then and the use of plugins has grown
exponentially is number and sophistication. Over this time
its become clear the original system is inadequate and
bogging down the system. For instance all plugins are loaded
with every request no matter if they will be needed or not.
Also plugin files can contain any type of plugin. Besides
these shortcomings, Perl has a perfectly good plugin system
via modules that is well-known and documented to developers.
See L<CGI::Application> and its collection of
L<CGI::Application::Plugin::*> modules.

Implementing plugins as modules by separating plugin types
out and suggesting some naming standards, applications can
more selectively load what it needs into memory.

=back

=head1 NEXT

=over

=item Develop a plugin loader methods either based on
L<Module::Pluggable> or perhaps using a callback hook
plugins could be loaded on demand.

=item The C<Include> tag does not process a file as markup.
How should this be implemented? Argument? Separate tag?

=item Implement a strict mode will throw error if an unknown
tag is encountered.

=item Implement a C<Loop> tag in the standard tagset. How
does this connect up with the stash or vars?

=item Implement a C<Translate> tag in the standard tagset
for localizing strings. This is similar in function to the
C<MT_TRANS> tag which exists outside of MT's template
engine.

=item Should Typist remain a singleton? 

=back

=head1 HELP WANTED (TO DO)

There is plenty to do that I could use help with in
continuing this effort.

=over

=item Plenty of bugs!

There are surely lots of bugs in this release. As mentioned
this code was assembled as part of a prototype and mental
exercise and then refactored and tweaked. It shouldn't be
too buggy (famous last words) since its based and inspired
on different bits of production code, but clearly issues
will exist in this release. B<Please use the CPAN bug
tracker as you find them. Patches would be greatly
appreciated.>

http://rt.cpan.org/Public/

=item TESTS! TESTS! TESTS!

This goes hand and hand with the previous point. Because of
how this came together tests weren't written before coding
and in just getting this out there for public review they
haven't been done yet either. Any help in this area would be
greatly appreciated.

=item Documentation

What's here is a bit hasty and barely a first draft.

=back

=head1 SUPPORT AND FEEDBACK

B<This distribution is hardly even alpha code. Do not use it
for a production application.>

Please direct all feedback, questions and commentary to the
mt-dev mailing list in which I moderate and many knowledge
MT and Perl developers frequent.

=end


