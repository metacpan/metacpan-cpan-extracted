package Text::Livedoor::Wiki::Plugin::Inline::Break;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{\~\~});
__PACKAGE__->n_args(0);
__PACKAGE__->dependency( 'Text::Livedoor::Wiki::Plugin::Inline::BreakClearAll' );

sub process {
    my ( $class , $inline , $line ) = @_;
    $line = $inline->parse($line);
    return "<br />";
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::Break - Inline Break Plugin

=head1 DESCRIPTION

break text line.

=head1 SYNOPSIS

 I have a ~~ dream

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
