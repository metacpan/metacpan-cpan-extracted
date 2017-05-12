package Text::Livedoor::Wiki::Plugin::Inline::Underbar;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Inline);

__PACKAGE__->regex(q{%%%([^%]*)%%%});
__PACKAGE__->n_args(1);

sub process {
    my ( $class , $inline , $line ) = @_;
    $line = $inline->parse($line);
    return ("<u>$line</u>");
}


1;


=head1 NAME

Text::Livedoor::Wiki::Plugin::Inline::Underbar - Underbar Inline Plugin

=head1 DESCRIPTION

underbar is not for a person's name.

=head1 SYNOPSIS

 %%%underbar%%%

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
