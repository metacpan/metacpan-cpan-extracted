package video_background;

use 5.008;
use strict;
use warnings;

use TiVo::HME::Application;

our @ISA = qw(TiVo::HME::Application);

our $VERSION = '1.0';

sub init {
	my($self, $context) = @_;

    $self->get_root_view->visible(1);

    my $mpg =  $T_RESOURCE->image_file('examples/myloop.mpg');
	$self->get_root_view->set_resource($mpg, 
			$T_CONST->HALIGN_CENTER | $T_CONST->VALIGN_CENTER);

	$self->{bg} = $T_VIEW->new(
        x=>2, y=>2, width=>640, height=>480, visible => 1)->add;
	$self->{fg} = $T_VIEW->new(
        x=>0, y=>0, width=>640, height=>480, visible => 1)->add;

    my $font = $T_RESOURCE->font('default', 20, $T_CONST->FONT_BOLD);
    $self->{bg}->set_resource(
        $T_RESOURCE->text($font,
            $T_RESOURCE->color(0x0, 0x0, 0x0, 0xff),
            'The picutre is a movie!')
    );
    $self->{fg}->set_resource(
        $T_RESOURCE->text($font,
            $T_RESOURCE->color(0xff, 0xff, 0xff, 0xff),
            'The picutre is a movie!')
    );
}

sub handle_event {
	my($self, $resource, $key_action, $key_code, $key_rawcode) = @_;
	#print "EVENT on $resource: $key_action $key_code $key_rawcode\n";

    if ($self->{properties}->{platform} =~ /^sim-/) {
        my $jpg = $T_RESOURCE->image_file('examples/myloop.jpg');
	    $self->get_root_view->set_resource($jpg, 
			$T_CONST->HALIGN_CENTER | $T_CONST->VALIGN_CENTER);
    }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

