package VideoLAN::LibVLC;
use 5.008001;
use strict;
use warnings;
use Carp;
use Scalar::Util 'weaken';
use Socket qw( AF_UNIX SOCK_DGRAM );
use IO::Handle;

# ABSTRACT: Wrapper for libvlc.so
our $VERSION = '0.03'; # VERSION


use Exporter::Extensible -exporter_setup => 1;
our %EXPORT;
our %EXPORT_TAGS= (
# BEGIN GENERATED XS CONSTANT LIST
  log_level_t => [qw( LOG_LEVEL_DEBUG LOG_LEVEL_ERROR LOG_LEVEL_NOTICE
    LOG_LEVEL_WARNING )],
  media_parse_flag_t => [qw( MEDIA_DO_INTERACT MEDIA_FETCH_LOCAL
    MEDIA_FETCH_NETWORK MEDIA_PARSE_LOCAL MEDIA_PARSE_NETWORK )],
  media_parsed_status_t => [qw( MEDIA_PARSED_STATUS_DONE
    MEDIA_PARSED_STATUS_FAILED MEDIA_PARSED_STATUS_SKIPPED
    MEDIA_PARSED_STATUS_TIMEOUT )],
  media_slave_type_t => [qw( MEDIA_SLAVE_TYPE_AUDIO MEDIA_SLAVE_TYPE_SUBTITLE
    )],
  media_type_t => [qw( MEDIA_TYPE_DIRECTORY MEDIA_TYPE_DISC MEDIA_TYPE_FILE
    MEDIA_TYPE_PLAYLIST MEDIA_TYPE_STREAM MEDIA_TYPE_UNKNOWN )],
  meta_t => [qw( META_ACTORS META_ALBUM META_ALBUMARTIST META_ARTIST
    META_ARTWORKURL META_COPYRIGHT META_DATE META_DESCRIPTION META_DIRECTOR
    META_DISCNUMBER META_DISCTOTAL META_ENCODEDBY META_EPISODE META_GENRE
    META_LANGUAGE META_NOWPLAYING META_PUBLISHER META_RATING META_SEASON
    META_SETTING META_SHOWNAME META_TITLE META_TRACKID META_TRACKNUMBER
    META_TRACKTOTAL META_URL )],
  position_t => [qw( POSITION_BOTTOM POSITION_BOTTOM_LEFT POSITION_BOTTOM_RIGHT
    POSITION_CENTER POSITION_DISABLE POSITION_LEFT POSITION_RIGHT POSITION_TOP
    POSITION_TOP_LEFT POSITION_TOP_RIGHT )],
  state_t => [qw( STATE_BUFFERING STATE_ENDED STATE_ERROR STATE_NOTHINGSPECIAL
    STATE_OPENING STATE_PAUSED STATE_PLAYING STATE_STOPPED )],
  track_type_t => [qw( TRACK_AUDIO TRACK_TEXT TRACK_UNKNOWN TRACK_VIDEO )],
  video_orient_t => [qw( VIDEO_ORIENT_BOTTOM_LEFT VIDEO_ORIENT_BOTTOM_RIGHT
    VIDEO_ORIENT_LEFT_BOTTOM VIDEO_ORIENT_LEFT_TOP VIDEO_ORIENT_RIGHT_BOTTOM
    VIDEO_ORIENT_RIGHT_TOP VIDEO_ORIENT_TOP_LEFT VIDEO_ORIENT_TOP_RIGHT )],
  video_projection_t => [qw( VIDEO_PROJECTION_CUBEMAP_LAYOUT_STANDARD
    VIDEO_PROJECTION_EQUIRECTANGULAR VIDEO_PROJECTION_RECTANGULAR )],
# END GENERATED XS CONSTANT LIST
);
$EXPORT_TAGS{constants}= [ map @{$EXPORT_TAGS{$_}}, grep /_t$/, keys %EXPORT_TAGS ];

sub exporter_autoload_symbol {
	my ($self, $name)= @_;
	# allow exporting anything in all-caps, and anything starting with libvlc
	my $sub= $self->can($name);
	if ($sub && $name =~ /^(?:libvlc.*|[A-Z_]+)$/) {
		return $EXPORT{$name}= $sub;
	} else {
		shift->next::method(@_);
	}
}

require XSLoader;
XSLoader::load('VideoLAN::LibVLC', $VideoLAN::LibVLC::VERSION);


# wrap with method in order to ignore arguments
sub libvlc_version   { libvlc_get_version() }
sub libvlc_changeset { libvlc_get_changeset() }
sub libvlc_compiler  { libvlc_get_compiler() }


sub argv { croak("read-only attribute") if @_ > 1; $_[0]{argv} }

sub _update_app_id {
	my $self= shift;
	$self->{app_id}= ''      unless defined $self->{app_id};
	$self->{app_version}= '' unless defined $self->{app_version};
	$self->{app_icon}= ''    unless defined $self->{app_icon};
	$self->libvlc_set_app_id($self->{app_id}, $self->{app_version}, $self->{app_icon});
}
sub app_id      { my $self= shift; if (@_) { $self->{app_id}= shift; $self->_update_app_id; } $self->{app_id} }
sub app_version { my $self= shift; if (@_) { $self->{app_version}= shift; $self->_update_app_id; } $self->{app_version} }
sub app_icon    { my $self= shift; if (@_) { $self->{app_icon}= shift; $self->_update_app_id; } $self->{app_icon} }


sub _update_user_agent {
	my $self= shift;
	$self->{user_agent_name}= '' unless defined $self->{user_agent_name};
	$self->{user_agent_http}= '' unless defined $self->{user_agent_http};
	$self->libvlc_set_user_agent($self->{user_agent_name}, $self->{user_agent_http});
}
sub user_agent_name { my $self= shift; if (@_) { $self->{user_agent_name}= shift; $self->_update_user_agent; } $self->{user_agent_name} }
sub user_agent_http { my $self= shift; if (@_) { $self->{user_agent_http}= shift; $self->_update_user_agent; } $self->{user_agent_http} }


sub audio_filters { my $self= shift; $self->{audio_filters} ||= [ $self->libvlc_audio_filter_list_get ] }
sub video_filters { my $self= shift; $self->{video_filters} ||= [ $self->libvlc_video_filter_list_get ] }

sub audio_filter_list { @{ shift->audio_filters } }
sub video_filter_list { @{ shift->video_filters } }


sub log { my $self= shift; $self->_set_logger(@_) if @_; $self->{log} }
sub can_redirect_log { !!$_[0]->can('libvlc_log_unset') }

# identical to libvlc api, other than needing to pump the event queue to see the messages
sub libvlc_set_log {
	my ($self, $callback, $argument)= @_;
	$self->_set_logger(sub { $callback->($argument, @_) });
}

sub _set_logger {
	my ($self, $target, $options)= @_;
	$self->can_redirect_log
		or croak "LibVLC log redirection is not supported in this version";
	# If target is undef, cancel the callback
	if (!defined $target) {
		return $self->libvlc_log_unset;
	}
	else {
		$self->_event_pipe; # init file handles, if not already done
		# If target is a coderef:
		if (ref $target eq 'CODE') {
			$self->{log}= $target;
		}
		# if target is a logger
		elsif (ref($target)->can('info')) {
			$self->{log}= sub {
				my ($level, $msg, $attr)= @_;
				$msg= join(' ', $msg, map { "$_=$attr->{$_}" } keys %$attr);
				if ($level == LOG_LEVEL_DEBUG()) { $target->debug($msg); }
				elsif ($level == LOG_LEVEL_NOTICE()) { $target->notice($msg); }
				elsif ($level == LOG_LEVEL_WARNING()) { $target->warn($msg); }
				elsif ($level >= LOG_LEVEL_ERROR()) { $target->error($msg); }
				else { $target->warn($msg); } # in case of future log levels
			};
		}
		else {
			croak "Don't know how to log to $target";
		}
		my $lev= $options? $options->{level} : undef;
		$lev= LOG_LEVEL_NOTICE() unless defined $lev;
		# Install callback
		weaken($self);
		my $cb_id= $self->_register_callback(sub { $self->log->($_[0]) } );
		$self->_libvlc_log_set($cb_id, $lev, $options->{fields} || ['*']);
	}
}


sub new {
	my $class= shift;
	my %args= (@_ == 1 && ref($_[0]) eq 'HASH')? %{ $_[0] }
		: (@_ == 1 && ref($_[0]) eq 'ARRAY')? ( argv => $_[0] )
		: ((@_&1) == 0)? @_
		: croak "Expected hashref, even-length list, or arrayref";
	$args{argv} ||= [];
	my $self= VideoLAN::LibVLC::libvlc_new($args{argv});
	%$self= %args;
	$self->_update_app_id
		if defined $self->{app_id} or defined $self->{app_version} or defined $self->{app_icon};
	$self->_update_user_agent
		if defined $self->{user_agent_name} or defined $self->{user_agent_http};
	$self->_set_logger($self->log)
		if defined $self->{log};
	return $self;
}


sub new_media {
	my $self= shift;
	my @attrs= (@_ & 1) == 0? @_
		: (@_ == 1 && !ref($_[0]))? ( ($_[0] =~ m,://,? 'location' : 'path') => $_[0] )
		: (@_ == 1 && ref($_[0]) eq 'HASH')?        %{ $_[0] }
		: (@_ == 1 && ref($_[0]) eq 'GLOB')?        ( fh => $_[0] )
		: (@_ == 1 && ref($_[0])->can('scheme'))?   ( location => $_[0] )
		: (@_ == 1 && ref($_[0])->can('absolute'))? ( path => $_[0] )
		: (@_ == 1 && ref($_[0])->can('read'))?     ( fh => $_[0] )
		: croak "Expected hashref, even-length list, file handle, string, Path::Class, or URI";
	require VideoLAN::LibVLC::Media;
	VideoLAN::LibVLC::Media->new(libvlc => $self, @attrs);
}


sub new_media_player {
	my $self= shift;
	my @attrs= (@_ & 1) == 0? @_
		: (@_ == 1 && ref($_[0]) eq 'HASH')?   %{ $_[0] }
		: croak "Expected hashref or even-length list";
	require VideoLAN::LibVLC::MediaPlayer;
	VideoLAN::LibVLC::MediaPlayer->new(libvlc => $self, @attrs);
}


sub callback_fh { shift->_event_pipe->[0] }

sub callback_dispatch {
	my ($self)= @_;
	# unsolved bug - I used perl recv() and it blocks.  If I use C recv() it works....
	my $event= $self->_recv_event()
		or return 0;
	my $cb= $self->{_callback}{$event->{callback_id}};
	$cb->($event) if $cb;
	return 1;
}

sub _event_pipe {
	$_[0]{_event_pipe} //= do {
		socketpair(my $r, my $w, AF_UNIX, SOCK_DGRAM, 0)
			or die "socketpair: $!";
		$r->blocking(0);
		# pass file handles to XS
		$_[0]->_set_event_pipe(fileno($r), fileno($w));
		[$r, $w];
	}
}

# REMINDER: Be sure to use weak references in callbacks, so that VLC instance
# doens't end up holding onto sub-resources.
sub _register_callback {
	my ($self, $callback)= @_;
	my $id= 0xFFFF & ($_[0]{_next_cb_id} ||= 1)++;
	if ($self->{callback}{$id}) {
		# extreme circumstances, the $id has wrapped around
		keys %{ $self->{callback} } < 0xFFFF
			or croak "Max callbacks reached";
		$id= 0xFFFF & $_[0]{_next_cb_id}++
			while $self->{callback}{$id};
	}
	$self->{_callback}{$id}= $callback;
	return $id;
}

sub _unregister_callback {
	my ($self, $id)= @_;
	delete $self->{_callback}{$id};
}


sub libvlc_video_set_callbacks {
	my ($player, $lock_cb, $unlock_cb, $display_cb, $opaque)= @_;
	$player->set_video_callbacks(lock => $lock_cb, unlock => $unlock_cb, display => $display_cb, opaque => $opaque);
}
sub libvlc_video_set_format_callbacks {
	my ($player, $format_cb, $cleanup_cb)= @_;
	$player->set_video_callbacks(format => $format_cb, cleanup => $cleanup_cb);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VideoLAN::LibVLC - Wrapper for libvlc.so

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use VideoLAN::LibVLC::MediaPlayer;
  use AnyEvent; # or whatever your favorite event loop is
  my $exit_cv= AE::cv;
  # Tell event loop to call callback_dispatch any time callback_fh is readable
  my $vlc= VideoLAN::LibVLC->new;
  my $listen_vlc= AE::io $vlc->callback_fh, 0, sub { $vlc->callback_dispatch };
  
  my $player= $vlc->new_media_player("funny_cats.avi");
  $player->set_video_callbacks(
    # callback when player needs new picture buffer
    lock => sub ($player, $event) {
      # Allocate automatically using queue_new_picture
      $player->queue_new_picture(id => ++$next_pic_id)
        while $player->queued_picture_count < 8
    },
	# callback when it is time to display a filled picture buffer
    display => sub ($player, $event) {
      do_stuff( $event->{picture} );  # do something with the picture
      $player->queue_picture($event->{picture});  # recycle the buffer
    },
  );
  $player->play; # start VLC thread that decodes and generates callbacks
  exit $exit_cv->recv; # give control to event loop

=head1 DESCRIPTION

This module wraps LibVLC.  The primary reason to use LibVLC instead of running
VLC as a child process is to get programmatic access to the video frames coming
from the decoder B<in real time>.  If you just want to iterate the frames of a
video for some kind of non-realtime analysis, you probably want LibAV instead.
LibVLC is primarily used to implement video players with alternate rendering,
like sending the video frames to OpenGL textures, websockets, aalib, or other
creative uses for which VLC doesn't have an output plugin.

LibVLC already has a very nice object-ish (yet still function-based) API, so
this package wraps each group of functions into a perl object in the logical
manner.  One difficulty, however, is that LibVLC delivers audio and video via
callbacks, and uses multiple threads for playback, which forces callbacks to
deal with multithreading issues.  Perl needs all callbacks to run from the
main thread, so this module solves that by converting callbacks into events,
and streaming them through a pipe.  You can then fit this into an event loop
of your choice by watching the read-state of the pipe and calling the
dispatcher.  You pretty much always need to integrate this into your event
loop since even logging output is handled via callbacks.  However, it only
needs done for the top level C<VideoLAN::LibVLC> instance, not for each player
object.  See L</callback_dispatch> for details.

=head1 CONSTANTS

This module can export constants used by LibVLC, however I renamed them a bit
because libvlc uses a mix of uppercase/lowercase/camel-case that is
distracting and confusing when used as perl const-subs, the LIBVLC_ prefix is
annoying for perl scripts, and some constants only differ by case.

The renaming rules are:

=over

=item *

Remove any "LIBVLC_" or "libvlc_" prefix

=item *

If the constant does not begin with the same word as the enum it belongs to,
add the enum's name to the beginning of the constant

=item *

Uppercase everything

=back

for example:

  LIBVLC_ERROR      =>   LOG_LEVEL_ERROR
  libvlc_Error      =>   STATE_ERROR
  libvlc_meta_Album =>   META_ALBUM

Each of LibVLC's enums can be exported individually:

  use VideoLAN::LibVLC qw( :log_level_t :media_parse_flag_t :media_parsed_status_t
   :media_slave_type_t :media_type_t :position_t :state_t :track_type_t
   :video_orient_t :video_projection_t );

Or get all of them with C<:constants>.

However, be aware that the constants change significantly across libvlc
versions, but this module always exports all of them.  Accessing a constant
not supported by your version of libvlc will throw an exception.
(I figured it would be better to allow the exceptions at runtime than for
 programs to break at compile time due to the host's version of libvlc.)

=head1 ATTRIBUTES

=head2 libvlc_version

Version of LibVLC.  This is a package attribute.

=head2 libvlc_changeset

Precise revision-control version of LibVLC.  This is a package attribute.

=head2 libvlc_compiler

Compiler used to create LibVLC.  This is a package attribute.

=head2 argv

A copy of the argv that you passed to the constructor.  Read-only.

=head2 app_id

A java-style name identifying the application.  Defaults to an empty string if you set app_version
or app_icon.

=head2 app_version

The version of your application.  Defaults to empty string if you assign an app_id or app_icon.

=head2 app_icon

The name of the icon for your application.  Defaults to empty string if you assign an app_id or app_version.

=head2 user_agent_name

A human-facing description of your application as a user agent for web requests.

=head2 user_agent_http

A HTTP UserAgent string for your application.

=head2 audio_filters

An arrayref of all audio filter modules built into LibVLC.

=head2 audio_filter_list

List accessor for audio_filters.

=head2 video_filters

An arrayref of all video filter modules built into LibVLC.

=head2 video_filter_list

List accessor for video_filters.

=head2 can_redirect_log

Whether or not this version of libvlc supports redirecting the log.

=head2 log

  # get
  my $current= $vlc->log
  
  # set to logger object
  $vlc->log( $log );
  $vlc->log( $log, \%options );
  
  # set to logging callback
  $vlc->log( sub { my ($event)= @_; ... } );
  $vlc->log( sub { my ($event)= @_; ... }, \%options );
  
  # disable logging
  $vlc->log(undef);

Set the logger object or logging callback or logging file handle for this LibVLC
instance.  It can be either a logger object like L<Log::Any>, or a callback.

The optional second argumnt \%options can request more or less information for
the callback.  Available options are:

  level   - one of LIBVLC_DEBUG LIBVLC_NOTICE LIBVLC_WARNING LIBVLC_ERROR
  context - boolean of whether to collect the attributes "module", "file", and "line".
  object  - boolean of whether to collect the attributes "name", "header", "id".

Note that logging can happen from other threads, so you won't see the messages until
you call L</callback_dispatch>.

=head1 METHODS

=head2 new

  my $vlc= VideoLAN::VLC->new( \@ARGV );
  my $vlc= VideoLAN::VLC->new( %attributes );
  my $vlc= VideoLAN::VLC->new( \%attributes );

Create a new instance of LibVLC (which directly corresponds to an initialization
of libvlc via C<libvlc_new>)

Note that libvlc suggests against passing command line arguments except for
debugging, since they can differ by version and by platform.

The returned object is based on a hashref, and the libvlc pointer is magically
attached.

=head2 new_media

  my $media= $vlc->new_media( $path );
  my $media= $vlc->new_media( $uri );
  my $media= $vlc->new_media( $file_handle );
  my $media= $vlc->new_media( %attributes );
  my $media= $vlc->new_media( \%attributes );

This nice heavily-overloaded method helps you quickly open new media
streams.  VLC can open paths, URIs, or file handles, and if you only
pass one argument to this method it attempts to decide which of those
three you intended.

You an instead pass a hash or hashref, and then it just passes them
along to the Media constructor.

=head2 new_media_player

  my $player= $vlc->new_media_player();

=head2 callback_fh

The file handle of the read-end of the callback pipe.  Listen on this file handle
to know when to call L</callback_dispatch>.

=head2 callback_dispatch

Read any pending callback messages from the pipe(s), and execute the callback.
This method does not block (unless your callback does).  You can wait for the
file handle L</callback_fh> to become readable to know when to call this method.

=over

=item AnyEvent example:

  my $vlc= VideoLAN::LibVLC->new;
  my $watcher= AE::io $vlc->callback_fh, 0, sub { $vlc->callback_dispatch };  

=item Manual event loop example:

  my $vlc= VideoLAN::LibVLC->new;
  while (1) {
    if (IO::Select->new($vlc->callback_fh)->can_read) {
      $vlc->callback_dispatch;
    }
  }

=back

The "wire format" used to stream the callbacks is deliberately hidden within
this module, and might change drastically in future versions.  It also uses
raw C-level pointers, so isn't safe for perl to tinker with anyway.

=head2 libvlc_video_set_callbacks

  libvlc_video_set_callbacks($player, $lock_cb, $unlock_cb, $display_cb, $opaque);

This is part of the LibVLC API, but you should use L<VideoLAN::LibVLC::Player/set_video_callbacks>
instead.

=head2 libvlc_video_set_format_callbacks

  libvlc_video_set_format_callbacks($player, $format_cb, $cleanup_cb);

This is part of the LibVLC API, but you should use L<VideoLAN::LibVLC::Player/set_video_callbacks>
instead.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
