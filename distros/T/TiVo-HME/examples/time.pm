package time;

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

    $root->set_resource($T_RESOURCE->color(0xff, 0xff, 0xff, 0xff));

    $self->{time}->[0] = $T_VIEW->new(
        x => 0, y => 0, width => $root->width, height => 280,
        visible => 1)->add;

    $self->{time}->[1] = $T_VIEW->new(
        x => 0, y => 0, width => $root->width, height => 280,
        visible => 1)->add;

    my $anim = $T_RESOURCE->animation(750);
    my $font = $T_RESOURCE->font('default', 46, $T_CONST->FONT_BOLD);
    my $black = $T_RESOURCE->color(0x0, 0x0, 0x0, 0xff);

    my $n = 0;
    while (1) {
        $self->{time}->[$n]->transparency(1, $anim);

        # switch views
        $n = ($n + 1) % 2;

        my $text = $T_RESOURCE->text($font, $black, scalar(localtime));

        $self->{time}->[$n]->set_resource($text, $T_CONST->HALIGN_CENTER);
        $self->{time}->[$n]->transparency(0, $anim);

        sleep(1);

    }
}

# listen for 'special' event
sub handle_event {
	my($self, $resource, $key_action, $key_code, $key_rawcode) = @_;

}

1;
