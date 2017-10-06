package Win32::AutoItX::Control::ListView;

=head1 NAME

Win32::AutoItX::Control::ListView - OO interface for ListView32 controls

=head1 SYNOPSIS

    use Win32::AutoItX;

    my $a = Win32::AutoItX->new;

    my $pid = $a->Run('regedit.exe');
    my $window = $a->get_window('Registry Editor');
    $window->wait;
    $window->show;

    my $listview = $window->get_control('SysListView321')->listview();

    for my $i (0 .. $listview->count - 1) {
        print "Item #$i Column 0 = ", $listview->text($i), "\n",
              "\tColumn 1 = ", $listview->text($i, 1), "\n",
              "\tColumn 2 = ", $listview->text($i, 2), "\n";
    }

    $listview->select_all;
    my @selected = $listview->selected;
    print "Selected items = @selected\n";

=head1 DESCRIPTION

Win32::AutoItX::Control::ListView provides an object-oriented interface for
AutoItX methods to operate with ListView32 (SysListView32) controls.

All items/subitems are 0 based. This means that the first item/subitem in a
list is 0, the second is 1, and so on.

In a "Details" view of a ListView32 control, the "item" can be thought of as the
"row" and the "subitem" as the "column".

=cut

use strict;
use warnings;

our $VERSION = '1.00';

use Carp;
use Scalar::Util qw{ blessed };

use overload fallback => 1, '""' => sub { $_[0]->{control}->{control} };

my %Control_Commands = qw{
    deselect       DeSelect
    find           FindItem
    count          GetItemCount
    get_selected   GetSelected
    selected_count GetSelectedCount
    subitem_count  GetSubItemCount
    text           GetText
    is_selected    IsSelected
    select         Select
    select_all     SelectAll
    clear_select   SelectClear
    invert_select  SelectInvert
    change_view    ViewChange
};

=head1 METHODS

=head2 new

    $listview = Win32::AutoItX::Control::ListView->new($control)

creates a ListView object.

=cut

sub new {
    my $class = shift;
    my %self;
    $self{control} = shift;
    croak "The first argument should be a Win32::AutoItX::Control object"
        unless blessed $self{control}
            and $self{control}->isa('Win32::AutoItX::Control');
    return bless \%self, $class;
}
#-------------------------------------------------------------------------------

=head2 selected

    $index = $listview->selected()
    @indexes = $listview->selected()

returns a string containing the item index of selected items. In the scalar
context it returns the first select item only.

=cut

sub selected {
    my $self = shift;
    return split(/\|/, $self->get_selected(wantarray ? 1 : 0));
}
#-------------------------------------------------------------------------------

=head2 find

    $index = $listview->find($string)
    $index = $listview->find($string, $subitem)

returns the item index of the string. Returns -1 if the string is not found.

=head2 count

    $count = $listview->count()

returns the number of list items.

=head2 selected_count

    $selected_count = $listview->selected_count()

returns the number of items that are selected.

=head2 subitem_count

    $subitem_count = $listview->subitem_count()

returns the number of subitems.

=head2 text

    $text = $listview->text($item, $subitem)

returns the text of a given item/subitem.

=head2 is_selected

    $boolean = $listview->is_selected($item)

returns 1 if the item is selected, otherwise returns 0.

=head2 select
    
    $listview->select($index)
    $listview->select($from_index, $to_index)

selects one or more items.

=head2 deselect

    $listview->deselect($index)
    $listview->deselect($from_index, $to_index)

deselects one or more items.

=head2 select_all

    $listview->select_all()

selects all items.

=head2 clear_select

    $listview->clear_select()

clears the selection of all items.

=head2 invert_select

    $listview->invert_select()

inverts the current selection.

=head2 change_view

    $listview->change_view($view)

changes the current view. Valid views are "list", "details", "smallicons",
"largeicons".

=head2 Win32::AutoItX::Control methods

This module also provides most of L<Win32::AutoItX::Control> methods.

=cut

sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://;

    my @params = @_;
    if (exists $Control_Commands{$method}) {
        push @params, '' unless @params;
        push @params, '' if @params < 2;
        unshift @params, $Control_Commands{$method};
        $method = 'clw';
    }
    $self->{control}->$method(@params);
}
#-------------------------------------------------------------------------------

=head1 SEE ALSO

=over

=item L<Win32::AutoItX::Control>

=item L<Win32::AutoItX>

=item AutoItX Help

=back

=head1 AUTHOR

Mikhail Telnov E<lt>Mikhail.Telnov@gmail.comE<gt>

=head1 COPYRIGHT

This software is copyright (c) 2017 by Mikhail Telnov.

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=cut

1;
