package Text::Livedoor::Wiki::Plugin::Inline::Bold;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{''([^']*)''});
__PACKAGE__->n_args(1);
__PACKAGE__->dependency('Text::Livedoor::Wiki::Plugin::Inline::Italic' );

sub process {
    my ( $class , $inline , $line ) = @_;
    $line = $inline->parse($line);
    return "<b>$line</b>";
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::Bold - Bold Inline Plugin

=head1 DESCRIPTION

make text italic.

=head1 SYNOPSIS

 ''Bold Text''

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
