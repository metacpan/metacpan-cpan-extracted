package URL::Transform;

=head1 NAME

URL::Transform - perform URL transformations in various document types

=head1 SYNOPSIS

    my $output;
    my $urlt = URL::Transform->new(
        'document_type'      => 'text/html;charset=utf-8',
        'content_encoding'   => 'gzip',
        'output_function'    => sub { $output .= "@_" },
        'transform_function' => sub { return (join '|', @_) },
    );
    $urlt->parse_file($Bin.'/data/URL-Transform-01.html');

    print "and this is the output: ", $output;

=head1 DESCRIPTION

URL::Transform is a generic module to perform an url transformation in
a documents. Accepts callback function using which the url link can be
changed.

There are different modules to handle different document types, elements
or attributes:

=over 4

=item C<text/html>, C<text/vnd.wap.wml>, C<application/xhtml+xml>, C<application/vnd.wap.xhtml+xml>

L<URL::Transform::using::HTML::Parser>,
L<URL::Transform::using::XML::SAX> (incomplete was used only to benchmark)

=item C<text/css>

L<URL::Transform::using::CSS::RegExp>

=item C<text/html/meta-content>

L<URL::Transform::using::HTML::Meta>

=item C<application/x-javascript>

L<URL::Transform::using::Remove>

=back

By passing C<parser> option to the C<< URL::Transform->new() >> constructor you
can set what library will be used to parse and execute the output and transform
functions. Note that the elements inside for example C<text/html> that are
of a different type will be transformed via L</default_for($document_type)> modules.

C<transform_function> is called with following arguments:

    transform_function->(
        'tag_name'       => 'img',
        'attribute_name' => 'src',
        'url'            => 'http://search.cpan.org/s/img/cpan_banner.png',
    );

and must return (un)modified url as the return value.

C<output_function> is called with (already modified) document chunk for outputting.

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use Carp::Clan;
use English '$EVAL_ERROR';
use HTML::Tagset;
use Compress::Zlib;
use File::Slurp 'read_file';

use base 'Class::Accessor::Fast';

=head1 PROPERTIES

    content_encoding
    document_type
    parser
    transform_function
    output_function

=over 4

=item parser

For HTML/XML can be HTML::Parser, XML::SAX

=item document_type

    text/html - default

=item transform_function

Function that will be called to make the transformation. The function will receive
one argument - url text.

=item output_function

Reference to function that will receive resulting output. The default one is to use
print.

=item content_encoding

Can be set to C<gzip> or C<deflate>. By default it is C<undef>, so there is
no content encoding.

=back

=cut

__PACKAGE__->mk_accessors(qw{
    document_type
    content_encoding
    transform_function
    output_function
    parser
    supported_document_types
});

=head1 METHODS

=head2 new

Object constructor.

Requires C<transform_function> a CODE ref argument.

The rest of the arguments are optional. Here is the list with defaults:

    document_type       => 'text/html;charset=utf-8',
    output_function     => sub { print @_ },
    parser              => 'HTML::Parser',
    content_encoding    => undef,

=cut

my %supported_document_types = (
    'text/html'                     => 'HTML::Parser',
    'text/vnd.wap.wml'              => 'HTML::Parser',
    'application/xhtml+xml'         => 'HTML::Parser',
    'application/vnd.wap.xhtml+xml' => 'HTML::Parser',
    'text/css'                      => 'CSS::RegExp',
    'text/html/meta-content'        => 'HTML::Meta',
    'application/x-javascript'      => 'Remove',
);

my %supported_content_encoding = (
    'gzip'    => 1,
    'deflate' => 1,
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new({
        'supported_document_types' => {},
        @_
    });

    croak 'pass transform_function'
        if not ref $self->transform_function eq 'CODE';

    # default document type
    my ($document_type, $encoding) = split ';', $self->document_type || '';
    $document_type ||= 'text/html';

    # default output function
    $self->output_function(sub { print @_ })
        if not defined $self->output_function;

    # setup thinks for parsing html documents
    my $parser = $self->parser || $supported_document_types{$document_type};
    croak 'unsupported document type: ', $document_type
        if not $parser;

    # check content_encoding
    my $content_encoding = $self->content_encoding;
    if ($content_encoding){
        croak 'unsupported content_encoding: ', $content_encoding
            if (not $supported_content_encoding{$content_encoding});
    }

    # construct parser object
    eval {
        no strict 'refs';
        $parser = 'URL::Transform::using::'.$parser;
        eval 'use '.$parser;
        $parser = $parser->new(
            'output_function'    => $self->output_function,
            'transform_function' => $self->transform_function,
            'parser_for'         => sub { $self->default_for(@_) },
        );
    };
    croak 'error loading parser "'.$parser.'" - '.$EVAL_ERROR.' ' if $EVAL_ERROR;

    $self->parser($parser);

    return $self;
}


=head2 default_for($document_type)

Returns default parser for a supplied $document_type.

Can be used also as a set function with additional argument - parser name.

If called as object method set the default parser for the object.
If called as module function set the default parser for a whole module.

=cut

sub default_for {
    my $self = shift;
    
    # if called from object get/set object parsers for different content types
    if (ref $self) {
        my $document_type = shift;

        # if case of set
        if (@_ > 0) {
            $self->supported_document_types->{$document_type} = shift;
        }
        
        return exists($self->{supported_document_types}->{$document_type})
            ? $self->{supported_document_types}->{$document_type}
            : $supported_document_types{$document_type};
    }
    # if called directly get/set the module defaults
    else {
        my $document_type = $self;
        
        # if case of set
        if (@_ > 0) {
            $supported_document_types{$document_type} = shift;
        }
        
        return $supported_document_types{$document_type};
    }
}


=head2 parse_string($string)

Submit document as a string for parsing.

This some function must be implemented by helper parsing classes.

=cut

sub parse_string {
    my $self = shift;
    my $data = shift;

    return $self->parser->parse_string(
        $self->decode_string($data)
    );
}


=head2 parse_chunk($chunk)

Submit chunk of a document for parsing.

This some function should be implemented by helper parsing classes.

=cut

sub parse_chunk {
    my $self = shift;
    my $data = shift;

    my $parser = $self->parser;

    if ($self->can_parse_chunks) {
        return $self->parser->parse_chunk($data);
    }
    else {
        die $self->parser.' is not able to parse in chunks. :(';
    }
}


=head2 can_parse_chunks

Return true/false if the parser can parse in chunks.

=cut

sub can_parse_chunks {
    my $self = shift;
    my $parser = $self->parser;

    if ( defined $self->content_encoding ) {
        return 0;
    }

    return $parser->can('parse_chunk');
}


=head2 parse_file($file_name)

Submit file for parsing.

This some function should be implemented by helper parsing classes.

=cut

sub parse_file {
    my $self = shift;

    # if the content is not encoded the call parser parse_file method
    return $self->parser->parse_file(@_)
        if not $self->content_encoding;

    # otherwise use parse_string that uses decode_string
    return $self->parse_string(scalar read_file(@_))
}


=head2 link_tags

    # To simplify things, reformat the %HTML::Tagset::linkElements
    # hash so that it is always a hash of hashes.

# Construct a hash of tag names that may have links.

=cut

# FIXME should be moved outside or URL::Transform because it HTML specific
my $_link_tags;
sub link_tags {
    # if it's already generate return the reference right away
    return $_link_tags if defined $_link_tags;

    my %link_tags;

    # meta can have a refresh url in the content, wml has some special tags
    my %link_elements = (
        %HTML::Tagset::linkElements,
        'meta'   => 'content',
        'go'     => 'href',
        'card'   => 'ontimer',
        'option' => 'onpick',
    );
    
    # To simplify things, reformat the %HTML::Tagset::linkElements
    # hash so that it is always a hash of hashes.
    while (my($k,$v) = each %link_elements) {
        if (ref($v)) {
            $v = { map {$_ => 1} @$v };
        }
        else {
            $v = { $v => 1};
        }
        $link_tags{$k} = $v;
    }

    # attributes that match all tags
    $link_tags{''} = {}
        if not exists $link_tags{''};

    # add tags with style
    $link_tags{''}->{'style'} = 1;
    $link_tags{'style'}->{''} = 1;

    # add tags with javascript
    foreach my $attr (keys %{js_attributes()}) {
        $link_tags{''}->{$attr} = 1;
    }
    $link_tags{'script'}->{''} = 1;

    # Uncomment this to see what HTML::Tagset::linkElements thinks are
    # the tags with link attributes
    #use Data::Dump; Data::Dump::dump(\%link_tags); exit;
    
    $_link_tags = \%link_tags;
    return $_link_tags;
}


=head2 js_attributes

# Construct a hash of all possible JavaScript attribute names

=cut

# FIXME should be moved outside or URL::Transform because it HTML specific
my $_js_attributes;
sub js_attributes {
    # if it's already generate return the reference right away
    return $_js_attributes if defined $_js_attributes;

    # taken from http://www.w3.org/TR/html401/interact/scripts.html#h-18.2.3
    my @js_attributes =  qw(
        onload
        onunload
        onclick
        ondblclick
        onmousedown
        onmouseup
        onmouseover
        onmousemove
        onmouseout
        onfocus
        onblur
        onkeypress
        onkeydown
        onkeyup
        onsubmit
        onreset
        onselect
        onchange
    );

    $_js_attributes = {
        map { $_ => 1 } @js_attributes
    };
    return $_js_attributes;
}


=head2 decode_string($string)

Will return decoded string suitable for parsing. Decoding
is chosen according to the $self->content_encoding.

Decoding is run automatically for every chunk/string/file.

=cut

sub decode_string {
    my $self = shift;
    my $data = shift;

    my $content_encoding = $self->content_encoding;

    # just ignore without content encoding
    return $data
        if (not $content_encoding);

    return Compress::Zlib::memGunzip($data)
        if ($content_encoding eq 'gzip');
    
    if ($content_encoding eq 'deflate') {
        my $raw = Compress::Zlib::uncompress($data);
        if ( defined $raw ) {
            return $raw;
        }
        else {
            # "Content-Encoding: deflate" is supposed to mean the "zlib"
            # format of RFC 1950, but Microsoft got that wrong, so some
            # servers sends the raw compressed "deflate" data.  This
            # tries to inflate this format.
            my($i, $status) = Compress::Zlib::inflateInit(
                WindowBits => -Compress::Zlib::MAX_WBITS(),
                        );
            my $OK = Compress::Zlib::Z_OK();
            die "Can't init inflate object" unless $i && $status == $OK;
            ($raw, $status) = $i->inflate(\$data);
            return $raw;
        }
    }

    return $data;
}


=head2 encode_string($string)

Will return encoded string. Encoding
is chosen according to the $self->content_encoding.

NOTE if you want to have your content encoded back to the
$self->content_encoding you will have to run this method
in your code. Argument to the C<output_function()> are always
plain text.

=cut

sub encode_string {
    my $self = shift;
    my $data = shift;

    my $content_encoding = $self->content_encoding;

    # just ignore without content encoding
    return $data
        if not $content_encoding;

    return Compress::Zlib::memGzip($data)
        if ($content_encoding eq 'gzip');

    return Compress::Zlib::compress($data)
        if ($content_encoding eq 'deflate');

    return $data;
}


=head2 get_supported_content_encodings()

Returns hash reference of supported content encodings.

=cut

sub get_supported_content_encodings {
    return \%supported_content_encoding;
}


1;


__END__


=head1 benchmarks

    Benchmark: timing 10000 iterations of HTML::Parser    , XML::LibXML::SAX, XML::SAX::PurePerl...
    HTML::Parser      :  3 wallclock secs ( 2.41 usr +  0.04 sys =  2.45 CPU) @ 4081.63/s (n=10000)
    XML::LibXML::SAX  : 29 wallclock secs (27.22 usr +  0.11 sys = 27.33 CPU) @ 365.90/s (n=10000)
    XML::SAX::PurePerl: 192 wallclock secs (180.62 usr +  0.50 sys = 181.12 CPU) @ 55.21/s (n=10000)

=head1 TODO

There are urls in C<pics> meta tag: C<< <meta http-equiv="pics-label" content=" ... >>. See L<http://www.w3.org/PICS/>.

=head1 SEE ALSO

L<HTML::Parser>, L<URL::Transform::using::HTML::Parser>

=head1 AUTHOR

Jozef Kutej C<< <jkutej at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


