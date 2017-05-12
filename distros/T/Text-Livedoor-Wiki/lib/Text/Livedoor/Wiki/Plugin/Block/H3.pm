package Text::Livedoor::Wiki::Plugin::Block::H3;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);

sub check {
    my $class       = shift;
    my $line        = shift;
    my $args        = shift;
    my $id          = $args->{id};
    my $inline      = $args->{inline};
    my $on_next     = $args->{on_next};
    my $scratchpad  = $Text::Livedoor::Wiki::scratchpad;


    my $catalog_keeper = $Text::Livedoor::Wiki::opts->{catalog_keeper};
    my $id_keeper      = $Text::Livedoor::Wiki::opts->{id_keeper};
    my $skip_catalog   = $Text::Livedoor::Wiki::opts->{skip_catalog};

    my $key = 'h3_is_active_' . $id;
    #if ( $line =~ /^\*[^\*]./ && !$on_next && !$class->get_child($id) ){
    if ( $line =~ /^\*[^\*]+/ && !$on_next && !$class->get_child($id) ){
        $scratchpad->{$key} = 1 ;
        $line =~ s/^\*//;
        my $title =  $inline->parse($line);
        my $header = '';
        my $header_meta = {};

        #XXX
        $Text::Livedoor::Wiki::scratchpad->{skip_ajust_block_break} = '1';
        
        if( $skip_catalog ) {
            $header = sprintf( qq|<div class="title-1"><h3>%s</h3></div>\n| ,  $title ) ;
        }
        else {
            $id_keeper->up(1);
            $Text::Livedoor::Wiki::scratchpad->{core}{h3pos}{$id_keeper->id(1)} = $Text::Livedoor::Wiki::scratchpad->{core}{current_pos};
            $catalog_keeper->append( {level=>1 , id =>  $id_keeper->id(1) , label => $title } );
            $header 
                = sprintf( qq|<div class="title-1"><h3 id="%s">%s</h3></div>\n| ,  $id_keeper->id(1) ,  $title ) ;
            $header_meta = {
                id => $id_keeper->id(1),
                title => $title,
            };
        }
        return { id => $id , header => $header , header_meta => $header_meta };
    }
    elsif( $on_next && $class->trigger_check($id,$line) && $line =~ /^\*/ && $scratchpad->{$key} ) { 
        $scratchpad->{$key} = 0 ;
        return ;
    }
    elsif( $scratchpad->{$key} ) {
        return { line => $line  };
    }
    return;

}

sub get {
    my $class = shift;
    my $block = shift;
    my $inline = shift;
    my $items = shift;
    my $meta = shift @{$items};
    my $header = $meta->{header} ;
    my $id     = $meta->{id};
    my $html = '';
    $html .= $_->{line}  . "\n" for @$items;
    $html =~ s/\n$//;
    # block in block
    $html = $block->parse( $html , 1 ) ;
    return qq|<div id="$id" class="wiki-section-1">\n$header<div id="$id-body" class="wiki-section-body-1">\n$html</div>\n</div>\n|;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::H3 - H3 Block Plugin

=head1 DESCRIPTION

H3 is top level header.

=head2 SYNOPSIS

 * Title
 
 contents
 
 
 * Title2
 
 Content

=head1 FUNCTION

=head2 check

=head2 get

=head1 AUTHOR

polocky

=cut
