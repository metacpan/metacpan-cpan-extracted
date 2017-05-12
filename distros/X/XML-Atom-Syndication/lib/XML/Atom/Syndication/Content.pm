package XML::Atom::Syndication::Content;
use strict;

use base qw( XML::Atom::Syndication::Object );

use XML::Atom::Syndication::Util qw( utf8_off );
use MIME::Base64 qw( encode_base64 decode_base64 );

XML::Atom::Syndication::Content->mk_accessors('attribute', 'type', 'src');
XML::Atom::Syndication::Content->mk_accessors('attribute', 'mode')
  ;    # deprecated 0.3 accessors

sub init {
    my $content = shift;
    my %param = @_ == 1 ? (Body => $_[0]) : @_;    # escaped text is assumed.
    $content->SUPER::init(%param);
    my $e = $content->elem;
    if ($param{Body}) {
        $content->body($param{Body});
    }
    if ($param{Type}) {
        $content->type($param{Type});
    }
    $content;
}

sub element_name { 'content' }

sub body {
    my $content = shift;
    my $elem    = $content->elem;
    my $type    = $elem->attributes->{'{}type'};
    my $mode;
    if (!defined $type || $type eq 'text' || $type eq 'html') {
        $mode = 'escaped';
    } elsif (   $type eq 'xhtml'
             || $type =~
             m{^(text/xml|application/xml|text/xml-external-parsed-entity)$}
             || $type =~ m{[\+/]xml$}) {
        $mode = 'xml';
             } elsif ($type =~ m{text/.+}) {
        $mode = 'escaped';
             } else {
        $mode = 'base64';
    }
    if (@_) {    # set
        my $data = shift;
        if ($mode eq 'base64') {    # is binary
            utf8_off($data);
            require XML::Elemental::Characters;
            my $b = XML::Elemental::Characters->new;
            $b->data(encode_base64($data, ''));
            $b->parent($elem);
            $elem->contents([$b]);
        } elsif ($mode eq 'xml') {    # is xml
            my $node = $data;
            unless (ref $node) {
                my $copy =
                    '<div xmlns="http://www.w3.org/1999/xhtml">' . $data
                  . '</div>';
                eval {
                    require XML::Elemental;
                    my $parser = XML::Elemental->parser;
                    my $xml    = $parser->parse_string($copy);
                    $node = $xml->contents->[0];
                };
                return $content->error(
                                 "Error parsing content body string as XML: $@")
                  if $@;
            }
            $node->parent($elem);
            $elem->contents([$node]);
        } else {    # is text
            my $text = XML::Elemental::Characters->new;
            $text->data($data);
            $text->parent($elem);
            $elem->contents([$text]);
        }
        $content->{__body} = undef;
        1;
    } else {    # get
        unless (defined $content->{__body}) {
            if ($mode eq 'xml') {
                my @children =
                  grep { ref($_) eq 'XML::Elemental::Element' }
                  @{$elem->contents};
                if (@children) {
                    my ($local) =
                      $children[0]->name =~ /{.*}(.+)/;    # process name
                    @children = @{$children[0]->contents}
                      if (@children == 1 && $local eq 'div');

                    # $content->{__body} = '<div>';
                    my $w = XML::Atom::Syndication::Writer->new;
                    $w->set_prefix('', 'http://www.w3.org/1999/xhtml');
                    map { $content->{__body} .= $w->as_xml($_) } @children;

                    # $content->{__body} .= '</div>';
                } else {
                    $content->{__body} = $elem->text_content;
                }
                if ($] >= 5.008) {
                    require Encode;
                    Encode::_utf8_on($content->{__body});
                    $content->{__body} =~ s/&#x(\w{4});/chr(hex($1))/eg;
                    Encode::_utf8_off($content->{__body});
                }
            } elsif ($mode eq 'base64') {
                $content->{__body} = decode_base64($elem->text_content);
            } else {    # escaped
                $content->{__body} = $elem->text_content;
            }
        }
        $content->{__body};
    }
}

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Content - class representing Atom
entry content.

=head1 DESCRIPTION

The content element either contains or links to the content
of the entry. The content of this element is
Language-Sensitive.

=head1 METHODS

XML::Atom::Syndication::Content is a subclass of
L<XML::Atom::Syndication::Object> that it inherits numerous
methods from. You should already be familiar with this base
class before proceeding.

=over

=item new(%params)

=item new($body)

The constructor of XML::Atom::Syndication::Content acts like
any other subclass of L<XML::Atom::Syndication::Object>
recognizing C<Elem>, C<Namespace> and C<Version> elements in
the optional HASH that can be passed. This class also
recognizes C<Body> and C<Type> elements in the hash which
map to the like named methods.

You can also pass in a string instead of a HASH. This string
will be used as the body of the content and stored as
escaped content.

B<NOTE:> If you pass in a string it will be stored as
escaped content. In other words, Base64 and XML content
cannot use this shorthand. Instead developers should pass 
a Body and Type element in a hash.

=item body($data)

An accessor to set the body of the content if any. If a src
attribute has been defined the body should be empty.

B<NOTE:> You must set the content type I<before> you set the
body in order for the content to be stored properly. As per
section 4.1.3.3 of the Atom Syndication Format
specification, content processing is determined by the type
attribute regardless of what the actual content is. The body
method will not attempt to determine the format of content,
it will simply reference the type attribute and process it
accordingly. If type has not been defined then it is treated
as escaped text.

=item type

The format of the content. The value of type may be one
"text", "html", or "xhtml". Failing that, it must conform to
the syntax of a MIME media type, but not be a composite
type. See section 4.2.6 of draft-freed-media-type-reg-04 for
more.

This accessor returns a string. You can set this attribute
by passing in an optional string.

=item src

An IRI that can be used to retrieve the content.

This accessor returns a string. You can set this attribute
by passing in an optional string.

=back

=head2 DEPRECATED

=over

=item mode

Indicates the method used to encode the content. This
attribute was present in version 0.3 of the format and
removed by version 1.0. It function was assumed by the 
type attribute and refinements to the content processing 
model.

This accessor returns a string. You can set this attribute
by passing in an optional string.

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end
