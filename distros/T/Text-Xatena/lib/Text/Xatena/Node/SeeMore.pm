package Text::Xatena::Node::SeeMore;

use strict;
use warnings;
use base qw(Text::Xatena::Node);
use Text::Xatena::Util;
use constant {
    SEEMORE => qr/^====(=)?$/
};


sub parse {
    my ($class, $s, $parent, $stack) = @_;
    if ($s->scan(SEEMORE)) {
        my $is_super = $s->matched->[1];
        my $node = $class->new;
        $node->{is_super} = $is_super;
        push @$parent, $node;
        push @$stack, $node;
        return 1;
    }
}

sub as_html {
    my ($self, $context, %opts) = @_;
    $context->_tmpl(__PACKAGE__, q[
        <div class="seemore">
            {{= $content }}
        </div>
    ], {
        content => $self->SUPER::as_html($context, %opts),
    });
}

1;
__END__



