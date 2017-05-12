#===============================================================================
#
# Text::TagTemplate
#
# A Perl module for working with simple templates, mainly for CGI, mod_perl,
# and HTML use.
#
# Copyright (C) 2000 SF Interactive, Inc.  All rights reserved.
#
# Maintainer: Matisse Enzer <matisse@matisse.net> (30 May 2002)
# Author:  Jacob Davies <jacob@well.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#===============================================================================

package Text::TagTemplate;
use strict;
use 5.004;
use Carp qw(cluck confess);
use English qw(-no_match_vars);
use vars qw( $VERSION );
# '$Revision: 1.1 $' =~ /([\d.]+)/;
$VERSION = '1.83';
use IO::File;
require Exporter;
use vars qw ( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );
@ISA         = qw( Exporter );
@EXPORT      = qw( );
@EXPORT_OK   = qw(
                   auto_cap
                   unknown_action
                   tags
                   add_tag
                   list_tag
                   add_list_tag
                   add_tags
                   delete_tag
                   clear_tags
		   template_string template_file
		   list
		   entry_string
		   entry_file
		   entry_callback
		   join_string
		   join_file
		   join_tags
		   parse
		   parse_file
		   parse_list
		   parse_list_files
		   tag_start
		   tag_contents
		   tag_end
		   tag_pattern
		 );
%EXPORT_TAGS = ( standard => [ qw( tags add_tag add_tags list_tag add_list_tag
                                   delete_tag clear_tags
                                   template_string template_file
				   list
                                   entry_string    entry_file entry_callback
				   join_string     join_file  join_tags
				   parse parse_file parse_list
				   parse_list_files ) ],
                 config   => [ qw( auto_cap unknown_action ) ] );

#===============================================================================
# F U N C T I O N   D E C L A R A T I O N S
#===============================================================================

sub new;
sub auto_cap;
sub unknown_action;
sub tags;
sub add_tag;
sub list_tag;
sub add_list_tag;
sub add_tags;
sub delete_tag;
sub clear_tags;
sub template_string;
sub template_file;
sub list;
sub entry_string;
sub entry_file;
sub entry_callback;
sub join_string;
sub join_file;
sub join_tags;

sub parse;
sub parse_file;
sub parse_list;
sub parse_list_files;

sub tag_start;
sub tag_contents;
sub tag_end;
sub tag_pattern;

sub _self_or_default;
sub _get_file;
sub _htmlesc($);
sub _urlesc($);

#===============================================================================
# P A C K A G E   G L O B A L S
#===============================================================================

# Filehandles:
# GET_FILE

#===============================================================================
# F I L E   V A R I A B L E S
#===============================================================================

my $default_object; # Used if we're skipping making template objects and just
                    # using the default object.

#===============================================================================
# P R I V A T E   F U N C T I O N S
#===============================================================================

#-------------------------------------------------------------------------------
# _self_or_default( @_ )
#
# Takes an @_ argument list, and if it doesn't include a Text::TagTemplate
# object at the beginning, it unshifts the default object.
# *** DEBUG ***
# This breaks inheritance, although it can be made inheritance-safe.

sub _self_or_default {
	my( $class ) = @_;
	return @_ if defined $class and !ref $class
	   and $class eq 'Text::TagTemplate';
	return @_ if defined $class
	   and ( ref $class eq 'Text::Template'
	      or UNIVERSAL::isa $class, 'Text::TagTemplate' );
	$default_object = Text::TagTemplate->new
	   unless defined $default_object;
	unshift @_, $default_object;
	return @_;
}

#-------------------------------------------------------------------------------
# _get_file( $file )
#
# Slurps the supplied file; confesses if it can't find it.

sub _get_file
{
	my( $file ) = @_;
	local $INPUT_RECORD_SEPARATOR = undef;
	open( GET_FILE, "<$file" ) or confess( "couldn't open $file: $ERRNO" );
	my $string = <GET_FILE>;
	close( GET_FILE ) or confess( "couldn't close $file: $ERRNO" );
	return $string;
}

#-------------------------------------------------------------------------------
# _htmlesc( $str )
#
# HTML-escapes a string.

sub _htmlesc($)
{
	my( $str ) = @_;
	return undef unless defined $str;
	$str =~ s/&/&amp;/g;
	$str =~ s/"/&quot;/g;
	$str =~ s/</&lt;/g;
	$str =~ s/>/&gt;/g;
	return $str;
}

#-------------------------------------------------------------------------------
# _urlesc( $str )
#
# URL-escapes a string.

sub _urlesc($)
{
	my( $str ) = @_;
	return undef unless defined $str;
	$str =~ s/([^a-zA-Z0-9_\-.])/ uc sprintf '%%%02x', ord $1 /eg;
	return $str;
}

#===============================================================================
# P E R L D O C
#===============================================================================

=head1 NAME

	Text::TagTemplate

=head1 VERSION

	1.82

=head1 SYNOPSIS

	use Text::TagTemplate qw( :standard );

	# Define a single tag to substitute in a template.
	add_tag( MYTAG => 'Hello world.' );

	# Define several tags all at once. The  tags()  method wipes out
	# all current tags.
	tags( +{ FOO => 'The string foo.',  # Single-quoted string
	         BAR => "$ENV{ USER }",     # Double-quoted string
		 LIST => join( '<LI>', @list ),  # Function call

		 # Functions or subroutines that get called each time
		 # the tag is replaced, possibly producing different
		 # results for the same tag if it appears twice or more.
		 TIME => \&time(),          # Reference to a function
		 SUB => sub {               # Anonymous subroutine
		 	my( $params ) = @_;
			return $params->{ NAME };
		}
	} );

	# Add a couple of tags to the existing set.  Takes a hash-ref.
	add_tags( +{ TAG1 => "Hello $ENV{ USER }",
		     TAG2 => rand( 10 ),  # random number between 0 and 10
		} );

	# Set the template file to use.
	template_file( 'template.htmlt' );

	# This is list of items to construct a list from.
	list( 'One', 'Two', 'Three' );

	# These are template-fragment files to use for making the list.
	entry_file( 'entry.htmlf' );
	join_file(  'join.htmlf'  );

	# This is a callback sub used to make the tags for each entry in a
	# parsed list.
	entry_callback( sub {
		my( $item ) = @_;
		return +{ ITEM => $item };
	} );

	# Add a new tag that contains the whole parsed list.
	add_tag( LIST => parse_list_files );

	# Print the template file with substitutions.
	print parse_file;

=head1 DESCRIPTION

This module is designed to make the process of constructing web-based
applications (such as CGI programs and Apache::Registry scripts) much easier,
by separating the logic and application development from the HTML coding, and
allowing ongoing changes to the HTML without requiring non-programmers to
modify HTML embedded deep inside Perl code.

This module provides a mechanism for including special HTML-like tags
in a file (or scalar) and replacing those tags at run-time with
dynamically generated content. For example the special tag
    <#USERINFO FIELD="favorite_color">

might be replaced by "green" after doing a database lookup. Usually
each special tag will have its own subroutine which is executed every time
the tag is seen.

Each subroutine can be basically anything you might want
to do in Perl including database lookups or whatever. You simply create
subroutines to return whatever is appropriate for replacing each special
tag you create.

Attributes in the special tags (such as the FIELD="favorite_color"
in the example above) are passed to the matching subroutine.

It is not web-specific, though, despite the definite bias that way, and the
template-parsing can just as easily be used on any other text documents.
The examples here will assume that you are using it for convential CGI
applications.

It provides functions for parsing strings, and constructing lists of repeated
elements (as in the output of a search engine).

It is object-oriented, but -- like the CGI module -- it does not require the
programmer to use an OO interface.  You can just import the ``:standard'' set
of methods and use them with no object reference, and it will create and use an
internal object automatically.  This is the recommended method of using it
unless you either need multiple template objects, or you are concerned about
namespace pollution.

=head1 TEMPLATES

The structure of templates is as any other text file, but with extra elements
added that are processed by the CGI as it prints the file to the browser.  These
extra elements are referred to in this manual as ``tags'', which should not be
confused with plain HTML tags -- these tags are replaced before the browser
even begins to process the HTML tags.  The syntax for tags intentionally
mimics HTML tags, though, to simplify matters for HTML-coders.

A tag looks like this:

	<#TAG>

or optionally with parameters like:

	<#TAG NAME=VALUE>

or with quoted parameters like:

	<#TAG NAME="Value, including spaces etc.">

Tags may be embedded in other tags (as of version 1.5), e.g.
    <#USERINFO DISPLAY="<#FAVORITE_COLOR>">

The tag name is the first part after the opening <# of the whole tag.  It must
be a simple identifier -- I recommend sticking to the character set [A-Z_] for
this.  The following parameters are optional and only used if the tag-action is
a callback subroutine (see below).  They are supplied in HTML-style name/value
pairs.  The parameter name like the tag name must be a simple identifier, and
again I recommend that it is drawn from the character set [A-Z_].  The value
can be any string, quoted if it contains spaces and the like.  Even if quoted,
it may not contain any of:

	< > " & =
	
which should be replaced with their HTML escape equivalents:

	&lt; &gt; &quot; &amp; &#061;

This may be a bug.  At present, other HTML escapes are not permitted in the
value.  This may also be a bug.

Tag names and parameter names are, by default, case-insensitive (they are
converted to upper-case when supplied).  You can change this behaviour by
using the auto_cap() method.  I don't recommend doing that, though.

There are four special parameters that can be supplied to any tag, HTMLESC and
URLESC.  Two of them cause the text returned by the tag to be HTML or URL escaped,
which makes outputting data from plain-text sources like databases or text
files easier for the programmer.  An example might be:

	<#FULL_NAME HTMLESC>

which would let the programmer simply put the full-name data into the tag
without first escaping it.  Another might be:

	<A HREF="/cgi-bin/lookup.cgi?key=<#RECORD_KEY URLESC>">



A typical template might look like:

	<HTML><HEAD><TITLE>A template</TITLE></HEAD>
	<BODY>

	<P>This is a tag:  <#TAG></P>

	<P>This is a list:</P>

	<#LIST>

	<P>This is a tag that calls a callback:  <#ITEM ID=358></P>

	</BODY></HTML>

Note that it is a full HTML document.

=head1 TAGS

You can supply the tags that will be used for substitutions in several ways.
Firstly, you can set the tags that will be used directly, erasing all tags
currently stored, using the tags() method.  This method -- when given an
argument -- removes all present tags and replaces them with tags drawn from the
hash-reference you must supply.  For example:

	tags( +{ FOO => 'A string called foo.',
	         BAR => 'A string called bar.' } );

The keys to the hash-ref supplied are the tag names; the values are the
substitution actions (see below for more details on actions).

If you have an existing hash you can use it to define several tags.
For example:

	tags( \%ENV );

would add a tag for each environment variable in the %ENV hash.

Secondly, you can use the add_tags() method to add all the tags in the supplied
hash-ref to the existing tags, replacing the existing ones where there is
conflict.  For example:

	add_tags( +{ FOOBAR => 'A string called foobar added.',
	             BAR    => 'This replaces the previous value for BAR' } );

Thirdly, you can add a single tag with add_tag(), which takes two arguments,
the tag name and the tag value.  For example:

	add_tag( FOO => 'This replaces the previous value for FOO' );

Which one of these is the best one to use depends on your application and
coding style, of course.

=head1 ACTIONS

Whichever way you choose to supply tags for substitutions, you will need to
supply an action for each tag.  These come in two sorts:  scalar values (or
scalar refs, which are treated the same way), and subroutine references for
callbacks.

=head2 Scalar Text Values

A scalar text value is simply used as a string and substituted in the
output when parsed. All of the following are scalar text values:

        tags( +{ FOO => 'The string foo.',  # Single-quoted string
                 BAR => "$ENV{ USER }",     # Double-quoted string
                 LIST => join( '<LI>', @list ),  # Function call
        } );

=head2 Subroutine References

If the tag action is a subroutine reference then it is treated as a callback.
The value supplied to it is a single hash-ref containing the parameter
name/value pairs supplied in the tag in the template.  For example,
if the tag looked like:

	<#TAG NAME="Value">

the callback would have an @_ that looked like:

	+{ NAME => 'Value' }

The callback must return a simple scalar value that will be substituted in the
output. For example:

	add_tag( TAG  => sub {
                    my( $params ) = @_;
                    my $name = $params->{ NAME };
		    my $text = DatabaseLookup("$name");
		    return $text;
                }
        } );


You can use these callbacks to allow the HTML coder to look up data in a
database, to set global configuration parameters, and many other situations
where you wish to allow more flexible user of your templates.

For example, the supplied value can be the key to a database lookup and the
callback returns a value from the database; or it can be used to set context
for succeeding tags so that they return different values.  This sort of thing
is tricky to code but easy to use for the HTMLer, and can save a great deal of
future coding work.

=head2 Default Action

If no action is supplied for a tag, the default action is used.  The default
default action is to confess() with an error, since usually the use of unknown tags
indicates a bug in the application.  You may wish to simply ignore unknown tags
and replace them with blank space, in which case you can use the
unknown_action() method to change it.  If you wish to ignore unknown
tags, you set this to the special value ``IGNORE''. For example:

	unknown_action( 'IGNORE' );

Unknown tags will then be left in the output (and typically ignored by
web browsers.)  The default action is indicated by the special value
``CONFESS''.  If you want to have unknown tags just be replaced by warning text
(and be logged with a cluck() call), use the special value ``CLUCK''.
For example:

	unknown_action( 'CLUCK' );

If the default action is a subroutine reference then the name of the
unknown tag is passed as a parameter called ''TAG''. For example:

	unknown_action( sub {
			    my( $params ) = @_;
			    my $tagname   = $params->{ TAG };
			    return "<BLINK>$tagname is unknown.</BLINK>";
	} );

You may also specify a custom string to be substituted for any
unknown tags. For example:

	unknown_action( '***Unknown Tag Used Here***' );

=head1 PARSING

Once you have some tags defined by your program you need to specify which
template to parse and replace tags in.

You can supply a string to parse, or the name of file to use.
The latter is usually easier.  For example:

	template_string( 'A string containing some tag: <#FOO>' );

or:

	template_file( 'template.htmlt' );

These methods just set the internal string or file to look for; the actual
parsing is done by the parse() or parse_file() methods.
These return the parsed template, they don't store it internally
anywhere, so you have to store or print it yourself.  For example:

	print parse_file;

will print the current template file using the current set of tags for
substitutions.  Or:

	$parsed = parse;

will put the parsed string into $parsed using the current string and tags for
substitutions.

These methods can also be called using more parameters to skip the internally
stored strings, files, and tags.  See the per-method documentation below for
more details; it's probably easier to do it the step-by-step method, though.

=head1 MAKING LISTS

One of the things that often comes up in CGI applications is the need to
produce a list of results -- say from a search engine.

Because you don't
necessarily know in advance the number of elements, and usually you want each
element formatted identically, it's hard to do this in a single template.

This
module provides a convenient interface for doing this using two templates
for each list, each a fragment of the completed list.  The ``entry''
template is used for each entry in the list.
The ``join'' template is inserted in between each pair of entries.
You only need to use a ''join'' template if you, say, want a
dividing line between each
entry but not one following the end of the list.  The entry template
is the interesting one.

There's a complicated way of making a list tag and an easy way.  I suggest
using the easy way.  Let's say you have three items in a list and each of them
is a hashref containing a row from a database.  You also have a file with a
template fragment that has tags with the same names as the columns in that
database.  To make a list using three copies of that template and add it as a
tag to the current template object, you can do:

	add_list_tag( ITEM_LIST => \@list );

and then when you use the tag, you can specify the template file in a parameter like this:

	<#ITEM_LIST ENTRY_FILE="entry.htmlf">

If the columns in the database are "name", "address" and "phone", that template might look like:

	<LI>Name: <#NAME HTMLESC><BR>
	Address: <#ADDRESS HTMLESC><BR>
	Phone: <#PHONE HTMLESC</LI>

Note that the path to the template can be absolute or relative; it can
be any file on the system, so make sure you trust your HTML people if you
use this method to make a list tag for them.

The second argument to add_list_tag is that list of tag hashrefs.  It might
look like:

	+[ +{
		NAME => 'Jacob',
		ADDRESS => 'A place',
		PHONE => 'Some phone',
	}, +{
		NAME => 'Matisse',
		ADDRESS => 'Another place',
		PHONE => 'A different phone',
	}, ]

and for each entry in that list, it will use the hash ref as a miniature
set of tags for that entry.

If you want to use the long way to make a list (not recommended; it's what
add_list_tag() uses internally), there are three things you need to set:

=item A list (array).

=item An entry template.

=item A subroutine that takes one element of the list as an argument and
returns a hash reference to a set of tags (which should appear in the
entry_template.)

You set the list of elements that you want to be made into a parsed list using
the list() method.  It just takes a list.  Obviously, the ordering in that list
is important.  Each element is a scalar, but it can be a reference, of course,
and will usually be either a key or a reference to a more complex set of data.
For example:

	list( $jacob, $matisse, $alejandro );

or
	list( \%hash1, \%hash2, \%hash3 );

You set the templates for the entry and join templates with the entry_string()
& join_string() or entry_file() & join_file() methods.  These work in the way
you would expect.  For example:

	entry_string( '<P>Name:  <#NAME></P><P>City:  <#CITY></P>' );
	join_string( '' );

or:

	entry_file( 'entry.htmlf' );
	join_file(  'join.htmlf'  );

Usually the _file methods are the ones you want.

In the join template, you can either just use the existing tags stored in the
object (which is recommended, since usually you don't care what's in the join
template, if you use it at all) or you can supply your own set of tags with the
join_tags() method, which works just like the tags() method.

The complicated part is the callback.  You must supply a subroutine
to generate the tags for each entry.  It's easier than it seems.

The callback is set with the entry_callback() method.  It is called
for each entry in the list, and its sole argument will be the item
we are looking at from the list, a single scalar.  It must return a
hash-ref of name/action pairs of the tags that appear in the
entry template.  A callback might look like this:

	entry_callback( sub {
		my( $person ) = @_;   # $person is assumed to be a hash-ref

		my $tags= +{ NAME => $person->name,
		             CITY => $person->city };

		return $tags;
	} );

You then have to make the list from this stuff, using the parse_list() or
parse_list_files() methods.  These return the full parsed list as a string.
For example:

	$list = parse_list;

or more often you'll be wanting to put that into another tag to put into your
full-page template, like:

	add_tag( LIST => parse_list_files );

That example above might produce a parsed list looking like:

	<P>Name:  Jacob</P><P>City:  Norwich</P>
	<P>Name:  Matisse</P><P>City:  San Francisco</P>
	<P>Name:  Alejandro</P><P>City:  San Francisco</P>

which you could then insert into your output.

If you're lazy and each item in your list is either a hashref or can easily
be turned into one (for example, by returning a row from a database as a
hashref) you may just want to return it directly, like this:

	entry_callback( sub {
		( $userid ) = @_;
		$sth = $dbh->prepare( <<"EOS" );
	SELECT * FROM users WHERE userid = "$userid"
	EOS
		$sth->execute;
		return $sth->fetchrow_hashref;
	} );

or more even more lazily, something like this:

	$sth = $dbh->prepare( <<"EOS" );
	SELECT * FROM users
	EOS
	$sth->execute;
	while ( $user = $sth->fetchrow_hashref ) {
		push @users, $user;
	}
	list( @users );
	entry_callback( sub { return $_[ 0 ] } );

Isn't that easy?  What's even easier is that the default value for
entry_callback() is C<sub { return $_[ 0 ] }>, so if your list is a list
of hashrefs, you don't even need to touch it.

=head1 WHICH INTERFACE?

You have a choice when using this module.  You may either use an
object-oriented interface, where you create new instances of
Text::TagTemplate objects and call methods on them, or you may use the
conventional interface, where you import these methods into your namespace and
call them without an object reference.  This is very similar to the way the CGI
module does things.  I recommend the latter method, because the other forces
you to do a lot of object referencing that isn't particularly clear to read.
You might need to use it if you want multiple objects or you are concerned
about namespace conflicts.  You'll also want to use the object interface
if you're running under mod_perl, because mod_perl uses a global to
store the template object, and it won't get deallocated between handler calls.

For the OO interface, just use:

	use Text::TagTemplate;
	my $parser = new Text::TagTemplate;

For the conventional interface, use:

	use Text::TagTemplate qw( :standard );

and you'll get all the commonly-used methods automatically imported.  If you
want the more obscure configuration methods, you can have them too with:

	use Text::TagTemplate qw( :standard :config );

The examples given here all use the conventional interface, for clarity.  The
OO interface would look like:

	$parser = new Text::TagTemplate;
	$parser->template_file( 'default.htmlt' );
	$parser->parse;

=cut

#===============================================================================
# P U B L I C   F U N C T I O N S
#===============================================================================

=head1 PER-METHOD DOCUMENTATION

The following are the public methods provided by B<Text::TagTemplate>.

=cut

#-------------------------------------------------------------------------------

=head1 B<new()> or new( I<%tags> ) or new( I<\%tags> )

Instantiate a new template object.
Optionally take a hash or hash-ref of tags to add initially.

  my $parser = Text::TagTemplate->new();
  my $parser = Text::TagTemplate->new( %tags );
  my $parser = Text::TagTemplate->new( \%tags );

=cut

sub new
{
	my( $class, @tags ) = @_;
	my $self = +{};
	$class = ref( $class ) || $class;

	$self->{ AUTO_CAP       } = 1;
	$self->{ UNKNOWN_ACTION } = 'CONFESS';

	$self->{ TAGS           } = +{};
	$self->{ STRING         } = '';
	$self->{ FILE           } = undef;
	$self->{ LIST           } = [];
	$self->{ ENTRY_STRING   } = '';
	$self->{ ENTRY_FILE     } = undef;
	$self->{ ENTRY_CALLBACK } = sub { return $_[ 0 ] };
	$self->{ JOIN_STRING    } = '';
	$self->{ JOIN_FILE      } = undef;
	$self->{ JOIN_TAGS      } = undef;
	$self->{ TAG_START      } = '<#';
	$self->{ TAG_CONTENTS   } = '[^<>]*';
	$self->{ TAG_END        } = '>';

	bless $self, $class;

	$self->add_tags( @tags ) if @tags;
	return $self;
}


=head1 Setting the Tag Pattern

The default pattern for tags is C<E<lt>#TAGNAME attributes E<gt>>.
This is implemented internally as a regular expression:
C<(?-xism:E<lt>#([^E<lt>E<gt>]*))> made up from three pieces which you may
override using the next three methods I<tag_start()>, I<tag_end()>,
and I<tag_contents()>.

For example, you might want to use a pattern for tags that does I<not> look
like HTML tags, perhaps to avoid confusing some HTML parsing tool.

Examples;

To use tags like this:

   /* TAGNAME attribute=value attribute2=value */

Do this:

   tag_start('/\*');       # you must escape the * character
   tag_contents('[^*]*');  # * inside [] does not need escaping
   tag_end('\*/');         # escape the *

=cut

#-------------------------------------------------------------------------------

=over 4

=item C<tag_start()> or C<tag_start( $pattern )>

Set and or get the pattern used to find the start of tags.

With no arguments returns the current value. The default value is C<E<lt>#>.

If an argument is supplied it is used to replace the current value.
Returns the new value.

See also tag_contents() and tag_end(), below.

=cut

sub tag_start {
    my($self,$pattern) = _self_or_default @_;
    if ($pattern) {
        $self->{TAG_START} = $pattern;
    }
    return $self->{TAG_START};
}

#-------------------------------------------------------------------------------

=item C<tag_contents()> or C<tag_contents( $pattern )>

Set and or get the pattern used to find the content of tags, that is
the stuff in between the I<tag_start> and the I<tag_end>.

With no arguments returns the current value. The default value is C<[^E<lt>E<gt>]*>.

If an argument is supplied it is used to replace the current value.
Returns the new value.


The pattern should be something that matches any number of characters that
are not the end of the tag. (See I<tag_end>, below.) Typ[ically you should
use an atom followed by *. In the defaul pattern  C<[^E<lt>E<gt>]*> the
C<[^E<lt>E<gt>]> defines a "character class" consisting of anything I<except>
E<lt> or E<gt>. The C<*> means "zero-or-more" of the preceding thing.

Examples:

Set the contents pattern to match anything that is not C<-->

=cut

sub tag_contents {
    my($self,$pattern) = _self_or_default @_;
    if ($pattern) {
        $self->{TAG_CONTENTS} = $pattern;
    }
    return $self->{TAG_CONTENTS};
}

#-------------------------------------------------------------------------------

=item C<tag_end()> or C<tag_end( $pattern )>

Set and or get the pattern used to find the end of tags.

With no arguments returns the current value. The default value is C<E<lt>>.

If an argument is supplied it is used to replace the current value.
Returns the new value.

=cut

sub tag_end {
    my($self,$pattern) = _self_or_default @_;
    if ($pattern) {
        $self->{TAG_END} = $pattern;
    }
    return $self->{TAG_END};
}

#-------------------------------------------------------------------------------

=item C<tag_patten()>

Returns the complete pattern used to find tags. The value is returned as a
quoted regular expression. The default value is C<(?-xism:E<lt>#([^E<lt>E<gt>]*))>.

Equivalant to:

 $start    = tag_start();
 $contents = tag_contents();
 $end      = tag_end();
 return qr/$start($contents)$end/;

=cut

sub tag_pattern {
    my ($self) = _self_or_default @_;
    return qr/$self->{TAG_START}($self->{TAG_CONTENTS})$self->{TAG_END}/;
}

#-------------------------------------------------------------------------------

=item C<auto_cap()> or C<auto_cap( $new_value )>

Returns whether tag names will automatically be capitalised, and if a value
is supplied sets the auto-capitalisation to this value first.  Default is
1; changing it is not recommended but hey go ahead and ignore me anyway,
what do I know?  Setting it to false will make tag names case-sensitive and
you probably don't want that.

=cut

sub auto_cap
{
	my( $self, $auto_cap ) = _self_or_default @_;
	$self->{ AUTO_CAP } = $auto_cap if defined $auto_cap;
	return $self->{ AUTO_CAP };
}

#-------------------------------------------------------------------------------

=item C<unknown_action()> or C<unknown_action( $action )>

Returns what to do with unknown tags.  If a value is supplied sets the action
to this value first.  If the action is the special value 'CONFESS' then it will
confess() at that point. This is the default.  If the action is the special
value 'IGNORE' then unknown tags will be ignored by the module, and
will appear unchanged in the parsed output.  If the special value 'CLUCK' is
used then the the unknown tags will be replaced by warning text and logged with a  cluck()  call. (See L<Carp> for cluck() and confess() - these are
like warn() and (die(), but with a stack trace.)
Other special values may be supplied later, so if scalar
actions are require it is suggested that a scalar ref be supplied, where
these special actions will not be taken no matter what the value.

=cut

sub unknown_action
{
	my( $self, $unknown_action ) = _self_or_default @_;
	$self->{ UNKNOWN_ACTION } = $unknown_action if defined $unknown_action;
	return $self->{ UNKNOWN_ACTION };
}

#-------------------------------------------------------------------------------

=item C<tags()> or C<tags( %tags )> or C<tags( \%tags )>

Returns the contents of the tags as a hash-ref of tag/action pairs.
If tags are supplied as a hash or hashref, it first sets the contents to
these tags, clearing all previous tags.

=cut

sub tags
{
	my( $self, @tags ) = _self_or_default @_;
	if ( @tags ) {
		$self->clear_tags;
		$self->add_tags( @tags );
	}
	return $self->{ TAGS };
}

#-------------------------------------------------------------------------------

=item C<add_tag( $tag_name, $tag_action )>

Adds a new tag.  Takes a tag name and the tag action.

=cut

# *** DEBUG *** Probably redundant.

sub add_tag
{
	my( $self, $name, $action ) = _self_or_default @_;
	$name = uc $name if $self->{ AUTO_CAP };
	$self->{ TAGS }->{ $name } = $action;
	return 1;
}

sub list_tag
{
	my( $self, $list, $entry_callback, @join_tags )
	   = _self_or_default @_;

	return sub {
		my %params = %{ $_[ 0 ] };
		my( $entry_string, $join_string );
		if ( exists $params{ ENTRY_STRING } ) {
			$entry_string = $params{ ENTRY_STRING };
		} elsif ( exists $params{ ENTRY_FILE } ) {
			$entry_string = _get_file $params{ ENTRY_FILE };
		} else {
			$entry_string = '';
		}
		if ( exists $params{ JOIN_STRING } ) {
			$join_string = $params{ JOIN_STRING };
		} elsif ( exists $params{ JOIN_FILE } ) {
			$join_string = _get_file $params{ JOIN_FILE };
		} else {
			$join_string = '';
		}
		return $self->parse_list( $list, $entry_string, $join_string,
		                          $entry_callback, @join_tags );
	};
}
#-------------------------------------------------------------------------------

=item C<add_list_tag( $tag_name, \@list, $entry_callback, @join_tags )>

Add a tag that will build a parsed list, allowing the person using the tag to
supply the filename of the entry and join templates, or to supply the strings
directly in tag parameters (which is currently annoying given the way they need
to be escaped).  The tag will take parameters for ENTRY_STRING, ENTRY_FILE,
JOIN_STRING or JOIN_FILE.

No checking is currently performed on the filenames given.  This shouldn't be a security problem unless you're allowing untrusted users to write your templates for you, which mean it's a bug that I need to fix (since I want untrusted users to be able to write templates under some circumstnaces).

=cut

sub add_list_tag
{
	my( $self, $tag_name, $list, $entry_callback, @join_tags )
	   = _self_or_default @_;

	$self->add_tag(
		$tag_name=> $self->list_tag( $list, $entry_callback,
		                             @join_tags )
	);
	return 1;
}

#-------------------------------------------------------------------------------

=item C<add_tags( %tags )> or C<add_tags( \%tags )>

Adds a bunch of tags.  Takes a hash or hash-ref of tag/action pairs.

=cut

sub add_tags
{
	my( $self, @tags ) = _self_or_default @_;
	my $tags;
	if ( @tags > 1 ) {
		%$tags = @tags;
	} elsif ( @tags == 1 ) {
		$tags = $tags[ 0 ];
	}
	foreach my $name ( keys %$tags ) {
		my $uc_name = $self->{ AUTO_CAP } ? uc $name : $name;
		$self->{ TAGS }->{ $uc_name } = $tags->{ $name };
	}
	return 1;
}

#-------------------------------------------------------------------------------

=item C<delete_tag( $name )>

Delete a tag by name.

=cut

sub delete_tag
{
	my( $self, $name ) = _self_or_default @_;
	my $uc_name = $self->{ AUTO_CAP } ? uc $name : $name;
	delete $self->{ TAGS }->{ $uc_name };
	return 1;
}

#-------------------------------------------------------------------------------

=item C<clear_tags()>

Clears all existing tags.

=cut

sub clear_tags
{
	my( $self ) = _self_or_default @_;
	$self->{ TAGS } = +{};
	return 1;
}

#-------------------------------------------------------------------------------

=item C<list()> or C<list( @list )>

Returns (and sets if supplied) the list of values to be used in parse_list()
or parse_list_files() calls. 

=cut

sub list
{
	my( $self, @list ) = _self_or_default @_;
	$self->{ LIST } = \@list if @list;
	return @{ $self->{ LIST } };
}

#-------------------------------------------------------------------------------

=item C<template_string()> or C<template_string( $string )>

Returns (and sets if supplied) the default template string for parse().

=cut

sub template_string
{
	my( $self, $template_string ) = _self_or_default @_;
	$self->{ STRING } = $template_string if defined $template_string;
	return $self->{ STRING };
}

#-------------------------------------------------------------------------------

=item C<template_file()> or C<template_file( $file )>

Returns (and sets if supplied) the default template file for parse_file().

=cut

sub template_file
{
	my( $self, $template_file ) = _self_or_default @_;
	$self->{ FILE } = $template_file if defined $template_file;
	return $self->{ FILE };
}

#-------------------------------------------------------------------------------

=item C<entry_string()> or C<entry_string( $string )>

Returns (and sets if supplied) the entry string to be used in parse_list()
calls.

=cut

sub entry_string
{
	my( $self, $entry_string ) = _self_or_default @_;
	$self->{ ENTRY_STRING } = $entry_string if defined $entry_string;
	return $self->{ ENTRY_STRING };
}

#-------------------------------------------------------------------------------

=item C<entry_file()> or C<entry_file( $file )>

Returns (and sets if supplied) the entry file to be used in
parse_list_files() calls.

=cut

sub entry_file
{
	my( $self, $entry_file ) = _self_or_default @_;
	$self->{ ENTRY_FILE } = $entry_file if defined $entry_file;
	return $self->{ ENTRY_FILE };
}

#-------------------------------------------------------------------------------

=item C<entry_callback()> or C<entry_callback( $callback )>

Returns (and sets if supplied) the callback sub to be used in parse_list()
or parse_list_files() calls.  If you don't set this, the default is just to
return the item passed in, which will only work if the item is a hashref
suitable for use as a set of tags.

=cut

sub entry_callback
{
	my( $self, $entry_callback ) = _self_or_default @_;
	$self->{ ENTRY_CALLBACK } = $entry_callback if defined $entry_callback;
	return $self->{ ENTRY_CALLBACK };
}

#-------------------------------------------------------------------------------

=item C<join_string()> or C<join_string( $string )>

Returns (and sets if supplied) the join string to be used in parse_list()
calls.

=cut

sub join_string
{
	my( $self, $join_string ) = _self_or_default @_;
	$self->{ JOIN_STRING } = $join_string if defined $join_string;
	return $self->{ JOIN_STRING };
}

#-------------------------------------------------------------------------------

=item C<join_file()> or C<join_file( $file )>

Returns (and sets if supplied) the join file to be used in
parse_list_files() calls.

=cut

sub join_file
{
	my( $self, $join_file ) = _self_or_default @_;
	$self->{ JOIN_FILE } = $join_file if defined $join_file;
	return $self->{ JOIN_FILE };
}

#-------------------------------------------------------------------------------

=item C<join_tags()> or C<join_tags( %tags )> or C<join_tags( \%tags )>

Returns (and sets if supplied) the join tags to be used in parse_list() and
parse_list_files() calls.

=cut

sub join_tags
{
	my( $self, @join_tags ) = _self_or_default @_;
	my $join_tags;
	if ( @join_tags > 1 ) {
		%$join_tags = @join_tags;
	} elsif ( @join_tags == 1 ) {
		$join_tags = $join_tags[ 0 ];
	}
	if ( defined $join_tags ) {
		$self->{ JOIN_TAGS } = +{};
		foreach my $name ( keys %$join_tags ) {
			my $uc_name = $self->{ AUTO_CAP } ? uc $name : $name;
			$self->{ JOIN_TAGS }->{ $uc_name }
			   = $join_tags->{ $name };
		}
	}
	return $self->{ JOIN_TAGS };
}

#-------------------------------------------------------------------------------

=item C<parse()> or C<parse( $string )> or C<parse( $string, %tags )> or C<parse( $string, \%tags )>

Parse a string, either the default string, or a string supplied.
Returns the string.  Can optionally also take the tags hash or hash-ref directly
as well.

=cut

sub parse
{
	my( $self, $string, @tags ) = _self_or_default @_;
	$string = defined $string ? $string : $self->{ STRING };
	my $tags;
	if ( @tags ) {
		if ( @tags > 1 ) {
			%$tags = @tags;
		} else {
			$tags = $tags[ 0 ];
		}
		my $uc_tags = +{};
		foreach my $name ( keys %$tags ) {
			my $uc_name = $self->{ AUTO_CAP } ? uc $name : $name;
			$uc_tags->{ $uc_name } = $tags->{ $name };
		}
		$tags = $uc_tags;
	} else {
		$tags = $self->{ TAGS };
	}

	# Loop until we have replaced all the tags.
	    my $regex = $self->tag_pattern();   
        while ( $string =~ /$regex/g ) {
                my $contents = $1;
		my $q_contents = quotemeta $contents;
		my $o_contents = $contents; # preserve in case we're ignoring.
		# Remove leading and trailing whitespace.
		$contents =~ s/^\s+//;
		$contents =~ s/\s+$//;
		# Remove whitespace in quoted values.
		$contents =~ s|"([^"]*)"|
			my $value = $1;
			$value =~ s/ /\&#032;/g;
			$value =~ s/\t/\&#009;/g;
			$value =~ s/\n/\&#010;/g;
			$value =~ s/\r/\&#013;/g;
			$value =~ s/=/\&#061;/g;
			$value;
		|egm;
		# Remove whitespace between parameters/equals-signs/values.
                $contents =~ s/\s+=\s+/=/g;

                my %params = ();
		# Chop up the contents into the tag name and the params.
                my( $tag, @param_pairs ) = split ' ', $contents;
                foreach my $param_pair ( @param_pairs ) {
			# Split it; value is optional.
                        my( $name, $value ) = split /=/, $param_pair;
                        $value = defined $value ? $value : '';
			# Dequote the values.
			# *** DEBUG ***
			# Should use full de-HTML-escape here.
                        $value =~ s/&lt;/</gi;
                        $value =~ s/&gt;/>/gi;
                        $value =~ s/&quot;/"/gi;
			$value =~ s/&#032;/ /g;
			$value =~ s/&#009;/\t/g;
			$value =~ s/&#010;/\n/g;
			$value =~ s/&#013;/\r/g;
			$value =~ s/&#061;/=/g;
                        $value =~ s/&amp;/&/gi;
			$name = uc $name if $self->{ AUTO_CAP };
                        $params{ $name } = $value;
                }

		my $uc_tag = uc $tag;
		my $action = $tags->{ $uc_tag };
		unless ( exists $tags->{ $uc_tag } ) {
			if (      $self->{ UNKNOWN_ACTION } eq 'CONFESS'    ) {
                		confess "unknown tag: $tag";
			} elsif ( $self->{ UNKNOWN_ACTION } eq 'CLUCK'   ) {
				$action = "unknown tag: $tag";
				cluck "unknown tag: $tag";
			} elsif ( $self->{ UNKNOWN_ACTION } eq 'IGNORE' ) {
				$string
				   =~ s/$self->{TAG_START}$q_contents$self->{TAG_END}/\000#$o_contents\000/;
			} else {
				# let sub refs know which tags this is.
				$params{ TAG } = $tag;
				$action = $self->{ UNKNOWN_ACTION };
			}
		}
		# Undefined actions are assumed to mean just use ''.
                $action  = '' unless defined $action;

                my $rep;
                my $type = ref $action;
                unless ( $type ) {
			# Tag scalar replacement.
                        $rep = $action;
                } else {
                        if      ( $type eq 'SCALAR' ) {
				# Substitute scalar-refs as strings.
                                $rep = $$action;
                        } elsif ( $type eq 'CODE'   ) {
				# Code-refs are callbacks with the params.
                                $rep = &$action( \%params );
                        } else {
				# Bad action ref-type; just use ''.
				$rep = '';
                        }
                }

		# Now we might want to HTML-escape or URL-escape the text.
		if ( exists $params{ HTMLESC } ) {
			$rep = _htmlesc $rep;
		} elsif ( exists $params{ URLESC } ) {
			$rep = _urlesc $rep;
		}
		if ( exists $params{ SELECTEDIF } ) {
			if ( $rep eq $params{ VALUE } ) {
				$rep = 'SELECTED';
			} else {
				$rep = '';
			}
		} elsif ( exists $params{ CHECKEDIF } ) {
			if ( $rep eq $params{ VALUE } ) {
				$rep = 'CHECKED';
			} else {
				$rep = '';
			}
		}

		# Substitute in the string.
                {
                    no warnings; # Avoid stoopid warnings in case $rep is empty
                    $string =~ s/$self->{TAG_START}$q_contents$self->{TAG_END}/$rep/;
                }
        }

	if ( $self->{ UNKNOWN_ACTION } eq 'IGNORE' ) {
		$string =~ s/\000#([^\000]*)\000/$self->{TAG_START}$1$self->{TAG_END}/g;
	}

        return $string;
}

#-------------------------------------------------------------------------------

=item C<parse_file()> or C<parse_file( $file )> or C<parse_file( $file, %tags )> or C<parse_file( $file, \%tags )>

Parses a file, either the default file or the supplied filename.
Returns the parsed file.  Dies if the file cannot be read.  Can optionally
take the tags hash or hash-ref directly.

=cut

sub parse_file
{
	my( $self, $file, @tags ) = _self_or_default @_;
	$file = defined $file ? $file : $self->{ FILE };
	my $string = _get_file( $file );
	$string = $self->parse( $string, @tags );
	return $string;
}

#-------------------------------------------------------------------------------

=item C<parse_list()> or C<parse_list( \@list )>

=item or C<parse_list( \@list, $entry_string, $join_string )>

=item or C<parse_list( \@list, $entry_string, $join_string, $entry_callback, \%join_tags )>

Makes a string from a list of entries, either the default or a supplied list.

At least one template string is needed: the one  to use for each entry,
and another is optional, to be used to join the entries.

A callback subroutine must be supplied
using entry_callback(), which takes the entry value from the list and must
return a hash-ref of tags to be interpolated in the entry string.  This will
be called for each entry in the list.  You can also supply a set of
tags for the join string using join_tags(), but by default the main tags will
be used in that string.

You can also optionally supply the strings for the entry and join template.
Otherwise the strings set previously (with entry_string() and join_string() )
will be used.

Finally, you can also supply the callback sub and join tags directly if you
want.

=cut

sub parse_list
{
	my( $self, $list, $entry_string, $join_string,
	    $entry_callback, @join_tags ) = _self_or_default @_;
	$list           = defined $list           ? $list
	                                          : $self->{ LIST };
	$entry_string   = defined $entry_string   ? $entry_string
	                                          : $self->{ ENTRY_STRING   };
	$join_string    = defined $join_string    ? $join_string
	                                          : $self->{ JOIN_STRING    };
	$entry_callback = defined $entry_callback ? $entry_callback
	                                          : $self->{ ENTRY_CALLBACK };
	my $join_tags;
	if ( @join_tags > 1 ) {
		%$join_tags = @join_tags;
	} elsif ( @join_tags == 1 ) {
		$join_tags = $join_tags[ 0 ];
	} else {
		$join_tags = $self->{ JOIN_TAGS };
	}

	# Call the callback for each entry and parse the entry string.
        my @element_strings = ();
        foreach my $element ( @$list ) {
                my @tags    = &$entry_callback( $element );
                my $string = $self->parse( $entry_string, @tags );
                push @element_strings, $string;
        }

	# Parse the join string, with join tags (if any) or the default tags.
        $join_string = $self->parse( $join_string, @join_tags );

	# Join it all together and return it.
        my $string = join $join_string, @element_strings;
        return @element_strings ? $string : '';
}

#-------------------------------------------------------------------------------

=item C<parse_list_files()> or C<parse_list_files( \@list )>

=item or C<parse_list_files( \@list, $entry_file, $join_file )>

=item or C<parse_list_files( \@list, $entry_file, $join_file, $entry_callback )>

=item or C<parse_list_files( \@list, $entry_file, $join_file, $entry_callback, %join_tags )>	

=item or C<parse_list_files( \@list, $entry_file, $join_file, $entry_callback, \%join_tags )>

Exactly as parse_list(), but using filenames, not strings.

=cut

sub parse_list_files
{
	my( $self, $list, $entry_file, $join_file, $entry_callback, @join_tags )
	   = _self_or_default @_;
	$list       = defined $list       ? $list
	                                  : $self->{ LIST };
	$entry_file = defined $entry_file ? $entry_file
	                                  : $self->{ ENTRY_FILE };
	$join_file  = defined $join_file  ? $join_file
	                                  : $self->{ JOIN_FILE  };
	my $entry_string = defined $entry_file ? _get_file( $entry_file )
	                                       : '';
	my $join_string  = defined $join_file  ? _get_file( $join_file  )
	                                       : '';

	my @params = ( $list, $entry_string, $join_string );
	push @params, $entry_callback if defined $entry_callback;
	push @params, @join_tags;
	return $self->parse_list( @params );
}

1;

#===============================================================================
# P E R L D O C
#===============================================================================

__END__

=back

=head1 COPYRIGHT

Copyright (C) 2000 SF Interactive, Inc.  All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHOR

Jacob Davies

	<jacob@well.com>

=head1 MAINTAINER

Matisse Enzer

	<matisse@matisse.net>

=head1 SEE ALSO

The README file supplied with the distribution, and the example/ subdirectory
there, which contains a full CGI application using this module.

The CGI module documentation.

Apache::TagRegistry(1)

Carp(3)
