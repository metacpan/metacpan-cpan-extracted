#############################################################################
## Name:        Wx::Perl::VirtualTreeCtrl
## Purpose:     TreeCtrl that populates it's children on demand
## Author:      Simon Flack
## Modified by: $Author: andreww $ on $Date: 2006/10/05 14:22:34 $
## Created:     08/10/2002
## RCS-ID:      $Id: VirtualTreeCtrl.pm,v 1.17 2006/10/05 14:22:34 andreww Exp $
#############################################################################

package Wx::Perl::VirtualTreeCtrl;
use strict;
use Exporter;
use Wx;
use Wx::Event 'EVT_TREE_ITEM_EXPANDING';
use Carp;

use vars qw($VERSION @EXPORT_OK @ISA $AUTOLOAD);

@ISA = qw(Wx::EvtHandler Exporter);
@EXPORT_OK = 'EVT_POPULATE_TREE_ITEM';
$VERSION = sprintf'%d.%03d', q$Revision: 1.17 $ =~ /: (\d+)\.(\d+)/;

use constant POPULATE_TREE_ITEM_EVENT => Wx::NewEventType;

sub new {
    my $class = shift;
    my $tree;
    if (@_ == 1) {
        $tree = shift;
        croak "Supplied tree control is not a Wx::TreeCtrl"
            unless ref $tree && $tree->isa('Wx::TreeCtrl');
    } elsif (@_ > 1) {
        $tree = Wx::TreeCtrl->new(@_);
    } else {
        croak "USAGE: $class->new(\$parent, \$id, \$pos, \$size, ...)\n"
            . "or $class->new(\$treectrl)";
    }

    my $self = $class->SUPER::new(); # Wx::EvtHandler
    $self->{_tree_ctrl} = $tree;
    $self->{_tree_ctrl}->PushEventHandler($self);
    return $self;
}

sub EVT_POPULATE_TREE_ITEM ($$$) {
    my ($evt_handler, $self, $callable) = @_;
    my $real_tree = $self->{_tree_ctrl};
    $evt_handler->Connect($real_tree, -1, POPULATE_TREE_ITEM_EVENT, $callable);
    EVT_TREE_ITEM_EXPANDING($self, $real_tree, \&_onExpandItem);
}

# Proxy Wx::TreeCtrl methods to the aggregated tree control
sub AUTOLOAD {
    my $self = shift;
    my ($method) = $AUTOLOAD =~ /.*:(.*)/;
    my $tctl = $self->{_tree_ctrl};
    my $class = ref $tctl;
    croak "Undefined method '$method' in class '$class'"
        unless $tctl->can($method);
    return $tctl->$method(@_);
}

sub AddRoot {
    my $self = shift;
    my $id = $self->GetTree->AddRoot(@_);
    $self->SetItemHasChildren($id, 1);
    return $id;
}

sub GetTree {
    my $self = shift;
    return $self->{_tree_ctrl};
}

sub GetPath {
    my $self = shift;
    my ($item) = @_;

    my @path;
    push @path, $self->{_tree_ctrl}->GetItemText($item);

    my $parent = $self->{_tree_ctrl}->GetItemParent($item);
    while ($parent && $parent->IsOk) {
        push @path, $self->{_tree_ctrl}->GetItemText($parent);
        $parent = $self->{_tree_ctrl}->GetItemParent($parent);
    }
    return reverse @path;
}

# When a Tree item is expanded, trigger a POPULATE_TREE_ITEM_EVENT
sub _onExpandItem {
    my $self = shift;
    my ($event) = @_;

    my $item = $event->GetItem;
    my $populate_evt = $self->_populate_event($item);
    $self->ProcessEvent($populate_evt);

    $event->Skip;
}

sub _populate_event {
    my $self = shift;
    my $item = shift;

    my $event = Wx::Perl::VirtualTreeCtrl::Event->new(
        $self->GetId, POPULATE_TREE_ITEM_EVENT, $item
    );
    $event->SetEventObject($self);

    return $event;
}


############################################################################

package Wx::Perl::VirtualTreeCtrl::Event;

use vars '@ISA';
@ISA = 'Wx::PlCommandEvent';

sub new {
    my $class = shift;
    my ($id, $event_id, $item) = @_;
    my $self = $class->SUPER::new($event_id, $id);
    $self->{_item} = $item;
    return bless $self, $class;
}

# Implement things missing from Wx::PlCommandEvent

sub SetEventObject {
    my $self = shift;
    $self->{_event_object} = shift;
}

sub GetEventObject {
    my $self = shift;
    return $self->{_event_object};
}

sub GetItem {
    my $self = shift;
    return ($self->{_item} || -1);
}

1;

=pod

=head1 NAME

Wx::Perl::VirtualTreeCtrl - Build a tree control on demand

=head1 DERIVED FROM

    Wx::EvtHandler

Standard C<Wx::TreeCtrl> and C<Wx::Window> methods can be used with a virtual
tree control.

=head1 SYNOPSIS

    use Wx::Perl::VirtualTreeCtrl 'EVT_POPULATE_TREE_ITEM';

    my $tree = new Wx::Perl::VirtualTreeCtrl($tree_ctrl);
    EVT_POPULATE_TREE_ITEM($self, $tree, \&AddChildren);
    my $root = $tree->AddRoot($name, $data);
    $tree->Expand($root);

    sub AddChildren {
        my ($self, $event) = @_;

        my $tree = $event->GetEventObject;
        my $item = $event->GetItem;
        my $item_data = $tree->GetPlData($item);

        if ($tree->GetChildrenCount($item, 0)) {
            # update existing children ...

            my ($child, $cookie) = $tree->GetFirstChild($item);
            while ($child && $child->IsOk) {
                my $child_data = $tree->GetPlData($child);
                # synchronise deletions
                if (child_was_deleted($child_data)) {
                    $tree->Delete($child);
                }

                ($child, $cookie) = $tree->GetNextChild($child, $cookie);
            }

        } else {
            # add children for the first time

            my @child_data = expensive_process_to_get_children($item_data);
            foreach (@child_data) {
                my $child = $tree->AppendItem($item, $_->{name});
                # make item expandable if it's a folder
                $tree->SetItemHasChildren($child, 1) if ...;
            }
        }
    }

=head2 DESCRIPTION

This module implements a tree like the Wx::TreeCtrl except that it populates
its items dynamically when nodes in the tree are expanded. You may prefer this
control over the standard tree control when you are populating your tree from a
remote source such as a database, or when your tree is very large.

This module implements the same interface as a standard  C<Wx::TreeCtrl>.

=head2 METHODS

=over 4

=item new ($parent, $id, $pos = wxDefaultPosition, $size = wxDefaultSize, ...)

Returns a new C<Wx::Perl::VirtualTreeCtrl> object. The parameters are the same
as those required by a standard Wx::TreeCtrl.

=item new ($tree_ctrl)

Returns a C<Wx::Perl::VirtualTreeCtrl> object that uses an existing
C<Wx::TreeCtrl> instead of creating its own. You may use this method when your
interface is built using C<Wx::XRC> resources or a third-party tool like
wxGlade.

=item GetPath($item)

Returns a list of item labels from the root item down the provided path

=item GetTree()

Returns a Wx::TreeCtrl suitable for regular C<wxTreeEvent>s and C<Wx::Sizer>
operations

    # Add a virtual tree to a sizer
    $sizer->Add($vtree->GetTree, 1, wxALL|wxGROW, 4);

    # Attach event listener for tree item activation (e.g. double click)
    EVT_TREE_ITEM_ACTIVATED($win, $vtree->GetTree, \&onActivateItem);

=back

=head2 EVENTS

=over 4

=item EVT_POPULATE_TREE_ITEM($event_handler, $virtual_tree, \&event_callback)

The item is being expanded and the control is requesting that part of the tree
be populated.

Your event callback will be passed the C<$event_handler> and event object, as
with other wxCommand events. The event object has the following accessors:

    $event->GetEventObject() # returns the virtual tree control
    $event->GetItem()        # returns the tree item id that is being populated

See the example in L<"SYNOPSIS">.

For further information, see the wxCommandEvent documentation, and the Event
handling overview from the wxWidgets documentation.

=item EVT_TREE_*

Standard C<wxTreeEvent>s can be used with a virtual tree control. See
L<"GetTree()"> for examples.

=back

=head2 SEE ALSO

=over

=item L<Wx::TreeCtrl>

The standard tree control from which this object is derived.

=item L<Wx::Perl::TreeChecker>

A tree control with checkboxes that is compatible with this module (you can
have a virtual tree checker)

=item wxWidgets

L<http:E<sol>E<sol>www.wxwidgets.org>

=item wxPerl

L<http:E<sol>E<sol>wxperl.sourceforge.net>

=back

=head2 AUTHOR

Simon Flack <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 


=cut
