package TiVo::HME::Resource;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.1';

use Digest::MD5 qw(md5_hex);

# stash of all current resources
our %_resources;
our @_resources;

# package globals
our $CONTEXT;
our $IO;
our @DEFAULT_RESOURCES;

use constant {
	FONT_DEFAULT_ID => 10,
	FONT_SYSTEM_ID => 11,
	CMD_RSRC_ADD_COLOR => 20,
	CMD_RSRC_ADD_TTF => 21,
	CMD_RSRC_ADD_FONT => 22,
	CMD_RSRC_ADD_TEXT  => 23,
	CMD_RSRC_ADD_IMAGE  => 24,
	CMD_RSRC_ADD_SOUND  => 25,
	CMD_RSRC_ADD_STREAM  => 26,
	CMD_RSRC_ADD_ANIM  => 27,
	CMD_RSRC_SET_ACTIVE  => 40,
	CMD_RSRC_SET_POSITION  => 41,
	CMD_RSRC_SET_SPEED  => 42,
	CMD_RSRC_SEND_EVENT  => 44,
	CMD_RSRC_CLOSE  => 45,
	CMD_RSRC_REMOVE  => 46,
};

sub set_context {
	my($class, $context) = @_;

	$CONTEXT = $context;
	$IO = $context->get_io;

	# load up default sounds
	for (my $i = TiVo::HME::CONST->ID_BONK_SOUND; 
		$i <= TiVo::HME::CONST->ID_SPEEDUP3_SOUND; $i++) {

		$DEFAULT_RESOURCES[$i] = 
			bless { id => $i, what => 'sound' }, $class;
	}

}

sub get_id {
	$CONTEXT->get_next_id;
}

sub _make {
	my($class, $what, $id, $key) = @_;

	# store an extra ref to find easier later
	$_resources{$key} = bless {key => $key, what => $what, id => $id}, $class;
	$_resources[$id] = $_resources{$key};
}
	
sub color {
	my($class, $r, $g, $b, $alpha) = @_;

	my $key = $r . $g . $b . $alpha;
	return $_resources{$key} if $_resources{key};

	# create color resource
	my $id = get_id;

	# ship it
	$IO->do('vvrrrr', CMD_RSRC_ADD_COLOR, $id, $alpha, $r, $g, $b);

	_make($class, 'color', $id, $key);
}

sub font {
	my($class, $name, $point_size, $style) = @_;
	my($key, $ttf_id, $id);

	$name = lc $name;
	return unless ($name =~ /system|default/);

	$key = $name . $point_size . $style;
	return $_resources{$key} if $_resources{key};

	$id = get_id;
	$ttf_id = $name eq 'system' ? FONT_SYSTEM_ID : FONT_DEFAULT_ID;

	# ship it
	$IO->do('vvvvf', CMD_RSRC_ADD_FONT, $id, $ttf_id, $style, $point_size);

	# store it
	_make($class, 'font', $id, $key);
}

sub text {
	my($class, $font, $color, $string) = @_;
	my($key, $id);

	$key = $font->{id} . $color->{id} . $string;
	return $_resources{$key} if $_resources{key};

	# create a new ID
	$id = get_id;

	# ship it
	$IO->do('vvvvs', CMD_RSRC_ADD_TEXT, $id, $font->{id}, $color->{id}, $string);

	# store it
	_make($class, 'text', $id, $key);
}

sub ttf_file {
	my($class, $fname) = @_;

	# TODO we should hash the file to see if we already got it...
	_binary_file($class, CMD_RSRC_ADD_TTF, $fname);
}

sub image_file {
	my($class, $fname) = @_;

	# TODO we should hash the file to see if we already got it...
	_binary_file($class, CMD_RSRC_ADD_IMAGE, $fname);
}

sub sound_file {
	my($class, $fname) = @_;

	# TODO we should hash the file to see if we already got it...
	_binary_file($class, CMD_RSRC_ADD_SOUND, $fname);
}

sub _binary_file {
	my($class, $opcode, $fname) = @_;

	my($size, $d) = -s $fname;
	open(F, $fname) || die "Can't open image file: $fname\n";
	binmode(F);
	my $s = sysread(F, $d, $size);
	close(F);

	if ($s != $size) {
		die "Error reading file $fname\n";
	}

	my $key = md5_hex($d);
	return $_resources{$key} if $_resources{key};

	my @data = split //, $d;

	# create a new ID
	my $id = get_id;

	$IO->do('vvR', $opcode, $id, [map(ord, @data)]);

	_make($class, 'binary', $id, $key);
}

# $play 0 = pause 1 = play
sub stream {
	my($class, $url, $content_type, $play) = @_;

	my $key = $url . $content_type;
	return $_resources{$key} if $_resources{key};

	# create a new ID
	my $id = get_id;
	$IO->do('vvssb', CMD_RSRC_ADD_STREAM, $id, $url, $content_type, $play);
	_make($class, 'stream', $id, $key);
}

# ease -1 = ease in, 0 = linear, 1 = ease out
sub animation {
	my($class, $duration, $ease) = @_;

	$ease ||= 0;

	my $key = $duration . $ease;
	return $_resources{$key} if $_resources{key};

	# create a new ID
	my $id = get_id;
	$IO->do('vvvf', CMD_RSRC_ADD_ANIM, $id, $duration, $ease);
	_make($class, 'animation', $id, $key);
}

sub set_active {
	my($self, $active) = @_;
	$IO->do('vvb', CMD_RSRC_SET_ACTIVE, $self->{id}, $active);
}

sub set_position {
	my($self, $position) = @_;
	$IO->do('vvv', CMD_RSRC_SET_POSITION, $self->{id}, $position);
}

# 0 = paused, 1 = play
sub set_speed {
	my($self, $speed) = @_;
	$IO->do('vvf', CMD_RSRC_SET_SPEED, $self->{id}, $speed);
}

# $data is an ARRAY REF or whatever
sub send_event {
	my($class, $target_resource, $animation, $data) = @_;

	my $aid = ($animation ? $animation->{id} : TiVo::HME::CONST->ID_NULL);

	$IO->do('vvvR', CMD_RSRC_SEND_EVENT, $target_resource->id, 
		$aid, $data);
}

sub close {
	my($self) = @_;
	$IO->do('vv', CMD_RSRC_CLOSE, $self->{id});
}

sub remove {
	my($self) = @_;

	if ($self->{id} && $self->{io}) {
		$IO->do('vv', CMD_RSRC_REMOVE, $self->{id});
		undef $self->{id};
	}
}

sub make_key_event {
	my($class, $target, $action, $code, $rawcode) = @_;

	my @d;
	push @d, $IO->make_vint(TiVo::HME::CONST->EVT_KEY);
	push @d, $IO->make_vint($target->id);
	push @d, $IO->make_vint($action);
	push @d, $IO->make_vint($code);
	push @d, $IO->make_vint($rawcode);

	[ @d ];
}

sub DESTROY {
	my($self) = shift;
	$self->remove;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

TiVo::HME::Resource - Perl encapsulation of a TiVo HME resource.

=head1 SYNOPSIS

  use TiVo::HME::Application;
  @ISA = qw(TiVo::HME::Applicaton);

    # create a buncha resources

    # Color
    # r,g,b,alpha = 0 ... 255
    my $color = $T_RESOURCE->color($red, $green, $blue, $alpha);

    # Font
    my $font = $T_RESOURCE->font([ 'system' | 'default' ], $point_size, STYLE);
    # point size is a float
    # STYLE is one of:
    # $T_CONST->FONT_PLAIN      
    # $T_CONST->FONT_BOLD       
    # $T_CONST->FONT_ITALIC     
    # $T_CONST->FONT_BOLDITALIC 

    # True Type Font (you need a file containing it)
    my $ttf = $T_RESOURCE->ttf_file($ttf_file_name);

    # Text
    my $text = $T_RESOURCE->text($font, $color, $string);
    # $font (TTF or Font) & $color are created as above
    # $string is yer string

    # Image (jpeg, mpeg, or png)
    my $image = $T_RESOURCE->image_file($path_to_image_file);

    # Sound
    my $sound = $T_RESOURCE->sound_file($path_to_sound_file);

    # Stream
    my $sound = $T_RESOURCE->stream($url, $content_type, $play);
    # $url points to stream resouce 
    # $content_type is a hint to TiVo so it knows what the stream is
    # $play, 1 = play, 0 = pause

    # Animation
    my $anim = $T_RESOURCE->animation($duration, $ease);
    # $duration is in miliseconds
    # $ease = -1. <= $ease <= 1.  0 = linear

    # Set active
    $resource->set_active ( [ 0 | 1 ] );

    # Set position
    $resource->position($pos);
    # $pos = milliseconds into resource

    # Set speed
    $resource->set_speed( 0 .. 1.);
    # 0 = paused
    # 1 = play at normal speed

    # Make key event
    my $event = $T_RESOURCE->make_key_event(1, $action, $code, $rawcode);
    # just put the '1' there for now...
    # $action can be anything BUT you can use:
    # $T_CONST->KEY_PRESS       
    # $T_CONST->KEY_REPEAT      
    # $T_CONST->KEY_RELEASE     

    # $code - see all the key codes defined in TiVo::HME::CONST
    # $rawcode can be anything

    # Send key event
    $T_RESOURCE->set_event(1, $animation, $event);
    # just put the '1' there for now...
    # $animation is an (optional) animation resource (0 to ignore)
    # $event is from 'make_key_event'

    # Close
    $resource->close;

    # Remove resource from TiVo
    $resource->remove;









    my $image = $T_RESOURCE->image_file('tivo.jpg');

=head1 DESCRIPTION

You create & manipulate resources - eventually assigning them to
Views to be displayed/played by your TiVo.

=head1 SEE ALSO

http://tivohme.sourceforge.net
TiVo::HME::Application

=head1 AUTHOR

Mark Ethan Trostler, E<lt>mark@zzo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mark Ethan Trostler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
