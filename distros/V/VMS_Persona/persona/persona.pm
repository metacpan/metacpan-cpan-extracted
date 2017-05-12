package VMS::Persona;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(&new_persona &assume_persona &drop_persona &delete_persona);
$VERSION = '1.01';


bootstrap VMS::Persona $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

VMS::Persona - Create, assume, or drop Personas

=head1 SYNOPSIS

  use VMS::Persona;
  $Persona = new_persona(NAME => $UserName
                         [, ASSUME_DEFPRIV => bool]
                         [, ASSUME_DEFCLASS => bool]);
  $IsOK = assume_persona(PERSONA => $Persona
                           [, ASSUME_SECURITY => bool]
                           [, ASSUME_ACCOUNT => bool]
                           [, ASSUME_JOB_WIDE => bool]);
  $IsOK = drop_persona();
  $IsOK = delete_persona($Persona);

=head1 DESCRIPTION

Create, assume, drop, or delete personas.

=head2 new_persona()

This function creates a new persona context and returns a handle to it. If
ASSUME_DEFPRIV is set to true, then the persona is created with default
privileges. If ASSUME_DEFCLASS is set to true, then the persona is created
with default classification.

=head2 assume_persona()

Assume a persona previously created with C<new_persona>. The
C<ASSUME_SECURITY>, C<ASSUME_ACCOUNT>, and C<ASSUME_JOB_WIDE> parameters
will, if set to true, set the corresponding flags in the C<$PERSONA_ASSUME>
call.

=head2 drop_persona()

Drop the current persona. (This is a convenience interface to the
$PERSONA_ASSUME system service with a persona handle of 1, which discards
the current persona)

=head2 delete_persona()

Delete a previously created persona.

=head1 SECURITY

Standard VMS system security is enforced, which means the process needs
DETACH (IMPERSONATE in VMS 7.1 and up) privilege and read access to the
SYSUAF.

=head1 LIMITATIONS

The persona services first came into VMS in version 6.2, so this module
just won't work on earlier versions of VMS.

The docs for the persona services in the VMS 6.2 and 7.1 docs are a
touch... skimpy. There's no better interpretation here, since I don't have
one.

=head1 ERRORS

The persona services can croak() with some errors. This is a list of them.

=over 4

=item Odd number of items passed

This error is thrown if C<new_persona()> is called with an odd number of
parameters.

=item Invalid parameter passed

Thrown if a bogus name (on the left side of a =>) parameter is passed.

=back

If a VMS error has occured, the functions will return undef, and fill in
$^E with the error code.

=head1 AUTHOR

Dan Sugalski <sugalskd@osshe.edu>

=head1 SEE ALSO

perl(1), I<OpenVMS System Services Reference Manual>

=cut
