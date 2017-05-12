package Text::Livedoor::Wiki::Plugin::Block::Toggle;

use warnings;
use strict;
use base qw(Text::Livedoor::Wiki::Plugin::Block);

__PACKAGE__->trigger({ start=> '^\[(\+|-)\]' , end  => '^\[END\]$' });

sub check {
    my $class        = shift;
    my $line        = shift;
    my $args        = shift;
    my $on_next     = $args->{on_next};
    my $id          = $args->{id};
    my $inline      = $args->{inline};
    my $scratchpad  = $Text::Livedoor::Wiki::scratchpad;
    my $row;
    my $option_str;
    my $processing = $scratchpad->{block}{$id}{processing};
        
    
    # rule
    # 1. [+]~ or [-]~
    # 2. not starting.
    # 3. this line
    # 4. no child found
    if ((my ( $mark ) = $line =~ /^\[(\+|-)\]/) && !$processing && !$on_next  && !$class->get_child($id) ){
        #XXX    
        $Text::Livedoor::Wiki::scratchpad->{skip_ajust_block_break} = '1';
        
        $scratchpad->{block}{$id}{processing} = 1 ;
        my $toggle =  $mark  eq '+'   ? 'close'  : 'open';
       
        my ( $dummy , $title ) = $line =~ /^\[(\+|-)\](.+)/;
        $title = '' unless defined $title;
        return { id => $id , title => $title , toggle => $toggle };
    }
    # end box
    elsif( !$on_next && $class->trigger_check($id,$line) && $line =~ /^\[END\]$/ && $processing ) {
        $scratchpad->{block}{$id}{processing} = 0;
        return { line => "\n" };
    }
    # finnalize
    elsif( $on_next && !$processing ) {
        return;
    }
    # processing
    elsif( $processing ) {
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
    my $box = $meta->{box};
    my $class_name = $meta->{class_name};
    my $id         = $meta->{id};
    my $title      = $meta->{title};
    $title = $inline->parse($title);

    # END LINE
    if ( scalar @$items ) { # in case there is no line in $items
        pop @$items if $items->[-1]{line} eq "\n";
    }

    my $html = '';
    $html .= $_->{line}  . "\n" for @$items;
    $html =~ s/\n$//;
    my $save_skip_catalog = $Text::Livedoor::Wiki::opts->{skip_catalog} || 0 ;
    $Text::Livedoor::Wiki::opts->{skip_catalog} = 1;
    $html = $block->parse( $html , 1) ;
    $Text::Livedoor::Wiki::opts->{skip_catalog} = $save_skip_catalog ;

    my $spacer_image = $class->opts->{storage} . '/images/common/spacer.gif';


    #return qq|<toggle-$id>\n$html</toggle-$id>\n|;
    my $id_inside = "$id-inside";
    my $id_label  = "$id-label";
    my $label_class =  $meta->{toggle} eq 'open' ? 'toggle-link-close': 'toggle-link-open';
    my $js = qq|if( document.getElementById('$id_inside').style.display =='none' ) {  document.getElementById('$id_inside').style.display ='block' ; document.getElementById('$id_label').className = 'toggle-link-close'; } else {  document.getElementById('$id_inside').style.display ='none';document.getElementById('$id_label').className = 'toggle-link-open'; } ;|;
    my $button = qq|<div class="toggle-title"><a id="$id-label" onClick="$js" class="$label_class"><img src="$spacer_image" width="17" height="17" alt="" /></a><p>$title</p></div>\n|;

    if( $meta->{toggle} eq 'open' ){ 
        $html= qq|$button<div id="$id_inside" class="toggle-display">\n$html</div>\n|;
    }
    else {
        $html= qq|$button<div style="display:none" id="$id_inside" class="toggle-display">\n$html</div>\n|;
    }

    return qq|<div id="$id">\n$html</div>\n|;
}

sub mobile {
    my $class = shift;
    my $block = shift;
    my $inline = shift;
    my $items = shift;
    my $meta = shift @{$items};
    my $box = $meta->{box};
    my $class_name = $meta->{class_name};
    my $id         = $meta->{id};
    my $title      = $meta->{title};
    $title = $inline->parse($title);

    # END LINE
    if ( scalar @$items ) {
        pop @$items if $items->[-1]{line} eq "\n";
    }

    my $html = '';
    $html .= $_->{line}  . "\n" for @$items;
    $html =~ s/\n$//;
    my $save_skip_catalog = $Text::Livedoor::Wiki::opts->{skip_catalog} || 0 ;
    $Text::Livedoor::Wiki::opts->{skip_catalog} = 1;
    $html = $block->parse( $html , 1) ;
    $Text::Livedoor::Wiki::opts->{skip_catalog} = $save_skip_catalog ;

    return qq|<div id="$id">\n$title<br />\n$html</div>\n|;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Block::Toggle - Toggle Block Plugin

=head1 DESCRIPTION

you can open and close block with this.

=head1 SYNOPSIS

 [+]''you can open me!''
 - item
 - item
 [END]
 [-]''you can close me!''
 * title
 hoge hoge
 hoge hoge
 [END]

=head1 FUNCTION

=head2 check

=head2 get

=head2 mobile

=head1 AUTHOR

polocky

=cut
