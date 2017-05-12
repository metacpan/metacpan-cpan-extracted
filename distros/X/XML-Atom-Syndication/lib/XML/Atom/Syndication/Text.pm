package XML::Atom::Syndication::Text;
use strict;

use base qw( XML::Atom::Syndication::Object );

XML::Atom::Syndication::Text->mk_accessors('attribute', 'type');

sub init {
    my $text = shift;
    my %param = @_ == 1 ? (Body => $_[0]) : @_;    # escaped text is assumed.
    $text->SUPER::init(%param);
    my $e = $text->elem;
    if ($param{Body}) {
        $text->body($param{Body});
    }
    if ($param{Type}) {
        $text->type($param{Type});
    }
    $text;
}

sub body {
    my $text = shift;
    my $elem = $text->elem;
    my $type = $elem->attributes->{'{}type'} || 'text';
    if (@_) {    # set
        my $data = shift;
        if ($type eq 'xhtml') {
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
                return $text->error(
                                 "Error parsing content body string as XML: $@")
                  if $@;
            }
            $node->parent($elem);
            $elem->contents([$node]);
        } else {    # is text or html
            my $text = XML::Elemental::Characters->new;
            $text->data($data);
            $text->parent($elem);
            $elem->contents([$text]);
        }
        $text->{__body} = undef;
        1;
    } else {    # get
        unless (defined $text->{__body}) {
            if ($type eq 'xhtml') {
                my @children =
                  grep { ref($_) eq 'XML::Elemental::Element' }
                  @{$elem->contents};
                if (@children) {
                    my ($local) =
                      $children[0]->name =~ /{.*}(.+)/;    # process name
                    @children = @{$children[0]->contents}
                      if (@children == 1 && $local eq 'div');

                    # $text->{__body} = '<div>';
                    my $w = XML::Atom::Syndication::Writer->new;
                    $w->set_prefix('', 'http://www.w3.org/1999/xhtml');
                    $w->no_cdata(1);  # works nicer with fringe case. see tests.
                    map { $text->{__body} .= $w->as_xml($_) } @children;

                    # $text->{__body} .= '</div>';
                } else {
                    $text->{__body} = $elem->text_content;
                }
                if ($] >= 5.008) {
                    require Encode;
                    Encode::_utf8_on($text->{__body});
                    $text->{__body} =~ s/&#x(\w{4});/chr(hex($1))/eg;
                    Encode::_utf8_off($text->{__body});
                }
            } else {    # escaped
                $text->{__body} = $elem->text_content;
            }
        }
        $text->{__body};
    }
}

1;

__END__

=begin

=head1 NAME

XML::Atom::Syndication::Text - class representing an Atom
text construct

=head1 DESCRIPTION

A Text construct contains human-readable text, usually in
small quantities. Its content (body) is Language-Sensitive.

=head1 METHODS

XML::Atom::Syndication::Text is a subclass of
L<XML::Atom::Syndication:::Object> that it inherits a number of
methods from. You should already be familiar with this base
class before proceeding.

All of these accessors return a string. You can set these elements
by passing in an optional string.

=over

=item body

An accessor to the text itself.

=item type

The format of the text. The value of type may be one
"text", "html", or "xhtml". Unlike the type attribute in the
content element, this attribute MAY NOT be a MIME type. If 
undefined "text" should be assumed.

=back

=head1 AUTHOR & COPYRIGHT

Please see the L<XML::Atom::Syndication> manpage for author,
copyright, and license information.

=cut

=end

