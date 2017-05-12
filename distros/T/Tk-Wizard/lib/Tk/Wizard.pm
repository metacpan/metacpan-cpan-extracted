package Tk::Wizard;

use strict;
use warnings;
use warnings::register;

our $VERSION = 2.086;

=head1 NAME

Tk::Wizard - GUI for step-by-step interactive logical process

=cut

use Carp;
use Config;
use Data::Dumper;
use File::Path;
use Tk;
use Tk::DialogBox;
use Tk::Frame;
use Tk::Font;
use Tk::MainWindow;
use Tk::ROText;
use Tk::Wizard::Image;
use Tk::JPEG;
use Tk::PNG;

use constant DEBUG_FRAME => 0;

use vars qw( @EXPORT @ISA %LABELS );

# use Log4perl if we have it, otherwise stub:
# See Log::Log4perl::FAQ
BEGIN {
	eval { require Log::Log4perl; };

	# No Log4perl so bluff: see Log4perl FAQ
	if($@) {
		no strict qw"refs";
		*{__PACKAGE__."::$_"} = sub { } for qw(TRACE DEBUG INFO WARN ERROR FATAL);
	}

	# Setup log4perl
	else {
		no warnings;
		no strict qw"refs";
		require Log::Log4perl::Level;
		Log::Log4perl::Level->import(__PACKAGE__);
		Log::Log4perl->import(":easy");
		# It took four CPAN uploads and tests to workout why
		# one user was getting syntax errors for TRACE: must
		# be the Mithrasmas spirit (hic):
		if ($Log::Log4perl::VERSION < 1.11){
			*{__PACKAGE__."::TRACE"} = *DEBUG;
		}
        *{__PACKAGE__."::LOGCROAK"} = *LOGCROAK;
        *{__PACKAGE__."::LOGCONFESS"} = *Carp::confess;
	}

    require Exporter;    # Exporting Tk's MainLoop so that
    @ISA    = ( "Exporter", );    # I can just use strict and Tk::Wizard without
    @EXPORT = ("MainLoop");       # having to use Tk
}

use base qw[ Tk::Derived Tk::Toplevel ];
Tk::Widget->Construct('Wizard');

# See INTERNATIONALISATION
%LABELS = (
    # Buttons
    BACK   => "< Back",
    NEXT   => "Next >",
    FINISH => "Finish",
    CANCEL => "Cancel",
    HELP   => "Help",
    OK     => "OK",
);

my $WINDOZE = ($^O =~ m/MSWin32/i);
my @PAGE_EVENT_LIST = qw(
	-preNextButtonAction
	-postNextButtonAction
	-preBackButtonAction
	-postBackButtonAction
);

my $REFRESH_MS = 1000; # Refresh the wizard every REFRESH_MS milliseconds

=head1 SYNOPSIS

	use Tk::Wizard ();
	my $wizard = new Tk::Wizard;
	# OR my $wizard = Tk::MainWindow->new -> Wizard();
	$wizard->configure( -property=>'value' );
	$wizard->cget( "-property");
	# $wizard->addPage(
	# ... code-ref to anything returning a Tk::Frame ...
	# );
	$wizard->addPage(
		sub {
			return $wizard->blank_frame(
				-title    => "Page Title",
				-subtitle => "Sub-title",
				-text     => "Some text.",
				-wait     => $milliseconds_b4_proceeding_anyway,
			);
		}
	);
	$wizard->addPage(
		sub { $wizard->blank_frame(@args) },
		-preNextButtonAction  => sub { warn "My -preNextButtonAction  called here" },
		-postNextButtonAction => sub { warn "My -postNextButtonAction called here" },
	);
	$wizard->Show;
	MainLoop;
	exit;

To avoid 50 lines of SYNOPSIS, please see the files included with the
distribution in the test directory: F<t/*.t>.  These are just Perl
programs that are run during the C<make test> phase of installation: you
can move/copy/rename them without harm once you have installed the module.

=head1 CHANGES

Please see the file F<Changes> included with the distribution for change history.

=head1 DEPENDENCIES

C<Tk> and modules of the current standard Perl Tk distribution.

On MS Win32 only: C<Win32API::File>.

=head1 EXPORTS

    MainLoop();

This is so that I can say C<use strict; use Tk::Wizard> without
having to C<use Tk>. You can always C<use Tk::Wizard ()> to avoid
importing this.

=head1 DESCRIPTION

In the context of this namespace, a Wizard is defined as a graphic user interface (GUI)
that presents information, and possibly performs tasks, step-by-step via a series of
different pages. Pages (or 'screens', or 'Wizard frames') may be chosen logically depending
upon user input.

The C<Tk::Wizard> module automates a large part of the creation of a wizard program
to collect information and then perform some complex task based upon it.

The wizard feel is largely based upon the Microsoft(TM,etc) wizard style: the default is
similar to that found in Windows 2000, though the more traditional Windows 95-like feel is also
supported (see the C<-style> entry in L</WIDGET-SPECIFIC OPTIONS>. Sub-classing the
module to provide different look-and-feel is highly encourage: please see
L</NOTES ON SUB-CLASSING Tk::Wizard>. If anyone would like to do a I<Darwin> or
I<Aqua> version, please let me know how you would like to handle the buttons. I'm not
hot on advertising widgets.

=head1 ADVERTISED SUB-WIDGETS

    my $subwidget = $wizard->Subwidget('buttonPanel');

=over 4

=item buttonPanel

The C<Frame> that holds the navigation buttons and optional help button.

=item nextButton

=item backButton

=item cancelButton

=item helpButton

The buttons in the C<buttonPanel>.

=item tagLine

The line above the C<buttonpanel>, a L<Tk::Frame|Tk::Frame> object.

=item tagText

The grayed-out text above the C<buttonpanel>, a L<Tk::Label|Tk::Label> object.

=item tagBox

A L<Tk::Frame|Tk::Frame> holding the tagText and tagLine.

=item imagePane

On all pages of a C<95>-style Wizard,
and for the first and last pages of the default c<top>-style Wizard,
this is a large pane on the left, that holds an image.
For the other pages of a C<top>-style Wizard, this refers to the image box at the top of the wizard.

=item wizardFrame

The frame that holds the content frame, the current Wizard page.

=back

=head1 STANDARD OPTIONS

=over 4

=item -title

Text that appears in the title bar.

=item -background

Main background colour of the Wizard's window.

=back

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item Name:   style

=item Class:  Style

=item Switch: -style

Sets the display style of the Wizard.

The default no-value or value of C<top> gives the Wizard will be a Windows 2000-like
look, with the initial page being a version of the traditional
style with a white background, and subsequent pages being C<SystemButtonFace> coloured,
with a white strip at the top holding a title and subtitle, and a smaller image (see
C<-topimagepath>, below).

The old default of C<95> is still available, if you wish to create a traditional,
Windows 95-style wizard, with every page being C<SystemButtonFace> coloured, with a
large image on the left (C<-imagepath>, below).

=item Name:   imagepath

=item Class:  Imagepath

=item Switch: -imagepath

Path to an image that will be displayed on the left-hand side
of the screen.  (Dimensions are not constrained.) One of either:

=over 4

=item *

Path to a file from which to construct a L<Tk::Photo|Tk::Photo>
object without the format being specified;
No checking is done, but paths ought to be absolute, as no effort
is made to maintain or restore any initial current working directory.

=item *

A reference to a Base64-encoded image to pass in the C<-data> field of the
L<Tk::Photo|Tk::Photo> object.  This is the default form, and a couple
of extra, unused images are supplied: see L<Tk::Wizard::Image>.

=back

=item Name:   topimagepath

=item Class:  Topimagepath

=item Switch: -topimagepath

Only required if C<-style=E<gt>'top'> (as above): the image
this filepath specifies
will be displayed in the top-right corner of the screen. Dimensions are not
restrained (yet), but only 50x50 has been tested.

Please see notes for the C<-imagepath>>.

=item Name:   nohelpbutton

=item Class:  Nohelpbutton

=item Switch: -nohelpbutton

Set to anything to disable the display of the I<Help> button.

=item Name:   resizable

=item Class:  resizable

=item Switch: -resizable

Supply a boolean value to allow resizing of the window: default
is to disable that feature to minimise display issues.

=item Switch: -tag_text

Text to supply in a 'tag line' above the wizard's control buttons.
Specify empty string to disable the display of the tag text box.

=item -fontfamily

Specify the "family" (ie name) of the font you want to use for all Wizard elements.
The default is your operating system default (or a sans serif), which on my test computers is
"MS Sans Serif" on Windows, "Helvetica" on Linux, and "Helvetica" on Solaris.

=item -basefontsize

Specify the base size of the font you want to use for all Wizard elements.
Titles and subtitles will be drawn a little larger than this;
licenses (the proverbial fine print) will be slightly smaller.
The default is your operating system default, which on my test computers is
8 on Windows, 12 on Linux, and 12 on Solaris.

=item -width

Specify the width of the CONTENT AREA of the Wizard, for all pages.
The default width (if you do not give any -width argument) is 50 * the basefontsize.
You can override this measure for a particular page by supplying a -width argument to the add*Page() method.

=item -height

Specify the height of the CONTENT AREA of the Wizard, for all pages.
The default height (if you do not give any -height argument) is 3/4 the default width.
You can override for a particular page by supplying a -height argument to the add*Page() method.

=item -kill_self_after_finish

The default for the Wizard is to withdraw itself after the "finish"
(or "cancel") button is clicked.  This allows the Wizard to be reused
during the same session (the Wizard will be destroyed when its parent
MainWindow is destroyed).
If you supply a non-zero value to this option,
the Wizard will instead be destroyed after the "finish" button is clicked.

=back

Please see also L</ACTION EVENT HANDLERS>.

=head2 WIZARD REFRESH RATE

C<$Tk::Wizard::REFRESH_MS> is the number of milliseconds
after which an C<update> will be called to redraw the Wizard.
Current value is one second.

=head1 METHODS

=head2 import

	use Tk::Wizard;
	use Tk::Wizard ();
	use Tk::Wizard ':old';
	use Tk::Wizard ':use' => [qw[ Choices FileSystem ]];

All the above examples are currently equivalent. However,
as of version 3.00, later in 2008, the first two will no
longer act as the last two -- that is, they will no longer
import the methods now located in the C<Choices> and
C<FileSystem> modules (L<Tk::Wizard::Choices>, L<Tk::Wizard::FileSystem>):
you will have to do that yourself, as in the final example,
or manuall:

	use Tk::Wizard;
	use Tk::Wizard::Tasks;

=cut

sub import {
	my $inv = shift;
	# The default `use module ()` messes up the logic below; fix with:
	shift if scalar(@_) and not defined $_[0];

	TRACE "Enter import for ".$inv;
	if (scalar @_){
		TRACE "Import list : ", join(",",@_);
	} else {
		TRACE "No import list";
	}

	# Maintian backwards compatabilty while $VERSION < 3
	if (not scalar(@_) or $_[0] eq ':old'){

		require Tk::Wizard::Choices;
		Tk::Wizard::Choices->import if Tk::Wizard::Choices->can('import');

		require Tk::Wizard::FileSystem;
		Tk::Wizard::FileSystem->import if Tk::Wizard::FileSystem->can('import');

		require Tk::Wizard::Tasks;
		Tk::Wizard::Tasks->import if Tk::Wizard::Tasks->can('import');
	}

	elsif (scalar @_ == 1){
		if ($_[0] eq ':none'){
			TRACE "Load no modules";
		}
	}

	elsif ($_[0] eq ':use'){
		shift; # drop :use - everything else is a sub-module sub-name
		my $use = shift;
		foreach my $m (ref $use? @$use : $use){
			my $n = 'Tk::Wizard::'.$m.'.pm';
			my $o = $n;
			$n =~ s/::/\//g;
			# require Tk::Wizard::Choices;
			require $n;
			$o->import;
		}
	}

	return @_;
}


=head2 new

Create a new C<Tk::Wizard> object.  You can provide custom values for any
or all of the standard widget options or widget-specific options

=cut

# The method is overridden to allow us to supply a MainWindow if one
# is not supplied by the caller.  Not supplying one suits me, but Mr.
# Rothenberg requires one, and he was probably right.

sub new {
    TRACE "Enter new with ", (@_ || 'nothing');
    my $inv = ref( $_[0] ) ? ref( $_[0] ) : $_[0];
    shift;    					# Ignore invocant

    my @args = @_;

    unless (
        ( scalar(@_) % 2 )		# Not a simple list
        and ref $args[0]		# Already got a MainWindow
    ) {
        # Get a main window:
        unshift @args, Tk::MainWindow->new;
        push @args, "-parent" => $args[0];
        push @args, "-kill_parent_on_destroy" => 1;
        $args[0]->optionAdd( '*BorderWidth' => 1 );
    }

    my $self        = $inv->SUPER::new(@args);
    my $font_family = $self->cget( -fontfamily );
    my $font_size   = $self->cget( -basefontsize );

    # Font used for &blank_frame titles
    $self->fontCreate(
        'TITLE_FONT',
        -family => $font_family,
        -size   => $font_size + 4,
        -weight => 'bold',
    );

    $self->fontCreate(
        'FIXED',
        -family => 'Courier',
        -size   => $font_size + 1,
    );

    # Font used in multiple choices for radio title
    $self->fontCreate(
        'RADIO_BOLD',
        -family => $font_family,
        -size   => $font_size + 2,
        -weight => 'demi',
    );

    # Fonts used if -style=>"top"
    $self->fontCreate(
        'TITLE_FONT_TOP',
        -family => $font_family,
        -size   => $font_size + 4,
        -weight => 'bold',
    );

    $self->fontCreate(
        'SUBTITLE_FONT',
        -family => $font_family,
        -size   => $font_size + 2,
    );

    # Font used in licence agreement  XXX REMOVE TO CORRECT MODULE
    $self->fontCreate(
        'SMALL_FONT',
        -family => $font_family,
        -size   => $font_size - 1,
    );

    # Font used in all other places
    $self->fontCreate(
        'DEFAULT_FONT',
        -family => $font_family,
        -size   => $font_size,
    );

    $self->{defaultFont} = 'DEFAULT_FONT';
    $self->{tagtext}->configure( -font => $self->{defaultFont} );

    if (not $self->cget('-width') ) {
        $self->configure( -width => $font_size * 50 );
    }

    if (not $self->cget('-height') ) {
        $self->configure( -height => $self->cget( -width ) * 0.75 );
    }
    return $self;
}

=head2 Populate

This method is part of the underlying Tk inheritance mechanisms.
You the programmer do not necessarily even need to know it exists;
we document it here only to satisfy Pod coverage tests.

=cut

sub Populate {
    my ( $self, $args ) = @_;
    TRACE "Enter Populate";
    $self->SUPER::Populate($args);
    $self->withdraw;
    my $sTagTextDefault = 'Perl Wizard';
    my $font_size       = $self->_font_size;

    # $composite->ConfigSpecs(-attribute => [where,dbName,dbClass,default]);
    $self->ConfigSpecs(
        -resizable => [ 'SELF', 'resizable', 'Resizable', undef ],

        # Potentially a MainWindow:
        -parent  => [ 'PASSIVE',  undef, undef, undef ],
        -command => [ 'CALLBACK', undef, undef, undef ],

        # -foreground => ['PASSIVE', 'foreground','Foreground', 'black'],
        -background => [ 'METHOD', 'background', 'Background', $WINDOZE? 'SystemButtonFace' : 'gray90' ],
        -style        => [ 'PASSIVE', "style",        "Style",        "top" ],
        -imagepath    => [ 'PASSIVE', 'imagepath',    'Imagepath',    \$Tk::Wizard::Image::LEFT{WizModernImage} ],
        -topimagepath => [ 'PASSIVE', 'topimagepath', 'Topimagepath', \$Tk::Wizard::Image::TOP{WizModernSmallImage} ],

        # event handling references
        -nohelpbutton          => [ 'CALLBACK', undef, undef, sub { 1 } ],
        -preNextButtonAction   => [ 'CALLBACK', undef, undef, sub { 1 } ],
        -postNextButtonAction  => [ 'CALLBACK', undef, undef, sub { 1 } ],
        -preBackButtonAction   => [ 'CALLBACK', undef, undef, sub { 1 } ],
        -postBackButtonAction  => [ 'CALLBACK', undef, undef, sub { 1 } ],
        -preHelpButtonAction   => [ 'CALLBACK', undef, undef, sub { 1 } ],
        -helpButtonAction      => [ 'CALLBACK', undef, undef, sub { 1 } ],
        -postHelpButtonAction  => [ 'CALLBACK', undef, undef, sub { 1 } ],
        -preFinishButtonAction => [ 'CALLBACK', undef, undef, sub { 1 } ],
        -finishButtonAction    => [ 'CALLBACK', undef, undef, sub { $self->withdraw; 1 } ],

        -kill_parent_on_destroy => [ 'PASSIVE',  undef,       undef,      0 ],
        -kill_self_after_finish => [ 'PASSIVE',  undef,       undef,      0 ],
        -debug                  => [ 'PASSIVE',  undef,       undef,      0 ],
        -preCloseWindowAction   => [ 'CALLBACK', undef,       undef,      sub { $self->DIALOGUE_really_quit } ],
        -tag_text               => [ 'PASSIVE',  "tag_text",  "TagText",  $sTagTextDefault ],
        -tag_width              => [ 'PASSIVE',  "tag_width", "TagWidth", 0 ],
        -wizardFrame            => [ 'PASSIVE',  undef,       undef,      0 ],
        -width                  => [ 'PASSIVE',  undef,       undef,      0 ],
        -height                 => [ 'PASSIVE',  undef,       undef,      0 ],
        -basefontsize           => [ 'PASSIVE',  undef,       undef,      $self->_font_size ],
        -fontfamily             => [ 'PASSIVE',  undef,       undef,      $self->_font_family ],
    );

    if ( exists $args->{-imagepath}
    	and not ref($args->{-imagepath}) eq 'SCALAR' and not -e $args->{-imagepath}
    ) {
        Carp::confess "Can't find file at -imagepath: " . $args->{-imagepath};
    }

    if ( exists $args->{-topimagepath}
    	and not ref($args->{-imagepath}) eq 'SCALAR' and not -e $args->{-topimagepath}
    ) {
        Carp::confess "Can't find file at -topimagepath: " . $args->{-topimagepath};
    }
    
    $self->{-imagepath}            = $args->{-imagepath};
    $self->{-topimagepath}         = $args->{-topimagepath};

    # Here's why we need Page objects
    $self->{_pages}        = [];

    # Events indexed like pages
    $self->{_pages_e}	  = {};

	$self->{_pages_e}->{$_} = [] foreach @PAGE_EVENT_LIST;

    $self->{-debug}					= $args->{-debug} || $Tk::Wizard::DEBUG || undef;
    $self->{background_userchoice}	= $args->{-background} || $self->ConfigSpecs->{-background}[3];
    $self->{background} 			= $self->{background_userchoice};
    $self->{-style}					= $args->{-style} || "top";
    $self->{_current_page_idx}		= 0;

    # $self->overrideredirect(1); # Removes borders and controls
	CREATE_BUTTON_PANEL: {
        my $buttonPanel = $self->Frame( -background => $self->{background}, )->pack(qw/ -side bottom -fill x/);
        $buttonPanel->configure( -background => 'yellow' ) if DEBUG_FRAME;

        # right margin:
        my $f = $buttonPanel->Frame(
            -width      => 5,
            -background => $self->{background},
        )->pack( -side => "right", -expand => 0 );
        $f->configure( -background => 'red' ) if DEBUG_FRAME;
		$self->Advertise( buttonPanel => $buttonPanel );
    }

	CREATE_TAGLINE: {
        my $tagbox = $self->Frame(
            -height     => 12,
            -background => $self->{background},
        )->pack(qw/-side bottom -fill x/);
        $tagbox->configure( -background => 'magenta' ) if DEBUG_FRAME;

        # This is a new, simpler, accurate-width Label way of doing it:
        $self->{tagtext} = $tagbox->Label(
            -border     => 2,
            -foreground => 'gray50',
            -background => $self->{background},
        );
        $self->{tagtext}->configure( -background => 'red' ) if DEBUG_FRAME;
        $self->_maybe_pack_tag_text;

        # This is the line that extends to the right from the tag text:
        $self->{tagline} = $tagbox->Frame(
            -relief => 'groove',
            -bd     => 1,
            -height => 2,
        )->pack(qw( -side right -fill x -expand 1 ));
        $self->{tagline}->configure( -background => 'yellow' ) if DEBUG_FRAME;
        $self->Advertise( tagLine => $self->{tagline} );
        $self->Advertise( tagBox  => $tagbox );
        $self->Advertise( tagText => $self->{tagtext} );
    }

	# Desktops for dir select: thanks to Slaven Rezic who also suggested 
    # SHGetSpecialFolderLocation for Win32. I have no Win32 on which to test.
	# There is a good module for this now
    if ($WINDOZE
    	and exists $ENV{USERPROFILE}
    	and -d "$ENV{USERPROFILE}/Desktop"
    ) {
        $self->{desktop_dir} = "$ENV{USERPROFILE}/Desktop";
    }
	elsif (exists $ENV{HOME}){
		if ( -d "$ENV{HOME}/Desktop" ) {
			$self->{desktop_dir} = "$ENV{HOME}/Desktop";
		}
		elsif ( -d "$ENV{HOME}/.gnome-desktop" ) {
			$self->{desktop_dir} = "$ENV{HOME}/.gnome-desktop";
		}
	}

}


=head2 parent

    my $apps_main_window = $wizard->parent;

This returns a reference to the parent Tk widget that was used to create the wizard.

=cut

sub parent { return $_[0]->{Configure}{ -parent } || shift }

sub _maybe_pack_tag_text {
	my $self = shift;
	TRACE "Enter _maybe_pack_tag_text";
    return if ( ( $self->{Configure}{-tag_text} || '' ) eq '' );
    $self->{tagtext}->configure( -text => $self->{Configure}{-tag_text} . ' ' );
    $self->{tagtext}->pack(qw( -side left -padx 0 -ipadx 2 ));
}

sub _pack_forget {
    my $self = shift;
    foreach my $o (@_) {
        $o->packForget if Tk::Exists($o);
    }
}

# Private method: returns a font family name suitable for the
# operating system.  (The default system font, if we can determine it)
sub _font_family {
    my $self = shift;

    # Find the default font on this platform:
    my $label = $self->Label;
    my $sFont = $label->cget( -font );
    return $1          if $sFont =~ /{(.+?)}/;
    return 'Verdana'   if $WINDOZE;
    return 'Helvetica';
}


# Private method: returns a font size suitable for the operating
# system.  (The default system font size, if we can determine it)
sub _font_size {
    my $self = shift;

    # Find the default font on this platform:
    my $label = $self->Label;
    my $sFont = $label->cget( -font );
    return $1 if $sFont =~ /(\d+)/;
	return 8  if $WINDOZE;
    return 12;    # Linux etc.
}


=head2 background

Get/set the background color for the body of the Wizard.

=cut

sub background {
    my $self    = shift;
    my $operand = shift;
    if ( defined($operand) ) {
        $self->{background} = $operand;
    }
    elsif ($self->{-style} ne '95' and (
        $self->_on_first_page or $self->_on_last_page ) 
    ){
        $self->{background} = 'white';
    }
    else {
        $self->{background} = $self->{background_userchoice};
    }
    return $self->{background};
}

# Sub-class me!
# Called by Show().
sub _initial_layout {
    my $self = shift;
    TRACE "Enter _initial_layout";
    return if $self->{_laid_out};

    # Wizard 98/95 style
    if ( $self->_showing_side_banner ) {
        my $im = $self->cget( -imagepath );
        if ( not ref $im ) {
			DEBUG "Load photo from file $im";
			FATAL "No such file as $im" unless -e $im;
			DEBUG $self;
            $self->Photo( "sidebanner", -file => $im );
        }
        else {
            $self->Photo( "sidebanner", -data => $$im );
        }

        # Hard-code white background for first and last page
        my $bg =
            $self->_on_first_page ? 'white'
          : $self->_on_last_page  ? 'white'
          :                         $self->{background};

        $self->{left_object} = $self->Label(
            -image      => "sidebanner",
            -anchor     => "n",
            -background => $bg,
          )->pack(
            -anchor => "n",
            -fill   => 'y',
          );
        $self->{left_object}->configure( -background => 'blue' ) if DEBUG_FRAME;
    }

	# Wizard 2k style - builds the left side of the wizard
    else {
        my $im = $self->cget( -topimagepath );
        if ( ref $im ) {
            $self->Photo( "topbanner", -data => $$im );
        }
        else {
            $self->Photo( "topbanner", -file => $im );
        }
        $self->{left_object} = $self->Label( -image => "topbanner" )->pack( -side => "top", -anchor => "e", );
    }
    $self->Advertise( imagePane => $self->{left_object} );
    $self->{_laid_out}++;
}


# Maybe sub-class me
sub _render_current_page {
    my $self = shift;
    TRACE "Enter _render_current_page $self->{_current_page_idx}";
    my %frame_pack = ( -side => "top" );

    $self->_pack_forget( $self->{tagtext} );

    if (not $self->_showing_side_banner ) {
        $self->_maybe_pack_tag_text;
    }

    if ($self->_on_first_page or $self->_on_last_page) {
        $self->{left_object}->pack( -side => "left", -anchor => "n", -fill => 'y' );
        if ( $self->{-style} ne '95' ) {
            $frame_pack{-expand} = 1;
            $frame_pack{-fill}   = 'both';
        }
    }

    elsif ( $self->cget( -style ) eq 'top' ) {
        $self->_pack_forget( $self->{left_object} );
    }

	# Take page-event from the store and apply to the object.
	# These compromises are getting silly, and indicative of the
	# need for a slight refactoring.

	# TRACE "Page == $self->{_current_page_idx}";
	foreach my $e (@PAGE_EVENT_LIST){
	#	TRACE "E = $e";
	#	TRACE Dumper $self->{_pages_e};
		my $code = $self->{_pages_e}->{$e}->[ $self->{_current_page_idx} ] || undef;
	#	TRACE $code if $code;
		if (defined $code){
			$self->configure( $e => $code )
		} else {
			# $self->configure( $e => undef )
		}
	}

    # $self->_repack_buttons done below;

    # Process button events and re-rendering
    my $panel = $self->Subwidget('buttonPanel');
    my %hssPackArgs = (
        -side   => "right", -expand => 0, -pady   => 5, -padx   => 5, -ipadx  => 8,
    );
    $self->_pack_forget(
		@{ $self->{_button_spacers} },
        $self->{cancelButton},
        $self->{nextButton}, $self->{backButton}, $self->{helpButton},
    );

	# No cancel button on the last page
    unless ($self->_on_last_page ) {
        $self->{cancelButton} = $panel->Button(
            -font    => $self->{defaultFont},
            -text    => $LABELS{CANCEL},
            -command => [ \&_CancelButtonEventCycle, $self, $self ],
        )->pack(%hssPackArgs);

        # Set the cancel button a little apart from the next button:
        my $f1 = $panel->Frame(
            -width      => 8,
            -background => $panel->cget( "-background" ),
        )->pack( -side => "right" );

        $f1->configure( -background => 'black' ) if DEBUG_FRAME;
        push @{ $self->{_button_spacers} }, $f1;
        $self->Advertise( cancelButton => $self->{cancelButton} );
    }

    $self->{nextButton} = $panel->Button(
        -font => $self->{defaultFont},
        -text => $self->_on_last_page ? $LABELS{FINISH} : $LABELS{NEXT},
        -command => [ \&_NextButtonEventCycle, $self ],
    )->pack(%hssPackArgs);
    $self->Advertise( nextButton => $self->{nextButton} );

    $self->{backButton} = $panel->Button(
        -font    => $self->{defaultFont},
        -text    => $LABELS{BACK},
        -command => [ \&_BackButtonEventCycle, $self ],
        -state   => $self->_on_first_page ? 'disabled' : 'normal',
    )->pack(%hssPackArgs);
    $self->Advertise( backButton => $self->{backButton} );

	# Optional help button:
    unless ($self->cget( -nohelpbutton ) ) {
        $self->{helpButton} = $panel->Button(
            -font    => $self->{defaultFont},
            -text    => $LABELS{HELP},
            -command => [ \&_HelpButtonEventCycle, $self ],
          )->pack(
            -side   => 'left', -anchor => 'w',
            -pady   => 10, -padx   => 10,
            -ipadx  => 8,
          );
        $self->Advertise( helpButton => $self->{helpButton} );
    }


    $self->configure( -background => $self->cget("-background") );
    $self->_pack_forget( $self->{wizardFrame} );

    if (not @{ $self->{_pages} } ) {
        LOGCROAK '_render_current_page called without any frames: did you add frames to the wizard?';
    }
    my $page = $self->{_pages}->[ $self->{_current_page_idx} ];

    if (not ref $page){
        LOGCROAK '_render_current_page() called for a non-existent frame: did you add frames to the wizard?';
    }

    my $frame = $page->();
    if (not Tk::Exists($frame) ) {
        LOGCROAK '_render_current_page() called for a non-frame: did your coderef argument to addPage() return something other than a Tk::Frame? '.Dumper($page);
    }

    $self->{wizardFrame} = $frame->pack(%frame_pack);
    $self->{wizardFrame}->update;

    # Update the wizard every 1000 seconds 
    $self->{_refresh_event_id} = $self->{wizardFrame}->repeat(
		$REFRESH_MS,
		sub { $self->{wizardFrame}->update }
	) if not $self->{_refresh_event_id};

    $self->Advertise( wizardFrame => $self->{wizardFrame} );

    $self->{nextButton}->focus();
    TRACE "Leave _render_current_page $self->{_current_page_idx}";
}

=head2 update

Redraws the Wizard.

=cut

sub update {
	my $self = shift;
	$self->{wizardFrame}->update if $self->{wizardFrame};
	return 1;
}


# I wish I could remember why this was used, and then dropped:
sub _resize_window {
    my $self = shift;
    return;
    if ( Tk::Exists( $self->{wizardFrame} ) ) {
        if ( $self->{frame_sizes}->[ $self->{_current_page_idx} ] ) {
            my ( $iW, $iH ) = @{ $self->{frame_sizes}->[ $self->{_current_page_idx} ] };
            DEBUG "Resize frame: -width => $iW, -height => $iH\n";
            $self->{wizardFrame}->configure(
                -width  => $iW,
                -height => $iH,
            );
            $self->{wizardFrame}->update;
            # $self->update;
        }
    }
}

=head2 blank_frame

  my $frame = wizard>->blank_frame(
    -title    => $sTitle,
    -subtitle  => $sSub,
    -text    => $sStandfirst,
    -wait    => $iMilliseconds
  );

Returns a L<Tk::Frame|Tk::Frame> object that is a child of the Wizard
control, with some C<pack>ing parameters applied - for more details,
please see C<-style> entry elsewhere in this document.

Arguments are name/value pairs:

=over 4

=item -title

Printed in a big, bold font at the top of the frame

=item -subtitle

Subtitle/stand-first.

=item -text

Main body text.

=item -wait

The amount of time in milliseconds to wait before moving forward
regardless of the user.  

This actually just calls the C<forward> method (see
L</forward>).  Use of this feature will enable the back-button even if
you have disabled it.  What's more, if the page is supposed to wait for user
input, this feature will probably not give your users a chance.

B<Beware> that if you set this value too low, you find your
callbacks interrupting previous callbacks, Values below 250 will be set to 250,
but you may need 1000.

See also: L<Tk::after>.

=item -width -height

Size of the CONTENT AREA of the wizard.
Yes, you can set a different size for each page!

=back

Also:

  -background

=cut

#
# Sub-class me:
#  accept the args in the POD and return a Tk::Frame
#
sub blank_frame {
    my $self = shift;
    my $args = {@_};
    TRACE "Enter blank_frame";
    DEBUG "self.bg = $self->{background}";

    my $wrap = $args->{-wraplength} || 375;
    if (not defined( $args->{-height} ) ) {
        $args->{-height} = $self->cget( -height );
    }

    if (not defined( $args->{-width} ) ) {
        $args->{-width} = $self->cget( -width );
        $args->{-width} += $self->{left_object}->width
          if !$self->_showing_side_banner;
    }

    $self->{frame_sizes}->[ $self->{_current_page_idx} ] = [ $args->{-width}, $args->{-height} ];
    $self->{frame_titles}->[ $self->{_current_page_idx} ] = $args->{-title} || 'no title given';

    DEBUG "blank_frame setting width/height to $args->{-width}/$args->{-height}";

    # This is the main content frame:
    my $frame = $self->Frame(
        -width      => $args->{-width},
        -height     => $args->{-height},
        -background => $self->{background},
    );
    $frame->configure( -background => 'green' ) if DEBUG_FRAME;

    # Do not let the content (body) frame auto-resize when we pack its contents:
    $frame->packPropagate(0);
    $args->{-title} ||= '';

    # We force the title to be one line (sorry):
    $args->{-title} =~ s/[\n\r\f]/ /g;
    $args->{-subtitle} ||= '';

    # We don't let the subtitle get pushed down away from the title:
    $args->{-subtitle} =~ s/^[\n\r\f]*//;
    my ($lTitle, $lSub, $lText);

    if (not $self->_showing_side_banner ) {

        # For 'top' style pages other than first and last
        my $top_frame = $frame->Frame( -background => 'white', )->pack(
            -fill   => 'x',
            -side   => 'top',
            -anchor => 'e'
        );
        my $p = $top_frame->Frame( -background => 'white' );
        my $photo = $self->cget( -topimagepath );
        if ( ref $photo ) {
            $p->Photo( "topimage", -data => $$photo );
        }
        else {
            $p->Photo( "topimage", -file => $photo );
        }

        $p->Label(
            -image      => "topimage",
            -background => 'white',
        )->pack(
            -side   => "right",
            -anchor => "e",
            -padx   => 5,
            -pady   => 5,
        );
        $p->pack( -side => 'right', -anchor => 'n' );

        my $title_frame = $top_frame->Frame( -background => 'white', )->pack(
            -side   => 'left',
            -anchor => 'w',
            -expand => 1,
            -fill   => 'x',
        );
        my $f = $title_frame->Frame(qw/-background white -width 10 -height 30/)->pack(qw/-fill x -anchor n -side left/);

        $f->configure( -background => 'yellow' ) if DEBUG_FRAME;

        # The title frame content proper:
        $lTitle = $title_frame->Label(
            -justify    => 'left',
            -anchor     => 'w',
            -text       => $args->{-title},
            -font       => 'TITLE_FONT_TOP',
            -background => $title_frame->cget("-background"),
        )->pack(
            -side   => 'top',
            -expand => 1,
            -fill   => 'x',
            -pady   => 5,
            -padx   => 0,
        );

        $lSub = $title_frame->Label(
            -font       => 'SUBTITLE_FONT',
            -justify    => 'left',
            -anchor     => 'w',
            -text       => '   ' . $args->{-subtitle},
            -background => $title_frame->cget("-background"),
        )->pack(
            -side   => 'top',
            -expand => 0,
            -fill   => 'x',
            -padx   => 5,
        );

        # This is the line below top:
        if ( ( $self->cget( -style ) eq 'top' ) && !$self->_on_first_page ) {
            my $f = $frame->Frame(
                -relief => 'groove',
                -bd     => 1,
                -height => 2,
            )->pack(qw/-side top -fill x/);
            $f->configure( -background => 'red' ) if DEBUG_FRAME;
		}

        if ( $args->{-text} ) {
            $lText = $frame->Label(
                -font       => $self->{defaultFont},
                -justify    => 'left',
                -anchor     => 'w',
                -wraplength => $wrap + 100,
                -justify    => "left",
                -text       => $args->{-text},
                -background => $self->{background},
              )->pack(
                -side => 'top',

                # -anchor => 'n',
                # -expand => 1,
                -expand => 0,
                -fill   => 'x',
                -padx   => 10,
                -pady   => 10,
            );
        }
    }

    # if 'top' style, but not first or last page
	# Whenever page does NOT have the side banner:
    else {
        $lTitle = $frame->Label(
            -justify    => 'left',
            -anchor     => 'w',
            -text       => $args->{-title},
            -font       => 'TITLE_FONT',
            -background => $frame->cget("-background"),
        )->pack(
            -side   => 'top',
            -anchor => 'n',
            -expand => 0, # 1
            -fill   => 'x',
        );
        $lSub = $frame->Label(
            -font       => 'SUBTITLE_FONT',
            -justify    => 'left',
            -anchor     => 'w',
            -text       => '   ' . $args->{-subtitle},
            -background => $frame->cget("-background"),
        )->pack(
            -anchor => 'n',
            -side   => 'top',
            -expand => 0,
            -fill   => 'x',
        );
        
        if ( $args->{-text} ) {
            $lText = $frame->Label(
                -font       => $self->{defaultFont},
                -justify    => 'left',
                -anchor     => 'w',
                -wraplength => $wrap,
                -justify    => "left",
                -text       => $args->{-text},
                -background => $frame->cget("-background"),
            )->pack(
                -side   => 'top',
                -expand => 0,
                -fill   => 'x',
                -pady   => 10,
            );
        }
        else {
            $frame->Label();
        }
    }

    if (DEBUG_FRAME){
    	$lTitle->configure( -background => 'light blue' );
    	$lSub->configure( -background   => 'light green' );
    	Tk::Exists($lText) && $lText->configure( -background => 'pink' );
	}

    DEBUG "blank_frame(), raw -wait is ".($args->{-wait} || "undef");
    $args->{ -wait } ||= 0;
    DEBUG "blank_frame(), cooked -wait is now $args->{-wait}";

    if ( $args->{ -wait } > 0 ) {
        _fix_wait( \$args->{ -wait } );
        DEBUG "In blank_frame(), fixed  -wait is $args->{-wait}";
        DEBUG "Installing 'after', self is $self";
        $self->after(
            $args->{-wait},
            sub {
                $self->{nextButton}->configure( -state => 'normal' );
                $self->{nextButton}->invoke;
            }
        );
    }

    return $frame->pack(qw/-side top -anchor n -fill both -expand 1/);
}


=head2 addPage

    $wizard->addPage ($page_code_ref1 ... $page_code_refN)
    $wizard->addPage (@args)
    $wizard->addPage ($page_code_ref, -preNextButtonAction => $x, -postNextButtonAction => $y)

Adds a page to the wizard. The parameters must be references to code that
evaluate to L<Tk::Frame|Tk::Frame> objects, such as those returned by the methods
C<blank_frame> and C<addDirSelectPage>.

Pages are (currently) stored and displayed in the order added.

Returns the index of the page added, which is useful as a page UID when
performing checks as the I<Next> button is pressed (see file F<test.pl>
supplied with the distribution).

As of version 2.084, you can just supply the args to L<blank_frame|blank_frame>.

As of version 2.076, you may supply arguments: C<-preNextButtonAction>,
C<-postNextButtonAction>, C<-preBackButtonAction>, C<-postBackButtonAction>:
see L<ACTION EVENT HANDLERS> for further information. More handlers, and
more documentation, may be added.

=cut

sub addPage {
    TRACE "Enter addPage";
    my ($self, @args) = @_;

	# Bit faster if, as of old, all args are code refs (ie no events):
	if (scalar (grep { ref $_ eq 'CODE' } @args) == scalar(@args)) {
	   DEBUG "Add args to make ".scalar @{ $self->{_pages} };
	   push @{ $self->{_pages} }, @args;
    }

	# Add pages with arguments:
    else {
		my ($code, @sub_args, $found);
		while (@args){
			if (ref $args[0] eq 'CODE'){
				$found = 1;
				if (defined $code){
					DEBUG "Call _addPage_with_args...";
					$self->_addPage_with_args($code, @sub_args);
				} 
                else {
					DEBUG "No code yet...";
				}
				@sub_args = ();
				$code = shift @args;
			} 
            else {
				DEBUG "Add to sub_args...";
				push @sub_args, shift(@args), shift(@args);
			}
		}

		if (defined $code){
			$found = 1;
			DEBUG "Call _addPage_with_args (finally)";
			$self->_addPage_with_args($code, @sub_args);
		}

		if (not $found){
			DEBUG "No code ref found: blank frame from args: ", join", ",@sub_args;
			push @{ $self->{_pages} }, sub { $self->blank_frame(@sub_args) };
		}
	}

	TRACE "Leave addpage";
	return scalar @{ $self->{_pages} };
}


sub _addPage_with_args {
    TRACE "Enter _addPage_with_args";
    my ($self, $code) = (shift, shift);
	my $args = scalar(@_)? {@_} : {};

	# Add the page
	DEBUG "Adding code ".Dumper $code;
    push @{ $self->{_pages} }, $code;

	# Add the arguments
	DEBUG "ARGS ",Dumper $args;
	foreach my $e (@PAGE_EVENT_LIST){
		DEBUG "Add $e for $#{$self->{_pages}}" if defined $args->{$e};
		$self->{_pages_e}->{$e}->[ $#{$self->{_pages}} ] = $args->{$e} || undef;
	}
	TRACE "Leave _addPage_with_args";
}


=head2 addSplashPage

Add to the wizard a page containing a chunk of text, specified in
the parameter C<-text>.  Suitable for an introductory "splash" page
and for a final "all done" page.

Accepts exactly the same arguments as C<blank_frame>.

=cut

sub addSplashPage {
    TRACE "Enter addSplashPage";
    my ($self, $args) = (shift, {@_});
    return $self->addPage( sub { $self->blank_frame(%$args) } );
}

=head2 addTextFramePage

Add to the wizard a page containing a scrolling textbox, specified in
the parameter C<-boxedtext>. If this is a reference to a scalar, it is
taken to be plain text; if a plain scalar, it is taken to be the name
of a file to be opened and read.

Accepts the usual C<-title>, C<-subtitle>, and C<-text> like C<blank_frame>.

=cut

sub addTextFramePage {
    my ($self, $args) = (shift, {@_});
    DEBUG "addTextFramePage args are ", Dumper($args);
    return $self->addPage( sub { $self->_text_frame($args) } );
}

sub _text_frame {
    my $self = shift;
    my $args = shift;

    DEBUG "Enter _text_frame with ", Dumper($args);
    my $text;
    my $frame = $self->blank_frame(%$args);
    if ( $args->{-boxedtext} ) {
        if ( ref $args->{-boxedtext} eq 'SCALAR' ) {
            $text = $args->{-boxedtext};
        }
        elsif ( not ref $args->{-boxedtext} ) {
            open my $in, $args->{-boxedtext}
            	or LOGCROAK "Could not read file: $args->{-boxedtext}; $!";
            read $in, $$text, -s $in;
            close $in;
            WARN "Boxedtext file $args->{-boxedtext} is empty." if not length $text;
        }
    }
    $$text = "" if not defined $text;
    my $t = $frame->Scrolled(
        "ROText",
        -background => ( $args->{ -background } || 'white' ),
        -relief => "sunken",
        -borderwidth => "1",
        -font        => $self->{defaultFont},
        -scrollbars  => "osoe",
        -wrap        => "word",
    )->pack(qw/-expand 1 -fill both -padx 10 -pady 10/);

    $t->configure( -background => 'green' ) if DEBUG_FRAME;
	$t->insert( '0.0', $$text );
    $t->configure( -state => "disabled" );

    return $frame;
}

#
# Function (NOT a method!):       _dispatch
# Description:  Thin wrapper to dispatch event cycles as needed
# Parameters:    The _dispatch function is an internal function used to determine if the dispatch back reference
#         is undefined or if it should be dispatched.  Undefined methods are used to denote dispatchback
#         methods to bypass.  This reduces the number of method dispatches made for each handler and also
#         increased the usability of the set methods when trying to unregister event handlers.
#
sub _dispatch {
    my $handler = shift;
    DEBUG "Enter _dispatch with " . ( $handler || "undef" );

    if ( ref($handler) eq 'Tk::Callback' ) {
        return !$handler->Call();
    }

    if ( ref($handler) eq 'CODE' ) {
        return !$handler->();
    }

    return 1;

    # Below is the original 1.9451 version:
    return ( !( $handler->Call() ) )
      if defined $handler
          and ref $handler
          and ref $handler eq 'CODE';

    return 0;
}

# Returns the number of the last page (zero-based):
sub _last_page {
    my $self = shift;
    my $i    = $#{ $self->{_pages} };
    return $i;
}

# Returns true if the current page is the last page:
sub _on_last_page {
    my $self = shift;
    DEBUG "_on_last_page(), pagePtr is $self->{_current_page_idx}";
    return ( $self->_last_page == $self->{_current_page_idx} );
}

# Returns true if the current page is the first page:
sub _on_first_page {
    my $self = shift;
    return ( 0 == $self->{_current_page_idx} );
}

# Method:      _NextButtonEventCycle
# Description: Runs the complete view of the action handler cycle for the "Next>" button on the
#              wizard button bar. This includes dispatching the preNextButtonAction and
#              postNextButtonAction handler at the appropriate times.
#
# Dictat: Never ever use goto unless you have a very good reason, and please explain that reason
#
sub _NextButtonEventCycle {
    my $self = shift;
    TRACE "Enter _NextButtonEventCycle";
    $self->{_inside_nextButtonEventCycle_}++ unless shift;

    DEBUG "NBEC counter == $self->{_inside_nextButtonEventCycle_}";

    # If there is more than one pending invocation, we will re-invoke
    # ourself when we're done:
    if ( $self->{_inside_nextButtonEventCycle_} > 1) {
        DEBUG "Called recursively, bail out";
        return;
    }

	# XXX DEBUG "Page $self->{_current_page_idx} -preNextButtonAction";
    if ( _dispatch( $self->cget( -preNextButtonAction ) ) ) {
        INFO "preNextButtonAction says we should not go ahead";
	    $self->{_inside_nextButtonEventCycle_}--;
		return;
    }

    if ( $self->_on_last_page ) {
        DEBUG "On the last page";
        if ( _dispatch( $self->cget( -preFinishButtonAction ) ) ) {
            DEBUG "preFinishButtonAction says we should not go ahead";
		    $self->{_inside_nextButtonEventCycle_}--;
            return;
        }
        elsif ( _dispatch( $self->cget( -finishButtonAction ) ) ) {
            DEBUG "finishButtonAction says we should not go ahead";
		    $self->{_inside_nextButtonEventCycle_}--;
        	return;
        }
        else {
        	$self->{really_quit}++;
        	$self->_CloseWindowEventCycle();
		}
    }

	# Advance the wizard page pointer and then adjust the navigation buttons.
	# Redraw the frame when finished to get changes to take effect.
	else {
		TRACE "OK - advance to next page";
		$self->_page_forward;
		$self->_render_current_page;
	}

    DEBUG "Before _dispatch postNextButtonAction";
    if ( _dispatch( $self->cget( -postNextButtonAction ) ) ) {
        INFO "postNextButtonAction says we should not go ahead";
	    $self->{_inside_nextButtonEventCycle_}--;
        return;
    }

    DEBUG "Done, NBEC counter is now $self->{_inside_nextButtonEventCycle_}";

    $self->{_inside_nextButtonEventCycle_}--;

    $self->_NextButtonEventCycle('no increment') if $self->{_inside_nextButtonEventCycle_};
}


# Move the wizard pointer back one position and then adjust the
# navigation buttons to reflect any state changes. Don't fall off
# end of page pointer
sub _BackButtonEventCycle {
    my $self = shift;
    return if _dispatch( 
        $self->cget( -preBackButtonAction ) 
    );
    $self->_page_backward;
    $self->_render_current_page;
    return if _dispatch( 
        $self->cget( -postBackButtonAction )
    );
	return;
}

sub _HelpButtonEventCycle {
    my $self = shift;
    return if _dispatch( $self->cget(-preHelpButtonAction));
    return if _dispatch( $self->cget( -helpButtonAction));
    return if _dispatch( $self->cget( -postHelpButtonAction));
}

sub _CancelButtonEventCycle {
    my $self = shift;
    return if $self->Callback( -preCancelButtonAction => $self->{-preCancelButtonAction} );
    $self->_CloseWindowEventCycle($_);
}

sub _CloseWindowEventCycle {
    my $self = shift;
    my $gui  = shift;
    TRACE "Enter _CloseWindowEventCycle... really_quit=[", ($self->{really_quit} || 'undef'), "]";

    if ( not $self->{really_quit} ) {
        DEBUG "Really?";
        if ( $self->Callback( -preCloseWindowAction => $self->{-preCloseWindowAction} ) ) {
            DEBUG "preCloseWindowAction says we should not go ahead";
            return;
        }
    }
    if ( Tk::Exists($gui) ) {
        DEBUG "gui=$gui= withdraw";
        $gui->withdraw;
    }

    if ( $self->{Configure}{-kill_parent_on_destroy} and Tk::Exists( $self->parent ) ) {
        DEBUG "Kill parent " . $self->parent . " " . $self->{Configure}{ -parent };
        # This should kill us, too:
        $self->parent->destroy;
        return;
    }

    DEBUG "Legacy withdraw";
    $self->{_showing} = 0;
    if ( $self->{Configure}{-kill_self_after_finish} ) {
        $self->destroy;
    }
    else {
        $self->withdraw;    # Legacy
    }

    return undef;
}


=head2 Show

	$wizard->Show();

Draw and display the Wizard on the screen.

Usually C<MainLoop> is called immediately after this.

=cut

sub Show {
	TRACE "Enter Show";
    my $self = shift;
    return if $self->{_showing};

    if ( $self->_last_page < 2 ) {
		my $lp = $self->_last_page + 1;
        warnings::warnif(
			ref($self), "Showing a Wizard with "
    	    . $lp . ' page' . ($lp==1? '' : 's').'!'
		)
    }

    $self->{_current_page_idx} = 0;
    $self->_initial_layout;

    $self->resizable( 0, 0 )
      unless $self->{Configure}{-resizable}
         and $self->{Configure}{-resizable} =~ /^(1|yes|true)$/i;

    $self->parent->withdraw;
    $self->Popup;
    $self->transient;    # forbid minimize
    $self->protocol( WM_DELETE_WINDOW => [ \&_CloseWindowEventCycle, $self, $self ] );

    $self->configure( -background => $self->cget("-background") );
    $self->_render_current_page;
    $self->{_showing} = 1;

    TRACE "Leave Show";
    return 1;
}

=head2 forward

Convenience method to move the Wizard on a page by invoking the
callback for the C<nextButton>.

You can automatically move forward after C<$x> tenths of a second
by doing something like this:

  $frame->after($x,sub{$wizard->forward});

=cut

sub forward {
    my $self = shift;
    return $self->_NextButtonEventCycle;
}

=head2 backward

Convenience method to move the Wizard back a page by invoking the
callback for the C<backButton>.

=cut

sub backward {
    my $self = shift;
    return $self->{backButton}->invoke;
}

sub _showing_side_banner {
    my $self = shift;
    return 1 if $self->cget( -style ) eq '95';
    return 1 if $self->_on_first_page;
    return 1 if $self->_on_last_page;
    return 0;
}

=head2 currentPage

    my $current_page = $wizard->currentPage()

This returns the index of the page currently being shown to the user.
Page are indexes start at 1, with the first page that is associated with
the wizard through the C<addPage> method.
See also the L</addPage> entry.

=cut

sub currentPage {
    my $self = shift;
    # Internally, the internal _current_page_idx is zero-based.  
    # But we "publish" it as one-based:
    return $self->{_current_page_idx} + 1;
}

=head2 setPageSkip

Mark one or more pages to be skipped at runtime.
All integer arguments are taken to be page numbers
(ie the number returned by any of the C<add*Page> methods)

You should never set the first page to be skipped, and
you can not set the last page to be skipped, though these
rules are not (yet) enforced.

=cut

sub setPageSkip {
    my $self = shift;
	# The user's argument is 1-based, but our internal data structures
	# are zero-based, thus subtract 1:
    foreach my $i (@_) {
        $self->{page_skip}{ $i - 1 } = 1;
    }
}

=head2 setPageUnskip

Mark one or more pages as not to be skipped at runtime
(that is, reverse the effects of C<setPageSkip>).

All integer arguments are taken to be page numbers
(that is, the number returned by any of the C<addPage> methods)

=cut

sub setPageUnskip {
    my $self = shift;
	# The user's argument is 1-based, but our internal data structures
	# are zero-based, thus subtract 1:
    foreach my $i (@_) {
        $self->{page_skip}{ $i - 1 } = 0;
    }
}

=head2 next_page_number

Returns the number of the page the Wizard will land on if the Next button is clicked
(ie the integer returned by C<add*Page>).

=cut

sub next_page_number {
    my $self  = shift;
	return $self->_next_page_number + 1;
}


# _next_page_number
# As public, but value is minus one
#
sub _next_page_number {
    my $self  = shift;
    my $i = $self->{_current_page_idx};
    DEBUG "_page_forward($i -->";

    do {
        $i++;
    } until (
		not $self->{page_skip}->{$i} or $self->_last_page <= $i
    );
    $i = $self->_last_page if ( $self->_last_page < $i );

    DEBUG " $i)\n";
    return $i;
}

# Increments the page pointer forward to the next logical page,
# honouring the Skip flags:
sub _page_forward {
    my $self = shift;
    $self->{_current_page_idx} = $self->_next_page_number;
}


=head2 back_page_number

Returns the number (ie the integer returned by add*Page) of the page
the Wizard will land on if the Back button is clicked.

=cut

# sub back_page_number {
#    my $self  = shift;
#    my $iPage = $self->{_current_page_idx};
#    do {
#        $iPage--;
#    } until ( !$self->{page_skip}{$iPage} || ( $iPage <= 0 ) );
#    $iPage = 0 if ( $iPage < 0 );
#    return $iPage;
# }

sub back_page_number {
	my $self = shift;
	return $self->_back_page_number + 1;
}

sub _back_page_number {
	my $self = shift;
    my $iPage = $self->{_current_page_idx};
    do {
        $iPage--;
    } until ( !$self->{page_skip}{$iPage} || ( $iPage <= 0 ) );
    $iPage = 0 if ( $iPage < 0 );
    return $iPage;
}


# Decrements the page pointer backward to the previous logical page,
# honouring the Skip flags:
sub _page_backward {
    my $self = shift;
    $self->{_current_page_idx} = $self->_back_page_number;
}

=head2 prompt

Equivalent to the JavaScript method of the same name: pops up
a dialogue box to get a text string, and returns it.  Arguments
are:

=over 4

=item -title =>

The title of the dialogue box.

=item -text =>

The text to display above the C<Entry> widget.

=item -value =>

The initial value of the C<Entry> box.

=item -wraplength =>

Text C<Label>'s wraplength: defaults to 275.

=item -width =>

The C<Entry> widget's width: defaults to 40.

=back

=cut

sub prompt {
    my $self = shift;
    my $args = {@_};
    my ( $d, $w );
    my $input = $self->cget( -value );
    $d = $self->DialogBox(
        -title => $args->{-title} || "Prompt",
        -buttons        => [ $LABELS{CANCEL}, $LABELS{OK} ],
        -default_button => $LABELS{OK},
    );

    if ( $args->{-text} ) {
        $w = $d->add(
            "Label",
            -font       => $self->{defaultFont},
            -text       => $args->{-text},
            -width      => 40,
            -wraplength => $args->{-wraplength} || 275,
            -justify    => 'left',
            -anchor     => 'w',
        )->pack();
    }

    $w = $d->add(
        "Entry",
        -font         => $self->{defaultFont},
        -relief       => "sunken",
        -width        => $args->{-width} || 40,
        -background   => "white",
        -justify      => 'left',
        -textvariable => \$input,
    )->pack(qw( -padx 2 -pady 2 -expand 1 ));

    $d->Show;
    return $input ? $input : undef;
}

#
# Using a -wait value for After of less than this seems to cause a weird Tk dump
# so call this whenever using a -wait
#
sub _fix_wait {
    my $wait_ref = shift;
    $$wait_ref += 200 if $$wait_ref < 250;
}

=head1 CALLBACKS

=head2 DIALOGUE_really_quit

This is the default callback for -preCloseWindowAction.
It gives the user a Yes/No dialog box; if the user clicks "Yes",
this function returns a false value, otherwise a true value.

=cut

sub DIALOGUE_really_quit {
    my $self = shift;
    TRACE "Enter DIALOGUE_really_quit";
    return 0 if $self->{nextButton}->cget( -text ) eq $LABELS{FINISH};

    unless ( $self->{really_quit} ) {
        DEBUG "# Get really quit info";
        my $button = $self->messageBox(
            '-icon'  => 'question',
            -type    => 'yesno',
            -default => 'no',
            -title   => 'Quit Wizard?',
            -message => "The Wizard has not finished running.\n\n"
            	. "If you quit now, the job will not be complete.\n\nDo you really wish to quit?"
        );
        $self->{really_quit} = lc $button eq 'yes' ? 1 : 0;
        DEBUG "# ... really=[$self->{really_quit}]";
    }
    return !$self->{really_quit};
}




=head1 ACTION EVENT HANDLERS

A Wizard is a series of pages that gather information and perform
tasks based upon that information. Navigated through the pages is via
I<Back> and I<Next> buttons, as well as I<Help>, I<Cancel> and
I<Finish> buttons.

In the C<Tk::Wizard> implementation, each button has associated with
it one or more action event handlers, supplied as code-references
executed before, during and/or after the button press.

The handler code should return a Boolean value, signifying whether the
remainder of the action should continue.  If a false value is
returned, execution of the event handler halts.

=over 4

=item -preNextButtonAction =>

This is a reference to a function that will be dispatched before the Next
button is processed.

=item -postNextButtonAction =>

This is a reference to a function that will be dispatched after the Next
button is processed. The function is called after the application has logically
advanced to the next page, but before the next page is drawn on screen.


=item -preBackButtonAction =>

This is a reference to a function that will be dispatched before the Previous
button is processed.

=item -postBackButtonAction =>

This is a reference to a function that will be dispatched after the Previous
button is processed.

=item -preHelpButtonAction =>

This is a reference to a function that will be dispatched before the Help
button is processed.

=item -helpButtonAction =>

This is a reference to a function that will be dispatched to handle the Help
button action.
By default there is no Help action; therefore unless you are providing this
function, you should initialize your Wizard with -nohelpbutton => 1.

=item -postHelpButtonAction =>

This is a reference to a function that will be dispatched after the Help
button is processed.

=item -preFinishButtonAction =>

This is a reference to a function that will be dispatched just before the Finish
button action.

=item -finishButtonAction =>

This is a reference to a function that will be dispatched to handle the Finish
button action.

=item -preCancelButtonAction =>

This is a reference to a function that will be dispatched before the Cancel
button is processed.  Default is to exit on user confirmation - see
L</DIALOGUE_really_quit>.

=item -preCloseWindowAction =>

This is a reference to a function that will be dispatched before the window
is issued a close command.
If this function returns a true value, the Wizard will close.
If this function returns a false value, the Wizard will stay on the current page.
Default is to exit on user confirmation - see L</DIALOGUE_really_quit>.

=back

All active event handlers can be set at construction or using configure --
see L</WIDGET-SPECIFIC OPTIONS> and L<Tk::options>.

=head1 BUTTONS

  backButton nextButton helpButton cancelButton

If you must, you can access the Wizard's button through the object
fields listed above, each of which represents a
L<Tk::Button|Tk::Button> object.  This may not be a good way to do it:
patches always welcome ;)

This is not advised for anything other than disabling or re-enabling the display
status of the buttons, as the C<-command> switch is used by the Wizard:

  $wizard->{backButton}->configure( -state => "disabled" )

Note: the I<Finish> button is simply the C<nextButton> with the label C<$LABEL{FINISH}>.

See also L<INTERNATIONALISATION>.

=head1 INTERNATIONALISATION

The labels of the buttons can be changed (perhaps into a language other an English)
by changing the values of the package-global C<%LABELS> hash, where keys are
C<BACK>, C<NEXT>, C<CANCEL>, C<HELP>, and C<FINISH>.

The text of the callbacks can also be changed via the
C<%LABELS> hash: see the top of the source code for details.

=head1 IMPLEMENTATION NOTES

This widget is implemented using the Tk 'standard' API as far as possible,
given that when I first needed a wizard in Perl/Tk, I had almost three weeks
of exposure to the technology.  Please, if you have a suggestion,
or patch, send it to me directly via C<LGoddard@CPAN.org>, or via CPAN's RT.

The widget supports both C<MainWindow> and not C<TopLevel> window.
Originally, only the former was supported - the reasoning was that
Wizards are applications in their own right, and not usually parts of other
applications. However, conventions are not always bad things, hence the update.

=head1 THE C<Tk::Wizard> NAMESPACE

In discussion on comp.lang.perl.tk, it was suggested by Dominique Dumont
that the following guidelines for the use of the C<Tk::Wizard> namespace be followed:

=over 4

=item 1

That the module C<Tk::Wizard> act as a base module, providing all the
basic services and components a Wizard might require.

=item 2

That modules beneath the base in the hierarchy provide implementations
based on aesthetics and/or architecture.

=back

=head1 NOTES ON SUB-CLASSING Tk::Wizard

If you are planning to sub-class C<Tk::Wizard> to create a different display style,
there are three routines you will need to over-ride:

=over 4

=item _initial_layout

=item _render_current_page

=item blank_frame

=back

This may change, please bear with me.

=head1 CAVEATS

=over 4

=item *

Bit messy when composing frames.

=item *

Task Frame LabFrame background colour doesn't set properly under 5.6.1.

=item *

20 January 2003: the directory tree part does not create directories
unless the eponymous button is clicked. Is this still an issue?

=item *

In Windows, with the system font set to > 96 DPI (via Display Properties / Settings
/ Advanced / General / Display / Font Size), the Wizard will not display pro pertly.
This seems to be a Tk feature.

=item *

Nothing is currently done to ensure text fits into the window - it is currently up to
the client to make frames C<Scrolled>) as required.

=back

=head1 BUGS

Please use RT (https://rt.cpan.org/Ticket/Create.html?Queue=Tk-Wizard)
to submit a bug report.

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org) based on work by Daniel T Hable.

Please see the F<README.md> file for a list of contributors and helpers - thanks to all.

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI.

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 11/2002 - 02/2010, 06/2015 ff.

This software is made available under the same terms as Perl itself.

This software is not endorsed by, or in any way associated with,  the Microsoft Corp

Microsoft is, obviously, a registered trademark of Microsoft Corp.

=cut

REDEFINES:
{
    no warnings 'redefine';
    sub Tk::ErrorOFF {
        DEBUG "This is Martin's Tk::Error\n";
        my ( $oWidget, $sError, @asLocations ) = @_;
        local $, = "\n";
        print STDERR @asLocations;
    }
}

1;

__END__


