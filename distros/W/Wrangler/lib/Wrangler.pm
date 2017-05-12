package Wrangler;

use strict;
use warnings;

use Wrangler::PubSub;
use Wrangler::Config;
use Wrangler::PluginManager;
use Wrangler::FileSystem::Layers;
use Wrangler::Wx::App;

our $VERSION = 2.15;
our $log = 0;
our $wishlist;

sub new {
	my $class = shift;
	my $self = bless {
		appname	=> 'Wrangler',
		version	=> $VERSION,
		@_
	}, $class;

	## load config
	Wrangler::Config::read();

	## simple CLI switch parsing
	if(@ARGV){
		for(@ARGV){
			if($_ eq '--debug'){
				$self->{debug} = 1;
				$log = 1; # $log is non-OO for efficiency
			}elsif($_ =~ /^\/|^\\/){
				$Wrangler::Config::env{CLI_ChangeDirectory} = $_;
			}
		}
	}

	## establish PluginManager
	Wrangler::PluginManager::load_plugins($self);

	## establish our virtual file-system
	$self->{fs} = Wrangler::FileSystem::Layers->new();

	Wrangler::PubSub::subscribe('file.activated', \&OnActivated,__PACKAGE__);
	Wrangler::PubSub::subscribe('main.menubar.toggle', sub {
		$self->{main}->OnToggleMenuBar($_[0]);
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('main.navbar.toggle', sub {
		$self->{main}->OnToggleNavbar($_[0]);
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('main.sidebar.toggle', sub {
		$self->{main}->OnToggleSidebar($_[0]);
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('main.statusbar.toggle', sub {
		$self->{main}->OnToggleStatusBar($_[0]);
	},__PACKAGE__);
	Wrangler::PubSub::subscribe('main.formeditor.recreate', sub {
		$self->{main}->OnReCreateFormEditor($_[0]);
	},__PACKAGE__);
	Wrangler::PubSub::publish('status.update', "Init complete");

	return $self;
}

sub config {
	Wrangler::Config::config(@_);
}

sub debug {
	print $_[0] . "\n" if $log;
}

sub wishlist {
	# use Data::Dumper;
	# print 'Wrangler::wishlist:'.Dumper($wishlist);
	return [ keys %$wishlist ];
}

sub run {
	my $self = shift;

	## create the Wx App and its main window
	my $app = Wrangler::Wx::App->new();	# Create the application object
	$self->{main} = $app->create($self);
	$app->MainLoop;				# Start event processing
}

sub OnActivated {
	Wrangler::debug("Main:: received event 'file.activated': @_");
	my ($path,$richlist_item) = @_;

	if($richlist_item->{'MIME::mediaType'}){
		my $viewers = $Wrangler::Config::settings{'openwith'};
		if( $viewers->{ $richlist_item->{'MIME::mediaType'} . '/*' } ){
			Wrangler::debug(" mediaType ".$richlist_item->{'MIME::mediaType'} ." has association ". $viewers->{ $richlist_item->{'MIME::mediaType'} . '/*' } .", appending path $richlist_item->{'Filesystem::Path'}) ");
			my $pid = ForkAndExec($viewers->{ $richlist_item->{'MIME::mediaType'} . '/*' }, $richlist_item->{'Filesystem::Path'} );
			Wrangler::PubSub::publish('status.update',"Launched external viewer with pid $pid");
			return;
		}
	}

	Wrangler::debug("No viewer associated or MIME::mediaType unknown. returning. ");
}

sub ForkAndExec {
	my @commands = @_;

	my $pid = fork();

	print STDERR "unable to fork: $!" unless defined($pid);
	return undef unless defined($pid);

	# contains no pid when we're in the forked child
	if(!$pid){
		exec(@commands);
		die "unable to exec: $!";
	}

	return $pid if $pid;
}

sub DESTROY {
	Wrangler::debug("Wrangler::DESTROY");

	## store config if it has changed
	Wrangler::Config::write()
}

1;

__END__

=pod

=head1 NAME

Wrangler - File manager with sophisticated metadata handling capabilities

=head1 DESCRIPTION

Extended file attributes are a very versatile and powerful extension of traditional
file system semantics. Yet, most end-user applications ignore xattribs, or in cases
where an app choses to make xattribs accessible for the average user, the actual
user-interface is hidden in "file properties" sub menus, or cumbersome to use.

Wrangler is a "file manager"-like application that puts file metadata first, offering
xattribs and other metadata alongside traditional metadata (size,type,mtime,...)
in all of it's views. The application was designed to browse and manage large collections
of multimedia content files, digital assets, and their associated metadata.

A modular application-layout in combination with a Plugin facility makes Wrangler
adaptable to most workflows or work environments. The central file-browser can be
complemented with a Navbar and Sidebar widget, for comfortable browsing, or with
more specialised multimedia widgets: Wrangler's image/video Previewer or the Metadata-Editor.
If you try only one feature, and you haven't used xattribs until now, then test
the Previewer. It reads preview-thumbnails embedded into JPEGs and takes the lag
out of browsing large image file collections - without maintaining an additional
database.

Wrangler is not meant as a replacement for your primary file manager. L<SEE ALSO>
lists a number of very capable file managers. Wrangler is primarily a metadata handling
application, while it also offers the interface and most functionalities commonly
found in file-managers for navigating filesystems and selecting files. But if you
end up using Wrangler for everyday file browsing, that's okay with us.

=head1 SCREENSHOTS

=begin HTML

<div>
<a href="https://raw.github.com/clipland/wrangler/master/screenshot1.png"><span><img src="https://raw.github.com/clipland/wrangler/master/screenshot1_small.png" width="400" height="300" alt="Screenshot 1" style="border: 1px solid #888;" /></span></a>
<a href="https://raw.github.com/clipland/wrangler/master/screenshot2.png"><span><img src="https://raw.github.com/clipland/wrangler/master/screenshot2_small.png" width="400" height="300" alt="Screenshot 1" style="border: 1px solid #888;" /></span></a>
</div>

=end HTML

L<Screenshot 1|https://raw.github.com/clipland/wrangler/master/screenshot1.png>
L<Screenshot 2|https://raw.github.com/clipland/wrangler/master/screenshot2.png>

=head1 UNIQUE FEATURES

FileBrowser is able to display arbitrary metadata. Most file-managers offer only
a hardcoded or limited set of file attributes for display in the columns of a directory
listing, mostly traditional stat values. Wrangler can display user-configurable
metadata from Filesystem, the Extended Attributes and MIME details in any order.

FileBrowser's file-listing behaviour is just as configurable. Users can adapt it
to a number of different browsing or interface styles: File listings can offer the
up-dir "..". Or a Navbar on top can be used to display clickable directory "bread crumbs"
instead. More display options are zebra-striping or media-file highlighting.

Wrangler tries to offer users a "glimpse into files" while traversing directories.
This includes a configurable metadata editor, which can also be used to edit writable
file properties. But also the Previewer, a widget that displays image previews (embedded
thumbnails first, which makes it very fast) and extracts stills from video files,
which in turn can easily be saved to disk.

Although Drag'n'Drop is currently missing, Wrangler's "Paste" operations are a bit
more elaborate. In FileBrowser, users can paste files traditionally, but also as
symlinks. In addition to that, when Bitmap data is on the Clipboard, users can
"Paste ...as image", to write out clipped image data as files - which is handy for
screen captures.

As part of the official release comes the ColourLabels Plugin, which enables users
to label files with colours from a fixed, Mac-compatible set.

=head1 KNOWN ISSUES

Wrangler's unreleased 1.x branch has been used in a production environment for many
years now. The present 2.x branch is based on proven code and shares many principles
with its predecessor, still it also introduced quite an amount of new code. As Wrangler
handles valuable data assets, underlying file-related operations have received much
attention and should be safe. That said, Wrangler is also a work in progress, and bugs
or unexpected behaviour may occur at any time.

The list of known issues may appear long. But we thinks it's better to inform than
to pretend. So please read on and decide if anything on this incomplete list of
known issues affects your usage scenario:

=over

=item *

When user-input is processed, from Wx LabelEdits or TextInput fields, UTF-8 handling
is not perfect and not thoroughly tested. That affects file renames, directory and
file creation.

=item *

Internal path handling in relation to symlinks and paths with /../ fragments may
have issues.

=item *

File-browser: When the listing is refreshed, selections are remembered. This is done
internally with a lookup-hash based on file-paths. For refreshes after renames,
mkdir, etc. where the file list is changed, the restored selection is incomplete.

=item *

Previewer complains about file not found after renames in FileBrowser.

=item *

Previewer mouse-wheel zooming behaves erratically when pointer is moved between zooms.
Also, the displayed image is magnified but not really zoomed (in terms of resolution).

=item *

File-browser: Renderer used to display metadata in columns is not configurable, for
example date is set to ISO-Date.

=item *

File-browser is currently only available as ListCtrl, as WxPerl's TreeListCtrl is 
not yet ready for primetime. But if you are interested, an unfinished FileBrowserTreeList
is included in the release.

=item *

Copy-and-paste'ing an item within the same directory would result in two items of
the same name in one directory - which most filesystems do not allow. In these cases
Wrangler appends the string '_copy' to each new item. This could be improved by
adding this string between basename and optional suffix.

=item *

There's no "combine folders" functionality upon copying/moving one folder into some
other directory which already contains another folder of the same name.

=item *

Drag-and-Drop of files and folders, internally and in combination with other applications,
is not yet implemented.

=item *

The Sidebar widget is currently Linux only, as it relies on Linux Trash locations,
Linux GTK bookmarks etc. Also, you can't change entries via UI, only by manually
editing the gtk bookmarks file, or using another app to do so.

=item *

The Navbar widget does not look at path length, so the end of longer/ deep paths
might become unclickable by disappearing under the right side of the application's
border.

=item *

Widget layout is not fully configurable and modified splitter sash positions are
not remembered by the application.

=item *

Internal metadata abstraction is not as abstract as it should be. For example, far
too often low-level file functions like rename() are called directly, instead of
relying on an abstract interface that regards a filename as "just another file-object
property".

=item *

As of this release, Wrangler 2.x only ships with a file-system abstraction for *nix
systems. Windows (NTFS) and OS X adapters are todo.

=item *

When files/folders are moved across filesystem-boundaries, there's no check or compensation
yet, for when the target fs is not able to store xattribs. So xattr, if set, will
get lost when you do that.

=item *

There's no progress indicator for file-operations, so copying/ moving a large file,
for example, won't pop-up a (cancellable) progress-dialogue.

=item *

The Plugin facility is a work-in-progress and its API is expected to change
over the next revisions.

=item *

User selected "Value Shortcuts" are not checked for a possible overlap with existing
(system) keyboard shortcuts.

=item *

Filesystem changes are currently only monitored with a simple pull-scheme, where
mtime is checked in a configurable interval. Once Wx 2.9 enters 'stable', this
could be replaced with push/ inotify like bindings.

=item *

Wrangler 2.x is English only, no translations/ localisations/ i18n yet.

=back

=head1 SEE ALSO

Wrangler's official homepage is at L<http://www.clipland.com/wrangler>.

As said, Wrangler is not meant as a perfect file-manager. If you are looking for
fully-fledged file-managers, then there's Nautilus, Thunar, Marlin, PCmanFM or
Konquerer on Linux, on OS X there's Finder and on Windows you'd have Windows/File
Explorer. Also, if you are working solely with images, L<ExifTool|Image::ExifTool>
and GUIs for it, like ExifToolGUI on Windows, might be more helpful. And there are
a number of dedicated solutions for audio file "tagging", like EasyTAG or Picard
which you might consider for sole audio file handling.

=head1 CONTRIBUTE

As with most Perl programs, Wrangler's source-code is open. And as such it can be
modified by the user. However, we ask you to report back any bugfixes or improvements.
Also, as Wrangler's license does not allow to redistribute a modified Wrangler as
a whole, certain restrictions apply for submitting patches via public "forks".
Please read the exact licensing terms if you want to work on the source or contribute
code.

L<Wrangler's public repository|https://github.com/clipland/wrangler> is currently
on github.

=head1 AUTHOR

Clipland GmbH L<http://www.clipland.com/>

=head1 COPYRIGHT

Copyright 2009-2014 Clipland GmbH. All rights reserved.

=head1 LICENSE

Wrangler is dual-licensed under the I<Wrangler Non-Commercial License> for private,
non-commercial use, free-of-charge; and under a purchasable license for commercial,
institutional and educational use. Please contact Clipland at L<http://www.clipland.com/wrangler>
to buy commercial licenses.

Please note that Wrangler's license keeps it from being L<officially "open source" software|http://opensource.org/faq#avoid-unapproved-licenses>.
Nor is it GNU "free software", as it permits only one (freedom 2) of the L<four freedoms|http://www.gnu.org/philosophy/free-sw.html>.

Wrangler falls into Debian's non-free software category, as the Wrangler Licenses
do not allow derived works, which would be rule 3 of the L<Debian Free Software Guidelines (DFSG)|https://www.debian.org/doc/debian-policy/ch-archive.html>.

Wrangler relies on a number of Perl modules and the WxWidgets toolkit. If you are
interested in the licensing and copyright status of these modules, please have a
look at Makefile.PL which contains some notes.
