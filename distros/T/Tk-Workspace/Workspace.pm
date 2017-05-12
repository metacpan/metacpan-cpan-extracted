package Tk::Workspace;
# Temp version for CPAN
$VERSION=1.75;
my $RCSRevKey = '$Revision: 1.75 $';
$RCSRevKey =~ /Revision: (.*?) /;
$VERSION=$1;

require Exporter;
use Carp;
use Env qw( PS1 );

use Tk qw(Ev);
use Tk::MainWindow;
use Tk::WorkspaceText;
use Tk::Entry;
use Tk::DialogBox;
use Tk::Dialog;
use Tk::RemoteFileSelect;
use Tk::ColorEditor;
use Tk::XFontSelect;
use Tk::SearchDialog;

use Tk::Shell qw( VERSION ishell shell_client shell_cmd );

use FileHandle;
use IO::File;
use IPC::Open3;
use IPC::Open2;
use IO::Select;
use Cwd;

@ISA=qw(Tk::Widget Exporter);

# Set this to the pathname of the workspace.xpm on your system.
my $iconpath = "/home/kiesling/.icons/workspace.xpm";

$SIG{WINCH} = \&do_win_signal_event;
sub do_win_signal_event {
  Tk::Event::DoOneEvent(255);
  $SIG{WINCH} = \&do_win_signal_event;
}

my ($ptk_major_ver, $ptk_minor_ver) = split /\./, $Tk::VERSION;

if( ( $ptk_major_ver lt '800' ) || ( $ptk_minor_ver lt '015' ) ) {
     die "Fatal Error: \nThis version of Workspace.pm Requires Perl/Tk 800.022.";
}

my $cmdhelptext = <<'end-of-cmd-help';

Usage: workspace [options]

 Options:
   -background | -bg <color>        Menu and dialog background color.
   -textbackground <color>          Background color of text.
   -foreground | -fg <color>        Menu and dialog text color.
   -textforeground <color>          Foreground color of text.
   -font | -fn <Xfontdesc>          X11 font for menus and dialogs.
   -importfile <filename>           Read <filename> into workspace at
                                    startup.
   -exportfile <filename>           Write workspace text to <filename>.
   -dump                            Display text on console.
   -class <Classname>               Resource class name.
   -xrm <pattern>                   Load X resources containing <pattern>.
   -display | -screen <displayname> Name of X display.
   -title <workspacename>           Name of workspace.
   -help                            Display this message.
   -iconic                          Iconify window on startup.
   -motif                           Use Motif look-and-feel.
   -synchronous                     Synchronous communication with X
                                    server. For debugging.
   -write                           Write workspace to disk.
   -quit                            Exit without saving workspace.

Options can begin with either one (`-'), or two (`--') dashes.

end-of-cmd-help

my @Workspaceobject = 
    ('#!/usr/local/bin/perl',
     'my $text=\'\';',
     'my $geometry=\'565x351+100+100\';',
     'my $wrap=\'word\';',
     'my $fg=\'black\';',
     'my $bg=\'white\';',
     'my $name=\'\';',
     'my $menuvisible=\'1\';',
     'my $scrollbars=\'\';',
     'my $insert=\'1.0\';',
     'my $font=\'*-courier-medium-r-*-*-12-*"\';',
     'use Tk;',
     'use Tk::Workspace;',
     'use strict;',
     'use FileHandle;',
     'use Env qw(HOME);',
     'my $workspace = Tk::Workspace -> new ( menubarvisible => $menuvisible, ',
                                        'scroll => $scrollbars );',
     '$workspace -> name($name);',
     '$workspace -> textfont($font);',
     '$workspace -> text -> insert ( \'end\', $text );',
     '$workspace -> text -> configure( -foreground => $fg, -background => $bg, -font => $font, -insertbackground => $fg );',
     '$workspace -> text -> pack( -fill => \'both\', -expand => \'1\');',
     'bless($workspace,\'Tk::Workspace\');',
     '$workspace -> wrap( $wrap );',
     '$workspace -> geometry( $geometry, $insert );',
     '$workspace -> commandline;',
     'MainLoop;' );

my $defaultbackgroundcolor="white";
my $defaultforegroundcolor="black";
my $defaulttextfont="*-courier-medium-r-*-*-12-*";
my $menufont="*-helvetica-medium-r-*-*-12-*";
my $clipboard;          # Internal clipboard.

sub new {
    my $proto = shift;
    my $class = ref( $proto ) || $proto;
    my @construct_args = @_;
    my @cmd_args = &custom_args( @ARGV );
    my $self = {
	window => new MainWindow,
	name => 'workspace',
	textfont => undef,
	# default is approximate width and height of 80x24 char. text widget
	width => undef,
	height => undef,
	# x and y origin are not defined until the workspace is
	# saved again.
	x => undef,
	y => undef,
	foreground => $defaultforegroundcolor,
	background => $defaultbackgroundcolor,
	textfont => '*-courier-medium-r-*-*-12-*',
	filemenu => undef,
	editmenu => undef,
	optionsmenu => undef,
	wrapmenu => undef,
	scrollmenu => undef,
	modemenu => undef,
	helpmenu => undef,
	exportmenu => undef,
	encodingmenu => undef,
	menubar => undef,
	popupmenu => undef,
	menubarvisible => undef,
	scroll => undef,
	scrollbuttons => undef,
	insertionpoint => undef,
	hasnet => undef,
	importfile => undef,
	outputmode => undef,
	outputfile => undef,
	filter => undef,
        text => [],
	cmdargs => (),
	searchopts => (),  # Flattened hash returned from SearchDialog widget.
	unicode => undef,
	encoding => undef,
	filepath => undef
	};
    bless($self, $class);
    my $i;
    for( $i = 0; $i < $#construct_args; ) {
      $self -> {$construct_args[$i]} = $construct_args[$i + 1];
      $i += 2;
    }
    push @{$self -> {cmdargs}}, @cmd_args;
    if( &requirecond( "Net::FTP" ) ) { $self -> hasnet('1') }
    $self -> {window} -> {parent} = $self;
    $self -> filepath;
    $self -> {text} =
      $self -> {window} -> Scrolled( 'WorkspaceText',
				     -font => $defaulttextfont,
		       -background => $defaultbackgroundcolor,
		       -exportselection => 'true',
		       -borderwidth => 0,
		       Name => 'workspaceText' );
    if( &requirecond("Unicode::Map") ) {
      if( &requirecond("Unicode::String") ) {
	$self -> {hasunicode} = '1';
      }
    }
    if( -f $iconpath ) {
      my $icon =
	$self -> {text} -> toplevel -> Pixmap(-file => $iconpath);
      $self -> {window} -> toplevel -> iconimage($icon);
    }
    &menus( $self );
    &set_scroll( $self );
    my $t = $self -> text;
    $t -> Subwidget('yscrollbar') -> configure(-width=>10);
    $t -> Subwidget('xscrollbar') -> configure(-width=>10);
    $t -> setFixedTabs ( 5 );
    $self -> window -> protocol( WM_TAKE_FOCUS, sub{ $self -> wmgeometry});
    # Prevents errors when trying to paste from an empty clipboard.
    $t -> clipboardAppend( '' );
    $self -> focusFollowsMouse;
    $self -> {encoding} = 'iso88591';
    $t -> focus;
    $t -> markGravity( 'insert', 'right' );
    return $self;
}

# Standard X11 toolkit arguments:
# Refer to the Tk::CmdLine manual page.
# one parameter each
my @std_parm_args = ( '-background', '-bg,', '-class', '-display',
		 '-screen', '-font', '-fn', '-foreground',
		 '-fg', '-title', '-xrm' );
# no parameters
my @std_bool_args = ( '-iconic', '-motif', '-synchronous' );

sub custom_args {
  my (@args) = @_;
  my( @newargs, $i, $need_parm );
  $need_parm = 0;
 LOOP:
  foreach $i ( @args ) {
    # POSIX-ly correct.
    $i =~ s/--/-/;
    if ( grep /$i/, @std_parm_args ) {
      die "Missing required parameter for argument $prev_arg.\n"
	if $need_parm == 1;
      $need_parm = 1;
      $prev_arg = $i;
      next LOOP;
    } elsif ( grep /$i/, @std_bool_args ) {
      die "Missing required parameter for argument $prev_arg.\n"
	if $need_parm == 1;
      $prev_arg = $i;
      next LOOP;
    } else {
      if( $need_parm == 1 ) {
	$need_parm = 0;
	next LOOP;
      }
      push @newargs, ($i);
    }
  }
  return @newargs;
}

# Class-specific arguments.
# Args that require a parameter.
my @parm_args = ( '-importfile', '-textforeground', '-textbackground',
		  '-exportfile' );
# Boolean -- No parameter.
my @bool_args = ('-help', '-write', '-quit', '-dump' );

sub commandline {
  my ($self) = @_;
  my ($need_parm, $i, $prev_arg, $arg, @workargs, $nargs);
  $nargs = @{$self -> {cmdargs}};
  for( $i =  $nargs; $i >= 0; $i-- ) {
    push @workargs, (${$self -> {cmdargs}}[$i]);
  }
  while( defined ( $i = pop @workargs ) ) {
    $i =~ s/--/-/;
    if( scalar( grep {/$i/} @parm_args ) > 0 ) {
      die "Missing required parameter for argument $prev_arg.\n"
	if $need_parm == 1;
      $need_parm = 1;
      $prev_arg = $i;
    } elsif ( grep {/$i/} @bool_args ) {
      die "Missing parameter for argument $prev_arg.\n"
	if $need_parm == 1;
      $need_parm = 0;
      $prev_arg = $i;
      # argument that is a boolean
      $i =~ s/\-//;
      $self -> $i('1');
    } elsif( $need_parm == 1 ) {
      # parameter for argument.
      $need_parm = 0;
      $prev_arg =~ s/\-//;
      $self -> $prev_arg($i);
    } else {
      die "Parameter error: $prev_arg, $i.\n";
    }
  }
}


###
### Class methods
###

sub bind {

    my $self = shift;

    ($self -> window) -> SUPER::bind('<Alt-i>',
				    sub{$self -> user_import});
    ($self -> window) -> SUPER::bind('<Alt-w>',
				    sub{$self -> ws_export});
    ($self -> window) -> SUPER::bind('<Alt-x>',
				    sub{$self -> ws_cut});
    ($self -> window) -> SUPER::bind('<Alt-c>',
				    sub{$self -> ws_copy});
    ($self -> window) -> SUPER::bind('<Alt-v>',
				    sub{$self -> ws_paste});
    ($self -> window) -> SUPER::bind('<F1>',
				    sub{$self -> self_help});
    ($self -> window) -> SUPER::bind('<Alt-s>',
				    sub{$self -> write_to_disk('')});
    ($self -> window) -> SUPER::bind('<Alt-q>',
				    sub{$self -> write_to_disk('1')});
    ($self -> window) -> SUPER::bind('<Alt-u>',
				    sub{$self -> ws_undo});
    ($self -> window) -> SUPER::bind('<Alt-f>',
				    sub{$self -> ws_search});
    ($self -> window) -> SUPER::bind('<Alt-g>',
				    sub{$self -> ws_search_again});
    ($self -> window) -> SUPER::bind('<Alt-j>',
				    sub{$self -> goto_line});
    ($self -> window) -> SUPER::bind('<Alt-p>',
				     sub{$self -> print_text});
    # unbind the right mouse button.
    ($self -> window) -> SUPER::bind('Tk::TextUndo', '<3>', '');
    $self -> {window} -> SUPER::bind( '<ButtonPress-3>',
			       [\&postpopupmenu, $self, Ev('X'), Ev('Y') ] );
}

sub WrapMenuItems
{
 my ($w) = @_;
 my $v;
 tie $v,'Tk::Configure',$w,'-wrap';
 return  [
      [radiobutton => 'Word', -variable => \$v, -value => 'word'],
      [radiobutton => 'Character', -variable => \$v, -value => 'char'],
      [radiobutton => 'None', -variable => \$v, -value => 'none'],
	  ];
}

sub EncodingMenuItems
{
 my ($self) = @_;
 return  [
      [radiobutton => 'ISO-8859-1 (Single Byte)',
           -variable => \$self -> {encoding}, -value => 'iso88591'],
      [radiobutton => 'UTF16 (Multibyte)', -variable => \$self -> {encoding},
           -value => 'utf16'],
	  ];
}

sub ScrollMenuItems {
    my ($self) = @_;
    return [
	 [checkbutton => 'Left', -command => sub{$self -> scrollbar('w')},
	  -variable => \$lscroll ],
	 [checkbutton => 'Right', -command => sub{$self -> scrollbar('e')},
	  -variable => \$rscroll ],
	 [checkbutton => 'Top', -command => sub{$self -> scrollbar('n')},
	  -variable => \$tscroll ],
	 [checkbutton => 'Bottom', -command => sub{$self -> scrollbar('s')},
	  -variable => \$bscroll],
	    ];
}

sub menus {
    my $self = shift;

    $self -> {menubar} = ($self -> {window} ) ->
	Menu ( -type => 'menubar',
	       -font => $menufont,
	     Name => 'workspaceMenuBar');
    $self -> {popupmenu} = ($self -> {window} ) ->
	Menu ( -type => 'normal',
	       -tearoff => '',
	       -font => $menufont,
	     Name => 'workspacePopupMenu' );

    $self -> {filemenu} = ($self -> {menubar}) -> Menu;
    $self -> {editmenu} = ($self -> {menubar}) -> Menu;
    $self -> {optionsmenu} = ($self -> {menubar}) -> Menu;
    $self -> {wrapmenu} = ($self -> {menubar}) -> Menu;
    $self -> {scrollmenu} = ($self -> {menubar}) -> Menu;
    $self -> {modemenu} = ($self -> {menubar}) -> Menu;
    $self -> {helpmenu} = ($self -> {menubar}) -> Menu;

    ($self -> {encodingmenu}) = ($self -> {menubar}) -> Menu;


    $self -> {menubar}  ->
	add ('cascade',
	     -label => 'File',
	     -menu => $self -> {filemenu} );
    $self -> {menubar}  ->
	add ('cascade',
	     -label => 'Edit',
	     -menu => $self -> {editmenu} );
    $self -> {menubar}  ->
	add ('cascade',
	     -label => 'Options',
	     -menu => $self -> {optionsmenu} );
    $self -> {menubar} -> add ('separator');

    $self -> {menubar}  ->
	add ('cascade',
	     -label => 'Help',
	     -menu => $self -> {helpmenu} );

    if( ( $self -> menubarvisible ) =~ m/1/ ) {
	$self -> {menubar} -> pack( -anchor => 'w', -fill => 'x' );
    }

    $self -> {popupmenu}  ->
	add ('cascade',
	     -label => 'File',
	     -menu => $self -> {filemenu} ->
	     clone( $self -> {popupmenu}, 'normal' ));
    $self -> {popupmenu}  ->
	add ('cascade',
	     -label => 'Edit',
	     -menu => $self -> {editmenu} ->
	     clone( $self -> {popupmenu}, 'normal' ) );

    $self -> {popupmenu}  ->
	add ('cascade',
	     -label => 'Options',
	     -menu => $self -> {optionsmenu} ->
	     clone( $self -> {popupmenu}, 'normal' ) );

    $self -> {popupmenu} -> add ('separator');
    $self -> {popupmenu}  ->
	add ('cascade',
	     -label => 'Help',
	     -menu => $self -> {helpmenu} ->
	     clone( $self -> {popupmenu}, 'normal' ) );

    $self -> {filemenu} -> add ( 'command', -label => 'Import Text...',
				 -state => 'normal',
				 -accelerator => 'Alt-I',
				 -command => sub{$self -> user_import});
    $self -> {filemenu} -> add ( 'command',
				 -label => 'Export Text',
				 -accelerator => 'Alt-W',
				 -command => sub{$self -> ws_export});
    $self -> {filemenu} -> add ('separator');
    $self -> {filemenu} -> add ( 'command', -label => 'System Command...',
				 -state => 'normal',
				 -command => sub{shell_cmd($self)});
    $self -> {filemenu} -> add ( 'command', -label => 'Shell',
				 -state => 'normal',
				 -command => sub{ishell($self)});
    $self -> {filemenu} -> add ( 'command', -label => 'Filter...',
				 -state => 'normal',
				 -command => sub{&filter_text($self)});
    $self -> {filemenu} -> add ('separator');
    $self -> {filemenu} -> add ( 'command', -label => 'Save...',
				 -state => 'normal',
				 -accelerator => 'Alt-S',
				 -command => sub{$self -> write_to_disk('')});
    $self -> {filemenu} -> add ( 'command', -label => 'Exit...',
				 -state => 'normal',
				 -accelerator => 'Alt-Q',
				 -command => sub{$self -> write_to_disk('1')});
    ($self -> { filemenu }) -> configure( -font => $menufont );
    $self -> {editmenu} -> add ( 'command', -label => 'Undo',
				 -state => 'normal',
				 -accelerator => 'Alt-U',
				 -font => $menufont,
				 -command => sub{$self -> ws_undo});
    $self -> {editmenu} -> add ('separator');
    $self -> {editmenu} -> add ( 'command', -label => 'Cut',
				 -state => 'normal',
				 -accelerator => 'Alt-X',
				 -font => $menufont,
				 -command => sub{$self -> ws_cut});
    $self -> {editmenu} -> add ( 'command', -label => 'Copy',
				 -accelerator => 'Alt-C',
				 -state => 'normal',
				 -font => $menufont,
				 -command => sub{$self -> ws_copy});
    $self -> {editmenu} -> add ( 'command', -label => 'Paste',
				 -accelerator => 'Alt-V',
				 -state => 'normal',
				 -font => $menufont,
				 -command => sub{$self -> ws_paste});
    $self -> {editmenu} -> add ('separator');
    ($self -> {editmenu}) -> add( 'command', -label => 'Search & Replace...',
				  -accelerator => 'Alt-F',
				 -state => 'normal',
				 -font => $menufont,
		 -command => sub{$self -> ws_search} );
    ($self -> {editmenu}) -> add( 'command', -label => 'Repeat Last Search',
				 -accelerator => 'Alt-G',
				 -state => 'normal',
				 -font => $menufont,
				 -command => sub{$self -> ws_search_again});
    $self -> {editmenu} -> add ( 'command', -label => 'Evaluate Selection',
				 -state => 'normal',
				 -command => sub{$self -> evalselection()});
    ($self -> { editmenu }) -> configure( -font => $menufont );

    $self -> {editmenu} -> add ('separator');
    $self -> {editmenu} -> add ( 'command', -label => 'Goto Line...',
				 -state => 'normal',
				 -font => $menufont,
				 -accelerator => 'Alt-J',
		 -command => sub{$self->goto_line});
    ($self -> { optionsmenu }) -> configure( -font => $menufont );
    $self -> {optionsmenu} -> add ( 'cascade',
				    -label => 'Word Wrap',
				    -menu => $self -> {wrapmenu} );
    $items = &WrapMenuItems($self -> {text});
    $self -> {wrapmenu} -> AddItems( @$items );
    $self -> {wrapmenu} -> configure (-font => $menufont);
    $self -> {optionsmenu} -> add ( 'cascade',
				    -label => 'Scroll Bars',
				    -menu => $self -> {scrollmenu} );
    $self -> {scrollbuttons} = &ScrollMenuItems( $self );
    $self -> {scrollmenu} -> AddItems( @{$self -> {scrollbuttons}} );
    $self -> {scrollmenu} -> configure (-font => $menufont);
    $self -> {optionsmenu} -> add( 'cascade', -labe => 'Output Encoding',
				   -menu => $self -> {encodingmenu});
    $items = &EncodingMenuItems($self);
    $self -> {encodingmenu} -> AddItems( @$items );
    $self -> {encodingmenu} -> configure( -font => $menufont );
    if( $self -> hasunicode !~ /1/ ) {
      $self -> {encodingmenu} -> entryconfigure( 2, -state => 'disabled' );
    }
    $self
	-> {optionsmenu} ->
	    add ( 'command',
		  -label => (($self -> menubarvisible)?'Hide ':'Show ').
		    'Menubar',
		  -command => [\&togglemenubar, $self ] );
    $self -> {optionsmenu} -> add ('separator');
    $self -> {optionsmenu} -> add ( 'command', -label => 
				    'Right Margin...',
				    -state => 'normal',
				    -font => $menufont,
         -command => [\&setFillColumn, $self]);
    $self -> {optionsmenu} -> add ( 'command', -label =>
				    'Color Editor...',
				 -state => 'normal',
				 -font => $menufont,
	 -command => [\&elementColor, $self]);
    $self -> {optionsmenu} -> add ( 'command', -label => 'Text Font...',
				 -state => 'normal',
				 -font => $menufont,
	 -command => [\&ws_font, $self]);
    $self -> {helpmenu} -> add ( 'command', -label => 'About...',
				 -state => 'normal',
				 -font => $menufont,
				 -command => sub{$self -> about});
    $self -> {helpmenu} -> add ( 'command', -label => 'Workspace Help...',
				 -state => 'normal',
				 -font => $menufont,
				 -accelerator => "F1",
				 -command => sub{$self -> self_help});
    $self -> {helpmenu} -> add ( 'command', -label => 'Text Editor Commands...',
				 -state => 'normal',
				 -font => $menufont,
				 -command => sub{$self -> edit_help});
}

###
### Instance methods.
###

sub hasunicode {
  my $self = shift;
  if(@_) { $self -> {hasunicode} = shift }
  return $self -> {hasunicode};
}

sub textforeground {
  my ($self, $arg) = @_;
  ( $self -> {text} ) -> configure( -foreground => $arg );
}

sub textbackground {
  my ($self, $arg) = @_;
  ( $self -> {text} ) -> configure( -background => $arg );
}

sub importfile {
  my ($self, $arg) = @_;
  open I, "<$arg" or 
    warn "Importfile: Couldn't open $arg: ".@!."\n";
  while( <I> ) {
    $self -> text -> insert( $self -> text -> index( 'insert' ),
			     $_ );
  }
  close I;
  $self ->{text}->{SubWidget}{workspacetext}{modified} = '1';
}

sub exportfile {
  my ($self, $arg) =@_;
  open O, ">>$arg" or
    warn "Exportfile: Couldn't open $arg: ".@!."\n";
  print O $self -> text -> get( '1.0', 'end' );
  close O;
}

sub dump {
  my ($self, $arg) = @_;
  print $self -> text -> get( '1.0', $self -> text -> index( 'end' ) );
}

sub write {
  my ($self, $args) = @_;
  $self -> write_to_disk( 0 );
}

sub quit {
  my ($self, $arg) = @_;
  $self -> window -> WmDeleteWindow;
}

sub title {
  my ($self, $arg) = @_;
  $self -> window -> configure( -title => $arg );
  $self -> window -> update;
  $self -> name( $arg );
  $self ->{text}->{SubWidget}{workspacetext}{modified} = '1';
}

sub window {
    my $self = shift;
    if (@_) { $self -> {window} = shift }
    return $self -> {window}
}

sub text {
    my $self = shift;
    if (@_) { $self -> {text} = shift }
    return $self -> {text}
}

sub name {
    my $self = shift;
    if (@_) { $self -> {name} = shift }
    return $self -> {name}
}

sub filepath {
    my $self = shift;
    if (@_) { 
	$self -> {filepath} = shift;
    } elsif (not defined $self -> {filepath}) {
	$self -> {filepath} = &cwd.'/'.$0;
	$self -> {filepath} =~ s/(\/\/)|(\/\.\/)/\//g;
    }
    return $self -> {filepath}
}

sub help {
  my $self = shift;
  print STDERR $cmdhelptext;
  $self -> window -> WmDeleteWindow;
}

sub textfont {
    my $self = shift;
    if (@_) { $self -> {textfont} = shift }
    return $self -> {textfont}
}

sub workspaceobject {
  return @Workspaceobject;
}

sub menubar {
    my $self = shift;
    if (@_) { $self -> {menubar} = shift }
    return $self -> {menubar}
}

sub menubarvisible {
    my $self = shift;
    if (@_) { $self -> {menubarvisible} = shift }
    return $self -> {menubarvisible}
}

sub popupmenu {
    my $self = shift;
    if (@_) { $self -> {popupmenu} = shift }
    return $self -> {popupmenu}
}

sub filemenu {
    my $self = shift;
    if (@_) { $self -> {filemenu} = shift }
    return $self -> {filemenu};
}

sub outputfile {
    my $self = shift;
    if (@_) { $self -> {outputfile} = shift }
    return $self -> {outputfile};
}

sub filter {
    my $self = shift;
    if (@_) { $self -> {filter} = shift }
    return $self -> {filter};
}

sub wrap {
    my $self = shift;
    my $w = $self -> {wrapmenu};
    if( @_) {
	my $m = shift;
	if ( $m =~ m/word/ ) { $w -> invoke( 1 ) };
	if ( $m =~ m/char/ ) { $w -> invoke( 2 ) };
	if ( $m =~ m/none/ ) { $w -> invoke( 3 ) };
    }
    return ($self -> {text}) -> cget('-wrap');
}

sub parent_ws {
# We say parent_ws because MainWindows' parents are not recognized
# by default.
    my $self = shift;
    if (@_) { $self -> {parent_ws} = shift }
    return $self -> {parent_ws}
}

sub editmenu {
    my $self = shift;
    if (@_) { $self -> {editmenu} = shift }
    return $self -> {editmenu}
}

sub helpmenu {
    my $self = shift;
    if (@_) { $self -> {helpmenu} = shift }
    return $self -> {helpmenu}
}

sub optionsmenu {
    my $self = shift;
    if (@_) { $self -> {optionsmenu} = shift }
    return $self -> {optionsmenu}
}

sub width {
    my $self = shift;
    if (@_) { $self -> {width} = shift }
    return $self -> {width}
}

sub height {
    my $self = shift;
    if (@_) { $self -> {height} = shift }
    return $self -> {height}
}

# show or hide menubar
sub togglemenubar {
    my $self = shift;

    $self -> {text} -> packForget;
    $self -> {menubar} -> packForget;
    if( ($self -> {menubarvisible}) =~ m/1/ ) {
	$self -> {menubarvisible} = '';
    } else {
	$self -> {menubar} -> pack( -side => 'top', -anchor => 'w',
				  -fill => 'x' );
	$self -> {menubarvisible} = '1';
    }
    $self -> optionsmenu -> entryconfigure( 4, -label =>
			(($self -> menubarvisible) ?
			 'Hide ': 'Show ' ) . 'Menubar' );
    $self -> {text} -> pack( -side => 'top', -fill => 'both', -expand => '1' );
    $self ->{text}->{SubWidget}{workspacetext}{modified} = '1';
    return $self -> {menubarvisible}
}

sub x {
    my $self = shift;
    if (@_) { $self -> {x} = shift }
    return $self -> {x}
}

sub outputmode {
    my $self = shift;
    if (@_) { $self -> {outputmode} = shift }
    return $self -> {outputmode}
}

sub y {
    my $self = shift;
    if (@_) { $self -> {y} = shift }
    return $self -> {y}
}

sub scroll {
    my $self = shift;
    if (@_) { $self -> {scroll} = shift }
    return $self -> {scroll}
}

sub hasnet {
  my $self = shift;
  if( @_ ) { $self -> {hasnet} = shift }
  return $self -> {hasnet}
}

sub insertionpoint {
    my $self = shift;
    if (@_) { $self -> {insertionpoint} = shift }
    return $self -> {insertionpoint}
}

sub open {
    my ($name) = @_;

    my @command_line = ( "\./" . $name . ' &');
    system( @command_line );
}

sub wmgeometry {
  my ($self) = @_;
  my $g = $self -> window -> geometry;
  $g =~ m/([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)/;
  $self -> width($1); $self -> height($2); $self -> x($3);
  $self -> y($4);
  $self -> geometry( $g, $self -> text -> index( 'insert' ) );
}

sub geometry {
    my ($self, $g, $i) = @_;
     my $nargs = scalar @_;
    if( $nargs == 3 ) {
      $g =~ m/([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)/;
      $self -> width($1); $self -> height($2); $self -> x($3);
      $self -> y($4);
      $self -> window -> geometry( $g );
      $self -> insertionpoint( $i );
      $self -> text -> markSet( 'insert', $self -> insertionpoint );
      $self -> text -> see( 'insert' );
    } elsif ( $nargs == 1 ) {
       my $cg = $self -> window -> geometry;
      $cg =~ m/([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)/;
      $self -> width($1); $self -> height($2); $self -> x($3);
      $self -> y($4);
      my $ip = $self -> text -> index( 'insert' );
       $self ->{text}->{SubWidget}{workspacetext}{modified} = '1';
      return ($cg, $ip);
    } else {
       warn "geometry: wrong no. of arguments: $nargs.\n";
    }
}

sub postpopupmenu {
    my $w = shift;
    my $self = shift;
    my $x = shift;
    my $y = shift;
#    my $g = ($self -> window) -> geometry;
#    $g =~ m/([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)/;
#    $self -> width($1); $self -> height($2); $self -> x($3);
#    $self -> y($4);
    ($self -> popupmenu) -> post( $x, $y );
}

sub fill_paragraph {
  my $self = shift;
  my $t = $self -> {text};
  $t -> paragraphFill;
}

sub select_paragraph {
    my $self = shift;
    my $t = $self -> {text};
    $t -> selectPara;
}

sub goto_line {
  my $self = shift;
  my $d = $self -> window -> DialogBox( -title => 'Goto Line',
					-buttons => [qw/Ok Cancel/],
				      -default_button => 'Ok' );
  my $l = $d -> add( 'Label', -text => 'Line Number: ',
		     -font => $menufont )
    -> pack( -side => 'left', -padx => 5, -pady => 5 );
  $d -> Subwidget ('B_Ok') -> configure (-font => $menufont);
  $d -> Subwidget ('B_Cancel') -> configure (-font => $menufont);
  my $e = $d -> add( 'Entry', -width => 10 )
    -> pack( -side => 'left', -padx => 5, -pady => 5 );
  my ($row, $col) = split /\./, $self -> text -> index('insert');
  $e -> insert( '1.0', $row );
  if( ( $resp = $d -> Show ) =~ /Ok/ ) {
    $self -> text -> markSet( 'insert', $e -> get.'.0' );
    $self -> text -> see( 'insert' );
  }
}

sub scrollbar {
  my $self = shift;
    if (@_) {
	my ($p) = @_;
	if (($p=~m/w/)&&($lscroll=='1')){
	    $self->{scroll}.='w';
	    $self->{scroll} =~ s/e//; $rscroll = '0';
	}
	elsif (($p=~m/e/)&&($rscroll=='1')) {
	    $self->{scroll}.='e';
	    $self->{scroll} =~ s/w//; $lscroll = '0';
	}
	elsif (($p=~m/n/)&&($tscroll=='1')) {
	    $self->{scroll} = 'n' . $self -> {scroll};
	    $self->{scroll} =~ s/s//;  $bscroll = '0';
	}
	elsif(($p=~m/s/)&&($bscroll=='1')) {
	    $self->{scroll} = 's' . $self -> {scroll};
	    $self->{scroll} =~ s/n//;  $tscroll = '0';
	}
	else {
	    $self -> {scroll} =~ s/$p//;
	}
	&set_scroll( $self );
	$self ->{text}->{SubWidget}{workspacetext}{modified} = '1';
	return $self -> {scroll};
    }
}

sub set_scroll {
    my ($self) = @_;
    $self -> {text} -> configure( -scrollbars => $self -> {scroll} );
    $self -> {text} -> pack( -expand => '1', -fill => 'both' );
    if( $self -> {scroll} =~ /w/ ) { $lscroll = '1' }
    if( $self -> {scroll} =~ /e/ ) { $rscroll = '1' }
    if( $self -> {scroll} =~ /n/ ) { $tscroll = '1' }
    if( $self -> {scroll} =~ /s/ ) { $bscroll = '1' }
}

sub ws_font {
    my ($self) = @_;
    my ($oldgeometry, $dialog, $f, $x, $y, $newwidth, $newheight);
    $dialog = ($self -> {window}) -> XFontSelect;
    my $f = $dialog -> Show;
    ($self -> text) -> configure( -font => $f );
    $self -> textfont( $f );
    $oldgeometry = ($self -> window) -> geometry();
    $oldgeometry =~ m/.+x.+\+(.+)\+(.+)/;
    $x = $1; $y = $2;
    $newwidth = ($self -> text) -> reqwidth;
    $newheight = ($self -> text) -> reqheight;
    $self -> geometry($newwidth . 'x' . $newheight .
				  '+' . $x . '+' . $y,
				  $self -> insertionpoint );
    $self ->{text}->{SubWidget}{workspacetext}{modified} = '1';
    return;
}

sub setFillColumn {
    my ($w) = @_;
    my $d = $w -> window -> DialogBox (-title => 'Set Right Margin',
				     -buttons => [qw/Ok Dismiss/],
				     -default_button => 'Ok' );
    my $oldmargin = $w -> text -> fillcolumn;
    $d -> Subwidget ('B_Ok') -> configure (-font => $menufont);
    $d -> Subwidget ('B_Dismiss') -> configure (-font => $menufont);
    my $e = $d -> add ('Entry', -width => 5,
		       -textvariable => \$oldmargin) -> 
	pack (-expand => '1', -fill => 'x', -padx => 5, -pady => 5);
    my $resp = $d -> Show;
    my $newmargin = $e -> get;
    $w -> text -> fillcolumn ($newmargin) if $resp !~ /Dismiss/;
}

sub elementColor {
  my ($w) = @_;
  my ($attribute, $color);
  my $c =
      $w -> window -> ColorEditor (-widgets => [$w -> text]);
  $c -> Show;
  $w ->{text}->{SubWidget}{workspacetext}{modified} = '1';
}

sub filter_text {
  my $self = shift;
  my $resp = $self -> filter_dialog;
  return if $resp =~ /Cancel/;
  my $name = $self -> name;
  my $cmd = $self -> filter;
  return if $cmd eq '';
  my $tmpname = $self -> mktmpfile;
  my $cmdstring;
  $cmdstring = "cat $tmpname | $cmd ";
  $self -> watchcursor;
# insert to self
  if( ( $self -> outputmode ) =~ /self/ ) {
    $self->text->insert($self->text->index('insert'),`$cmdstring`);
    `rm -f $tmpname`;
  }
# output to file
  if( ( $self -> outputmode ) =~ /file/ ){
    my $ofilename = $self -> outputfile;
    if( $ofilename ne '' ) {
      if( $ofilename =~ /\:/ ) {
	$ofilename =~ s/^\///;
	$self -> remotefilter( 'file', $ofilename, $cmdstring );
      } else {
	`$cmdstring >$ofilename`;
      }
    }
  }
# output to terminal
  if( ( $self -> outputmode ) =~ /terminal/ ) {
    my $ofilename = $self -> outputfile;
    $cmdstring = $cmdstring . (($ofilename ne '') ? ' >'.$ofilename : '');
    system $cmdstring;
    `rm -f $tmpname`;
  }
# output to new workspace
  if( ( $self -> outputmode ) =~ /new/ ) {
    my $newname = $self -> outputfile;
    return if $newname eq '';
    my $outfile = "$tmpname.output";
    `$cmdstring >$outfile`;
    if( $newname =~ /\:/ ) {
      my ($host, $remotename) = split /\:/, $newname;
      $remotename =~ s/^\///;
      &create( $remotename );
      `./$remotename -importfile $outfile -write -quit &`;
      `rm -f $tmpname $outfile`;
      if( ($self -> hasnet) !~ /1/ ) {
	$self ->
	  error( "Network not enabled:\nNetwork library modules not found." );
	return;
      }
      require Tk::LoginDialog;
      my $d = ($self -> {window}) -> LoginDialog;
      my $resp = $d -> Show;
      my $uid = $d -> cget( '-userid' );
      my $pwd = $d -> cget( '-password' );
      return if $resp !~ /Login/;
      my $ftp = Net::FTP -> new( $host, Debug => 1 );
      return if ! defined $ftp;
      $ftp -> login( $uid, $pwd );
      $ftp -> put( $remotename );
      $ftp -> close;
    } else {
      &create( $newname );
      `./$newname -importfile $outfile -write -quit &`;
      `rm -f $tmpname $outfile`;
    }
  }
  $self ->{text}->{SubWidget}{workspacetext}{modified} = '1';
  $self -> defaultcursor;
}

sub remotefilter {
  my ($self, $mode, $ofilename, $cmdstring ) = @_;
  if( ($self -> hasnet) !~ /1/ ) {
    $self ->
      error( "Network not enabled:\nNetwork library modules not found." );
    return;
  }
  require Tk::LoginDialog;
  my $name = $self -> name;
  my ($localfile);
  my $d = ($self -> {window}) -> LoginDialog;
  my $resp = $d -> Show;
  my $uid = $d -> cget( '-userid' );
  my $pwd = $d -> cget( '-password' );
  return if $resp !~ /Login/;
  my ($hostid, $outputpath) = split /\:/, $ofilename;
  my $ftp = Net::FTP -> new( $hostid, Debug => 1 );
  return if ! defined $ftp;
  $ftp -> login( $uid, $pwd );
  if ( $mode =~ /file/ ) {
    $localfile = $self -> makelocal( $cmdstring );
    $ftp -> put( $localfile, $outputpath );
    $ftp -> close;
  }
}

sub makelocal {
  my ($self, $cmdstring) = @_;
  my $name = $self -> name;
  my $localfile = "/tmp/tmp$name"."$$.tmp";
  open( CMD, "$cmdstring |" )or
    return error( "Couldn't start $cmdstring." );
  open LOCALFILE, ">$localfile" or
    return error( "Could not open $localfile" );
  while( <CMD> ) {
    print LOCALFILE $_;
  }
  close CMD;
  close LOCALFILE;
  return $localfile;
}

sub error {
  my $self = shift;
  my $message = shift;

  return if $message eq '';
  my $d = ($self -> {window}) -> Dialog( -title => 'Workspace Error',
					 -text => $message,
					 -bitmap => 'info',
					 -default_button => 'Ok',
					 -font => $menufont,
					 -buttons => [qw/Ok/] );
  $d -> Subwidget ('B_Ok') -> configure (-font => $menufont);
  $d -> Show;
}

sub mktmpfile {
  my $self = shift;
  my $name = $self -> name;
  open FILE, ">/tmp/$name$$.tmp" 
    or warn "Could not open /tmp/$name$$\: @!\n";
  my $contents = $self -> text -> get( '1.0', 'end' );
  print FILE $contents;
  close FILE;
  return "/tmp/$name$$.tmp";
}

sub filter_dialog {
  my $self = shift;
  my $dw = ($self->window)->DialogBox( -title => 'Filter',
				     -buttons => ['Ok', 'Cancel']);
  my $f1 = $dw -> Frame( -container => '0' );
  my $f2 = $dw -> Frame( -container => '0', -relief => groove,
		       -borderwidth => '3' );
  my $f3 = $dw -> Frame( -container => '0' );
  my $cl = $f1 -> Label( -text => 'Filter:', -font => $menufont );
  $cl -> pack( -side => 'left' );
  my $cm = $f1 -> Entry( -width => 47 )
    -> pack( -side => 'left', -padx => 5 );
  $f1 -> pack( -ipady => 10, -fill => 'both', -expand => '1' );
  $f2 -> Label( -text => "\nOutput To:", -font => $menufont )
    -> pack( -anchor => 'w' );
  my $b1 = $f2 -> Radiobutton ( -text => 'Self',
				-font => $menufont,
				-state => 'normal',
				-variable => \$self -> {outputmode},
				-value => 'self' )
    -> pack( -side => 'left' );
  my $b2 = $f2 -> Radiobutton ( -text => 'File',
				-font => $menufont,
				-state => 'normal',
				-variable => \$self -> {outputmode},
				-value => 'file' )
    -> pack( -side => 'left' );
  my $b3 = $f2 -> Radiobutton ( -text => 'Terminal',
				-font => $menufont,
				-state => 'normal',
				-variable => \$self -> {outputmode},
				-value => 'terminal' )
    -> pack( -side => 'left' );
  my $b4 = $f2 -> Radiobutton ( -text => 'New Workspace',
				-font => $menufont,
				-state => 'normal',
				-variable => \$self -> {outputmode},
				-value => 'new' )
    -> pack( -side => 'left' );
  $b1 -> select;
  $f2 -> Label( -text => "\n" ) -> pack( -anchor => 'w' );
  $f2 -> pack( -expand => '1', -fill => 'both',
	     -ipady => 10);
  $f3 -> Label( -text => 'Output File: ',
	      -font => $menufont )
    -> pack( -side => 'left' );
  my $ofil = $f3 -> Entry( -width => 40 )
    -> pack( -side => 'left', -expand => '1', -fill => 'x', -padx => 5 );
  $f3 -> Label( -text => "\n" ) -> pack( -anchor => 'w' );
  $f3 -> pack( -expand => '1', -fill => 'x' );
  my $resp = $dw -> Show;
  $self->filter( $cm -> get );
  $self->outputfile( $ofil -> get );
  return $resp;
}

sub write_to_disk {
    my $self = shift;
    my $quit = shift;
    my $workspacename = $self -> name;
    my $t = $self -> {text};
    my $tmppath = ($self -> filepath) . '.tmp';
    my $perlpath = `which perl`;
    my ($contents, $object, $x, $y, $fg, $bg, $f, $resp, $wrap, $mb);
    my ($geometry, $width, $height, $sb, $ip);

    if( $quit ) {
      if($t->{SubWidget}{workspacetext}{modified} !~ m/1/) {
	goto EXIT;
      } elsif ( ( $resp = &close_dialog($self) ) =~ m/Cancel/) {
	return;
      } elsif ($resp !~ m/Yes/ ) {
	goto EXIT;
      }
    }
    $self -> watchcursor;
    open FILE, ">>" . $tmppath;
    $contents = ($self -> text) -> get( '1.0', 'end' );
    print FILE '#!' . $perlpath . "\n";

    $geometry= ($self -> window) -> geometry;
    $geometry =~ m/([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)/;
    $width = $1; $height = $2; $x = $3; $y = $4;

    $wrap = $self -> wrap;
    $mb = $self -> menubarvisible;
    $sb = $self -> {scroll};

    $fg = ($self -> text) -> cget('-foreground');
    $bg = ($self -> text) -> cget('-background');
    $ip = ($self -> text) -> index( 'insert' );
    $f = $self -> textfont;

    # concatenate text.
    print FILE 'my $text = <<\'end-of-text\';' . "\n";
    print FILE $contents;
    print FILE "end-of-text\n";

    # This re-creates on the default workspace object, except
    # the first line, the name, height and width, x and y orgs,
    # foreground and background colors,
    # and the initial empty text.;
    my @tmpobject = @Workspaceobject;
    grep { s/name\=\'\'/name=\'$workspacename\'/ } @tmpobject;
    grep { s/geometry\=\'.*\'/geometry=\'$geometry\'/ } @tmpobject;
    grep { s/wrap\=\'.*\'/wrap=\'$wrap\'/ } @tmpobject;
    grep { s/fg\=\'.*\'/fg=\'$fg\'/ } @tmpobject;
    grep { s/bg\=\'.*\'/bg=\'$bg\'/ } @tmpobject;
    grep { s/font\=\'.*\'/font=\'$f\'/ } @tmpobject;
    grep { s/menuvisible\=\'.*\'/menuvisible=\'$mb\'/ } @tmpobject;
    grep { s/scrollbars\=\'.*\'/scrollbars=\'$sb\'/ } @tmpobject;
    grep { s/insert\=\'.*\'/insert=\'$ip\'/ } @tmpobject;
    grep { s/#!\/usr\/bin\/perl// } @tmpobject;
    grep { s/my \$text=\'\'\;// } @tmpobject;
    foreach $line ( @tmpobject ) { print FILE $line . "\n"; };
    close FILE;
    {
      my @remove_old = ( 'mv', $tmppath, $self -> filepath );
      system( @remove_old );
    }
    {
      # set restrictive perms, umask() seems to lock up 
	chmod 0700, $self -> filepath;
    }
    $self -> defaultcursor;
   $t->{SubWidget}{workspacetext}{modified} = '';
EXIT:	   if ( $quit ) { $self -> window -> WmDeleteWindow; }
	
}

# Create a new Workspace executable if one doesn't exist.
sub create {
    my ($workspacename) = ((@_)?@_:'Workspace');
    my $Source;
    my $directory = ''; # Where are we.

    # Make sure a workspace executable of the same basename
    # doesn't exist already.  If it does, make the old workspace
    # a backup.
    if ( -e $workspacename ) {
	rename $workspacename, $workspacename . '.bak';
    }

    #Name the workspace...
    my @tmpobject = @Workspaceobject;
    grep { s/name\=\'\'/name\=\'$workspacename\'/ } @tmpobject;
grep 
{ s/Construct Tk::Workspace/Construct Tk::Workspace \'$workspacename\'\;/ }
@tmpobject;

    open FILE, ">" . $workspacename
	or die "Can't open Workspace " . $workspacename;
    # This creates on the default workspace object.

    foreach $line ( @tmpobject ) { print FILE $line . "\n"; }
    close FILE;
# Havn't figured out a way to use the umask function w/o
# locking up... until then, set perms to rwx for owner only.
chmod 0700, $workspacename;
utime time, time, ($workspacename);
return( $workspacename );
}

sub ws_copy {
    my $self = shift;
    my $selection;
    if ( ! (($self -> {text}) -> tagRanges('sel')) ) { return; }
    # per clipboard.txt, this asserts workspace text widget's
    # ownership of X display clipboard, and clears it.
    ($self -> {text}) -> clipboardClear;
    $selection = ($self -> {text})
	-> SelectionGet(-selection => 'PRIMARY',
			-type => 'STRING' );
    # Appends PRIMARY selection to X display clipboard.
    ($self -> {text}) -> clipboardAppend($selection);
    $clipboard = $selection;   # our  clipboard, not X's.
    return $selection;
}

sub ws_cut {
    my $self = shift;
    my $selection;
    if ( ! (($self -> {text}) -> tagRanges('sel')) ) { return; }
    # per clipboard.txt, this asserts workspace text widget's
    # ownership of X display clipboard, and clears it.
    ($self -> {text}) -> clipboardClear;
    $selection = ($self -> {text})
	-> SelectionGet(-selection => 'PRIMARY',
			-type => 'STRING' );
    # Appends PRIMARY selection to X display clipboard.
    ($self -> {text}) -> clipboardAppend($selection);
    ($self ->{text}) ->
	delete(($self -> {text}) -> tagRanges('sel'));
    $clipboard = $selection;   # our  clipboard, not X's.
    $self -> {text} -> {SubWidget}{workspacetext}{modified} = '1';
    return $selection;
}

sub ws_paste {
    my $self = shift;
    my $selection;
    my $point;
    # Don't use CLIPBOARD because of a bug? in PerlTk...
    #
    # Checks PRIMARY selection, then X display clipboard,
    # and returns if neither is defined.
#    ($self -> {text}) ->
#	selectionOwn(-selection => 'CLIPBOARD');
#    if ( ! (($self -> {text}) -> tagRanges('sel'))
#	 or (($selection =  ($self -> {text})
#	-> SelectionGet(-selection => 'PRIMARY',
#			-type => 'STRING')) == '') ) {
#	return;
#    }
#    if ($self -> {text} -> tagRanges('sel')) {
#	$selection = ($self -> {text})
#	    -> SelectionGet(-selection => 'PRIMARY',
#			    -type => 'STRING');
#    } else {
#	$selection = $clipboard;
#    }
    $selection = ($self -> {text}) -> clipboardGet;
    $point = ($self -> {text}) -> index("insert");
    ($self -> {text}) -> insert( $point,
				      $selection);
    ($self -> {text}) -> see( 'insert' );
    $self -> {text} -> {SubWidget}{workspacetext}{modified} = '1';
    return $selection;
}

sub ws_undo {
    my $self = shift;
    my $undo;
    $undo = ($self -> {text}) -> undo;
    $self ->{text}->{SubWidget}{workspacetext}{modified} = '1';
    return $self
}

sub evalselection {
    my $self = shift;
    my $s;
    my $result;
    $s = ($self -> {text})
	-> SelectionGet( -selection => 'PRIMARY',
			 -type => 'STRING' );
    $result = eval $s;
    ($self -> {text}) ->
	insert( ( ( $self -> {text} ) -> 
		  tagNextrange( 'sel', '1.0', 'end' ))[1], $result );
}

sub about {
    my $self = shift;
    my $aboutdialog;
    my $title_text;
    my $version_text;
    my $name_text;
    my $mod_time;
    my $line_space;  # blank label as separator.
    my @filestats = { $device,
		    $inode,
		    $nlink,
		    $uid,
		    $gid,
		    $raw_device,
		    $size,
		    $atime,
		    $mtime,
		    $ctime,
		    $blksize,
		    $blocks };

    @filestats = stat ($self -> {name});

    $aboutdialog =
	($self -> {window}) ->
	    DialogBox( -buttons => ["Ok"],
		       -title => 'About' );
    $title_text = $aboutdialog -> add ('Label');
    $version_text = $aboutdialog -> add ('Label');
    $name_text = $aboutdialog -> add ('Label');
    $mod_time = $aboutdialog -> add ('Label');
    $line_space = $aboutdialog -> add ('Label');

    $title_text -> configure ( -font => $menufont,
			       -text =>
	       'Workspace.pm by rkiesling@mainmatter.com' );
    $version_text -> configure ( -font => $menufont,
				 -text => "Version:  $VERSION");
    $name_text -> configure ( -font => $menufont,
                              -text => "\'" . $self -> {name} . "\'" );
    $mod_time -> configure ( -font => $menufont,
                             -text => 'Last File Modification: ' .
                             localtime($filestats[9])  );
    $line_space -> configure ( -font =>$menufont,
                               -text => '');

    $name_text -> pack;
    $mod_time -> pack;
    $line_space -> pack;
    $title_text -> pack;
    $version_text -> pack;
    $aboutdialog -> Show;
}

sub cmd_import {
  my( $ws, $args ) = @_;
  print "$args\n";
}

sub user_import {

    my $self = shift;
    my $import;
    my $filedialog;
    my $filename = '';
    my ($l, $unistr, $transtr, $mapobj, $ans, $tmpfile, $basename);
    my $nofiledialog;

    if( ( $ans = $self -> hasunicode ) eq '1' ) {
        $l = Unicode::String -> new( '' );
        $unistr = Unicode::String -> new( '' );
        $mapobj = Unicode::Map -> new( "ISO-8859-1" );
    }
    $filedialog = ($self -> {window})
	-> RemoteFileSelect ( -directory => '.');
    $filename = $filedialog -> Show;

    $self -> watchcursor;
    if( $filename =~ /\:/ ) {
      my $hostname = $filedialog -> cget( -hostname );
      my $uid = $filedialog -> cget( -userid );
      my $passwd = $filedialog -> cget( -password );
      my $transcript = $filedialog -> cget( -transcript );
      $filename =~ s/^.*\://;
      $filename =~ /^.*\/(.*)/;
      $basename = $1;
      $tmpfile = "/tmp/$basename";
      my $ftp = Net::FTP->new( $hostname, $transcript );
      $ftp -> login( $uid, $passwd );
      if ( ( $ftp -> get( $filename, $tmpfile ) ) ne $tmpfile ) {
	print "Could not create $hostname:$filename.\n";
      }
      open IMPORT, "< $tmpfile" or &filenotfound($self);
      while ( $l = <IMPORT> ) {
	  $unistr .= $l;
      }
      if( $ans eq '1' ) {
	$transtr = $mapobj -> from_unicode( $unistr );
	($self -> {text}) -> insert ( 'insert', $transtr );
      } else {
	($self -> {text}) -> insert ( 'insert', $unistr );
      }
      $ftp -> quit;
    } elsif ( $filename ) {
      open IMPORT, "< $filename" or &filenotfound($self);
      while ( $l = <IMPORT> ) {
	$unistr .= $l;
      }
      if( $ans eq '1' ) {
	$transtr = $mapobj -> from_unicode( $unistr );
	($self -> {text}) -> insert ( 'insert', $transtr );
      } else {
	($self -> {text}) -> insert ( 'insert', $unistr );
      }
    }
    ($self -> {text}) -> pack;
    close IMPORT;
    unlink( $tmpfile ) if -e $tmpfile;
    $self ->{text}->{SubWidget}{workspacetext}{modified} = '1';
    $self -> defaultcursor;
}

sub ws_export {
    my $self = shift;
    my $encoding = $self -> {encoding};
    my ($filedialog, $ftp, $l, $l2, $mapobj);
    my $filename = undef;

    $filedialog = ($self -> {window})->RemoteFileSelect ( -directory => '.' );
    return if ! defined ( $filename = $filedialog -> Show );
    $self -> watchcursor;
    if( $encoding =~ /utf16/ ) {
      $mapobj = Unicode::Map -> new('ISO-8859-1');
      $l2 = Unicode::String -> new( '' );
    }
    if( $filename =~ /\:/ ) {
      my $hostname = $filedialog -> cget( -hostname );
      my $uid = $filedialog -> cget( -userid );
      my $passwd = $filedialog -> cget( -password );
      my $transcript = $filedialog -> cget( -transcript );
      $ftp = Net::FTP->new( $hostname, $transcript );
      $filename =~ s/^.*\://;
      $filename =~ /^.*\/(.*)/;
      my $basename = $1;
      my $tmpfile = "/tmp/$basename";
      open OFN, "+> $tmpfile" or &filenotfound( $self );
      if( $encoding =~ /utf16/ ) {
        $ftp -> binary;
	$l2 = $mapobj ->
          to_unicode( ($self -> {text}) -> get( '1.0', 'end' ) );
	syswrite OFN, $l2, length( $l2 );
      } else {
	print OFN ($self -> {text}) -> get( '1.0', 'end' );
      }
      close OFN;
      $ftp -> login( $uid, $passwd );
      if ( ( $ftp -> put( $tmpfile, $filename ) ) ne $filename ) {
	print "Could not create $hostname:$filename.\n";
      }
      $ftp -> quit;
      unlink ($tmpfile);
    } else {
      open OFN, "+> $filename" or &filenotfound( $self );
      if( $encoding =~ /utf16/ ) {
	$l2 = $mapobj -> to_unicode(($self -> {text}) -> get( '1.0', 'end' ));
	syswrite OFN, $l2, length( $l2 );
      } else {
	print OFN ($self -> {text}) -> get( '1.0', 'end' );
      }
      close OFN;
    }
    $self -> defaultcursor;
}

sub close_dialog {
    my $self = shift;
    my $dialog;
    my $response;
    my $notice = "Save this workspace\nbefore closing?";

    $dialog =  ( $self -> {window} )
	-> Dialog( -title => 'Close Workspace',
		   -text => $notice, -bitmap => 'question',
		   -buttons => [qw/Yes No Cancel/]);
    $dialog -> configure (-font => $menufont);
    $dialog -> Subwidget ('B_Yes') -> configure (-font => $menufont);
    $dialog -> Subwidget ('B_No') -> configure (-font => $menufont);
    $dialog -> Subwidget ('B_Cancel') -> configure (-font => $menufont);
    return $response = $dialog -> Show;
}

sub filenotfound {

    my $self = shift;

    my $nofiledialog =
	($self -> {window}) ->
		DialogBox( -buttons => ["OK"],
			   -title => 'File Error' );
    my $filenotfound = $nofiledialog -> add ( 'Label');
    $filenotfound -> configure ( -font => $menufont,
			   -text => 'Could not open file.');
    $filenotfound -> pack;
    $nofiledialog -> Show;
}

sub my_directory {
    open PATHNAME, "pwd |";
    read PATHNAME, $directory, 512;
    close PATHNAME;
}

sub self_help {
    my $libfilename = &libname;
    my $help_text;
    my $helpwindow;
    my $textwidget;

    open  HELP, 'pod2text < '.$libfilename.' |'  or $help_text =
"Unable to process help text for $libfilename.";
    while (<HELP>) {
	$help_text .= $_;
    }
    close( HELP );

    $helpwindow = new MainWindow( -title => "$appfilename Help" );
    my $textframe = $helpwindow -> Frame( -container => 0,
					  -borderwidth => 1 ) -> pack;
    my $buttonframe = $helpwindow -> Frame( -container => 0,
					  -borderwidth => 1 ) -> pack;
    $textwidget = $textframe
	-> Scrolled( 'Text',
		     -font => $defaulttextfont,
		     -scrollbars => 'e' ) -> pack( -fill => 'both',
						   -expand => 1 );
    $textwidget -> Subwidget('yscrollbar') -> configure(-width=>10);
    $textwidget -> Subwidget('xscrollbar') -> configure(-width=>10);
    $textwidget -> insert( 'end', $help_text );

    $buttonframe -> Button( -text => 'Dismiss',
			    -font => $menufont,
			    -default => 'active',
			    -command => sub{$helpwindow -> DESTROY} ) ->
				pack;
}

sub edit_help {
    my $libfilename = &libname;
    my $help_text;
    my $helpwindow;
    my $textwidget;

    $libfilename =~ s/Workspace/WorkspaceText/;
    open  HELP, 'pod2text < '.$libfilename.' |'  or $help_text =
"Unable to process help text for $libfilename.";
    while (<HELP>) {
	$help_text .= $_;
    }
    close( HELP );

    $helpwindow = new MainWindow( -title => "$appfilename Help" );
    my $textframe = $helpwindow -> Frame( -container => 0,
					  -borderwidth => 1 ) -> pack;
    my $buttonframe = $helpwindow -> Frame( -container => 0,
					  -borderwidth => 1 ) -> pack;
    $textwidget = $textframe
	-> Scrolled( 'Text',
		     -font => $defaulttextfont,
		     -scrollbars => 'e' ) -> pack( -fill => 'both',
						   -expand => 1 );
    $textwidget -> Subwidget('yscrollbar') -> configure(-width=>10);
    $textwidget -> Subwidget('xscrollbar') -> configure(-width=>10);
    $textwidget -> insert( 'end', $help_text );

    $buttonframe -> Button( -text => 'Dismiss',
			    -font => $menufont,
			    -default => 'active',
			    -command => sub{$helpwindow -> DESTROY} ) ->
				pack;
}

# return the pathname to the Workspace.pm module.
sub libname {
  my ($i, $val);
  foreach $i ( keys( %:: ) ) {
    $val = $::{$i};
    if ( $val =~ /Workspace\.pm/ ) {
      $val =~ s/\*main::\_\<//;
      return $val;
    }
  }
}

# should the name be "usecond"?
sub requirecond {
  my ($modulename) = @_;
  my ($filename, $fullname, $result);
  $filename = $modulename;
  $filename .= '.pm' if $filename !~ /.pm$/;
  $filename =~ s/\:\:/\//;
  foreach my $prefix ( @INC ) {
    $fullname = "$prefix/$filename";
    if( -f $fullname ) {
      eval "use $modulename";
      return '1';
    }
  }
  return '';
}

# for each subwidget
sub watchcursor {
  my $app = shift;
  $app -> window -> Busy( -recurse => '1' );
}

sub defaultcursor {
  my $app = shift;
  $app -> window -> Unbusy( -recurse => '1' );
}

sub ws_search_again {
  my $self = shift;
  my ($t, @oplist, %opts, $opkey, $opval, $i, $firstmatch, $newinsert,
     $matchlength, @tkopts, $newcol, $row, $col );
  push @oplist, @{$self -> {searchopts}};
  for($i=0;$i<=@oplist;$i+=2){$opts{$oplist[$i]}=$oplist[$i+1]}
  return if $opts{'-searchstring'} eq '';
  my $s = $opts{'-searchstring'};
  ($opts{'-optioncase'} ne '1') ? push @tkopts, ('-nocase') : '' ;
  ($opts{'-optionregex'} eq '1') ? push @tkopts, ('-regex') : ' ';
  ($opts{'-optionbackward'} eq '1') ? push @tkopts, ('-backwards') :
     push @tkopts, ('-forward');
  $t = $self -> text;
  $newinsert = $t -> index('insert');
  ($row, $col) = split /\./, $newinsert;
  $matchlength = length($s);
  $newcol =  $col+$matchlength;
  $col += 1;
  $newinsert="$row\.$col";
  if(($opts{'-replacestring'} ne '' ) && ( $opts{-optionregex} ne '1')){
    local $r = $opts{'-replacestring'};
    $newinsert = $t -> index('insert');
    ($row, $col) = split /\./, $newinsert;
    $col += 1;
    $newinsert="$row\.$col";
    $firstmatch = $t -> search( @tkopts,$s,$newinsert);
    if( $firstmatch ne '' ) {
      ($row, $col) = split /\./, $firstmatch;
      $t -> markSet( 'insert', $firstmatch );
      $t -> see( 'insert' );
      $matchlength = length($s);
      $newcol =  $col+$matchlength;
      for( $i = $col; $i < $newcol; $i++ ) {
	$t -> tagAdd( 'sel', "$row\.$i" );
      }
      $t -> delete( $firstmatch, "$row\.$i" );
      $t -> insert( $t -> index('insert'), $r );
      $newcol=$col+length($r);
      for( $i = $col; $i < $newcol; $i++ ) {
	$t -> tagAdd( 'sel', "$row\.$i" );
      }
    }
  } else {
    $t->tagRemove('sel',$t->index('insert'), "$row\.$newcol");
    $firstmatch = $t -> search( @tkopts,$s,$newinsert);
    if( $firstmatch ne '' ) {
      ($row, $col) = split /\./, $firstmatch;
      $t -> markSet( 'insert', $firstmatch );
      $t -> see( 'insert' );
      $newcol =  $col+$matchlength;
      for( $i = $col; $i < $newcol; $i++ ) {
	$t -> tagAdd( 'sel', "$row\.$i" );
      }
    }
  }
}

sub ws_search {
  my $self = shift;
  my ($t, @oplist, %opts, $opkey, $opval, $i, $firstmatch, $nextmatch,
     $matchlength, @tkopts, );
  $t = $self -> text;
  push @oplist, @{$self -> {searchopts}};
  my $d = $self -> window -> SearchDialog( @oplist );
  @oplist = $d -> Show;
  for($i=0;$i<=@oplist;$i+=2){$opts{$oplist[$i]}=$oplist[$i+1]}
  return if $opts{'-searchstring'} eq '';
  $t -> tagRemove( 'sel', '1.0', 'end' );
  push @{$self -> {searchopts}}, @oplist;
  my $s = $opts{'-searchstring'};
  ($opts{'-optioncase'} ne '1') ? push @tkopts, ('-nocase') : '' ;
  ($opts{'-optionregex'} eq '1') ? push @tkopts, ('-regex') : ' ';
  ($opts{'-optionbackward'} eq '1') ? push @tkopts, ('-backwards') :
     push @tkopts, ('-forward');
  if(($opts{'-replacestring'} ne '' ) && ( $opts{-optionregex} ne '1')){
    local $r = $opts{'-replacestring'};
    $firstmatch = $t -> search( @tkopts,$s,$t->index('insert'));
    if( $firstmatch ne '' ) {
      local ($row, $col) = split /\./, $firstmatch;
      local $newcol;
      $t -> markSet( 'insert', $firstmatch );
      $t -> see( 'insert' );
      $matchlength = length($s);
      $newcol =  $col+$matchlength;
      for( $i = $col; $i < $newcol; $i++ ) {
	$t -> tagAdd( 'sel', "$row\.$i" );
      }
      $t -> delete( $firstmatch, "$row\.$i" );
      $t -> insert( $t -> index('insert'), $r );
      $newcol=$col+length($r);
      for( $i = $col; $i < $newcol; $i++ ) {
	$t -> tagAdd( 'sel', "$row\.$i" );
      }
    }
  } else {
    $firstmatch = $t -> search( @tkopts,$s,$t->index('insert'));
    if( $firstmatch ne '' ) {
      local ($row, $col) = split /\./, $firstmatch;
      local $newcol;
      $t -> markSet( 'insert', $firstmatch );
      $t -> see( 'insert' );
      $matchlength = length($s);
      $newcol =  $col+$matchlength;
      for( $i = $col; $i < $newcol; $i++ ) {
	$t -> tagAdd( 'sel', "$row\.$i" );
      }
    }
  }
}

1;
__END__

=head1 NAME

  Workspace.pm--Persistent, multi-purpose text processor.
  (File browser, shell, editor) script.
  Requires Perl/Tk; optionally Net::FTP.

=head1 SYNOPSIS

   # Create a workspace from the shell prompt:

       mkws "workspace"

   # Open an existing workspace from the shell prompt:

       workspace [-background | -bg <color>] [-textbackground <color>]
                 [-foreground | -fg <color>] [-textforeground <color>]
                 [-font | -fn <fontdesc>] [-importfile <filename>]
                 [-exportfile <filename>] [-dump] [-xrm <pattern>]
                 [-class <Classname>] [-display | -screen <dpyname>]
                 [-title <workspacename>] [-help] [-iconic]
                 [-motif] [-synchronous] [-write] [-quit]

   # Open from a Perl script:

      use Tk;
      use Tk::Workspace;

      Tk::Workspace::open(Tk::Workspace::create("workspace"));

   # Create workspace object within a Perl script:

      $w = Tk::Workspace -> new( x => 100,
                                 y => 100,
                                 width => 300,
                                 height => 250,
				 textfont => "*-courier-medium-r-*-*-12-*",
                                 foreground => 'white',
                                 background => 'black',
                                 menuvisible => 'true',
                                 scroll => 'se',
                                 insert => '1.0',
                                 menubarvisible => 'True',
                                 text => 'Text to be inserted',
                                 name => 'workspace' );

=head1 DESCRIPTION

Workspace uses a modified Tk::Text widget to create an embedded Perl
text editor.  The resulting file can be run as a standalone
program.

=head1 OPTIONS

In normal use, common X toolkit options apply to non-text
areas, like the window border and menus. Text resources can
also be specified, but they often have a lower priority
than the Workspace's saved values and user selections.
Refer to the section: X RESOURCES, below.

Command line options are described more fully in the Tk::CmdLine
manual page.

=head2 X Toolkit Options

=over 4

=item -foreground | -fg <color>

Foreground color of widgets.  -fg is a synonym for -foreground.

=item -background | -bg <color>

Background color of widgets.  -bg is a synonym for -background.

=item -class <classname>

Name of X Window resource class.  In normal use, this is overriden
by the Workspace name.

=item -display | -screen <displayname>

Name of X display.  -screen is a synonym for -display.

=item -font | -fn <fontname>

Font descriptor for widgets.  -fn is a synonym for -font.

=item -iconic

Start with the window iconfied.

=item -motif

Adhere as closely as possible to Motif look-and-feel standards.

=item -name <resourcename>

Specifies the name under which X resources can be found.  Refer
to the section: X RESOURCES, below.

=item -synchronous

Requests should be sent to the X server synchronously.  Mainly
useful for debugging.

=item -title <windowtitle>

Title of the window.  This is overridden by the Workspace.

=item -xrm <resourcestring>

Specifies a resource pattern to override defaults.  Refer
to the section: X RESOURCES, below.

=back

=head2 Workspace Specific Options

=over 4

=item -textforeground <color>

Set the color of the text foreground.  Overrides the Workspace's
own setting.

=item -textbackground <color>

Set the color of the text background.  Overrides the Workspace's
own setting.

=item -importfile <filename>

At startup, import <filename> into the workspace at the cursor
position.

=item -exportfile <filename>

Export the text of the workspace to <filename>.

=item -title <workspacename>

Set the window title and workspace name.

=item -write

Save the workspace in its current state.  If the window is not
yet drawn, use the default geometry of 565x351+100+100 and
insertion cursor index of 1.0.

=item -dump

Print the Workspace text to standard output.

=item -quit

Close the Workspace without saving.

=back

=head1 X RESOURCES

In normal use, a workspace's Xresources begin with its name
in lower-case letters.

  myworkspace*borderwidth:       3
  myworkspace*relief:            sunken
  myworkspace*takefocus:         true

Top-level options are described in the Tk::Toplevel and Tk::options
manual pages.

In addition, several subwidgets have standard names, so properties
can easily apply to all Workspaces:

      Widget             Resource Name
      ------             -------------
      Text Editor        workspaceText
      Menu Bar Menus     workspaceMenuBar
      Popup Menus        workspacePopupMenu

Examples of resource settings that apply to all Workspaces:

  *workspaceText*insertwidth:         5
  *workspaceText*spacing1:            20
  *workspaceMenuBar*foreground:       white
  *workspaceMenuBar*background:       darkslategray
  *workspacePopupMenu*foreground:     white
  *workspacePopupMenu*background:     mediumgray

Complete descriptions of the options that each widget recognizes
are given in the Tk::Text, Tk::TextUndo, and Tk::Menu manual pages.

=head1 MENU FUNCTIONS

A workspace contains a menu bar with File, Edit, Options, and Help
menus.

The menus also pop up by pressing the right mouse button (Button-3)
over the text area, whether the menu bar is visible or not.

The menu functions are provided by the Tk::Workspace, Tk::TextUndo,
Tk::Text, and Tk::Widget modules.

=head2 File Menu

Import Text -- Insert the contents of a selected text file at the
insertion point.

Export Text -- Write the contents of the workspace to a text file.

The Import and Export Text functions allow saving to files on remote
hosts using FTP, if the Perl Net::FTP module is installed.  Please
refer to the file INSTALL in the distribution archive and the
Tk::RemoteFileSelect manual page.

System Command -- Prompts for the name of a command to be executed
by the shell, /bin/sh.  The output is inserted into the workspace.

For example, to insert a manual page into the workspace, enter:

   man <programname> | colcrt - | col -b

Shell -- Starts an interactive shell.  The prompt is the PS1 prompt of
the environment where the workspace was started.  At present the
workspace shell recognizes only a subset of the bash prompt variables,
and does not implement command history or setting of environment
variables in the subshell.

Due to I/O blocking, results can be unpredictable, especially if the
called program causes an eof condition on STDERR.  For details refer
to the Tk::Shell POD documentation.

Refer to the bash(1) manual page for further information.

Typing 'exit' leaves the shell and returns the workspace to normal
text editing mode.

Filter -- Specify a filter and output destination for the text in the
Workspace.  A ``filter'' is defined as a program that takes its input
from standard input, STDIN, and sends its output to standard output,
STDOUT.  By default, output is inserted into the Workspace at the
cursor position.  Other destinations are:

  - File--Write output to the file name specified.
  - Terminal--Write output to the Workspace's STDOUT or to a
    character device specified as the output file.
  - New Workspace--Write output to a new Workspace with the
    name specified.

If the Perl Net::FTP module is installed, filter output can be
sent to a remote host, using the pathname syntax,
hostname:/filepathname .

Save -- Save the workspace to disk.

Quit -- Close the workspace window, optionally saving to disk.

Workspaces are saved with file mode permissions 0700 (read, write, and
execute for the owner of the file).

=head2 Edit Menu

Undo -- Reverse the next previous change to the text.

Cut -- Delete the selected text and place it on the X clipboard.

Copy -- Copy the selected text to the X clipboard.

Paste -- Insert text from the X clipboard at the insertion point.

Evaluate Selection -- Interpret the selected text as Perl code.

Search & Replace -- Open a dialog box to enter search and/or replace
strings.  Users can select options for exact upper/lower case
matching, regular expression searches, forward or backward searches,
and no query on replace.  If "Replace without Asking" is selected,
then all search matches will be replaced.  The default is to prompt
before the replacement.  Replacements for regular expression matches
are not supported.

Goto Line -- Go to the line entered by the user.

Which Line -- Report the line and column position of the
insertion point.

=head2 Options Menu

Wrap -- Select how the text should wrap at the right margin.

Scroll Bars -- Select from scroll bars at right or left, top or bottom of
the text area.

Encoding -- Select the encoding to use when exporting text.  Does not
affect the Workspace text itself.  When importing, the text is mapped
into ISO-8859-1, regardless of encoding.  This option is only
available if the UTF16 libraries are installed on the system.  If they
aren't, then the Workspace uses the default ISO 8859-1 encoding.
Refer to the file INSTALL in the distribution archive for information
about the required libraries.

Show/Hide Menubar -- Toggle whether the menubar is visible.  A popup
version of the menus is always available by pressing the right
mouse button (Button 3) over the text area.

Color Editor -- Pops up a Color Editor window.  You can select the
text attribute that you want to change from the Colors -> Color
Attributes menu.  If your system libraries have an rgb.txt file, a
list of the available colors is displayed on the left-hand side of the
window.  Double-clicking on a color name, or selecting its color space
parameters from the sliders in the middle of the ColorEditor, displays
that color in the swatch on the right-hand side of the window.
Pressing the Apply... button at the bottom of the Color Editor applies
the color selection to the text.  The most useful attributes for
Workspace text are foreground, background, and insertBackground.

Text Font -- Select text font from list of system fonts.

=head2 Help Menu

About -- Report name of workspace and modification time, and
version of Workspace.pm library.

Help -- Display the Workspace.pm POD documentation in a text window
formatted by pod2text.

=head1 KEY BINDINGS

For further information, please refer to the Tk::Text
and Tk::bind man pages.

    Alt-Q                 Quit, Optionally Saving Text
    Alt-S                 Save Workspace to Disk
    Alt-I                 Import Text
    Alt-W                 Export Text
    Alt-U                 Undo
    Alt-X                 Copy Selection to Clipboard and Delete
    Alt-C                 Copy Selection to Clipboard
    Alt-V                 Insert Clipboard Contents at Cursor
    Alt-F                 Search & Replace
    Alt-H                 Select Paragraph
    Alt-L                 Fill Paragraph
    Alt-P                 Print

    Right, Ctrl-F         Forward Character
    Left, Ctrl-B          Backward Character
    Up, Ctrl-P            Up One Line
    Down, Ctrl-N          Down One Line
    Shift-Right           Forward Character Extend Selection
    Shift-Left            Backward Character Extend Selection
    Shift-Up              Up One Line, Extend Selection
    Shift-Down            Down One Line, Extend Selection
    Ctrl-Right, Meta-F    Forward Word
    Ctrl-Left, Meta-B     Backward Word
    Ctrl-Up               Up One Paragraph
    Ctrl-Down             Down One Paragraph
    PgUp                  Scroll View Up One Screen
    PgDn                  Scroll View Down One Screen
    Ctrl-PgUp             Scroll View Right
    Ctrl-PgDn             Scroll View Left
    Home, Ctrl-A          Beginning of Line
    End, Ctrl-E           End of Line
    Ctrl-Home, Meta-<     Beginning of Text
    Ctrl-End, Meta->      End of Text
    Ctrl-/                Select All
    Ctrl-\                Clear Selection
    F16, Copy, Meta-W     Copy Selection to Clipboard
    F20, Cut, Ctrl-W      Copy Selection to Clipboard and Delete
    F18, Paste, Ctrl-Y    Paste Clipboard Text at Insertion Point
    Delete, Ctrl-D        Delete Character to Right, or Selection
    Backspace, Ctrl-H     Delete Character to Left, or Selection
    Meta-D                Delete Word to Right
    Meta-Backspace, Meta-Delete
                          Delete Word to Left
    Ctrl-K                Delete from Cursor to End of Line
    Ctrl-O                Open a Blank Line
    Ctrl-X                Clear Selection
    Ctrl-T                Reverse Order of Characters on Either Side
                          of the Cursor
    Ctrl-.                Center the line the insertion cursor is on
                          in the window.

    Mouse Button 1:
    Single Click: Set Insertion Cursor at Mouse Pointer
    Double Click: Select Word Under the Mouse Pointer and Position 
    Cursor at the Beginning of the Word
    Triple Click: Select Line Under the Mouse Pointer and Position 
    Cursor at the Beginning of the Line
    Drag: Define Selection from Insertion Cursor
    Shift-Drag: Extend Selection
    Double Click, Shift-Drag: Extend Selection by Whole Words
    Triple Click, Shift-Drag: Extend Selection by Whole Lines
    Ctrl: Position Insertion Cursor without Affecting Selection

    Mouse Button 2:
    Click: Copy Selection into Text at the Mouse Pointer
    Drag:Shift View

    Mouse Button 3:
    Pop Up Menu Bar

    Meta                  Escape

    


=head1 METHODS

There is no actual API specification, but Workspaces recognize
the following instance methods:

about, bind, close_dialog, cmd_import, commandline, create,
custom_args, defaultcursor, do_win_signal_event, dump, editmenu,
elementColor, evalselection, exportfile, filemenu, filenotfound,
filepath, filter, filter_dialog, filter_text, fontdialogaccept, 
fontdialogapply, fontdialogclose, geometry, goto_line, havenet, 
height, helpmenu, importfile, insertionpoint, libname, menubar, 
menubarvisible, menus, mktmpfile, my_directory, name, new, open, 
optionsmenu, outputfile, outputmode, parent_ws, popupmenu, 
postpopupmenu, quit, requirecond, scroll, scrollbar, self_help, 
set_scroll, text, textbackground, textfont, textforeground, title, 
togglemenubar, user_import, watchcursor, what_line, width, window, 
wmgeometry, workspaceobject, wrap, write, write_to_disk, ws_copy, 
ws_cut, ws_export, ws_font, ws_paste, ws_undo, x, y

The following class methods are available:

new, ScrollMenuItems, WrapMenuItems, workspaceobject.

The 'new' constructor recognizes the settings of the following
options, which are used by the Workspace.pm :

window, name, textfont, width, height, x, y, foreground,
background, textfont, filemenu, editmenu, optionsmenu,
wrapmenu, scrollmenu, modemenu, helpmenu, menubar, popupmenu,
menubarvisible, scroll, scrollbuttons, insertionpoint, text

=head1 CREDITS

Tk::Workspace by rkiesling@mainmatter.com (Robert Kiesling)

Perl/Tk by Nick Ing-Simmons.
Tk::ColorEditor widget by Steven Lidie.
Perl by Larry Wall and many others.

=head1 REVISION

$Id: Workspace.pm,v 1.75 2002/08/22 21:10:49 kiesling Exp $

=head1 SEE ALSO:

Tk::overview(1), Tk::ColorEditor(1), perl(1) manual pages.

=cut

