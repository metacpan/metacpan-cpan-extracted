package WikiText::HTML::Emitter;
use strict;
use warnings;
use base 'WikiText::Emitter';

use CGI::Util;

sub break_lines {@_>1?($_[0]->{break_lines}=$_[1]):$_[0]->{break_lines}}

my $type_tags = {
    b => 'strong',
    i => 'em',
    wikilink => 'a',
    hyperlink => 'a',
};

sub uri_escape {
    $_ = shift;
    s/ /\%20/g;
    return $_;
}

sub begin_node {
    my $self = shift;
    my $node = shift;
    my $type = $node->{type};
    my $tag = $type_tags->{$type} || $type;
# XXX For tables maybe...
#    $tag =~ s/-.*//;
    $self->{output} .=
      ($tag =~ /^(br|hr)$/)
        ? "<$tag />\n"
        : ($type eq "hyperlink")
          ?  $self->begin_hyperlink($node)
        : ($type eq "wikilink")
          ?  $self->begin_wikilink($node)
          : "<$tag>" .
            ($tag =~ /^(ul|ol|table|tr)$/ ? "\n" : "");
}

sub begin_hyperlink {
    my $self = shift;
    my $node = shift;
    my $tag = $node->{type};

    my $link = $node->{attributes}{target};

    return qq{<a href="$link">};
}

sub begin_wikilink {
    my $self = shift;
    my $node = shift;
    my $tag = $node->{type};

    my $link = $self->{callbacks}{wikilink}
        ? $self->{callbacks}{wikilink}->($node)
        : CGI::Util::escape($node->{attributes}{target});

    my $class = $node->{attributes}{class};
    $class = $class ? qq{ class="$class"} : '';
    return qq{<a href="$link"$class>};
}

sub end_node {
    my $self = shift;
    my $node = shift;
    my $type = $node->{type};
    my $tag = $type_tags->{$type} || $type;
    $tag =~ s/-.*//;
    return if ($tag =~ /^(br|hr)$/);
    $self->{output} .= "</$tag>" .
        ($tag =~ /^(p|hr|ul|ol|li|h\d|table|tr|td|pre)$/ ? "\n" : "");
}

sub text_node {
    my $self = shift;
    my $text = shift;
    if ($self->break_lines) {
        $text =~ s/\n/<br>\n/g;
    }
    $self->{output} .= "$text";
}

1;
