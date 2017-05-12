package Text::Livedoor::Wiki::Plugin::Block::Line;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);

sub check {
    my $class = shift;
    my $line = shift;
    my $args = shift;
    my $id          = $args->{id};
    my $on_next     = $args->{on_next};
    if( $line =~ /^----/ ) {
        #XXX
        $Text::Livedoor::Wiki::scratchpad->{skip_ajust_block_break} = '1';
        
        $line =~ s/^----//;
        return  { line => $line  };
    }
    return;
}

sub get {
    my $class = shift;
    my $block = shift;
    my $inline = shift;
    my $items = shift;
    my $text = '';
    $text .= qq|<hr size="1" noshade="noshade" />| . $inline->parse($_->{line}) . "\n" for @$items;
    return $text;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::Line - Block Line Plugin

=head1 DESCRIPTION

let's have a line.

=head1 SYNOPSIS

 ----
 ---- line 

=head1 FUNCTION

=head2 check

=head2 get

=head1 AUTHOR

polocky

=cut
