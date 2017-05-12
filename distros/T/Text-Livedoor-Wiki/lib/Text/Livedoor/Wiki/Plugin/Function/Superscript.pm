package Text::Livedoor::Wiki::Plugin::Function::Superscript;

use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
__PACKAGE__->function_name('sup');

sub process {
    my ( $class, $inline, $data ) = @_;
    my $value = $data->{value};
    $value = $inline->parse( $value );
    return "<sup>$value</sup>";
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Superscript - Superscript Function Plugin

=head1 DESCRIPTION

write superscript text.

=head1 SYNOPSIS

 &sup(){text here here here};

=head1 FUNCTION

=head2 process

=head1 AUTHOR

polocky

=cut
