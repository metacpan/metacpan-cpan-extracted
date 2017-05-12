package Text::MetaMarkup::HTML;
use base 'Text::MetaMarkup';
use strict;

sub escape {
    my ($self, $text) = @_;
    return if not defined $text;
    $text =~ s/([&<>"])/sprintf '&#%d;', ord $1/ge;
    return $text;
}    

sub paragraph_style {
    my ($self, $tag, $text) = @_;
    return "<$tag>$text</$tag>\n\n";
}

sub paragraph {
    my ($self, $tag, $text) = @_;
    $text =~ /^--/ and return '<hr>';
    
    if ($text =~ /^\*/) {
        $tag = 'ul';
        $text =~ s/^\*\s*(.*(?:\n[^*].*)*)/{li:$1}/gm;
    }
    $tag ||= 'p';
    my $r = $self->parse_paragraph_text($text);
    return $r =~ /\n/
        ? "<$tag>\n$r\n</$tag>\n\n"
        : "<$tag>$r</$tag>\n\n";
}

sub inline {
    my ($self, $tag, $text) = @_;
    return "<$tag>" . $self->parse_paragraph_text($text) . "</$tag>";
}

sub link {
    my ($self, $href, $text) = @_;
    $href = $self->escape($href->{href});
    return sprintf
        q[<a href="%s">%s</a>],
        $href,
        $self->parse_paragraph_text(defined $text ? $text : $href);
}

1;

__END__

=head1 NAME

Text::MetaMarkup::HTML - MM-to-HTML conversion

=head1 SYNOPSIS

    use Text::MetaMarkup::HTML;
    print Text::MetaMarkup::HTML->new->parse(file => $filename);

=head1 DESCRIPTION

This module extends Text::MetaMarkup and converts the parsed document to HTML.

Text::MetaMarkup::HTML adds special support for the following tags:

=over 4

=item Paragraph tag C<style>

Its contents are not subject to escaping and inline tag interpolation.

=back

=head1 EXAMPLE

=head2 Input

    h1: Example

    This is just {i:an {b:example}}.

    * foo
    * bar
    * baz

=head2 Output

    <h1>Example</h1>

    <p>This is just <i>an <b>example</b></i>.

    <ol><li>foo</i>
    <li>bar</li>
    <li>baz</li></ol>

=head1 LICENSE

There is no license. This software was released into the public domain. Do with
it what you want, but on your own risk. The author disclaims any
responsibility.

=head1 AUTHOR

Juerd Waalboer <juerd@cpan.org> <http://juerd.nl/>

=cut
