package pEFL::Emotion;

use strict;
use warnings;

use Carp;

use pEFL::Emotion::Object;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use pEFL::Elm ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
EMOTION_ASPECT_KEEP_NONE
EMOTION_ASPECT_KEEP_WIDTH
EMOTION_ASPECT_KEEP_HEIGHT
EMOTION_ASPECT_KEEP_BOTH
EMOTION_ASPECT_CROP
EMOTION_ASPECT_CUSTOM
EMOTION_WAKEUP
EMOTION_SLEEP
EMOTION_DEEP_SLEEP
EMOTION_HIBERNATE
EMOTION_META_INFO_TRACK_TITLE
EMOTION_META_INFO_TRACK_ARTIST
EMOTION_META_INFO_TRACK_ALBUM
EMOTION_META_INFO_TRACK_YEAR
EMOTION_META_INFO_TRACK_GENRE
EMOTION_META_INFO_TRACK_COMMENT
EMOTION_META_INFO_TRACK_DISC_ID
EMOTION_META_INFO_TRACK_COUNT
EMOTION_ARTWORK_IMAGE
EMOTION_ARTWORK_PREVIEW_IMAGE
EMOTION_VIS_NONE
EMOTION_VIS_GOOM
EMOTION_VIS_LIBVISUAL_BUMPSCOPE
EMOTION_VIS_LIBVISUAL_CORONA
EMOTION_VIS_LIBVISUAL_DANCING_PARTICLES
EMOTION_VIS_LIBVISUAL_GDKPIXBUF
EMOTION_VIS_LIBVISUAL_G_FORCE
EMOTION_VIS_LIBVISUAL_GOOM
EMOTION_VIS_LIBVISUAL_INFINITE
EMOTION_VIS_LIBVISUAL_JAKDAW
EMOTION_VIS_LIBVISUAL_JESS
EMOTION_VIS_LIBVISUAL_LV_ANALYSER
EMOTION_VIS_LIBVISUAL_LV_FLOWER
EMOTION_VIS_LIBVISUAL_LV_GLTEST
EMOTION_VIS_LIBVISUAL_LV_SCOPE
EMOTION_VIS_LIBVISUAL_MADSPIN
EMOTION_VIS_LIBVISUAL_NEBULUS
EMOTION_VIS_LIBVISUAL_OINKSIE
EMOTION_VIS_LIBVISUAL_PLASMA
EMOTION_VIS_LAST
EMOTION_EVENT_MENU1
EMOTION_EVENT_MENU2
EMOTION_EVENT_MENU3
EMOTION_EVENT_MENU4
EMOTION_EVENT_MENU5
EMOTION_EVENT_MENU6
EMOTION_EVENT_MENU7
EMOTION_EVENT_UP
EMOTION_EVENT_DOWN
EMOTION_EVENT_LEFT
EMOTION_EVENT_RIGHT
EMOTION_EVENT_SELECT
EMOTION_EVENT_NEXT
EMOTION_EVENT_PREV
EMOTION_EVENT_ANGLE_NEXT
EMOTION_EVENT_ANGLE_PREV
EMOTION_EVENT_FORCE
EMOTION_EVENT_0
EMOTION_EVENT_1
EMOTION_EVENT_2
EMOTION_EVENT_3
EMOTION_EVENT_4
EMOTION_EVENT_5
EMOTION_EVENT_6
EMOTION_EVENT_7
EMOTION_EVENT_8
EMOTION_EVENT_9
EMOTION_EVENT_10
);

require XSLoader;
XSLoader::load('pEFL::Emotion');


# Preloaded methods go here.

sub AUTOLOAD {
	# This AUTOLOAD is used to 'autoload' constants from the constant()
	# XS function.

	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak "&Callback::constant not defined" if $constname eq 'constant';
	my ($error, $val) = constant($constname);
	if ($error) { croak $error; }
	{
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX		*$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
		*$AUTOLOAD = sub { $val };
#XXX	}
	}
	goto &$AUTOLOAD;
}

1;
__END__

=head1 NAME

pEFL::Emotion

=head1 DESCRIPTION

pEFL::Emotion contains the "EMOTION_*" Constants.

Additional it contains the following general functions:

=over 4

=item * pEFL::Emotion::init();

=item * pEFL::Emotion::shutdown()

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<https://www.enlightenment.org/develop/legacy/api/c/start#emotion_main.html>

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
