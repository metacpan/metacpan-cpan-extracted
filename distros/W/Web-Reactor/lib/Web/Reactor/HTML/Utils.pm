##############################################################################
##
##  Web::Reactor application machinery
##  Copyright (c) 2013-2022 Vladi Belperchinov-Shabanski "Cade"
##        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
##  http://cade.noxrun.com
##  
##  LICENSE: GPLv2
##  https://github.com/cade-vs/perl-web-reactor
##
##############################################################################
##
## HTML Utils
##
## All checks and escaping is done accordingly to HTML Living standard from
## 5 September 2022, chapter notes are given in the comments
## https://html.spec.whatwg.org/multipage/
##
##############################################################################
package Web::Reactor::HTML::Utils;
use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
                html_escape

                html_element
                html_table

                html_ftree

                html_hover_layer
                html_popup_layer

                html_alink

                html_tabs_table
                
                html_check_tag_name
                html_check_tag_name_boom
                
                html_check_attr_name
                html_check_attr_name_boom
                
                );
use strict;
use Exception::Sink;
use Data::Tools;
use Web::Reactor::HTML::Tab;
use Web::Reactor::HTML::Layout;

##############################################################################

sub html_escape
{
  return Data::Tools::str_html_escape( @_ );
}

##############################################################################

sub html_element
{
  my $tag = shift;
  my $txt = shift;
  my %atr = @_;

  hash_lc_ipl( \%atr );
  
  my $extra = $atr{ 'extra' };
  delete $atr{ 'extra' };

  html_check_tag_name_boom( $tag );
  
  my $html;
  
  $html .= "<$tag ";
  
  while( my ( $k, $v ) = each %atr )
    {
    html_check_attr_name_boom( $k, "invalid attribute name [$k] for tag [$tag]" );
    $html .= $k;
    if( defined $v )
      {
      my $vv = str_html_escape_attr( $v );
      $html .= "='$vv'";
      }
    $html .= " ";
    }
  
  $html .= $extra;
  $html .= defined $txt ? ">$txt</$tag>" : "/>";

use Data::Dumper;
print STDERR Dumper( "\n"x10, $tag, $txt, \%atr, $html, "\n"x100 );
  
  return $html . "\n";
}

##############################################################################

=pod

flat tree, represented by single table with rows

DEMO:

  my $a = [
          'opa',
          'tralala',
          'heyo',
          'yoyo',
          'didi',
          {
          LABEL => 'opa',
          DATA  => [
                     'tralala',
                     'heyo',
                     {
                     LABEL => 'sesssil',
                     DATA  => [
                              'tralala',
                              'heyo',
                              'yoyo',
                              'didi',
                              ],
                     },
                     'yoyo',
                     'didi',
                     ],
          },
          'heyo',
          'yoyo',
          ];

  print html_ftree( $a, 'ARGS' => 'cellpadding=10 width=100% border=0' );

=cut

my $ftree_item_id;
sub html_ftree
{
  my $data = shift;
  my %opt  = @_;

  my $t_args;
  $t_args ||= $opt{ 'ARGS' };
  $t_args ||= 'class=' . $opt{ 'CLASS' } if $opt{ 'CLASS' };

  $ftree_item_id++;

  my $ftree_table_id = "FTREE_TABLE_$ftree_item_id";

  my $html;

  $html .= "\n";
  $html .= "<table id=$ftree_table_id $t_args>";

  $html .= __html_ftree_branch( $data, $ftree_table_id, $ftree_table_id . '.', 0, \%opt );

  $html .= "</table>";
  $html .= "\n";

  return $html;
}

sub __html_ftree_branch
{
  my $data           = shift;
  my $ftree_table_id = shift;
  my $branch_id      = shift;
  my $level          = shift;
  my $opt            = shift;

  my $html;

  $html .= "\n";

  for my $row ( @$data )
    {
    my $label;
    my $data;

    my $r_args; # row  args
    my $c_args; # cell args

    if( ref( $row ) eq 'HASH' )
      {
      $label = $row->{ 'LABEL' };
      $data  = $row->{ 'DATA'  };

      $r_args ||= $row->{ 'ARGS' };
      $r_args ||= 'class=' . $row->{ 'CLASS' } if $row->{ 'CLASS' };
      }
    else
      {
      $label = $row;
      }

    $r_args ||= $opt->{ 'ARGS_TR' };
    $c_args ||= $opt->{ 'ARGS_TD' };
 
    $ftree_item_id++;

    my $row_id = $branch_id . $ftree_item_id . '.';

    # $label = "($row_id) $label"; # DEBUG

    my $hidden = $level > 0 ? "style='display: none'" : undef;
    my $pad = $level * 6 + 1;
    my $cell = html_layout_2lr( '&nbsp;', $label, "$pad=<" );

    if( ref( $data ) eq 'ARRAY' )
      {
      my $open_code = qq{ onclick='ftree_click( "$ftree_table_id", "$row_id" )' };
      $html .= "<tr id=$row_id $open_code $r_args $hidden><td $c_args>$cell</td></tr>";
      $html .= __html_ftree_branch( $data, $ftree_table_id, $row_id, $level + 1, $opt );
      }
    else
      {
      $html .= "<tr id=$row_id $hidden $r_args><td $c_args>$cell</td></tr>";
      }

    $html .= "\n";
    }

  return $html;
}

##############################################################################

sub html_hover_layer
{
  my $reo = shift;
  my %opt  = @_;

  if( ref( $reo ) !~ /^Web::Reactor(::|$)/ )
    {
    boom "missing REO reactor object";
    }

  if( @_ == 1 )
    {
    %opt = ( VALUE => shift() );
    }

  my $value = $opt{ 'VALUE' };
  my $class = $opt{ 'CLASS' } || 'hover-layer';
  my $delay = $opt{ 'DELAY' } || 250;

  my $hover_layer_counter = $reo->create_uniq_id();
  my $hover_layer_id = "R_HOVER_LAYER_$hover_layer_counter";

  my $html;
  my $handle;

  $handle = qq{ onmouseover='reactor_hover_show_delay( this,"$hover_layer_id", $delay, event )' };
  $html   = qq{ <div class='$class' id="$hover_layer_id">$value</div> };

  if ( wantarray )
    {
    # will not use ACCUMULATOR_HTML
    return ( $handle, $html );
    }
  else
    {
    $reo->html_content_accumulator( 'ACCUMULATOR_HTML', $html );
    return $handle;
    }
}

##############################################################################

sub html_popup_layer
{
  my $reo = shift;
  my %opt  = @_;

  if( ref( $reo ) !~ /^Web::Reactor(::|$)/ )
    {
    boom "missing REO reactor object";
    }

  if( @_ == 1 )
    {
    %opt = ( VALUE => shift() );
    }

  my $value  = $opt{ 'VALUE'  };
  my $class  = $opt{ 'CLASS'  } || 'popup-layer';
  my $delay  = $opt{ 'DELAY'  } || 150;
  my $type   = $opt{ 'TYPE'   } || 'CLICK';

  $delay = 0 unless $delay > 0;

  my $trigger;
  if( $type eq 'CONTEXT' )  
    {
    $trigger = qq( onContextMenu="return reactor_popup_mouse_over( this )" );
    }
  else # ( $type eq 'CLICK' )  
    {
    $trigger = qq( onClick="return reactor_popup_mouse_over( this, { click_open: 1 } )" );
    }  

  my $popup_layer_id_counter = $reo->create_uniq_id();
  my $popup_layer_id = "R_POPUP_LAYER_$popup_layer_id_counter";

  my $handle  = qq( $trigger data-popup-layer-id="$popup_layer_id" );
  my $html    = qq( <div class='$class' id="$popup_layer_id">$value</div> );

  if ( wantarray )
    {
    # will not use ACCUMULATOR_HTML
    return ( $handle, $html );
    }
  else
    {
    $reo->html_content_accumulator( 'ACCUMULATOR_HTML', $html );
    return $handle;
    }
}

##############################################################################

sub html_alink
{
  my $reo   =    shift;
  my $type  = lc shift;
  my $value =    shift;
  my $opts  =    shift; # hashref with alink options
  my @args  = @_;

  my $href = $reo->args_type( $type, @args );

  my $tag_args;

  my $tag_id = $opts->{ 'ID' };

  my $class = $opts->{ 'CLASS' };
  my $hint = $opts->{ 'HINT' };
  
  my $confirm = $opts->{ 'CONFIRM' };
  $tag_args .= '  ' . qq( onclick="return confirm('$confirm');" ) if $confirm =~ /^([^"']+)$/;
  
  if( $opts->{ 'DISABLED' } )
    {
    $tag_args .= '  ' . qq( onclick="return false;" ) ;
    $class .= " disabled-button";
    $hint = undef; # remove button hints for disabled buttons
    }

  $tag_args .= '  ' . "ID='$tag_id'";
  $tag_args .= '  ' . "class='$class'";
  if( $hint )
    {
    my $hint_tag_arg = html_hover_layer( $reo, VALUE => $hint, DELAY => 1000 );
    $tag_args  .= '  ' . $hint_tag_arg;
    }

  # FIXME: FIX REACTOR TO HAVE SENSIBLE HTML_LINK FUNCTIONS, I.E. CONVERT HINT TO HASHREF!
  my $disable_on_click = int( $opts->{ 'DISABLE_ON_CLICK' } );
  if( $confirm !~ /^([^"']+)$/ and $disable_on_click > 0 )
    {
    my $class_off = $opts->{ 'DISABLE_ON_CLICK_CLASS' };
    $tag_args .= '  ' . "data-class-on='$class' data-class-off='$class_off'";
    $tag_args .= '  ' . qq( onclick="return reactor_element_disable_on_click( this, $disable_on_click );" );
    }

  return "<a href=?_=$href $tag_args>$value</a>";
}

##############################################################################

=pod

sub html_tabs_table

arguments: array_ref, opt_hash

array_ref is list of hash refs with this content:

    LABEL          -- label text for the this tab handle
    LABEL_TD_ARGS  -- further optional arguments for the label TD
    TEXT           -- text to show when tab handle clicked
    TEXT_TD_ARGS   -- TD element args, same as above
    ON             -- if true, this tab will be initially visible
    TAB_ID         -- html id for this tab

opt_hash is inline with the following items:

    LABELS_TABLE_ARGS -- args for the table containing labels
    TEXT_TABLE_ARGS   -- same as above

    LABEL_CLASS_ON    -- active TD class for tab handle labels
    LABEL_CLASS_OFF   -- inactive TD class for tab handle labels

    ARGS              -- args for containing TABLE element
    VERTICAL          -- if true, tabs will be vertical

    ACTIVE_TAB_FORM_FEEDBACK_ID -- html INPUT element to hold active tab id

example:

  my @tabs;

  for my $z ( 1 .. 5 )
    {
    push @tabs, {
                  LABEL         => "TAB $z",
                  TEXT          => "$z " x 128,
                  LABEL_TD_ARGS => "class=tab-label style='cursor: pointer;'",
                  TEXT_TD_ARGS  => "class=tab-text",
                };
    }

  $html = html_tabs_table( \@tabs, ARGS => "width=70% border=2", VERTICAL => 1 );

=cut

sub html_tabs_table
{
  my $reo = shift;
  my $ar  = shift;
  my %opt = @_;

  my $vert = $opt{ 'VERTICAL' };

  my @label_td;
  my @text_td;

  my $cnt = @$ar;

  my $class_on  = $opt{ 'LABEL_CLASS_ON' };
  my $class_off = $opt{ 'LABEL_CLASS_OFF' };

  my $tab = new Web::Reactor::HTML::Tab(
                                   REO_REACTOR => $reo,
                                   CLASS_ON    => $class_on,
                                   CLASS_OFF   => $class_off,
                                   ACTIVE_TAB_FORM_FEEDBACK_ID => $opt{ 'ACTIVE_TAB_FORM_FEEDBACK_ID' },
                                 );

  for my $e ( @$ar )
    {
    my $label      = $e->{ 'LABEL'         };
    my $label_args = $e->{ 'LABEL_TD_ARGS' };
    my $text       = $e->{ 'TEXT'          };
    my $text_args  = $e->{ 'TEXT_TD_ARGS'  };
    my $on         = $e->{ 'ON'            };
    my $tab_id     = $e->{ 'TAB_ID'        };

    if( ! $vert and $label_args !~ /WIDTH=/i )
      {
      my $w = int( 100 / $cnt );
      $label_args .= " WIDTH=$w%";
      }

    my ( $tab_handle, $tab_html ) = $tab->add( "<TD $text_args>$text</td>", TYPE => 'TR', ON => $on, TAB_ID => $tab_id );

    push @label_td, "<TD $label_args $tab_handle>$label</TD>";
    push @text_td,  $tab_html;
    }
  $tab->finish();

  my $args  = $opt{ 'ARGS' };

  my $text;

  $text .= "<TABLE $args>\n";
  if( $vert )
    {
    my $label_args  = $opt{ 'VERT_LABEL_TD_ARGS' };
    my $text_args   = $opt{ 'VERT_TEXT_TD_ARGS' };

    $label_args .= " WIDTH=50%" if $label_args !~ /WIDTH=/i;

    $text .= "<TR>";
    $text .= "<TD $label_args><TABLE WIDTH=100%>";
    $text .= "<TR>" . join( "</TR><TR>", @label_td ) . "</TR>";
    $text .= "</TABLE></TD>";

    $text .= "<TD $text_args><TABLE WIDTH=100%>";
    $text .= join( '', @text_td );
    $text .= "</TABLE></TD>";

    $text .= "</TR>";
    }
  else
    {
    my $labels_table_args = $opt{ 'LABELS_TABLE_ARGS' };
    $labels_table_args .= " WIDTH=100%" if $labels_table_args !~ /WIDTH=/i;
    $text .= "<TR><TD><TABLE $labels_table_args><TR>" . join( '', @label_td ) . "</TR></TABLE></TD></TR>";
    $text .= join( '', @text_td );
    }
  $text .= "</TABLE>\n";


  return $text;
}

##############################################################################

sub html_check_tag_name
{
  return $_[0] =~ /^[a-zA-Z0-9]+$/; # $13.1.2.1
}                                             

sub html_check_tag_name_boom
{
  boom( $_[1] || "invalid tag name [$_[0]]" ) unless html_check_tag_name( $_[0] );
}

sub html_check_attr_name
{
  return $_[0] =~ /^[a-zA-Z_0-9\:\-]+$/; # $13.1.2.3 but extra strict
}                                             

sub html_check_attr_name_boom
{
  boom( $_[1] || "invalid attribute name [$_[0]]" ) unless html_check_attr_name( $_[0] );
}

##############################################################################
1;
##############################################################################

