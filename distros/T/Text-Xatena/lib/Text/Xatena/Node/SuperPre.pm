package Text::Xatena::Node::SuperPre;

use strict;
use warnings;
use base qw(Text::Xatena::Node);
use Text::Xatena::Util;
use constant {
    BEGINNING => qr/^>\|([^|]*)\|$/,
    ENDOFNODE => qr/^\|\|<$/,
};

our $SUPERPRE_CLASS_NAME = 'code';

sub parse {
    my ($class, $s, $parent, $stack) = @_;
    if ($s->scan(BEGINNING)) {
        my $lang = $s->matched->[1];
        my $content = $s->scan_until(ENDOFNODE);
        pop @$content;
        my $node = $class->new([join("\n", @$content)]);
        $node->{lang} = $lang;
        push @$parent, $node;
        return 1;
    }
}

sub lang { $_[0]->{lang} }

sub as_html {
    my ($self, $context, %opts) = @_;
    $context->_tmpl(__PACKAGE__, q[
        ? if ($lang) {
            <pre class="{{= $class }} {{= "lang-$lang" }}">{{= $content }}</pre>
        ? } else {
            <pre class="{{= $class }}">{{= $content }}</pre>
        ? }
    ], {
        class   => $SUPERPRE_CLASS_NAME,
        lang    => $self->lang,
        content => escape_html(join "", @{ $self->children })
    });
}

1;
__END__



