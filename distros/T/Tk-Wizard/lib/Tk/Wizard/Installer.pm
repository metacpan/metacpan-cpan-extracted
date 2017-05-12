package Tk::Wizard::Installer;

use strict;
use warnings;
use warnings::register;

our $VERSION = 2.41;

=head1 NAME

Tk::Wizard::Installer - Building-blocks for a software install wizard

=head1 SYNOPSIS

    use Tk::Wizard::Installer;
    my $wizard = new Tk::Wizard::Installer( -title => "Installer Test", );
    $wizard->addDownloadPage(
        -no_retry => 1,
        -files  => {
            'http://www.cpan.org/' => './cpan_index1.html',
        },
    );
    $wizard->addPage( sub {
        return $wizard->blank_frame(
            -title=>"Finished",
            -subtitle => "Please press Finish to leave the Wizard.",
            -text => ""
        );
    });
    $wizard->Show;
    MainLoop;

=cut

use lib '../../'; # dev
use Carp;
use Cwd;
use Data::Dumper;
use FileHandle;
use File::Path;
use File::Copy;
use File::Spec;
use Tk;
use Tk::ErrorDialog;
use Tk::LabFrame;
use Tk::ProgressBar;
use Tk::Wizard ':use' => 'FileSystem';

# For uninstaller
use Fcntl;   # For O_RDWR, O_CREAT, etc.
#  use Fcntl ':flock';
use SDBM_File;

# use Log4perl if we have it, otherwise stub:
# See Log::Log4perl::FAQ
BEGIN {
	eval { require Log::Log4perl; };

	# No Log4perl so bluff: see Log4perl FAQ
	if ($@) {
		no strict qw"refs";
		*{__PACKAGE__."::$_"} = sub { } for qw(TRACE DEBUG INFO WARN ERROR FATAL);
        *{__PACKAGE__."::LOGCROAK"} = *Carp::croak;
        *{__PACKAGE__."::LOGCONFESS"} = *Carp::confess;
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
	}
}

use Exporter;
use vars qw/ @EXPORT /;

use base "Tk::Wizard";
@EXPORT = ("MainLoop");

use constant DEBUG_FUNC => 0;

# See INTERNATIONALISATION
my %LABELS = (

	# Buttons
    BACK   => "< Back",
    NEXT   => "Next >",
    FINISH => "Finish",
    CANCEL => "Cancel",
    HELP   => "Help",
    OK     => "OK",

    # licence agreement
    LICENCE_ALERT_TITLE => "Licence Condition",
    LICENCE_OPTION_NO   => "I do not accept the terms of the licence agreement",
    LICENCE_OPTION_YES  => "I accept the terms of the licence agreement",
    LICENCE_IGNORED => "You must read and agree to the licence before you can use this software.\n\nIf you do not agree to the terms of the licence, you must remove the software from your machine.",
    LICENCE_DISAGREED => "You must read and agree to the licence before you can use this software.\n\nAs you indicated that you do not agree to the terms of the licence, please remove the software from your machine.\n\nSetup will now exit.",

    # FileList
    # - supplied as args: see POD for those sections
);


=head1 DESCRIPTION

This module makes the first moves towards a C<Tk::Wizard> extension
to automate software installation, primarily for end-users, in the manner
of I<InstallShield>.

If you are looking for a freeware software installer that is not
dependent upon Perl, try I<Inno Setup> - C<http://www.jrsoftware.org/>. It's
so good, even Microsoft have been caught using it.

=head1 METHODS

C<Tk::Wizard::Installer> supports all the methods and means of L<Tk::Wizard|Tk::Wizard>
plus those listed in the remainder of this document.

=head2 addLicencePage

    $wizard->addLicencePage ( -filepath => $path_to_licence_text )

Adds a page (a L<Tk::Frame|Tk::Frame>) that contains a scroll text box
of a licence text file specified in the C<-filepath> argument.
Presents the user with two options: accept, or don't accept.  The user
I<cannot> progress until the former option has been chosen.  The
choice is entered into the object field C<licence_agree>, which is
automatically tested when the I<Next> button is pressed, or with the 
Wizard's C<callback_licence_agreement> function. You can over-ride
this last action by providing your own C<-preNextButtonAction> callback.

=cut

sub addLicencePage {
    my ( $self, $args ) = ( shift, {@_} );
    Carp::croak "No -filepath argument present" if not $args->{-filepath};
	my %btn_args =
		map { my $x = delete $args->{$_}; $_ => $x }
		grep { /ButtonAction$/ }
		keys %$args;
	return $self->addPage( 
        sub { $self->_page_licence_agreement($args) }, 
        %btn_args,
        ( 
          $args->{'-preNextButtonAction'}
          ?  (-preNextButtonAction => sub { $self->callback_licence_agreement(@_); } )
          : ()
        )
    );
}


# PRIVATE METHOD _page_licence_agreement
#
# Returns a C<Tk::Wizard> page entitled "End-user Licence Agreement",
# a scroll-box of the licence text, and an "Agree" and "Disagree"
# option. If the user agrees, the caller's package's global (yuck)
# C<$LICENCE_AGREE> is set to a Boolean true value.
#
# See also L</callback_licence_agreement>.

sub _page_licence_agreement {
    my ( $self, $args ) = ( shift, shift );

    my $padx = $self->cget( -style ) eq 'top' ? 30 : 5;
    $self->{licence_agree} = undef;
    my $fname = $args->{-filepath};

	my $text;
	open my $in, $fname or LOGCROAK "Could not read licence from $fname: $!";
	read $in, $text, -s $in;
	close $in;
	warn "Licence file $fname is empty!" if not length $text;

    # Clean up line endings because Tk::ROText on *NIX displays them:
    $text =~ s![\r\n]+!\n!g;
    my ( $frame, @pl ) = $self->blank_frame(
        -title    => "End-user Licence Agreement",
        -subtitle => "Please read the following licence agreement carefully.",
    );
    my $t = $frame->Scrolled(
        'ROText',
        -relief      => 'sunken',
        -borderwidth => 2,
        -font        => 'SMALL_FONT',
        -width       => 10,
        -setgrid     => 'true',
        -height      => 9,
        -scrollbars  => 'e',
        -wrap        => 'word',
    );
    $t->insert( '0.0', $text );
    $t->configure( -state => "disabled" );
    $t->pack(qw/-expand 1 -fill both -padx 10 -pady 10/);
    my %opts1 = (
        -font     => $self->{defaultFont},
        -text     => $LABELS{LICENCE_OPTION_YES},
        -variable => \${ $self->{licence_agree} },
        -relief   => 'flat',
        -value    => 1,
        -anchor   => 'w',
    );

    # Setting -background to undef causes core dump deep inside Tk!
    $opts1{-background} = $self->cget("-background")
      if $self->cget("-background");
    $opts1{-underline} = 2;    # Third character is the "A" of "Accept"
    $self->bind( '<Alt-a>' => sub { ${ $self->{licence_agree} } = 1 } );
    my $buttonAccept = $frame->Radiobutton(%opts1)->pack( -padx => $padx, -anchor => 'w', );

    my %opts2 = (
        -font     => $self->{defaultFont},
        -text     => $LABELS{LICENCE_OPTION_NO},
        -variable => \${ $self->{licence_agree} },
        -relief   => 'flat',
        -value    => 0,
        -anchor   => 'w',
    );
    # Setting -background to undef causes core dump deep inside Tk!
    $opts2{-background} = $self->cget("-background")
      if $self->cget("-background");
    $opts2{-underline} = 5;    # 6th character = 'N' of 'Not'
    $self->bind( '<Alt-n>' => sub { ${ $self->{licence_agree} } = 0 } );
    $frame->Radiobutton(%opts2)->pack( -padx => $padx, -anchor => 'w', );

    if ( $args->{-wait} ) {
        Tk::Wizard::_fix_wait( \$args->{-wait} );

        # $frame->after($args->{-wait},sub{$self->forward});
        $frame->after(
            $args->{-wait},
            sub {
                $self->{nextButton}->configure( -state => 'normal' );
                $self->{nextButton}->invoke;
            }
        );
    }
    return $frame;
}


=head2 addFileListPage

  $wizard->addFileListPage ( name1=>value1 ... nameN=>valueN )

Adds a page (a L<Tk::Frame|Tk::Frame>) that contains a progress bar
(L<Tk::ProgressBar|Tk::ProgressBar>) which is updated as a supplied
list of files is copied or moved from one location to another.

The I<Next> and I<Back> buttons of the Wizard are disabled whilst
the process takes place.

The two arguments (below) C<-to> and C<-from> should be references
to arrays (or anonymous arrays), where entries in the former are
moved or copied to the locations specified to the equivalent
entries in the latter, renaming and path creation occurring as needed:

  -copy => 1,
  -from   => [
    '/html/index.html',
    '/html/imgs/index.gif',
    '/html/oldname.html'
    ],
  -to => [
    '/docs/',
    '/docs/imgs/',
    '/html/newname.html'
    ],

The above example
copies C<index.html> to C</docs/index.html>, C<index.gif> is copied to
become C</docs/imgs/index.gif>, and C<oldname.html> is copied to
C<newname.html> in the same C<html> directory.

Arguments:

=over 4

=item -title

=item -subtitle

=item -text

See L<Tk::Wizard/blank_frame>.

=item -copy

=item -move

Setting one or the other will determine whether files are copied (without deletion of originals)
or moved (with deletion of originals). The default action is the former.

=item -from

Reference to an array of locations to copy/move from

=item -to

Reference to an array of locations to move/copy to

=item -delay

Delay (in mS) before copying begins (see L<Tk::after>).  Default is 1000.

=item -wait

Prevents display of the next Wizard page once the job is done.

=item -bar

A list of properties to pass to the L<Tk::ProgessBar|Tk::ProgessBar>
object created and used in this routine.  Assumes reasonable defaults.

=item -label_frame_title

Text for the label frame (L<Tk::LabFrame|Tk::LabFrame> object) which
contains our moving parts.  Defaults to C<Copying Files>.

=item -label_preparing

Text for label displayed whilst counting files to be copied.
Defaults to C<Preparing...>.

=item -label_from

The text of the label prepended to the name of the directory being copied.
Defaults to C<From:>.

=item -label_file

The text of the label prepended to the name of the file being copied.
Defaults to C<Copying:>.

=item -on_error

A code reference to handle errors, which are detailed in the anonymous hash C<-failed>,
where names are filenames and values are the error messages.
If not supplied, calls L</pre_install_files_quit>.

=item -uninstall_db

Path at which to store an uninstall database file for use with
L<addUninstallPage|addUninstallPage>. This path will be used
to create two files, one with a C<dir> extension and one
with a C<pag> extension.

=item -uninstall_db_perms

If you supply C<-uninstall_db> to create an uninstaller,
you may use this argument to provide a file permissions
for the db files; otherwise, the default is C<0666>.
Please see the notes in C<SDBM_File> that explain why
C<0666> is a good choice.

=back

=cut

# Internally (as private as it gets in Perl):
#
# =item -bar
#
# Confusingly, a progressBar object to update
#
# =item -labelFrom
#
# Label object to update
#
# =item -labelTo
#
# Label object to update
#
sub addFileListPage {
    my ( $self, $args ) = ( shift, {@_} );
    # $self->addPage( sub { $self->_page_filelist($args) } );
	my %btn_args =
		map { my $x = delete $args->{$_}; $_ => $x }
		grep { /ButtonAction$/ }
		keys %$args;
	return $self->addPage( sub { $self->_page_filelist($args) }, %btn_args );
}

=head2 addFileCopyPage

Alias for L<addFileListPage|addFileListPage>.

=cut

sub addFileCopyPage {
	my $self = shift;
	$self->addFileListPage(@_);
}

sub _page_filelist {
    my ( $self, $args ) = ( shift, shift );

    Carp::croak "Arguments should be supplied as a hash ref"
      if not ref $args or ref $args ne "HASH";
    Carp::croak "-from and -to are required"
      if not $args->{-from} or not $args->{-to};
    Carp::croak "-from and -to are different lengths"
      if $#{ $args->{-from} } != $#{ $args->{-to} };
    Carp::croak "Nothing to do! -from and -to are empty"
      if $#{ $args->{-from} } == -1 or $#{ $args->{-to} } == -1;

	# Uninstaller
	if (exists $args->{-uninstall_db}){
		DEBUG "Setting-up uninstall SDBM";
		$self->{_uninstall_db_path} = $args->{-uninstall_db};
		$self->{_uninstall_db} = {};
		tie(
			%{$self->{_uninstall_db}},
			'SDBM_File',
			$self->{_uninstall_db_path},
			O_WRONLY | O_CREAT,
			$args->{-uninstall_db_perms} || 0666,
		) or die "Could not create uninstaller db file - failed to tie `SDBM file '$self->{_uninstall_db_path}': $!; aborting";
	}

    my $frame = $self->blank_frame(
        -title    => $args->{-title}    || "Copying Files",
        -subtitle => $args->{-subtitle} || "Please wait whilst Setup copies files to your computer.",
        -text     => $args->{-text}     || "\n"
    );

    my %bar;    # progress bar args
    if ( $args->{-bar} ) {
        %bar = @{ $args->{-bar} };

        # insert error checking here...
    }
    $bar{-gap}    = 0 unless defined $bar{-gap};
    $bar{-blocks} = 0 unless defined $bar{-blocks};
    $bar{-colors}      = [ 0 => 'blue' ] unless $bar{-colors};
    $bar{-borderwidth} = 2               unless $bar{-borderwidth};
    $bar{-relief}      = 'sunken'        unless $bar{-relief};
    $bar{-from}        = 0               unless $bar{-from};
    $bar{-to}          = 100             unless $bar{-to};

    my $f = $frame->LabFrame(
        -label => $args->{-label_frame_title} || "Copying files",
        -labelside => "acrosstop"
    );
    $args->{-labelFrom} = $f->Label(qw//)->pack(qw/-padx 16 -side top -anchor w/);
    $args->{-labelTo}   = $f->Label(qw//)->pack(qw/-padx 16 -side top -anchor w/);
    $self->{-bar}       = $f->ProgressBar(%bar)->pack(qw/ -padx 20 -pady 10 -side top -anchor w -fill both -expand 1 /);
    $f->pack(qw/-fill x -padx 30/);

    $self->{nextButton}->configure( -state => "disable" );
    $self->{backButton}->configure( -state => "disable" );

    $self->{-bar}->after(
        $args->{-delay} || 1000,
        sub {
            my $todo = $self->_pre_install_files($args);
            DEBUG "Configure bar to $todo";
            $self->{-bar}->configure( -to => $todo );
            $self->_install_files($args);
            $self->{nextButton}->configure( -state => "normal" );
            $self->{backButton}->configure( -state => "normal" );

            if ( $args->{-wait} ) {
                Tk::Wizard::_fix_wait( \$args->{-wait} );

                $frame->after(
                    $args->{-wait},
                    sub {
                        $self->{nextButton}->configure( -state => 'normal' );
                        $self->{nextButton}->invoke;
                      }
                );
            }
          }
    );
    return $frame;
}


# Pre-parse, counting files and expanding directories if necessary
# Return total number of files to process
# Puts any failures into %{$self->{-failed}}
sub _pre_install_files {
    my ( $self, $args ) = ( shift, shift );
    Carp::croak "Arguments should be supplied as a hash ref"
      if not ref $args or ref $args ne "HASH";
    Carp::croak "-from and -to are different lengths"
      if $#{ $args->{-from} } != $#{ $args->{-from} };

    my $total = 0;
    my $i     = -1;
    $args->{-labelFrom}->configure( -text => $args->{-label_preparing} || "Preparing..." );
    $args->{-labelFrom}->update;
    $args->{-labelTo}->configure( -text => "" );
    $args->{-labelFrom}->update;
    $self->{-failed} = {};

    # Make a local copy of our args:
    my @asToOrig   = @{ $args->{-to} };
    my @asFromOrig = @{ $args->{-from} };
    my ( @asFrom, @asTo );

    # Process parallel lists:
  FILELIST_ELEMENT:
    foreach my $sTo (@asToOrig) {
        my $sFrom = shift @asFromOrig;
        $i++;
        if ( -d $sFrom ) {

            # Sanity check:
            if ( !-d $sTo ) {
                $self->{-failed}->{$sTo} = qq{Can not copy directory $sFrom to file};
                next FILELIST_ELEMENT;
            }
            if ( !opendir DIR, $sFrom ) {
                $self->{-failed}->{$sFrom} = qq{Can not read directory};
                next FILELIST_ELEMENT;
            }
            foreach ( grep { !/^\.{1,2}$/ } readdir DIR ) {
                push @asFrom, "$sFrom/$_";
                push @asTo,   "$sTo/$_";
                $total++;
            }
            closedir DIR or warn "Could not closedir: $!";
            next FILELIST_ELEMENT;
        }

		# Files:
        elsif ( -f $sFrom ) {
            if ( -d $sTo ) {
                # Copy from file to directory:
                my ( $sJunkVol, $sJunkPath, $fname ) = File::Spec->splitpath($sFrom);
                $sTo = "$sTo/$fname";
            }
            push @asFrom, $sFrom;
            push @asTo,   $sTo;
            $total++;
        }
        else {
            $self->{-failed}->{$sFrom} = qq{No such file or directory};
        }
    }

    if ( scalar keys %{ $self->{-failed} } > 0 ) {
        DEBUG "Failed " . ( scalar keys %{ $self->{-failed} } );;
        if ( ref $args->{-on_error} eq 'CODE' ) {
            DEBUG "Calling -on_error handler.";
            &{ $args->{-on_error} };
        }
        else {
            DEBUG "Calling self/pre_install_files_quit.";
            $self->pre_install_files_quit( scalar keys %{ $self->{-failed} } );
        }
    }
    @{ $args->{-from} } = @asFrom;
    @{ $args->{-to} }   = @asTo;
    return $total;    # why was it total+1?
}


# See page_filelist
sub _install_files {
    my ( $self, $args ) = ( shift, shift );
    Carp::croak "Arguments should be supplied as a hash ref"
      if not ref $args or ref $args ne "HASH";
    Carp::croak "-from and -to are different lengths"
      if $#{ $args->{-from} } != $#{ $args->{-from} };

    $args->{-label_from} = $args->{-move} ? 'Moving: ' : "Copying: "
      if not $args->{-label_from};
    $args->{-label_file} = "To: " if not $args->{-label_file};
    $args->{-slowdown} ||= 0;
    my $total = 0;
    my $i     = -1;

    foreach ( @{ $args->{-to} } ) {
        $i++;

        # Directories:
        if ( -d @{ $args->{-from} }[$i] ) {
            local *DIR;
            my $orig_dir = cwd;
            chdir @{ $args->{-from} }[$i] or die "'From' dir does not exist - ".@{ $args->{-from} }[$i];
            opendir DIR, "." or warn 'Could not open directory ',$!;
            foreach ( grep { !/^\.\.?$/ } readdir DIR ) {
                push @{ $args->{-from} }, @{ $args->{-from} }[$i] . "/" . $_;
                push @{ $args->{-to} },   @{ $args->{-to} }[$i] . "/" . $_;
            }
            closedir DIR or warn 'Could not close dir, ',$!;
            chdir $orig_dir;
            next;
        }

        # Files:
        elsif ( -r @{ $args->{-from} }[$i] ) {

            # update the display
            my ( $fv, $fd, $ff ) = File::Spec->splitpath( @{ $args->{-from} }[$i] );
            my ( $tv, $td, $tf ) = File::Spec->splitpath( @{ $args->{-to} }[$i] );
            $args->{-labelFrom}->configure( -text => $args->{-label_from} . @{ $args->{-from} }[$i] );
            $args->{-labelFrom}->update;
            $args->{-labelTo}->configure( -text => $args->{-label_file} . @{ $args->{-to} }[$i] );
            $args->{-labelTo}->update;
            $self->{-bar}->value( $self->{-bar}->value + 1 );
            DEBUG "Updating bar to " . $self->{-bar}->value;
            $self->{-bar}->update;

            # Make the TO path, if needs be
            my $d = File::Spec->catpath( $tv, $td, '' );
            DEBUG "Check dir $d";
            if ( !-d $d ) {
                eval { File::Path::mkpath($d) };
				Carp::croak "Could not make path $d : $!" if $@;
                DEBUG "Made $d";
				if (exists $self->{_uninstall_db} ){
					$self->{_uninstall_db}->{ Cwd::abs_path( $d ) } ++
				}
            }

            # Do the move/copy
            if ( $args->{-move} ) {
                if ( move( @{ $args->{-from} }[$i], @{ $args->{-to} }[$i] ) ) {
					if (exists $self->{_uninstall_db} ){
						$self->{_uninstall_db}->{
							Cwd::abs_path( @{ $args->{-to} }[$i] )
						} ++
					}
				}
				else {
                    $self->{-failed}->{ @{ $args->{-to} }[$i] } = "Could not write file";
                    @{ $args->{-from} }[$i] = undef;
                }
            }
            else {
                if ( copy( @{ $args->{-from} }[$i], @{ $args->{-to} }[$i] ) ) {
					if (exists $self->{_uninstall_db} ){
						$self->{_uninstall_db}->{
							Cwd::abs_path( @{ $args->{-to} }[$i] )
						} ++
					}
				}
				else {
                    $self->{-failed}->{ @{ $args->{-to} }[$i] } = "Could not write file";
                    @{ $args->{-from} }[$i] = undef;
                }
            }
        }

        else {
            $self->{-failed}->{ @{ $args->{-from} }[$i] } = "Could not read file";
            @{ $args->{-from} }[$i] = undef;
        }

		DEBUG "slowdown is =$args->{-slowdown}=\n";
		sleep( $args->{-slowdown} / 1000 ) if exists $args->{-slowdown};
    }

    if ( scalar keys %{ $self->{-failed} } > 0 ) {
        ERROR "Failed " . ( scalar keys %{ $self->{-failed} } );
        if ( ref $args->{-on_error} eq 'CODE' ) {
            TRACE "# Calling -on_error handler.";
            &{ $args->{-on_error} };
        }
        else {
            TRACE "# Calling pre_install_files_quit.";
            $self->pre_install_files_quit( scalar keys %{ $self->{-failed} } );
        }
    }

    else {
        $args->{-labelFrom}->configure(	-text => 'Completed.' );
        $args->{-labelTo}->configure(	-text => '' );
    }

    return $total;
}


=head2 addDownloadPage

	$wizard->addDownloadPage( name1 => value1 ... nameN => valueN )

Adds a page that will attempt to download specified
files to specified locations, updating two progress bars in the
process.

If a file cannot be downloaded, the user will be prompted to try
again.  If the user sooner or later wishes to carry on even though
a file has not downloaded, the calling C<Wizard>'s C<-failed>
slot is filled with the URIs of the files that could not be downloaded,
and the supplied C<-on_error> argument comes into play - see below.
If no C<-on_error> parameter is provided, the Wizard will continue.

The I<Next> and I<Back> buttons of the Wizard are disabled whilst
the download process takes place.

=over 4

=item -files

A reference to a hash, where keys are URIs and
values are local locations to place the contents of those URIs.

WARNING: Files that are successfully downloaded will be deleted from
the hash.

=item -wait

If supplied, the frame will remain on the screen when the download
is complete - default is to automate a click on the C<next> button
once the downloads are completed without errors.

=item -bar

A list of properties to pass to the L<Tk::ProgessBar|Tk::ProgessBar>
object created and used in this routine.  Assumes reasonable defaults.

=item -no_retry

If set to a true value, will prevent the I<Try again?> dialogue.

=item -on_error

If a file cannot be downloaded and the user chooses not to keep trying,
then this parameter comes into operation.  If it is a reference, then it
is assumed to be a code reference to execute; otherwise a dialogue box
asks the user if they really wish to quit.  If they do, then the
Tk::Wizard CloseWindow event cycle is triggered -- the
default result of which is probably yet another confirmation of closure....

If no C<-on_error> parameter is provided, the Wizard will continue even
if it cannot download the requested data.

=item -done_text

Text to display when complete.  Default: I<complete>.

=back

Would it be useful to implement globbing for FTP URIs?

=cut

sub addDownloadPage {
    my ( $self, $args ) = ( shift, {@_} );
    # $self->addPage( sub { $self->_page_download($args) } );
	my %btn_args =
		map { my $x = delete $args->{$_}; $_ => $x }
		grep { /ButtonAction$/ }
		keys %$args;
	return $self->addPage( sub { $self->_page_download($args) }, %btn_args );
}

sub _page_download {
    my ( $self, $args ) = ( shift, shift );
    Carp::croak "Arguments should be supplied as a hash ref"
      if not ref $args or ref $args ne "HASH";
    Carp::croak "-files is required" if not $args->{-files};
    Carp::croak "-files should be a hash of uri => filepath pairs"
      if ref $args->{-files} ne 'HASH';

    my @failed;
    my $frame = $self->blank_frame(
        -title    => $args->{-title}    || "Downloading Files",
        -subtitle => $args->{-subtitle} || "Please wait whilst Setup downloads files to your computer.",
        -text     => $args->{-text}     || "\n"
    );
    my %bar;    # progress bar args

    if ( defined $args->{-bar} ) {
        %bar = @{ $args->{-bar} };
        # insert error checking here...
    }
    $bar{-gap}    = 0 unless defined $bar{-gap};
    $bar{-blocks} = 0 unless defined $bar{-blocks};
    $bar{-colors}      = [ 0 => 'blue' ] unless $bar{-colors};
    $bar{-borderwidth} = 2               unless $bar{-borderwidth};
    $bar{-relief}      = 'sunken'        unless $bar{-relief};
    $bar{-from}        = 0               unless $bar{-from};
    $bar{-to}          = 100             unless $bar{-to};

    my $all = $frame->LabFrame(
        -label => $args->{-label_all_files} || "Over-all Progress",
        -labelside => "acrosstop"
    );
    $self->{-bar} = $all->ProgressBar(%bar)->pack(qw/ -padx 20 -pady 10 -side top -anchor w -fill both -expand 1 /);
    $all->pack(qw/-fill x -padx 30/);

    $args->{file_label} = $frame->LabFrame(
        -label => $args->{-label_this_file} || "This FIle",
        -labelside => "acrosstop"
    );
    $args->{-file_bar} =
      $args->{file_label}->ProgressBar(%bar)->pack(qw/ -padx 20 -pady 10 -side top -anchor w -fill both -expand 1 /);

    $args->{file_label}->pack(qw/-fill x -padx 30/);
    $self->{nextButton}->configure( -state => "disable" );
    $self->{backButton}->configure( -state => "disable" );

    $self->{-bar}->after(
        $args->{-delay} || 10,
        sub {
            require LWP::UserAgent;
            require HTTP::Request;
            while ( scalar keys %{ $args->{-files} } > 0 ) {
                $args->{file_label}->configure( -label => 'Preparing to download...' );
                $args->{file_label}->update;
                $self->{-bar}->value(0);
                $self->{-bar}->configure( -to => scalar keys %{ $args->{-files} } );

                foreach my $uri ( keys %{ $args->{-files} } ) {
                    TRACE "Try $args->{-files}->{$uri}";
                    my ($uri_msg) = $uri =~ m!^\w+:/+[^/]+(.*?)/?$!;
                    $args->{file_label}->configure( -label => $uri_msg || "Current File" );
                    $args->{file_label}->update;
                    if (
                        $self->_read_uri(
                            bar    => $args->{-file_bar},
                            uri    => $uri,
                            target => $args->{-files}->{$uri},
                        )
                      )
                    {
                        delete $args->{-files}->{$uri};
                    }
                    $self->{-bar}->value( $self->{-bar}->value + 1 );
                    $self->{-bar}->update;
                    $args->{-file_bar}->configure( -to => 0 );
                    $args->{-file_bar}->value(0);
                    $args->{-file_bar}->update;
                }

                if ( scalar keys %{ $args->{-files} } > 0 ) {
                    DEBUG "Files left: ", ( scalar keys %{ $args->{-files} } );
                    if ( $args->{-no_retry}
                        || !$self->confirm_download_again( scalar keys %{ $args->{-files} } ) )
                    {
                        INFO "Not trying again";
                        $self->{-failed} = $args->{-files};
                        $args->{-files}  = {};
                    }
                }
            }

            if ( scalar keys %{ $self->{-failed} } > 0 and $args->{-on_error} ) {
                DEBUG "Failed to download";
                if ( ref $args->{-on_error} eq 'CODE' ) {
                    DEBUG "Calling -on_error handler.";
                    &{ $args->{-on_error} };
                }
                elsif ( $args->{-on_error} ) {
                    DEBUG "Calling self/download_quit.";
                    $self->download_quit( scalar keys %{ $self->{-failed} } );
                }
            }
            else {
                INFO "Failures: ", scalar keys %{ $self->{-failed} };
                foreach ( keys %{ $self->{-failed} } ) {
                    INFO "\t$_\n";
                }
                $self->{-failed} = 0;
            }
            $self->{-bar}->packForget;
            $args->{-file_bar}->packForget;
            $args->{file_label}->packForget;
            $all->packForget;
            $frame->Label( -text => $args->{-done_text} || "Finished", )->pack( -fill => "both", -expand => 1 );

            # $self->{backButton}->configure(-state=>"normal");
            $self->{nextButton}->configure( -state => "normal" );
            if ( $args->{-wait} ) {
                Tk::Wizard::_fix_wait( \$args->{-wait} );

                $frame->after(
                    $args->{-wait},
                    sub {
                        $self->{nextButton}->configure( -state => 'normal' );
                        $self->{nextButton}->invoke;
                      }
                );
            }
          }
    );
    return $frame;
}

# c/o PPM.pm
sub _read_uri {
    my ( $self, $args ) = ( shift, {@_} );
    carp "Require uri param"    unless defined $args->{uri};
    carp "Require target param" unless defined $args->{target};
    my ( $proxy_user, $proxy_pass );
    ( $self->{response}, $self->{bytes_transferred}, $self->{errstr} ) = ( undef, 0, undef );
    my $ua = LWP::UserAgent->new;
    $ua->timeout( $args->{timeout}     || 10 );
    $ua->agent( $ENV{HTTP_PROXY_AGENT} || ( "$0/$Tk::Wizard::Installer::VERSION " . $ua->agent ) );

    if ( defined $args->{proxy} ) {
        $proxy_user = $args->{HTTP_PROXY_USER};
        $proxy_pass = $args->{HTTP_PROXY_PASS};
        DEBUG "_read_uri: calling env_proxy: $args->{http_proxy}";
        $ua->env_proxy;
    }
    elsif ( defined $ENV{HTTP_PROXY} ) {
        $proxy_user = $ENV{HTTP_PROXY_USER};
        $proxy_pass = $ENV{HTTP_PROXY_PASS};
        DEBUG "_read_uri: calling env_proxy: $ENV{HTTP_proxy}";
        $ua->env_proxy;
    }
    my $req = HTTP::Request->new( GET => $args->{uri} );
    if ( defined $proxy_user and defined $proxy_pass ) {
        DEBUG "_read_uri: calling proxy_authorization_basic($proxy_user, $proxy_pass)";
        $req->proxy_authorization_basic( $proxy_user, $proxy_pass );
    }

    # update the progress bar
    ( $self->{response}, $self->{bytes_transferred} ) = ( undef, 0 );
    $self->{response} = $ua->request( $req, sub { &_lwp_callback( $self, $args->{bar}, @_ ) },, 4096 );
    if ( $self->{response} && $self->{response}->is_success ) {
        my ( $dirs, $file ) = $args->{target} =~ /^(.*?)([^\\\/]+)$/;
        if ( $dirs and $dirs !~ /^\.{1,2}$/ and !-d $dirs ) {
            eval { File::Path::mkpath($dirs) };
            if ($@) {
                Carp::croak "Could not make path $dirs : $!";
            }
        }
        my $TARGET;
        if ( !open $TARGET, '>', $args->{target} ) {
            ERROR "_read_uri: Couldn't open $args->{target} for writing";
            $self->{errstr} = "Couldn't open $args->{target} for writing: $!\n";
            return;
        }
        DEBUG "# Writing to $args->{target}...";
        $TARGET->binmode;
        $TARGET->print( $self->{response}->content ) or warn;
        $TARGET->close                               or warn;
        return 1;
    }

    my $sMsg = "Error(2) reading $args->{uri}\n";
    if ( $self->{response} ) {
        $sMsg =
          join( ' ', qq{Error(1) reading $args->{uri}:}, $self->{response}->code, $self->{response}->message, "\n" );
    }
    DEBUG "_read_uri: $sMsg";
    $self->{errstr} = $sMsg;
    return 0;
}

# c/o PPM.pm
sub _lwp_callback {
    my $self = shift;
    my ( $bar, $data, $res, $protocol ) = @_;
    $bar->configure( -to => $res->header('Content-Length') );

    #  $bar->configure(-to => $res->{_headers}->content_length);
    $bar->value( $bar->value + length $data );
    $bar->update;
    $self->{response} = $res;
    $self->{response}->add_content($data);
    $self->{bytes_transferred} += length $data;
}


=head1 CALLBACKS

=head2 callback_licence_agreement

Intended to be used with an action-event handler like C<-preNextButtonAction>,
this routine check that the object field C<licence_agree>
is a Boolean true value. If that operand is not set, it warns
the user to read the licence; if that operand is set to a
Boolean false value, a message box says goodbye and quits the
program.

=cut

sub callback_licence_agreement {
    my $self = shift;
    if ( not defined ${ $self->{licence_agree} } ) {
        my $button = $self->parent->messageBox(
            '-icon'  => 'info',
            -type    => 'ok',
            -title   => $LABELS{LICENCE_ALERT_TITLE},
            -message => $LABELS{LICENCE_IGNORED}
        );
        return 0;
    }
    elsif ( not ${ $self->{licence_agree} } ) {
        my $button = $self->parent->messageBox(
            '-icon'  => 'warning',
            -type    => 'ok',
            -title   => $LABELS{LICENCE_ALERT_TITLE},
            -message => $LABELS{LICENCE_DISAGREED}
        );
        exit;
    }
    return 1;
}

=head2 confirm_download_again

This callback is triggered when a file download fails
during a DownloadPage.
In the default implementation, the user is asked if they would like to try again
(Yes or No).

=cut

sub confirm_download_again {
    my ( $self, $failed ) = ( shift, shift );
    my $button = $self->parent->messageBox(
        -icon    => 'question',
        -type    => 'yesno',
        -default => 'yes',
        -title   => 'File Download',
        -message => $failed . " file"
          . ( $failed != 1 ? "s" : "" )
          . " were not downloaded.\n\nWould you like to try again?",
    );
    return lc $button eq 'yes' ? 1 : 0;
}

=head2 confirm_download_quit

This callback is triggered when the -on_error condition happens
at the end of a DownloadPage.
In the default implementation, the user is asked if they would like to abort the entire installation process
(Yes or No).

=cut

sub confirm_download_quit {
    my ( $self, $failed ) = ( shift, shift );
    my $button = $self->parent->messageBox(
        -icon    => 'error',
        -type    => 'yesno',
        -default => 'no',
        -title   => 'Abort Installation?',
        -message => "Without downloading the remaining $failed file"
          . ( $failed != 1 ? "s" : "" )
          . ", the Installer cannot complete the installation.\n\n"
          . "Should the Installation process be aborted?",
    );
    $self->CloseWindowEventCycle if lc $button eq 'yes';
}



=head2 pre_install_files_quit

Asks if the user wishes to continue after file copy errors.

=cut

sub pre_install_files_quit {
    my ( $self, $failed ) = ( shift, shift );
    TRACE "Enter pre_install_files_quit ...";

	SHOW:
    my $d = $self->Dialog(
        -bitmap         => 'error',
        -buttons        => [ 'Yes', 'No', 'Details' ],
        -default_button => 'no',
        -title          => 'Abort Installation?',
        -text           => "Failed to copy $failed file"
          . ( $failed != 1 ? "s" : "" ) . ".\n\n"
          . "Do you wish to continue anyway?",
    );
    my $button = $d->Show;
    if ( lc $button eq 'details' ) {
        $self->messageBox(
            -title   => 'File error details',
            -type    => 'Ok',
            -icon    => 'info',
            -message => join(
                "\n", map { join( ' ', $self->{-failed}->{$_}, $_ ) }
                  keys %{ $self->{-failed} }
            ),
        );
        goto SHOW; # XXX Martin, why goto?!
    }

    if ( lc $button eq 'no' ) {
        DEBUG "Won't continue....";
        $self->{cancelButton}->configure( -state => 'normal' );
        $self->{cancelButton}->invoke;
    }
    else {
        DEBUG "Will continue.";
    }

    # Clear out the error list so we don't inform the user twice about
    # the same problem:
    $self->{-failed} = undef;
}



=head2 addUninstallPage

Basically the same as L<addFileListPage|addFileListPage>,
but rather than taking arguments to indicate from and to where
files are to be moved or copied, takes the argument
C<-uninstall_db>, which should be the same value as supplied to
L<addFileListPage|addFileListPage>.

=cut


sub addUninstallPage {
    my ( $self, $args ) = ( shift, {@_} );
    # $self->addPage( sub { $self->_page_uninstall($args) } );
	my %btn_args =
		map { my $x = delete $args->{$_}; $_ => $x }
		grep { /ButtonAction$/ }
		keys %$args;
	return $self->addPage( sub { $self->_page_uninstall($args) }, %btn_args );
}

sub _page_uninstall {
    my ( $self, $args ) = ( shift, shift );

    my $frame = $self->blank_frame(
        -title    => $args->{-title}    || "Uninstalling Files",
        -subtitle => $args->{-subtitle} || "Please wait whilst files are uninstalled.",
        -text     => $args->{-text}     || "\n"
    );

    my %bar;    # progress bar args
    if ( $args->{-bar} ) {
        %bar = @{ $args->{-bar} };
        # insert error checking here...
    }
    $bar{-gap}    		= 0 unless defined $bar{-gap};
    $bar{-blocks} 		= 0 unless defined $bar{-blocks};
    $bar{-colors}      	= [ 0 => 'blue' ] unless $bar{-colors};
    $bar{-borderwidth} 	= 2               unless $bar{-borderwidth};
    $bar{-relief}      	= 'sunken'        unless $bar{-relief};
    $bar{-from}        	= 0               unless $bar{-from};
    $bar{-to}          	= 100             unless $bar{-to};

    my $f = $frame->LabFrame(
        -label 		=> $args->{-label_frame_title} || "Uninstalling files",
        -labelside	=> "acrosstop"
    );
    $args->{-labelFrom} = $f->Label(qw//)->pack(qw/-padx 16 -side top -anchor w/);
    $args->{-labelTo}   = $f->Label(qw//)->pack(qw/-padx 16 -side top -anchor w/);
    $self->{-bar}       = $f->ProgressBar(%bar)->pack(qw/ -padx 20 -pady 10 -side top -anchor w -fill both -expand 1 /);
    $f->pack(qw/-fill x -padx 30/);

    $self->{nextButton}->configure( -state => "disable" );
    $self->{backButton}->configure( -state => "disable" );

	# Get the db file ready
	$self->{_uninstall_db_path} = $args->{-uninstall_db};
	$self->{_uninstall_db} = {};
	tie(
		%{$self->{_uninstall_db}},
		'SDBM_File',
		$self->{_uninstall_db_path},
		O_RDWR,
		$args->{-uninstall_db_perms} || 0666,
	) or die "Could not create uninstaller db file - failed to tie `SDBM file '$self->{_uninstall_db_path}': $!; aborting";

    $self->{-bar}->after(
        $args->{-delay} || 1000,
        sub {
            my $todo = scalar keys %{$self->{_uninstall_db}};
            TRACE "Configure bar to $todo\n";
            $self->{-bar}->configure( -to => $todo );

            # $self->_install_files($args);

			# Process files
			my $i = 0;
			foreach my $file (keys %{$self->{_uninstall_db}}){
				# Skip dirs for now - process below
				next if -d $file;
				# Process files if they have not been deleted by user
				if (-e $file){
					if (unlink $file){
						# No report of removed files
						delete $self->{_uninstall_db}->{$file};
					}
					else {
						# Report info
						$self->{_uninstall_db}->{$file} = 'could not remove file - '.$@;
					}
				}
				else {
					# Report info
					$self->{_uninstall_db}->{$file} = 'does not exist';
				}
				$self->{-bar}->value( $self->{-bar}->value + 1 );
				# DEBUG "Updating bar to " . $self->{-bar}->value;
				$self->{-bar}->update;
				$i ++;
			}

			# Process dirs
			foreach my $dir (keys %{$self->{_uninstall_db}}){
				next unless -d $dir;

				INFO "Try to remove $dir";

				my $pwd = getcwd;
				if (not chdir $dir){
					ERROR "Could not cd to $dir - $@";
					ERROR "   -e $dir == ".(-e $dir);
					next;
				}
				chdir $pwd;
				my @present;
				if (opendir my $d, $dir){
                	@present = grep { !/^\.+$/ } readdir $d;
					closedir $d;
				} else {
					 warn $pwd," - ",$!;
				 }

				if (@present){
					$self->{_uninstall_db}->{$dir} = "contains user-created files";
				}
				elsif (not rmdir $dir){
					$self->{_uninstall_db}->{$dir} = $!;
				}
				else {
					delete $self->{_uninstall_db}->{$dir};
				}
				$self->{-bar}->value( $self->{-bar}->value + 1 );
				DEBUG "Updating bar to " . $self->{-bar}->value;
				$self->{-bar}->update;
				$i ++;
			}

            $self->{nextButton}->configure( -state => "normal" );
            $self->{backButton}->configure( -state => "normal" );

			if (scalar keys %{ $self->{_uninstall_db} }){
				# report
				my $button = $self->messageBox(
					'-icon'  => 'warning',
					-type    => 'ok',
					-title   => 'Some files could not be removed',
					-message => join( "\n",
						"Some files could not be removed:\n"
						. join("\n",
							map { $_ ." - ". $self->{_uninstall_db}->{$_} }
								keys %{ $self->{_uninstall_db} }
						)
				)
				);
			}

			$self->{_uninstall_db} = undef;
			untie %{ $self->{_uninstall_db} };
			foreach my $i (qw( dir pag )){
				my $fn = $self->{_uninstall_db_path}.'.'.$i;
				DEBUG "Try to remove $fn";
				if (not unlink $fn ){
					my $perm = (stat $fn)[2]; # umask
					ERROR "Could not remove ".$fn." - $! (perms without umask = $perm";
				}
			}

            if ($args->{-wait}) {
                Tk::Wizard::_fix_wait( \$args->{-wait} );
                $frame->after(
                    $args->{-wait},
                    sub {
                        $self->{nextButton}->configure( -state => 'normal' );
                        $self->{nextButton}->invoke;
					}
                );
            }
          }
    );
    return $frame;
}

=head1 DIALOGUES

=head2 DIALOGUE_really_quit

Called when the user tries to quit.
As opposed to the base C<Wizard>'s dialogue of the same name,
this dialogue refers to "the Installer", rather than "the Wizard".

=cut

sub DIALOGUE_really_quit {
    TRACE "Enter Installer DIALOGUE_really_quit  ...";
    my $self = shift;
    return 0 if $self->{nextButton}->cget( -text ) eq $LABELS{FINISH};
    unless ( $self->{really_quit} ) {
        my $button = $self->parent->messageBox(
            -icon    => 'question',
            -type    => 'yesno',
            -default => 'no',
            -title   => 'Quit The Installation?',
            -message => "The Installer has not finished running.\n\nIf you quit now, the installation will be incomplete.\n\nDo you really wish to quit?"
        );
        $self->{really_quit} = lc $button eq 'yes' ? 1 : 0;
    }
    if ( $self->{really_quit} ) {
        DEBUG "Quitting\n";
        $self->{cancelButton}->configure( -state => 'normal' );
        $self->{cancelButton}->invoke;
    }
    else {
        DEBUG "Ok, continuing\n";
    }
    return !$self->{really_quit};
}

1;

__END__

=head1 INTERNATIONALISATION

The labels of the licence can be changed (perhaps into a language other an English)
by changing the values of the package-global C<%LABELS> hash, at the top of the source.
This will be revised in a future version.

Please see other functions' arguments for label-changing parameters.

=head1 CAVEATS / TODO / BUGS

=over 4

=item *

It would be nice to have an 'Estimated Time Remaining' feature for the copy routines.

=item *

How about a remove-before-copy feature, and removing of directories?  When there is time, yes.

=back

=head1 SEE ALSO

L<Tk::LabFrame>; L<File::Path>; L<Tk::ProgressBar>; L<File::Spec>; L<File::Copy>; L<Tk>; L<Tk::Wizard>; L<Tk::Wizard::Install::Win32>.

=head1 AUTHOR

Lee Goddard (lgoddard @ cpan.org).

=head1 KEYWORDS

Wizard; set-up; setup; installer; uninstaller; install; uninstall; Tk; GUI.

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org).

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 11/2002 - 01/s ff.

Made available under the same terms as Perl itself.
