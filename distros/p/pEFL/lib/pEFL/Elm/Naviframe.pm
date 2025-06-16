package pEFL::Elm::Naviframe;

use strict;
use warnings;

require Exporter;
use pEFL::Evas;
use pEFL::Elm::Object;

our @ISA = qw(Exporter ElmNaviframePtr);

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
XSLoader::load('pEFL::Elm::Naviframe');

sub add {
    my ($class,$parent) = @_;
    my $widget = elm_naviframe_add($parent);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_genitems, $widget);
    $widget->event_callback_add(EVAS_CALLBACK_DEL, \&pEFL::PLSide::cleanup_signals, $widget);
    return $widget;
}

*new = \&add;

package ElmNaviframePtr;

our @ISA = qw(ElmObjectPtr EvasObjectPtr);

sub item_pop_pv {
	my ($nav) = @_;
	my $content = $nav->item_pop();
	my $class = ElmObjectPtr::widget_type_get($content);
	if ($class =~ /^Elm_/) {
		my $pclass = $class;
		$pclass =~ s/_//g;
		$pclass = $pclass . "Ptr";
		bless($content,$pclass);
	}
	return $content;

}



#

# Preloaded methods go here.

1;
__END__
=head1 NAME

pEFL::Elm:Naviframe

=head1 SYNOPSIS

  use pEFL::Elm;
  [...]
  my $widget = pEFL::Elm::Naviframe->add($parent);
  [...]

=head1 DESCRIPTION

This module is a perl binding to the Elementary Naviframe widget.

For more informations see https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Naviframe.html 

For instructions, how to use pEFL::Elm::Naviframe, please study this API reference for now. A perl-specific documentation will perhaps come in later versions. But applying the C documentation should be no problem. pEFL::Elm::Naviframe gives you a nice object-oriented interface that is kept close to the C API. Please note, that the perl method names remove the "elm_naviframe_" at the beginning of the c functions.

=head1 SPECIFICS OF THE BINDING

There is a special version of $nav->item_pop() with the name $nav->item_pop_pv() that tries to bless the returned EvasObject to the appropriate perl class. In fact the C class is fetched by ElmObjectPtr::widget_type_get and translated to the PerlClass through deleting underscores and adding "Ptr". It should work with all Elm_*-Widgets for which a perl binding exist. Nevertheless it is not guaranteed to work in all cases.

If you prefer to use the pure version $nav->item_pop() be aware, that this version returns a EvasObject and you possibly have to bless this to the right perl class manually.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Elm__Naviframe.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
