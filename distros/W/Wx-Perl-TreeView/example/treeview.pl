#!/usr/bin/perl -w

use strict;
use lib 'lib';

use Wx qw(:treectrl);
use Wx::Event qw(EVT_MENU);
use Wx::Perl::TreeView;
use Wx::Perl::TreeView::SimpleModel;

my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new( undef, -1, 'Example' );
my @data =
  ( { node   => 'root',
      childs => [ { node   => 'first',
                    childs => [ { node => 'a' }, { node => 'b' } ],
                    },
                  { node   => 'second',
                    childs => [ { node => 'c' }, { node => 'd' } ],
                    },
                  ],
      },
    { node   => 'root',
      childs => [ { node   => '1st',
                    childs => [ { node => '1' }, { node => '2' } ],
                    },
                  { node   => '2nd',
                    childs => [ { node => '3' }, { node => '4' } ],
                    },
                  ],
      },
    );
my $model = Wx::Perl::TreeView::SimpleModel->new( $data[0] );
my $tree = Wx::TreeCtrl->new( $frame, -1, [-1, -1], [-1, -1],
                              wxTR_HAS_BUTTONS | wxTR_HIDE_ROOT );
my $treeview = Wx::Perl::TreeView->new( $tree, $model );

my $index = 0;
my $bar = Wx::MenuBar->new;
my $menu = Wx::Menu->new;
EVT_MENU( $frame, $menu->Append( -1, "Toggle" ),
          sub { $index = ( $index + 1 ) % 2;
                $model->{data} = $data[$index];
                $treeview->refresh;
                } );
$bar->Append( $menu, "Do it" );
$frame->SetMenuBar( $bar );

$frame->Show;
$app->MainLoop;

1;
