#############################################################################
## Name:        Wx::Perl::VirtualDirSelector
## Purpose:     A wxDirSelector clone driven by a virtual tree control
## Author:      Simon Flack
## Modified by: $Author: simonf $ on $Date: 2005/08/30 14:05:10 $
## Created:     27/08/2004
## RCS-ID:      $Id: VirtualDirSelector.pm,v 1.8 2005/08/30 14:05:10 simonf Exp $
#############################################################################

package Wx::Perl::VirtualDirSelector;
use strict;
use Wx qw/:id :misc :sizer :dialog/;
use Wx::Event 'EVT_UPDATE_UI';
use Wx::Perl::VirtualTreeCtrl 'EVT_POPULATE_TREE_ITEM';
use Exporter;
use Carp;

use vars qw($VERSION @ISA);

@ISA = qw(Exporter Wx::Dialog);
$VERSION = sprintf'%d.%03d', q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;

sub new {
    my $class = shift;
    my ($parent, $id, $dir_populator, $message, $root_data, $style, $pos) = @_;
    croak("VirtualDirSelector: Invalid window id") unless $id;
    croak("VirtualDirSelector: Invalid populator") unless $dir_populator;
    $parent    ||= Wx::wxTheApp->GetTopWindow;
    $message   ||= "Select a directory";
    $root_data ||= "";
    $style     ||= wxDEFAULT_DIALOG_STYLE;
    $pos       ||= wxDefaultPosition;

    # Set up the dialog
    my $self = $class->SUPER::new($parent, $id, '', $pos, wxDefaultSize, $style);
    $self->_load_dialog($message);
    $self->SetImageList(_image_list());

    # Add the custom populator
    EVT_POPULATE_TREE_ITEM($self, $self->{tree}, $dir_populator);
    my $root = $self->{tree}->AddRoot('/');
    $self->{tree}->SetPlData($root, $root_data);
    $self->{tree}->SetItemHasChildren($root, 1);
    $self->SetRootItemSelectable(1);

    return $self;
}

sub ExpandRoot {
    my $self = shift;
    my $root = $self->{tree}->GetRootItem;
    $self->{tree}->Expand($root);
}

sub SetRootItemSelectable {
    my $self = shift;
    my ($is_selectable) = @_;
    $self->{root_item_selectable} = !!$is_selectable;
}

sub SetRootLabel {
    my $self = shift;
    my ($label) = @_;
    my $root = $self->{tree}->GetRootItem;
    $self->{tree}->SetItemText($root, $label);
}

sub SetRootImage {
    my $self = shift;
    my ($image, $which) = @_;
    my $root = $self->{tree}->GetRootItem;
    $self->{tree}->SetItemImage($root, $image, $which);
}

sub SetImageList {
    my $self = shift;
    my ($image_list) = @_;
    $self->{image_list} = $image_list;
    $self->{tree}->SetImageList($self->{image_list});
}

sub GetSelection {
    my $self = shift;
    my $selection = $self->{tree}->GetSelection();
    return $self->{tree}->GetPlData($selection);
}

sub GetSelectedPath {
    my $self = shift;
    my $selection = $self->{tree}->GetSelection();
    return $self->{tree}->GetPath($selection);
}

sub _load_dialog {
    my $self = shift;
    my ($label) = @_;

    $self->SetTitle('Browse for folder');
    $self->SetSize([318,308]);

    my $dialog_message = new Wx::StaticText(
        $self, -1, $label, wxDefaultPosition, [-1,40]
    );

    $self->{tree} = new Wx::Perl::VirtualTreeCtrl(
        $self, -1, wxDefaultPosition, [300,180]
    );

    my $sizer = new Wx::BoxSizer(wxVERTICAL);
    $sizer->Add($dialog_message, 0, wxALL, 5);
    $sizer->Add($self->{tree}->GetTree, 0, wxALL, 5);

    my $btn_sizer = new Wx::BoxSizer(wxHORIZONTAL);
    $btn_sizer->Add(new Wx::Button($self, wxID_OK, 'OK'), 0, wxALL, 2);
    $btn_sizer->Add(new Wx::Button($self, wxID_CANCEL, 'Cancel'), 0, wxALL, 2);

    $sizer->Add($btn_sizer, 0, wxALL|wxALIGN_RIGHT, 5);

    $self->SetSizer($sizer);
    $self->Layout;

    EVT_UPDATE_UI($self, wxID_OK, \&_on_update_ui);

    return $self;
}

sub _on_update_ui {
    my $self = shift;
    my ($event) = @_;

    my $enable = 0;
    if ($self->{root_item_selectable}) {
        $enable = 1 if $self->{tree}->GetSelection();
    } else {
        my $root = $self->{tree}->GetRootItem();
        $enable = 1 unless $self->{tree}->IsSelected($root);
    }
    $event->Enable($enable);
}

my $icon;
sub _icon {
    return $icon if $icon;
    $icon = [ map { m/^"(.*)"/ ? ( $1 ) : () } <DATA> ];
}

sub _image_list {
    my $image_list = new Wx::ImageList(16,16);
    $image_list->Add(Wx::Icon -> newFromXPM(_icon()));
    return $image_list;
}

1;

=pod

=head1 NAME

Wx::Perl::VirtualDirSelector - A "virtual" clone of the standard DirSelector

=head1 DERIVED FROM

    Wx::Dialog

=head1 SYNOPSIS

    use Wx::Perl::VirtualDirSelector;

    my $dirsel = new Wx::Perl::VirtualDirSelector(
        undef, -1, \&OnDirPopulate, 'Select a folder', 'c:\\'
    );

    $dirsel->SetRootLabel('/');
    $dirsel->ExpandRoot();

    if ($dirsel->ShowModal() == wxID_OK) {
        Wx::MessageBox(sprintf "you selected '%s'", $dirsel->GetSelection);
    }


=head2 DESCRIPTION

A clone of the standard windows DirSelector (wxDirSelector()), driven by a
Wx::Perl::VirtualTreeCtrl.

=head2 METHODS

=over 4

=item new ($parent, $id, \E<amp>dir_populator, $message, $root_data, $style,
$pos)

Returns a virtual dir selector (C<@ISA Wx::Dialog>)

    $parent         - parent window (default: TopWindow)
    $id             - window id
    \&dir_populator - coderef to populate virtual tree control
    $message        - Selection prompt (default: 'Select a directory')
    $root_data      - Data assigned to the root item (default: '')
    $style          - dialog style (default: wxDEFAULT_DIALOG_STYLE)
    $pos            - dialog position (default: wxDefaultPosition)

C<E<amp>dir_populator> is a Wx::Perl::VirtualTreeCtrl event callback.

=item ExpandRoot()

Expand the root Item

=item GetSelection()

Returns the data for the selected tree item.

=item GetSelectedPath()

Returns a list of path elements from the root node to the selected node.

See the documentation for C<Wx::Perl::VirtualTreeCtrl::GetPath> for more
information.

=item SetImageList($wx_imagelist)

Set a custom Wx::ImageList for the tree control

=item SetRootItemSelectable(bool)

If FALSE, the C<OK> button will be greyed-out when the root item is selected.

Default: TRUE

=item SetRootLabel($label)

Set the root item's text label

=item SetRootImage($image_id, [$which])

Set the root item's image. See Wx::TreeCtrl::GetItemImage for an explanation of
the optional C<$which> parameter.

=back

=head2 SEE ALSO

=over 4

=item L<Wx::TreeCtrl>

The standard tree control from which this object is derived.

=item L<Wx::Perl::VirtualTreeCtrl>

A tree control that is populated dynamically.

=item wxWidgets

L<http://www.wxwidgets.org>

=item wxPerl

L<http://wxperl.sourceforge.net>

=back

=head2 AUTHOR

Simon Flack <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut

__DATA__
/* XPM */
static char * folder_xpm[] = {
"16 16 52 1",
" 	c #FFFFFF",
".	c #CC9934",
"+	c #CB9833",
"@	c #C99631",
"#	c #C7942F",
"$	c #DFDFDF",
"%	c #F6F6F6",
"&	c #C28F2A",
"*	c #C8C8C8",
"=	c #FFFF99",
"-	c #BD8A25",
";	c #BA8722",
">	c #B7841F",
",	c #B5821D",
"'	c #B3811B",
")	c #B07E18",
"!	c #F7F7F7",
"~	c #FFF791",
"{	c #FFF48E",
"]	c #AE7C16",
"^	c #8C8C8C",
"/	c #DEDEDE",
"(	c #FFEB85",
"_	c #FFE681",
":	c #C5922D",
"<	c #C08D28",
"[	c #BC8924",
"}	c #B88520",
"|	c #B4811C",
"1	c #FFE07B",
"2	c #A3710B",
"3	c #FFD46F",
"4	c #F8C560",
"5	c #A06E08",
"6	c #6E6E6E",
"7	c #FFCC67",
"8	c #EFBC57",
"9	c #9E6C06",
"0	c #6D6D6D",
"a	c #E6B34E",
"b	c #9C6A04",
"c	c #BF8C27",
"d	c #DCA944",
"e	c #9A6802",
"f	c #D3A03B",
"g	c #996701",
"h	c #AB7913",
"i	c #A87610",
"j	c #A5730D",
"k	c #4C4C4C",
"l	c #838383",
"m	c #D6D6D6",
"                ",
"  .+@#$%        ",
" .    &*%       ",
". ==== -;>,')$! ",
"+~{{{{{     ]^/ ",
"@(_::::::<[}|''$",
"#1:         _ 2^",
":3.=========4=56",
"&7+=~~~~~~~~8=90",
"<7:=((((((((a=b0",
"-7c=11111111d=e0",
";7}=33333333f=g6",
"$,')]hij259begkl",
"%*l00000000000l*",
" %$mmmmmmmmmmm$%",
"                "};
