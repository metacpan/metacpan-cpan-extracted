package Text::Livedoor::Wiki::Plugin::Base::Block::List;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);
sub list {
    my $self  = shift;
    my $inline = shift;
    my $items = shift;
    my $tag   = shift;
    my $id = $items->[0]{id};
    my $level = 1;
    my $data = qq|<$tag id="$id" class="list-1">\n|;
     
    my $fix_data = '';
    my $last = scalar @$items;
    my $cnt=0;
    for my $item ( @$items ) {
        $cnt++;
        my $on_deep= 0;
        while( $level != $item->{level} ) {
            if( $level > $item->{level} ) {
                $level--;
                $data .= "</$tag>\n</li>\n" ;
            }
            else {
                $level++;
                $data .= qq|<$tag class="list-$item->{level}">\n|;
            }
        }
        if(  $cnt != $last ) {
            my $next_item = $items->[$cnt];
            if( $level < $next_item->{level} ) { 
                $on_deep =1;
            }
        }
        $data .= "<li>" . $inline->parse($item->{line});
        $data .= $on_deep ? "\n" : "</li>\n" ;
    }

    while( $level >1 ) {
        $data .= "</$tag>\n</li>\n" ;
        $level--;
    }
    $data .= "</$tag>\n";
    return $data;
}
1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Base::Block::List - Base Class For UL / OL Block Plugin

=head1 DESCRIPTION

base class for L<Text::Livedoor::Wiki::Plugin::Block::UL> and L<Text::Livedoor::Wiki::Plugin::Block::OL>

=head1 SYNOPSIS

 use base qw(Text::Livedoor::Wiki::Plugin::Base::Block::List)

=head1 FUNCTION

=head2 list

create list

=head1 AUTHOR

polocky

=cut
