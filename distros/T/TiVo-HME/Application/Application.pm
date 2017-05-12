package TiVo::HME::Application;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.1';

# Just use these there so subclass don't have to
use TiVo::HME::View;
use TiVo::HME::Resource;
use TiVo::HME::CONST;

# some handy-dandy constants
our $pkg = 'TiVo::HME::';
our $T_RESOURCE = $pkg . 'Resource';
our $T_VIEW = $pkg . 'View';
our $T_CONST = $pkg . 'CONST';

# You'll thank me for this I promise...
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($T_RESOURCE $T_VIEW $T_CONST);

use IO::Select;

use constant {

	# root view ID
	ID_ROOT_VIEW => 2,

	# Application errors
	APP_ERROR_UNKNOWN => 		0,
	APP_ERROR_BAD_ARGUMENT => 	1,
	APP_ERROR_BAD_COMMAND => 	2,
	APP_ERROR_RSRC_NOT_FOUND => 3,
	APP_ERROR_VIEW_NOT_FOUND => 4,
	APP_ERROR_OUT_OF_MEMORY => 	5,
	APP_ERROR_OTHER => 			100,

	# Resource status
	RSRC_STATUS_UNKNOWN =>		0,
	RSRC_STATUS_CONNECTING =>	1,
	RSRC_STATUS_CONNECTED =>	2,
	RSRC_STATUS_LOADING =>		3,
	RSRC_STATUS_READY =>		4,
	RSRC_STATUS_PLAYING =>		5,
	RSRC_STATUS_PAUSED =>		6,
	RSRC_STATUS_SEEKING =>		7,
	RSRC_STATUS_CLOSED =>		8,
	RSRC_STATUS_COMPLETE =>		9,
	RSRC_STATUS_ERROR =>		10,

	# Resource errors
	RSRC_ERROR_UNKNOWN =>				0,
	RSRC_ERROR_BAD_DATA =>				1,
	RSRC_ERROR_BAD_MAGIC =>				2,
	RSRC_ERROR_BAD_VERSION =>			3,
	RSRC_ERROR_CONNECTION_LOST =>		4,
	RSRC_ERROR_CONNECTION_TIMEOUT =>	5,
	RSRC_ERROR_CONNECT_FAILED =>		6,
	RSRC_ERROR_HOST_NOT_FOUND =>		7,
	RSRC_ERROR_INCOMPATIBLE =>			8,
	RSRC_ERROR_NOT_SUPPORTED =>			9,
	RSRC_ERROR_BAD_ARGUMENT =>			20,
	RSRC_ERROR_BAD_STATE =>				21,

	# Key events
	KEY_PRESS =>	1,
	KEY_REPEAT =>	2,
	KEY_RELEASE =>	3,
};

sub new {
	bless {}, shift;
}

# set context & create root view
sub set_context {
	my($self) = shift;
	$self->{context} = shift;

	# set context in Resource
	$T_RESOURCE->set_context($self->{context});

	# Create root view (note we don't 'add' it since it's
	#	already exists on the TiVo
	$self->{root_view} = $T_VIEW->new(
		id => ID_ROOT_VIEW,
		context => $self->{context},
		x => 0, y => 0,
		width => 640, height => 480,
	);
}

sub get_context {
	$_[0]->{context};
}

sub get_root_view {
	$_[0]->{root_view};
}

sub id {
	$T_CONST->ID_ROOT_STREAM;
}

sub read_events {
	my($self) = @_;

	my $io = $self->{context}->get_io;

	my $s = IO::Select->new;
	$s->add($io->{io});

	while(1) {
		my @ready = $s->can_read;
		my($op) = $io->read_chunk_header;
        return if (!defined $op);
		if ($op == $T_CONST->EVT_DEVICE_INFO) {
			# Read in device info structure
			my $id = $io->read_vint;
			my $count = $io->read_vint;
			for (my $i = 0; $i < $count; $i++) {
				my $key = $io->read_string;
				my $value = $io->read_string;
				print "Key value $i is $key = $value\n";
				$self->{properties}->{$key} = $value;
			}
		} elsif ($op == $T_CONST->EVT_APP_INFO) {
			# do something more interesting here
			print "app info...\n";
			my $id = $io->read_vint;
			my $count = $io->read_vint;
			for (my $i = 0; $i < $count; $i++) {
				my $key = $io->read_string;
				my $value = $io->read_string;
				print "Key value $i is $key = $value\n";
			}
		} elsif ($op == $T_CONST->EVT_RSRC_INFO) {
			print "resource info...\n";
			my $resource = $io->read_vint;
			my $status = $io->read_vint;
			my $count = $io->read_vint;
			for (my $i = 0; $i < $count; $i++) {
				my $key = $io->read_string;
				my $value = $io->read_string;
				print "Key value $i is $key = $value\n";
			}
		} elsif ($op == $T_CONST->EVT_KEY) {
			my $resource = $io->read_vint;
			my $key_action = $io->read_vint;
			my $key_code = $io->read_vint;
			my $key_rawcode = $io->read_vint;

			# dispatch this bad boy
			$self->handle_event($resource,
				$key_action, $key_code, $key_rawcode);

		}

		$io->terminate_chunk;

	}
}

sub handle_event {
	# Override me to hande events!!
}

1;

__END__

=head1 NAME

TiVo::HME::Application - Perl implementation of TiVo's HME protocol
See http://tivohme.sourceforge.net/

=head1 SYNOPSIS

  use TiVo::HME::Application;
  our @ISA(TiVo::HME::Application);

  sub init {
    my($self, $context) = @_;

    $self->get_root_view->visible(1);
    my $mpg =  $T_RESOURCE->image_file('examples/myloop.jpg');
    $self->get_root_view->set_resource($mpg,
        $T_CONST->HALIGN_CENTER | $T_CONST->VALIGN_CENTER);
    }

    sub handle_event {
        my($self, $resource, $key_action, $key_code, $key_rawcode) = @_;
        print "You pressed the $key_code key on the remote!\n";
    }


=head1 DESCRIPTION

    Perl on your TiVo in 11 Steps!!

    Step 1: Go to http://tivohme.sourceforge.net
    Step 2: Go to Step 1
    Step 3: Go to Step 2 (seriously)
    Step 4: Congratulations on making it here!
    Step 5: Really, go to http://tivohme.sourceforge.net, download the
        SDK, read the PDF files (don't worry about the protocol PDF,
        that's what this is for).
    Step 6: Learn about Views & Resources
    Step 7: Learn about the Application cycle (init then event loop)
    Step 8: Learn about Events
    Step 9: Learn how the Perl stuff differs from the Java stuff
        (mainly only in naming)
    Step 10: View & understand the perl examples - especially how they
        related to the Java examples (they do the same thing!).
    Step 11: Use your imagination to create a kick-arse Perl-based HME app!!

=head2 Start the Server
    
    First you must start up the HTTP daemon - your TiVo (or Simulator) wants 
    to connect to us at port 7288 if you're curious.
    The 'start.pl' script start ups the Server & waits for a connection from
    a TiVo or simulator.
    When one comes it, the URL is pulled off & is taked for the name of
    the app.
    SO after starting the server, in the Simulator you type in:
    http://localhost/myapp & hit return.
    The Perl HME stuff will now try to find a module named 'myapp.pm'.
    Obviously myapp.pm needs to be in @INC - so your start script should
    'use lib qw(...)' to point to where your TiVo HME app lives.

=head2 Write your App

    Your TiVo HME app should subclass TiVo::HME::Application.

    use TiVo::HME::Application;
    our @ISA = qw(TiVo::HME::Application);

    The entry point to your app is the 'init' function call.  Hopefully
    by now it's starting to sound similar to mod_perl.
    You get a reference to $self & $context as the parameters.
    We'll talk about contexts laters as you most likely don't need
    anything from that object.
    In $self you stash thing that you want to persist beyond the init
    call.  Mostly that'll be Views, Resources, & Application state.

=head2 Views

    Views are containers for Resources.  A View has exactly 1 parent view and
    any number of childen views.
    Views have stuff like bounds, scale, translation, and transparency.
    They can be visible or not, they can be painted on or not.
    And they can have exactly 1 Resource.

=head3 Creating a new View

    my $view = TiVo::HME::View->new(
        x => MIN_X_VALUE,
        y => MIN_Y_VALUE,
        width => MAX_WIDTH,
        height => MAX_HEIGHT,
        visible => [ 0 | 1 ],
        [ parent => $parent_view ]
    );

    x, y, width, height are the bounding rectangle of the view.  
    Anything drawn outside of that box will be clipped.
    If you do not specify the parent it will be set to the root view.
    There are accessor methods for each of the view's properties.

    You MUST 'add' the View after you create it!!

    $view->add;

=head3 The Root View

    There is 1 Root view whose bounds are the entire screen (640x480).
    This view is INVISIBLE by default.  Mostly like you will want to
    make it visible as soon as your done adding resources if not sooner:

    $T_VIEW->root_view->visible(1);

=head2 Manipulating Views

    See the sourceforge page for details about what this stuff means.

=head3 Adding the View

    $view->add;

=head3 Set the View's Resource

    $view->set_resource(<resource>, [ flags ]);
    <resource> is the resource - see below
    [ flags ] if present is OR'ed together flags from CONST.pm
        see HALIGN_LEFT -> IMAGE_BESTFIT
        set to HALIGN_LEFT by default

=head3 Visible

    $self->visible([ 0 | 1], [animation]);

=head3 Bounds

    $self->bounds(x, y, width, heigth, [animation]);

=head3 Scale

    $self->scale(scale_x, scale_y, [animation]);
    scale_x & scale_y are floats

=head3 Translate

    $self->translate(t_x, t_y, [animation]);
    Translate origin

=head3 Transparency

    $self->transparency(transparency, [animation]);
    0 = opaque
    1 = transparent

=head3 Painting

    $self->painting([ 0 | 1], [animation]);
    Set painting

=head3 Remove

    $self->remove([animation]);
    Remove view

=head2 Resources

    There are 9 Resources:

        Image
        Sound
        Font
        True Type Font
        Color
        Text
        Stream
        Animation

    See http://tivohme.sourceforge.net for details about what these
        are & how they are used.

=head3 Image Resource

    my $img = $T_RESOURCE->image_file(<filename>);
    Can be a PNG, JPEG, or MPEG file (for setting video backgrounds)

=head3 Sound Resource

    my $sound = $T_RESOURCE->sound_file(<filename>);
    Has to be a 8-bit PCM file

=head3 Font Resource

    my $font = $T_RESOURCE->font(<name>, <point size>, <style>);
    Where <name> is 'system' or 'default'
    <point size> is a float (have no idea why)
    <style> is $T_CONST->FONT_PLAIN
                $T_CONST->FONT_BOLD
                $T_CONST->FONT_ITALIC
                $T_CONST->FONT_BOLDITALIC

=head3 TTF Resource

    my $ttf_font = $T_RESOURCE->ttf_file(<filename>);
    Pass a TTF file

=head3 Color Resource

    my $color = $T_RESOURCE->color(<red>, <green>, <blue>, <alpha>
    All values are 0-255
    Alpha = 255 = opaque
    Alpha = 0 = transparent

=head3 Text Resource
    
    my $text = $T_RESOURCE->text(<font>, <color>, <string>);
    Where <font> is a font or TTF resource,
    color is a color resource & string is yer string

=head3 Stream Resource

    my $stream = $T_RESOURCE->stream(<url>, <content-type>, <play>);
    <url> points to a streamable resource
    <content-type> is the content type hint
    <play> = 1 = play
    <play> = 0 = pause

=head3 Manipulating Resources

    Again see the sourceforge page for what these mean

=head4 Make active

    $resource->active([ 0 | 1 ]);
    Make a resource active or not

=head4 Set position

    $resource->set_position(<int>);

Sets the position at which the resource is played back. Resources which are playing are  immediately repositioned. Resources which
are not yet started will begin playing at this  position.

=head4 Set speed

    $resource->set_speed([ 0 .. 1 ]);

=head4 Close

    $resource->close;

=head4 Remove

    $resource->remove;

=head4 Send Event

    Only key events are supported (HME limitation not mine)
    $resource->send_event(<target>, <animation>, <data>);
    <target> currently can only be 1
    <animation> is an animation resource
    <data> is see 'make_key_event'

=head4 Make Key Event

    $self->make_key_event(<target>, <action>, <code>, <rawcode>);
    <target> can only be 1
    <action> is $T_CONST->KEY_PRESS
                $T_CONST->KEY_REPEAT
                $T_CONST->KEY_RELEASE
    <code> is a key code - look in CONST.pm for all of 'em
    <rawcode> is whatever the heck you want it to be

=head4 Default resources

    All of the default resources (sounds) are available in the
        @TiVo::HME::DEFAULT_RESOURCES array indexed by the
        constants ID_BONK_SOUND etc... - see CONST.pm

=head2 Examples

    SEE AND UNDERSTAND THE EXAMPLES!!!!!

=head2 EXPORT

Exporting is Bad.  Bad. Bad. Bad.  
And Yet this modules exports 3 symbols.
That's how important they are.  You will use them many times in
your app & will thank me someday.   Really.

$T_RESOURCE is a handle to 'TiVo::HME::Resource'
$T_VIEW is a handle to 'TiVo::HME::View'
$T_CONST is a handle to 'TiVo::HME::CONST'

You really don't want to be writing:

my $r = TiVo::HME::Resource->color(222. 32, 20, 0xff);

when you can just write

my $r = $T_RESOURCE->color(222. 32, 20, 0xff);

Or for constants:

my $bonk = TiVo::HME::CONST->ID_BONK_SOUND;

vs.

my $bonk = $T_CONST->ID_BONK_SOUND;

Isn't that worth Exporting??

=head1 SEE ALSO

    http://tivohme.sourceforge.net

=head1 AUTHOR

Mark Ethan Trostler, E<lt>mark@zzo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Mark Ethan Trostler

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
