package Text::Livedoor::Wiki::Plugin::Block::DL;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);

sub check {
    my $class   = shift;
    my $line    = shift;
    my $args    = shift;
    my $on_next = $args->{on_next};
    my $id      = $args->{id};
    if( my( $title , $description ) = $line =~ /^:([^\|]*)\|(.*)/ ) {
        return { id => $id , title => $title ,  description => $description  };
    }
    return;

}

sub get {
    my $class   = shift;
    my $block   = shift;
    my $inline  = shift;
    my $items   = shift;
    my $id      = $items->[0]{id};
    my $inlines = '';
    for (@$items) {
        $inlines .= $class->item($inline, $_);
    }
    return qq|<dl id="$id">\n$inlines</dl>\n|;
}

sub item {
    my $class = shift;
    my $inline = shift;
    my $item = shift;
    my $dt   =  $inline->parse( $item->{title} );
    my $dd   =  $inline->parse( $item->{description} );
    my $line = "<dt>$dt</dt><dd>$dd</dd>\n";
    return $line;
}


1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::DL - Definition List Block Plugin

=head1 DESCRIPTION

Definition list

=head1 SYNOPSIS

 :word|description here
 :word|description here
 :word|description here

=head1 FUNCTION

=head2 check

=head2 get

=head2 item

=head1 AUTHOR

polocky

=cut
