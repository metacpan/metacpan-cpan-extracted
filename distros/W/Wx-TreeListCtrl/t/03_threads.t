#!/usr/bin/perl -w

use strict;
use Config;
use if !$Config{useithreads} => 'Test::More' => skip_all => 'no threads';
use threads;
use Wx;
use Wx::TreeListCtrl;
use Wx qw(:everything);
use if !Wx::wxTHREADS(), 'Test::More' => skip_all => 'No thread support';
use Test::More tests => 8;
use Wx::Event qw(EVT_BUTTON);


Wx::InitAllImageHandlers;

my @tocheck;
sub check_init(&) {
    my( $code ) = @_;
    push @tocheck, [ $code->(), $code->() ];
}

sub check_undef {
    $_->[1] = undef foreach @tocheck;
}

my $app = Wx::App->new( sub { 1 } );
my $frame = Wx::Frame->new( undef, -1, 'Test frame' );

EVT_BUTTON( $app, -1,
            sub {
                my $t = threads->create
                  ( sub {
                        ok( 1, 'In event thread' );
                    } );
                ok( 1, 'Before event join' );
                $t->join;
                ok( 1, 'After event join' );
            } );

check_init { Wx::TreeListColumnInfo->new('Column 1')};

my $ctrl1 = Wx::TreeListCtrl->new($frame, wxID_ANY, wxDefaultPosition, wxDefaultSize, 0);
my $ctrl2 = Wx::TreeListCtrl->new($frame, wxID_ANY, wxDefaultPosition, wxDefaultSize, 0);

my $info1 = Wx::TreeListColumnInfo->new('Column Info 1');
my $info2 = Wx::TreeListColumnInfo->new('Column Info 2');

$ctrl1->AddColumn('Added Col 1');
$ctrl2->AddColumn('Added Col 2');

my $info3 = $ctrl1->GetColumn(1);
my $info4 = $ctrl2->GetColumn(1);

$ctrl1->AddColumn($info4);
$ctrl2->AddColumn($info3);

undef $info3;
undef $info1;
undef $ctrl1;


check_undef;
my $t = threads->create
  ( sub {
        ok( 1, 'In thread' );
    } );
ok( 1, 'Before join' );
$t->join;
ok( 1, 'After join' );

my $evt2 = Wx::CommandEvent->new( wxEVT_COMMAND_BUTTON_CLICKED, 123 );
undef $evt2;
$app->ProcessEvent
  ( Wx::CommandEvent->new( wxEVT_COMMAND_BUTTON_CLICKED, 123 ) );
ok( 1, 'After event' );

END { ok( 1, 'At END' ) };
