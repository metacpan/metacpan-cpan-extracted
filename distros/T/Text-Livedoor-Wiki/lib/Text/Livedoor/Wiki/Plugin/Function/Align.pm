package Text::Livedoor::Wiki::Plugin::Function::Align;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
__PACKAGE__->function_name('align');

sub prepare_args {
    my $class = shift;
    my $args = shift;
    die 'no args' unless scalar @$args;
    my $align = $args->[0];
    die 'invalid value for alignment.' unless $align =~ /^(left|right|center)$/i;
    return { align => lc $align };
}

sub process {
    my ( $class, $inline, $data ) = @_;
    my $align = $data->{args}{align};

    my $style = qq{style="text-align:$align;"};
    my $value = $inline->parse( $data->{value} );
    return "<div $style>$value</div>";
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Align - Align Function Plugin

=head1 DESCRIPTION

change text alignment.

=head1 SYNOPSIS 

 &align(right){Here are some words.}

=head1 FUNCTION

=head2 prepare_args

=head2 process


=head1 AUTHOR

oklahomer

=cut
