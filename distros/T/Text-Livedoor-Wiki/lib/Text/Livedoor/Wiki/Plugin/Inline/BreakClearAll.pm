package Text::Livedoor::Wiki::Plugin::Inline::BreakClearAll;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{\~\~\~});
__PACKAGE__->n_args(0);

sub process {
    my ( $class , $inline , $line ) = @_;
    return '<br clear="all" />';
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::BreakClearAll - br with clear="all" inline plugin

=head1 DESCRIPTION

 break with clear="all" attr.

=head1 SYNOPSIS

 hoge ~~~ hoge

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
