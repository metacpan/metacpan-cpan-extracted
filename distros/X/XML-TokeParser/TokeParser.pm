=head1 NAME

XML::TokeParser - Simplified interface to XML::Parser

=head1 SYNOPSIS

    use XML::TokeParser;
                                                                    #
    #parse from file
    my $p = XML::TokeParser->new('file.xml')
                                                                    #
    #parse from open handle
    open IN, 'file.xml' or die $!;
    my $p = XML::TokeParser->new( \*IN, Noempty => 1 );
                                                                    #
    #parse literal text
    my $text = '<tag xmlns="http://www.omsdev.com">text</tag>';
    my $p    = XML::TokeParser->new( \$text, Namespaces => 1 );
                                                                    #
    #read next token
    my $token = $p->get_token();
                                                                    #
    #skip to <title> and read text
    $p->get_tag('title');
    $p->get_text();
                                                                    #
    #read text of next <para>, ignoring any internal markup
    $p->get_tag('para');
    $p->get_trimmed_text('/para');
                                                                    #
    #process <para> if interesting text
    $t = $p->get_tag('para');
    $p->begin_saving($t);
    if ( $p->get_trimmed_text('/para') =~ /interesting stuff/ ) {
        $p->restore_saved();
        process_para($p);
    }

=head1 DESCRIPTION

XML::TokeParser provides a procedural ("pull mode") interface to XML::Parser
in much the same way that Gisle Aas' HTML::TokeParser provides a procedural
interface to HTML::Parser.  XML::TokeParser splits its XML input up into
"tokens," each corresponding to an XML::Parser event.

A token is a B<L<bless'd|"XML::TokeParser::Token">> reference to an array whose first element is an event-type 
string and whose last element is the literal text of the XML input that 
generated the event, with intermediate elements varying according to the 
event type.

Each token is an I<object> of type L<XML::TokeParser::Token|"XML::TokeParser::Token">.
Read 
L<"XML::TokeParser::Token"|"XML::TokeParser::Token">
to learn what methods are available for inspecting the token,
and retrieving data from it.

=cut

package XML::TokeParser;

use strict;
use vars qw($VERSION);
use Carp;# qw( carp croak );
use XML::Parser;

$VERSION = '0.05';

=head1 METHODS

=over 4

=item $p = XML::TokeParser->new($input, [options])

Creates a new parser, specifying the input source and any options.  If 
$input is a string, it is the name of the file to parse.  If $input is a 
reference to a string, that string is the actual text to parse.  If $input 
is a reference to a typeglob or an IO::Handle object corresponding to an 
open file or socket, the text read from the handle will be parsed.

Options are name=>value pairs and can be any of the following:

=over 4

=item Namespaces

If set to a true value, namespace processing is enabled.

=item ParseParamEnt

This option is passed on to the underlying XML::Parser object; see that 
module's documentation for details.

=item Noempty

If set to a true value, text tokens consisting of only whitespace (such as 
those created by indentation and line breaks in between tags) will be 
ignored.

=item Latin

If set to a true value, all text other than the literal text elements of 
tokens will be translated into the ISO 8859-1 (Latin-1) character encoding 
rather than the normal UTF-8 encoding.

=item Catalog

The value is the URI of a catalog file used to resolve PUBLIC and SYSTEM 
identifiers.  See XML::Catalog for details.

=back

=cut

sub new {
    my $class  = shift;
    my $source = shift;
    my %args   = ( Noempty => 0, Latin => 0, Catalog => 0, @_ );
    my $self = { output => [], EOF => 0 };
    $self->{noempty} = delete $args{Noempty};
    $self->{latin}   = delete $args{Latin};
    my $catname = delete $args{Catalog};
    my $parser = XML::Parser->new(%args) or croak "$!";
    $parser->setHandlers(
        Start   => \&start,
        End     => \&end,
        Char    => \&char,
        Proc    => \&proc,
        Comment => \&comment
    );

    if ($catname) {
        require XML::Catalog;
        my $catalog = XML::Catalog->new($catname) or croak "$!";
        $parser->setHandlers( ExternEnt => $catalog->get_handler($parser) );
    }
    $self->{parser} = $parser->parse_start( TokeParser => $self ) or croak "$!";
    if ( ref($source) eq 'SCALAR' ) {
        $self->{src}        = $source;
        $self->{src_offset} = 0;
    }
    elsif ( ref($source) =~ /^IO:|^GLOB$/ ) {
        $self->{srcfile} = $source;
    }
    else {
        require IO::File;
        $self->{srcfile} = IO::File->new( $source, 'r' ) or return undef;
        $self->{opened} = 1;
    }
    bless $self, $class;
}

sub DESTROY {
    my $self = shift;
    $self->{srcfile}->close() if $self->{srcfile} && $self->{opened};
    $self->{parser} = undef;
}


=item $token = $p->get_token()

Returns the next token, as an array reference, from the input.  Returns 
undef if there are no remaining tokens.

=cut

sub get_token {
    local $_;
    my $self = shift;
    $self->parsechunks();
    my $token = shift @{ $self->{output} };
    while ($self->{noempty}
        && $token
        && $token->[0] eq 'T'
        && $token->[1] =~ /^\s*$/ )
    {
        $self->parsechunks();
        $token = shift @{ $self->{output} };
    }
    if ( defined $token and exists $self->{savebuff} ) {
        push @{ $self->{savebuff} }, [@$token];
    }

    return() unless defined $token;
    bless $token, 'XML::TokeParser::Token';
}


=item $p->unget_token($token,...)

Pushes tokens back so they will be re-read.  Useful if you've read one or 
more tokens too far.  Correctly handles "partial" tokens returned by 
get_tag(). 

=cut

sub unget_token {
    my $self = shift;
    while ( my $token = pop @_ ) {
        if ( @$token == 4 && ref( $token->[1] ) eq 'HASH' ) {
            $token = [ 'S', @$token ];
        }
        elsif ( @$token == 2 && substr( $token->[0], 0, 1 ) eq '/' ) {
            $token = [ 'E', substr( $token->[0], 1 ), $token->[1] ];
        }
        unshift @{ $self->{output} }, $token;
    }
}


=item $token = $p->get_tag( [$token] )

If no argument given, skips tokens until the next start tag or end tag 
token. If an argument is given, skips tokens until the start tag or end tag 
(if the argument begins with '/') for the named element.  The returned 
token does not include an event type code; its first element is the element 
name, prefixed by a '/' if the token is for an end tag.

=cut

sub get_tag {
    my ( $self, $tag ) = @_;
    my $token;
    while ( $token = $self->get_token() ) {
        my $type = shift @$token;
        next unless $type =~ /[SE]/;
        substr( $token->[0], 0, 0 ) = '/' if $type eq 'E';
        last unless ( defined($tag) && $token->[0] ne $tag );
    }
    $token;
}


=item $text = $p->get_text( [$token] )

If no argument given, returns the text at the current position, or an empty 
string if the next token is not a 'T' token.  If an argument is given, 
gathers up all text between the current position and the specified start or 
end tag, stripping out any intervening tags (much like the way a typical 
Web browser deals with unknown tags).

=cut

sub get_text {
    my ( $self, $tag ) = @_;
    my $text = "";
    my $token;
    while ( $token = $self->get_token() ) {
        my $type = $token->[0];
        if ( $type eq 'T' ) {
            $text .= $token->[1];
        }
        elsif ( $type =~ /[SE]/ ) {
            my $tt = $token->[1];
            $tt = "/$tt" if $type eq 'E';
            last if ( !defined($tag) || $tt eq $tag );
        }
        elsif ( $type eq 'PI' ) {
            last;
        }
    }
    if ($token) {
        $self->unget_token($token);
        pop @{ $self->{savebuff} } if exists $self->{savebuff};
    }
    $text;
}


=item $text = $p->get_trimmed_text( [$token] )

Like get_text(), but deletes any leading or trailing whitespaces and 
collapses multiple whitespace (including newlines) into single spaces.

=cut

sub get_trimmed_text {
    my $self = shift;
    my $text = $self->get_text(@_);
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    $text =~ s/\s+/ /g;
    $text;
}


=item $p->begin_saving( [$token] ) 

Causes subsequent calls to get_token(), get_tag(), get_text(), and 
get_trimmed_text() to save the returned tokens.  In conjunction with 
restore_saved(), allows you to "back up" within a token stream.  If an 
argument is supplied, it is placed at the beginning of the list of saved 
tokens (useful because you often won't know you want to begin saving until 
you've already read the first token you want saved).

=cut

sub begin_saving {
    my $self = shift;
    delete $self->{savebuff} if exists $self->{savebuff};
    $self->{savebuff} = [];
    push @{ $self->{savebuff} }, @_ if @_;
}


=item $p->restore_saved()

Pushes all the tokens saved by begin_saving() back onto the token stream.  
Stops saving tokens.  To cancel saving without backing up, call 
begin_saving() and restore_saved() in succession.

=back

=cut

sub restore_saved {
    my $self = shift;
    if ( exists $self->{savebuff} ) {
        $self->unget_token( @{ $self->{savebuff} } );
        delete $self->{savebuff};
    }
}


=for comment

=cut

sub parsechunks {
    my ($self) = @_;
    my $buf = '';
    while ( ( !@{ $self->{output} } || $self->{output}[-1][0] eq 'T' )
        && !$self->{EOF} )
    {

        #    if (defined($self->{src}) && ($self->{src_offset}<length(${$self->{src}}))) {
        #      $buf=substr(${$self->{src}},$self->{src_offset},4096);
        #      $self->{src_offset}+=4096;
        #    }
        if ( defined( $self->{src} ) ) {
            if ( $self->{src_offset} < length( ${ $self->{src} } ) ) {
                $buf = substr( ${ $self->{src} }, $self->{src_offset}, 4096 );
                $self->{src_offset} += 4096;
            }
        }
        else {
            read( $self->{srcfile}, $buf, 4096 );
        }
        if ( length($buf) == 0 ) {
            $self->{EOF} = 1;
            $self->{parser}->parse_done();
        }
        else {
            $self->{parser}->parse_more($buf);
        }
    }
}


=for comment Start handler

=cut

sub start {
    my ( $parser, $element, @attrs ) = @_;
    my $self = $parser->{TokeParser};
    push @{ $self->{output} },
      [ 'S', $self->nsname($element), {}, [], $parser->original_string() ];
    while (@attrs) {
        my ( $name, $val ) = ( shift @attrs, shift @attrs );
        $name = $self->nsname($name);
        $val  = $self->encode($val);
        $self->{output}[-1][2]{$name} = $val;
        push @{ $self->{output}[-1][3] }, $name;
    }
}


=for comment End handler

=cut

sub end {
    my ( $parser, $element ) = @_;
    my $self = $parser->{TokeParser};
    push @{ $self->{output} },
      [ 'E', $self->nsname($element), $parser->original_string() ];
}


=for comment Char handler

=cut

sub char {
    my ( $parser, $text ) = @_;
    my $self = $parser->{TokeParser};
    $text = $self->encode($text);
    if ( @{ $self->{output} } && $self->{output}[-1][0] eq 'T' ) {
        $self->{output}[-1][1] .= $text;
        $self->{output}[-1][-1] .= $parser->original_string();
    }
    else {
        push @{ $self->{output} }, [ 'T', $text, $parser->original_string() ];
    }
}


=for comment

=cut

sub proc {
    my ( $parser, $target, $value ) = @_;
    my $self = $parser->{TokeParser};
    push @{ $self->{output} },
      [
        "PI",                  $self->encode($target),
        $self->encode($value), $parser->original_string()
      ];
}


=for comment Comment handler

=cut

sub comment {
    my ( $parser, $text ) = @_;
    my $self = $parser->{TokeParser};
    push @{ $self->{output} },
      [ "C", $self->encode($text), $parser->original_string() ];
}


=for comment nsname
figures out the Namespace if Namespaces is on

=cut

sub nsname {
    my ( $self, $name ) = @_;
    my $parser = $self->{parser};
    if ( $parser->{Namespaces} ) {
        my $ns = $parser->namespace($name) || '';
        $name = "{$ns}" . $name;
    }
    return $self->encode($name);
}


=for comment

=cut

sub encode {
    my ( $self, $text ) = @_;
    if ( $self->{latin} ) {
        $text =~ s{([\xc0-\xc3])(.)}{
      my $hi = ord($1);
      my $lo = ord($2);
      chr((($hi & 0x03) <<6) | ($lo & 0x3F))
     }ge;
    }
    $text;
}


package XML::TokeParser::Token;
use strict;

=head2 XML::TokeParser::Token

A token is a blessed array reference,
that you acquire using C<$p-E<gt>get_token> or C<$p-E<gt>get_tag>,
and that might look like:

    ["S",  $tag, $attr, $attrseq, $raw]
    ["E",  $tag, $raw]
    ["T",  $text, $raw]
    ["C",  $text, $raw]
    ["PI", $target, $data, $raw]

If you don't like remembering array indices (you're a real programmer),
you may access the attributes of a token like:

C<$t-E<gt>tag>, C<$t-E<gt>attr>, C<$t-E<gt>attrseq>, C<$t-E<gt>raw>,
C<$t-E<gt>text>, C<$t-E<gt>target>, C<$t-E<gt>data>.

B<****Please note that this may change in the future,>
B<where as there will be 4 token types, XML::TokeParser::Token::StartTag ....>

What kind of token is it?

To find out, inspect your token using any of these is_* methods
(1 == true, 0 == false, d'oh):

=over 4

=item is_text

=item is_comment

=item is_pi which is short for is_process_instruction

=item is_start_tag

=item is_end_tag

=item is_tag

=back

=cut

# test your token, but don't toke
#sub toke                   { croak "Don't toke!!!!"; }

sub is_text                { return 1 if $_[0]->[0] eq 'T';     return 0;}
sub is_comment             { return 1 if $_[0]->[0] eq 'C';     return 0;}
sub is_pi                  { return 1 if $_[0]->[0] eq 'PI';    return 0;}

#sub is_process_instruction { goto &is_pi; }
{
    no strict;
    *is_process_instruction = *is_pi;
}


sub is_start_tag {
    if( $_[0]->[0] eq 'S'
        or ( @{$_[0]} == 4 && ref( $_[0]->[1] ) eq 'HASH' )
    ){
        if(defined $_[1]){
            return 1 if $_[0]->[1] eq $_[1];
        } else {
            return 1;
        }
    }
    return 0;
}

sub is_end_tag {
    if( $_[0]->[0] eq 'E'
        or ( @{$_[0]} == 2 && substr( $_[0]->[0], 0, 1 ) eq '/' )
    ){
        if(defined $_[1]){
            return 1 if $_[0]->[1] eq $_[1];
        } else {
            return 1;
        }
    }
    return 0;
}



sub is_tag {
    if( $_[0]->[0] eq 'S'
        or $_[0]->[0] eq 'E'
        or ( @{$_[0]} == 4 && ref( $_[0]->[1] ) eq 'HASH' )
        or ( @{$_[0]} == 2 && substr( $_[0]->[0], 0, 1 ) eq '/' )
    ){
        if( defined $_[1] ){
            return 1 if $_[0]->[1] eq $_[1];
        } else {
            return 1;
        }
    }
    return 0;
}


=pod

What's that token made of?
To retrieve data from your token, use any of the following methods,
depending on the kind of token you have:

=over 4

=item target

only for process instructions

=cut

sub target  { return $_[0]->[1] if $_[0]->is_pi; }

=item data

only for process instructions

=cut

sub data    { return $_[0]->[2] if $_[0]->is_pi; }

=item raw

for all tokens

=cut

sub raw     { return $_[0]->[-1]; }


=item attr

only for start tags, returns a hashref ( C<print "#link ", >C<$t-E<gt>attr>C<-E<gt>{href}> ).

=cut

#sub attr    { return $_[0]->[2] if $_[0]->is_start_tag(); }
sub attr    { return $_[0]->[-3] if $_[0]->is_start_tag(); }

=item my $attrseq = $t->attrseq

only for start tags, returns an array ref of the keys found in C<$t-E<gt>attr>
in the order they originally appeared in.

=cut

#sub attrseq { return $_[0]->[3] if $_[0]->is_start_tag(); }
sub attrseq { return $_[0]->[-2] if $_[0]->is_start_tag(); }

#for S|E


=item my $tagname = $t->tag

only for tags ( C<print "opening ", >C<$t-E<gt>tag>C< if >C<$t-E<gt>is_start_tag> ).

=cut

sub tag     { return $_[0]->[1] if $_[0]->is_tag; }

=item my $text = $token->text

only for tokens of type text and comment 

=back

=cut

sub text    { return $_[0]->[1] if $_[0]->is_text or $_[0]->is_comment; }

1;


=pod

Here's more detailed info about the tokens.

=over 4

=item Start tag

The token has five elements: 'S', the element's name, a reference to a hash 
of attribute values keyed by attribute names, a reference to an array of 
attribute names in the order in which they appeared in the tag, and the 
literal text.

=item End tag

The token has three elements: 'E', the element's name, and the literal text.

=item Character data (text)

The token has three elements: 'T', the parsed text, and the literal text.  
All contiguous runs of text are gathered into single tokens; there will 
never be two 'T' tokens in a row.

=item Comment

The token has three elements: 'C', the parsed text of the comment, and the 
literal text.

=item Processing instruction

The token has four elements: 'PI', the target, the data, and the literal 
text.

=back

The literal text includes any markup delimiters (pointy brackets, 
<![CDATA[, etc.), entity references, and numeric character references and 
is in the XML document's original character encoding.  All other text is in 
UTF-8 (unless the Latin option is set, in which case it's in ISO-8859-1) 
regardless of the original encoding, and all entity and character 
references are expanded.

If the Namespaces option is set, element and attribute names are prefixed 
by their (possibly empty) namespace URIs enclosed in curly brackets and 
xmlns:* attributes do not appear in 'S' tokens.

=head1 DIFFERENCES FROM HTML::TokeParser

Uses a true XML parser rather than a modified HTML parser.

Text and comment tokens include extracted text as well as literal text.

PI tokens include target and data as well as literal text.

No tokens for declarations.

No "textify" hash.

unget_token correctly handles partial tokens returned by get_tag().

begin_saving() and restore_saved()

=head1 EXAMPLES

Example:

    use XML::TokeParser;
    use strict;
                                                                               #
    my $text = '<tag foo="bar" foy="floy"> some text <!--comment--></tag>';
    my $p    = XML::TokeParser->new( \$text );
                                                                               #
    print $/;
                                                                               #
    while( defined( my $t = $p->get_token() ) ){
        local $\="\n";
        print '         raw = ', $t->raw;
                                                                               #
        if( $t->tag ){
            print '         tag = ', $t->tag;
                                                                               #
            if( $t->is_start_tag ) {
                print '        attr = ', join ',', %{$t->attr};
                print '     attrseq = ', join ',', @{$t->attrseq};
            }
                                                                               #
            print 'is_tag       ', $t->is_tag;
            print 'is_start_tag ', $t->is_start_tag;
            print 'is_end_tag   ', $t->is_end_tag;
        }
        elsif( $t->is_pi ){
            print '      target = ', $t->target;
            print '        data = ', $t->data;
            print 'is_pi        ', $t->is_pi;
        }
        else {
            print '        text = ', $t->text;
            print 'is_text      ', $t->is_text;
            print 'is_comment   ', $t->is_comment;
        }
                                                                               #
        print $/;
    }
    __END__


Output:

             raw = <tag foo="bar" foy="floy">
             tag = tag
            attr = foo,bar,foy,floy
         attrseq = foo,foy
    is_tag       1
    is_start_tag 1
    is_end_tag   0


             raw =  some text 
            text =  some text 
    is_text      1
    is_comment   0


             raw = <!--comment-->
            text = comment
    is_text      0
    is_comment   1


             raw = </tag>
             tag = tag
    is_tag       1
    is_start_tag 0
    is_end_tag   1



=head1 BUGS

To report bugs, go to
E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-TokeParserE<gt>
or send mail to E<lt>bug-XML-Tokeparser@rt.cpan.orgE<gt>

=head1 AUTHOR

Copyright (c) 2003 D.H. aka PodMaster (current maintainer).
Copyright (c) 2001 Eric Bohlman (original author).

All rights reserved.
This program is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
If you don't know what this means,
visit E<lt>http://perl.com/E<gt> or E<lt>http://cpan.org/E<gt>.

=head1 SEE ALSO

L<HTML::TokeParser>,
L<XML::Parser>,
L<XML::Catalog>,
L<XML::Smart>,
L<XML::Twig>.

=cut
