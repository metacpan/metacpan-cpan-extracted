package Tk::GtkSettings;

=head1 NAME

Tk::GtkSettings - Give Tk applications the looks of Gtk applications

=cut

use strict;
use warnings;
use File::Basename;
our $VERSION = '0.04';

use Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	$delete_output
	$gtkpath
	$verbose
	$out_file
	alterColor
	appName
	convertColorCode
	export2file
	export2Xdefaults
	export2xrdb
	export2Xresources
	groupAdd
	groupAll
	groupDelete
	groupExists
	groupMembers
	groupMembersAdd
	groupMembersReplace
	groupOption
	groupOptionAll
	groupOptionDelete
	gtkKey
	gtkKeyAll
	gtkKeyDelete
	hex2rgb
	hexstring
	initDefaults
	loadGtkInfo
	platformPermitted
	removefromFile
	removeFromXdefaults
	removeFromXresources
	removeFromxrdb
	resetAll
	rgb2hex
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} });

our @EXPORT = qw(
	applyGtkSettings
);

sub appName;
sub export2xrdb;
sub generateOutput;
sub initDefaults;
sub loadGtkInfo;
sub platformPermitted;
sub resetAll;

our $delete_output = 1;
our $gtkpath;
our $verbose = 0;
our $out_file;

if (platformPermitted) {
	$gtkpath = $ENV{HOME} . "/.config/gtk-3.0/";
	$out_file = $ENV{HOME} . "/.tkgtksettings";
}

my $no_gtk = 0;
my %gtksettings = ();
my %groups = (main => [[''], {}]);
my $app_name = basename($0);
my $marker;

my @basegtkeys = qw(
	theme_fg_color
	theme_bg_color
	theme_text_color
	theme_base_color
	theme_view_hover_decoration_color
	theme_hovering_selected_bg_color
	theme_selected_bg_color
	theme_selected_fg_color
	theme_view_active_decoration_color
	theme_button_background_normal
	theme_button_decoration_hover
	theme_button_decoration_focus
	theme_button_foreground_normal
	theme_button_foreground_active
	borders
	warning_color
	success_color
	error_color
	theme_unfocused_fg_color
	theme_unfocused_text_color
	theme_unfocused_bg_color
	theme_unfocused_base_color
	theme_unfocused_selected_bg_color_alt
	theme_unfocused_selected_bg_color
	theme_unfocused_selected_fg_color
	theme_button_background_backdrop
	theme_button_decoration_hover_backdrop
	theme_button_decoration_focus_backdrop
	theme_button_foreground_backdrop
	theme_button_foreground_active_backdrop
	unfocused_borders
	warning_color_backdrop
	success_color_backdrop
	error_color_backdrop
	insensitive_fg_color
	insensitive_base_fg_color
	insensitive_bg_color
	insensitive_base_color
	insensitive_selected_bg_color
	insensitive_selected_fg_color
	theme_button_background_insensitive
	theme_button_decoration_hover_insensitive
	theme_button_decoration_focus_insensitive
	theme_button_foreground_insensitive
	theme_button_foreground_active_insensitive
	insensitive_borders
	warning_color_insensitive
	success_color_insensitive
	error_color_insensitive
	insensitive_unfocused_fg_color
	theme_unfocused_view_text_color
	insensitive_unfocused_bg_color
	theme_unfocused_view_bg_color
	insensitive_unfocused_selected_bg_color
	insensitive_unfocused_selected_fg_color
	theme_button_background_backdrop_insensitive
	theme_button_decoration_hover_backdrop_insensitive
	theme_button_decoration_focus_backdrop_insensitive
	theme_button_foreground_backdrop_insensitive
	theme_button_foreground_active_backdrop_insensitive
	unfocused_insensitive_borders
	warning_color_insensitive_backdrop
	success_color_insensitive_backdrop
	error_color_insensitive_backdrop
	link_color
	link_visited_color
	tooltip_text
	tooltip_background
	tooltip_border
	content_view_bg
);

my @contentwidgets = qw(
	CodeText
	Entry
	FloatEntry
	PodText
	Spinbox
	Text
	TextUndo
	TextEditor
	ROText
);

my @listwidgets = qw(
	Dirlist
	DirTree
	HList
	IconList
	Listbox
	Tlist
	Tree
);

my %mainoptions = qw(
	background           theme_bg_color
	foreground           theme_fg_color
	font                 gtk-font-name
	activeBackground     tk-active-background
	activeForeground     theme_fg_color
	backPageColor        tk-through-color
	highlightBackground  theme_bg_color
	highlightColor			theme_hovering_selected_bg_color
	inactiveBackground   tk-through-color
	insertBackground     theme_fg_color
	selectBackground     theme_selected_bg_color
	selectForeground     theme_selected_fg_color
	troughColor          tk-through-color
);

my %contentoptions = qw(
	background           content_view_bg
	highlightColor			theme_bg_color
);

my %listoptions = qw(
	background           content_view_bg
	highlightColor			theme_bg_color
);


appName(basename($0));

=head1 SYNOPSIS

=over 4

 use Tk::GtkSettings;
 applyGtkSettings;
 
 #or
 
 use Tk::GtkSettings qw(initDefaults export2xrdb);
 initDefaults;
 #do your adjustments here
 export2xrdb;
 
 #then initialize your perl/Tk app.
 
 use Tk;
 my $w = new MainWindow;
 
 #Do your stuff here
 
 $w->MainLoop;

=back

=head1 ABSTRACT

Apply Gtk colors and fonts to your perl/Tk application

=head1 DESCRIPTION

Tk::GtkSettings attempts to overcome some very old complaints about Tk: 

 - It's ugly!
 - It's complicated to adjust colors and fonts to your desktop style

Tk::GtkSettings loads your Gtk configuration files and applies it's font and color settings to your perl/Tk application.

B<initDefaults> loads some nice (at least we think so) default settings that copies your Gtk theme pretty well.

However, it gives plenty of tools for you to adjust it and mess it up any way you like.

It is harmless to install on Windows or Mac. It just will not do anything on these systems. That makes it
smooth to add as a dependency to your own package if you want it to be able to run on Windows and Mac as well.

In working with colors it assumes 8-bit color depth.

=head1 EXPORTS

=over 4

=item B<$delete_output>

=over 4

Usefull for testing and debugging. B<export2xrdb> exports to a file which then is sent to xrdb. 
It checks if this file should be deleted when done. Default value is 1.

=back

=item B<$gtkpath>

=over 4

Usefull for testing. Default value is ~/.config/gtk-3.0/. That is the location where the
Gtk configuration files reside. This variable is not defined when on Windows or Mac.

=back

=item B<$out_file>

=over 4

Default value ~/.tkgtksettings. Used by B<export2xrdb>. This variable is not defined
on Windows or Mac.

=back

=item B<$verbose>

=over 4

Usefull for testing and debugging. Default value is 0. If set B<Tk::GtkSettings> will 
complain about everything not in order. Otherwise it will quietly fail.

=back

=item B<alterColor>(I<$hexcolor>, I<$offset>)

=over 4

Adjusts $hexcolor by $offset. It takes every color chanel and adds or substracts $offset.
If the channel value is greater than 127 it will substract, otherwise it will add.

 alterColor('#000000', 1) returns #010101
 alterColor('#FFFFFF', 1) returns #FEFEFE

=back

=cut

sub alterColor {
	my ($hex, $offset) = @_;
	my @rgb = hex2rgb($hex);
	my @rgba = ();
	for (@rgb) {
		if ($_ < 128) {
			my $c = $_ + $offset;
			$c = 0 if $c < 0;
			push @rgba, $c
		} else {
			my $c = $_ - $offset;
			$c = 255 if $c > 255;
			push @rgba, $c
		}
	}
	return rgb2hex(@rgba)
}

=item B<applyGtkSettings>

=over 4

Just making life easy. Call this one and your done, unless you require adjustments.
It calls B<initDefaults> and exports the whole bunch to xrdb.
Exported by default.

=back

=cut

sub applyGtkSettings {
	initDefaults;
	export2xrdb;
}

=item B<appName>(I<$name>)

=over 4

Sets and returns your application name. By default it is set to the basename of what is in B<$0>. Your Gtk settings
will only be applied to your application in xrdb. You can set it to an empty string. Then it will 
apply your Gtk settings to all your perl/Tk applications.

=back

=cut

sub appName {
	if (@_ ) {
		$app_name = shift;
		$marker = "!$app_name Tk::GtkSettings section\n";
	}
	return $app_name
}

=item B<convertColorCode>(I<'rgb(255, 0, 0)'>)

=over 4

Some color settings in the Gtk configuration files are in the format 'rgb(255, 255, 255)'.
B<convertColorCode> converts these to a hex color string.

=back

=cut

sub convertColorCode {
	my $input = shift;
	if ($input =~ /rgb\((\d+),(\d+),(\d+)\)/) {
		my $r = substr(sprintf("0x%X", $1), 2);
		my $g = substr(sprintf("0x%X", $2), 2);
		my $b = substr(sprintf("0x%X", $3), 2);
		return "#$r$g$b"
	}
}

=item B<decodeFont(I<$gtkfontstring>)

=over 4

Converts the font string in gtk to something Tk can handle

=back

=cut

# {Khmer OS Battambang} -12 bold italic
sub decodeFont {
	my $rawfont = shift;
	my $family = '';
	my $style = '';
	my $size = '';
	if ($rawfont =~ s/^([^,]+),//) {
		$family = $1;
	}
	$rawfont =~ s/^\s*//; #remove leading spaces
	if ($rawfont =~ s/^([^\d]+)//) {
		$style = $1;
		$style =~ s/^\s*//; #remove leading spaces
		$style =~ s/\s*!//; #remove trailing spaces
		$style = lc($style);
	}
	if ($rawfont =~ s/^(\d+)//) {
		$size = $1;
		$size =~ s/\s*!//; #remove trailing spaces
	}
	return "{$family} $size $style"
}

=item B<export2file>(I<$file>, ?I<$removeflag>?)

=over 4

Exports your Gtk settings to $file in a format recognized by xrdb. It looks for a section
in the file marked by appName . "Tk::GtkSettings section\n". If it finds it it will replace this section.
Otherwise it will append your Gtk settings to the end of the file. If $file does not yet exist it
will create it. if $removeflag is true it will not export but remove the section from $file.

=back

=cut

sub export2file {
	my ($file, $remove) = @_;
	return if $no_gtk;
	return unless platformPermitted;
	$remove = 0 unless defined $remove;
	my $out = "";
	my $found = 0;
	if (-e $file) {
		unless (open(XDEF, "<$file")) { 
			warn "cannot open $file" if $verbose;
			return
		}
		my $inside = 0;
		while (my $l = <XDEF>) {
			if ($inside) {
				if ($l eq $marker) {
					$inside = 0;
				}
			} else {
				if ($l eq $marker) {
					$inside = 1;
					$found = 1;
					$out = "$out$l" . generateOutput . $l unless $remove;
				} else {
					$out = "$out$l";
				}
			}
		}
		close XDEF;
	}
	unless ($found) {
		$out = "$out\n$marker" . generateOutput . "$marker\n"
	}
	unless (open(XDEFO, ">$file")) { 
		warn "cannot open $file" if $verbose;
		return
	}
	print XDEFO $out;
	close XDEFO;
}

=item B<export2Xdefaults>(?I<$removeflag>?)

=over 4

Same as B<export2file>, however the file is always '~/.Xdefaults'.

=back

=cut

sub export2Xdefaults {
	export2file('~/.Xdefaults');
}

=item B<export2Xresources>(?I<$removeflag>?)

=over 4

Same as B<export2file>, however the file is always '~/.Xresources'.

=back

=cut

sub export2Xresources {
	export2file('~/.Xresources');
}

=item B<export2xrdb>

=over 4

exports your Gtk settings directly to the xrdb database.

=back

=cut

sub export2xrdb {
	return unless platformPermitted;
	return if $no_gtk;
	if (open(OFILE, ">", $out_file)) {
		print OFILE generateOutput;
		close OFILE;
		system "xrdb $out_file";
		unlink $out_file if $delete_output;
	}
}

=item B<generateOutput>

=over 4

Generates the output used by the export functions. Returns a string.

=back

=cut

sub generateOutput {
	return if $no_gtk;
	return unless platformPermitted;
	my $output = '';
	#group main has to be done first.
	my (@g) = ('main');
	for (sort keys %groups) {
		push @g, $_ unless $_ eq 'main';
	}
	for (@g) {
		my $name = $_;
		my $group = $groups{$name};
		my $options = $group->[1];
		my $mem = $group->[0];
		for (@$mem) {
			my $member = $_;
			for (sort keys %$options) {
				my $val = gtkKey($options->{$_});
				$val = $options->{$_} unless defined $val;
				unless ($name eq 'main') {
					$output = $output . $app_name . "*$member." . $_ . ": " . $val . "\n";
				} else {
					$output = $output . $app_name . '*' . $_ . ": " . $val . "\n";
				}
			}
		}
	}
	return $output
}

=item B<groupAdd>(I<$groupname>, I<\@members>, I<\%options>)

=over 4

Adds $groupname to the groups hash. If @members or %options are not specified, 
it will leave them empty.

=back

=cut

sub groupAdd {
	my ($group, $members, $options) = @_;
	unless (defined $group) {
		warn "group is not defined" if $verbose;
		return
	}
	$members = [] unless defined $members;
	$options = {} unless defined $options;
	unless (exists $groups{$group}) {
		$groups{$group} = [$members, $options]
	} else {
		warn "group $group already exists" if $verbose
	}
}

=item B<groupAll>

=over 4

Returns a list of all available groups.

=back

=cut

sub groupAll {
	return keys %groups
}

=item B<groupDelete>(I<$groupname>)

=over 4

Removes $groupsname from the groups hash. You cannot delete the 'main' group.

=back

=cut

sub groupDelete {
	my $group = shift;
	if (groupExists($group)) {
		if ($group eq 'main') {
			warn "deleting main group is not allowed" if $verbose;
			return 0
		}
		delete $groups{$group};
	}
	return 1
}

=item B<groupExists>(I<$groupname>)

=over 4

Returns true if $groupname is available.

=back

=cut

sub groupExists {
	my $group = shift;
	unless (defined $group) {
		warn "group not specified or is not defined" if $verbose;
		return 0
	}
	unless (exists $groups{$group}) {
		warn "group $group does not exist" if $verbose;
		return 0
	}
	return 1
}

=item B<groupMembers>(I<$groupname>)

=over 4

Returns the list of existing members of $groupname. It will return an empty list
if $groupname equals 'main'.

=back

=cut

sub groupMembers {
	my $group = shift;
	if (groupExists($group)) {
		if ($group eq 'main') {
			warn "no access to main group members";
			return ()
		}
		my $l = $groups{$group}->[0];
		return @$l;
	}
}

=item B<groupMembersAdd>(I<$groupname>, I<@newmembers>)

=over 4

Adds new members to $groupname. You cannot add members to the 'main' group.

=back

=cut

sub groupMembersAdd {
	my $group = shift;
	if (groupExists($group)) {
		if ($group eq 'main') {
			warn "no access to main group members";
			return
		}
		my $l = $groups{$group}->[0];
		push @$l, @_;
	}
}

=item B<groupMembersReplace>(I<$groupname>, I<@members>)

=over 4

Replaces the list of members in $groupsname by @members. You cannot modify the members list of the 'main' group.

=back

=cut

sub groupMembersReplace {
	my $group = shift;
	if (groupExists($group)) {
		if ($group eq 'main') {
			warn "No access to main group members";
			return
		}
		my $l = $groups{$group}->[0];
		@$l = @_;
	}
}

=item B<groupOption>(I<$groupname>, I<$option>, ?I<$value>?)

=over 4

Sets and returns the value of $option in $groupname. $value should be a corresponding key from
the Gtk hash. If that key is not found, it assumes a direct value.

=back

=cut

sub groupOption {
	my $group = shift;
	if (groupExists($group)) {
		my $option = shift;
		unless (defined $option) { 
			warn "option not defined or specified" if $verbose;
			return
		}
		if (@_) {
			my $value = shift;
			$groups{$group}->[1]->{$option} = $value;
		}
		return $groups{$group}->[1]->{$option}
	}
}

=item B<groupOptionAll>(I<$groupname>)

=over 4

Returns a list of all available options in $groupname.

=back

=cut

sub groupOptionAll {
	my $group = shift;
	if (groupExists($group)) {
		my $opt = $groups{$group}->[1];
		return keys %$opt
	}
}

=item B<groupOptionDelete>(I<$groupname>, I<$option>)

=over 4

Removes $option from $groupname

=back

=cut

sub groupOptionDelete {
	my $group = shift;
	if (groupExists($group)) {
		my $option = shift;
		unless (defined $option) { 
			warn "option not defined or specified" if $verbose;
			return
		}
		delete $groups{$group}->[1]->{$option};
	}
}

=item B<gtkKey>(I<$key>, ?I<$value>?)

=over 4

Sets and returns the value of $key in the Gtk hash

=back

=cut

sub gtkKey {
	my ($key, $val) = @_;
	return undef if $no_gtk;
	$gtksettings{$key} = $val if defined $val;
	if (exists $gtksettings{$key}) {
		return $gtksettings{$key}
	} else {
		warn "item $key not present in gtk settings" if $verbose;
	}
	return undef
}

=item B<gtkKeyAll>

=over 4

Returns a list of all available keys in the Gtk hash.

=back

=cut

sub gtkKeyAll {
	return 0 if $no_gtk;
	return keys %gtksettings
}

=item B<gtkKeyDelete>(I<$key>)

=over 4

Delets $key from the Gtk hash.

=back

=cut

sub gtkKeyDelete {
	my $key = shift;
	return 0 if $no_gtk;
	if (exists $gtksettings{$key}) {
		delete $gtksettings{$key}
	} else {
		warn "item $key not present in gtk settings" if $verbose;
	} 
}

=item B<initDefaults>

=over 4

Initializes some sensible defaults. Also does a full reset and loads Gtk configuration files.

=back

=cut

sub initDefaults {
	resetAll;
	loadGtkInfo;
	gtkKey('tk-active-background', alterColor(gtkKey('theme_bg_color'), 20));
	gtkKey('tk-through-color', alterColor(gtkKey('theme_bg_color'), 20));
	for (keys %mainoptions) {
		groupOption('main', $_, $mainoptions{$_})
	}
	my @cw = @contentwidgets;
	my %co = %contentoptions;
	groupAdd('content', \@cw, \%co);
	my @lw = @listwidgets;
	my %lo = %listoptions;
	groupAdd('list', \@lw, \%lo);
}

=item B<hex2rgb>(I<$hex_color>)

=over 4

Returns and array with the decimal values of red, green and blue.

=back

=cut

sub hex2rgb {
	my $hex = shift;
	$hex =~ s/^(\#|Ox)//;
	$_ = $hex;
	my ($r, $g, $b) = m/(\w{2})(\w{2})(\w{2})/;
	my @rgb = ();
	$rgb[0] = CORE::hex($r);
	$rgb[1] = CORE::hex($g);
	$rgb[2] = CORE::hex($b);
	return @rgb
}

=item B<hexstring>(I<$num>)

=over 4

Return the hexadecimal representation of $num in a two character string.

=back

=cut

sub hexstring {
	my $num = shift;
	my $hex = substr(sprintf("0x%X", $num), 2);
	if (length($hex) < 2) { $hex = "0$hex" }
	return $hex
}

=item B<loadGtkInfo>

=over 4

Empties the Gtk hash and (re)loads the Gtk configuration files.

=back

=cut

sub loadGtkInfo {
	%gtksettings = ();
	my $cf = $gtkpath . "colors.css";
	if (open(OFILE, "<", $cf)) {
		while (<OFILE>) {
			my $line = $_;
			if ($line =~ s/\@define-color\s//) {
				if ($line =~ /([^\s]+)\s([^;]+);/) {
					my $key = $1;
					my $color = $2;
					$color = convertColorCode($color) if $color =~ /^rgb\(/;
					$key = _truncate($key);
					$gtksettings{$key} = $color
				}
			}
		}
		close OFILE
	} else {
		warn "cannot open Gtk colors.css" if  $verbose;
		$no_gtk = 1;
	}
	my $sf = $gtkpath . "settings.ini";
	if (open(OFILE, "<", $sf)) {
		while (<OFILE>) {
			my $line = $_;
			if ($line =~ /([^=]+)=([^\n]+)/) {
				$gtksettings{$1} = $2
			}
		}
		close OFILE;
		if (exists $gtksettings{'gtk-font-name'}) {
			my $font = decodeFont($gtksettings{'gtk-font-name'});
			$gtksettings{'gtk-font-name'} = $font;
		}
	} else {
		warn "cannot open Gtk settings.ini" if $verbose;
		$no_gtk = 1;
	}
}

=item B<platformPermitted>

=over 4

Returns true if you are not on Windows or Mac.

=back

=cut

sub platformPermitted {
	my $platform = $^O;
	return 0 if (($^O eq 'MSWin32') or ($^O eq 'darwin'));
	return 1
}

=item B<removeFromfile>(I<$file>)

=over 4

Same as export2file($file, 1)

=back

=cut

sub removeFromfile {
	my $f = shift;
	export2file($f, 1);
}

=item B<removeFromXdefaults>

=over 4

Same as export2Xdefaults(1)

=back

=cut

sub removeFromXdefaults {
	export2file('~/.Xdefaults', 1);
}

=item B<removeFromXresources>

=over 4

Same as export2Xresources(1)

=back

=cut

sub removeFromXresources {
	export2file('~/.Xresouces', 1);
}

=item B<removeFromxrdb>

=over 4

Removes all the settings previously defined from the xrdb database

=back

=cut

sub removeFromxrdb {
	return unless platformPermitted;
	return if $no_gtk;
	if (open(OFILE, ">", $out_file)) {
		print OFILE generateOutput;
		close OFILE;
		system "xrdb -remove $out_file";
		unlink $out_file if $delete_output;
	}
}

=item B<resetAll>

=over 4

Removes all groups and options. The group 'main' will remain, but all its options are also deleted.
This does not affect the Gtk hash.

=back

=cut

sub resetAll {
	%groups = (
		main => [[''], {}]
	)
}

=item B<rgb2hex>(I<$red>, I<$green>, I<$blue>)

=over 4

Converts the decimval values $red, $green and $blue into a hex color string.

=back

=cut

sub rgb2hex {
	my ($red, $green, $blue) = @_;
	my $r = hexstring($red);
	my $g = hexstring($green);
	my $b = hexstring($blue);
	return "#$r$g$b"

}

sub _truncate {
	my $name = shift;
	for (@basegtkeys) {
		my $key = $_;
		if (substr($name, 0, length($key)) eq $key) {
			return $key
		}
	}
	return $name
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2022 by Hans Jeuken

GPL v3.0 or same as Perl, in your option.

=head1 AUTHOR

Hans Jeuken (jeuken dot hans at gmail dot com)

=head1 BUGS AND CAVEATS

Exporting to xrdb will not work if the name of your executable/script contains
an extension (.pl). This is a limitation of xrdb.

If you find any bugs, please contact the author.

=head1 TODO

=cut


1;
__END__
