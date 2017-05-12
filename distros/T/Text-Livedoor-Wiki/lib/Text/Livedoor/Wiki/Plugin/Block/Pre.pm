package Text::Livedoor::Wiki::Plugin::Block::Pre;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);

sub check {
    my $self = shift;
    my $line = shift;
    my $args        = shift;
    my $on_next     = $args->{on_next};

    if( $line =~ /^\^/ ) {
        $line =~ s/^\^// unless $on_next;;
        return  { line => $line . "\n" };
    }
    return;

}

sub get {
    my $self = shift;
    my $block = shift;
    my $inline = shift;
    my $items = shift;
    my $html = '';
    $html .= $inline->parse( $_->{line} ) . "\n" for @$items;
    return "<pre>\n$html</pre>\n";

}
1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::Pre - Pre Block Plugin

=head1 DESCRIPTION

pre-formatted text

=head1 SYNOPSIS

 ^ PRE
 ^ pre block

=head1 FUNCTION

=head2 check

=head2 get

=head1 AUTHOR

polocky

=cut
