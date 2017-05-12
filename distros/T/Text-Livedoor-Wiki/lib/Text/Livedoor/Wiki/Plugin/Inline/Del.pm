package Text::Livedoor::Wiki::Plugin::Inline::Del;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{%%([^%]*)%%});
__PACKAGE__->n_args(1);
__PACKAGE__->dependency( 'Text::Livedoor::Wiki::Plugin::Inline::Underbar' );

sub process {
    my ( $class , $inline , $line ) = @_;
    $line = $inline->parse($line);
    return "<del>$line</del>";
}
1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::Del - Del Inline Plugin

=head1 DESCRIPTION

delete text.

=head1 SYNOPSIS

 %%delete text%%

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
