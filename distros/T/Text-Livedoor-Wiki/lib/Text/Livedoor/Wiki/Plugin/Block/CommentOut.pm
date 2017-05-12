package Text::Livedoor::Wiki::Plugin::Block::CommentOut;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);

sub check {
    my $class = shift;
    my $line = shift;
    my $args = shift;
    my $id          = $args->{id};
    my $on_next     = $args->{on_next};
    if( $line =~ /^\/\// ) {
        $Text::Livedoor::Wiki::scratchpad->{skip_ajust_block_break} = '1';
        return  { id => $id };
    }
    return;
}

sub get { 
    return "";
} 

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::CommentOut - Comment Out Block Plugin 

=head1 DESCRIPTION

comment out text so that the text does not show up on HTML. 
This is NOT the kind of plugin which convert HTML comment tag such as <!-- ... 

=head1 SYNOPSIS

 // comment here and do not display after parsing

=head1 FUNCTION

=head2 check

=head2 get

=head1 AUTHOR

polocky

=cut
