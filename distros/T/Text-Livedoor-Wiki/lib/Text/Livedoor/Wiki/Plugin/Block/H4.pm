package Text::Livedoor::Wiki::Plugin::Block::H4;

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

    my $key = 'h4_is_active_' . $id;
    
    # start rule
    #  1. start with **~
    #  2. not end yet
    #if ( $line =~ /^\*\*[^\*]./ && !$scratchpad->{$key} && !$class->get_child($id)){
    if ( $line =~ /^\*\*[^\*]+/ && !$scratchpad->{$key} && !$class->get_child($id)){
        $scratchpad->{$key} = 1 ;
        $line =~ s/^\*\*//;
        my $title =  $inline->parse($line);
        my $header = '';

        #XXX
        $Text::Livedoor::Wiki::scratchpad->{skip_ajust_block_break} = '1';
        
        if( $skip_catalog ) {
            $header = sprintf( qq|<div class="title-2"><h4>%s</h4></div>\n| ,  $title ) ;
        }
        else {
            $id_keeper->up(2);
            $catalog_keeper->append( {level=>2 , id =>  $id_keeper->id(2) , label => $title } );
            $header = sprintf( qq|<div class="title-2"><h4 id="%s">%s</h4></div>\n| ,  $id_keeper->id(2) ,  $title ) ;
        }
        return { header => $header , id => $id };
    }
    # end rule
    # 1. next line
    # 2. no not-closed child block
    # 3. *
    elsif( $on_next && $class->trigger_check($id,$line) &&  $line =~ /^\*/ && $scratchpad->{$key} ) {
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
    my $id     = $meta->{id} ;
    my $html = '';
    $html .= $_->{line} . "\n" for @$items;
    $html =~ s/\n$//;
    # block in block
    $html = $block->parse( $html , 1 ) ;
    return qq|<div id="$id" class="wiki-section-2">\n$header<div id="$id-body" class="wiki-section-body-2">\n$html</div>\n</div>\n|;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::H4 - H4 Block Plugin

=head1 DESCRIPTION

H4 is second level header

=head1 SYNOPSIS

 ** title2
  
 content
 
 ** title2

=head1 FUNCTION

=head2 check

=head2 get

=head1 AUTHOR

polocky

=cut
