######################################## SOH ###########################################
## Function : Replacement for Tk:Optionmenu (more flexible handling for 'image_only')
##
## Copyright (c) 2002-2009 Michael Krause. All rights reserved.
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##
## History  : V1.0	30-Aug-2002 	Class derived from original Optionmenu. MK
##            V1.1  19-Nov-2002 	Added popup() function MK.
##            V1.2  07-Nov-2003 	Added -tearoff option MK.
##            V1.3  16-Dec-2004 	Added multicolumn & activate option (-rows/-activate option) MK.
##            V1.4  14-Jun-2005 	Added second hierarchy for the options,
##                                  Optionformat: [ label, value], [[keylabel, \@subopts], undef], [], ... MK.
##            V1.5  29-Jul-2005 	Added columnbreak for second hierarchy options
##            V1.6  14-Sep-2005 	Rewrite: Added TRUE multi-level hierarchy options with color opts. MK
##            V1.7  30-Sep-2005 	Added selection-validate operation. MK
##            V1.8  25-Sep-2006 	Added detection for loops, which might crash the app for linux. MK
##            V1.9  11-Mar-2009 	Added -popover 'cursor for popup() func. MK
##            V2.0  06-Feb-2014 	Added '-clearoption*' function to automatically add a 'clear entry'. MK
##
######################################## EOH ###########################################
package Tk::Optionbox;

##############################################
### Use
##############################################
use Storable qw(freeze);
use Tk;
use Tk::Menubutton;
use Tk::Menu;

use strict;
use Carp qw(:DEFAULT cluck);

use vars qw ($VERSION);
$VERSION = '2.0';

use base qw (Tk::Derived Tk::Menubutton);


use constant CLEAR_OPTION_TAG	=>	'__CLEAR__OPTIONBOX_ENTRY__';

########################################################################
Tk::Widget->Construct ('Optionbox');

my $ClearXPM;

#---------------------------------------------
sub ClassInit {
	my ($class, $window) = (@_);
	
	$class->SUPER::ClassInit($window);
	$window->bind ($class, '<Control-Tab>','focusNext');
	$window->bind ($class, '<Control-Shift-Tab>','focusPrev');
	$window->bind ($class, '<Tab>', 'focus');

	###################################################
	# The following Image is borrowed from free
	# Silk icon set 1.3 by Mark James
	# http://www.famfamfam.com/lab/icons/silk/
	###################################################
	$ClearXPM = $window->Pixmap( -data =>  <<'ClearXPM_EOP'
/* XPM */
static char *cancel[] = {
/* columns rows colors chars-per-pixel */
"16 16 10 1",
"  c #EE0000",
". c #F70706",
"X c #F9231D",
"o c #FB3230",
"O c #F84737",
"+ c #FC504A",
"@ c #FE6659",
"# c #FECACA",
"$ c #FFEFEF",
"% c None",
/* pixels */
"%%%%%%%%%%%%%%%%",
"%%%%....... %%%%",
"%%% o@@@@+@X.%%%",
"%% o@+ooooo@X %%",
"%.o@+#+oo+#++X %",
"%.@O#$$++$$#oO.%",
"%.@o@$$$$$$oXO.%",
"%.@oo+$$$$OX.O.%",
"%.@oX+$$$$oX.+ %",
"%.+o+$$$$$$o.O %",
"%.+o#$$oo$$#Xo.%",
"% X++#+..o#oOX %",
"%% X+X.X..XoX %%",
"%%% XOOOOOOX %%%",
"%%%% ... .  %%%%",
"%%%%%%%%%%%%%%%%"
};
ClearXPM_EOP
	) unless $ClearXPM;

}

#---------------------------------------------
sub Populate {
	# Parameters
	my ($this, $args) = @_;

	# Locals
	my ($var, $menu, %defaults, %all_presets, $value);
	local $_;

	# Check whether we're in backward compatibility mode
	unless (defined $args->{-image}) {
		$args->{-indicatoron} = 1;
		$this->{no_image} = 1;
	}
	
	$this->SUPER::Populate ($args);
	
	# Create a Closure for saving the current value
	$var = delete $args->{-textvariable};
	unless (defined $var) {
		my $gen = undef;
		$var = \$gen;
	}
	$this->configure(-textvariable => $var);

	# Setup DEFAULT Configs
	%defaults = (
    	-takefocus						=> ['SELF', 'takefocus', 'Takefocus', 1],
    	-highlightthickness				=> ['SELF', 'highlightThickness', 'HighlightThickness', 1],
    	-borderwidth					=> [['SELF', 'PASSIVE'], 'borderwidth', 'BorderWidth', 2],
    	-relief							=> [['SELF', 'PASSIVE'], 'relief', 'Relief', 'raised'],
    	-anchor							=> [['SELF', 'PASSIVE'], 'anchor', 'Anchor', 'w'],
     	-direction 						=> [['SELF', 'PASSIVE'], 'direction', 'Direction', 'flush'],
    	-font							=> [['SELF', 'PASSIVE'], 'font', 'Font', 'Helvetica 12 bold'],
    	-variable 						=> ['PASSIVE', undef, undef, undef],
    	-tearoff 						=> ['PASSIVE', 'tearoff', 'TearOff', 1],
    	-rows	 						=> ['PASSIVE', 'rows', 'Rows', 20],
    	-activate 						=> ['PASSIVE', 'activate', 'Activate', 1],
    	-separator 						=> ['PASSIVE', 'separator', 'Separator', '.'],
    	-options 						=> ['METHOD',  undef, undef, undef],
    	-command 						=> ['CALLBACK',undef,undef,undef],
    	-validatecommand				=> ['PASSIVE', 'validatecommand', 'ValidateCommand', sub {0}],
		# automatic clear entry configs
     	-clearoptionon					=> ['PASSIVE', 'clearoption', 'ClearOption', 0],
     	-clearoptiontext				=> ['PASSIVE', 'clearoptiontext', 'Clearoptiontext', 'CLEAR OPTION'],
     	-clearoptionimage				=> ['PASSIVE', 'clearoptionimage', 'Clearoptionimage', $ClearXPM],
     	-clearoptionforeground			=> ['PASSIVE', 'clearoptionforeground', 'Clearoptionforeground', 'Black'],
     	-clearoptionbackground			=> ['PASSIVE', 'clearoptionbackground', 'Clearoptionbackground', '#d9d9d9'],
     	-clearoptionactiveforeground	=> ['PASSIVE', 'clearoptionactiveforeground', 'Clearoptionactiveforeground', 'Black'],
     	-clearoptionactivebackground	=> ['PASSIVE', 'clearoptionactivebackground', 'Clearoptionactivebackground', '#ececec'],
	);	
	$this->ConfigSpecs(%defaults);

	# configure those opts needed by a create-time-configure
	# @ target-widget-creation here & now
	%all_presets = (%defaults, %$args);
 	foreach (keys %all_presets) {
		$value = defined $args->{$_} ? $args->{$_} : $defaults{$_}[-1];
		next if /-options/;
		$this->configure($_ => $value);
	}
	
	# initialize internals
	$this->{MenuItems} = [];
}
#---------------------------------------------
sub popup
{
	# Parameters
	my ($this, %args) = @_;
	# Locals
	my ($menu, $xpos, $ypos);

	$menu = $this->menu;
	
	if ($args{-popover} and $args{-popover} eq 'cursor') {
	   my $e = $Tk::event;
		$xpos = $e->X;
		$ypos = $e->Y;
	}
	else {
		$xpos = $this->rootx;
		$ypos = $this->rooty;
	}
	$menu->post($xpos, $ypos);
}
#---------------------------------------------
sub set_option
{
	# Parameters
	my ($this, $label, $value, $full_label) = @_;
	#print "DBG: variable [\$this, \$label, \$value, \$full_label] = >$this, $label, $value, $full_label<\n";
	# Locals
	my ($failed, $validatecommand, $variable, $textvariable, $old_label, $old_value);
	
	$validatecommand = $this->cget('-validatecommand');
	$textvariable = $this->cget('-textvariable');
	$variable = $this->cget('-variable');

	$old_value = $variable ? $$variable : $this->{OldValue};
	$old_label = $$textvariable;

	# Some presettings
	$value = $label if @_ == 2;
	$full_label = $label unless $full_label;
	$full_label = '' if $label eq CLEAR_OPTION_TAG();
	
	# Perform validate operation, if available
	do	{ $failed = &$validatecommand ($this, $value, $label, $full_label, $old_value, $old_label)
		} if $validatecommand and $label ne CLEAR_OPTION_TAG();

	#Do the changes
	unless ($failed) {
		$$variable = $value if $variable;
		$this->{OldValue} = $value;
		$$textvariable = $label;

		# Now invoke the callback
		$this->{CallBackActive} = 1;
		$this->Callback(-command => $value, $label, $full_label);
		delete $this->{CallBackActive};
	}	    
}
#---------------------------------------------
my $FingerPrint;
sub add_options
{
	# Parameters
	my ($this, @args) = @_;
	
	# Locals
	my ($test, $menu, $var, $old, $width, $activate, $menu_items, $first,
		$font, $foreground, $background, $activeforeground, $activebackground);

	#-----------------------------------------------------------------------------
	$this->{MenuItems} = [] unless $this->{MenuItems};
	# Check if we already prepared exactly the same tree
	$test = freeze(\@args);
	return if $FingerPrint and $FingerPrint eq $test and scalar @{$this->{MenuItems}} > 0;
	$FingerPrint = $test;
	#print "building new tree...\n";

	$var = $this->cget('-textvariable');
	$width = $this->cget('-width');
	$activate = $this->cget('-activate');
	$font = $this->cget('-font');
	$foreground = $this->cget('-foreground');
	$background = $this->cget('-background');
	$activeforeground = $this->cget('-activeforeground');
	$activebackground = $this->cget('-activebackground');

	# Store old selection
	$old = $$var;

	($menu_items, $width, $first) = $this->generate_menu(undef, (ref $args[0] eq 'ARRAY') ? @{$args[0]} : @args);

	# Check for Auto-gen CLEAR entry
	if ($this->cget('-clearoptionon')) {
		my $clearoptiontext = $this->cget('-clearoptiontext');
		unshift @$menu_items,	[ 'command', $clearoptiontext,
									-command => sub { $this->set_option(CLEAR_OPTION_TAG(), '', '') },
									#-columnbreak => $columnbreak,
									-font => $font,
									-foreground => $this->cget('-clearoptionforeground'),
									-background => $this->cget('-clearoptionbackground'),
									-activeforeground => $this->cget('-clearoptionactiveforeground'),
									-activebackground => $this->cget('-clearoptionactivebackground'),
									-image => $this->cget('-clearoptionimage'),
									($clearoptiontext ? (-compound => 'left') : ()),
								];
	}

	push @{$this->{MenuItems}}, @$menu_items;
	$menu = $this->Menu(-menuitems => $this->{MenuItems});
 	$menu->configure(-font => $font);
	$menu->configure(-tearoff => $this->cget('-tearoff') );
	$menu->configure(-foreground => $this->cget('-foreground') );
	$menu->configure(-background => $this->cget('-background') );
	$menu->configure(-activeforeground => $this->cget('-activeforeground') );
	$menu->configure(-activebackground => $this->cget('-activebackground') );

	# check for old menu
	my $old_menu = $this->cget(-menu);
	if ($old_menu) {
		#print "found an old menu!\n";
		$old_menu->delete(0, 'end');
		$old_menu->destroy;
	}

	# attach it
	$this->configure(-menu => $menu);
	$this->configure(-font => $font);
	
	if (!defined($old) || !exists($this->{MenuItemSetupTable}{$old})) {
		$this->set_option($first, $this->{MenuItemSetupTable}{$first}) if defined $first and $activate;
	}
	if ($this->{no_image}) {
		$this->configure('-width' => $width);
	}
}
#---------------------------------------------
sub generate_menu
{
	# Parameters
	my ($this, $parent) = (shift, shift);

	# Locals
	my ($column, $item, $label, $value, $maxrows, @menu_items,
		$separator, $length, $width, $first,
		$font, $foreground, $background, $activeforeground, $activebackground);
	local $_;

	$column = 0;
	$maxrows = $this->cget('-rows');
	$separator = $this->cget('-separator');
	$font = $this->cget('-font');
	$foreground = $this->cget('-foreground');
	$background = $this->cget('-background');
	$activeforeground = $this->cget('-activeforeground');
	$activebackground = $this->cget('-activebackground');
	
	$parent = '' unless $parent;
	$separator = $this->cget('-separator');

	foreach (@_) {		
		my $columnbreak = $column ? (($column % $maxrows) ? 0 : 1) : 0; # Closure

		$label = $value = $_;
		($label, $value) = @$label if ref $label;
		
		if (ref $label) {
			($label, $value) = @$label;
			my ($menuitems, undef, $first) = $this->generate_menu(($parent ? ($parent . $separator . $label) : $label), @$value);
			$item = [ 'cascade', $label,
									-tearoff => '0',
									-menuitems => $menuitems,
									-columnbreak => $columnbreak,
									-font => $font, 
									-foreground => $foreground,
									-background => $background,
									-activeforeground => $activeforeground,
									-activebackground => $activebackground,
					];
			$label = $first;
		}
		else {
			my ($cmd_label, $cmd_value, $full_label); # Closures
			$cmd_label = $label; $cmd_value = $value;
			$length = length($label);
			$width = $length if (!defined($width) or $length > $width);
			$full_label = ($parent ? ($parent . $separator . $label) : $label);
			$this->{MenuItemSetupTable}{$full_label} = $value;
			$item = [ 'command', $cmd_label,
									-command => sub { $this->set_option($cmd_label, $cmd_value, $full_label) },
									-columnbreak => $columnbreak,
									-font => $font,
									-foreground => $foreground,
									-background => $background,
									-activeforeground => $activeforeground,
									-activebackground => $activebackground,
					];
			$label = $full_label;
		}
		$first = $label unless $first;
		$column++;
		push @menu_items, $item;
	}
	return (\@menu_items, $width, $first);
}
#---------------------------------------------
sub options
{
	my ($this, $opts) = @_;
	if (@_ > 1) {
		if ($this->{CallBackActive}) {
			cluck "\nTk::Optionbox Error: Found an illegal recursion loop: from Callback() to options() which is not allowed!\nAuto-shutting-down now, please let the developer fix this!";
			kill 9, $$;
		}
		delete $this->{MenuItemSetupTable};
		delete $this->{MenuItems};
		$this->add_options($opts);
	}
	else {
		return $this->_cget('-options');
	}

}
#---------------------------------------------
sub itemtable
{
	my $this = shift;
	my %itemtable = $this->{MenuItemSetupTable} ? %{$this->{MenuItemSetupTable}} : ();

	return wantarray ? %itemtable : \%itemtable;
}

########################################################################
1;
__END__


=head1 NAME

Tk::Optionbox - Another pop-up option-widget (with MULTI-level selections)

=head1 SYNOPSIS

    use Tk;
    use Tk::Optionbox

    my $current_class;
    my @all_classes = qw(cat dog bird);
    my $demo_xpm;
	
    my $mw = MainWindow->new();
	
    # prepare some graphics
    setup_pixmap();

    # create a demo 
    my $optionbox = $mw->Optionbox (
        -text     => "Class",
        -image    => $demo_xpm, # use this line for personal pics or
        #-bitmap  => '@' . Tk->findINC('cbxarrow.xbm'));
        -command  => \&class_cb,
        -options  => [ @all_classes ],
        -variable => \$current_class, 
		-tearoff  => '1',
		-rows => 10,
		-activate => '0',
    )->pack;
	
    Tk::MainLoop;
	
    sub class_cb
    {
        print "class_cb called with [@_], \$current_class = >$current_class<\n";
    }
    sub setup_pixmap
    {
        my $cbxarrow_data = <<'cbxarrow_EOP';
	/* XPM */
	static char *cbxarrow[] = {
	"11 14 2 1",
	". c none",
	"  c black",
	"...........",
	"....   ....",
	"....   ....",
	"....   ....",
	"....   ....",
	"....   ....",
	".         .",
	"..       ..",
	"...     ...",
	"....   ....",
	"..... .....",
	"...........",
	".         .",
	".         ."
	};
cbxarrow_EOP

        $demo_xpm = $mw->Pixmap( -data => $cbxarrow_data);
    }
	

=head1 DESCRIPTION

Another menu button style widget that can replace the default Optionmenu.
Useful in applications that want to use a more flexible option menu. 
It's based on the default TK::Optionmenu, beside that it can handle menubuttons
without the persistent, ugly B<menu-indicator>, suitable for perl Tk800.x (developed with Tk800.024).

You can tie a scalar-value to the Optionbox widget, enable/disable it,
assign a callback, that is invoked each time the Optionbox is changed,
as well as set Option-values and configure any of the options
understood by Tk::Frame(s) like -relief, -bg, ... .
(see docs of TK::Optionmenu) for details

=head1 METHODS

=over 4

=item B<set_option()>

'set_option($newvalue)' allows to set/reset the widget methodically,
$newvalue will be aplied to the labeltext (if visible) and the internal
variable regardless if it is a list previously store in options.

You should prefer interacting with the widget via a variable.


=item B<add_options()>

'add_options(@newoptions)' allows to enter additonal options that will be
displayed in the pull-down menu list.

You should prefer to use a Configure ('-options' => ...).

NOTE: Unless You specify -activate => 0 for the widget each time you use
add_options the first item will be set to be the current one and any assigned
callback gets called.

=item B<popup()>

'popup()' allows to immediately popup the menu to force the user
to do some selection.
It is possible to specify -popover => 'cursor' as an additional argument.
Doing this the pop-up selection is shown at the current cursor position instead of
the default location OVER the anchoring button.

=item B<itemtable()>

'itemtable()' retrieves a list of all current selection items.
Requesting a listcontext retrieves a label/value based hash, retrieving
a scalar retrieves a hash-ref. NOTE the B<-separator> setting for
the hierarchical delimiter wherever applied.

=back


=head1 OPTIONS

=over 4

=item B<-variable>

'-variable' allows to specify a reference to a scalar-value.
Each time the widget changes by user interaction, the variable
is changed too. Every variable change is immediately mapped in the
widget too.


=item B<-command>

'-command' can be used to supply a callback for processing after
each change of the Option value.
This callback receives as parameters 'current' value + label + full-label
for hierarcical (sub)lists. NOTE the B<-separator> setting for
the hierarchical delimiter applied for full-label.

=item B<-image>

'-image' can be used to supply a personal bitmap for the menu-button.
In difference to the original Optionmenu the std. menu-indicator is
switched off, if a graphic/bitmap is used , although it might
be re-enabled manually with a B<'-indicatoron =\> 1'> setting.
If no image and no bitmap is specified the text given with B<'-text'>
or the current selected optiontext is displayed in the button.

=item B<-options>

'-options' expects a reference to a list of options.

NOTE: Version 1.4 adds a secondary level to selections: instead of the
plain format label, label, [ label, value ], [ label, value ], [ label, value ],
you must use this format: [ label, value ], [[keylabel, \@subopts], undef], [ label, value ],
NOTE: Version 1.6 adds TRUE multi-level selections. The methodology is the same as before:
Whenever instead of a label an Array-reference is found it is suggested as a subitem-list.
It is poosible to mix plain items, items with spec'd values other than the label in any level.
See the supplied example for further information.

=item B<-activate>

'-activate' expects 0/1 and rules whether the first item applied with -options gets
set 'current'. see NOTE above.

=item B<-rows>

'-rows' defines after how many entries the list gets split into another row. default is 25.
This values applies also for sub-item-lists

=item B<-separator>

'-separator' defines the separator character that is used for the internal representation
of the tree delimiter. Invoking a callback via set_options the target function get [value,
label & full-hierarchical label]. The f-h-label uses the specified separator. Default is '.'

=item B<-tearoff>

'-tearoff' defines whether the pop'd up list will have a tear-off entry at first position.

=item B<-validatecommand>

'-validatecommand' defines a Callback function to evaluate the current selection.
It is invoked with B<the_widget>, B<value>, B<label>, B<full_label>, B<old_value> and B<old_label>.
Returning B<FALSE> will reject the current selection.

=item B<-clearoptionon>

'-clearoptionon' expects 0/1 and rules whether the first option  in the pop'd up optionlist
is an automatically created 'clear' entry which blanks the internal variable and returns
'' to any assigned callback if clicked/selected

=item B<-clearoptiontext> I<text> defines the text of the automatically created 'clear'
entry (default 'CLEAR OPTION'). If the text is left blank only the image is shown

=item B<-clearoptionimage> I<image> defines the image shown within the automatically created 'clear'
entry (default a 'x' sign)

=item B<-clearoptionforeground> color defines the foreground color of the automatically created 'clear'
entry (default 'Black')

=item B<-clearoptionbackground> color defines the background color of the automatically created 'clear'
entry (default '#d9d9d9')

=item B<-clearoptionactiveforeground> color defines the ACTIVE foreground color of the automatically created 'clear'
entry (default 'Black')

=item B<-clearoptionactivebackground> color defines the ACTIVE background color of the automatically created 'clear'
entry (default '#ececec')

=back

Please see the TK:Optionmenu docs for details on all other aspects
of these widgets.


=head1 AUTHORS

Michael Krause, KrauseM_AT_gmx_DOT_net

This code may be distributed under the same conditions as Perl.

V2.0  (C) February 2014

=cut

###
### EOF
###

