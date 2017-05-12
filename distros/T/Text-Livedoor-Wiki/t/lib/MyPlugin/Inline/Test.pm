package MyPlugin::Inline::Test;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{#####([^#]*)#####});
__PACKAGE__->n_args(1);

sub process {
    my ( $class , $inline , $line ) = @_;
    $line = $inline->parse($line);
    my $id = $class->uid;
    my $ping = $class->opts->{ping};
    return "<INLINE_$id>$line-$ping</INLINE_$id>";
}

1;
