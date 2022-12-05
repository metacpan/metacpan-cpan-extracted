package Tk::FileTree;

# FileTree -- TixFileTree widget
#
# Derived from Tk::DirTree

use strict;
use vars qw($VERSION);
$VERSION = '1.01';

use Tk;
use Tk::Derived;
use Tk::Tree;
use Tk::ItemStyle;
use Cwd;
use DirHandle;
use File::Spec qw();

use base  qw(Tk::Derived Tk::Tree);
use strict;

Construct Tk::Widget 'FileTree';

sub ClassInit
{
	my ($class,$mw) = @_;

	$class->SUPER::ClassInit($mw);
	$mw->bind($class,'<FocusIn>','focus');
	$mw->bind($class,'<FocusOut>','unfocus');
	$mw->bind($class,'<Double-1>' => ['MouseButton','Double1',Ev('index',Ev('@'))]);
	$mw->bind($class,'<B1-Motion>',['MouseButton','Button1Motion',Ev('index',Ev('@'))]);
	$mw->bind($class,'<ButtonPress-1>',['FileTree_ButtonPress1', Ev('index',Ev('@'))]);
	$mw->bind($class,'<ButtonRelease-1>',['FileTree_ButtonRelease1']);
	$mw->bind($class,'<Shift-ButtonPress-1>',['MouseButton','ShiftButton1',Ev('index',Ev('@'))]);  #JWT:ADDED 20091020!
	$mw->bind($class,'<Control-ButtonPress-1>',['MouseButton','CtrlButton1',Ev('index',Ev('@'))]);
	$mw->bind($class,'<Alt-ButtonPress-1>',['MouseButton','Button1', Ev('index',Ev('@'))]);
	#THESE NEEDED TO GET TAB-FOCUS CYCLING RIGHT:
	$mw->bind($class,'<Tab>', sub { my $w = shift; $w->focusNext; });
	$mw->bind($class,'<<LeftTab>>', sub { my $w = shift; $w->focusPrev; });
	$mw->MouseWheelBind($class); # XXX Both needed?  M$-Windows seems to ignore (bummer!)
	$mw->YMouseWheelBind($class);

	return $class; 
}

my $bummer = ($^O eq 'MSWin32') ? 1 : 0;
my $sep = $bummer ? '\\' : '/';

*_fs_encode = eval { require Encode; 1 } ? sub { Encode::encode("iso-8859-1", $_[0]) } : sub { $_[0] };

sub Populate {
    my($cw, $args) = @_;

	$cw->toplevel->bind('<<setPalette>>' => [$cw => 'fixPalette']);
	$cw->{'-showcursoralways'} = delete($args->{'-showcursoralways'})  if (defined $args->{'-showcursoralways'});
	$cw->{Configure}{'-font'} = $args->{'-font'}   #MUST ACTUALLY SET THE HList "DEFAULT" FONT FOR BOTH PLATFORMS!:
			|| ($bummer ? "{MS Sans Serif} 8" : "Helvetica -12 bold");
	my $disableFG = (defined $args->{'-disabledforeground'})
			? delete($args->{'-disabledforeground'}) : ($Tk::DISABLED_FG || '#a3a3a3');

    $cw->SUPER::Populate($args);

    $cw->ConfigSpecs(
        -dircmd             => [qw/CALLBACK dirCmd DirCmd DirCmd/],
        -dirtree            => [qw/CALLBACK dirTree DirTree 0/],
        -showhidden         => [qw/PASSIVE showHidden ShowHidden 0/],
        -image              => [qw/PASSIVE image Image folder/],
        -fileimage          => [qw/PASSIVE image Image file/],
        -font               => [qw/METHOD font    Font/],
        -root               => [qw/PASSIVE root Directory 0/],
        -include            => [qw/PASSIVE include Include undef/],
        -exclude            => [qw/PASSIVE exclude Exclude undef/],
        -directory          => [qw/SETMETHOD directory Directory/, '.'],
		-showcursoralways   => [qw/PASSIVE showcursoralways showcursoralways 0/],
		-state              => ['METHOD', 'state', 'State', 'normal'],
		-disabledforeground => ['PASSIVE', 'disabledForeground', 'DisabledForeground', $disableFG],
		-background         => [qw/METHOD background Background/, ''],
		-foreground         => [qw/METHOD foreground Foreground/, ''],
		-selectforeground   => [qw/METHOD selectForeground SelectForeground/, ''],
		-activeforeground   => [qw/METHOD activeForeground ActiveForeground/, '#000000'],
        -value              => '-directory'
	);

    $cw->configure( -separator => $sep, -itemtype => 'imagetext');

	my $Palette = $cw->Palette;
	foreach my $tp (qw/text image imagetext/) {   #CREATE "DEFAULT" STYLES FOR EACH itemtype:
		$cw->{"_style$tp"} = $cw->ItemStyle($tp);
		#FORCE "activebackground" := "background" TO AVOID UGLY PARTIAL BACKGROUND SHADING OF THE ACTIVE ENTRY!:
		$cw->{"_style$tp"}->configure('-activebackground' => $Palette->{'background'})  if ($Palette->{'background'});
		$cw->{"_style$tp"}->configure('-font' => $cw->{Configure}{'-font'})  if ($tp ne 'image');
	}
	$cw->configure('-activeforeground' => $args->{'-activeforeground'})  if ($args->{'-activeforeground'});
	$cw->configure('-selectforeground' => $args->{'-selectforeground'})  if ($args->{'-selectforeground'});
	$cw->{'_lastactive'} = 0;
	$cw->{'_hasfocus'} = 0;
	#NOTE:  HList's DEFAULT FOCUS-MODEL ACTS AS -takefocus => 1 (not '') BUT '',0, AND 1 WORK AS WE EXPECT!
	$cw->{'_savefocuscfg'} = (defined $args->{'-takefocus'}) ? $args->{'-takefocus'} : '';
	$cw->{Configure}{'-state'} = 'normal';
	#THESE NEEDED TO GET TAB-FOCUS CYCLING RIGHT:
	$cw->parent->bind('<Tab>', sub { my $w = shift; $w->focusNext; });
	$cw->parent->bind('<FocusIn>', sub { my $w = shift; $w->focusNext; });
}

sub DirCmd {
    my( $w, $dir, $showhidden ) = @_;
    $dir .= $sep if $dir =~ /^[a-z]:$/io and $bummer;
    my $h = DirHandle->new( $dir ) or return();
    my @names = grep( $_ ne '.' && $_ ne '..', $h->read );
    @names = grep( ! /^[.]/o, @names ) unless $showhidden;
    return( @names );
}

*dircmd = \&DirCmd;

sub fullpath
{
	my ($path) = @_;
	my $cwd = getcwd();
	$path ||= $cwd;	if (CORE::chdir($path)) {
		$path = getcwd();
		CORE::chdir($cwd) || die "Cannot cd back to $cwd:$!";
	} else {
		warn "Cannot cd to $path:$!"
	}
	$path = File::Spec->canonpath($path);
	return $path;
}

sub directory
{
    my ($w,$key,$val) = @_;
    # We need a value for -image, so its being undefined
    # is probably caused by order of handling config defaults
    # so defer it.
}

sub set_dir {
	my($w, $val, %ops) = @_;
	my $fulldir = fullpath($val);

	if (defined($ops{'-root'}) && $ops{'-root'}) {
		$ops{'-root'} = $fulldir  if ($ops{'-root'} !~ m#\Q$sep\E#);
		$w->configure('-root' => $ops{'-root'});
	}
	my $parent = ($bummer && $fulldir =~ s/^([a-z]:)//i) ? $1 : $sep;
	$w->add_to_tree( $parent, $parent)  unless $w->infoExists($parent);

    my @dirs = ($parent);
    foreach my $name (split( /\Q$sep\E/, $fulldir )) {
        next unless length $name;
        push @dirs, $name;
	my $dir = File::Spec->catfile( @dirs );
        $w->add_to_tree($dir, $name, $parent)
	            unless $w->infoExists( $dir );
        $parent = $dir;
    }

    $w->OpenCmd($parent);
    $w->setmode($parent, 'close');
}

*chdir = \&set_dir;


sub OpenCmd {
	my($w, $dir) = @_;

	my $parent = $dir;
	my $include = $w->cget('-include');
	my $checkInclude = (ref($include) =~ /ARRAY/o && $#{$include} >= 0 && $include->[0] =~ /\S/) ? 1 : 0;
	my $exclude = $w->cget('-exclude');
	my $checkExclude = (ref($exclude) =~ /ARRAY/o && $#{$exclude} >= 0 && $exclude->[0] =~ /\S/) ? 1 : 0;
	my $dirTreeOnly = $w->cget('-dirtree');

NAME:	foreach my $name ($w->dirnames($parent)) {
		next if ($name eq '.' || $name eq '..');
		my $subdir = _fs_encode(File::Spec->catfile($dir, $name));
		next unless (!$dirTreeOnly || -d $subdir);
		if (! -d $subdir) {
			if ($checkInclude) {
				my $included = 0;
				foreach my $i (@{$include}) {
					$included = 1  if ($subdir =~ /\.$i$/i);
				}
				next NAME  unless ($included);
			}
			if ($checkExclude) {
				foreach my $i (@{$exclude}) {
					next NAME  if ($subdir =~ /\.$i$/i);
				}
			}
		}
		if ($w->infoExists($subdir)) {
			$w->show( -entry => $subdir, -noexpand => 1);
		} else {
			$w->add_to_tree($subdir, $name, $parent);
		}
	}
}

*opencmd = \&OpenCmd;

sub add_to_tree {
    my($w, $dir, $name, $parent) = @_;

    my $dir8 = _fs_encode($dir);
    my $image = (-d $dir) ? $w->cget('-image') : $w->cget('-fileimage');
    $image = $w->Getimage($image)  if (!UNIVERSAL::isa($image, 'Tk::Image'));

	my $rootdir = $w->cget('-root');
	$rootdir =~ s#\Q$sep\E$##;  #MUST REMOVE TRAILING SEPERTOR!
	my $mode = (-d $dir && (!$rootdir || $dir =~ /^\Q$rootdir\E/)) ? 'open' : 'none';

    my @args = (-image => $image, -text => $name, -style => $w->{"_styleimagetext"});
    if ($parent) {  # Add in alphabetical order.
        foreach my $sib ($w->infoChildren( $parent )) {
		    use if !$bummer, "locale"; # dumps core under Windows under some (japanese?) locales, see http://www.nntp.perl.org/group/perl.cpan.testers/2008/11/msg2550386.html
		    my $sib8 = _fs_encode($sib);
		    if ($sib8 gt $dir8) {
                push @args, (-before => $sib);
                last;
            }
        }
    }

#TK doesn't LIKE THIS: $dir =~ s#\Q$sep\E#\/#go;
    $w->add($dir, @args);
    $w->setmode($dir, $mode);
}

sub has_subdir {
    my($w, $dir) = @_;
    foreach my $name ($w->dirnames($dir)) {
        next if ($name eq '.' || $name eq '..');
        next if ($name =~ /^\.+$/o);
        return (1)  if -d File::Spec->catfile($dir, $name);
    }
    return (0);
}

sub dirnames {
    my ($w, $dir) = @_;
    my @names = $w->Callback( '-dircmd', $dir, $w->cget('-showhidden'));
    return (@names);
}

sub _normalize  #(INTERNAL) Convert Windowsey paths to standard (*nix) ones (\ => /), retains driveletters!
{
	my $entry = shift;

	$entry =~ s#\Q$sep\E#\/#go  if ($bummer && $entry =~ /\:/o);
	return $entry;
}

sub _borgify  #(INTERNAL) Convert standard (*nix) paths to Windows (/path => C:\path, A:/path => A:\path)
{             #ALSO REMOVE ANY TRAILING '/' OR '\\' (unless path == '/'.
	my $entry = shift;

	if ($bummer) {
		$entry =~ s#^([a-z]\:)#\U$1\E\:#o;
		$entry =~ s#^\/#C\:\/#io  if ($entry !~ /\:/o);
		$entry =~ s#\/#$sep#go  unless ($entry =~ m#\\#o);
		$entry =~ s#\Q${sep}\E$##o;
	} else {
		$entry =~ s#${sep}$##o  unless ($entry eq $sep);
	}
	return $entry;
}

sub curselection  #convenience method for JFM5 file-manager:
{
	return shift->selectionGet;
}

sub index  #convenience method for JFM5 file-manager (returns psudo-normalized [C:]/paths):
{
	my ($w, $idx) = @_;

	return &_normalize($w->{'_lastactive'})  if ($idx =~ /^active$/o);
	return &_normalize($w->info('anchor'))  if ($idx =~ /^(?:active|anchor)$/o);
	return &_normalize($idx);
}

sub expand  #OPEN ALL NECESSARY DIRECTORIES TO MAKE $entry VISABLE AND SELECTABLE:
{
	my ($w, $entry) = @_;

	return  unless (-d $entry);
	my $rootdir = $w->cget('-root');
	my $dir = '';
	foreach my $name (split( /\Q$sep\E/, $entry )) {
		next  unless (length $name);
		$dir .= $sep  unless ($bummer && $dir eq '');
		$dir .= $name;
		$w->open($dir, -noexpand => 1)  if ((!$rootdir || $dir =~ /^\Q$rootdir\E/) && -d $dir && $dir ne $entry);
	}
}

sub anchorSet
{
	my ($w, $entry) = @_;

	$entry = &_borgify($entry);
	my $showcursor = $w->{'-showcursoralways'} || ((defined($_[2]) && $_[2] == 1) ? 1 : $w->{'-showcursoralways'});
	$w->Tk::Tree::anchorClear;
	if ($w->{Configure}{'-state'} !~ /d/o
			&& ($showcursor || $w->{'_hasfocus'})) {
		eval "\$w->Tk::Tree::anchorSet(\$entry)";  #FAIL SILENTLY IF NOT OPEN & CAN'T SEE!
		if ($@) {
			$w->expand($entry);
			eval "\$w->Tk::Tree::anchorSet(\$entry)";  #FAIL SILENTLY IF NOT THERE OR CAN'T SEE!
		}
	}
	$w->{'_lastactive'} = $entry;          #THIS HIDES CURSOR.
}

sub activate  #convenience method for JFM5 file-manager (psudonym for anchorSet()):
{
	return anchorSet(@_);
}

sub getRow  #convenience method for JFM5 file-manager (returns psudo-normalized [C:]/paths):
{
	my ($w, $val) = @_;

	$val = &_borgify($val);
	wantarray ? ({'-filename' => $val}, &_normalize($val), ((-d $val) ? 'd' : '-')) : &_normalize($val);
}

#THESE METHODS WRAP THEIR Tk-Tree VERSIONS TO SILENCE ERRORS AND EITHER FAIL GRACEFULLY OR 
#EXPAND COLLAPSED ENTRIES IF NEEDED TO AVOID ERRORS FROM Tk::Tree (WHICH IS RATHER "NOISY"), 
#AND ALSO HANDLE M$-Windows PATH FORMAT TRANSLATIONS:

sub selectionSet
{
	my ($w, $entry) = @_;

	$entry = &_borgify($entry);
	eval "\$w->Tk::Tree::selectionSet(\$entry)";
	if ($@) {
		$w->expand($entry);  #FAILS IF COLLAPSED (NOT DISPLAYED), SO EXPAND AND TRY AGAIN:
		eval "\$w->Tk::Tree::selectionSet(\$entry)";  #FAIL SILENTLY IF NOT THERE!
	}
	return $@ || 0;
}

sub selectionClear
{
	my $w = shift;
	my $entry = shift;

	#IF SOMEONE GIVES US 2 ARGS, IE. "(0, 'end')", JUST CLEAR ALL (WE CAN'T DO RANGES)!
	return $w->Tk::Tree::selectionClear  if (!defined($entry) || defined($_[0]));
	return $w->Tk::Tree::selectionClear(&_borgify($entry));
}

sub selectionToggle  #convenience method for JFM5 file-manager:
{
	my ($w, $indx) = @_;
	my @selected = $w->selectionGet;

	foreach my $s (@selected) {
		if ($s eq $indx) {
			$w->selectionClear($indx);
			return;
		}
	}
	$w->selectionSet($indx);
}

sub see
{
	my $w = shift;
	my $entry = shift;

	$entry = &_borgify($entry);
	eval "\$w->Tk::Tree::see(\$entry)";
	if ($@) {
		$w->expand($entry);  #FAILS IF COLLAPSED (NOT DISPLAYED), SO EXPAND AND TRY AGAIN:
		eval "\$w->Tk::Tree::see(\$entry)";  #FAIL SILENTLY IF NOT THERE!
	}
	return $@ || 0;
}

sub hide
{
	my $w = shift;
	my @args = @_;

	unshift @args, '-entry'  unless ($#args >= 1 && $args[0] =~ /^\-/o);
	$args[1] = &_borgify($w->index(&_borgify($args[1])));
	eval "\$w->Tk::HList::hide(\@args)";
	return $@ || 0;
}

sub show
{
	my $w = shift;
	my @args = @_;

	unshift @args, '-entry'  unless ($#args >= 1 && $args[0] =~ /^\-/o);
	$args[1] =  &_borgify($w->index(&_borgify($args[1])));
	eval "\$w->Tk::HList::show(\$args[0], \$args[1])";
	if ($@) {
		my %ops = @args;
		unless ($ops{'-noexpand'}) {
			$w->expand($args[1]);  #FAILS IF COLLAPSED (NOT DISPLAYED), SO EXPAND AND TRY AGAIN:
			eval "\$w->Tk::HList::show(\$args[0], \$args[1])";  #FAIL SILENTLY IF NOT THERE!
		}
	}
	return $@ || 0;
}

sub selectionIncludes
{
	my $w = shift;
	my $entry = shift;

	my $res = 0;
	$entry = &_borgify($entry);
	
	eval "\$res = \$w->Tk::Tree::selectionIncludes(\$entry)";  #FAIL SILENTLY IF NOT THERE OR CAN'T SEE!
	if ($@) {
		$w->expand($entry);  #FAILS IF COLLAPSED (NOT DISPLAYED), SO EXPAND AND TRY AGAIN:
		eval "\$res = \$w->Tk::Tree::selectionIncludes(\$entry)";  #FAIL SILENTLY IF NOT THERE!
	}
	return $@ ? 0 : $res;
}

sub close
{
	my $w = shift;
	my $entry = shift;

	$entry = &_borgify($entry);
	eval "\$w->Tk::Tree::close(\$entry)";  #FAIL SILENTLY IF NOT THERE OR CAN'T SEE!
	return $@ || 0;
}

sub open
{
	my $w = shift;
	my $entry = shift;
	my %ops = @_;

	$entry = &_borgify($entry);
	return "e:open:$entry Not a directory!"  unless (-d $entry);

	eval "\$w->Tk::Tree::open(\$entry)";  #FAIL SILENTLY IF NOT THERE OR CAN'T SEE!
	if ($@ && !$ops{'-noexpand'}) {  #FAILS IF COLLAPSED (NOT DISPLAYED), SO EXPAND AND TRY AGAIN:
		$w->expand($entry);
		eval "\$w->Tk::Tree::open(\$entry)";  #FAIL SILENTLY IF NOT THERE!
	}
	return $@ || 0;
}

sub FileTree_ButtonPress1
{
	my $w = shift;
	return  if ($w->{Configure}{'-state'} =~ /d/o);

	my $Ev = $w->XEvent;
	my $mode = $w->cget('-selectmode');
	$w->Tk::HList::Button1($Ev);
	my $force = ($mode !~ /^multiple/o && ! $w->{'_hasfocus'}) ? 1 : undef;
	#FORCE ANCHOR-SET ON UNFOCUSED WIDGET SO DRAG-SELECT WILL WORK (HList USES ANCHOR FOR ACTIVE CURSOR)!:
	my $ent = $w->Tk::HList::GetNearest($Ev->y, 1);
	$w->anchorSet($ent, $force)  if (defined($ent) && length($ent));
}

sub FileTree_ButtonRelease1
{
	my $w = shift;
	return  if ($w->{Configure}{'-state'} =~ /d/o);

	my $Ev = $w->XEvent;
	my $mode = $w->cget('-selectmode');
	$w->Tk::HList::ButtonRelease_1($Ev);
	if ($mode !~ /^multiple/o && ! $w->{'_hasfocus'}) {
		#CLEAR FORCED VISIBLE ANCHOR SET BY FileTree_ButtonPress1 ON UNFOCUSED WIDGET!:
		my $ent = $w->Tk::HList::GetNearest($Ev->y, 1);
		$w->anchorSet($ent)  if (defined($ent) && length($ent));
	}
}

#THIS ALLOWS US TO INTERVENE BEFORE EACH MOUSE-BUTTON FUNCTION IS REDIRECTED TO IT'S
#CORRESPONDING HList EQUIVALENT SO WE CAN BLOCK ACTIONS WHEN WIDGET IS DISABLED:
sub MouseButton
{
	my $w = shift;
	return  if ($w->{Configure}{'-state'} =~ /d/o);

	my $button = shift;
	my $Ev = $w->XEvent;

	eval "\$w->Tk::HList::$button(\$Ev)";
}

sub state {
	my ($w, $val) = @_;

	return $w->{Configure}{'-state'} || undef  unless (defined($val) && $val);

	#THE STUPID HList WIDGET IS BROKEN: WON'T TAKE STATE CHANGE?!  $w->Tk::HList::configure('-state' => $val);
	#SO WE HAVE TO "EMULATE" IT OURSELVES MANUALLY - GRRRRRRRR!:
	return  if (defined($w->{'_prevstate'}) && $val eq $w->{'_prevstate'});  #DON'T DO TWICE IN A ROW!

	$w->{'_statechg'} = 1;
	if ($val =~ /d/o) {  #WE'RE DISABLING (SAVE CURRENT ENABLED STATUS STUFF, THEN DISABLE USER-INTERACTION):
		my $Palette = $w->Palette;
		$w->{'_lastactive'} = $w->index('active') || 0  if ($w->{'_hasfocus'});
		@{$w->{'_savesel'}} = $w->curselection;  #SAVE & CLEAR THE CURRENT SELECTION, FOCUS STATUS & COLORS:
		$w->{'_savefocuscfg'} = $w->cget('-takefocus');
		$w->selectionClear;
		$w->anchorClear;
		$w->{'_foreground'} = $w->foreground;
		$w->{Configure}{'-state'} = $val;
		$w->foreground($w->cget('-disabledforeground') || $Palette->{'disabledForeground'});
		$w->focusNext  if ($w->{'_hasfocus'});  #MOVE FOCUS OFF WIDGET IF IT HAS IT.
		$w->Tk::HList::configure(-takefocus => 0);
		$w->configure(-takefocus => 0);
	} elsif ($w->{'_prevstate'}) {  #ENABLING (BUT DON'T DO ALL THIS WHEN ENABLING *INITIALLY*)!:
		my $fg = $w->{'_foreground'};
		$fg ||= $w->toplevel->cget('-foreground') || $w->toplevel->Palette->{'foreground'};
		$fg ||= $Tk::NORMAL_BG || 'black';
		$w->{Configure}{'-state'} = $val;
		$w->Tk::HList::configure('-foreground' => $fg, -takefocus => $w->{'_savefocuscfg'});
		$w->configure(-takefocus => $w->{'_savefocuscfg'});
		if (ref $w->{'_savesel'}) {   #RESTORE SELECTED LIST.
			$w->selectionSet(shift @{$w->{'_savesel'}})  while (@{$w->{'_savesel'}});
		}
		$w->activate($w->{'_lastactive'})  if ($w->{'_lastactive'});
		my $colr = 'foreground';
		(my $colr_ = $colr) =~ tr/A-Z/a-z/;
		$fg = $w->{'_foreground'};
		$fg ||= $w->toplevel->cget('-foreground') || $w->toplevel->Palette->{'foreground'};
		$w->configure('-foreground' => $fg)  if ($fg);  #RESTORE FG COLOR.
	} else {                        #INSTEAD, JUST DO THIS WHEN INITIALLY SET ENABLED!:
		#NOTE:  HList's DEFAULT FOCUS-MODEL ACTS AS -takefocus => 1 (not '') BUT '',0, AND 1 WORK AS WE EXPECT,
		#SO WE FIX THAT HERE ('' IF NOT SPECIFIED IN INITIAL FLAGS)!:
		$w->Tk::HList::configure(-takefocus => $w->{'_savefocuscfg'});
	}
	$w->{'_prevstate'} = $w->{Configure}{'-state'};
	$w->{'_statechg'} = 0;
}

sub focus
{
	my $w = shift;
	if ($w->{Configure}{'-state'} =~ /d/o) {
		#HANDLE EDGE CASE DUE TO WRONG INITIALIZATION ORDER (-state=disabled, -takefocus=1)!:
		#(WHEN INITIALIZING W/BOTH THESE FLAGS, ->state('disabled') GETS CALLED FIRST SETTING FOCUS:=0,
		#BUT THEN FOCUS GETS SET TO 1(FLAG) CAUSING LEFT-TAB STRANDING)!
		$w->configure(-takefocus => 0)  if ($w->cget('-takefocus'));
		$w->focusNext;
		return;
	}
	$w->Tk::focus;
	$w->{'_hasfocus'} = 1;
	$w->parent->bind('<<LeftTab>>', sub {   #THESE NEEDED TO GET FOCUS-CYCLING RIGHT:
		$w->focusCurrent->parent->focusPrev;
		Tk->break;
	});
	return  if ($w->{'-showcursoralways'});

	#RESTORE CURSOR WHEN FOCUS IS GAINED (FAIL SILENTLY IF NO LONGER VISIBLE!):
	$w->activate($w->{'_lastactive'})  if ($w->{'_lastactive'});
}

sub unfocus
{
	my $w = shift;
	if ($w->{'-showcursoralways'}) {
		$w->{'_hasfocus'} = 0;
		return;
	}

	$w->{'_lastactive'} = $w->index('active')  unless ($w->{Configure}{'-state'} =~ /d/o);
	$w->{'_hasfocus'} = 0;
	$w->anchorClear  unless ($w->{Configure}{'-state'} =~ /d/o);
}

sub fixPalette {     #WITH OUR setPalette, WE CAN CATCH PALETTE CHANGES AND ADJUST EVERYTHING ACCORDINGLY!:
	my $w = shift;   #WE STILL PROVIDE THIS AS A USER-CALLABLE METHOD FOR THOSE WHO ARE NOT.
	my $Palette = $w->Palette;

	$w->background($Palette->{'background'});
	$w->foreground($Palette->{'foreground'});
}

#WE NEED CONTROL OVER COLOR OR PALETTE CHANGES TO THESE COLOR ATTRIBUTES:
sub background {
	my $w = shift;
	my $val = shift;
	return $w->{Configure}{'-background'}  unless (defined($val) && $val);

	my $dfltBG = $w->toplevel->cget('-background');
	#ALLOW BACKGROUND CHANGE IF FORCE OR VALUE APPEARS TO BE USER-SET:
	$w->{'_backgroundset'} = 0  if ($val !~ /^${dfltBG}$/i);
	## Ensure that the base Frame, pane and columns (if any) get set
	unless ($w->{'_backgroundset'}) {
		Tk::configure($w, "-background", $val);
		$w->{Configure}{'-background'} = $val;
		foreach my $tp (qw/text image imagetext/) {
			$w->{"_style$tp"}->configure('-background' => $val, '-activebackground' => $val);
		}
		$w->{'_backgroundset'} = 1  unless ($w->{'_statechg'} || $val =~ /^${dfltBG}$/i);
	}
}

#PBM. IS THAT IF USER SETS A CUSTOM COLOR, WE WANT TO KEEP THAT THRU BOTH STATE AND PALETTE CHANGES,
#OTHERWISE, WE WANT TO PROPERLY CHANGE WHEN EITHER STATE OR PALETTE CHANGES, EVEN IF PALETTE CHANGES 
#WHILE THE STATE IS DISABLED!:
sub foreground {   #THIS CODE IS UGLY AS CRAP, BUT NECESSARY TO ACTUALLY WORK:
	my $w = shift;
	my $val = shift;
	return $w->{Configure}{'-foreground'}  unless (defined($val) && $val);

	my $dfltFG = $w->toplevel->cget('-foreground');
	#ALLOW FOREGROUND CHANGE IF FORCE OR VALUE APPEARS TO BE USER-SET:
	my $palettechg = ($val =~ /^${dfltFG}$/i) ? 1 : 0;
	my $disabled = ($w->{Configure}{'-state'} =~ /d/o) ? 1 : 0;
	my $allowed = 0;
	if ($w->{'_statechg'}) {  #ALWAYS ALLOW FORCE OR STATE-CHANGE TO SET FG:
		$allowed = 1;   #IF FORCE OR WE'RE CHANGING "STATE" (ie. "normal" to "disabled"):
	} elsif ($w->{'_foregroundset'}) {  #USER SPECIFIED A SPECIFIC FG COLOR.
		$allowed = 1  unless ($palettechg);  #PREVIOUSLY USER-SET, ALLOW USER BUT NOT setPalette TO CHANGE:
	} elsif ($disabled) {
		$allowed = 1    #NOT PREVIOUSLY USER-SET, ALLOW setPalette OR DISABLED STATE TO SET FG:
	} elsif (!$w->{'_foregroundset'}) {  #ALLOW CHANGE SINCE USER HASN'T SPECIFIED A COLOR:
		$allowed = 1
	}
	## Ensure that the base Frame, pane and columns (if any) get set
	if ($allowed) {   #FG ALLOWED TO BE CHANGED:
		if ($disabled) {  #FORCE TO DISABLED FG, IF DISABLED:
			my $Palette = $w->Palette;
			$w->{'_foreground'} = $val
					if ($w->{'_statechg'} eq '0');  #STATE CHANGED TO DIABLED BEFORE INITIALIZATION, SO SAVE SAVE USER-SPECIFIED ("normal") COLOR:
			$w->{'_foreground'} = $w->{'_foregroundset'} || $Palette->{'foreground'}  #NEED TO GET IT HERE, SINCE STARTED DISABLED & WE DIDN'T HAVE IT YET!
					unless ($w->{'_foreground'});  #NO "normal" COLOR SAVED YET, SAVE USER'S FG IF SPECIFIED, OR THE PALETTE'S COLOR:
			$val = $w->cget('-disabledforeground') || $Palette->{'disabledForeground'};  #NOW SWITCH TO THE PALETTE'S "DISABLED" FG COLOR.
		}
		Tk::configure($w, "-foreground", $val);
		$w->{Configure}{'-foreground'} = $val;
		foreach my $tp (qw/text image imagetext/) {
			$w->{"_style$tp"}->configure('-foreground' => $val);
		}

		#FREEZE (SAVE) THE FG (IF ENABLED AND SET BY USER, NOT PALETTE & NOT CHANGING "STATE"):
		if (!$disabled && !$palettechg && !$w->{'_statechg'}) {
			$w->{'_foregroundset'} = $val  if (!$disabled && !$palettechg && !$w->{'_statechg'});
		} else {
			#WE MUST CONSIDER UPDATING ACTIVE AND SELECT FOREGROUND IF CHANGING STATES OR PALETTES:
			$w->{'_propogateFG'} = 1;
			$w->activeforeground($val);
			$w->selectforeground($val);
			$w->{'_propogateFG'} = 0;
		}
	} else {   #NOT ALLOWED TO BE CHANGED: MUST RESET TO "USER-SET" FG, SINCE TK'S ALREADY "CHANGED" IT INTERNALLY:
		if ($w->{'_foregroundset'}) {
			Tk::configure($w, "-foreground", $w->{'_foregroundset'});
			$w->{Configure}{'-foreground'} = $w->{'_foregroundset'};
		} elsif ($palettechg && $disabled) {  #IF WE'RE NOT "USER-SET" AND WE'RE DISABLED, SAVE NEW PALLETTE-SET FG FOR RESTORATION WHEN ENABLED:
			$w->{'_foreground'} = $val;
		}
	}
}

sub activeforeground {
	my ($w, $val) = @_;
	return $w->{Configure}{'-activeforeground'}  unless (defined($val) && $val);

	my $dfltFG = $w->toplevel->cget('-foreground');
	my $palettechg = ($val =~ /^${dfltFG}$/i) ? 1 : 0;
	my $disabled = ($w->{Configure}{'-state'} =~ /d/o) ? 1 : 0;
	my $allowed = 0;
	if ($w->{'_activeforegroundset'}) {
		$allowed = 1  unless ($w->{'_propogateFG'} || $palettechg);  #USER-SET:  ALLOW USER, BUT NOT setPalette TO CHANGE:
	} else {
		$allowed = 1;  #NOT PREVIOUSLY USER-SET, SO ALLOW setPalette IF ENABLED:
	}
	if ($allowed) {
		$w->{Configure}{'-activeforeground'} = $val;
		foreach my $tp (qw/text image imagetext/) {
			$w->{"_style$tp"}->configure('-activeforeground' => $val);
		}
		$w->{'_activeforegroundset'} = $val  unless ($disabled || $palettechg
				|| $w->{'_statechg'} || $w->{'_propogateFG'});
	} else {   #NOT ALLOWED TO BE CHANGED: MUST RESET TO "USER-SET" FG, SINCE TK'S ALREADY "CHANGED" IT INTERNALLY:
		if ($w->{'_activeforegroundset'}) {
			eval { Tk::configure($w, "-activeforeground", $w->{'_activeforegroundset'}); };
			$w->{Configure}{'-activeforeground'} = $w->{'_activeforegroundset'};
		}
	}
}

sub selectforeground {
	my ($w, $val) = @_;
	return $w->{Configure}{'-selectforeground'}  unless (defined($val) && $val);

	my $dfltFG = $w->toplevel->cget('-foreground');
	my $palettechg = ($val =~ /^${dfltFG}$/i) ? 1 : 0;
	my $disabled = ($w->{Configure}{'-state'} =~ /d/o) ? 1 : 0;
	my $allowed = 0;
	if ($w->{'_selectforegroundset'}) {
		$allowed = 1  unless ($w->{'_propogateFG'} || $palettechg);  #FROZEN, ALLOW USER, BUT NOT setPalette TO CHANGE:
	} else {
		$allowed = 1;    #NOT FROZEN, ALLOW setPalette IF ENABLED:
	}
	if ($allowed) {
		Tk::configure($w, "-selectforeground", $val);
		$w->{Configure}{'-selectforeground'} = $val;
		foreach my $tp (qw/text image imagetext/) {
			$w->{"_style$tp"}->configure('-selectforeground' => $val);
		}
		$w->{'_selectforegroundset'} = $val  unless ($disabled || $palettechg
				|| $w->{'_statechg'} || $w->{'_propogateFG'});
	} else {   #NOT ALLOWED TO BE CHANGED: MUST RESET TO "FROZEN" FG, SINCE TK'S ALREADY "CHANGED" IT INTERNALLY:
		if ($w->{'_selectforegroundset'}) {
			Tk::configure($w, "-selectforeground", $w->{'_selectforegroundset'});
			$w->{Configure}{'-selectforeground'} = $w->{'_selectforegroundset'};
		}
	}
}

sub font {  #SINCE WE CREATE "DEFAULT" STYLES FOR FG/BG PURPOSES, WE MUST SET THE FONT THERE TOO!:
	my ($w, $val) = @_;

	return $w->{Configure}{'-font'} || undef  unless (defined($val) && $val);

	$w->{Configure}{'-font'} = $val;
	foreach my $tp (qw/text imagetext/) {
		$w->{"_style$tp"}->configure('-font' => $val);
	}
}

1

__END__

=head1 NAME

Tk::FileTree - Tk::DirTree like widget for displaying & manipulating directories 
(and files).

=for category  Tk Widget Classes

=head1 SYNOPSIS

	#!/usr/bin/perl

	use Tk;

	use Tk::FileTree;

	my $bummer = ($^O =~ /MSWin/);

	my $top = MainWindow->new;

	my $tree = $top->Scrolled('FileTree',

		-scrollbars => 'osoe',

		-selectmode => 'extended',

		-width => 40,

		-height => 16,

		-takefocus => 1,

	)->pack( -fill => 'both', -expand => 1);

	my $ok = $top->Button( qw/-text Show -underline 0/, -command => \&showme );

	my $cancel = $top->Button( qw/-text Quit -underline 0/, -command => sub { exit } );

	$ok->pack(     qw/-side left  -padx 10 -pady 10/ );

	$cancel->pack( qw/-side right -padx 10 -pady 10/ );

	my ($root, $home);

	if ($bummer) {

		$home = $ENV{'HOMEDRIVE'} . $ENV{'HOMEPATH'};

		$home ||= $ENV{'USERPROFILE'};

		($root = $home) =~ s#\\[^\\]*$##;

	} else {

		$root = '/home';

		$home = "/home/$ENV{'USER'}";

		$home = $root = '/'  unless (-d $home);

	}

	print "--home=$home= root=$root=\n";

	$tree->set_dir($home, -root => $root);

	MainLoop;

	sub showme {

		my @selection = $tree->selectionGet;

		print "--Show me:  active=".$tree->index('active')."=\n";

		print "--selected=".join('|',@selection)."=\n";

		foreach my $i (@selection) {

			print "-----$i selected.\n";

		}

		my $state = $tree->state();

		print "--state=$state=\n";

		print (($state =~ /d/) ? "--enabling.\n" : "--disabling.\n");

		$tree->state(($state =~ /d/) ? 'normal' : 'disabled');

	}

=head1 DESCRIPTION

Creates a widget to display a file-system (or part of it) in a tree format.  
Works very similar to L<Tk::DirTree>, but displays both files and 
subdirectories by default.  Each subdirectory includes an indicator icon 
resembling [+] or [-] to either expand and view it's contents (files and 
subdiretories) or collapse them respectively.  A separate icon is displayed for 
files and subdirectories making it easier to tell them apart.  Options allow 
users to select a file, a directory, or multiple entries (like a listbox) which 
can be returned to the program for further processing.

This widget is derived from B<Tk::DirTree>.  It provides additional features, 
including listing files, in addition to the subdirectories, options (filters) 
to limit which files are displayed (by specificy including or excluding a list 
of file extensions), and additional bindings and functions to enable 
user-selection and interaction with specific files and directories from within 
other programs.

I took Tk::DirTree, renamed it and modified it to create this module primarily 
to be able to add a "tree-view" option to my Perl-Tk based filemanager 
called B<JFM5>, which allows users to select and perform common functions on 
files and directories on their system, and others (via L<Net::xFTP>).  I have 
previously created other modules toward this effort, namely L<Tk::HMListbox> 
and L<Tk::JThumbnail>.  These modules provide the different "views":  Detailed 
list, Image list, and now Tree-view, respectively.

=head1 STANDARD OPTIONS

B<-background> B<-borderwidth> B<-cursor> 
B<-disabledforeground> B<-exportselection> B<-font> B<-foreground> B<-height> 
B<-highlightbackground> B<-highlightcolor> B<-highlightthickness> B<-relief> 
B<-scrollbars> B<-selectbackground> B<-selectborderwidth> B<-selectforeground> 
B<-state> B<-takefocus> B<-width> B<-xscrollcommand> B<-yscrollcommand>

See L<Tk::options> for details of the standard options.

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name: B<activeForeground>

=item Class: B<activeForeground>

=item Switch: B<-activeforeground>

Specifies an alternate color for the foreground of the "active" entry (the one 
the text cursor is on).  This entry is also shown with a hashed box around it.  
NOTE:  The "activebackground" color, however, is always fixed to the same color 
as the widget's background, due to the fact that the underlying L<Tk::HList> 
module only sets the text and icon areas to the active background, rather than 
the entire row resulting in a somewhat ugly appearance if the row is "active" 
but not "selected".  

DEFAULT:  Same color as the widget's foreground color.

=item Name: B<browseCmd>

=item Class: B<BrowseCmd>

=item Switch: B<-browsecmd>

Specifies a callback to call whenever the user browses on a file or directory 
(usually by single-clicking on the name). The callback is called with one 
argument:  the complete pathname of the file / directory.

=item Name: B<command>

=item Class: B<Command>

=item Switch: B<-command>

Specifies the callback to be called when the user activates on a file or 
directory (usually by double-clicking on the name).  The callback is called 
with one argument, the complete pathname of the file / directory.

=item Name: B<dirCmd>

=item Class:	B<DirCmd>

=item Switch:	B<-dircmd>

Callback function to obtain the list of directories and files for display.  A 
sensible default is provided and it should not be overridden unless you know 
what you are doing!  It takes three arguments:  a widget object handle, a 
directory path, and a boolean value (TRUE for include hidden (dot) files or 
FALSE to exclude them).  

Tk::DirTree documentation:  Specifies the callback to be called when a 
directory listing is needed for a particular directory.  If this option is not 
specified, by default the DirTree widget will attempt to read the directory as 
a Unix directory.  On special occasions, the application programmer may want to 
supply a special method for reading directories: for example, when he needs to 
list remote directories.  In this case, the B<-dircmd> option can be used.  
The specified callback accepts two arguments:  the first is the name of the 
directory to be listed; the second is a Boolean value indicating whether 
hidden sub-directories should be listed. This callback returns a list of names 
of the sub-directories of this directory.

=item Name: B<dirTree>

=item Class:	B<DirTree>

=item Switch:	B<-dirtree>

Boolean option to only show directories (like Tk::DirTree) if TRUE, show both 
directories and files if FALSE.  Use this to work as a drop-in replacement for 
Tk::DirTree.  To truly emulate Tk::DirTree's behavior, one should probably also 
specify "-takefocus => 1", as that seems to be it's default focus model.

DEFAULT:  I<FALSE> (Show both directories and files).

=item Name: B<exclude>

=item Class:	B<Exclude>

=item Switch:	B<-exclude>

Specify a reference to an array of file-extensions to be excluded.  Note:  Not 
applicable to directory names (case insensitive).  See also:  B<-include>.

DEFAULT:  I<[]> (Do not exclude any files).

EXAMPLE:  -exclude => ['exe', 'obj']  (Exclude M$-Windows object and executable 
files).

=item Switch:	B<-height>

Specifies the desired height for the window.  I'm not sure what units it uses, 
so users will need to use trial and error and seems to work differently than 
the B<-width> option.  See also:  B<-width>.

=item Name: B<fileimage>

=item Class:	B<Image>

=item Switch:	B<-fileimage>

Specify an alternate xpm (tiny icon) image to be displayed to the left of each 
file displayed which is not a directory).  See also:  B<-image>.

DEFAULT:  A sensible default icon of a white sheet of paper with a dogeared 
corner is provided.

=item Name: B<image>

=item Class:	B<Image>

=item Switch:	B<-image>

Specify an alternate xpm (tiny icon) image to be displayed to the left of each 
directory).  See also:  B<-fileimage>.

DEFAULT:  A sensible default icon of a yellow folder is provided (the same one 
used by Tk::DirTree).

=item Name: B<include>

=item Class:	B<Include>

=item Switch:	B<-include>

Specify a reference to an array of file-extensions to be included, all other 
entensions will be excluded.  Note:  Not applied to directory names 
(case insensitive).  See also:  B<-exclude>.

DEFAULT:  I<[]> (Include all files).

EXAMPLE:  -include => ['pl', 'pm']  (Include only Perl files).

=item Name: B<root>

=item Class:	B<Directory>

=item Switch:	B<-root>

Specify a "root path" above which the user will not be able to expand to view 
any other subdirectories or files (by clicking the little [-] icon next to 
each directory).  

DEFAULT:  I<"/"> (Allow user to expand any level).

=item Name:	B<selectMode>

=item Class:	B<SelectMode>

=item Switch:	B<-selectmode>

Specifies one of several styles for manipulating the selection.
The value of the option may be arbitrary, but the default bindings
expect it to be either B<single>, B<browse>, B<multiple>, 
B<extended> or B<dragdrop>.

DEFAULT:  I<browse>.

=item Name: B<-showcursoralways>

=item Class: B<-showcursoralways>

=item Switch: B<-showcursoralways>

This option, when set to 1 always shows the active cursor.  When set to 0, 
the active cursor is only shown when the widget has the keyboard focus.  
NOTE:  The option:  I<-takefocus =E<gt> 1> will cause the mouse to give 
keyboard focus to the widget when clicked on an item, which while 
activating the item clicked on will also make the active cursor visible.

DEFAULT: I<0> (Hide cursor when focus leaves the widget).

=item Name: B<showHidden>

=item Class:	B<ShowHidden>

=item Switch:	B<-showhidden>

Boolean option to include hidden (dot) files and directories (if TRUE), 
otherwise, exclude them.

DEFAULT:  I<FALSE> (Exclude hidden directories and files (those that begin with 
a dot (".")).

=item Switch:	B<-state>

Specifies one of two states for the widget: B<normal> or B<disabled>.  
If the widget is disabled then items may not be selected,
items are drawn in the B<-disabledforeground> color, and selection
cannot be modified and is not shown (though selection information is
retained).  Note:  The active and any selected items are saved when 
disabling the widget, and restored when re-enabled.

=item Name:	B<takeFocus>

=item Class:	B<TakeFocus>

=item Switch: B<-takefocus>

There are actually three different focusing options:  Specify B<1> to both 
allow the widget to take keyboard focus itself and to enable grabbing the 
keyboard focus when a user clicks on a row in the tree.  Specify B<''> 
to allow the widget to take focus (via the <TAB> circulate order) but do 
not grab the focus when a user clicks on (selects) a row.  This is the 
default focusing model.  Specify B<0> to not allow the widget to receive 
the keyboard focus.  Disabling the widget will also prevent focus while 
disabled, but restore the previous focusing policy when re-enabled.  

DEFAULT:  I<""> (Empty string, also a "false" value, the default Tk 
focusing option), but different from I<0> (zero), as explained above.

=item Name:	B<width>

=item Class:	B<Width>

=item Switch:	B<-width>

Seems to specify the desired width for the widget in tenths of inches, 
though I haven't confirmed if this is absolute.  It also seems to work 
differently than the B<-height> option.  See also B<-height>.

=back

=head1 WIDGET METHODS

The B<FileTree> method creates a widget object.  
The widget object can also be created via B<Scrolled('FileTree')>.
This object supports the B<configure> and B<cget> methods described in 
L<Tk::options> which can be used to enquire and modify the options described 
above.  The widget also inherits the methods provided by the generic 
L<Tk::Widget>, L<Tk::HList> and L<Tk::Tree> classes.

To create a FileTree widget:

I<$widget> = I<$parent>-E<gt>B<FileTree>(?I<options>?);

The following additional methods are available for FileTree widgets:

=over 4

=item I<$widget>-E<gt>B<activate>(I<index>)

Sets the active element and the selection anchor to the one indicated 
by I<index>.  If I<index> is outside the range of elements in the tree
no element is activated.  The active element is drawn with a thin hashed 
border, and its index may be retrieved with the index B<active> or B<anchor>.  
Note:  The "I<index>" for FileTree widgets (if not I<active> or B<anchor>, 
must be a full path-name to a file or directory in the tree.  Also note, if 
the activated entry is not visible (inside a collapsed directory), the 
directories above it will be expanded (as if the user clicked the [+] icon) 
to make it visible (as the parent I<Tk::Tree> widget requires this in 
order to be able to activate an entry.

=item I<$widget>-E<gt>B<add_pathimage>(I<path>, I<ExpandedImage [+]>, I<CollapsedImage [-]>)

Overrides the default "[+]" and "[-]" icon images (black foreground) used for 
each directory in the tree.  Normally, this is unnecessary, but one specific 
use (useful for users) is adding a matching set with a white foreground if 
setting the palette or background color to a "dark" color (where the 
foreground text is all set to white because a black text foreground is 
difficult to see).  NOTE:  Any program allowing users to change the color 
palette to be changed will also need to unpack, destroy, recreate, add the 
additional pair of images (with white foregrounds) and repack the FileTree 
widget if it determines that the foreground color is being changed from black 
to white (ie. palette has changed from a "light" to a "dark" background).  The 
reason for this extra work is due to the fact that there is no known way to 
go through and reset and redraw all the icons displayed when the palette 
is changed.  Tk does not include white-foreground bitmaps of these two images, 
so the author of such a program will need to either also create these two 
bitmaps and include them in the Tk directory itself 
(ie. /usr/local/lib/site_perl/Tk); or simply use the two corresponding 
"*_night.xpm" icon images B<included> with this module!

=item I<$widget>-E<gt>B<chdir>(I<full_directory_path> [, I<ops> ])

Synonym for I<$widget>-E<gt>B<set_dir>(I<full_directory_path> [, I<ops> ]) - 
a holdover from Tk::DirTree.  See B<setdir> below.

=item I<$widget>-E<gt>B<close>(I<index>)

Collapses the display of the directory specified by I<index>, if it is a 
directory and it is currently expanded (files and subdirectories are 
currently displayed.  If successful, it also activates and scrolls the entry 
into view.  See also the B<open> method.

=item I<$widget>-E<gt>B<curselection>

Convenience method that returns a list containing the "indices" (values) of 
all of the elements in the HListbox that are currently selected.  If there 
are no elements selected in the tree then an empty list is returned.  
The values returned are always fully-qualified file and directory names.  
It is equivalent to I<$widget>-E<gt>B<selectionGet>.

=item I<$widget>-E<gt>B<delete>(I<index>)

Deletes one or all elements of the HListbox.  The "I<index>" must eiter be 
must be a full path-name to a file or directory in the tree or "I<all>", 
meaning delete the entire tree.

=item I<$widget>-E<gt>B<hide>([I<-entry> => ] I<index>)

Given an I<index>, sets the entry to "hidden" so that it does not 
display in the tree (but maintains it's index.  The "I<-entry>" 
argument is unnecessary, but retained for Tk::HList compatability.  
See also the B<show> method.

=item I<$widget>-E<gt>B<index>(I<index>)

Returns the "normalized" version of the entry that corresponds to I<index>.  
"normalized" means that file and directory paths are converted into a 
valid "*nix" format ("/" instead of "\"), any trailing "/" is removed 
unless the path is "/" (root).  This can still be passed to any of the 
public methods, which will ensure they're in the proper format for the 
host operating system.  Two special values may also be given for 
I<index>:  I<active> and I<anchor>, which are similar for I<Tk::HList>-based 
widgets and return the current active element's index.  The subtle difference 
is that "I<anchor>" is not valid when the widget is disabled, but "I<active>" 
will still return the saved anchor position.

=item I<$widget>-E<gt>B<open>(I<index> [, I<ops> ])

Expands the display of the directory specified by I<index>, if it is a 
directory and it is currently collapsed (files and subdirectories are 
currently not displayed.  If successful, it also activates and scrolls the 
entry into view.  The optional I<ops> represents a hash of additional options.  
Currently, the only valid value is "I<-silent =<gt> 1>", meaning just open, 
but don't activate or scroll the window position.  
See also the B<close> method.

=item I<$widget>-E<gt>B<see>(I<index>)

Adjust the view in the tree so that the element given by I<index>
is visible.  If the element is already visible then the command has no effect; 
if the element is near one edge of the window then the widget 
scrolls to bring the element into view at the edge.  If I<index> is hidden 
or not a valid entry, this function is ignored.

=item I<$widget>-E<gt>B<selectionClear>([I<index>])

If I<index> is specified and it's element is currently selected, it will 
be unselected.  If no I<index> is specified, all selected items will be 
unselected, clearing the selection list.

=item I<$widget>-E<gt>B<selectionIncludes>(I<index>)

Returns 1 if the element indicated by I<index> is currently
selected, 0 if it isn't.

=item I<$widget>-E<gt>B<selectionSet>(I<index>)

Adds entry specified by I<index> to the selected list if it is not already 
selected.  Note:  Unlike listboxes, etc. only a single element may be 
selected per call.  Ranges are not accepted (ignored).

=item I<$widget>-E<gt>B<selectionToggle>(I<index>)

If the entry specified by I<index> is currently selected, it will be 
unselected, otherwise, it will be selected.

=item I<$widget>-E<gt>B<set_dir>(I<full_directory_path> [, I<ops> ])

Sets the directory path to be opened and displayed in the widget.  The 
entire file-system (drive-letter in M$-Windows) will be accessible, but 
initially collapsed.  It can add any new files and subdirectories it 
finds in the tree if it has changed since the previous call.

To limit how far up the file-system that users can can 
expand, specify I<-root> =<gt> "I<directory_path>", for example:  
$widget->set_dir("/home/user/documents", -root => "/home/user").  This 
would open the user "user"'s "documents" directory expanded, but not 
permit him to expand either root ("/" or "/home" to see their contents.

=item I<$widget>-E<gt>B<show>([I<-entry> => ] I<index>)

Given an I<index>, sets the hidden entry to visible so that it is 
displayed in the tree (but maintains it's index.  The "I<-entry>" 
argument is unnecessary, but retained for Tk::HList compatability.  
See also the B<hide> method.

=back

=head1 AUTHOR

Jim Turner, C<< <https://metacpan.org/author/TURNERJW> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2022 Jim Turner.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=head1 ACKNOWLEDGEMENTS

Tk::FileTree is a derived work from L<Tk::DirTree>:  
Perl/TK version by Chris Dean <ctdean@cogit.com>. Original Tcl/Tix version by Ioi Kim Lam. 

=head1 KEYWORDS

filetree dirtree filesystem

=head1 SEE ALSO

L<Tk::DirTree>, L<Tk::Tree>, L<Tk::HList>.

