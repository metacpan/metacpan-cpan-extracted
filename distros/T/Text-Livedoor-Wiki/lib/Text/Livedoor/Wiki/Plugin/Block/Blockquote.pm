package Text::Livedoor::Wiki::Plugin::Block::Blockquote;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);

sub check {
    my $class = shift;
    my $line = shift;
    my $args = shift;
    my $id          = $args->{id};
    my $on_next     = $args->{on_next};
    if( $line =~ /^[ \t>]/ ) {
        $line =~ s/^[ \t>]// unless $on_next;;
        return  { id => $id , line => $line . "\n" };
    }
    return;
}

sub get {
    my $class = shift;
    my $block = shift;
    my $inline = shift;
    my $items = shift;
    my $id    = $items->[0]{id};
    my $text = '';
    $text .= $_->{line} for @$items;
    my $html =  $inline->parse($text);
    return qq|<blockquote id="$id">\n$html\n</blockquote>\n|;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::Blockquote - Blockquote Block Plugin

=head1 DESCRIPTION

surround text with blockquote tag

=head1 SYNOPSIS

 > block text
 > here here here
 > hi mom!
 > you can use space instead of > or TAB if you want.

=head1 FUNCTION

=head2 check

=head2 get

=head1 AUTHOR

polocky

=cut
