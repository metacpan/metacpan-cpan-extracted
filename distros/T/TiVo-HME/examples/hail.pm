package hail;

use 5.008;
use strict;
use warnings;

use TiVo::HME::Application;

our @ISA = qw(TiVo::HME::Application);

our $VERSION = '1.0';

# Preloaded methods go here.
sub new {
	my($class) = @_;
	bless {}, $class;
}

sub init {
	my($self, $context) = @_;

    # play some default sounds
	$TiVo::HME::Resource::DEFAULT_RESOURCES[$T_CONST->ID_BONK_SOUND]->set_speed(1);
	sleep(1);
	$TiVo::HME::Resource::DEFAULT_RESOURCES[$T_CONST->ID_ALERT_SOUND]->set_speed(1);
	sleep(1);
	$TiVo::HME::Resource::DEFAULT_RESOURCES[$T_CONST->ID_TIVO_SOUND]->set_speed(1);
	sleep(1);
	$TiVo::HME::Resource::DEFAULT_RESOURCES[$T_CONST->ID_SPEEDUP3_SOUND]->set_speed(1);
	sleep(1);

	my $anim = $T_RESOURCE->animation(5000, 0);
	# color = r,g,b,alpha
	my $white_color = $T_RESOURCE->color(0xff, 0xff, 0xff, 0xff);
	my $font = $T_RESOURCE->font('default', 25, $T_CONST->FONT_BOLD);
	my $text = $T_RESOURCE->text($font, $white_color, 'mark rox');

	my $view = $T_VIEW->new(
		x => 0,
		y => 0,
		width => 640,
		height => 480,
		visible => 1);
	$view->add;
	my $image = $T_RESOURCE->image_file('examples/tivo.png');

	# make root view visible (invisible by default)
	$self->get_root_view->visible(1);
	$view->set_resource($text, 
			$T_CONST->HALIGN_CENTER | $T_CONST->VALIGN_CENTER);
	#$view->set_resource($image, $T_CONST->HALIGN_CENTER);
	$view->bounds(50,50,590,430,$anim);
	$view->scale(10.0, 10.0, ,$anim);

	$self->{view} = $view;
}

sub handle_event {
	my($self, $resource, $key_action, $key_code, $key_rawcode) = @_;
	print "EEVENT on $resource: $key_action $key_code $key_rawcode\n";
	my $white_color = $T_RESOURCE->color(0xff, 0xff, 0xff, 0xff);
	my $font = $T_RESOURCE->font('default', 25, $T_CONST->FONT_BOLD);
	my $text = $T_RESOURCE->text($font, $white_color, 'mark rulez');
	$self->{view}->scale(1.0, 1.0);
	$self->{view}->bounds(-50,-50,640,480);
	$self->{view}->set_resource($text, 
			$T_CONST->HALIGN_CENTER | $T_CONST->VALIGN_CENTER);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
