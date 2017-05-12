#!/usr/bin/perl -w

use strict;
use lib 'lib';

use Wx qw(:listctrl wxRED wxGREEN);
use Wx::Event qw(EVT_MENU);
use Wx::Perl::ListView;
use Wx::Perl::ListView::SimpleModel;

my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new( undef, -1, 'Example' );
my( $red, $green ) = ( wxRED, wxGREEN );
my @data =
  ( [ [ { string => '(0, 0)', foreground => $red }, { string => '(0, 1)' }, ],
      [ { string => '(1, 0)', foreground => $green }, { string => '(1, 1)' }, ],
      [ { string => '(2, 0)' }, { string => '(2, 1)' }, ],
      [ { string => '(3, 0)' }, { string => '(3, 1)' }, ],
      ],
    [ [ { string => '(a, a)' }, { string => '(a, b)' }, ],
      [ { string => '(b, a)', background => $red }, { string => '(b, b)' }, ],
      [ { string => '(c, a)', foreground => $green }, { string => '(c, b)' }, ],
      [ { string => '(d, a)' }, { string => '(d, b)' }, ],
      ],
    );

my $model = Wx::Perl::ListView::SimpleModel->new( $data[0] );
my $listview = Wx::Perl::ListView->new( $model, $frame );
$listview->InsertColumn( 0, 'First' );
$listview->InsertColumn( 1, 'Second' );
$listview->refresh;

my $index = 0;
my $bar = Wx::MenuBar->new;
my $menu = Wx::Menu->new;
EVT_MENU( $frame, $menu->Append( -1, "Toggle" ),
          sub { $index = ( $index + 1 ) % 2;
                $model->{data} = $data[$index];
                $listview->refresh;
                } );
$bar->Append( $menu, "Do it" );
$frame->SetMenuBar( $bar );

$frame->Show;
$app->MainLoop;

1;
