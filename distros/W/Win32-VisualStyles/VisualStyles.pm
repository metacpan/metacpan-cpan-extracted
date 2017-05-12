package Win32::VisualStyles;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

use Exporter ();
our @ISA = qw(Exporter);

our @EXPORT_OK = qw( STAP_ALLOW_NONCLIENT
                     STAP_ALLOW_CONTROLS
                     STAP_ALLOW_WEBCONTENT
                     GetThemeAppProperties
                     SetThemeAppProperties
                     IsAppThemed
                     IsThemeActive
                     control_styles_active
                   );

our %EXPORT_TAGS = (
    constants => [ qw( STAP_ALLOW_NONCLIENT
                       STAP_ALLOW_CONTROLS
                       STAP_ALLOW_WEBCONTENT
                )],
    functions => [ qw( GetThemeAppProperties
                       SetThemeAppProperties
                       IsAppThemed
                       IsThemeActive
                       control_styles_active
                )],
    all       => [ @EXPORT_OK ],
                   );

require XSLoader;
XSLoader::load('Win32::VisualStyles', $XS_VERSION);

our $_V6_CONTEXT_APPLIED = 0;

sub import {
    my($pkg, @spec) = @_;
    my $apply_context = 1;
    my @new_spec;

    # Process local (non-Exporter) spec
    for my $spec (@spec) {
        $apply_context = 0, next if $spec =~ m/^:use_default_context$/;
        push @new_spec, $spec;
    }

    # Pass anything left to Exporter
    __PACKAGE__->export_to_level(1, $pkg, @new_spec);

    if($apply_context) {
        if($_V6_CONTEXT_APPLIED) {
            require Carp;
            Carp:carp("Attempt to apply activation context more than once ignored");
        }
        else {
            $_V6_CONTEXT_APPLIED = _SetActivationContext();
        }
    }
}

sub STAP_ALLOW_NONCLIENT  {1}
sub STAP_ALLOW_CONTROLS   {2}
sub STAP_ALLOW_WEBCONTENT {4}

sub control_styles_active {
    return 0 unless _v6_context_active();
    return 0 unless IsAppThemed();
    return 0 unless IsThemeActive();
    return (GetThemeAppProperties() & STAP_ALLOW_CONTROLS);
}

1; # End of VisualStyles.pm
__END__

=head1 NAME

Win32::VisualStyles - Apply Win32 Visual (aka XP) Styles to windows

=head1 SYNOPSIS

  use Win32::VisualStyles;   # enable visual styles

  # Turn on visual styles from the command line
  C:\> perl -MWin32::VisualStyles script.pl

  my $styles = Win32::VisualStyles::GetThemeAppProperties();
  Win32::VisualStyles::SetThemeAppProperties($styles);

  use Win32::VisualStyles qw(IsThemeActive IsAppThemed);
  my $global_styles_enabled = IsThemeActive();
  my $app_styles_enabled    = IsAppThemed();

  use Win32::VisualStyles qw(GetThemeAppProperties :use_default_context);
    # Get access to GetThemeAppProperties() without changing the
    # activation context

  if( Win32::VisualStyles::control_styles_active() ) {
    # Do something if styles are active for this app.
  }

=head1 DESCRIPTION

This module modifies the run-time environment (the "activation context")
of a Win32 process to control Visual Styles (aka XP Styles).

Visual Styles are the new graphical designs used for user interface
components starting from Windows XP.  You may also hear them refered
to using the informal term 'v6 manifest'.  They are implemented by
v6 of Comctl32.dll.

By default this module enables visual styles for all graphical components that
support them, and that are created after the module is loaded.  There
may well be side effects on graphical components created before this
module is loaded, so it is recommended to load this module as early
in your program as possible. It is possible to override this default
behaviour by passing the C<< :use_default_context >> tag on the
import line - this allows you to load the module without enabling
visual styles.

Note that the effect is global, and so this module should not be used
by module authors themselves.

On Operating systems that do not support Visual Styles (i.e. before
Windows XP) this module should have no effect, so it is safe to call
unconditionally from your script - although if you expect you script
to be run on multiple platforms you should check that it looks
correct on each target platform.

In cases where different code needs to be run when Styles are active
then you can call the C<< Win32::VisualStyles::control_styles_active() >>
function which will return a true value when visual styles are
actually in use.

=head1 EXPORTS

By default this module exports nothing into the calling namespace.
On request the following symbols may be exported:

=over

=item C<< GetThemeAppProperties >>

=item C<< SetThemeAppProperties >>

=item C<< IsAppThemed >>

=item C<< IsThemeActive >>

=item C<< STAP_ALLOW_NONCLIENT >>

=item C<< STAP_ALLOW_CONTROLS >>

=item C<< STAP_ALLOW_WEBCONTENT >>

=item C<< control_styles_active >>

=back

The following tags may be used as shortcuts on the import line:

=over

=item C<< :all >>

Imports all functions and constants listed above.

=item C<< :functions >>

Imports all the functions:
C<< GetThemeAppProperties >>,
C<< SetThemeAppProperties >>,
C<< IsAppThemed >>,
C<< IsThemeActive >>,
C<< control_styles_active >>.

=item C<< :constants >>

Imports all the constants:
C<< STAP_ALLOW_NONCLIENT >>,
C<< STAP_ALLOW_CONTROLS >>,
C<< STAP_ALLOW_WEBCONTENT >>.

=item C<< :use_default_context >>

This pseudo-tag, when passed on the import line prevents this module
from altering the activation context. Use this when you just want
assess to the functions provided without forcing visual styles to be
enabled. Whether visual styles are actually enabled or not will depend
on the build and environment of the perl you are using.

=back

=head1 AVAILABLE FUNCTIONS

=head2 GetThemeAppProperties

  my $styles = GetThemeAppProperties();

Returns a bitmask with bits set to indicate whether themes are
currently being applied to various regions of the application.   Note
that the returned bitmask may not reflect reality in the case that
visual styles are disabled by the operating system and
C<< SetThemeAppProperties() >> has been called.

=over

=item C<< $styles & STAP_ALLOW_NONCLIENT >>

If true, themes are active for non-client (frame) areas of windows.

=item C<< $styles & STAP_ALLOW_CONTROLS >>

If true, themes are active for controls (buttons etc.) within the
client areas of windows.

=item C<< $styles & STAP_ALLOW_WEBCONTENT >>

If true, themes are active for controls (buttons etc.) within html
(hosted MSHTML/Internet Explorer) windows.

=back

=head2 SetThemeAppProperties

  SetThemeAppProperties(STAP_ALLOW_NONCLIENT |
                        STAP_ALLOW_CONTROLS  |
                        STAP_ALLOW_WEBCONTENT);

Sets a mask of bits enabling/disabling themes in various parts of the
window.  This call will have no effect on operating systems that don't
support themes, or when the OS has disabled themes for the
application.  Note that in the latter case this call will affect the
return value from C<< GetThemeAppProperties() >>.

Bitmask bits are as for C<< GetThemeAppProperties >>.

=head2 IsThemeActive

  my $themes_globally_enable = IsThemeActive()

Returns a boolean value indicating whether the OS has globally
disabled/enabled visual styles.  The return value may be controlled by
the computer user through visual style settings in the control panel.
If true it does not give any indication whether the application is
actually making use of themed content or not.

=head2 IsAppThemed

  my $themed = IsAppThemed();

Returns a boolean value indicating whether the OS has disabled/enabled
visual styles for the application.  The return value may be controlled
by the computer user within the compatibility tab of the application's
properties - at least on Vista).

=head2 control_styles_active

  if(control_styles_active()) {
    ...
  }

Returns a boolean value that indicates whether styles are actually
active in the client area of the window. Combines the results from
C<< IsThemeActive() >>, C<< IsAppThemed() >>,
C<< GetThemeAppProperties() & STAP_ALLOW_CONTROLS >>, and investigates
whether the current activation context is actually capable of
supporting themes.

=head1 SEE ALSO

MSDN L<http://msdn.microsoft.com> for more information on activation
contexts and manifests, and for detailed descriptions of the Win32 API
calls
C<< GetThemeAppProperties() >>,
C<< SetThemeAppProperties() >>,
C<< IsThemeActive() >>,
C<< IsAppThemed() >>.

=head1 SUPPORT

Contact the author for support.

=head1 AUTHORS

Robert May (C<robertmay@cpan.org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Robert May

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
