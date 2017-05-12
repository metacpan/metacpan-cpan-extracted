package Text::Livedoor::Wiki::Plugin::Block::UL;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Base::Block::List);

sub check {
    my $self = shift;
    my $line = shift;
    my $args    = shift;
    my $on_next = $args->{on_next};
    my $id      = $args->{id};

    if( my( $mark ) = $line =~ /^(-{1,3})[^-]/ ) {
        my $level = length $mark ;
        unless ( $on_next ) {
            $line =~ s/^-{$level}//;
        }
        return { id => $id , level => $level , line => $line };
    }
    return;
}

sub get {
    my $self = shift;
    my $block = shift;
    my $inline = shift;
    my $items = shift;
    $self->list($inline, $items,'ul');
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::UL - UL Block Plugin

=head1 DESCRIPTION

unordered list

=head1 SYNOPSIS

 o hoge
 -- hogehoge
 --- hy mom
 - hoge

=head1 FUNCTION

=head2 check

=head2 get

=head1 AUTHOR

polocky

=cut
