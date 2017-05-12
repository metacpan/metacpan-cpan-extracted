#############################################################################
## Name:        lib/Wx/DemoModules/wxGridER.pm
## Purpose:     wxPerl demo helper for wxGrid editors and renderers
## Author:      Mattia Barbon
## Modified by:
## Created:     05/06/2003
## RCS-ID:      $Id: wxGridER.pm 2378 2008-04-26 04:21:45Z mdootson $
## Copyright:   (c) 2003, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxGridER;

use strict;
use base 'Wx::Grid';

my $longtext = join ' ', qw(Multiple lines of text are displayed
                            wrapped in the cell. AutoSize is set on to
                            display the contents);
my @editors_renderers =
  ( [ 'Default editor and renderer', 'Test 1', undef ],
    [ 'Float editor', '1.00', sub { Wx::GridCellFloatEditor->new },
      'Float renderer', '2.13', sub { Wx::GridCellFloatRenderer->new( 12, 7 ) },
      ],
    [ 'Bool editor', '1', sub { Wx::GridCellBoolEditor->new },
      'Bool renderer', '1', sub { Wx::GridCellBoolRenderer->new },
      ],
    [ 'Number editor', '14', sub { Wx::GridCellNumberEditor->new( 12, 20 ) },
      'Number renderer', '12', sub { Wx::GridCellNumberRenderer->new },
      ],
    [ 'Choice editor', 'Test', sub { Wx::GridCellChoiceEditor->new( [qw(This Is a Test) ] ) },
      ],
    [ 'Auto Wrap editor', $longtext, sub { Wx::GridCellAutoWrapStringEditor->new },
      'Auto Wrap renderer', $longtext, sub { Wx::GridCellAutoWrapStringRenderer->new },
      ],
    [ 'Enum editor', 2, sub { Wx::GridCellEnumEditor->new( 'First,Second,Third,Fourth,Fifth' ) },
      # unluckily Enum renderer requires a custom grid table to work
      ],
    );

sub new {
  my( $class, $parent ) = @_;
  my $this = $class->SUPER::new( $parent, -1 );
  
  $this->CreateGrid( 2 * @editors_renderers + 1, 7 );
  
  # set every cell read-only
  for my $x ( 1 .. $this->GetNumberCols ) { # cols
    for my $y ( 1 .. $this->GetNumberRows ) { # rows
      $this->SetReadOnly( $y, $x, 1 ); # rows, cols
    }
  }

  $this->SetColSize( 0, 20 );
  $this->SetColSize( 1, 150 );
  $this->SetColSize( 2, 150 );
  $this->SetColSize( 3, 20 );
  $this->SetColSize( 4, 150 );
  $this->SetColSize( 5, 100 );
  $this->SetColSize( 6, 20 );

  my $row = 1;
  foreach my $er ( @editors_renderers ) {
    if( $er->[0] ) {
      eval {
          $this->SetCellEditor( $row, 2, &{$er->[2]} ) if $er->[2];
          $this->SetCellOverflow( $row, 2, 0);
          $this->SetCellValue( $row, 1, $er->[0] );
          $this->SetCellValue( $row, 2, $er->[1] );
          $this->SetReadOnly( $row, 2, 0 );
      };
    }
    if( $er->[3] ) {
      eval {
          $this->SetCellRenderer( $row, 5, &{$er->[5]} ) if $er->[5];
          $this->SetCellOverflow( $row, 5, 0);
          $this->SetCellValue( $row, 4, $er->[3] );
          $this->SetCellValue( $row, 5, $er->[4] );
          $this->SetReadOnly( $row, 5, 0 );
      };
    }
    $this->AutoSizeRow( $row, 1 );
    $row += 2;
  }

  return $this;
}

sub add_to_tags { 'controls/grid' }
sub title { 'Editors and renderers' }

1;
