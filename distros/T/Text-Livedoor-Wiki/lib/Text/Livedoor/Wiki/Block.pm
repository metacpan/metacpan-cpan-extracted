package Text::Livedoor::Wiki::Block;

use warnings;
use strict;
use UNIVERSAL::require;
use Scalar::Util;

sub new {
    my $class = shift;
    my $self = shift;
    $self = bless $self , $class;
    Scalar::Util::weaken($self->{inline});
    $self->_load( $self->{block_plugins}  );
    return $self;
}
sub blocks { shift->{blocks} }
sub trigger{ shift->{trigger} }
sub inline { shift->{inline}->parse(@_); }
sub on_mobile{ shift->{on_mobile} }

#XXX only for footnote plugin for now
sub footer_section {
    my $self = shift;
    my $res = '';
    my $footnotes = $Text::Livedoor::Wiki::scratchpad->{footnotes};

    if( $footnotes ) {
        $res =qq|<div class="footer-footnote">\n<hr />\n<ul class="list-1">\n|;
        my $cnt = 1;
        for ( @$footnotes ) {
            $res .=qq|<li><a href="#footnote$cnt" name="footer-footnote$cnt">*$cnt </a> : $_</li>\n|;
            $cnt++;
        }
        $res .="<ul>\n</div>\n";
    }
    return $res;
}

sub opts { $Text::Livedoor::Wiki::opts }
sub parse {
    my $self = shift;
    my $text = shift;
    my $nested = shift;
    my $catalog_keeper = $self->opts->{catalog_keeper};
    my $id_keeper      = $self->opts->{id_keeper};
    my $skip_catalog   = $self->opts->{skip_catalog};

    my @lines = split("\n" ,$text , -1 );
    my $html = ''; 
    my @items = ();
    my $last  = scalar @lines;
    my $cnt = 0;
    my $on_processing = 0;
    my $current_block ;

    $Text::Livedoor::Wiki::scratchpad->{core}{block_uid}++;
    LINE : 
    for ( @lines ) {
        $Text::Livedoor::Wiki::scratchpad->{core}{current_pos}++ unless $nested;
        #warn  $Text::Livedoor::Wiki::scratchpad->{core}{current_pos} . ':' . $_ unless $nested;
        $cnt++;
        my $blocks_cache = $on_processing  ? [$current_block] : $self->blocks ;
        my $id =  $self->opts->{name} . '_block_' . $Text::Livedoor::Wiki::scratchpad->{core}{block_uid} ;
        for my $block ( @{$blocks_cache} ) {
            if( my $res = $block->check($_ , { id => $id , on_next =>  0 , inline => $self->{inline} } ) ) {
                $current_block= $block;
                $on_processing = 1; 
                push @items, $res;
                if( $last != $cnt ) {
                    unless(  my $next_res = $block->check($lines[$cnt] ,  { id => $id , on_next =>  1 , inline => $self->{inline} } ) ) {
                        $html =~ s/<br \/>\n$// unless $Text::Livedoor::Wiki::scratchpad->{skip_ajust_block_break};
                         $Text::Livedoor::Wiki::scratchpad->{skip_ajust_block_break} = 0;
                        $html .= $self->on_mobile ? $block->mobile(  $self, $self->{inline} , \@items) : $block->get( $self, $self->{inline} , \@items );
                        @items = ();
                        $Text::Livedoor::Wiki::scratchpad->{core}{block_uid}++;
                        $on_processing = 0; 
                    }
                }
                else {
                    #$html =~ s/<br \/>\n$//;
                    $html =~ s/<br \/>\n$// unless $Text::Livedoor::Wiki::scratchpad->{skip_ajust_block_break};
                    $html .=  $self->on_mobile ? $block->mobile(  $self, $self->{inline} , \@items) : $block->get( $self , $self->{inline} , \@items );
                    @items = ();
                    $Text::Livedoor::Wiki::scratchpad->{core}{block_uid}++;
                    $on_processing = 0; 
                }
                next LINE;
            }
        }

        my $text=  $self->inline($_) ;
        if( length $text ) {
            $html .=  $text . qq|<br />\n|;    
        }
        else {
            $html .=  qq|<br />\n|;    
        }
    }
    $on_processing = 0; # in case

    #hoge<br /> <- remove this <br />
    $html =~ s/<br \/>\n$//;

    if( $html && !($html =~ /\n$/) ) {
        $html .= "\n";
    }

    return $html;
}
sub _load {
    my $self = shift;
    my $plugins = shift;
    my $trigger = {};

    for (@$plugins ) {
        $_->require;
        $trigger->{$_} = $_->trigger if $_->trigger;
    }
    $self->{blocks} = $plugins;
    $self->{trigger} = $trigger;
   
}

1;

=head1 NAME

Text::Livedoor::Wiki::Block - Block Parser

=head1 DESCRIPTION

block parser. supporting block has block :-)

=head1 METHOD

=head2 blocks

=head2 footer_section

=head2 inline

=head2 new

=head2 on_mobile

=head2 opts

=head2 parse

=head2 trigger

=head1 AUTHOR

polocky

=cut
