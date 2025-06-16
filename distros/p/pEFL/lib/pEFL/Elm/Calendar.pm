package pEFL::Elm::Calendar;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::Elm::Object;


our @ISA = qw(Exporter ElmCalendarPtr);

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

our %Format_Cbs;

require XSLoader;
XSLoader::load('pEFL::Elm::Calendar');

sub add {
    my ($class,$parent) = @_;
    my $widget = elm_calendar_add($parent);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_signals, $widget);
    return $widget;
}

*new = \&add;

package ElmCalendarPtr;

use pEFL::Time;
use Scalar::Util qw(refaddr);
use pEFL::Eina;

our @ISA = qw(ElmObjectPtr EvasObjectPtr);

sub register_format_cb {
    my ($obj, $func) = @_;

    my $objaddr = $$obj;
    my $funcaddr = refaddr($func);

    my $func_struct ={
                        function => $func,
                        cstructaddr => ''
    };

    $Format_Cbs{$objaddr} = $func_struct;
}

sub format_function_set {
    my ($obj, $func) = @_;
    register_format_cb( $obj, $func);

    $obj->_elm_calendar_format_function_set($func);
}

sub marks_get_pv {
    my ($obj) = @_;
    my $list = $obj->marks_get();
    my @array = pEFL::Eina::list2array($list,"ElmCalendarMarkPtr");
    return @array;
}

# Preloaded methods go here.

1;
__END__
=head1 NAME

pEFL::Elm:Calendar

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $widget = pEFL::Elm::Calendar->add($parent);
  $widget->weekdays_names_set(["Mo","Di","Mi","Do","Fr","Sa","So"]);
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary Calendar widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Calendar.html 

For instructions, how to use pEFL::Elm::Calendar, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::Calendar gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_calendar_" at the beginning of the c functions.

=head1 Limitations

At the moment the method $calendar->format_function_set(\&func) doesn't work.

Please note, that $calendar->weekdays_name_set(\@arr) expects an array reference as argument. Likewise $calendar->weekdays_name_get() returns an array reference.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Calendar.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
