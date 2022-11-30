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
## HTML Layout
##
##############################################################################
package Web::Reactor::HTML::Layout;
use strict;

use Exception::Sink;
use Data::Tools;
use Web::Reactor::HTML::Utils;

use Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw( 

                html_table

                html_layout_grid
                html_layout_hbox
                html_layout_vbox

                html_layout_hbox_flex

                html_layout_2lr
                html_layout_2lr_flex

                );

### LAYOUT ###################################################################

=pod

takes two-dimensional perl array and formats it in html table

DEMO:

  my @data;

  push @data, [
              '123',
              { ARGS => 'align=right', DATA => 'asd' },
              'qwe'
              ];
  push @data, {
                CLASS => 'grid',
                DATA => [
                        '123',
                        { ARGS  => 'align=center', DATA => 'asd' },
                        { CLASS => 'fmt-img',      DATA => 'qwe' },
                        ],
              };
  push @data, {
              # columns class list (CCL), used only for current row
              # use PCCL for permanent (for the rest of the rows)
              CCL  => [ 'view-name-h', 'view-value-h' ],
              DATA => [ 'name',        'value'        ],
              };
  push @data, {
              PCCL  => [ 'view-name-h', 'view-value-h' ],
              # set only PCCL and skip this row
              SKIP  => YES,
              };

  $text .= html_table( \@data, ARGS => 'width=100%' );

=cut


sub html_table
{
  my $rows = shift;
  my %opt  = @_;

  hash_uc_ipl( \%opt );

  # t_* table attr
  # r_* row   attr
  # c_* cell  attr

  my $t_args;
  $t_args ||= $opt{ 'ARGS' };
  $t_args ||= 'class=' . $opt{ 'CLASS' } if $opt{ 'CLASS' };

  my $tr1 = $opt{ 'TR1' } || $opt{ 'TR-1' } || 'tr-1';
  my $tr2 = $opt{ 'TR2' } || $opt{ 'TR-2' } || 'tr-2';
  my $trh = $opt{ 'TRH' };
  my $tdh = $opt{ 'TDH' };

  my $ccl  = $opt{ 'CCL'  } || undef;
  my $pccl = $opt{ 'PCCL' } || undef;

  my $t_cmt = $opt{ 'COMMENT' };

  my $text;
  $text .= "\n\n\n";
  $text .= "<!--- BEGIN TABLE: $t_cmt --->\n" if $t_cmt;
  $text .= "<table $t_args>\n<tbody>\n";

  my $r_class = $tr1;

  my $row_num = 0;
  for my $row ( @$rows )
    {
    my $cols;
    $r_class = $r_class eq $tr1 ? $tr2 : $tr1;
    my $r_args;

    $r_class = $trh if $trh and $row_num == 0;

    if ( ! ref( $row ) ) # SCALAR
      {
      # fallback
      $row = [ $row ];
      }

    if ( ref( $row ) eq 'ARRAY' )
      {
      $cols  = $row;
      $r_args = "class='$r_class'";
      }
    elsif ( ref( $row ) eq 'HASH' )
      {
      $row      = hash_uc( $row );
      $cols     = $row->{ 'DATA' };
      $r_args ||= $row->{ 'ARGS' };
      $r_args ||= 'class=' . ( $row->{ 'CLASS' } || $r_class );
      $ccl      = $row->{ 'CCL'  } if $row->{ 'CCL'  };
      $pccl     = $row->{ 'PCCL' } if $row->{ 'PCCL' };

      next if $row->{ 'SKIP' };
      }
    else
      {
      boom "invalid row type, expected HASH or ARRAY reference";
      next;
      }

    $text  .= "  <tr $r_args>\n";

    $ccl = $pccl if $pccl and ! $ccl; # use permanent cols class list if permanent specified and not local one

    my $col_num = 0;
    for my $cell ( @$cols )
      {
      my $c_class;
      my $c_args;
      my $val;

      $c_class = $tdh if $tdh and $row_num == 0;
      $c_class = $ccl->[ $col_num ] if $ccl and $ccl->[ $col_num ];

      if ( ! ref( $cell ) ) # SCALAR
        {
        $val = $cell;
        }
      elsif( ref( $cell ) eq 'HASH' )
        {
        $cell    = hash_uc( $cell );
        $val     = $cell->{ 'DATA' };
        $c_args  = $cell->{ 'ARGS' };
        $c_args .= " class='" . $cell->{ 'CLASS' } . "'" if $cell->{ 'CLASS' };
        $c_args .= " width='" . $cell->{ 'WIDTH' } . "'" if $cell->{ 'WIDTH' };
        }
      else
        {
        # FIXME: carp croak boom :)
        next;
        }

      $c_args ||= "class='" . $c_class . "'";
      $text .= "    <td $c_args>$val</td>\n";
      $col_num++;
      }

    $ccl = undef;

    $text  .= "  </tr>\n";
    $row_num++;
    }

  $text .= "</tbody>\n</table>\n";
  $text .= "<!--- END TABLE: $t_cmt --->\n" if $t_cmt;
  $text .= "\n\n\n";

  return $text;
}

##############################################################################

sub html_layout_grid
{
  my $data = shift;
  
  my $text;
  
  $text .= "<table border=0 cellspacing=0 cellpadding=0 width=100%>";

  for my $row ( @$data )
    {
    my $row_args;
    if( ref( $row ) eq 'HASH' )
      {
      $row_args = $row->{ 'ARGS' };
      $row      = $row->{ 'DATA' };
      }
    
    $text .= "<tr $row_args>";
    for my $col ( @$row )
      {
      my $col_args;
      if( ref( $row ) eq 'HASH' )
        {
        $col_args = $col->{ 'ARGS' };
        $col      = $col->{ 'DATA' };
        }
      $text .= "<td $col_args>$col</td>";
      }
    $text .= "</tr>";
    }
  
  $text .= "</table>";
  
  return $text;
}

sub html_layout_hbox
{
  my $data = shift;
  
  return html_layout_grid( [ { DATA => $data, ARGS => "valign=top" } ] );
}

sub html_layout_vbox
{
  my $data = shift;
  
  my @data;
  push @data, [ $_ ] for @$data;

  return html_layout_grid( \@data );
}

sub html_layout_hbox_flex
{
  my $opt = ${ shift() } if ref( $_[0] ) eq 'SCALAR';
  my @data = @_;
  
  my @opt = split /,/, $opt;
  
  my $text;
  
  $text .= "<div style='display: flex; border: solid 1px #f00;'>";
  
  while( @data )
    {
    my $data = shift @data;
    my $opt  = shift @opt || 1;
    $text .= "<div style='flex:$opt; border: solid 2px #0f0;'>$data</div>";
    }
  
  $text .= "</div>";
  
  return $text;
}

sub html_layout_vbox
{
  my $data = shift;
  
  my @data;
  push @data, [ $_ ] for @$data;

  return html_layout_grid( \@data );
}

#-----------------------------------------------------------------------------

=pod

formats pair for left/right boxes aligned within specific width

format is: 'left-spec=right-spec'

left-spec  is formatting for the left data.
right-spec is formatting for the right data.

both specs are:

align-symbol . width-len%

examples:

<50%=50%>   -- left is left aligned, right is right aligned, equal length
<=>         -- the same
>20=>       -- left is right aligned, 20% width, right is right aligned, 80% 
=1%         -- same as <99=1> or <99%=1%>

using '==' instead of '=' enables no-word-wrap style

=cut

sub html_layout_2lr
{
  my $ld = shift; # left data
  my $rd = shift; # right data
  my $fm = shift || '<=>'; # format: '[<>]nn%=nn%[<>]'
  
  my $la; # left  align
  my $ra; # right align
  my $lw; # left  width
  my $rw; # right width
  my $nw; # no-wrap
  if( $fm =~ /^([<>]?)((\d+)%?)?=(=)?((\d+)%?)?([<>]?)$/ )
    {
    $la = $1;
    $lw = $3;
    $nw = $4;
    $rw = $6;
    $ra = $7;
    }
  else
    {
    boom "invalid format [$fm]";
    }  
  
  $la = { '<' => 'align=left', '>' => 'align=right' }->{ $la };
  $ra = { '<' => 'align=left', '>' => 'align=right' }->{ $ra };

  $lw = $rw = 50 if $lw == 0 and $rw == 0;
  $lw = int( 100 - $rw ) if $lw == 0 and $rw > 0;
  $rw = int( 100 - $lw ) if $rw == 0 and $lw > 0;
  
  $lw = "width=$lw%";
  $rw = "width=$rw%";

  $nw = "style='white-space: nowrap'" if $nw;

  return "<table width=100% cellspacing=0 cellpadding=0 border=0 $nw><tr><td $la $lw>$ld</td><td $ra $rw>$rd</td></tr></table>";
}

sub html_layout_2lr_flex
{
  my $ld = shift; # left data
  my $rd = shift; # right data
  my $fm = shift || '<=>'; # format: '[<>]nn%=nn%[<>]'

  return "<div style='display: flex;'><div style='flex: 99; text-align: left;'>$ld</div><div style='flex: 1; text-align: right; white-space: nowrap;'>$rd</div></div>";
  
  my $la; # left  align
  my $ra; # right align
  my $lw; # left  width
  my $rw; # right width
  my $nw; # no-wrap
  if( $fm =~ /^([<>]?)((\d+)%?)?=(=)?((\d+)%?)?([<>]?)$/ )
    {
    $la = $1;
    $lw = $3;
    $nw = $4;
    $rw = $6;
    $ra = $7;
    }
  else
    {
    boom "invalid format [$fm]";
    }  
  
  $la = { '<' => 'align=left', '>' => 'align=right' }->{ $la };
  $ra = { '<' => 'align=left', '>' => 'align=right' }->{ $ra };

  $lw = $rw = 50 if $lw == 0 and $rw == 0;
  $lw = int( 100 - $rw ) if $lw == 0 and $rw > 0;
  $rw = int( 100 - $lw ) if $rw == 0 and $lw > 0;
  
  $lw = "width=$lw%";
  $rw = "width=$rw%";

  $nw = "style='white-space: nowrap'" if $nw;

  return "<table width=100% cellspacing=0 cellpadding=0 border=0 $nw><tr><td $la $lw>$ld</td><td $ra $rw>$rd</td></tr></table>";
}

### EOF ######################################################################
1;
