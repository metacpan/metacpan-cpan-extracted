# ##############################################################################
# # Script     : Tkx::TclTk::Bind.pm                                           #
# # -------------------------------------------------------------------------- #
# # Copyright  : Frei unter GNU General Public License  bzw.  Artistic License #
# # Authors    : JVBSOFT - Jürgen von Brietzke                   0.001 - 1.400 #
# # Version    : 1.400                                             14.Feb.2016 #
# # -------------------------------------------------------------------------- #
# # Function   : Bindet TclTk-Bibliotheken an Perl::Tkx                        #
# # -------------------------------------------------------------------------- #
# # Language   : PERL 5                                (V) 5.12.xx  -  5.22.xx #
# # Coding     : ISO 8859-15 / Latin-9                         UNIX-Zeilenende #
# # Standards  : Perl-Best-Practices                       severity 1 (brutal) #
# # -------------------------------------------------------------------------- #
# # Module     : Archive::Tar                           ActivePerl-CORE-Module #
# #              Config                                                        #
# #              English                                                       #
# #              Exporter                                                      #
# #              File::Spec                                                    #
# #              Tkx                                                           #
# #              ------------------------------------------------------------- #
# #              Const::Fast                            ActivePerl-REPO-Module #
# #              File::Remove                                                  #
# #              Modern::PBP::Perl                                             #
# ##############################################################################

package Tkx::TclTk::Bind 1.400;

# ##############################################################################

use Archive::Tar;
use Config;
use Const::Fast;
use English qw{-no_match_vars};
use File::Remove qw{remove};
use File::Spec;
use Modern::PBP::Perl qw{5.12};
use Tkx;

# ##############################################################################

use base qw{ Exporter };
our @EXPORT_OK = qw{ &load_library };

# ##############################################################################

our $TEMP_DIR;
our @PACKAGES;

# ##############################################################################
# #                            D E S T R U K T O R                             #
# ##############################################################################
# # Aufgabe   | Löscht die temporären Dateien                                  #
# ##############################################################################

sub END {

   foreach my $package (@PACKAGES) {
      my $dir = File::Spec->catfile( $TEMP_DIR, $package );
      remove( \1, $dir );
   }

} # end of sub END

# ##############################################################################
# # Name      | load_library                                                   #
# # ----------+--------------------------------------------------------------- #
# # Aufgabe   | Lädt ein Bibliotheks-Archiv in das System-Temp-Verzeichnis     #
# # ----------+------------+-------------------------------------------------- #
# # Parameter | scalar     | Name des Bibliothek-Archivs ohne '.xx.tar'        #
# #           | array      | Zu installierender Tcl/Tk-Package-Name            #
# # ----------+------------+-------------------------------------------------- #
# # Rückgabe  | scalar     | Pfad zum entpackten Archiv                        #
# ##############################################################################

sub load_library {

   my ( $library, @package ) = @ARG;

   const my $CONST_UMASK => oct 777;

   # --- TEMP-Verzeichnis bestimmen --------------------------------------------
   $TEMP_DIR
      = defined $ENV{TMP}    ? $ENV{TMP}
      : defined $ENV{TEMP}   ? $ENV{TEMP}
      : defined $ENV{TMPDIR} ? $ENV{TMPDIR}
      : defined $ENV{HOME}   ? $ENV{HOME}
      :                        undef;
   if ( not defined $TEMP_DIR ) {
      _error( 'No environment value "ENV{TMP & TEMP & TMPDIR & HOME}" found',
         $library );
   }

   # --- TEMP-Verzeichnis erzeugen wenn nötig ----------------------------------
   $TEMP_DIR = File::Spec->catfile( $TEMP_DIR, 'TclTk' );
   if ( not -e $TEMP_DIR ) {
      mkdir $TEMP_DIR, $CONST_UMASK
         or _error( "Can't create directory\n$TEMP_DIR", $library );
   }

   # --- Archiv-Name und -Typ bestimmen ----------------------------------------
   my $archname
      = $OSNAME =~ /MSWin32/ismx ? 'mswin'
      : $OSNAME =~ /linux/ismx   ? 'linux'
      : $OSNAME =~ /darwin/ismx  ? 'darwin'
      :                            undef;
   if ( not defined $archname ) {
      _error( "System $OSNAME is not supported", $library );
   }
   my $archtype
      = $Config{archname} =~ /i686-linux/smx   ? '32'
      : $Config{archname} =~ /x86_64-linux/smx ? '64'
      : $Config{archname} =~ /MSWin32-x86/smx  ? '32'
      : $Config{archname} =~ /MSWin32-x64/smx  ? '64'
      : $Config{archname} =~ /darwin/smx       ? 'xx'
      :                                          undef;
   if ( not defined $archtype ) {
      _error( 'System type unknown - must be 32- or 64-bit', $library );
   }
   my $tar_name = "$library.$archname.$archtype.tar";

   my $archiv;

   # --- Archiv-Datei aus 'PerlApp' laden --------------------------------------
   no warnings;
   if ( defined $PerlApp::BUILD ) {
      $archiv = PerlApp::extract_bound_file($tar_name);
      if ( not defined $archiv ) {
         _error( "Library '$archiv' not boundet", $library );
      }
   }

   # --- Archiv-Datei im Installations-Pfad suchen -----------------------------
   else {
      foreach my $lib (@INC) {
         $archiv
            = File::Spec->catfile( $lib, qw(Tkx TclTk Bind TAR), $tar_name );
         last if ( -e $archiv );
         $archiv = undef;
      }
      if ( not defined $archiv ) {
         _error( "Library '$tar_name' not found", $library );
      }
   }
   use warnings;

   # --- Archiv-Datei in TEMP-Verzeichnis entpacken ----------------------------
   my $tar = Archive::Tar->new();
   $tar->read($archiv);
   my @entries = $tar->list_files;
   foreach my $entry (@entries) {
      my $target = File::Spec->catfile( $TEMP_DIR, $entry );
      if ( $entry =~ /[\/]$/ismx ) {
         if ( not -e $target ) {
            mkdir $target, $CONST_UMASK
               or _error( "Can't create directory\n$target", $library );
         }
      }
      else {
         my $file = $tar->get_content($entry);
         open my $FH, '>', $target or _error( "Can't open\n$target", $library );
         binmode $FH;
         print {$FH} $file or _error( "Can't print\n$target", $library );
         close $FH or _error( "Can't close\n$target", $library );
         chmod $CONST_UMASK, $target;
      }
   }

   push @PACKAGES, @package;

   return $TEMP_DIR;

} # end of sub load_library

# ##############################################################################
# #                        P R I V A T E   --   S U B S                        #
# ##############################################################################

sub _error {

   my ( $error_text, $library ) = @ARG;

   Tkx::package_require('BWidget');
   my $error_window = Tkx::widget->new(q{.});
   my $return       = $error_window->new_MessageDlg(
      -title   => "Tkx::TclTk::Bind::$library",
      -message => $error_text,
      -icon    => 'error',
      -buttons => ['Cancel'],
      -font    => 'TkCaptionFont',
      -width   => 500,
   );
   Tkx::destroy($error_window);
   exit;

} # end of sub _error

# ##############################################################################
# #                                  E N D E                                   #
# ##############################################################################
1;

__END__

=head1 NAME

Tkx::TclTk::Bind - Load Tcl/Tk-Library to Temp-Directory


=head1 VERSION

This document describes Perl::Modern::Perl version 1.400.


=head1 SYNOPSIS

   use Tkx::TclTk::Bind qw{ &load_library };
   ...
   my $temp_dir = load_library('tlc-tk-library-archiv');


=head1 DESCRIPTION

The module is an auxiliary module for:

=over 3

=item Tkx::TclTk::Bind::IWidgets

=item Tkx::TclTk::Bind::ImageLibrary

=back

Use this modul not direct !!!


=head1 DIAGNOSTICS

All error messages are displayed in a Tkx MessageBox.

=head2 No environment value "ENV{TMP & TEMP & TMPDIR & HOME}" found

Could not find environment variable to store the libraries.

=head2 Can't create directory\nTEMP_DIR

Can not display the directory for the libraries.

=head2 System xxxxxx is not supported

The current operating system is not supported.

=head2 System type unknown - must be 32- or 64-bit

t can not be determined whether the Perl version is based on 32 or 64 bits.

=head2 Library 'xxxxxx' not boundet

The library was not involved in the production of B<PerlApp>.

=head2 Library 'xxxxxx' not found

The library was not found.

=head2 Can't create directory\n$xxxxxx

The temporary working directory can not be created.

=head2 Can't open\nxxxxxx  /  Can't print\nxxxxxx  /  Can't close\nxxxxxx

The library can not be exported or saved.


=head1 INTERFACE

=head2 load_library(...)

Load and extract the given library-archiv (TAR-Ball without system-type and
'.tar') to the User-TEMP-Directory.

When you exit the program, the libraries are unloaded.

The modul include support for B<PerlApp> from B<ActiveState>.


=head1 CONFIGURATION AND ENVIRONMENT

The binding to libraries in a directory under the environment variable:

   - TMP
   - TEMP
   - TEMPDIR
   - HOME

stored. The search sequence corresponds to the sequence shown.


=head1 DEPENDENCIES

The following pragmas and modules are required:

=head2 CORE

   - Archive::Tar
   - Config
   - English
   - Exporter
   - File::Spec
   - Tkx

=head2 CPAN or ActiveState Repository

   - Const::Fast
   - File::Remove
   - Modern::PBP::Perl


=head1 INCOMPATIBILITIES

The module works with PERL 5:12 or higher under MS Win, Linux and Max OS.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-modern-moose@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Juergen von Brietzke  C<< <juergen.von.brietzke@t-online.de> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015,
Juergen von Brietzke C<< <juergen.von.brietzke@t-online.de> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
