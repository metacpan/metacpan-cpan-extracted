use strict;
use warnings;

package Tk::Wizard::Installer::Win32;
use warnings::register;
our $VERSION = 2.22;

=head1 NAME

Tk::Wizard::Installer::Win32 - Win32-specific routines for Tk::Wizard::Installer

=cut


use lib "../../../"; # dev
use Carp ();
use Cwd;
use File::Path;
use Exporter;
use Tk::Wizard ':use' => 'FileSystem';
use base 'Tk::Wizard::Installer';

use vars '@EXPORT';
@EXPORT = ("MainLoop");

use constant DEBUG_FRAME => 0;

# use Log4perl if we have it, otherwise stub:
# See Log::Log4perl::FAQ
BEGIN {
	eval { require Log::Log4perl; };
	if($@) {
		no strict qw"refs";
		*{__PACKAGE__."::$_"} = sub { } for qw(TRACE DEBUG INFO WARN ERROR FATAL);
	} else {
		no warnings;
		no strict qw"refs";
		require Log::Log4perl::Level;
		Log::Log4perl::Level->import(__PACKAGE__);
		Log::Log4perl->import(":easy");
		if ($Log::Log4perl::VERSION < 1.11){
			*{__PACKAGE__."::TRACE"} = *DEBUG;
		}
	}

    use Win32::Shortcut;
    require Win32;
    if ( $Win32::VERSION lt 0.2 ) {
        eval 'use Win32::OLE';    # autouse is still not very good?
        die "Could not load Win32::OLE: $@" if $@;
    }
    eval {
    	use Win32;
    	use Win32::TieRegistry( Delimiter => "/", ArrayValues => 0 );
	};
	die $@ if $@;
}


=head1 DESCRIPTION

As a sub-class of L<Tk::Wizard|Tk::Wizard> and
L<Tk::Wizard::Installer|Tk::Wizard::Installer>, this module offers
all of those methods and means, plus the below, which
are thought to be specific to the Microsoft Windows platform.

If you are looking for a freeware software installer that is not
dependant upon Perl, try Inno Setup - C<http://www.jrsoftware.org/>. It's
so good, even Microsoft have been caught using it.

If you are looking for a means to update the Windows C<Path> variable,
have a look for I<PathTool.exe>, a tiny Windows 32-bit executable
by Luke Bailey (C<luke@notts.flexeprint.com>). This tool can also be
used to add new, persistant environment variables to the system.

=head1 METHODS

=head2 register_with_windows

Registers an application with Windows so that it can be "uninstalled"
using the I<Control Panel>'s I<Add/Remove Programs> dialogue.

An entry is created in the Windows' registry pointing to the
uninstall script path. See C<UninstallString>, below.

Returns C<undef> on failure, C<1> on success.
Does nothing on non-MSWin32 platforms

Aguments are:

=over 4

=item uninstall_key_name

The name of the registery sub-key to be used. This is transparent to the
end-user, but should be unique for all applications.

=item UninstallString

The command-line to execute to uninstall the script.

According to Microsoft at L<http://msdn.microsoft.com/library/default.asp?url=/library/en-us/dnwue/html/ch11d.asp>:

"You must supply complete names for both the DisplayName and UninstallString
values for your uninstall program to appear in the Add/Remove Programs
utility. The path you supply to Uninstall-String must be the complete
command line used to carry out your uninstall program. The command line you
supply should carry out the uninstall program directly rather than from a
batch file or subprocess."

The default value is:

	perl -e '$args->{app_path} -u'

This default assumes you have set the argument C<app_path>, and that it
checks and reacts to the the command line switch C<-u>:

	package MyInstaller;
	use strict;
	use Tk::Wizard;
	if ($ARGV[0] =~ /^-*u$/i){
		# ... Have been passed the uninstall switch: uninstall myself now ...
	}

Or something like that.

=item QuietUninstallString

As C<UninstallString> above, but for ... quiet uninstalls.

=item app_path

Please see the entry for C<UninstallString>, above.

=item DisplayName

=item DisplayVersion

=item Size

The strings displayed in the Control Panel's Add/Remove Programs list.

=item ModifyPath

=item NoRepair NoModify NoRemove

=item EstimatedSize InstallSorce InstallDate InstallLocation

=item AthorizedCDFPrefix Language ProductID

Unknown

=item Comments

=item RegOwner

=item RegCompnay

=item Contact

=item HelpTelephone

=item Publisher

=item URLUpdateInfo

=item URLInfoAbout

=item HelpLink

These are all displayed when the Support Information link
is clicked in the Add/Remove Programs dialogue. The last
should be full URIs.

=back

The routine will also try to add any other parameters to the
registry tree in the current location: YMMV.

=cut

sub register_with_windows {
    my ( $self, $args ) = ( shift, {@_} );
    return 1 if $^O !~ /mswin32/i;

    unless ($args->{DisplayName}
        and $args->{UninstallString}
        and ( $args->{uninstall_key_name} or $args->{app_path} ) ){
        die __PACKAGE__
          . "::register_with_windows requires an argument of name/value pairs which must include the keys 'UninstallString', 'uninstall_key_name' and 'DisplayName'";
    }

    if ( not $args->{UninstallString} and not $args->{app_path} ) {
        die __PACKAGE__ . "::register_with_windows requires either argument 'app_path' or 'UninstallString' be set.";
    }

    if ( $args->{app_path} ) {
        $args->{app_path} = "perl -e '$args->{app_path} -u'";
    }
    my $uninst_key_ref =
      $Registry->{'LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/'}->CreateKey(
		  $args->{uninstall_key_name}
	);
    Carp::confess "Perl Win32::TieRegistry error" if !$uninst_key_ref;

    foreach my $i ( keys %$args ) {
        next if $i =~ /^(app_path|uninstall_key_name)$/g;
        $uninst_key_ref->{"/$i"} = $args->{$i};
    }

    return 1;
}

=head2 addStartMenuPage

Adds a page that allows
users to select a location on the Windows "Start Menu",
perhaps to add a shortcut there.

This routine does not currently create the directory in the
I<Start Menu>, nor does it place a link there - see
L</callback_create_shortcut> for that. Rather, the
caller supplies a C<-variable> parameter that is a reference
to a scalar which, once the page is 'run', will contain
either the path to the user's chosen directory, or C<undef>
if the option to not select was chosen.

In addition, when the page is 'run', it places the path to the
current user's I<Start Menu/Programs> directory into the object
field C<startmenu_dir_current>, and the path to the common
I<Start Menu/Programs> in the object field C<startmenu_dir_common>.

The physical creation of the shortcut is left as an exercise to the reader.
Have a look at the C<$mkdir> C<Button> in C<Tk::Wizard/page_dirSelect>.

=over 4

=item -user

Set to C<all> or C<current> to list the "Start Menu" for all users, or
just the current user.  Default is C<all>.  Note that in the current
versions of Windows in common use, if there exist entries with the
same name in both the common and current user's I<Start Menu>, the
entry in the common menu takes precedence.

=item -variable

A reference to a variable that, when the page is completed,
will contain the directory the user has chosen to create an item in. Note
this is I<not> the full path: see above.

=item -program_group

Name of the directory to create on the start menu, if any.  If
defined, this will be appended to any selection the user makes.  Note
that since addStartMenuPage() is just the GUI part, no directory will
actually be created until C</callback_create_shortcut> is called.

=item -disable_nochoice

Set to prevent the display of the checkbox which allows the user not
to use this feature.  See C<-label_nochoice>, below.

=item -label_nochoice

If the parameter C<-disable_nochoice> has not been set,
C<-label_nochoice> should contain text to use for the label by the
checkbox which disables choices on
this page and causes the page to set the C<-variable> parameter to
C<undef>.
Default text is C<Do not create a shortcut on the Start Menu>.

=item -listHeight

Height of the list box, default is C<10> but you may
vary this if your C<-text> attribute takes up more or less much room.

=back

Accepts the Standard Options that are common to the C<HList> and
C<Label> widgets, but does not accept aliases:

	-relief -highlightthickness -background -borderwidth -cursor
	-highlightcolor -foreground -font

You can supply the common Tk::Wizard options:

	-title -subtitle -text

This method will initially attempt to use F<Win32.pm>; failing that,
it will attempt to use a Windows Scripting Host object created via
L<Win32::OLE|Win32::OLE>.  If both fail (WSH only existing by default
in Win98 and above), the routine will return C<undef>, rather than a
page frame object.  This may not be ideal but works for me --
suggestions welcomed for a better idea.

=cut

sub addStartMenuPage {
    my ( $self, $args ) = ( shift, {@_} );
    # return $self->addPage( sub { $self->_page_start_menu($args) } );
	my %btn_args =
		map { my $x = delete $args->{$_}; $_ => $x }
		grep { /ButtonAction$/ }
		keys %$args;
	return $self->addPage( sub { $self->_page_start_menu($args) }, %btn_args );
}

sub _page_start_menu {
    local *DIR;
    my ($self) = (shift);
    my $args;
    if ( ref $_[0] eq 'HASH' ) {
        $args = shift;
    }
    else {
        $args = {@_};
    }
    my $cwd    = cwd;
    my $do_set = 1;

    Carp::croak "You must set -variable parameter"if not exists $args->{-variable};

    $args->{-user} ||= 'common';
    $args->{-background} = 'white'  unless exists $args->{-background};
    $args->{-relief}     = 'sunken' unless exists $args->{-relief};
    $args->{-border}     = 1        unless exists $args->{-border};
    $args->{-listHeight} = 10       unless exists $args->{-listHeight};
    $args->{-title}    ||= "Create Shortcuts";
    $args->{-subtitle} ||= "Please select where to place an icon on the start menu";

    $args->{-text}     ||= "
If you want the new Program Group to be installed within an existing
folder in your Start Menu, select that folder below.
If you do not want to install the new Program in your Start Folder,
check the checkbox below.";

    $args->{-label_nochoice} ||= "Do not create a shortcut on the Start Menu";
    $self->{-program_group} = $args->{-program_group};

    my $common_formatting = {};

    $common_formatting->{-background} = $args->{-background}
      if exists $args->{-background};

    $common_formatting->{-relief} = $args->{-relief} if exists $args->{-relief};

    $common_formatting->{-highlightthickness} = $args->{-highlightthickness}
      if exists $args->{-highlightthickness};

    $common_formatting->{-borderwidth} = $args->{-borderwidth}
      if exists $args->{-borderwidth};

    $common_formatting->{-cursor} = $args->{-cursor} if exists $args->{-cursor};

    $common_formatting->{-highlightcolor} = $args->{-highlightcolor}
      if exists $args->{-highlightcolor};

    $common_formatting->{-foreground} = $args->{-foreground}
      if exists $args->{-foreground};

    $common_formatting->{-font} = $args->{-font} if exists $args->{-font};

    # Don't pass these to other modules
    my $variable = $args->{-variable};
    delete $args->{-variable};
    my $group = $args->{-program_group};
    delete $args->{-program_group};

    my $frame = $self->blank_frame(%$args);
    DEBUG_FRAME && $frame->configure( -background => 'blue' );

    if ( $Win32::VERSION gt 0.1999999 ) {
        $self->{startmenu_dir_current} = eval('Win32::GetFolderPath(Win32::CSIDL_STARTMENU)') . '\Programs';
        $self->{startmenu_dir_common}  = eval('Win32::GetFolderPath(Win32::CSIDL_COMMON_STARTMENU)') . '\Programs';
    }

    # The above may not work if non-standard/non-English setup, so:
    if (   not $self->{startmenu_dir_current}
        or not $self->{startmenu_dir_common} ) {
        my $WshShell = eval 'Win32::OLE->CreateObject("WScript.Shell")';
        if ( ref $WshShell eq 'Win32::OLE' ) {
            $self->{startmenu_dir_current} = $WshShell->SpecialFolders(17);
            $self->{startmenu_dir_common}  = $WshShell->SpecialFolders(2);
        }
        else {
            warn "Could not find special folders using Win32 or OLE!";
            return undef;
        }
    }

    # The default is to install for all users:
    my $dir_parent = $self->{startmenu_dir_common};
    if ( $args->{-user} eq 'current' ) {
        $dir_parent = $self->{startmenu_dir_current};
    }

    # This is the default answer, if the user just clicks "Next":
    $$variable = "$dir_parent\\$group";

    # Recursively read the Start Menu folder, building up a list of
    # all folders in there:
    my @asTry = ($dir_parent);
    my @asDir;

  	TRY_DIR:
    while (@asTry) {
		local $" = ',';

        # $sTry is the FULL path of this folder:
        my $sTry = shift @asTry;
        next TRY_DIR if !-d $sTry;
        push @asDir, $sTry;
        opendir DIR, $sTry
          or Carp::croak "Can not open the start menu ($sTry): $!";
        my @asTryChildren = sort readdir DIR;

        push @asTry, grep { !m/^\.\.?$/ && s/^(.*)$/$sTry\\$1/ && -d } @asTryChildren;
        closedir DIR or warn $!;
    }

    my $text = $frame->Label(
        -justify      => 'left',
        -textvariable => $variable,
        -anchor       => 'w',
        %$common_formatting,
      )->pack(
        -side   => 'top',
        -anchor => 'w',
        -fill   => 'x',
        -padx   => 10,
      );

    $text->configure( -background => 'magenta' ) if DEBUG_FRAME;

    my $hlist = $frame->Scrolled(
		'HList',
		-scrollbars => "osoe",
		-selectmode => 'single',
		-height     => $args->{-listHeight},
		-itemtype   => 'text',
		-separator  => '\\',
		-browsecmd  => sub {
			$$variable = shift;
			$$variable .= "\\" . $group if $group;
        },
        %$common_formatting,
	)->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 10,
        -pady   => 5,
	);
    $hlist->configure( -background => 'yellow' ) if DEBUG_FRAME;

    foreach my $i (@asDir) {
        my $t = $i;
        $t =~ s!\Q$dir_parent!!;
        $t =~ s!\A\\!!;
        if ( !$hlist->info( "exists", $t ) ) {

            DEBUG "trying to add i=$i= t=$t= to hlist...\n";
            $hlist->add(
                 $t,
                -text => $t,
                -data => $i,
            );
        }
    }

    $self->{_hlist_active_} = 0;
    $self->_toggle_hlist( $hlist, $variable, $group );
    if ( !$args->{-disable_nochoice} ) {
        my $b = $frame->Checkbutton(
            -text    => $args->{-label_nochoice},
            -anchor  => 'w',
            -command => [ \&_toggle_hlist, $self, $hlist, $variable, $group ],
          )->pack(
            -side   => 'left',
            -anchor => 'w',
            -padx   => 10,
            -pady   => 5,
          );
        $b->configure( -background => 'red' ) if DEBUG_FRAME;
    }

    return $frame;
}


sub _toggle_hlist {
    my $self = shift;

    # Required arg1 = the Scrolled HList widget:
    my $hlist = shift || return;

    # Required arg2 = reference to variable that HList is bound to:
    my $rs = shift || return;

    # Optional arg3 = the group string being added onto the path:
    my $group = shift;
    $self->{_hlist_active_} = !$self->{_hlist_active_};

    my $w = $hlist->Subwidget('scrolled');
    if ( !$self->{_hlist_active_} ) {
        $$rs = '';
        # Deactivate the entire HList.  HList does not support the
        # -state configuration option, therefore we use the bindtags
        # "hack":
        $self->{_hlist_bindtags_} = $w->bindtags;
        $w->bindtags( ['Freeze'] );
    }

    else {
        $$rs = $hlist->info('anchor');
        $$rs .= "\\" . $group if $group;
        if ( $self->{_hlist_bindtags_} ) {
            $w->bindtags( $self->{_hlist_bindtags_} );
        }
    }
}


=head1 CALLBACKS

=head2 callback_create_shortcut

A convenience interface to L<Win32::Shortcut|Win32::Shortcut> method
that creates a shortcut at the path specified.  Parameters are pretty
much what you see when you right-click a shortcut:

=over 4

=item -save_path

The location at which the shortcut should be saved.  This should be
the full path including filename ending in C<.lnk>.

The filename minus extension will be visible in the shortcut.
If the C<-program_group> parameter was passed to
C<METHOD page_start_menu>, the directory it refers to
will be included in the save path you supply.  To avoid
this, either C<undef>ine the object field C<-program_group>,
or supply the parameter C<-no_program_group>.

=item -no_program_group>

See C<-save_path>, above.

=item -target

The shortcut points to this file, directory, or URI -- see notes for
C<-save_path>, above.

=item -workingdir

The working directory for the C<-target>, above.

=item -description

This is what you see when you mouse-over a shortcut
in more "modern" (Win2k/ME+) Windows.

=item -iconpath

Path to the icon file -- an C<.exe>, C<.dll>, C<.ico> or
other acceptable format.

=item -iconindex

Index of the icon in the file if a C<.exe> or C<.dll>.

=item -arguments

Um... it's the second parameter in Win32::Shortcut::Set -
could well be parameters for the target, but I'm too much of
a rush to check. XXX

=item -show

Whether the C<-target>, above, should be
started maximized or minimized. Acceptable values are
the constants:

    SW_SHOWMAXIMIZED SW_SHOWMINNOACTIVE SW_SHOWNORMAL

=item -hotkey

Key combination to activate the shortcut. Probably looks
something like C<ctrl+t>.

=back

On success, returns the C<-save_path>; on failure, C<undef>.

=cut

sub callback_create_shortcut {
    my ( $self, $args ) = ( shift, {@_} );
    Carp::croak "-target is required (you gave " . ( join ", ", keys %$args ) . ")"
      unless defined $args->{-target} and $args->{-target} ne '';

    Carp::croak "-save_path is required  (you gave " . ( join ", ", keys %$args ) . ")"
      unless defined $args->{-save_path} and $args->{-save_path} ne '';

    $args->{-arguments}   = '' unless exists $args->{-arguments};
    $args->{-workingdir}  = '' unless exists $args->{-workingdir};
    $args->{-description} = '' unless exists $args->{-description};
    $args->{-show}        = 0  unless exists $args->{-show};
    $args->{-hotkey}      = 0  if not exists $args->{-hotkey} or $args->{-hotkey} eq '';
    $args->{-iconpath}    = 0  unless exists $args->{-iconpath};
    $args->{-iconindex}   = 0  unless exists $args->{-iconindex};
    delete $self->{-program_group} if exists $args->{-no_program_group};

    if (    exists $self->{-program_group}
        and exists $args->{-save_path} ) {
        my ( $base, $file ) = $args->{-save_path} =~ /(.*?)([^\/\\]+)$/;

        # Historical error on $self->{-program_groups}
        $base .= "\\" . ($self->{-program_groups} || $self->{-program_group});

        mkpath $base if !-e $base;
        $args->{-save_path} = $base . "\\" . $file;
        $args->{-save_path} =~ s/[\\\/]+/\\/g;
    }

    if (    $args->{-target} =~ /^(ht|f)tp:\/\//
        and $args->{-save_path} !~ /\.uri$/i ) {
        Carp::croak "Internet shortcuts require a .uri ending!";
    }

    if (    $args->{-target} !~ /^(ht|f)tp:\/\//
        and $args->{-save_path} =~ /\.uri$/i ) {
        Carp::croak "Only internet shortcuts require a .uri ending!";
    }

    my $s = Win32::Shortcut->new;
    $s->Set(
        $args->{-target},
        $args->{-arguments},
        $args->{-workingdir},
        $args->{-description},
        $args->{-show},
        $args->{-hotkey},
        $args->{-iconpath},
        $args->{-iconindex},
    );
    my $r = $s->Save(
		$args->{-save_path}
	) ?
		$args->{-save_path} : undef;

    $s->Close;

    return $r;
}


=head2 callback_create_shortcuts

Convenience method to create multiple shortcuts at once.
Supply an array of hashes, each hash being arguments
to supply to C<callback_create_shortcut>.

Returns an array or reference to an array that contains
the reults of the shortcut creation.

See L<callback_create_shortcut>.

=cut

sub callback_create_shortcuts {
    my $self = shift;
    my @paths;
    foreach (@_) {
        Carp::confess "Not a hash reference" unless ref $_ eq 'HASH';
        $self->callback_create_shortcut(%$_);
    }
    return wantarray ? @paths : \@paths;
}


sub Tk::Error::RedefineIfNeeded {
    local $\ = "\n";
    print STDERR @_;
}

1;

__END__

=head1 CAVEATS AND BUGS

* Error going backwards into a C<addStartMenuPage>.

=head1 CHANGES

Please see the file F<Changes> included with the distribution.

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org).

=head1 SEE ALSO

L<Tk::Wizard>; L<Tk::Wizard::Installer>;
L<Win32/GetFolderPath>;
L<Win32::Shortcut>;
L<Win32::OLE>.

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI; windows; win32; registry; shortcut;

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org).

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 11/2002 - 01/2008, 06/2015 ff.

Made available under the same terms as Perl itself.
