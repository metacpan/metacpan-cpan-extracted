# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl X11-Aosd.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use strict;
use Test::More;

BEGIN {
    if ( $ENV{DISPLAY} eq '' ) {
      plan skip_all => 'No X11 server present (DISPLAY is unset)';
    }
    else {
      plan tests => 17;
    }

    use_ok('X11::Aosd', ':all');
}

my $fail = 0;
foreach my $constname (qw(
	COORDINATE_CENTER COORDINATE_MAXIMUM COORDINATE_MINIMUM
	TRANSPARENCY_COMPOSITE TRANSPARENCY_FAKE TRANSPARENCY_NONE)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined X11::Aosd macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $aosd = X11::Aosd->new;
ok( $aosd->isa("X11::Aosd"), 'new X11::Aosd()');

$aosd->set_name("X11::Aosd example", "foo");
my @name = $aosd->get_name;
ok ($name[0] eq 'X11::Aosd example' && $name[1] eq 'foo', "set_name() && get_name()");

my $trans = $aosd->get_transparency;
ok ( $trans == TRANSPARENCY_NONE || 
     $trans == TRANSPARENCY_FAKE ||
     $trans == TRANSPARENCY_COMPOSITE, "get_transparency()");

$aosd->set_transparency(TRANSPARENCY_NONE);
ok ( $trans == TRANSPARENCY_NONE, "set_transparency()");

$aosd->set_geometry(100,200,300,400);

my @geo = $aosd->get_geometry;
ok ( $geo[0]==100 && $geo[1]==200 && $geo[2]==300 && $geo[3]==400,
     "set_geometry() && get_geometry()");

my @screen = $aosd->get_screen_size;
ok ( $screen[0]>0 && $screen[1]>0, "get_screen_size()");

$aosd->set_position(0, 210, 211);
@geo = $aosd->get_geometry;
ok ( $geo[0]==0 && $geo[1]==0 && $geo[2]==210 && $geo[3]==211,
     "set_position()");

$aosd->set_position_offset(67, 56);
@geo = $aosd->get_geometry;
ok ( $geo[0]==67 && $geo[1]==56 && $geo[2]==210 && $geo[3]==211,
     "set_position_offset()");

my ($rend_cr, $rend_user_data);
my $color = 0;
my $dir = 1;
my $x = 0;
$aosd->set_renderer(sub {
    my ($cr, $user_data) = @_;
    $rend_cr = $cr;
    $rend_user_data = $user_data;
    $color += $dir*0.05;
    if ( $color > 1 ) {
      $color = 1;
      $dir = -1;
    }
    if ( $color < 0 ) {
      $color = 0;
      $dir = 1;
    }
    $aosd->set_position_with_offset(COORDINATE_CENTER, COORDINATE_CENTER, 210, 211, $x++, 0);
    $cr->set_source_rgba ($color, 0, 0, 0.75);
    $cr->rectangle (0, 0, 200, 200);
    $cr->fill;
}, $$);

$aosd->render;

ok ( $rend_cr->isa("Cairo::Context") && $rend_user_data == $$, "set_renderer() && render()");

$aosd->show;
ok ( $aosd->get_is_shown, "show() && get_is_shown()");

$aosd->loop_once;

$aosd->set_mouse_event_cb(sub {
    my ($event, $data) = @_;
    print "mouse click: [$event->{x},$event->{y}] button=$event->{button} data=$data\n";
}, 42);

ok ( eval { $aosd->set_hide_upon_mouse_event(1); 1 }, "set_hide_upon_mouse_event(1)");

my $time = time;
$aosd->loop_for(1200);
ok ( time-$time>0, "loop_for(1200)");

my $main_loop = Glib::MainLoop->new;
my $cnt = 0;
Glib::Timeout->add(
    16,
    sub { $aosd->update; $main_loop->quit if ++$cnt == 100; 1 },
);
$main_loop->run;

ok ($cnt == 100, "run in Glib::MainLoop()");

$aosd->hide;
ok ( !$aosd->get_is_shown, "hide() && !get_is_shown()");

$time = time;
$aosd->flash(200, 800, 200);
ok ( time-$time>0, "flash()");
