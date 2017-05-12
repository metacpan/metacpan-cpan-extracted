package Text::Livedoor::Wiki::Plugin::Inline::Subscript;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{__([^_]*)__});
__PACKAGE__->n_args(1);

sub process {
    my ( $class , $inline , $line ) = @_;
    $line = $inline->parse($line);
    return "<sub>$line</sub>";
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::Subscript - Subscript Inline Plugin

=head1 DESCRIPTION

without subscript , can not type H2O

=head1 SYNOPSIS

 H__2__O

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
