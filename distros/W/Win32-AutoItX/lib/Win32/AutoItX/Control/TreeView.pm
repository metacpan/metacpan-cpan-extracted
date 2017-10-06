package Win32::AutoItX::Control::TreeView;

=head1 NAME

Win32::AutoItX::Control::TreeView - OO interface for TreeView32 controls

=head1 SYNOPSIS

    use Win32::AutoItX;

    my $a = Win32::AutoItX->new;

    my $pid = $a->Run('regedit.exe');
    my $window = $a->get_window('Registry Editor');
    $window->wait;
    $window->show;

    my $treeview = $window->get_control('SysTreeView321')->treeview();
    $treeview->expand('#0');
    for my $i (0 .. $treeview->count('#0') - 1) {
        print "Item #$i = ", $treeview->text("#0|#$i"), "\n";
    }

    $treeview->expand('Computer|HKEY_LOCAL_MACHINE');
    $treeview->select('Computer|HKEY_LOCAL_MACHINE|SOFTWARE');

=head1 DESCRIPTION

Win32::AutoItX::Control::TreeView provides an object-oriented interface for
AutoItX methods to operate with TreeView32 (SysTreeView32) controls.

The C<$item> parameter is a string-based parameter that is used to reference a
particular treeview item using a combination of text and indices. Indices are
0-based. For example:

    Heading1
    ----> H1SubItem1
    ----> H1SubItem2
    ----> H1SubItem3
    ----> ----> H1S1SubItem1
    Heading2
    Heading3


Each "level" is separated by |. An index is preceded with #.
For example:

    Item            $item
    Heading2        "Heading2" or "#1"
    H1SubItem2      "Heading1|H1SubItem2" or "#0|#1"
    H1S1SubItem1    "Heading1|H1SubItem3|H1S1SubItem1" or "#0|#2|#0"

=cut

use strict;
use warnings;

our $VERSION = '1.00';

use Carp;
use Scalar::Util qw{ blessed };

use overload fallback => 1, '""' => sub { $_[0]->{control}->{control} };

my %Control_Commands = qw{
    count      GetItemCount
    exists     Exists
    text       GetText
    is_checked IsChecked
    check      Check
    uncheck    Uncheck
    collapse   Collapse
    expand     Expand
    select     Select
    selected   GetSelected
};

=head1 METHODS

=head2 new

    $treeview = Win32::AutoItX::Control::TreeView->new($control)

creates a TreeView object.

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

=head2 count

    $count = $treeview->count($item)

returns the number of children for a selected item.

=head2 exists

    $boolean = $treeview->exists($item)

returns 1 if an item exists, otherwise 0.

=head2 text

    $text = $treeview->text()

returns the text of an item.

=head2 is_checked

    $checked = $treeview->is_checked($item)

returns the state of an item. 1:checked, 0:unchecked, -1:not a checkbox.

=head2 check

    $treeview->check($item)

checks an item (if the item supports it).

=head2 uncheck

    $treeview->uncheck($item)

unchecks an item (if the item supports it).

=head2 collapse

    $treeview->collapse($item)

collapses an item to hide its children.

=head2 expand

    $treeview->expand($item)

expands an item to show its children.

=head2 select

    $treeview->select($item)

selects an item.

=head2 selected

    $item = $treeview->selected($use_index)

returns the item reference of the current selection using the text reference of
the item (or index reference if C<$use_index> is set to 1).

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
        $method = 'ctw';
    }
    $self->{control}->$method(@params);
}
#-------------------------------------------------------------------------------

=head1 SEE ALSO

=over

=item L<Win32::AutoItX::Control>

=item L<Win32::AutoItX>

=item AutoItX Help

=item https://www.autoitscript.com/autoit3/docs/functions/ControlTreeView.htm

=back

=head1 AUTHOR

Mikhail Telnov E<lt>Mikhail.Telnov@gmail.comE<gt>

=head1 COPYRIGHT

This software is copyright (c) 2017 by Mikhail Telnov.

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=cut

1;
