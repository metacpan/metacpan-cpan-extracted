package Text::Livedoor::Wiki::Plugin::Function::Color;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
__PACKAGE__->function_name('color');

sub prepare_args {
    my $class = shift;
    my $args  = shift;
    die 'no args' unless scalar @$args;

    my $color   = $args->[0];
    my $bgcolor = $args->[1];
    my $my_args = {};
    
    if( $color ) {
        die 'color is not web color' unless $color =~ /^[a-zA-Z0-9#]+$/i;
        $my_args->{color} = $color;
    }

    if( $bgcolor ) {
        die 'bgcolor is not web color' unless $bgcolor=~ /^[a-zA-Z0-9#]+$/i;
        $my_args->{bgcolor} = $bgcolor;
    }
    return $my_args;
}
sub process {
    my ( $class, $inline, $data ) = @_;
    my $str_color  = '';
    my $str_bgcolor = '';

    if( my $color = $data->{args}{color} ) {
        $str_color = "color:$color;";
    }

    if( my $bgcolor = $data->{args}{bgcolor} ) {
        $str_bgcolor = "background-color:$bgcolor;";
    }

    my $style = qq{style="$str_color$str_bgcolor"};
    my $value = $inline->parse( $data->{value} );
    return "<span $style>$value</span>";
    
}

sub process_mobile {
    my ( $class, $inline, $data ) = @_;
    my $str_color ='';
    my $str_bgcolor = '';

    if( my $color = $data->{args}{color} ) {
        $str_color = qq| color="$color"|;
    }

    if( my $bgcolor = $data->{args}{bgcolor} ) {
        $str_bgcolor = qq| style="background-color:$bgcolor"|;
    }

    my $value = $inline->parse( $data->{value} );
    return (qq|<font${str_color}${str_bgcolor}>$value</font>|);
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Color - Color Function Plugin

=head1 DESCRIPTION

customize font color.

=head1 SYNOPSIS 

 &color(red){red}
 &color(,red){back ground red}
 &color(red,black){ red text and block background}
 &color(#ffffff,#000000){hey hey}

=head1 FUNCTION

=head2 prepare_args

=head2 process

=head2 process_mobile

=head1 AUTHOR

polocky

=cut
