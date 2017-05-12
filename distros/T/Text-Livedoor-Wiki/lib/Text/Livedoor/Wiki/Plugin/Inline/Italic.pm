package Text::Livedoor::Wiki::Plugin::Inline::Italic;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{'''([^']*)'''});
__PACKAGE__->n_args(1);

sub process {
    my ( $class , $inline , $line ) = @_;
    $line = $inline->parse($line);
    return "<i>$line</i>";
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::Italic - Italic Inline Plugin

=head1 DESCRIPTION

write italic text.

=head1 SYNOPSIS

 '''italic''' 

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
