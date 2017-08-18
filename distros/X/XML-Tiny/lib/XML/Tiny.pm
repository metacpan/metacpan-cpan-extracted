package XML::Tiny;

use strict;

require Exporter;

use vars qw($VERSION @EXPORT_OK @ISA);

$VERSION = '2.07';
@EXPORT_OK = qw(parsefile);
@ISA = qw(Exporter);

# localising prevents the warningness leaking out of this module
local $^W = 1;    # can't use warnings as that's a 5.6-ism

=head1 NAME

XML::Tiny - simple lightweight parser for a subset of XML

=head1 DESCRIPTION

XML::Tiny is a simple lightweight parser for a subset of XML

=head1 SYNOPSIS

    use XML::Tiny qw(parsefile);
    open($xmlfile, 'something.xml);
    my $document = parsefile($xmlfile);

This will leave C<$document> looking something like this:

    [
        {
            type   => 'e',
            attrib => { ... },
            name   => 'rootelementname',
            content => [
                ...
                more elements and text content
                ...
           ]
        }
    ]

=head1 FUNCTIONS

The C<parsefile> function is optionally exported.  By default nothing is
exported.  There is no objecty interface.

=head2 parsefile

This takes at least one parameter, optionally more.  The compulsory
parameter may be:

=over 4

=item a filename

in which case the file is read and parsed;

=item a string of XML

in which case it is read and parsed.  How do we tell if we've got a string
or a filename?  If it begins with C<_TINY_XML_STRING_> then it's
a string.  That prefix is, of course, ignored when it comes to actually
parsing the data.  This is intended primarily for use by wrappers which
want to retain compatibility with Ye Aunciente Perl.  Normal users who want
to pass in a string would be expected to use L<IO::Scalar>.

=item a glob-ref or IO::Handle object

in which case again, the file is read and parsed.

=back

The former case is for compatibility with older perls, but makes no
attempt to properly deal with character sets.  If you open a file in a
character-set-friendly way and then pass in a handle / object, then the
method should Do The Right Thing as it only ever works with character
data.

The remaining parameters are a list of key/value pairs to make a hash of
options:

=over 4

=item fatal_declarations

If set to true, E<lt>!ENTITY...E<gt> and E<lt>!DOCTYPE...E<gt> declarations
in the document
are fatal errors - otherwise they are *ignored*.

=item no_entity_parsing

If set to true, the five built-in entities are passed through unparsed.
Note that special characters in CDATA and attributes may have been turned
into C<&amp;>, C<&lt;> and friends.

=item strict_entity_parsing

If set to true, any unrecognised entities (ie, those outside the core five
plus numeric entities) cause a fatal error.  If you set both this and
C<no_entity_parsing> (but why would you do that?) then the latter takes
precedence.

Obviously, if you want to maximise compliance with the XML spec, you should
turn on fatal_declarations and strict_entity_parsing.

=back

The function returns a structure describing the document.  This contains
one or more nodes, each being either an 'element' node or a 'text' mode.
The structure is an arrayref which contains a single 'element' node which
represents the document entity.  The arrayref is redundant, but exists for
compatibility with L<XML::Parser::EasyTree>.

Element nodes are hashrefs with the following keys:

=over 4

=item type

The node's type, represented by the letter 'e'.

=item name

The element's name.

=item attrib

A hashref containing the element's attributes, as key/value pairs where
the key is the attribute name.

=item content

An arrayref of the element's contents.  The array's contents is a list of
nodes, in the order they were encountered in the document.

=back

Text nodes are hashrefs with the following keys:

=over 4

=item type

The node's type, represented by the letter 't'.

=item content

A scalar piece of text.

=back

If you prefer a DOMmish interface, then look at L<XML::Tiny::DOM> on the CPAN.

=cut

my %regexps = (
    name => '[:_a-z][\\w:\\.-]*'
);

my $strict_entity_parsing; # mmm, global. don't worry, parsefile sets it
                           # explicitly every time

sub parsefile {
    my($arg, %params) = @_;
    my($file, $elem) = ('', { content => [] });
    local $/; # sluuuuurp

    $strict_entity_parsing = $params{strict_entity_parsing};

    if(ref($arg) eq '') { # we were passed a filename or a string
        if($arg =~ /^_TINY_XML_STRING_/) { # it's a string
            $file = substr($arg, 17);
        } else {
            local *FH;
            open(FH, $arg) || die(__PACKAGE__."::parsefile: Can't open $arg\n");
            $file = <FH>;
            close(FH);
        }
    } else { $file = <$arg>; }

    # strip any BOM
    $file =~ s/^(\xff\xfe(\x00\x00)?|(\x00\x00)?\xfe\xff|\xef\xbb\xbf)//;

    die("No elements\n") if (!defined($file) || $file =~ /^\s*$/);

    # illegal low-ASCII chars
    die("Not well-formed (Illegal low-ASCII chars found)\n") if($file =~ /[\x00-\x08\x0b\x0c\x0e-\x1f]/);

    # turn CDATA into PCDATA
    $file =~ s{<!\[CDATA\[(.*?)]]>}{
        $_ = $1.chr(0);          # this makes sure that empty CDATAs become
        s/([&<>'"])/             # the empty string and aren't just thrown away.
            $1 eq '&' ? '&amp;'  :
            $1 eq '<' ? '&lt;'   :
            $1 eq '"' ? '&quot;' :
            $1 eq "'" ? '&apos;' :
                        '&gt;'
        /eg;
        $_;
    }egs;

    die("Not well-formed (CDATA not delimited or bad comment)\n") if(
        $file =~ /]]>/ ||                          # ]]> not delimiting CDATA
        $file =~ /<!--(.*?)--->/s ||               # ---> can't end a comment
        grep { $_ && /--/ } ($file =~ /^\s+|<!--(.*?)-->|\s+$/gs) # -- in comm
    );

    # strip leading/trailing whitespace and comments (which don't nest - phew!)
    $file =~ s/^\s+|<!--(.*?)-->|\s+$//gs;
    
    # turn quoted > in attribs into &gt;
    # double- and single-quoted attrib values get done seperately
    while($file =~ s/($regexps{name}\s*=\s*"[^"]*)>([^"]*")/$1&gt;$2/gsi) {}
    while($file =~ s/($regexps{name}\s*=\s*'[^']*)>([^']*')/$1&gt;$2/gsi) {}

    if($params{fatal_declarations} && $file =~ /<!(ENTITY|DOCTYPE)/) {
        die("I can't handle this document\n");
    }

    # ignore empty tokens/whitespace tokens
    foreach my $token (grep { length && $_ !~ /^\s+$/ }
      split(/(<[^>]+>)/, $file)) {
        if(
          $token =~ /<\?$regexps{name}.*?\?>/is ||  # PI
          $token =~ /^<!(ENTITY|DOCTYPE)/i          # entity/doctype decl
        ) {
            next;
        } elsif($token =~ m!^</($regexps{name})\s*>!i) {     # close tag
            die("Not well-formed\n\tat $token\n") if($elem->{name} ne $1);
            $elem = delete $elem->{parent};
        } elsif($token =~ /^<$regexps{name}(\s[^>]*)*(\s*\/)?>/is) {   # open tag
            my($tagname, $attribs_raw) = ($token =~ m!<(\S*)(.*?)(\s*/)?>!s);
            # first make attribs into a list so we can spot duplicate keys
            my $attrib  = [
                # do double- and single- quoted attribs seperately
                $attribs_raw =~ /\s($regexps{name})\s*=\s*"([^"]*?)"/gi,
                $attribs_raw =~ /\s($regexps{name})\s*=\s*'([^']*?)'/gi
            ];
            if(@{$attrib} == 2 * keys %{{@{$attrib}}}) {
                $attrib = { @{$attrib} }
            } else { die("Not well-formed - duplicate attribute\n"); }
            
            # now trash any attribs that we *did* manage to parse and see
            # if there's anything left
            $attribs_raw =~ s/\s($regexps{name})\s*=\s*"([^"]*?)"//gi;
            $attribs_raw =~ s/\s($regexps{name})\s*=\s*'([^']*?)'//gi;
            die("Not well-formed\n$attribs_raw") if($attribs_raw =~ /\S/ || grep { /</ } values %{$attrib});

            unless($params{no_entity_parsing}) {
                foreach my $key (keys %{$attrib}) {
                    ($attrib->{$key} = _fixentities($attrib->{$key})) =~ s/\x00//g; # get rid of CDATA marker
                }
            }
            $elem = {
                content => [],
                name => $tagname,
                type => 'e',
                attrib => $attrib,
                parent => $elem
            };
            push @{$elem->{parent}->{content}}, $elem;
            # now handle self-closing tags
            if($token =~ /\s*\/>$/) {
                $elem->{name} =~ s/\/$//;
                $elem = delete $elem->{parent};
            }
        } elsif($token =~ /^</) { # some token taggish thing
            die("I can't handle this document\n\tat $token\n");
        } else {                          # ordinary content
            $token =~ s/\x00//g; # get rid of our CDATA marker
            unless($params{no_entity_parsing}) { $token = _fixentities($token); }
            push @{$elem->{content}}, { content => $token, type => 't' };
        }
    }
    die("Not well-formed (Duplicated parent)\n") if(exists($elem->{parent}));
    die("Junk after end of document\n") if($#{$elem->{content}} > 0);
    die("No elements\n") if(
        $#{$elem->{content}} == -1 || $elem->{content}->[0]->{type} ne 'e'
    );
    return $elem->{content};
}

sub _fixentities {
    my $thingy = shift;

    my $junk = ($strict_entity_parsing) ? '|.*' : '';
    $thingy =~ s/&((#(\d+|x[a-fA-F0-9]+);)|lt;|gt;|quot;|apos;|amp;$junk)/
        $3 ? (
            substr($3, 0, 1) eq 'x' ?     # using a =~ match here clobbers $3
                chr(hex(substr($3, 1))) : # so don't "fix" it!
                chr($3)
        ) :
        $1 eq 'lt;'   ? '<' :
        $1 eq 'gt;'   ? '>' :
        $1 eq 'apos;' ? "'" :
        $1 eq 'quot;' ? '"' :
        $1 eq 'amp;'  ? '&' :
                        die("Illegal ampersand or entity\n\tat $1\n")
    /ge;
    $thingy;
}

=head1 COMPATIBILITY

=head2 With other modules

The C<parsefile> function is so named because it is intended to work in a
similar fashion to L<XML::Parser> with the L<XML::Parser::EasyTree> style.
Instead of saying this:

  use XML::Parser;
  use XML::Parser::EasyTree;
  $XML::Parser::EasyTree::Noempty=1;
  my $p=new XML::Parser(Style=>'EasyTree');
  my $tree=$p->parsefile('something.xml');

you would say:

  use XML::Tiny;
  my $tree = XML::Tiny::parsefile('something.xml');

Any valid document that can be parsed like that using XML::Tiny should
produce identical results if you use the above example of how to use
L<XML::Parser::EasyTree>.

If you find a document where that is not the case, please report it as
a bug.

=head2 With perl 5.004

The module is intended to be fully compatible with every version of perl
back to and including 5.004, and may be compatible with even older
versions of perl 5.

The lack of Unicode and friends in older perls means that XML::Tiny
does nothing with character sets.  If you have a document with a funny
character set, then you will need to open the file in an appropriate
mode using a character-set-friendly perl and pass the resulting file
handle to the module.  BOMs are ignored.

=head2 The subset of XML that we understand

=over 4

=item Element tags and attributes

Including "self-closing" tags like E<lt>pie type = 'steak n kidney' /E<gt>;

=item Comments

Which are ignored;

=item The five "core" entities

ie C<&amp;>, C<&lt;>, C<&gt;>, C<&apos;> and C<&quot;>;

=item Numeric entities

eg C<&#65;> and C<&#x41;>;

=item CDATA

This is simply turned into PCDATA before parsing.  Note how this may interact
with the various entity-handling options;

=back

The following parts of the XML standard are handled incorrectly or not at
all - this is not an exhaustive list:

=over 4

=item Namespaces

While documents that use namespaces will be parsed just fine, there's no
special treatment of them.  Their names are preserved in element and
attribute names like 'rdf:RDF'.

=item DTDs and Schemas

This is not a validating parser.  <!DOCTYPE...> declarations are ignored
if you've not made them fatal.

=item Entities and references

<!ENTITY...> declarations are ignored if you've not made them fatal.
Unrecognised entities are ignored by default, as are naked & characters.
This means that if entity parsing is enabled you won't be able to tell
the difference between C<&amp;nbsp;> and C<&nbsp;>.  If your
document might use any non-core entities then please consider using
the C<no_entity_parsing> option, and then use something like
L<HTML::Entities>.

=item Processing instructions

These are ignored.

=item Whitespace

We do not guarantee to correctly handle leading and trailing whitespace.

=item Character sets

This is not practical with older versions of perl

=back

=head1 PHILOSOPHY and JUSTIFICATION

While feedback from real users about this module has been uniformly
positive and helpful, some people seem to take issue with this module
because it doesn't implement every last jot and tittle of the XML
standard and merely implements a useful subset.  A very useful subset,
as it happens, which can cope with common light-weight XML-ish tasks
such as parsing the results of queries to the Amazon Web Services.
Many, perhaps most, users of XML do not in fact need a full implementation
of the standard, and are understandably reluctant to install large complex
pieces of software which have many dependencies.  In fact, when they
realise what installing and using a full implementation entails, they
quite often don't *want* it.  Another class of users, people
distributing applications, often can not rely on users being able to
install modules from the CPAN, or even having tools like make or a shell
available.  XML::Tiny exists for those people.

=head1 BUGS and FEEDBACK

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<http://rt.cpan.org/> or by email,
and should include the smallest possible chunk of code, along with
any necessary XML data, which demonstrates the bug.  Ideally, this
will be in the form of a file which I can drop in to the module's
test suite.  Please note that such files must work in perl 5.004.

=head1 SEE ALSO

=over 4

=item For more capable XML parsers:

L<XML::Parser>

L<XML::Parser::EasyTree>

L<XML::Tiny::DOM>

=item The requirements for a module to be Tiny

L<http://beta.nntp.perl.org/group/perl.datetime/2007/01/msg6584.html>

=back

=head1 AUTHOR, COPYRIGHT and LICENCE

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

Thanks to David Romano for some compatibility patches for Ye Aunciente Perl;

to Matt Knecht and David Romano for prodding me to support attributes,
and to Matt for providing code to implement it in a quick n dirty minimal
kind of way;

to the people on L<http://use.perl.org/> and elsewhere who have been kind
enough to point out ways it could be improved;

to Sergio Fanchiotti for pointing out a bug in handling self-closing tags,
for reporting another bug that I introduced when fixing the first one,
and for providing a patch to improve error reporting;

to 'Corion' for finding a bug with localised filehandles and providing a fix;

to Diab Jerius for spotting that element and attribute names can begin
with an underscore;

to Nick Dumas for finding a bug when attribs have their quoting character
in CDATA, and providing a patch;

to Mathieu Longtin for pointing out that BOMs exist.

Copyright 2007-2010 David Cantrell E<lt>david@cantrell.org.ukE<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

'<one>zero</one>';
