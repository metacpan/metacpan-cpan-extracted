package Wrangler::Plugin::ColourLabels;

use strict;
use warnings;

use Wx ('wxITEM_RADIO');

our @osx_colours = ('None','Orange', 'Red', 'Yellow', 'Blue', 'Purple', 'Green', 'Gray');
our @osx_colour_values = (
	[0,0,0],	# "None"
	[255,200,60],	# ffc83c 2
	[255,138,138],	# ff8a8a 1
	[255,240,40],	# fff028 3
	[150,210,255],	# 96d2ff 5
	[235,180,255],	# ebb4ff 6
	[190,240,40],	# bef028 4
	[200,200,200],	# c8c8c8 7
);

sub new { my $class = shift; return bless({ wrangler => $_[0] }, $class); }

sub plugin_name { return 'ColourLabels'; }

sub plugin_info { return "Adds colour labeling to FileBrowser. Colour labels are stored in the OS X compliant extended attribute (xattr) \"kMDItemFSLabel\" of files and directories."; }

sub plugin_phases {
	return { wrangler_startup => 1, file_context_menu => 1, directory_listing => 1 };
}

sub wrangler_startup {
	my $self = shift;

	$Wrangler::wishlist->{'Extended Attributes::kMDItemFSLabel'} = 1;

	return 1;
}

sub file_context_menu {
	my $self = shift;
	my $menu = shift;
	my $selections = shift;

	$self->{menu_entries} = [];

	my $menuItem = Wx::MenuItem->new($menu, -1, 'Label X (remove)', 'Label X (remove)', wxITEM_RADIO);
	push(@{ $self->{menu_entries} }, [
		$menuItem,
		sub { $self->Delete($selections); },
		sub { $menuItem->Check(1); }
	]);

	my $has_colour;
	for(@$selections){
		$has_colour = $_->{'Extended Attributes::kMDItemFSLabel'} if $_->{'Extended Attributes::kMDItemFSLabel'};
	}

	for my $colourId (1..$#osx_colours){
		my $menuItem = Wx::MenuItem->new($menu, -1, 'Label "'.$osx_colours[$colourId].'"', 'Label "'.$osx_colours[$colourId].'"', wxITEM_RADIO); # ."\t$colourId"

		push(@{ $self->{menu_entries} }, [
			$menuItem,
			sub { $self->Set($selections, $colourId); },
			sub { $menuItem->Check(1) if $has_colour && $has_colour == $colourId; }
		]);
	}

	return $self->{menu_entries};
}

sub directory_listing {
	my $self = shift;
	my $filebrowser = shift;
	my $itemId = shift;
	my $richlist_item = shift;

	my $colourId = $richlist_item->{'Extended Attributes::kMDItemFSLabel'};
	$filebrowser->SetItemBackgroundColour($itemId, Wx::Colour->new(@{ $osx_colour_values[$colourId] }) ) if $colourId;
}

sub Set {
	my $self = shift;
	my $selections = shift;
	my $colourId = shift;

	for(@$selections){
		Wrangler::debug("Plugin::ColourLabels::Set: setting colourId:$colourId ($osx_colours[$colourId]) on $_->{'Filesystem::Path'}");
		my $ok = $self->{wrangler}->{fs}->set_property($_->{'Filesystem::Path'}, 'Extended Attributes::kMDItemFSLabel', $colourId);
	}
	Wrangler::PubSub::publish('filebrowser.refresh');
}

sub Delete {
	my $self = shift;
	my $selections = shift;
	my $colourId = shift;

	for(@$selections){
		Wrangler::debug("Plugin::ColourLabels::Set: deleting metadata-key 'Extended Attributes::kMDItemFSLabel'");
		my $ok = $self->{wrangler}->{fs}->del_property($_->{'Filesystem::Path'}, 'Extended Attributes::kMDItemFSLabel');
	}
	Wrangler::PubSub::publish('filebrowser.refresh');
}

1;

__END__

=pod

=head1 NAME

Wrangler::Plugin::ColourLabels - Colour labeling for files and directories in Wrangler

=head1 DESCRIPTION

Does what it says on the tin. When activated, this Plugin enables users to label
files and folders (arbitrary inodes) with a colour. This has the effect that FileBrowser
(and possibly other contexts as well) associate a colour with this file/dir, change
it's background colour from usually white to the selected one. This helps users
with the organisation of files and folders.

The status of this Plugin is a work-in-progress. OS X interoperability is largely
untested.

=head1 BACKGROUND

Colour labeling is mostly known to people coming from Macintosh OS X, where I<Finder>
allows users to "label" files with a colour, one of 7, mutually exclusive. The actual
metadata is written into a file's/ directory's I<user.kMDItemFSLabel> extended attribute
(xattr), which means that labeling-info sometimes ends up in the (hidden/ sidecar)
file I<.DS_Store> on filesystems that do not support xattribs.

The name "kMDItemFSLabel" seems to come from a vocabulary of Apple internal I<MDItem*>
constants, each prefixed with a lower-cased I<k>, then a namespace reference "FS"
for a file-system scope, and then the pointer to its function, "labeling". The values
of this key range from 0-7, referencing an, again, Apple specific list of colours: None,
Orange, Red, Yellow, Blue, Purple, Green, Gray.

As this is pretty much a de-facto standard, with Apple being first here and many
people using it and relying on this attribute, this scheme is used as the default 
internal way Wrangler::Plugin::ColourLabels stores colour labeling information.

B<Other schemes>

On Linux, some file-managers do support file-labeling. The downside is that each
implements a different, unportable approach. All of them break with the unwritten
law of keeping metadata "as close" to an object as possible. Nautilus at one point
allowed files to be emblemised and colour-labeled, storing the data about that in
GNOME's GVFS, which maintains an internal database which is queried with every gvfs-info
call. But Nautilus dropped support for these functions and even Add-Ons meant to
bring that back are currently unusable.

Marlin allows users to "Set a Colour" for directory items, one from a set of 9.
The actual labeling information is then saved to a Marlin-specific SQLite database
stored in Marlin's per-user ~/.config sub-directory. And this database stores numeric
values mapped to a Marlin-internal colour "vocabulary".

Thunar solves this in a very similar way, but takes it one step further by storing
labeling information in a proprietary ThunarDB (.tdb) file-database.

Both approaches render file/directory colour labeling as opaque for other applications
or services. Upcoming releases of this Plugin here may offer a facility that allows
very basic export and/or using of all these stores in parallel.

=head1 SEE ALSO

As of this writing, the freedesktop project hasn't proposed any metadata keys
for colour-labeling directory items. Compare L<CommonExtendedAttributes|http://www.freedesktop.org/wiki/CommonExtendedAttributes/>

L<Apple Spotlight Metadata Attributes|https://developer.apple.com/library/mac/documentation/Carbon/Reference/MetadataAttributesRef/Reference/CommonAttrs.html>

=head1 COPYRIGHT & LICENSE

This module is part of L<Wrangler>. Please refer to the main module for further
information and licensing / usage terms.
