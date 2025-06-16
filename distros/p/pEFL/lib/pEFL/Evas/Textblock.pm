package pEFL::Evas::Textblock;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter EvasTextblockPtr);

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
XSLoader::load('pEFL::Evas::Textblock');

sub add {
	my ($class,$parent) = @_;
	my $widget = evas_object_textblock_add($parent);
	$widget->event_callback_add(pEFL::Evas::EVAS_CALLBACK_DEL(), \&pEFL::PLSide::cleanup, $widget);
	return $widget;
}

*new = \&add;

package EvasTextblockPtr;

use pEFL::Eina;

our @ISA = qw(EvasObjectPtr);

sub node_format_list_get_pv {
	my ($obj) = @_;
	my $list = $obj->node_format_list_get();
	my @array = pEFL::Eina::list2array($list,"EvasTextblockNodeFormatPtr");
	return @array;
}

sub range_delete {
	my ($textblock,$cur1,$cur2) = @_;
	return $cur1->range_delete($cur2);
}

sub visible_range_get {
	my ($textblock,$cur1,$cur2) = @_;
	return $cur1->visible_range_get($cur2);
}

sub range_text_get {
	my ($textblock,$cur1,$cur2,$format) = @_;
	return $cur1->range_text_get($cur2,$format);
}

sub range_formats_get {
	my ($textblock,$cur1,$cur2) = @_;
	return $cur1->range_formats_get($cur2);
}

sub range_formats_get_pv {
	my ($textblock,$cur1,$cur2) = @_;
	my $list = $cur1->range_formats_get($cur2);
	my @array = pEFL::Eina::list2array($list,"EvasTextblockNodeFormatPtr");
	return @array;
}

sub range_geometry_get {
	my ($textblock,$cur1,$cur2) = @_;
	return $cur1->range_geometry_get($cur2);
}

sub range_geometry_get_pv {
	my ($textblock,$cur1,$cur2) = @_;
	my $list = $cur1->range_geometry_get($cur2);
	my @array = pEFL::Eina::list2array($list,"EvasTextblockRectanglePtr");
	return @array;
}

sub text_markup_prepend {
	my ($textblock, $cur, $text) = @_;
	pEFL::Evas::Textblock::text_markup_prepend($cur,$text)
}

package pEFL::Evas::TextblockRectangle;

our @ISA = qw(EvasTextblockRectanglePtr);

1;
__END__

=head1 NAME

pEFL::Evas::Textblock

=head1 DESCRIPTION

This module is a perl binding to the Evas Textblock Object Functions.

It contains functions and methods to create and manipulate textblock objects.

=head1 SPECIFICS OF THE BINDING

For the following method, which returns an Eina_List, exists a "perl-value"-method:

=over 4

=item * $textblock->node_format_list_get_pv();

=back

For asthetic reason there are some shortcuts for some TextblockCursorPtr-methods (namely the range methods):

=over 4

=item * $textblock->range_delete($cur1,$cur2);

=item * $textblock->visible_range_get($cur1,$cur2);

=item * $textblock->range_text_get($cur1,$cur2,$format);

=item * $textblock->range_formats_get($cur1,$cur2);

=item * $textblock->range_formats_get_pv($cur1,$cur2);

=item * $textblock->range_geometry_get($cur1,$cur2);

=item * $textblock->range_geometry_get_pv($cur1,$cur2);

=item * $textblock->text_markup_prepend($cur1,$text); 

=back

=head1 SEE ALSO

https://www.enlightenment.org/develop/legacy/api/c/start#group__Evas__Object__Textblock__Group.html

=head1 AUTHOR

Maximilian Lika

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Maximilian Lika

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
