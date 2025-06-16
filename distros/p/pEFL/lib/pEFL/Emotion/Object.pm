package pEFL::Emotion::Object;

use strict;
use warnings;

require Exporter;

use pEFL::Evas;
use pEFL::Elm::Object;

our @ISA = qw(Exporter EmotionObjectPtr);

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

);

require XSLoader;
XSLoader::load('pEFL::Emotion::Object');

sub add {
    my ($class,$evas) = @_;
    my $widget = emotion_object_add($evas);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_signals, $widget);
    return $widget;
}

*new = \&add;

package EmotionObjectPtr;

our @ISA = qw(ElmObjectPtr EvasObjectPtr);

# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Emotion::Object

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $emotion = pEFL::Emotion::Object->add($evas);
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Emotion Object widget.

For more informations see L<https://www.enlightenment.org/develop/legacy/api/c/start#emotion_main.html>

For instructions, how to use pEFL::Emotion::Object, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Emotion::Object gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "emotion_object_" at the beginning of the c functions.

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
