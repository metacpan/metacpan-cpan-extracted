package animate;

use 5.008;
use strict;
use warnings;

use TiVo::HME::Application;

our @ISA = qw(TiVo::HME::Application);

our $VERSION = '1.0';

sub init {
	my($self, $context) = @_;

    my $root = $self->get_root_view;
    $root->visible(1);

    $self->{content} = $T_VIEW->new(
        target => $self,
        x => $T_CONST->SAFE_ACTION_H / 2,
        y => $T_CONST->SAFE_ACTION_V / 2,
        width => $root->width - $T_CONST->SAFE_ACTION_H,
        height => $root->height - $T_CONST->SAFE_ACTION_V,
        visible => 1)->add;

    for (my $i = 0; $i < 16; $i++) {
        $self->{sprites}->[$i] = sprite_view->new(
            $self,
            $self->{content},
            $i,
            int(rand($self->{content}->width)),
            int(rand($self->{content}->height)),
            8 + int(rand(64)),
            8 + int(rand(64)));
    }
}

# listen for 'special' event
sub handle_event {
	my($self, $resource, $key_action, $key_code, $key_rawcode) = @_;

    if ($key_code == $T_CONST->KEY_TIVO) {
        $self->{sprites}->[$key_rawcode]->animate;
    }
}

package sprite_view;

our @ISA = qw(TiVo::HME::View);
use TiVo::HME::Application;

sub new {
    my($class, $target, $parent, $index, $x, $y, $width, $height) = @_;

    my $self = $class->SUPER::new(
        target => $target, 
        parent => $parent,
        index => $index,
        x => $x,
        y => $y,
        width => $width,
        height => $height,
        visible => 1)->add;

    my $color = $T_RESOURCE->color(
        int(rand(255)), int(rand(255)), int(rand(255)), 0xff);
    $self->set_resource($color);
    $self->animate;

    $self;
}

sub animate {
    my($self) = @_;

    my $speed = 250 + int(rand(5000));
    my $anim = $T_RESOURCE->animation($speed, 0);

    my $dest_x = int(rand($self->{parent}->width));
    my $dest_y = int(rand($self->{parent}->height));

    $self->bounds($dest_x, $dest_y, $self->width, $self->height, $anim);

    $T_RESOURCE->send_event($self->{target}, 0, 
        $T_RESOURCE->make_key_event(
            $self->{target}, 1, $T_CONST->KEY_TIVO, $self->{index}));
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
