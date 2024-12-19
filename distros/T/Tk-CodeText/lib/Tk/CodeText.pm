package Tk::CodeText;

=head1 NAME

Tk::CodeText - Programmer's Swiss army knife Text widget.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.58';

use base qw(Tk::Derived Tk::Frame);

use Tk::CodeText::Kamelon;
use Tk;
use Tie::Watch;
require Tk::CodeText::StatusBar;
require Tk::CodeText::TagsEditor;
require Tk::CodeText::Theme;
require Tk::DialogBox;
require Tk::Font;
require Tk::XText;


Construct Tk::Widget 'CodeText';

my @defaultattributes = (
	'Alert' => [-background => '#DB7C47', -foreground => '#FFFFFF'],
	'Annotation' => [-foreground => '#5A5A5A'],
	'Attribute' => [-foreground => '#00B900', -weight => 'bold'],
	'BaseN' => [-foreground => '#0000A9'],
	'BuiltIn' => [-foreground => '#B500E6'],
	'Char' => [-foreground => '#FF00FF'],
	'Comment' => [foreground => '#5A5A5A', -slant => 'italic'],
	'CommentVar' => [-foreground => '#5A5A5A', -slant => 'italic', -weight => 'bold'],
	'Constant' => [-foreground => '#0000FF', -weight => 'bold'],
	'ControlFlow' => [-foreground => '#0062AD'],
	'DataType' => [-foreground => '#0080A8', -weight => 'bold'],
	'DecVal' => [-foreground => '#9C4E2B'],
	'Documentation' => [-foreground => '#7F5A41', -slant => 'italic'],
	'Error' => [-background => '#FF0000', -foreground => '#FFFF00'],
	'Extension' => [-foreground => '#9A53D1'],
	'Float' => [-foreground => '#9C4E2B', -weight => 'bold'],
	'Function' => [-foreground => '#008A00'],
	'Import' => [-foreground => '#950000', -slate => 'italic'],
	'Information' => [foreground => '#5A5A5A', -weight => 'bold'],
	'Keyword' => [-weight => 'bold'],
	'Normal' => [],
	'Operator' => [-foreground => '#85530E'],
	'Others' => [-foreground => '#FF6200'],
	'Preprocessor' => [-slant => 'italic'],
	'RegionMarker' => [-background => '#00CFFF'],
	'SpecialChar' => [-foreground => '#9A53D1'],
	'SpecialString' => [-foreground => '#FF4449'],
	'String' => [-foreground => '#FF0000'],
	'Variable' => [-foreground => '#0000FF', -weight => 'bold'],
	'VerbatimString' => [-foreground => '#FF4449', -weight => 'bold'],
	'Warning' => [-background => '#FFFF00', -foreground => '#FF0000'],
);

my $minusimg = '#define indicatorclose_width 11
#define indicatorclose_height 11
static unsigned char indicatorclose_bits[] = {
   0xff, 0x07, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0xfd, 0x05,
   0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0x01, 0x04, 0xff, 0x07 };
';

my $plusimg = '#define indicatoropen_width 11
#define indicatoropen_height 11
static unsigned char indicatoropen_bits[] = {
   0xff, 0x07, 0x01, 0x04, 0x21, 0x04, 0x21, 0x04, 0x21, 0x04, 0xfd, 0x05,
   0x21, 0x04, 0x21, 0x04, 0x21, 0x04, 0x01, 0x04, 0xff, 0x07 };
';


=head1 SYNOPSIS

 require Tk::CodeText;
 my $text= $window->CodeText(@options)->pack;

=head1 DESCRIPTION

B<Tk::CodeText> aims to be a Scintilla like text widget for Perl/Tk.

This is a rewrite, almost from scratch and not backwards compatible
with version 0.3.4 and earlier.

It leans heavily on L<Syntax::Kamelon>.

It features:

=over 4

=item line numbers on display

=item code folding

=item status bar 

The status bar has document info and tools for setting tab size, indent style and syntax

=item advanced word based undo/redo stack

It keeps track of the last saving point and selections

=item syntax highlighting in many languages and formats.

=item commenting and uncommenting blocks and lines

=item indenting and unindenting blocks and lines

=item automatic indentation

=item matching of nested {}, () and [] pairs

=back

=head1 OPTIONS

=over 4

=item Switch: B<-autoindent>

By default 0. If set the text will be indented to the 
level and style of the previous line.

=item Name: B<bookmarkColor>

=item Class: B<BookmarkColor>

=item Switch: B<-bookmarkcolor>

Default value #71D0CC. Background color for the line number label
of a bookmarked line.

=item Name: B<bookmarkSize>

=item Class: B<BookmarkSize>

=item Switch: B<-bookmarksize>

Default value 20. length of the label for bookmark entries
in the bookmarks menu.

=item Name: B<configDir>

=item Class: B<ConfigDir>

=item Switch: B<-configdir>

An empty string by default. If set to an existing folder that folder will be used
for config files. Currently there is only one of those. The recent colors for the 
TagsEditor.

=item Switch: B<-contextmenu>

Reference to a Tk::Menu object that is used as context menu.
If you do not specify it, the B<-menuitems> option is checked.

=item Switch: B<-disablemenu>

By default 0. If set the right-click context menu is disabled.

=item Name: B<highlightInterval>

=item Class: B<HighlightInterval>

=item Switch: B<-highlightinterval>

By default 1 milisecond. Highlighting is done on a
line by line basis. This is the time between lines.

=item Name: B<indentStyle>

=item Class: B<IndentStyle>

=item Switch: B<-indentstyle>

Default value 'tab'. You can also set it to a number.
In that case an indent will be the number of spaces.

=item Switch: B<-linespercycle>

Default value 10. It specifies how many lines Tk::CodeText will Highlight in one cycle.
You can tone it down if the application responds sluggish.

=item Switch: B<-match>

Default value '[]{}()'. Specifies which items to match
against nested occurrences.

=item Switch: B<-matchoptions>

Default: [-background => 'blue', -foreground => 'yellow'].
Specifies the options for the match tag.

=item Switch: B<-menuitems>

Specify the menu items for the left-click popup menu.
By default set to undef, meaning no popup menu.

=item Switch: B<-minusimg>

Image used for the collapse state of a folding point.
By default it is a bitmap defined in this module.

=item Switch: B<-mmodifiedcall>

Callback called whenever text is modified. It gets
the location index as parameter.

=item Switch: B<-plusimg>

Image used for the expand state of a folding point.
By default it is a bitmap defined in this module.

=item Switch: B<-readonly>

Default value 0. If you set it to 1 the user will not be
able to make modifications.

=item Switch: B<-saveimage>

The icon image used to indicate the text is modified on the status bar.
By default it is an internally defined xpm.

=item Switch: B<-scrollbars>

Default value 'osoe'. Specifies if and how scrollbars
are to be used. If you set it to an ampty string no
scrollbars will be created. See also L<Tk::Scrolled>.

Only available at create time.

=item Switch: B<-statusinterval>

By default 200 ms. Update interval for the status bar.

=item Name: B<showFolds>

=item Class: B<ShowFolds>

=item Switch: B<-showfolds>

Default value 1. If cleared the folding markers
will be hidden.

=item Name: B<showNumbers>

=item Class: B<ShowNumbers>

=item Switch: B<-shownumbers>

Default value 1. If cleared the line numbers
will be hidden.

=item Name: B<showStatus>

=item Class: B<ShowStatus>

=item Switch: B<-showstatus>

Default value 1. If cleared the status bar
will be hidden.

=item Name: B<syntax>

=item Class: B<Syntax>

=item Switch: B<-syntax>

Default value 'None'. Sets and returns the currently
used syntax definition.

=item Switch: B<-themefile>

Default value undef. Sets and loads a theme file with tags information 
for highlighting. A call to cget returns the name of the loaded theme file.
See also L<Tk::CodeText::Theme>.

=item Switch: B<-xmlfolder>

XML folder to use for L<Syntax::Kamelon>

Only available at create time.

=back

=cut

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $scrollbars = delete $args->{'-scrollbars'};
	$scrollbars = 'soe' unless defined $scrollbars;

	my $theme = delete $args->{'-theme'};
	unless (defined $theme) {
		$theme = Tk::CodeText::Theme->new;
		$theme->put(@defaultattributes);
	}

	my @ko = (
		formatter => ['Base',
			foldingdepth => 'all',
		],
	);
	my $xmldir = delete $args->{'-xmlfolder'};
	push @ko, 'xmlfolder', $xmldir if defined $xmldir;

	$self->SUPER::Populate($args);

	$self->{COLORINF} = [];
	$self->{COLORED} = 1;
	$self->{FOLDBUTTONS} = {};
	$self->{FOLDINF} = [];
	$self->{FOLDSSHOWN} = [];
	$self->{FOLDSVISIBLE} = 0;
	$self->{KAMELON} = Tk::CodeText::Kamelon->new($self, @ko);
	$self->{HIGHLIGHTINTERVAL} = 1;
	$self->{LINESPERCYCLE} = 10;
	$self->{LOOPACTIVE} = 0;
	$self->{NOHIGHLIGHTING} = 1;
	$self->{NUMBERSVISIBLE} = 0;
	$self->{NUMBERINF} = [];
	$self->{POSTCONFIG} = 0;
	$self->{STATUSVISIBLE} = 0;
	$self->{SYNTAX} = 'None';
	$self->{THEME} = $theme;
	$self->{SAVEFIRSTVISIBLE} = 1;
	$self->{SAVELASTVISIBLE} = 1;
	
	#create editor frame
	my $ef = $self->Frame(
		-relief => 'sunken',
		-borderwidth => 2,
	)->pack(
		-expand => 1,
		-fill => 'both',
	);

	#create the frame for the line numbers
	my $numbers = $ef->Frame(
		-width => 40,
	);

	#create the frame for code folding
	my $folds = $ef->Frame(
		-width => 18,
	);
	$folds->bind('<ButtonRelease-3>', [$self, 'foldsMenuPop', Ev('X'), Ev('Y')]);
	my $fmenu = $folds->Menu(
		-tearoff => 0,
		-menuitems => [
			[command => 'Collapse All', -command => ['foldCollapseAll', $self]],
			[command => 'Expand All', -command => ['foldExpandAll', $self]],
		],
	);
	$fmenu->bind('<Leave>', [$fmenu, 'unpost']);

	#create the textwidget
	my @opt = (
#		-width => 20,
#		-height => 10,
		-findandreplacecall => sub { $self->FindAndOrReplace(@_) },
		-modifycall => ['OnModify', $self],
		-relief => 'flat',
		-scrollbars => $scrollbars,
	);
	my $text;
	if ($scrollbars eq '') {
		$text = $ef->XText(@opt)
	} else {
		$text = $ef->Scrolled('XText', @opt)
	}
	$text->pack(-side => 'left', -expand =>1, -fill => 'both');
	$text->bind('Control-b>', [$self, 'bookmarkNew']);
	$text->bind('Control-B>', [$self, 'bookmarkRemove']);
	
	#create the find and replace panel
	my @pack = (-side => 'left', -padx => 2, -pady => 2);
	my $sandr = $self->Frame;
	$self->Advertise(SandR => $sandr);

	#searchframe
	my $case = '-case';
	my $find = '';
	my $reg = '-exact';
	my $replace = '';
	
	my $rframe; #the variable for the replaceframe must exist
	my $sframe = $sandr->Frame->pack(-fill => 'x');
	$sframe->Label(
		-anchor => 'e',
		-text => 'Find',
		-width => 7,
	)->pack(@pack);
	my $e = $sframe->Entry(
		-textvariable => \$find,
	)->pack(@pack, -expand => 1, -fill => 'x');
	$e->bind('<Escape>', [$self, 'FindClose']);
	$e->bind('<Return>', sub { $self->FindNext('-forward', $reg, $case, $find) });
	$sframe->Button(
		-text => 'Next',
		-command => sub { $self->FindNext('-forward', $reg, $case, $find) },
	)->pack(@pack); 
	$sframe->Button(
		-text => 'Previous',
		-command => sub { $self->FindNext('-backward', $reg, $case, $find) },
	)->pack(@pack);
	$sframe->Button(
		-text => 'All',
		-command => sub { $self->FindAll($reg, $case, $find) },
	)->pack(@pack);
	$sframe->Checkbutton(
		-text => 'Case',
		-onvalue => '-case',
		-offvalue => '-nocase',
		-variable => \$case,
	)->pack(@pack);
	$sframe->Checkbutton(
		-text => 'Reg',
		-onvalue => '-regexp',
		-offvalue => '-exact',
		-variable => \$reg,
	)->pack(@pack);
	$sframe->Button(
		-text => 'Close',
		-command => ['FindClose', $self],
	)->pack(@pack);

	#replaceframe
	$rframe = $sandr->Frame;
	$rframe->Label(
		-anchor => 'e',
		-text => 'Replace',
		-width => 7,
	)->pack(@pack);
	$self->Advertise(Replace => $rframe);
	my $r = $rframe->Entry(
		-textvariable => \$replace,
	)->pack(@pack, -expand => 1, -fill => 'x');
	$r->bind('<Escape>', [$self, 'FindClose']);
	$r->bind('<Return>',  sub {
		$self->ReplaceSelectionsWith($replace) if $self->SelectionExists;
		$self->FindNext('-forward', $reg, $case, $find);
	});
	$rframe->Button(
		-text => 'Replace',
		-command => sub {
			$self->ReplaceSelectionsWith($replace) if $self->SelectionExists;
			$self->FindNext('-forward', $reg, $case, $find);
		},
	)->pack(@pack); 
	$rframe->Button(
		-text => 'Skip',
		-command => sub {	$self->FindNext('-forward', $reg, $case, $find)	},
	)->pack(@pack); 
	$rframe->Button(
		-text => 'Replace all',
		-command => sub {
			my $pos = $self->index('insert');
			$self->unselectAll;
			$self->goTo('1.0');
			my $count = 0;
			$self->FindNext('-forward', $reg, $case, $find);
			while ($self->selectionExists) {
				if ($self->SelectionExists) {
					$self->ReplaceSelectionsWith($replace);
					$count ++
				}
				$self->FindNext('-forward', $reg, $case, $find);
			}
			$self->goTo($pos);
			$self->see($pos);
			$self->log("Made $count replaces");
		},
	)->pack(@pack);

	#create the statusbar
	my $statusbar = $self->StatusBar(
		-widget => $self,
	);
	$self->after(10, ['updateStatus', $statusbar]);
	#create progressbar for loading and saving
	$self->Advertise(XText => $text);
	$self->Advertise(Numbers => $numbers);
	$self->Advertise(Folds => $folds);
	$self->Advertise(Statusbar => $statusbar);
	$self->Advertise(Foldsmenu => $fmenu);
	$self->Advertise(FindEntry => $e);

	# hack for getting proper bitmap foreground
	my $l = $self->Label;
	my $fg = $l->cget('-foreground');
	$l->destroy;

	$self->ConfigSpecs(
		-bookmarkcolor => [qw/PASSIVE bookmarkColor BookmarkColor/, '#71D0CC'],
		-bookmarksize => [qw/PASSIVE bookmarkSize BookmarkSize/, 20],
		-configdir => [qw/PASSIVE configdir ConfigDir/, ''],
		-highlightinterval => [qw/METHOD highlightInterval HighlightInterval/, 1],
		-linespercycle => ['METHOD', undef, undef, 10],
		-minusimg => ['PASSIVE', undef, undef, $self->Bitmap(
			-data => $minusimg,
			-foreground => $fg,
		)],
		-modifiedcall => ['CALLBACK', undef, undef, sub {}],
		-plusimg => ['PASSIVE', undef, undef, $self->Bitmap(
			-data => $plusimg,
			-foreground => $fg,
		)],
		-position => ['METHOD'],
		-saveimage => [$statusbar],
		-showfolds => [qw/METHOD showFolds ShowFolds/, 1],
		-shownumbers => [qw/METHOD showNumers ShowNumbers/, 1],
		-showstatus => [qw/METHOD showStatus ShowStatus/, 1],
		-syntax => [qw/METHOD syntax Syntax/, 'None'],
		-statusinterval => [$statusbar],
		-themefile => ['METHOD'],
		DEFAULT => [ $text ],
	);

	$self->Delegates(
		DEFAULT => $text,
	);

	$self->tagConfigure('Hidden', -elide => 1);

	my $yscroll = $text->Subwidget('yscrollbar');
	my $scrollcommand = $yscroll->cget( -command );
	$yscroll->configure(
		-command => sub {
			$scrollcommand->Call(@_);
			$self->lnumberCheck;
			$self->foldsCheck;
		}
	);

	#configure all the bindings for the text widget
	$text->bind('<KeyPress>', [$self, 'OnKeyPress', Ev('K') ]);
	#lazy events
	my @levents = qw(
		ButtonPress B2-Motion 
		B1-Motion MouseWheel
	);
	foreach my $levent (@levents) {
		my $bindsub = $text->bind("<$levent>");
		if ($bindsub) {
			$text->bind("<$levent>", sub {
				$bindsub->Call;
				$self->contentCheckLight;
			});
		} else {
			$text->bind( "<$levent>", sub { $self->contentCheckLight } );
		}
	}
	#forced events
	my @events = qw(Expose Visibility Configure Return);
	foreach my $event (@events) {
		my $bindsub = $text->bind("<$event>");
		if ($bindsub) {
			$text->bind("<$event>", sub {
				$bindsub->Call;
				$self->contentCheck;
			});
		} else {
			$text->bind( "<$event>", sub { $self->contentCheck } );
		}
	}
 	$self->after(10, sub {
		$self->{POSTCONFIG} = 1;
		$self->themeUpdate;
		$self->lnumberCheck(1);
 	});
}

=item B<bookmarkAdd>I<(?$line?)>

Bookmarks line number I<$line?>. If you do not specify I<$line?>, the line that has
the insert cursor is bookmarked.

=cut

sub bookmarkAdd {
	my ($self, $line) = @_;
	$line = $self->linenumber('insert') unless defined $line;
	return if $self->bookmarked($line);
	$self->tagAdd('BOOKMARK', "$line.0", "$line.0 lineend");
}

sub bookmarkCheck {
	my $self = shift;
	my $numframe = $self->Subwidget('Numbers');
	my $nbg = $numframe->cget('-background');
	my $bbg = $self->cget('-bookmarkcolor');
	
	my $nimf = $self->{NUMBERINF};
	for (@$nimf) {
		my $lab = $_;
		my $line = $lab->cget('-text');
		if ($self->bookmarked($line)) {
			$lab->configure('-background', $bbg);
		} else {
			$lab->configure('-background', $nbg);
		}
	}
}

=item B<bookmarked>I<($line)>

Returns true if line number I<$line?> is bookmarked.

=cut

sub bookmarked {
	my ($self, $line) = @_;
	my @range = $self->tagNextrange('BOOKMARK', "$line.0", "$line.0 lineend");
	return @range eq 2
}

sub bookmarkGo {
	my ($self, $line) = @_;
	return unless $self->bookmarked($line);
	$self->goTo("$line.0");
}

=item B<bookmarkList>

Returns a list of all bookmarked line numbers in the text.

=cut

sub bookmarkList {
	my $self = shift;
	my @list = ();
	my @ranges = $self->tagRanges('BOOKMARK');
	while (@ranges) {
		my $begin = shift @ranges;
		push @list, $self->linenumber($begin);
		shift @ranges;
	}
	return @list
}

sub bookmarkMenuItems {
	my $self = shift;
	my @items = ( 
		[command => '~Add bookmark',
			-command => ['bookmarkNew', $self],
		],
		[command => '~Remove bookmark',
			-command => ['bookmarkRemove', $self],
		],
		[command => '~Remove all bookmarks',
			-command => ['bookmarkRemoveAll', $self],
		],
		[separator => ''],
		[command => '~Next bookmark',
			-command => ['bookmarkNext', $self],
		],
		[command => '~Previous bookmark',
			-command => ['bookmarkPrev', $self],
		],
		[separator => ''],
	);
	return @items
}

sub bookmarkMenuPop {
	my ($self, $menu, $bmentry) = @_;
	#find bookmark submenu
	my $submenu;
	for(0 ..$menu->index('end')) {
		if ($menu->type($_) eq 'cascade') {
			my $label = $menu->entrycget($_, '-label');
			if ($label eq $bmentry) {
				$submenu = $menu->entrycget($_, '-menu');
				last;
			}
		}
	} 

	#refresh the bookmarks menu
	if (defined $submenu) {
		#find first entry that is a bookmark
		my $first;
		for(0 ..$submenu->index('end')) {
			next unless $submenu->type($_) eq 'command';
			my $label = $submenu->entrycget($_, '-label');
			if ($label =~ /^\d+/) {
				$first = $_;
				last;
			}
		}
		#delete all bookmarks from the menu
		$submenu->delete($first, 'end') if defined $first;
		#add all current bookmarks
		my @bookmarks = $self->bookmarkList;
		for (@bookmarks) {
			my $mark = $_;
			$submenu->add('command',
				-command => sub { $self->bookmarkGo($mark) },
				-label => "$mark - " . $self->bookmarkText($mark),
			);
		}
	} else {
		warn "Submenu $bmentry not found"
	}
}

=item B<bookmarkNew>

Same as B<bookmarkAdd> except it updates the visible bookmarks
in the line number column.

=cut

sub bookmarkNew {
	my $self = shift;
	$self->bookmarkAdd(@_);
	$self->bookmarkCheck;
}

=item B<bookmarkNext>I<(?$line?)>

Jumps to the next bookmark relative to line number I<$line>.
If you do not specify I<$line?>, the jump is made from the insert cursor position.

=cut

sub bookmarkNext {
	my ($self, $line) = @_;
	$line = $self->linenumber('insert') unless defined $line;
	my @list = $self->bookmarkList;
	for (@list) {
		my $next = $_;
		if ($next > $line) {
			$self->bookmarkGo($next);
			return
		}
	}
}

=item B<bookmarkPrev>I<(?$line?)>

Jumps to the previous bookmark relative to line number I<$line?>.
If you do not specify I<$line?>, the jump is made from the insert cursor position.

=cut

sub bookmarkPrev {
	my ($self, $line) = @_;
	$line = $self->linenumber('insert') unless defined $line;
	my @list = $self->bookmarkList;
	for (reverse @list) {
		my $prev = $_;
		if ($prev < $line) {
			$self->bookmarkGo($prev);
			return
		}
	}
}

=item B<bookmarkRemove>I<(?$line?)>

Removes the bookmark at I<$line?>. 
If you do not specify I<$line?>, the bookmark of the line that holds the insert cursor position is removed.

=cut

sub bookmarkRemove {
	my $self = shift;
	$self->bookmarkRemoveForce(@_);
	$self->bookmarkCheck;
}

=item B<bookmarkRemoveAll>

Removes all bookmarks. 

=cut

sub bookmarkRemoveAll {
	my $self = shift;
	my @list = $self->bookmarkList;
	for (@list) {
		$self->bookmarkRemove($_);
	}
	$self->bookmarkCheck;
}

sub bookmarkRemoveForce {
	my ($self, $line) = @_;
	$line = $self->linenumber('insert') unless defined $line;
	return unless $self->bookmarked($line);
	$self->tagRemove('BOOKMARK', "$line.0", "$line.0 lineend");
}

sub bookmarkText {
	my ($self, $line) = @_;
	my $text = $self->get("$line.0", "$line.0 lineend");
	$text =~ s/^\s+//; #remove leading spaces
	my $max = $self->cget('-bookmarksize');
	$text = substr($text, 0, $max) if length($text) > $max;
	return $text
}

=item B<canUndo>

Returns true if the undo stack has content.

=cut

=item B<canRedo>

Returns true if the redo stack has content.

=cut

=item B<clear>

Delets all text. Clears the undo and redo stack. Clears the modified flag.
Resets hightlighting to syntax 'None'

=cut

sub clear {
	my $self = shift;
	$self->Subwidget('XText')->clear;
	$self->Kamelon->Reset;
	$self->configure(-syntax => 'None');
}

sub Colored {
	my $self = shift;
	$self->{COLORED} = shift if @_;
	return $self->{COLORED}
}

sub ColorInf {
	my $self = shift;
	$self->{COLORINF} = shift if @_;
	return $self->{COLORINF}
}

=item B<comment>

Comments the current line or selection.

=cut

sub contentCheck {
	my $self = shift;
	$self->lnumberCheck;
	$self->foldsCheck;
	$self->bookmarkCheck;
}

sub contentCheckLight {
	my $self = shift;
	my $start = $self->SaveFirstVisible;
	my $end = $self->SaveLastVisible;
	if (($start ne $self->visualBegin) or ($end ne $self->visualEnd)) {
		$self->contentCheck;
	} else {
		$self->bookmarkCheck;
	}
}

sub FindAndOrReplace {
	my ($self, $flag) = @_;
	my $geosave = $self->toplevel->geometry;
	my $sandr = $self->Subwidget('SandR');
	if ($flag) {
		$self->Subwidget('Replace')->packForget
	} else {
		$self->Subwidget('Replace')->pack(
			-fill => 'x',
		);
	}
	$sandr->pack(
		-fill => 'x',
		-before => $self->Subwidget('Statusbar'),
	);
	$self->Subwidget('FindEntry')->focus;
	$self->toplevel->geometry($geosave);

}

sub FindClose {
	my $self = shift;
	$self->Subwidget('XText')->focus;
	$self->Subwidget('SandR')->packForget;
}

sub foldButton {
	my ($self, $line) = @_;
	my $folds = $self->Kamelon->Formatter->Folds;
	my $fbuttons = $self->FoldButtons;
	unless (exists $fbuttons->{$line}) {
		my $data = $folds->{$line};
		my @opt = ();
		my $state;
		if ($self->isHidden($line + 1)) {
			push @opt, -image => $self->cget('-plusimg');
			$state = 'collapsed';
		} else {
			push @opt, -image => $self->cget('-minusimg');
			$state = 'expanded';
		}
		my $b = $self->Subwidget('Folds')->Button(@opt,
			-command => ['foldFlip', $self, $line],
			-relief => 'flat',
		);
		$fbuttons->{$line} = {
			button => $b,
			data => $data,
			state => $state,
		};
	}
	return $fbuttons->{$line};
}

sub FoldButtons {
	my $self = shift;
	$self->{FOLDBUTTONS} = shift if @_;
	return $self->{FOLDBUTTONS}
}

sub foldCollapse {
	my ($self, $line) = @_;
	my $data = $self->FoldButtons->{$line};
	$data->{'state'} = 'collapsed';
	$data->{'button'}->configure(-image => $self->cget('-plusimg'));
	my $end = $data->{'data'}->{'end'};
	$line ++;
	while ($line <= $end) {
		$self->hideLine($line);
		$line ++;
	}
	$self->lnumberCheck;
	$self->foldsCheck;
}

=item B<foldCollapseAll>

Collapses all folding points.

=cut

sub foldCollapseAll {
	my $self = shift;
	my $folds = $self->Kamelon->Formatter->Folds;
	for (sort keys %$folds) {
		$self->foldButton($_); #just make sure a fold button exists
		$self->foldCollapse($_);
	}
}

sub foldExpand {
	my ($self, $line) = @_;
	my $data = $self->FoldButtons->{$line};
	$data->{'state'} = 'expanded';
	$data->{'button'}->configure(-image => $self->cget('-minusimg'));
	$self->lnumberCheck;
	my $end = $data->{'data'}->{'end'};
	$line ++;
	while ($line <= $end) {
		$self->showLine($line);
		my $nested = $self->FoldButtons->{$line};
		if (defined $nested) {
			$self->foldExpand($line) unless ($nested->{'state'} eq 'collapsed');
			$line = $nested->{'data'}->{'end'};
			$self->showLine($line);
		} else {
			$line ++
		}
	}
	$self->foldsCheck;
}

=item B<foldExpandAll>

Expands all folding points.

=cut

sub foldExpandAll {
	my $self = shift;
	my $folds = $self->Kamelon->Formatter->Folds;
	for (sort keys %$folds) {
		$self->foldButton($_); #just make sure a fold button exists
		$self->foldExpand($_);
	}
}

sub foldFlip {
	my ($self, $line) = @_;
	my $data = $self->FoldButtons->{$line};
	if ($data->{'state'} eq 'collapsed') {
		$self->foldExpand($line);
	} elsif ($data->{'state'} eq 'expanded') {
		$self->foldCollapse($line);
	}
}

sub FoldInf {
	my $self = shift;
	$self->{FOLDINF} = shift if @_;
	return $self->{FOLDINF}
}

sub foldsCheck {
	my $self = shift;
	return unless $self->cget('-showfolds');

	my $last = $self->visualEnd;
	return if $self->Colored < $last;

	my $folds = $self->Kamelon->Formatter->Folds;
	my $inf = $self->FoldInf;
	my $fbuttons = $self->FoldButtons;
	my $fframe = $self->Subwidget('Folds');
	my $line = $self->visualBegin;

	#clear out currently mapped fold keys
	$self->foldsClear;

	my $count = 0;
	my @shown = ();
	while ($line <= $last) {
		while ($self->isHidden($line)) { $line ++ }
		if (exists $folds->{$line}) {
			#vertical alignment with the line
			my ( $x, $y, $wi, $he ) = $self->dlineinfo("$line.0");
			my $but = $self->foldButton($line)->{'button'};
			my $bh = $but->reqheight;
			my $delta = int(($he - $bh) / 2);
			$but->place(-x => 0, -y => $y + $delta);
			push @shown, $but;
			$inf->[$count] = $but;
		}
		$count ++;
		$line ++;
	}
	$self->{FOLDSSHOWN} = \@shown;
	while (@$inf >= $count) {
		pop @$inf;
	}
}

sub foldsClear {
	my $self = shift;
	my $shown = $self->{FOLDSSHOWN};
	for (@$shown) { 
		$_->placeForget;
	}
	$self->{FOLDSSHOWN} = [];
}

sub foldsMenuPop {
	my ($self, $x, $y) = @_;
	$self->Subwidget('Foldsmenu')->post($x - 2, $y - 2);
}

=item B<fontCompose>I<($font, %options)>

Returns a new font based on $font.
The keys -family -size -weight -slant are supported 

=cut

sub fontCompose {
	my ($self, $font, %options) = @_;
	my $family = $self->fontActual($font, '-family');
	my $size = $self->fontActual($font, '-size');
	my $weight = '';
	my $slant = '';
	$slant = $options{'-slant'} if exists $options{'-slant'};
	$weight = $options{'-weight'} if exists $options{'-weight'};
	$slant = 'roman' if $slant eq '';
	$weight = 'normal' if $weight eq '';
	return $self->Font(
		-family => $family,
		-size => $size,
		-slant => $slant,
		-weight => $weight,
	);
}

=item B<getFontInfo>

Returns info about the font used in the text widget.
The info is a hash with keys -family -size -weight -slant -underline -overstrike. 

=cut

=item B<goTo>I<($index)>

Sets the insert cursor to $index.

=cut

sub goTo {
	my ($self, $index) = @_;
	$self->Subwidget('XText')->goTo($index);
	$self->contentCheckLight;
}

sub hideLine {
	my ($self, $line) = @_;
	$self->tagAdd('Hidden', "$line.0", "$line.0 lineend + 1c");
}

sub highlightCheck {
	my ($self, $pos) = @_;
	return if $self->NoHighlighting;
	my $line = $self->linenumber($pos);
	my $colored = $self->Colored;
	$self->highlightPurge($line) if $line <= $self->Colored;
}

sub highlightinterval {
	my $self = shift;
	$self->{HIGHLIGHTINTERVAL} = shift if @_;
	return $self->{HIGHLIGHTINTERVAL}
}

sub highlightLine {
	my ($self, $num) = @_;
	my $kam = $self->Kamelon;
	$kam->LineNumber($num);
	my $xt = $self->Subwidget('XText');
	my $begin = "$num.0"; 
	my $end = $xt->index("$num.0 lineend + 1c");
	my $cli = $self->ColorInf;
	my $k = $cli->[$num - 1];
	$kam->StateSet(@$k);
	my $txt = $xt->get($begin, $end); #get the text to be highlighted
#	print "'$txt'\n";
	if ($txt ne '') { #if the line is not empty
		my $pos = 0;
		my $start = 0;
		my @h = $kam->ParseRaw($txt);
		while (@h ne 0) {
			$start = $pos;
			$pos += length(shift @h);
			my $tag = shift @h;
			$xt->tagAdd($tag, "$num.$start", "$num.$pos");
		};
		$xt->tagRaise('sel');
	};
	$cli->[$num] = [ $kam->StateGet ];
}

sub highlightLoop {
	my $self = shift;
	if ($self->NoHighlighting) {
		$self->LoopActive(0);
		return
	}
	my $xt = $self->Subwidget('XText');
	my $lpc = $self->cget('-linespercycle');
#	$lpc = 10 unless defined $lpc;
	my $colored = $self->Colored;
	$self->highlightRemove($colored, $colored + $lpc);
	for (1 .. $lpc) {
		my $colored = $self->Colored;
		if ($colored <= $xt->linenumber('end - 1c')) {
			$self->LoopActive(1);
			$self->highlightLine($colored);
			$colored ++;
			$self->Colored($colored);
		} else {
			$self->LoopActive(0);
		}
		last unless $self->LoopActive;
	}
	$self->after($self->highlightinterval, ['highlightLoop', $self]) if $self->LoopActive;
}

sub highlightPurge {
	my ($self, $line, $remove) = @_;
	$line = 1 unless defined $line;
	$remove = 0 unless defined $remove;

	#purge highlightinfo
	$self->highlightRemove($line) if $remove;
	$self->Colored($line);
	my $cli = $self->ColorInf;
	if (@$cli) { splice(@$cli, $line) };
		
	#purge folds
	$self->foldsClear;
	my $folds = $self->Kamelon->Formatter->Folds;
	for (keys %$folds) {
		delete $folds->{$_} if $_ >= $line
	}
	#clear out unused fold buttons
	my $btns = $self->FoldButtons;
	for (keys %$btns) {
		unless (exists $folds->{$_}) {
			my $b = delete $btns->{$_};
			$b->{'button'}->destroy;
		}
	}
	$self->highlightLoop unless $self->LoopActive;
}

sub highlightRemove {
	my ($self, $begin, $end) = @_;
	$end = $self->linenumber('end') unless defined $end;
	$begin = 1 unless defined $begin;
	for ($self->tags) {
		$self->tagRemove($_, "$begin.0", "$end.0 lineend" )
	}
}

=item B<indent>

Indents the current line or selection.

=item B<isHidden>I<($line)>

Returns true if $line is hidden by a colde fold.

=cut

sub isHidden {
	my ($self, $line) = @_;
	my @names = $self->tagNames("$line.0");
	my $hit = grep({ $_ eq 'Hidden'} @names);
	return $hit;
}

sub Kamelon {
	return $_[0]->{KAMELON}
}

=item B<linenumber>I<($index)>

Returns the line number of $index.

=cut

sub linespercycle {
	my $self = shift;
	$self->{LINESPERCYCLE} = shift if @_;
	return $self->{LINESPERCYCLE}
}


=item B<lineVisible>I<($line)>

=cut

sub lineVisible {
	my ($self, $line) = @_;
	my $first = $self->visualBegin;
	my $last = $self->visualEnd;
	return (($line >= $first) and ($line <= $last))
}

sub lnumberCheck {
	my ($self, $force) = @_;
	$force = 0 unless defined $force;

	my $line = $self->visualBegin;
	my $last = $self->visualEnd;

	my $sb = $self->SaveFirstVisible;
	my $se = $self->SaveLastVisible;

	unless ($force) {
		return if ($sb eq $line) and ($last eq $se);
	}
	return unless $self->{POSTCONFIG};
	return unless $self->cget('-shownumbers');

	$self->SaveFirstVisible($line);
	$self->SaveLastVisible($last);
	my $widget = $self->Subwidget('XText');
	my $count = 0;
	my $font = $widget->cget('-font');

	my $nimf = $self->{NUMBERINF};
	my $numframe = $self->Subwidget('Numbers');

	while ($line <= $last) {
		while ($self->isHidden($line)) { $line ++ }
		my ( $x, $y, $wi, $he ) = $self->dlineinfo("$line.0");

		#create a number label if it does not yet exist;
		unless (defined $nimf->[$count]) {
			my $l = $numframe->Label(
				-justify => 'right',
				-anchor => 'ne',
				-font => $font,
				-borderwidth => 0,
			);
			push @$nimf, $l;
		}

		#configure and position the number label

#		#take care of bookmarked lines
#		my $labbg = $numframe->cget('-background');
#		$labbg = $self->cget('-bookmarkcolor') if $self->bookmarked($line);
		my $lab = $nimf->[$count];
		$lab->configure(
#			-background => $labbg,
			-text => $line,
			-width => length($last),
		);
		$lab->placeForget if $lab->ismapped;
		$lab->place(-x => 0, -y => $y);
		$line ++;
		$count ++;
	}

	my $numwidth = $nimf->[$count - 1]->reqwidth;
	$numframe->configure(-width => $numwidth);

	#remove redundant nummber labels
	while (defined $nimf->[$count]) {
		my $l = pop @$nimf;
		$l->placeForget;
		$l->destroy;
	}
}

=item B<load>I<($file)>

Clears the text widget and loads $file.
Returns 1 if successfull.

=cut

sub load{
	my ($self, $file) = @_;
	if ($self->Subwidget('XText')->load($file)) {
		my $syntax = $self->Kamelon->SuggestSyntax($file);
		$self->configure(-syntax => $syntax) if defined $syntax;
		return 1
	}
	return 0
}

sub LoopActive {
	my $self = shift;
	$self->{LOOPACTIVE} = shift if @_;
	return $self->{LOOPACTIVE}
}

sub NoHighlighting {
	my $self = shift;
	$self->{NOHIGHLIGHTING} = shift if @_;
	return $self->{NOHIGHLIGHTING}
}

sub OnKeyPress {
	my ($self, $key) = @_;
	if (length($key) > 1) {
		$self->contentCheckLight;
	}
}

sub OnModify {
	my ($self, $index) = @_;
	$self->highlightCheck($index);
	$self->bookmarkCheck;
	$self->Callback('-modifiedcall', $index);
}

sub position {
	my ($self, $pos) = @_;
	if (defined $pos) {
		$self->goTo($pos);
		$self->see($pos);
	}
	return $self->index('insert');
}

=item B<redo>

Redoes the last undo.

=cut

=item B<save>I<($file)>

Saves the text into $file. Returns 1 if successfull.

=item B<saveExport>I<($file)>

Same as save, except it does not clear the modified flag.

=cut

sub SaveFirstVisible {
	my $self = shift;
	$self->{SAVEFIRSTVISIBLE} = shift if @_;
	return $self->{SAVEFIRSTVISIBLE}
}

sub SaveLastVisible {
	my $self = shift;
	$self->{SAVELASTVISIBLE} = shift if @_;
	return $self->{SAVELASTVISIBLE}
}

=item B<selectionExists>

Returns true if a selection exists

=cut

sub showfolds {
	my ($self, $flag) = @_;
	my $f = $self->Subwidget('Folds');
	if (defined $flag) {
		if ($flag) {
			my $before = $self->Subwidget('XText');
			$f->pack(
				-side => 'left',
				-before => $before,
				-fill => 'y',
			);
			$self->{FOLDSVISIBLE} = 1;
			$self->foldsCheck;
		} else {
			$self->{FOLDSVISIBLE} = 0;
			$f->packForget;
		}
	}
	return $self->{FOLDSVISIBLE}
}

sub showLine {
	my ($self, $line) = @_;
	$self->tagRemove('Hidden', "$line.0", "$line.0 lineend + 1c");
}

sub shownumbers {
	my ($self, $flag) = @_;
	my $f = $self->Subwidget('Numbers');
	if (defined $flag) {
		if ($flag) {
			my $before = $self->Subwidget('XText');
			$before = $self->Subwidget('Folds') if $self->{FOLDSVISIBLE};
			$f->pack(
				-side => 'left',
				-before => $before,
				-fill => 'y',
			);
			$self->{NUMBERSVISIBLE} = 1;
			$self->lnumberCheck;
		} else {
			$f->packForget;
			$self->{NUMBERSVISIBLE} = 0;
		}
	}
	return $self->{NUMBERSVISIBLE}
}

sub showstatus {
	my ($self, $flag) = @_;
	my $f = $self->Subwidget('Statusbar');
	if (defined $flag) {
		if ($flag) {
			$f->pack(
				-fill => 'x',
			);
			$self->{STATUSVISIBLE} = 1;
			$f->updateStatus;
		} else {
			$f->packForget;
			$self->{STATUSVISIBLE} = 0;
		}
	}
	return $self->{STATUSVISIBLE};
}


sub syntax {
	my ($self, $new) = @_;
	my $kam = $self->Kamelon;
	if (defined($new)) {
		$self->NoHighlighting(1);
		$self->highlightPurge(1, 1);
		$self->Subwidget('XText')->configure(
			-mlcommentend => undef,
			-mlcommentstart => undef,
			-slcomment => undef,
		);
		unless ($new eq 'None') {
			$kam->Syntax($new);
			my $idx = $kam->GetIndexer;
			$self->Subwidget('XText')->configure(
				-mlcommentend => $idx->InfoMLCommentEnd($new),
				-mlcommentstart => $idx->InfoMLCommentStart($new),
				-slcomment => $idx->InfoSLComment($new),
			);
			$self->NoHighlighting(0);
			$self->Colored(0);
			$self->ColorInf([ [$kam->StateGet] ]);
			$self->highlightLoop unless $self->LoopActive;
		}
		$self->{SYNTAX} = $new;
	}
	return $self->{SYNTAX}
}

=item B<tags>

Returns the Kamelon list of AvailableAttributes.

=cut

sub tags {
	return $_[0]->Kamelon->AvailableAttributes
}

=item B<theme>

Returns a reference to the current theme object.
See also L<Tk::CodeText::Theme>

=cut

sub theme {
	return $_[0]->{THEME}
}

=item B<themeDialog>

Initiates a dialog for editing the colors and font information for highlighting.

=cut

sub themeDialog {
	my $self = shift;
	my $theme = $self->theme;
	my $dialog = $self->DialogBox(
		-title => 'Theme editor',
		-buttons => ['Ok', 'Cancel'],
		-default_button => 'Ok',
		-cancel_button => 'Cancel',
	);
	my $historyfile;
	my $config = $self->cget('-configdir');
	$historyfile = "$config/recent_colors";
	my $editor = $dialog->add('TagsEditor',
		-defaultbackground => $self->Subwidget('XText')->cget('-background'),
		-defaultforeground => $self->Subwidget('XText')->cget('-foreground'),
		-defaultfont => $self->Subwidget('XText')->cget('-font'),
		-historyfile => $historyfile,
		-relief => 'sunken',
		-borderwidth => 2,
		-width => 62,
	)->pack(-expand => 1, -fill => 'both', -padx => 2, -pady => 2);
	my $toolframe =  $dialog->add('Frame',
	)->pack(-fill => 'x');
	$toolframe->Button(
		-command => sub {
			my $file = $self->getSaveFile(
				-filetypes => [
					['Highlight Theme' => '.ctt'],
				],
			);
			$editor->save($file) if defined $file;
		},
		-text => 'Save',
	)->pack(-side => 'left', -padx => 5, -pady => 5);
	$toolframe->Button(
		-text => 'Load',
		-command => sub {
			my $file = $self->getOpenFile(
				-filetypes => [
					['Highlight Theme' => '.ctt'],
				],
			);
			if (defined $file) {
				my $obj = Tk::CodeText::Theme->new;
				$obj->load($file);
				$editor->put($obj->get);
				$editor->updateAll
			}
		},
	)->pack(-side => 'left', -padx => 5, -pady => 5);
	
	$editor->put($theme->get);
	my $button = $dialog->Show(-popover => $self);
	if ($button eq 'Ok') {
		$theme->put($editor->get);
		$self->themeUpdate;
	}
	$dialog->destroy;
}

sub themefile {
	my $self = shift;
	if (@_) {
		my $file = shift;
		if ((defined $file) and (-e $file)) {
			$self->theme->load($file);
			#the ->after is necessary here, at create time the widget would not yet return the
			#correct font information to configure the tags correctly.
			#TODO: find a solution for this.
			$self->after(1, ['themeUpdate', $self]);;
		}
		$self->{THEMEFILE} = $file;
	}
	return $self->{THEMEFILE};
}

sub themeUpdate {
	my $self = shift;
	my $theme = $self->theme;
	my @values = $theme->get;
	my $font = $self->cget('-font');
	my $bg = $self->Subwidget('XText')->cget('-background');
	my $fg = $self->Subwidget('XText')->cget('-foreground');
	for ($theme->tagList) { $self->tagDelete($_) }
	while (@values) {
		my $tag = shift @values;
		my $options = shift @values;
		my %opt = @$options;
		my $nbg = $bg;
		my $nfg = $fg;
		my $nfont = $font;
		$nbg = $opt{'-background'} if exists $opt{'-background'};
		$nfg = $opt{'-foreground'} if exists $opt{'-foreground'};
		$nfont = $self->fontCompose($nfont, -slant => $opt{'-slant'}) if exists $opt{'-slant'};
		$nfont = $self->fontCompose($nfont, -weight => $opt{'-weight'}) if exists $opt{'-weight'};
		$self->tagConfigure($tag,
			-background => $nbg,
			-foreground => $nfg,
			-font => $nfont,
		);
	}
	$self->highlightPurge(1);
}

=item B<uncomment>

Uncomments the current line or selection.

=item B<undo>

Undoes the last edit operation.

=item B<unindent>

Unintents the current line or selection

=cut

sub ViewMenuItems {
	my $self = shift;

	my $a;
	tie $a, 'Tk::Configure', $self, '-autoindent';
	my $f;
	tie $f, 'Tk::Configure', $self, '-showfolds';
	my $n;
	tie $n, 'Tk::Configure', $self, '-shownumbers';
	my $s;
	tie $s, 'Tk::Configure', $self, '-showstatus';

	my $v = $self->cget('-wrap');
	Tie::Watch->new(
		-variable => \$v,
		-store => sub {
			my ($watch, $value) = @_;
			$watch->Store($value);
			$self->configure(-wrap => $v);
			$self->contentCheck;
		},
	);

	my @values = (-onvalue => 1, -offvalue => 0);
	my $match = $self->cget('-match');
	my $curlies = '';
	$curlies = '{}' if $match =~ /\{\}/;
	my $paren = '';
	$paren = '()' if $match =~ /\(\)/;
	my $brackets = '';
	$brackets = '[]' if $match =~ /\[\]/;
	my @opt = (
		-command => sub  { $self->configure('-match',  $curlies . $paren . $brackets) },
		-offvalue => '',
	);
	my @items = ( 
		[checkbutton => '~Auto indent', @values, -variable => \$a],
		['cascade'=> '~Wrap', -tearoff => 0, -menuitems => [
			[radiobutton => 'Word', -variable => \$v, -value => 'word'],
			[radiobutton => 'Character', -variable => \$v, -value => 'char'],
			[radiobutton => 'None', -variable => \$v, -value => 'none'],
		]],
		['cascade'=> '~Match', -tearoff => 0, -menuitems => [
			[checkbutton => '() Parenthesis', @opt, -variable => \$paren, -onvalue => '()'],
			[checkbutton => '{} Curlies', @opt, -variable => \$curlies, -onvalue => '{}'],
			[checkbutton => '[] Brackets',@opt, -variable => \$brackets, -onvalue => '[]'],
		]],
		[command => '~Colors', -command => [themeDialog => $self]],
		'separator',
		[checkbutton => 'Code ~folds', @values, -variable => \$f],
		[checkbutton => '~Line numbers', @values, -variable => \$n],
		[checkbutton => '~Status bar', @values, -variable => \$s],
	);
	return @items
}

=item B<visualBegin>

Returns the line number of the first visible line.

=cut

=item B<visualEnd>

Returns the line number of the last visible line.

=cut

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS AND CAVEATS

Matching {}, [] and () does not take strings with matchable symbols into account.

If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::Text>

=item L<Tk::XText>

=item L<Syntax::Kamelon::Syntaxes>

=back

=cut

1;

__END__
