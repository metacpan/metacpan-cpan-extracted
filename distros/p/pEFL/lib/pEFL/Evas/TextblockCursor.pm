package pEFL::Evas::TextblockCursor;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter EvasTextblockCursorPtr);

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
XSLoader::load('pEFL::Evas::TextblockCursor');

sub new {
    my ($class,$parent) = @_;
    my $widget = evas_object_textblock_cursor_new($parent);
    #$widget->smart_callback_add("del", \&pEFL::PLSide::cleanup, $widget);
    return $widget;
}


package EvasTextblockCursorPtr;

use pEFL::Eina;

sub range_formats_get_pv {
	my ($obj,$cp2) = @_;
	my $list = $obj->range_formats_get($cp2);
	my @array = pEFL::Eina::list2array($list,"EvasTextblockNodeFormatPtr");
	return @array;
}

sub range_geometry_get_pv {
	my ($obj,$cp2) = @_;
	my $list = $obj->range_geometry_get($cp2);
	my @array = pEFL::Eina::list2array($list,"EvasRectanglePtr");
	return @array;
}

sub text_markup_prepend {
	my ($cur,$text) = @_;
	return $cur->evas_object_textblock_text_markup_prepend($text);
}

#our @ISA = qw(EvasObjectPtr);

# Preloaded methods go here.

1;
__END__

=head1 NAME

pEFL::Evas::TextblockCursor

=head1 DESCRIPTION

This module is a perl binding to Evas_Textblock_Cursor.

A pEFL::Evas::TextblockCursor is used to manipulate the cursor of an evas textblock.

=head1 SPECIFICS OF THE BINDING

For the following methods, which return an Eina_List, exist a "perl-value"-method:

=over 4

=item $cur->range_formats_get_pv();

=item $cur->range_geometry_get_pv();

=back

Beyond the pure translation of the C-API, there are some shortcuts-methods:

=over 4

=item $cur->text_markup_prepend($text); (for evas_object_textblock_text_markup_prepend($cur,$text);

=item pEFL::Evas::TextblockCursor::copy($cur1,$cur2);

=item pEFL::Evas::TextblockCursor::compare($cur1,$cur2);

=item pEFL::Evas::TextblockCursor::equal($cur1,$cur2);

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
