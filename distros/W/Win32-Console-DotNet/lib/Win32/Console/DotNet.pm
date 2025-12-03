=pod

=head1 NAME

Win32::Console::DotNet - Win32::Console .NET interface

=head1 SYNOPSIS

Simply integrate this module into your package or script.

  use Win32::Console::DotNet;
  #
  System::Console->WriteLine("The current console title is: \"%s\"",
    System::Console->Title);
  System::Console->WriteLine("\t(Press any key to change the console title.)");
  System::Console->ReadKey(1);
  System::Console->Title( "The title has changed!" );
  System::Console->WriteLine("Note that the new console title is \"%s\"\n".
    "\t(Press any key to quit.)", System::Console->Title);
  System::Console->ReadKey(1);
  #
  # This example produces the following results:
  #     The current console title is: "Command Prompt - perl  samples\Title.pl"
  #         (Press any key to change the console title.)
  #     Note that the new console title is "The title has changed!"
  #         (Press any key to quit.)
  #

Alternatively, using the System namespace.

  use Time::Piece;
  use Win32::Console::DotNet;
  use System;
  #
  Console->Clear();
  my $dat = localtime;
  #
  Console->Write("\nToday is %s at %s.", $dat->mdy, $dat->hms);
  Console->Write("\nPress Enter key to continue... ");
  Console->ReadLine();
  #
  # The example displays output like the following:
  #     Today is 07/30/2024 at 08:32:54.
  #     Press Enter key to continue...
  #

=cut

package Win32::Console::DotNet;

# ------------------------------------------------------------------------
# Boilerplate ------------------------------------------------------------
# ------------------------------------------------------------------------

use 5.014;
use warnings;

# version '...'
our $version = 'v4.6.0';
our $VERSION = 'v0.5.7';
$VERSION = eval $VERSION;

# authority '...'
our $authority = 'github:microsoft';
our $AUTHORITY = 'github:brickpool';

# ------------------------------------------------------------------------
# Used Modules -----------------------------------------------------------
# ------------------------------------------------------------------------

use Carp qw( confess );
use Config;
use Devel::StrictMode;
use Devel::Assert STRICT ? 'on' : '';
use Encode ();
use Encode::Alias ();
use English qw( -no_match_vars );
use IO::File;
use IO::Handle;
use IO::Null;
use List::Util qw(
  first 
  max
);
use Scalar::Util qw( blessed );
use threads;
use threads::shared;
use Win32;
use Win32::Console;
use Win32API::File;

use namespace::clean;

# ------------------------------------------------------------------------
# Encode::Encoding -------------------------------------------------------
# ------------------------------------------------------------------------

# Gets the code page identifier of the current Encoding.
my $CodePage = sub {
  assert ( @_ == 1 );
  my $self = shift;
  assert ( is_Object($self) && $self->isa('Encode::Encoding') );

  my $regex = qr/^cp(\d+)$/;
  my @aliases = grep { 
    /$regex/ && $Encode::Alias::Alias{$_} eq $self;
  } keys(%Encode::Alias::Alias);
  my $element = first { /$regex/ } ( $self->name, @aliases );
  return $element && $element =~ $regex ? 0+ $1 : 0;
};

# Allows additional 'cpXXXX' to be used as an alias for encoding. Encoding may 
# be either the name of an encoding or an encoding object (as described in 
# Encode).
BEGIN {
  # require Encode;
  Encode::Alias::define_alias( cp20127  => 'ascii'  );
  Encode::Alias::define_alias( cp20866  => 'koi8-r' );
  Encode::Alias::define_alias( cp21866  => 'koi8-u' );

  require Encode::Unicode;
  Encode::Alias::define_alias( cp1200   => 'UTF-16LE' );
  Encode::Alias::define_alias( cp1201   => 'UTF-16BE' );
  Encode::Alias::define_alias( cp12000  => 'UTF-32LE' );
  Encode::Alias::define_alias( cp12001  => 'UTF-32BE' );

  require Encode::Byte;
  Encode::Alias::define_alias( qr/^cp2859(\d)$/i  => '"iso-8859-$1"'  );
  Encode::Alias::define_alias( qr/^cp2860(3|5)$/i => '"iso-8859-1$1"' );

  # require Encode::CN;
  Encode::Alias::define_alias( cp51936 => 'euc-cn' );

  # require Encode::JN;
  Encode::Alias::define_alias( cp20932 => 'euc-jp'      );
  Encode::Alias::define_alias( cp50221 => 'iso-2022-jp' );

  # require Encode::KR;
  Encode::Alias::define_alias( cp50225 => 'iso-2022-kr' );
  Encode::Alias::define_alias( cp51949 => 'euc-kr'      );
}

# Allows the use of additional MIME names (stored in Encode::MIME::Name).
BEGIN {
  require Encode::MIME::Name;
  $Encode::MIME::Name::MIME_NAME_OF{ cp932 } ||= 'Windows-31J';
  $Encode::MIME::Name::MIME_NAME_OF{ cp949 } ||= 'Windows-949';
  $Encode::MIME::Name::MIME_NAME_OF{ cp950 } ||= 'Big5';
}

# ------------------------------------------------------------------------
# Class Definition -------------------------------------------------------
# ------------------------------------------------------------------------

=head1 DESCRIPTION

The I<Win32::Console::DotNet> class offers fundamental support for Windows
applications that read from and write to a console.

The I<Win32::Console::DotNet> class is based on the L<Win32::Console> module 
and provides an I<.NET> compatible API. 

The I<.NET> API provides a number of benefits that allow developers to 
effectively create console applications and efficiently manage Windows console 
applications. Here are some of the key features:

=over

=item * B<Windows Console Functions>: 
The I<.NET> API offers a wide range of functions for handling input and 
output, such as reading keyboard inputs and writing text to the screen. These 
low-level functions such as I<ReadConsoleInput>, I<WriteConsoleOutput>, and 
I<SetConsoleCursorPosition> are suitably abstracted by the I<.NET> API.

=item * B<Windows Console Structures>:
Access to low-level data structures such as I<CONSOLE_SCREEN_BUFFER_INFO> or 
I<INPUT_RECORD> is simplified by using the I<.NET> API. These low-level console
structures are effectively managed by this module. 

=item * B<Windows Console Extensions>:
It provides an extended compatibility layer to the classic Windows Console API.
The I<.NET> API provided in this module is well-known and thoroughly 
documented, transforming the otherwise complex Windows Console API into a 
powerful tool for developing Windows console applications. 

=back

B<To summarize>: The I<.Net> API provides easy direct access to console 
windows and allows detailed control over display and interaction, making your 
applications based on the classic Windows console API more robust and 
therefore better.

B<Note>: I<System::Console> is the singleton class that represents the 
I<Win32::Console::DotNet> console applications. You can take a closer look at 
the use of I<System::Console> in the examples provided.

=head2 Class

public class I<< Win32::Console::DotNet >>

Object Hierarchy

  UNIVERSAL
    Win32::Console::DotNet

=cut

package Win32::Console::DotNet {

  # ------------------------------------------------------------------------
  # Type Constraints -------------------------------------------------------
  # ------------------------------------------------------------------------

  no namespace::clean;

=begin private

=head2 Type Checks

Basic type checks

This module use the following type checks:

    is_Bool
    is_ClassName
    is_FileHandle
    is_Object
    is_Str

I<Note>: if L<Type::Tiny> is present, the L<Type::Standard> functions are used.

This module has the following assert type checks:

    assert_Bool
    assert_ArrayRef
    assert_CodeRef
    assert_FileHandle
    assert_Int
    assert_Object
    assert_Str

=over

=cut

BEGIN { eval { require Types::Standard } }

=item I<is_Bool>

  sub is_Bool($value) : Bool

Check for a reasonable boolean value. Accepts C<1>, C<0>, the empty string and 
C<undef>.

I<Param>: C<$value> to be checked.

I<Returns>: I<true> if operand is boolean.

=cut

  sub is_Bool($) {
    # Taken from Types::Nano
    return !defined($_[0]) 
      || !ref($_[0]) && { 1 => 1, 0 => 1, '' => 1 }->{$_[0]};
  };
  if ( exists &Types::Standard::is_Bool ) {
    no warnings qw( redefine prototype );
    *is_Bool = \&Types::Standard::is_Bool;
  }

=item I<is_ClassName>

  sub is_ClassName ($value) : Bool

Check for a name of a loaded package. The package must have C<@ISA> or 
C<$VERSION> defined.

I<Param>: C<$value> to be checked.

I<Returns>: I<true> if I<$value> is name of a valid package.

=cut

  sub is_ClassName($) {
    # Taken from Types::Standard
    assert ( @_ == 1 );
    my $stash = do {
      no strict 'refs';
      \%{ $_[0] . '::' };
    };
    return !!1 
      if exists $stash->{ISA} 
      || exists $stash->{VERSION};
    foreach my $globref ( values %{$stash} ) {
      return !!1
        if ref(\$globref) eq 'GLOB' 
          ? *{$globref}{CODE}
          : ref($globref);
    }
    return !!0;
  };
  if ( exists &Types::Standard::is_ClassName ) {
    no warnings qw( redefine prototype );
    *is_ClassName = \&Types::Standard::is_ClassName;
  }

=item I<is_FileHandle>

  sub is_FileHandle($value) : Bool

Check for a file handle.

I<Param>: C<$value> to be checked.

I<Returns>: I<true> if I<$value> is a file handle.

=cut

  sub is_FileHandle($) {
    # Taken from Params::Util::PP
    return
      (ref($_[0]) eq 'GLOB')
        || 
      (tied($_[0]) && tied($_[0])->can('TIEHANDLE'))
        || 
      (blessed($_[0]) && $_[0]->isa('IO::Handle'))
        || 
      (blessed($_[0]) && $_[0]->isa('Tie::Handle'))
  }
  if ( exists &Types::Standard::is_FileHandle ) {
    no warnings qw( redefine prototype );
    *is_FileHandle = \&Types::Standard::is_FileHandle;
  }

=item I<is_Object>

  sub is_Object($value) : Bool

Check for a blessed object.

I<Param>: C<$value> to be checked.

I<Returns>: I<true> if I<$value> is blessed.

=cut

  sub is_Object($) {
    goto &Scalar::Util::blessed;
  }
  if ( exists &Types::Standard::is_Object ) {
    no warnings qw( redefine prototype );
    *is_Object = \&Types::Standard::is_Object;
  }

=item I<is_Str>

  sub is_Str($value) : Bool

Check for a string.

I<Param>: C<$value> to be checked.

I<Returns>: I<true> if I<$value> is a string.

=cut

  sub is_Str($) {
    return defined($_[0]) && !ref($_[0]);
  }
  if ( exists &Types::Standard::is_Str ) {
    no warnings qw( redefine prototype );
    *is_Str = \&Types::Standard::is_Str;
  }

=item I<get_message>

  classmethod $get_message(Any $value) : Str;

Generates an error message for an C<assert_*> exception.

I<Param>: C<$value> to be checked.

I<Returns>: an error message string.

=cut

  # code snippet from Type::Nano
  my $get_message = sub {
    my ($name, $value) = (shift, @_);
    
    require B;
    !defined($value)
      ? sprintf("Undef did not pass type constraint %s", $name)
      : ref($value)
        ? sprintf("Reference %s did not pass type constraint %s", $value, $name)
        : sprintf("Value %s did not pass type constraint %s", 
          B::perlstring($value), $name);
  };

=item I<assert_Bool>

  sub assert_Bool($value) : Bool

Check the boolean value. Accepts C<1>, C<0>, the empty string (C<''> or C<"">) 
and C<undef>.

I<Param>: C<$value> to be checked.

I<Returns>: C<$value> if the C<$value> is boolean.

I<Throws>: I<IllegalArgumentException> if the check fails.

=cut

  sub assert_Bool($) {
    confess(sprintf("IllegalArgumentException: %s\n", 
      'Bool'->$get_message($_[0]))) 
        if STRICT and !is_Bool($_[0]);
    return $_[0];
  }

=item I<assert_ArrayRef>

  sub assert_ArrayRef($ref) : ArrayRef

Check the array reference.

I<Param>: C<$ref> to be checked.

I<Returns>: C<$ref> if operand is an array reference.

I<Throws>: I<IllegalArgumentException> if the check fails.

=cut

  sub assert_ArrayRef($) {
    confess(sprintf("IllegalArgumentException: %s\n", 
      'ArrayRef'->$get_message($_[0])))
        if STRICT and !(ref($_[0]) eq 'ARRAY');
    return $_[0];
  }

=item I<assert_CodeRef>

  sub assert_CodeRef($ref) : CodeRef

Check the code reference.

I<Param>: C<$ref> to be checked.

I<Returns>: C<$ref> if operand is a code reference.

I<Throws>: I<IllegalArgumentException> if the check fails.

=cut

  sub assert_CodeRef($) {
    confess(sprintf("IllegalArgumentException: %s\n", 
      'CodeRef'->$get_message($_[0])))
        if STRICT and !(ref($_[0]) eq 'CODE');
    return $_[0];
  }

=item I<assert_FileHandle>

  sub assert_FileHandle($value) : FileHandle

Check for a file handle.

I<Param>: C<$value> to be checked.

I<Returns>: C<$value> if C<$value> is a file handle.

I<Throws>: I<IllegalArgumentException> if the check fails.

=cut

  sub assert_FileHandle($) {
    confess(sprintf("IllegalArgumentException: %s\n", 
      'FileHandle'->$get_message($_[0])))
        if STRICT and !is_FileHandle($_[0]);
    return $_[0];
  }

=item I<assert_Int>

  sub assert_Int($value) : Int

Check for on integer; strict constaint.

I<Param>: C<$value> to be checked.

I<Returns>: C<$value> if the C<$value> is an integer.

I<Throws>: I<IllegalArgumentException> if the check fails.

=cut

  sub assert_Int($) {
    confess(sprintf("IllegalArgumentException: %s\n", 
      'Int'->get_message($_[0])))
        if STRICT 
        and !(defined($_[0]) && !ref($_[0]) && $_[0] =~ /\A[+-]?\d+\z/);
    return $_[0];
  }

=item I<assert_Object>

  sub assert_Object($value) : Object

Check for a blessed object.

I<Param>: C<$value> to be checked.

I<Returns>: C<$value> if C<$value> is blessed.

I<Throws>: I<IllegalArgumentException> if the check fails.

=cut

  sub assert_Object($) {
    confess(sprintf("IllegalArgumentException: %s\n", 
      'Object'->$get_message($_[0])))
        if STRICT and !is_Object($_[0]);
    return $_[0];
  }

=item I<assert_Str>

  sub assert_Str($value) : Str

Check the string that cannot be stringified.

I<Param>: C<$value> to be checked.

I<Returns>: C<$value> if the C<$value> is a string.

I<Throws>: I<IllegalArgumentException> if the check fails.

=cut

  sub assert_Str($) {
    confess(sprintf("IllegalArgumentException: %s\n", 
      'Str'->get_message($_[0])))
        if STRICT and !is_Str($_[0]);
    return $_[0];
  }

=back

=end private

=cut

  # ------------------------------------------------------------------------
  # Constants --------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Constants

=begin private

=over

=item I<_DEBUG>

  use constant _DEBUG => 1|undef;

C<_DEBUG> is defined as 1 if the environment variable C<NDEBUG> or 
C<PERL_NDEBUG> is not defined as I<true> and the environment variable 
C<EXTENDED_TESTING> has been set to I<true>, otherwise undefined.

=cut

use constant _DEBUG => (  $ENV{EXTENDED_TESTING} 
                      && !$ENV{NDEBUG} 
                      && !$ENV{PERL_NDEBUG}
                    ) ? 1 : undef;

=item I<TRUE>

=item I<FALSE>

  use constant {
    TRUE  => !! 1,
    FALSE => !! '',
  };

Defines C<TRUE> and C<FALSE> constants.

I<See also>: L<constant::boolean>

=cut

  use constant {
    TRUE  => !! 1,
    FALSE => !! '',
  };

=item I<DefaultConsoleBufferSize>

  use constant DefaultConsoleBufferSize => 256;

Defines the standard console buffer size.

=cut

  use constant DefaultConsoleBufferSize => 256;

=item I<MinBeepFrequency>

=item I<MaxBeepFrequency>

  use constant {
    MinBeepFrequency  => 0x25,
    MaxBeepFrequency  => 0x7fff,
  };

Beep range - see MSDN.

=cut

  use constant {
    MinBeepFrequency  => 0x25,
    MaxBeepFrequency  => 0x7fff,
  };

=item I<MaxConsoleTitleLength>

  use constant MaxConsoleTitleLength => 24500;

MSDN says console titles can be up to 64 KB in length.
But I get an exception if I use buffer lengths longer than
~24500 Unicode characters.  Oh well.

=cut

  use constant MaxConsoleTitleLength => 24500;

=item I<StdConUnicodeEncoding>

  use constant StdConUnicodeEncoding => Encode::find_encoding('UTF-16');

The value corresponds to the Windows code pages 1200 (little endian byte 
order) or 1201 (big endian byte order).

=cut

  use constant StdConUnicodeEncoding => Encode::find_encoding('cp120' . 
    ($Config{byteorder} & 0b1));

=back

=end private

=over

=item I<WinError.h>

  use constant Win32Native::ERROR_INVALID_HANDLE => 0x6;

C<ERROR_INVALID_HANDLE> is a predefined constant that is used to represent a 
value that is passed to or returned by one or more built-in functions.

=cut

  sub Win32Native::ERROR_INVALID_HANDLE() { 0x6 };

=begin private

=item I<Winuser.h>

  use constant {
    AltVKCode         => 0x12,
    NumberLockVKCode  => 0x90,
    CapsLockVKCode    => 0x14,
  };

  use constant {
    VK_CLEAR    => 0x0c,
    VK_SHIFT    => 0x10,
    VK_PRIOR    => 0x21,
    VK_NEXT     => 0x22,
    VK_INSERT   => 0x2d,
    VK_NUMPAD0  => 0x60,
    VK_NUMPAD9  => 0x69,
    VK_SCROLL   => 0x91,
  };

Virtual-Key Codes from I<Winuser.h>

=cut

  use constant {
    AltVKCode         => 0x12,
    NumberLockVKCode  => 0x90,  # virtual key code
    CapsLockVKCode    => 0x14,
  };

  use constant {
    VK_CLEAR    => 0x0c,
    VK_SHIFT    => 0x10,
    VK_PRIOR    => 0x21,
    VK_NEXT     => 0x22,
    VK_INSERT   => 0x2d,
    VK_NUMPAD0  => 0x60,
    VK_NUMPAD9  => 0x69,
    VK_SCROLL   => 0x91,
  };

=end private

=item I<WinCon.h>

  use constant Win32Native::KEY_EVENT => 0x0001;

The Event member contains a I<KEY_EVENT_RECORD> structure with information 
about a keyboard event.

=cut

  sub Win32Native::KEY_EVENT() { 0x0001 };

=begin private

  use constant {
    eventType       => 0,
    keyDown         => 1,
    repeatCount     => 2,
    virtualKeyCode  => 3,
    virtualScanCode => 4,
    uChar           => 5,
    controlKeyState => 6,
  };

Constants for accessing the input event array which is used for the console 
input buffer API calls.

I<See also>: I<KEY_EVENT_RECORD> structure.

=cut

  use constant {
    eventType       => 0,
    keyDown         => 1,
    repeatCount     => 2,
    virtualKeyCode  => 3,
    virtualScanCode => 4,
    uChar           => 5,
    controlKeyState => 6,
  };

=pod

  use constant {
    dwSizeX               => 0,
    dwSizeY               => 1,
    dwCursorPositionX     => 2,
    dwCursorPositionY     => 3,
    wAttributes           => 4,
    srWindowLeft          => 5,
    srWindowTop           => 6,
    srWindowRight         => 7,
    srWindowBottom        => 8,
    dwMaximumWindowSizeX  => 9,
    dwMaximumWindowSizeY  => 10,
  };

Constants for accessing the console screen buffer array which contains 
information about a console screen buffer.

I<See also>: I<CONSOLE_SCREEN_BUFFER_INFO> structure.

=cut

  use constant {
    dwSizeX               => 0,
    dwSizeY               => 1,
    dwCursorPositionX     => 2,
    dwCursorPositionY     => 3,
    wAttributes           => 4,
    srWindowLeft          => 5,
    srWindowTop           => 6,
    srWindowRight         => 7,
    srWindowBottom        => 8,
    dwMaximumWindowSizeX  => 9,
    dwMaximumWindowSizeY  => 10,
  };

=pod

  use constant {
    dwSize    => 0,
    bVisible  => 1,
  };

Constants for accessing the console cursor info array which contains information 
about the console cursor.

I<See also>: I<CONSOLE_CURSOR_INFO> structure.

=cut

  use constant {
    dwSize    => 0,
    bVisible  => 1,
  };

=end private

=back

=cut

  use namespace::clean;

  # ------------------------------------------------------------------------
  # Variables --------------------------------------------------------------
  # ------------------------------------------------------------------------

=begin private

=head2 Variables

=over

=item <_instance>

  my $_instance ( is => private, type => Object );

The instance reference is stored in the C<$_instance> scalar.

=cut

  my $_instance = undef;


=item I<_in>

  my $_in ( is => private, type => FileHandle );

For L</In>

=item I<_out>

  my $_out ( is => private, type => FileHandle );

For L</Out>

=item I<_error>

  my $_error ( is => private, type => FileHandle ):

For L</Error>

=cut

  my $_in;
  my $_out;
  my $_error;

=item I<_cachedInputRecord>

  my $_cachedInputRecord ( is => private, type => ArrayRef ) = [(-1)];

For L</ReadKey>

=cut

  # ReadLine & Read can't use this because they need to use ReadFile
  # to be able to handle redirected input.  We have to accept that
  # we will lose repeated keystrokes when someone switches from
  # calling ReadKey to calling Read or ReadLine.  Those methods should 
  # ideally flush this cache as well.
  my $_cachedInputRecord = [(-1)];

=item I<_haveReadDefaultColors>

  my $_haveReadDefaultColors ( is => private, type => Bool );

For L</ResetColor>

=cut

  my $_haveReadDefaultColors;

=item I<_defaultColors>

  my $_defaultColors ( is => private, type => Ref[Int] );

Reference value of L<$ATTR_NORMAL|Win32::Console>, used for L</ResetColor>. 

=cut

  my $_defaultColors = \$ATTR_NORMAL;

=item I<_isOutTextWriterRedirected>

  my $_isOutTextWriterRedirected ( is => private, type => Bool ) = FALSE;

For L</OutputEncoding>

=item I<_isErrorTextWriterRedirected>

  my $_isErrorTextWriterRedirected ( is => private, type => Bool ) = FALSE;

For L</OutputEncoding>

=cut

  my $_isOutTextWriterRedirected = FALSE;
  my $_isErrorTextWriterRedirected = FALSE;

=item I<_inputEncoding>

  my $_inputEncoding ( is => private, type => Int );

For L</InputEncoding>

=item I<_outputEncoding>

  my $_outputEncoding ( is => private, type => Int );

For L</OutputEncoding>

=cut

  my $_inputEncoding;
  my $_outputEncoding;

=item I<_stdInRedirectQueried>

  my $_stdInRedirectQueried ( is => private, type => Bool ) = FALSE;

For L</IsInputRedirected>

=item I<_stdOutRedirectQueried>

  my $_stdOutRedirectQueried ( is => private, type => Bool ) = FALSE;

For L</IsOutputRedirected>

=item I<_stdErrRedirectQueried>

  my $_stdErrRedirectQueried ( is => private, type => Bool ) = FALSE;

For L</IsErrorRedirected>

=cut

  my $_stdInRedirectQueried = FALSE;
  my $_stdOutRedirectQueried = FALSE;
  my $_stdErrRedirectQueried = FALSE;

=item I<_isStdInRedirected>

  my $_isStdInRedirected ( is => private, type => Bool );

For L</IsInputRedirected>

=item I<_isStdOutRedirected>

  my $_isStdOutRedirected ( is => private, type => Bool );

For L</IsOutputRedirected>

=item I<_isStdErrRedirected>

  my $_isStdErrRedirected ( is => private, type => Bool );

For L</IsErrorRedirected>

=cut

  my $_isStdInRedirected;
  my $_isStdOutRedirected;
  my $_isStdErrRedirected;

=item I<InternalSyncObject>

  my $InternalSyncObject ( is => private, type => Any );

Private variable for locking instead of locking on a public type for SQL 
reliability work.

Use this for internal synchronization during initialization, wiring up events,
or for short, non-blocking OS calls.

=item I<ReadKeySyncObject>

  my $ReadKeySyncObject ( is => private, type => Any );

Use this for blocking in Console->ReadKey, which needs to protect itself in 
case multiple threads call it simultaneously.

Use a L</ReadKey>-specific lock though, to allow other fields to be 
initialized on this type.

=cut

  my $InternalSyncObject :shared;
  my $ReadKeySyncObject :shared;

=item I<_consoleInputHandle>

  my $_consoleInputHandle ( is => private, type => Int );

Holds the output handle of the console.

=item I<_consoleOutputHandle>

  my $_consoleOutputHandle ( is => private, type => Int );

Holds the input handle of the console.

=cut

  # About reliability: I'm not using SafeHandle here.  We don't 
  # need to close these handles, and we don't allow the user to close
  # them so we don't have many of the security problems inherent in
  # something like file handles.  Additionally, in a host like SQL 
  # Server, we won't have a console.
  my $_consoleInputHandle;
  my $_consoleOutputHandle;

=item I<_leaveOpen>

  my $_leaveOpen ( is => private, type => HashRef ) = {};

If a file handle needs to be protected against automatic closing (when leaving 
the scope), the associated parameter C<$ownsHandle> is set to I<false> when 
L</SafeFileHandle> is called.

To leave the file handle open, we save the L<IO::Handle> object in this hash 
so that the C<REFCNT> is C<< > 0 >>.

=cut

  my $_leaveOpen = {};

=item I<ResourceString>

  my %ResourceString ( is => private, type => Hash ) = (...);

This hash variable contains all resource strings that are used here in this 
package.

=cut

  my %ResourceString = (
    ArgumentNullException =>
      "Value cannot be null. Parameter name: %s",
    Arg_InvalidConsoleColor =>
      "The ConsoleColor enum value was not defined on that enum. Please ".
      "use a defined color from the enum.",
    ArgumentOutOfRange_BeepFrequency =>
      "Console->Beep's frequency must be between between %d and %d.",
    ArgumentOutOfRange_ConsoleBufferBoundaries =>
      "The value must be greater than or equal to zero and less than the ".
      "console's buffer size in that dimension.",
    ArgumentOutOfRange_ConsoleBufferLessThanWindowSize =>
      "The console buffer size must not be less than the current size and ".
      "position of the console window, nor greater than or equal to 32767.",
    ArgumentOutOfRange_CursorSize =>
      "The cursor size is invalid. It must be a percentage between 1 and 100.",
    ArgumentOutOfRange_ConsoleTitleTooLong
      => "The console title is too long.",
    ArgumentOutOfRange_ConsoleWindowBufferSize =>
      "The new console window size would force the console buffer size to be ".
      "too large.",
    ArgumentOutOfRange_ConsoleWindowPos =>
      "The window position must be set such that the current window size fits ".
      "within the console's buffer, and the numbers must not be negative.",
    ArgumentOutOfRange_ConsoleWindowSize_Size =>
      "The value must be less than the console's current maximum window size ".
      "of %d in that dimension. Note that this value depends on screen ".
      "resolution and the console font.",
    ArgumentOutOfRange_NeedPosNum =>
      "Positive number required.",
    ArgumentOutOfRange_NeedNonNegNum =>
      "Non-negative number required.",
    InvalidOperation_ConsoleKeyAvailableOnFile =>
      "Cannot see if a key has been pressed when either application does not ".
      "have a console or when console input has been redirected from a file.",
    InvalidOperation_ConsoleReadKeyOnFile =>
      "Cannot read keys when either application does not have a console or ".
      "when console input has been redirected. Try Console->Read.",
    IO_NoConsole =>
      "There is no console.",
  );

=back

=end private

=cut

  # ------------------------------------------------------------------------
  # Attributes -------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Attributes

=over

=item I<BackgroundColor>

  field BackgroundColor ( is => rw, type => Int,
    default => $Win32::Console::BG_BLACK >> 4 );

A Color that specifies the background color of the console; that is, the color 
that appears behind each character.  The default is black.

I<Throws>: I<ArgumentException> if the color specified in a set operation is not
valid.

=cut

  sub BackgroundColor {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $succeeded;
      my $csbi = GetBufferInfo(FALSE, \$succeeded);

      # For code that may be used from Windows app w/ no console
      if ( !$succeeded ) {
        my $BLACK = ($BG_BLACK & 0xf0) >> 4;
        return $BLACK;
      }

      my $c = $csbi->{wAttributes} & 0xf0;
      my $value = ColorAttributeToConsoleColor($c);
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      if ( $value < 0 || $value > 15 ) {
        confess("ArgumentException:\n".
          "$ResourceString{Arg_InvalidConsoleColor}\n");
      }
      my $c = ConsoleColorToColorAttribute($value, TRUE);

      my $succeeded;
      my $csbi = GetBufferInfo(FALSE, \$succeeded);
      # For code that may be used from Windows app w/ no console
      return if !$succeeded;

      assert ( $_haveReadDefaultColors 
        or ~- warn "Setting the background color before we've read the ".
                   "default background color!"
      );

      my $attr = $csbi->{wAttributes};
      $attr &= ~0xf0;
      # Perl's bitwise-or.
      $attr = $attr | $c;
      # Ignore errors here - there are some scenarios for running code that 
      # wants to print in colors to the console in a Windows application.
      Win32::Console::_SetConsoleTextAttribute(ConsoleOutputHandle(), $attr);
      return;
    }
  };

=item I<BufferHeight>

  field BufferHeight ( is => rw, type => Int );

The current height, in rows, of the buffer area.

I<Throws>: I<ArgumentOutOfRangeException> if the value in a set operation is 
less than or equal to zero or greater than or equal to C<0x7fff> or less than 
L</WindowTop> + L</WindowHeight>.

I<Throws>: I<IOException> if an I/O error occurred.

=cut

  sub BufferHeight {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
      my $value = $csbi->{dwSize}->{Y};
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      $self->SetBufferSize($self->BufferWidth, $value);
      return;
    }
  };

=item I<BufferWidth>

  field BufferWidth ( is => rw, type => Int );

The current width, in columns, of the buffer area.

I<Throws>: I<ArgumentOutOfRangeException> if the value in a set operation is 
less than or equal to zero or greater than or equal to C<0x7fff> or less than 
L</WindowLeft> + L</WindowWidth>.

=cut

  sub BufferWidth {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
      my $value = $csbi->{dwSize}->{X};
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      $self->SetBufferSize($value, $self->BufferHeight);
      return;
    }
  };

=item I<CapsLock>

  field CapsLock ( is => ro, type => Bool );

Gets a value indicating whether the C<CAPS LOCK> keyboard toggle is turned on 
or turned off.

=cut

  sub CapsLock {
    assert ( @_ == 1 );
    my $self = assert_Object shift;
    GET: {
      require Win32Native;
      my $value = (Win32Native::GetKeyState(CapsLockVKCode) & 1) == 1;
      return assert_Bool $value;
    }
  };

=item I<CursorLeft>

  field CursorLeft ( is => rw, type => Int );

The column position of the cursor within the buffer area.

I<Throws>: I<ArgumentOutOfRangeException> if the value in a set operation is 
less than zero or greater than or equal to L</BufferWidth>.

=cut

  sub CursorLeft {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
      my $value = $csbi->{dwCursorPosition}->{X};
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      $self->SetCursorPosition($value, $self->CursorTop);
      return;
    }
  };

=item I<CursorSize>

  field CursorSize ( is => rw, type => Int );

The height of the cursor within a character cell.

The size of the cursor expressed as a percentage of the height of a character 
cell. The property value ranges from C<1> to C<100>.

I<Throws>: I<ArgumentOutOfRangeException> if the value specified in a set 
operation is less than C<1> or greater than C<100>.

=cut

  sub CursorSize {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my @cci;
      my $hConsole = ConsoleOutputHandle();
      my $r = do {
        @cci = Win32::Console::_GetConsoleCursorInfo($hConsole);
        @cci > 1;
      };
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n")
      }
      my $value = $cci[dwSize];
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      if ( $value < 1 || $value > 100 ) {
        confess("ArgumentOutOfRangeException: value $value\n". 
          "$ResourceString{ArgumentOutOfRange_CursorSize}\n");
      }

      my @cci;
      my $hConsole = ConsoleOutputHandle();
      my $r = do {
        @cci = Win32::Console::_GetConsoleCursorInfo($hConsole);
        @cci > 1;
      };
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n")
      }

      $cci[dwSize] = $value;
      $r = Win32::Console::_SetConsoleCursorInfo($hConsole, @cci);
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n")
      }
      return;
    }
  };

=item I<CursorTop>

  field CursorTop ( is => rw, type => Int );

The row position of the cursor within the buffer area.

I<Throws>: I<ArgumentOutOfRangeException> if the value in a set operation is 
less than zero or greater than or equal to L</BufferHeight>.

=cut

  sub CursorTop {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
      my $value = $csbi->{dwCursorPosition}->{Y};
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      $self->SetCursorPosition($self->CursorLeft, $value);
      return;
    }
  };

=item I<CursorVisible>

  field CursorVisible ( is => rw, type => Bool );

The attribute indicating whether the cursor is visible.

I<True> if the cursor is visible; otherwise, I<false>.

=cut

  sub CursorVisible {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my @cci;
      my $hConsole = ConsoleOutputHandle();
      my $r = do {
        @cci = Win32::Console::_GetConsoleCursorInfo($hConsole);
        @cci > 1;
      };
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n")
      }
      my $value = $cci[bVisible];
      return assert_Bool $value;
    }
    SET: {
      my $value = assert_Bool shift;

      my @cci;
      my $hConsole = ConsoleOutputHandle();
      my $r = do {
        @cci = Win32::Console::_GetConsoleCursorInfo($hConsole);
        @cci > 1;
      };
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n")
      }

      $cci[bVisible] = $value;
      $r = Win32::Console::_SetConsoleCursorInfo($hConsole, @cci);
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n")
      }
      return;
    }
  };

=item I<Error>

  field Error ( is => ro, type => FileHandle );

A I<FileHandle> that represents the standard error stream.

=cut

  sub Error {
    assert ( @_ == 1 );
    my $self = assert_Object shift;
    GET: {
      if ( !defined $_error ) {
        InitializeStdOutError(FALSE);
      }
      return $_error;
    }
  };

=item I<ForegroundColor>

  field ForegroundColor ( is => rw, type => Int, 
    default => $Win32::Console::FG_LIGHTGRAY);

Color that specifies the foreground color of the console; that is, the color
of each character that is displayed. The default is gray.

I<Throws>: I<ArgumentException> if the color specified in a set operation is not
valid.

=cut

  sub ForegroundColor {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $succeeded;
      my $csbi = GetBufferInfo(FALSE, \$succeeded);

      # For code that may be used from Windows app w/ no console
      if ( !$succeeded ) {
        return $FG_LIGHTGRAY;
      }

      my $c = $csbi->{wAttributes} & 0x0f;
      my $value = ColorAttributeToConsoleColor($c);
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      if ( $value < 0 || $value > 15 ) {
        confess("ArgumentException:\n".
          "$ResourceString{Arg_InvalidConsoleColor}\n");
      }
      my $c = ConsoleColorToColorAttribute($value, FALSE);

      my $succeeded;
      my $csbi = GetBufferInfo(FALSE, \$succeeded);
      # For code that may be used from Windows app w/ no console
      return if !$succeeded;

      assert ( $_haveReadDefaultColors 
        or ~- warn "Setting the foreground color before we've read the ".
                   "default foreground color!"
      );

      my $attr = $csbi->{wAttributes};
      $attr &= ~0x0f;
      # Perl's bitwise-or.
      $attr = $attr | $c;
      # Ignore errors here - there are some scenarios for running code that 
      # wants to print in colors to the console in a Windows application.
      Win32::Console::_SetConsoleTextAttribute(ConsoleOutputHandle(), $attr);
      return;
    }
  };

=item I<In>

  field In ( is => ro, type => FileHandle );

A I<FileHandle> that represents the standard input stream.

=cut

  sub In {
    assert ( @_ == 1 );
    my $self = assert_Object shift;
    GET: {
      # Because most applications don't use stdin, we can delay 
      # initialize it slightly better startup performance.
      if ( !defined $_in ) {
        lock($InternalSyncObject);
        # Set up Console->In
        my $s = __PACKAGE__->OpenStandardInput();
        my $reader;
        if ( !$s ) {
          $reader = IO::Null->new();
        } else {
          my $enc = __PACKAGE__->InputEncoding;
          my $cpi = $enc->$CodePage() || Win32::GetConsoleCP();
          $reader = IO::File->new_from_fd(fileno($s), 'r');
          $reader->binmode(":encoding(cp$cpi)");
        }
        $_in = assert_FileHandle $reader;
      }
      return $_in;
    }
  };

=item I<InputEncoding>

  field InputEncoding ( is => rw, type => Object );
  class_has InputEncoding ( is => rw, isa => Object, init_arg => undef );

Gets or sets the encoding the console uses to write input.

I<Remarks>: A get operation may return a cached value instead of the console's 
current input encoding.

=cut

  sub InputEncoding {
    assert ( @_ >= 1 && @_ <= 2 );
    my $caller = shift;

    assert ( $caller );
    assert ( is_Object($caller) || is_ClassName($caller) );

    goto SET if @_;
    GET: {
      return $_inputEncoding
        if $_inputEncoding;

      {
        lock($InternalSyncObject);

        return $_inputEncoding
          if $_inputEncoding;

        my $cp = Win32::GetConsoleCP() || Win32::GetACP();
        $_inputEncoding = Encode::find_encoding("cp$cp");
        return $_inputEncoding;
      }
    }
    SET: {
      if ( !defined $_[0] ) {
        confess("ArgumentNullException:\n". 
          sprintf("$ResourceString{ArgumentNullException}\n", "value"));
      }
      my $value = assert_Object shift;

      {
        lock($InternalSyncObject);

        if ( !IsStandardConsoleUnicodeEncoding($value) ) {
          my $cp = $value->$CodePage();
          my $r = Win32::SetConsoleCP($cp);
          if ( !$r ) {
            warn("WinIOError:\n$EXTENDED_OS_ERROR\n");
          }
        }

        $_inputEncoding = $value;

        # We need to reinitialize Console->In in the next call to _in
        # This will discard the current FileHandle, potentially 
        # losing buffered data
        $_in = undef;
        return;
      }
    }
  };

=item I<IsErrorRedirected>

  field IsErrorRedirected ( is => ro, type => Bool );
  class_has IsErrorRedirected ( is => ro, type => Bool, init_arg => undef );

Gets a value that indicates whether error has been redirected from the 
standard error stream. I<True> if error is redirected; otherwise, I<false>.

=cut

  sub IsErrorRedirected {
    assert ( @_ == 1 );
    my $caller = shift;

    assert ( $caller );
    assert ( is_Object($caller) || is_ClassName($caller) );

    GET: {
      return $_isStdErrRedirected
        if $_stdErrRedirectQueried;

      {  
        lock($InternalSyncObject);

        return $_isStdErrRedirected
          if $_stdErrRedirectQueried;

        my $errHndle = Win32::Console::_GetStdHandle(STD_ERROR_HANDLE);
        $_isStdErrRedirected = IsHandleRedirected($errHndle);
        $_stdErrRedirectQueried = TRUE;

        return $_isStdErrRedirected;
      }
    }
  };

=item I<IsInputRedirected>

  field IsInputRedirected ( is => ro, type => Bool );
  class_has IsInputRedirected ( is => ro, type => Bool, init_arg => undef );

Gets a value that indicates whether input has been redirected from the 
standard input stream. I<True> if input is redirected; otherwise, I<false>.

=cut

  sub IsInputRedirected {
    assert ( @_ == 1 );
    my $caller = shift;

    assert ( $caller );
    assert ( is_Object($caller) || is_ClassName($caller) );

    GET: {
      return $_isStdInRedirected
        if $_stdInRedirectQueried;

      {
        lock($InternalSyncObject);

        return $_isStdInRedirected
          if $_stdInRedirectQueried;

        $_isStdInRedirected = IsHandleRedirected(ConsoleInputHandle());
        $_stdInRedirectQueried = TRUE;

        return $_isStdInRedirected;
      }
    }
  };

=item I<IsOutputRedirected>

  field IsOutputRedirected ( is => ro, type => Bool );
  class_has IsOutputRedirected ( is => ro, type => Bool, init_arg => undef );

Gets a value that indicates whether output has been redirected from the 
standard output stream. I<True> if output is redirected; otherwise, I<false>.

=cut

  sub IsOutputRedirected {
    assert ( @_ == 1 );
    my $caller = shift;

    assert ( $caller );
    assert ( is_Object($caller) || is_ClassName($caller) );

    GET: {
      return $_isStdOutRedirected
        if $_stdOutRedirectQueried;

      {
        lock($InternalSyncObject);

        return $_isStdOutRedirected
          if $_stdOutRedirectQueried;

        $_isStdOutRedirected = IsHandleRedirected(ConsoleOutputHandle());
        $_stdOutRedirectQueried = TRUE;

        return $_isStdOutRedirected;
      }
    }
  };

=item I<KeyAvailable>

  field KeyAvailable ( is => ro, type => Bool );

Gets a value indicating whether a key press is available in the input stream.

=cut

  sub KeyAvailable {
    assert ( @_ == 1 );
    my $self = assert_Object shift;
    GET: {
      if ( $_cachedInputRecord->[eventType] == Win32Native::KEY_EVENT ) {
        return TRUE;
      }

      my @ir;
      my $numEventsRead = 0;
      while (TRUE) {
        my $r = do {
          @ir = Win32::Console::_PeekConsoleInput(ConsoleInputHandle());
          my $r = @ir != 1;
          $numEventsRead = @ir > 1 ? 1 : 0;
          @ir = (0) x 6 unless $ir[0];
          $r;
        };
        if ( !$r ) {
          my $errorCode = Win32::GetLastError();
          if ( $errorCode == Win32Native::ERROR_INVALID_HANDLE ) {
            confess("InvalidOperationException:\n". 
              "$ResourceString{InvalidOperation_ConsoleKeyAvailableOnFile}". 
              "\n");
          }
          confess("WinIOError: stdin\n$EXTENDED_OS_ERROR\n");
        }

        if ( $numEventsRead == 0 ) {
          return FALSE;
        }

        # Skip non key-down && mod key events.
        if ( !IsKeyDownEvent(\@ir) || IsModKey(\@ir) ) {
          #

          $r = do {
            @ir = Win32::Console::_ReadConsoleInput(ConsoleInputHandle());
            my $r = @ir > 1;
            $numEventsRead = @ir > 1 ? 1 : 0;
            @ir = (0) x 6 unless $ir[0];
            $r;
          };

          if ( !$r ) {
            confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
          }
        } 
        else {
          return TRUE;
        }
      }
    }
  };

=item I<LargestWindowHeight>

  field LargestWindowHeight ( is => ro, type => Int );

Gets the largest possible number of console window rows, based on the current 
font and screen resolution.

=cut

  sub LargestWindowHeight {
    assert ( @_ == 1 );
    my $self = assert_Object shift;
    GET: {
      # Note this varies based on current screen resolution and 
      # current console font.  Do not cache this value.
      my (undef, $bounds_Y) = Win32::Console::_GetLargestConsoleWindowSize(
        ConsoleOutputHandle());
      return assert_Int $bounds_Y;
    }
  };

=item I<LargestWindowWidth>

  field LargestWindowWidth ( is => ro, type => Int );

Gets the largest possible number of console window columns, based on the 
current font and screen resolution.

=cut

  sub LargestWindowWidth {
    assert ( @_ == 1 );
    my $self = assert_Object shift;
    GET: {
      # Note this varies based on current screen resolution and 
      # current console font.  Do not cache this value.
      my ($bounds_X) = Win32::Console::_GetLargestConsoleWindowSize(
        ConsoleOutputHandle());
      return assert_Int $bounds_X;
    }
  };

=item I<NumberLock>

  field NumberLock ( is => ro, type => Bool );

Gets a value indicating whether the C<NUM LOCK> keyboard toggle is turned on 
or turned off.

=cut

  sub NumberLock {
    assert ( @_ == 1 );
    my $self = assert_Object shift;
    GET: {
      require Win32Native;
      my $value = (Win32Native::GetKeyState(NumberLockVKCode) & 1) == 1;
      return assert_Bool $value;
    }
  };

=item I<Out>

  field Out ( is => ro, type => FileHandle );

A I<FileHandle> that represents the standard output stream.

=cut

  sub Out {
    assert ( @_ == 1 );
    my $self = assert_Object shift;
    GET: {
      if ( !defined $_out ) {
        InitializeStdOutError(TRUE);
      }
      return $_out;
    }
  };

=item I<OutputEncoding>

  field OutputEncoding ( is => rw, type => Object );
  class_has OutputEncoding ( is => rw, isa => Object, init_arg => undef );

Gets or sets the encoding the console uses to write output.

I<Remarks>: A get operation may return a cached value instead of the console's 
current output encoding.

=cut

  sub OutputEncoding {
    assert ( @_ >= 1 && @_ <= 2 );
    my $caller = shift;

    assert ( $caller );
    assert ( is_Object($caller) || is_ClassName($caller) );

    goto SET if @_;
    GET: {
      return $_outputEncoding
        if $_outputEncoding;

      {
        lock($InternalSyncObject);

        return $_outputEncoding
          if $_outputEncoding;

        my $cp = Win32::GetConsoleOutputCP() || Win32::GetACP();
        $_outputEncoding = Encode::find_encoding("cp$cp");
        return assert_Object $_outputEncoding;
      }
    }
    SET: {
      if ( !defined $_[0] ) {
        confess("ArgumentNullException:\n". 
          sprintf("$ResourceString{ArgumentNullException}\n", "value"));
      }
      my $value = assert_Object shift;

      {
        lock($InternalSyncObject);
        # Before changing the code page we need to flush the data 
        # if Out hasn't been redirected. Also, have the next call to
        # $_out reinitialize the console code page.

        if ( defined($_out) && !$_isOutTextWriterRedirected ) {
          $_out->flush();
          $_out = undef;
        }
        if ( defined($_error) && !$_isErrorTextWriterRedirected ) {
          $_error->flush();
          $_error = undef;
        }

        if ( !IsStandardConsoleUnicodeEncoding($value) ) {
          my $cp = $value->$CodePage();
          my $r = Win32::SetConsoleOutputCP($cp);
          if ( !$r ) {
            warn("WinIOError:\n$EXTENDED_OS_ERROR\n");
          }
        }

        $_outputEncoding = $value;
        return;
      } # set
    }
  };

=item I<Title>

  field Title ( is => rw, type => Str ) = '';

The string to be displayed in the title bar of the console.  The maximum length 
of the title string is C<24500> characters for set and C<1024> for get.

I<Throws>: I<InvalidOperationException> in a get operation, if the specified 
title is longer than C<24500> characters.

I<Throws>: I<ArgumentOutOfRangeException> in a set operation, if the specified 
title is longer than C<24500> characters.

I<Throws>: I<ArgumentNullException> in a set operation, if the specified title 
is C<undef>.

I<Throws>: I<Exception> in a set operation, if the specified title is not a 
string.

I<Remarks>: The return value is a empty string if the specific length is greater
than C<1024>.

=cut

  sub Title {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $title;
      my $titleLength = 0xffff;
      my $r = do { # GetTitleNative
        Win32::SetLastError(0);
        $title = Win32::Console::_GetConsoleTitle();
        $titleLength = length($title);
        # Win32::Console::_GetConsoleTitle() only supports 1024 characters
        $title = substr($title, 0, 1024) if $titleLength > 1024;
        Win32::GetLastError() == 0;
      };
  
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n")
      }
  
      if ( $titleLength > MaxConsoleTitleLength ) {
        confess("InvalidOperationException:\n".
          "$ResourceString{ArgumentOutOfRange_ConsoleTitleTooLong}\n");
      }

      return assert_Str $title;
    }
    SET: {
      my $value = shift;
      if ( !defined $value ) {
        confess("ArgumentNullException:\n". 
          sprintf("$ResourceString{ArgumentNullException}\n", "value"));
      }
      assert_Str $value;
      if ( length($value) > MaxConsoleTitleLength ) {
        confess("ArgumentOutOfRangeException:\n".
          "$ResourceString{ArgumentOutOfRange_ConsoleTitleTooLong}\n");
      }

      Win32::Console::_SetConsoleTitle($value)
        or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      return;
    }
  };

=item I<TreatControlCAsInput>

  field TreatControlCAsInput ( is => rw, type => Bool ) = FALSE;

Indicating whether the combination of the C<Control> modifier key and C<C> 
console key (C<Ctrl+C>) is treated as ordinary input or as an interruption 
that is handled by the operating system.

The attribute is I<true> if C<Ctrl+C> is treated as ordinary input; otherwise, 
I<false>.

I<Throws>: I<IOException> if unable to get or set the input mode of the console 
input buffer.

=cut

   sub TreatControlCAsInput {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $handle = ConsoleInputHandle();
      if ( $handle == Win32API::File::INVALID_HANDLE_VALUE ) {
        confess("IOException:\n$ResourceString{IO_NoConsole}\n");
      }
      my $mode = 0;
      my $r = do {
        Win32::SetLastError(0);
        $mode = Win32::Console::_GetConsoleMode($handle) || 0;
        Win32::GetLastError() == 0;
      };
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      }
      my $value = ($mode & ENABLE_PROCESSED_INPUT) == 0;
      return assert_Bool $value;
    }
    SET: {
      my $value = assert_Bool shift;
      my $handle = ConsoleInputHandle();
      if ( $handle == Win32API::File::INVALID_HANDLE_VALUE ) {
        confess("IOException:\n$ResourceString{IO_NoConsole}\n");
      }
      my $mode = 0;
      my $r = do {
        Win32::SetLastError(0);
        $mode = Win32::Console::_GetConsoleMode($handle) || 0;
        Win32::GetLastError() == 0;
      };
      if ( $value ) {
        $mode &= ~ENABLE_PROCESSED_INPUT;
      } else {
        $mode |= ENABLE_PROCESSED_INPUT;
      }
      $r = Win32::Console::_SetConsoleMode($handle, $mode);
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      }
      return;
    }
  };

=item I<WindowHeight>

  field WindowHeight ( is => rw, type => Int );

The height of the console window measured in rows.

I<Throws>: I<ArgumentOutOfRangeException> if the value is less than or equal to 
C<0> or the value plus L</WindowTop> is greater than or equal to C<0x7fff> or 
the value greater than the largest possible window height for the current 
screen resolution and console font.

I<Throws>: I<Exception> if an error occurs when reading or writing information.

=cut

  sub WindowHeight {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
      my $value = $csbi->{srWindow}->{Bottom} - $csbi->{srWindow}->{Top} + 1;
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      $self->SetWindowSize($self->WindowWidth, $value);
      return;
    }
  };

=item I<WindowLeft>

  field WindowLeft ( is => rw, type => Int );

The leftmost console window position measured in columns.

I<Throws>: I<ArgumentOutOfRangeException> if the value is less than C<0> or
as a result of the assignment, L</WindowLeft> plus L</WindowWidth> would exceed
L</BufferWidth>.

I<Throws>: I<Exception> if an error occurs when reading or writing information.

=cut

  sub WindowLeft {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
      my $value = $csbi->{srWindow}->{Left};
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      $self->SetWindowPosition($value, $self->WindowTop);
      return;
    }
  };

=item I<WindowTop>

  field WindowTop ( is => rw, type => Int );

The uppermost console window position measured in rows.

I<Throws>: I<ArgumentOutOfRangeException> if the value is less than C<0> or
as a result of the assignment, L</WindowTop> plus L</WindowHeight> would exceed
L</BufferHeight>.

I<Throws>: I<Exception> if an error occurs when reading or writing information.

=cut

  sub WindowTop {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
      my $value = $csbi->{srWindow}->{Top};
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      $self->SetWindowPosition($self->WindowLeft, $value);
      return;
    }
  };

=item I<WindowWidth>

  field WindowWidth ( is => rw, type => Int );

The width of the console window measured in columns.

I<Throws>: I<ArgumentOutOfRangeException> if the value is less than or equal to 
C<0> or the value plus L</WindowLeft> is greater than or equal to C<0x7fff> or 
the value greater than the largest possible window width for the current screen 
resolution and console font.

I<Throws>: I<Exception> if an error occurs when reading or writing information.

=cut

  sub WindowWidth {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    goto SET if @_;
    GET: {
      my $csbi = GetBufferInfo();
      my $value = $csbi->{srWindow}->{Right} - $csbi->{srWindow}->{Left} + 1;
      return assert_Int $value;
    }
    SET: {
      my $value = assert_Int shift;
      $self->SetWindowSize($value, $self->WindowHeight);
      return;
    }
  };

=back

=cut

  # ------------------------------------------------------------------------
  # Constructors -----------------------------------------------------------
  # ------------------------------------------------------------------------

  use constant FACTORY => __PACKAGE__;

=head2 Constructors

=over

=item I<new>

  factory new() : Win32::Console::DotNet

Public constructor.

=cut

  sub new {
    assert ( @_ == 1 );
    my $class = shift;
    assert ( is_ClassName $class );
    return bless {}, $class;
  };

=item I<instance>

  factory instance() : Win32::Console::DotNet

This constructor instantiates an object instance if none exists, otherwise it
returns an existing instance.

It is used to initialize the default I/O console.

=cut

  sub instance {
    assert ( @_ == 1 );
    my $class = shift;
    # already got an object
    return $class if ref($class);
    # create a instance and store it in $_instances if not already defined
    $_instance = $class->new() unless $_instance;
    return $_instance;
  }

=back

=cut

  # ------------------------------------------------------------------------
  # Destructors ------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Destructors

=over

=item I<DESTROY>

  method DESTROY()

Restore the console before destroying the instance/object.

=cut

  #
  # END block to explicitly destroy the Singleton object since
  # destruction order at program exit is not predictable.
  # see CPAN RT #23568 and #68526 for examples
  #
  END {
    # dereferences and causes orderly destruction of the instance
    undef($_instance);
  }

=back

=cut

  # ------------------------------------------------------------------------
  # Methods ----------------------------------------------------------------
  # ------------------------------------------------------------------------

=head2 Methods

=over

=item I<Beep>

  method Beep()

Plays the sound of a beep through the console speaker.

  method Beep(Int $frequency, Int $duration)

Plays the sound of a beep of a specified frequency and duration through the 
console speaker.

I<Param>: C<$frequency> of the beep, ranging from C<37> to C<32767> hertz.

I<Param>: C<$duration> of the beep measured in milliseconds.

I<Throws>: I<ArgumentOutOfRangeException> if C<$frequency> is less than C<37> 
or more than C<32767> hertz or C<$duration> is less than or equal to zero.

=cut

  sub Beep {
    assert ( @_ == 1 || @_ == 3 );
    my $self = assert_Object shift;
    my $frequency = @_ > 1 ? assert_Int(shift) : 800;
    my $duration =  @_ > 0 ? assert_Int(shift) : 200;

    if ( $frequency < MinBeepFrequency || $frequency > MaxBeepFrequency ) {
      confess("ArgumentOutOfRangeException: frequency $frequency\n". 
        sprintf("$ResourceString{ArgumentOutOfRange_BeepFrequency}\n", 
          MinBeepFrequency, MaxBeepFrequency));
    }
    if ( $duration <= 0 ) {
      confess("ArgumentOutOfRangeException: duration $duration\n". 
        "$ResourceString{ArgumentOutOfRange_NeedPosNum}\n");
    }

    # Note that Beep over Remote Desktop connections does not currently
    # work.  Ignore any failures here.
    require Win32Native;
    Win32Native::Beep($frequency, $duration);
    return;
  }

=item I<Clear>

  method Clear()

Clears the console buffer and corresponding console window of display 
information.

I<Throws>: I<IOException> if an I/O error occurred.

=cut

  sub Clear {
    assert ( @_ == 1 );
    my $self = assert_Object shift;

    my $coordScreen = { X => 0, Y => 0 };
    my $csbi;
    my $conSize;
    my $success;

    my $hConsole = ConsoleOutputHandle();
    if ( $hConsole == Win32API::File::INVALID_HANDLE_VALUE ) {
      confess("IOException:\n$ResourceString{IO_NoConsole}\n");
    }

    # get the number of character cells in the current buffer
    # Go through my helper method for fetching a screen buffer info
    # to correctly handle default console colors.
    $csbi = GetBufferInfo();
    $conSize = $csbi->{dwSize}->{X} * $csbi->{dwSize}->{Y};

    # fill the entire screen with blanks

    my $numCellsWritten = 0;
    $success = do {
      Win32::SetLastError(0);
      $numCellsWritten = Win32::Console::_FillConsoleOutputCharacter($hConsole,
        ' ', $conSize, $coordScreen->{X}, $coordScreen->{Y}
      ) || 0;
      Win32::GetLastError() == 0;
    };
    if ( !$success ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
    }

    # now set the buffer's attributes accordingly

    $numCellsWritten = 0;
    $success = do {
      Win32::SetLastError(0);
      $numCellsWritten = Win32::Console::_FillConsoleOutputAttribute($hConsole,
        $csbi->{wAttributes}, $conSize, $coordScreen->{X}, $coordScreen->{Y}
      ) || 0;
      Win32::GetLastError() == 0;
    };
    if ( !$success ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
    }

    # put the cursor at (0, 0)

    $success = Win32::Console::_SetConsoleCursorPosition($hConsole, 
      $coordScreen->{X}, $coordScreen->{Y});
    if ( !$success ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
    }
    return;
  }

=item I<GetCursorPosition>

  method GetCursorPosition() : ArrayRef[Int]

Gets the position of the cursor.

I<Returns>: the column and row position of the cursor as array reference.

=cut

  sub GetCursorPosition {
    assert ( @_ == 1 );
    my $self = assert_Object shift;

    return [
      $self->CursorLeft, 
      $self->CursorTop,
    ]
  }

=item I<MoveBufferArea>

  method MoveBufferArea(Int $sourceLeft, Int $sourceTop, Int $sourceWidth, 
    Int $sourceHeight, Int $targetLeft, Int $targetTop);

Copies a specified source area of the screen buffer to a specified destination 
area.

I<Param>: C<$sourceLeft> is the leftmost column of the source area.

I<Param>: C<$sourceTop> is the topmost row of the source area.

I<Param>: C<$sourceWidth> is the number of columns in the source area.

I<Param>: C<$sourceHeight> is the number of rows in the source area.

I<Param>: C<$targetLeft> is the leftmost column of the destination area.

I<Param>: C<$targetTop> is the topmost row of the destination area.

I<Throws>: I<ArgumentOutOfRangeException> if one or more of the parameters is 
less than zero or C<$sourceLeft> or C<$targetLeft> is greater than or equal to 
L</BufferWidth> or C<$sourceTop> or C<$targetTop> is greater than or equal to 
L</BufferHeight> or C<$sourceTop> + C<$sourceHeight> is greater than or equal 
to L</BufferHeight> or C<$sourceLeft> + C<$sourceWidth> is greater than or 
equal to L</BufferWidth>.

I<Throws>: I<IOException> if an I/O error occurred.

I<Remarks>: If the destination and source parameters specify a position located 
outside the boundaries of the current screen buffer, only the portion of the 
source area that fits within the destination area is copied. That is, the 
source area is clipped to fit the current screen buffer.

The L</MoveBufferArea> method copies the source area to the destination area. If 
the destination area does not intersect the source area, the source area is 
filled with blanks using the current foreground and background colors. 
Otherwise, the intersected portion of the source area is not filled.

  method MoveBufferArea(Int $sourceLeft, Int $sourceTop, Int $sourceWidth, 
    Int $sourceHeight, Int $targetLeft, Int $targetTop, Str $sourceChar, 
    Int $sourceForeColor, Int $sourceBackColor);

Copies a specified source area of the screen buffer to a specified destination 
area.

I<Param>: C<$sourceLeft> is the leftmost column of the source area.

I<Param>: C<$sourceTop> is the topmost row of the source area.

I<Param>: C<$sourceWidth> is the number of columns in the source area.

I<Param>: C<$sourceHeight> is the number of rows in the source area.

I<Param>: C<$targetLeft> is the leftmost column of the destination area.

I<Param>: C<$targetTop> is the topmost row of the destination area.

I<Param>: C<$sourceChar> is the character used to fill the source area.

I<Param>: C<$sourceForeColor> is the foreground color used to fill the source 
area.

I<Param>: C<$sourceBackColor> is the background color used to fill the source 
area.

I<Throws>: I<ArgumentOutOfRangeException> if one or more of the parameters is 
less than zero or C<$sourceLeft> or C<$targetLeft> is greater than or equal to 
L</BufferWidth> or C<$sourceTop> or C<$targetTop> is greater than or equal to 
L</BufferHeight> or C<$sourceTop> + C<$sourceHeight> is greater than or equal 
to L</BufferHeight> or C<$sourceLeft> + C<$sourceWidth> is greater than or 
equal to L</BufferWidth>.

I<Throws>: I<ArgumentException> if one or both of the color parameters is not 
valid.

I<Throws>: I<IOException> if an I/O error occurred.

I<Remarks>: If the destination and source parameters specify a position located 
outside the boundaries of the current screen buffer, only the portion of the 
source area that fits within the destination area is copied. That is, the 
source area is clipped to fit the current screen buffer.

The L</MoveBufferArea> method copies the source area to the destination area. 
If the destination area does not intersect the source area, the source area is 
filled with the character specified by C<$sourceChar>, using the colors 
specified by C<$sourceForeColor> and C<$sourceBackColor>. Otherwise, the 
intersected portion of the source area is not filled.

The L</MoveBufferArea> method performs no operation if C<$sourceWidth> or 
C<$sourceHeight> is zero.

=cut

  sub MoveBufferArea {
    assert ( @_ == 7 || @_ == 10 );
    my $self            = assert_Object shift;
    my $sourceLeft      = assert_Int shift;
    my $sourceTop       = assert_Int shift;
    my $sourceWidth     = assert_Int shift;
    my $sourceHeight    = assert_Int shift;
    my $targetLeft      = assert_Int shift;
    my $targetTop       = assert_Int shift;
    my $sourceChar      = @_ ? assert_Str(shift) : ' ';
    my $sourceForeColor = @_ ? assert_Int(shift) : $FG_BLACK;
    my $sourceBackColor = @_ ? assert_Int(shift) : $self->BackgroundColor;

    if ( $sourceForeColor < 0 || $sourceForeColor > 15 ) {
      confess("ArgumentException: sourceForeColor\n".
        "$ResourceString{Arg_InvalidConsoleColor}\n");
    }
    if ( $sourceBackColor < 0 || $sourceBackColor > 15 ) {
      confess("ArgumentException: sourceBackColor\n".
        "$ResourceString{Arg_InvalidConsoleColor}\n");
    }

    my $csbi = GetBufferInfo();
    my $bufferSize = $csbi->{dwSize};
    if ( $sourceLeft < 0 || $sourceLeft > $bufferSize->{X} ) {
      confess("ArgumentOutOfRangeException: sourceLeft $sourceLeft\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $sourceTop < 0 || $sourceTop > $bufferSize->{Y} ) {
      confess("ArgumentOutOfRangeException: sourceTop $sourceTop\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $sourceWidth < 0 || $sourceWidth > $bufferSize->{X} - $sourceLeft ) {
      confess("ArgumentOutOfRangeException: sourceWidth $sourceWidth\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $sourceHeight < 0 || $sourceTop > $bufferSize->{Y} - $sourceHeight ) {
      confess("ArgumentOutOfRangeException: sourceHeight $sourceHeight\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }

    # Note: if the target range is partially in and partially out
    # of the buffer, then we let the OS clip it for us.
    if ( $targetLeft < 0 || $targetLeft > $bufferSize->{X} ) {
      confess("ArgumentOutOfRangeException: targetLeft $targetLeft\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $targetTop < 0 || $targetTop > $bufferSize->{Y} ) {
      confess("ArgumentOutOfRangeException: targetTop $targetTop\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }

    # If we're not doing any work, bail out now (Windows will return
    # an error otherwise)
    return if $sourceWidth == 0 || $sourceHeight == 0;

    # Read data from the original location, blank it out, then write
    # it to the new location.  This will handle overlapping source and
    # destination regions correctly.

    # See the "Reading and Writing Blocks of Characters and Attributes" 
    # sample for help

    # Read the old data
    my $data = (" " x ($sourceWidth * $sourceHeight * 4));
    $bufferSize->{X} = $sourceWidth;
    $bufferSize->{Y} = $sourceHeight;
    my $bufferCoord = { X => 0, Y => 0 };
    my $readRegion = {};
    $readRegion->{Left} = $sourceLeft;
    $readRegion->{Right} = $sourceLeft + $sourceWidth - 1;
    $readRegion->{Top} = $sourceTop;
    $readRegion->{Bottom} = $sourceTop + $sourceHeight - 1;

    my $r;
    $r = do {
      my @rect = Win32::Console::_ReadConsoleOutput(ConsoleOutputHandle(), 
        $data,
        $bufferSize->{X}, $bufferSize->{Y}, 
        $bufferCoord->{X}, $bufferCoord->{Y}, 
        $readRegion->{Left}, $readRegion->{Top}, 
        $readRegion->{Right}, $readRegion->{Bottom}
      );
      @rect > 1;
    };
    if ( !$r ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
    }

    # Overwrite old section
    # I don't have a good function to blank out a rectangle.
    my $writeCoord = { X => 0, Y => 0 };
    $writeCoord->{X} = $sourceLeft;
    my $c = ConsoleColorToColorAttribute($sourceBackColor, TRUE);
    $c |= ConsoleColorToColorAttribute($sourceForeColor, FALSE);
    my $attr = $c;
    my $numWritten;
    for (my $i = $sourceTop; $i < $sourceTop + $sourceHeight; $i++) {
      $writeCoord->{Y} = $i;
      $r = do {
        Win32::SetLastError(0);
        $numWritten = Win32::Console::_FillConsoleOutputCharacter(
          ConsoleOutputHandle(), $sourceChar, $sourceWidth,
          $writeCoord->{X}, $writeCoord->{Y}
        ) || 0;
        Win32::GetLastError() == 0;
      };
      assert ( $numWritten == $sourceWidth 
        or ~- warn "FillConsoleOutputCharacter wrote the wrong number of chars!"
      );
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      }
      $r = do {
        Win32::SetLastError(0);
        $numWritten = Win32::Console::_FillConsoleOutputAttribute(
          ConsoleOutputHandle(), $attr, $sourceWidth,
          $writeCoord->{X}, $writeCoord->{Y}
        ) || 0;
        Win32::GetLastError() == 0;
      };
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      }
    }

    # Write text to new location
    my $writeRegion = {};
    $writeRegion->{Left} = $targetLeft;
    $writeRegion->{Right} = $targetLeft + $sourceWidth;
    $writeRegion->{Top} = $targetTop;
    $writeRegion->{Bottom} = $targetTop + $sourceHeight;

    $r = do {
      my @rect = Win32::Console::_WriteConsoleOutput(
        ConsoleOutputHandle(), $data, 
        $bufferSize->{X}, $bufferSize->{Y}, 
        $bufferCoord->{X}, $bufferCoord->{Y}, 
        $writeRegion->{Left}, $writeRegion->{Top}, 
        $writeRegion->{Right}, $writeRegion->{Bottom}
      );
      @rect > 1;
    };
    return;
  }

=item I<OpenStandardError>

  method OpenStandardError() : FileHandle
  method OpenStandardError(Int $bufferSize) : FileHandle
  classmethod OpenStandardError() : FileHandle
  classmethod OpenStandardError(Int $bufferSize) : FileHandle

Acquires the standard error object.

I<Returns>: the standard error object.

=cut

  sub OpenStandardError {
    assert ( @_ >= 1 && @_ <= 2 );
    my $caller = shift;
    my $bufferSize = @_ ? assert_Int(shift) : DefaultConsoleBufferSize;

    assert ( $caller );
    assert ( is_Object($caller) || is_ClassName($caller) );

    if ( $bufferSize < 0 ) {
      confess("ArgumentOutOfRangeException: bufferSize\n". 
        "$ResourceString{ArgumentOutOfRange_NeedNonNegNum}\n");
    }
    return GetStandardFile(STD_ERROR_HANDLE, 'w', $bufferSize);
  }

=item I<OpenStandardInput>

  method OpenStandardInput() : FileHandle
  method OpenStandardInput(Int $bufferSize) : FileHandle
  classmethod OpenStandardInput() : FileHandle
  classmethod OpenStandardInput(Int $bufferSize) : FileHandle

Acquires the standard input object.

I<Returns>: the standard input object.

=cut

  sub OpenStandardInput {
    assert ( @_ >= 1 && @_ <= 2 );
    my $caller = shift;
    my $bufferSize = @_ ? assert_Int(shift) : DefaultConsoleBufferSize;

    assert ( $caller );
    assert ( is_Object($caller) || is_ClassName($caller) );

    if ( $bufferSize < 0 ) {
      confess("ArgumentOutOfRangeException: bufferSize\n". 
        "$ResourceString{ArgumentOutOfRange_NeedNonNegNum}\n");
    }
    return GetStandardFile(STD_INPUT_HANDLE, 'r', $bufferSize);
  }

=item I<OpenStandardOutput>

  method OpenStandardOutput() : FileHandle
  method OpenStandardOutput(Int $bufferSize) : FileHandle
  classmethod OpenStandardOutput() : FileHandle
  classmethod OpenStandardOutput(Int $bufferSize) : FileHandle

Acquires the standard output object.

I<Returns>: the standard output object.

=cut

  sub OpenStandardOutput {
    assert ( @_ >= 1 && @_ <= 2 );
    my $caller = shift;
    my $bufferSize = @_ ? assert_Int(shift) : DefaultConsoleBufferSize;

    assert ( $caller );
    assert ( is_Object($caller) || is_ClassName($caller) );

    if ( $bufferSize < 0 ) {
      confess("ArgumentOutOfRangeException: bufferSize\n". 
        "$ResourceString{ArgumentOutOfRange_NeedNonNegNum}\n");
    }
    return GetStandardFile(STD_OUTPUT_HANDLE, 'w', $bufferSize);
  }

=item I<Read>

  method Read() : Int

Reads the next character from the standard input stream.

I<Returns>: the next character from the input stream, or negative one (C<-1>) 
if there are currently no more characters to be read.

I<Throws>: I<IOException> if an I/O error occurred.

=cut

  sub Read {
    assert ( @_ == 1 );
    my $self = assert_Object shift;

    assert_FileHandle $self->In;
    my $r = $self->In->read(my $ch, 1);
    if ( !$r ) {
      confess("IOException:\n$OS_ERROR\n") unless defined $r;
      # flush on stdin is not provided, so a loop is used
      1 while defined $self->In->getline();
      return -1;
    }
    return ord($ch);
  }

=item I<ReadKey>

  method ReadKey() : ConsoleKeyInfo
  method ReadKey(Bool $intercept) : ConsoleKeyInfo

Obtains the next character or function key pressed by the user. 
The pressed key is optionally displayed in the console window.

I<Param>: C<$intercept> determines whether to display the pressed key in the 
console window. I<True> to not display the pressed key; otherwise, I<false>.

I<Returns>: an I<ConsoleKeyInfo> (blessed HashRef) that describes the console 
key and unicode character, if any, that correspond to the pressed console key. 
The I<ConsoleKeyInfo> also describes, in a bitwise combination of values, 
whether one or more C<Shift>, C<Alt>, or C<Ctrl> modifier keys was pressed 
simultaneously with the console key.

=cut

  sub ReadKey {
    assert ( @_ >= 1 && @_ <= 2 );
    my $self = assert_Object shift;
    my $intercept = @_ ? assert_Bool(shift) : FALSE;

    my @ir;
    my $numEventsRead = -1;
    my $r;

    { 
      lock($ReadKeySyncObject);

      if ( $_cachedInputRecord->[eventType] == Win32Native::KEY_EVENT ) {
        # We had a previous keystroke with repeated characters.
        @ir = @$_cachedInputRecord;
        if ( $_cachedInputRecord->[repeatCount] == 0 ) {
          $_cachedInputRecord->[eventType] = -1;
        } else {
          $_cachedInputRecord->[repeatCount]--; 
        }
        # We will return one key from this method, so we decrement the
        # repeatCount here, leaving the cachedInputRecord in the "queue".

      } else { # We did NOT have a previous keystroke with repeated characters:

        while (TRUE) {
          $r = do {
            @ir = Win32::Console::_ReadConsoleInput(ConsoleInputHandle());
            my $r = @ir > 1;
            $numEventsRead = @ir > 1 ? 1 : 0;
            @ir = (0) x 6 unless $ir[0];
            $r;
          };
          if ( !$r || $numEventsRead == 0 ) {
            # This will fail when stdin is redirected from a file or pipe.
            # We could theoretically call Console->Read here, but I 
            # think we might do some things incorrectly then.
            confess("InvalidOperationException:\n".
              "$ResourceString{InvalidOperation_ConsoleReadKeyOnFile}\n");
          }

          my $keyCode = $ir[virtualKeyCode];

          # First check for non-keyboard events & discard them. Generally we tap 
          # into only KeyDown events and ignore the KeyUp events but it is 
          # possible that we are dealing with a Alt+NumPad unicode key sequence, 
          # the final unicode char is revealed only when the Alt key is 
          # released (i.e when the sequence is complete). To avoid noise, when 
          # the Alt key is down, we should eat up any intermediate key strokes 
          # (from NumPad) that collectively forms the Unicode character. 

          if ( !IsKeyDownEvent(\@ir) ) {
            #
            next if $keyCode != AltVKCode;
          }

          my $ch = $ir[uChar];

          # In a Alt+NumPad unicode sequence, when the alt key is released uChar 
          # will represent the final unicode character, we need to surface this. 
          # VirtualKeyCode for this event will be Alt from the Alt-Up key event. 
          # This is probably not the right code, especially when we don't expose 
          # ConsoleKey.Alt, so this will end up being the hex value (0x12). 
          # VK_PACKET comes very close to being useful and something that we 
          # could look into using for this purpose... 

          if ( $ch == 0 ) {
            # Skip mod keys.
            next if IsModKey(\@ir);
          }

          # When Alt is down, it is possible that we are in the middle of a 
          # Alt+NumPad unicode sequence. Escape any intermediate NumPad keys 
          # whether NumLock is on or not (notepad behavior)
          my $key = $keyCode;
          if (IsAltKeyDown(\@ir)  && (($key >= VK_NUMPAD0 && $key <= VK_NUMPAD9)
                                  || ($key == VK_CLEAR) || ($key == VK_INSERT)
                                  || ($key >= VK_PRIOR && $key <= VK_NEXT))
          ) {
            next;
          }

          if ( $ir[repeatCount] > 1 ) {
            $ir[repeatCount]--;
            $_cachedInputRecord = \@ir;
          }
          last;
        }
      } # we did NOT have a previous keystroke with repeated characters.
    } # lock($ReadKeySyncObject)

    my $state = $ir[controlKeyState];
    my $shift = ($state & SHIFT_PRESSED) != 0;
    my $alt = ($state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;
    my $control = ($state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) != 0;

    my $info = {
      KeyChar   => chr($ir[uChar]),
      Key       => $ir[virtualKeyCode],
      Modifiers => ($shift ? 2 : 0) + ($alt ? 1 : 0) + ($control ? 4 : 0),
    };

    if ( !$intercept ) {
      $self->Write(chr($ir[uChar]));
    }
    return bless $info, 'ConsoleKeyInfo';
  }

=item I<ReadLine>

  method ReadLine() : Str

Reads the next line of characters from the standard input stream.

I<Returns>: the next line of characters from the input stream, or C<undef> if no 
more lines are available.

I<Throws>: I<IOException> if an I/O error occurred.

=cut

  sub ReadLine {
    assert ( @_ == 1 );
    my $self = assert_Object shift;

    assert_FileHandle $self->In;
    $! = undef;
    my $str = $self->In->getline();
    confess("IOException:\n$OS_ERROR\n") if $!;
    chomp $str if defined $str;
    return $str;
  }

=item I<ResetColor>

  method ResetColor()

Sets the foreground and background console colors to their defaults.

I<Throws>: I<IOException> if an I/O error occurred.

=cut

  sub ResetColor {
    assert ( @_ == 1 );
    my $self = assert_Object shift;

    my $succeeded;
    my $csbi = GetBufferInfo(FALSE, \$succeeded);
    return if !$succeeded;

    assert ( $_haveReadDefaultColors 
      or ~- warn "Setting the color attributes before we've read the default ".
                 "color attributes!"
    );
 
    my $defaultAttrs = $$_defaultColors & 0xff;
    # Ignore errors here - there are some scenarios for running code that wants
    # to print in colors to the console in a Windows application.
    Win32::Console::_SetConsoleTextAttribute(ConsoleOutputHandle(), 
      $defaultAttrs);
    return;
  }

=item I<SetBufferSize>

  method SetBufferSize(Int $width, Int $height)

Sets the height and width of the screen buffer area to the specified values.

I<Param>: C<$width> of the buffer area measured in columns.

I<Param>: C<$height> of the buffer area measured in rows.

=cut

  sub SetBufferSize {
    assert ( @_ == 3 );
    my $self = assert_Object shift;
    my $width = assert_Int shift;
    my $height = assert_Int shift;

    my $csbi = GetBufferInfo();
    my $srWindow = $csbi->{srWindow};
    if ( $width < $srWindow->{Right} + 1 || $width >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: width $width\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferLessThanWindowSize}",
        "\n");
    }
    if ( $height < $srWindow->{Bottom} + 1 || $height >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: height $height\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferLessThanWindowSize}",
        "\n");
    }
    Win32::Console::_SetConsoleScreenBufferSize(ConsoleOutputHandle(), 
      $width, $height) or confess("WinIOError:\n$EXTENDED_OS_ERROR\n");

    return;
  }

=item I<SetCursorPosition>

  method SetCursorPosition(Int $left, Int $top)

Sets the position of the cursor.

I<Param>: C<$left> column position of the cursor. Columns are numbered from left 
to right starting at C<0>.

I<Param>: C<$top> row position of the cursor. Rows are numbered from top to 
bottom starting at C<0>.

=cut

  sub SetCursorPosition {
    assert ( @_ == 3 );
    my $self = assert_Object shift;
    my $left = assert_Int shift;
    my $top = assert_Int shift;

    # Note on argument checking - the upper bounds are NOT correct 
    # here!  But it looks slightly expensive to compute them.  Let
    # Windows calculate them, then we'll give a nice error message.
    if ( $left < 0 || $left >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: left $left\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }
    if ( $top < 0 || $top >= 0x7fff ) {
      confess("ArgumentOutOfRangeException: top $top\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
    }

    my $hConsole = ConsoleOutputHandle();
    my $r = Win32::Console::_SetConsoleCursorPosition($hConsole, $left, $top);
    if ( !$r ) {
      # Give a nice error message for out of range sizes
      my $errorCode = Win32::GetLastError();
      my $csbi = GetBufferInfo();
      if ( $left < 0 || $left >= $csbi->{dwSize}->{X} ) {
        confess("ArgumentOutOfRangeException: left $left\n". 
          "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
      }
      if ( $top < 0 || $top >= $csbi->{dwSize}->{Y} ) {
        confess("ArgumentOutOfRangeException: top $top\n". 
          "$ResourceString{ArgumentOutOfRange_ConsoleBufferBoundaries}\n");
      }

      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
    }

    return;
  }

=item I<SetError>

  method SetError(FileHandle $newError)

Sets the L</Error> attribute to the specified error I<FileHandle>.

I<Param>: C<$newError> represents a io handle that is the new standard error.

=cut

  sub SetError {
    assert ( @_ == 2 );
    my $self = assert_Object shift;
    my $newError = shift;

    if ( !defined $newError ) {
      confess("ArgumentNullException:\n". 
        sprintf("$ResourceString{ArgumentNullException}\n", "newError"));
    }
    $_isErrorTextWriterRedirected = TRUE;
    {
      lock($InternalSyncObject);
      $_error = assert_FileHandle $newError;
    }
    return;
  }

=item I<SetIn>

  method SetIn(FileHandle $newIn)

Sets the L</In> attribute to the specified input I<FileHandle>.

I<Param>: C<$newIn> represents a io handle that is the new standard input.

=cut

  sub SetIn {
    assert ( @_ == 2 );
    my $self = assert_Object shift;
    my $newIn = shift;

    if ( !defined $newIn ) {
      confess("ArgumentNullException:\n". 
        sprintf("$ResourceString{ArgumentNullException}\n", "newIn"));
    }
    {
      lock($InternalSyncObject);
      $_in = assert_FileHandle $newIn;
    }
    return;
  }

=item I<SetOut>

  method SetOut(FileHandle $newOut)

Sets the L</Out> attribute to the specified output I<FileHandle>.

I<Param>: C<$newOut> represents a io handle that is the new standard output.

=cut

  sub SetOut {
    assert ( @_ == 2 );
    my $self = assert_Object shift;
    my $newOut = shift;

    if ( !defined $newOut ) {
      confess("ArgumentNullException:\n". 
        sprintf("$ResourceString{ArgumentNullException}\n", "newOut"));
    }
    $_isOutTextWriterRedirected = TRUE;
    {
      lock($InternalSyncObject);
      $_out = assert_FileHandle $newOut;
    }
    return;
  }

=item I<SetWindowSize>

  method SetWindowSize(Int $width, Int $height)

Sets the height and width of the console window to the specified values.

I<Param>: C<$width> of the console window measured in columns.

I<Param>: C<$height> of the console window measured in rows.

=cut

  sub SetWindowSize {
    assert ( @_ == 3 );
    my $self = assert_Object shift;
    my $width = assert_Int shift;
    my $height = assert_Int shift;

    if ( $width <= 0 ) {
      confess("ArgumentOutOfRangeException: width $width\n". 
        "$ResourceString{ArgumentOutOfRange_NeedPosNum}\n");
    }
    if ( $height <= 0 ) {
      confess("ArgumentOutOfRangeException: height $height\n". 
        "$ResourceString{ArgumentOutOfRange_NeedPosNum}\n");
    }
    
    # Get the position of the current console window
    my $csbi = GetBufferInfo();
    my $r;

    # If the buffer is smaller than this new window size, resize the
    # buffer to be large enough.  Include window position.
    my $resizeBuffer = FALSE;
    my $size = {
      X => $csbi->{dwSize}->{X},
      Y => $csbi->{dwSize}->{Y},
    };
    if ( $csbi->{dwSize}->{X} < $csbi->{srWindow}->{Left} + $width ) {
      if ( $csbi->{srWindow}->{Left} >= 0x7fff - $width ) {
        confess("ArgumentOutOfRangeException: width $width\n". 
          "$ResourceString{ArgumentOutOfRange_ConsoleWindowBufferSize}\n");
      }
      $size->{X} = $csbi->{srWindow}->{Left} + $width;
      $resizeBuffer = TRUE;
    }
    if ( $csbi->{dwSize}->{Y} < $csbi->{srWindow}->{Top} + $height ) {
      if ( $csbi->{srWindow}->{Top} >= 0x7fff - $height ) {
        confess("ArgumentOutOfRangeException: height $height\n". 
          "$ResourceString{ArgumentOutOfRange_ConsoleWindowBufferSize}\n");
      }
      $size->{Y} = $csbi->{srWindow}->{Top} + $height;
      $resizeBuffer = TRUE;
    }
    if ( $resizeBuffer ) {
      $r = Win32::Console::_SetConsoleScreenBufferSize(ConsoleOutputHandle(), 
        $size->{X}, $size->{Y});
      if ( !$r ) {
        confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
      }
    }

    my $srWindow = $csbi->{srWindow};
    # Preserve the position, but change the size.
    $srWindow->{Bottom} = $srWindow->{Top} + $height - 1;
    $srWindow->{Right} = $srWindow->{Left} + $width - 1;

    $r = Win32::Console::_SetConsoleWindowInfo(ConsoleOutputHandle(), TRUE, 
      $srWindow->{Left}, $srWindow->{Top}, 
      $srWindow->{Right}, $srWindow->{Bottom}
    );
    if ( !$r ) {
      my $errorCode = Win32::GetLastError();

      # If we resized the buffer, un-resize it.
      if ( $resizeBuffer ) {
        Win32::Console::_SetConsoleScreenBufferSize(ConsoleOutputHandle(), 
          $csbi->{dwSize}->{X}, $csbi->{dwSize}->{Y});
      }

      # Try to give a better error message here
      my $bounds = { X => 0, Y => 0 };
      ($bounds->{X}, $bounds->{Y}) = 
        Win32::Console::_GetLargestConsoleWindowSize(ConsoleOutputHandle());
      if ( $width > $bounds->{X} ) {
        confess("ArgumentOutOfRangeException: width $width\n". 
          sprintf("$ResourceString{ArgumentOutOfRange_ConsoleWindowSize_Size}".
            "\n", $bounds->{X}));
      }
      if ( $height > $bounds->{Y} ) {
        confess("ArgumentOutOfRangeException: height $height\n". 
          sprintf("$ResourceString{ArgumentOutOfRange_ConsoleWindowSize_Size}".
            "\n", $bounds->{Y}));
      }

      confess(sprintf("WinIOError:\n%s\n", Win32::FormatMessage($errorCode)));
    }

    return;
  }

=item I<SetWindowPosition>

  method SetWindowPosition(Int $left, Int $top)

Sets the position of the console window relative to the screen buffer.

I<Param>: C<$left> corner of the console window.

I<Param>: C<$top> corner of the console window.

=cut

  sub SetWindowPosition {
    assert ( @_ == 3 );
    my $self = assert_Object shift;
    my $left = assert_Int shift;
    my $top = assert_Int shift;

    # Get the size of the current console window
    my $csbi = GetBufferInfo();

    my $srWindow = $csbi->{srWindow};

    # Check for arithmetic underflows & overflows.
    my $newRight = $left + $srWindow->{Right} - $srWindow->{Left} + 1;
    if ( $left < 0 || $newRight > $csbi->{dwSize}->{X} || $newRight < 0 ) {
      confess("ArgumentOutOfRangeException: left $left\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleWindowPos}\n");
    }
    my $newBottom = $top + $srWindow->{Bottom} - $srWindow->{Top} + 1;
    if ( $top < 0 || $newBottom > $csbi->{dwSize}->{Y} || $newBottom < 0 ) {
      confess("ArgumentOutOfRangeException: top $top\n". 
        "$ResourceString{ArgumentOutOfRange_ConsoleWindowPos}\n");
    }

    # Preserve the size, but move the position.
    $srWindow->{Bottom} -= $srWindow->{Top} - $top;
    $srWindow->{Right} -= $srWindow->{Left} - $left;
    $srWindow->{Left} = $left;
    $srWindow->{Top} = $top;

    my $r = Win32::Console::_SetConsoleWindowInfo(ConsoleOutputHandle(), TRUE, 
      $srWindow->{Left}, $srWindow->{Top}, 
      $srWindow->{Right}, $srWindow->{Bottom}
    );
    if ( !$r ) {
      confess("WinIOError:\n$EXTENDED_OS_ERROR\n");
    }

    return;
  }

=item I<Write>

  method Write(Str $format, Item $arg0, Item $arg1, ...)

Writes the text representation of the specified arguments to the standard 
output stream using the specified format information.

I<Param>: C<$format> is a composite format string.

I<Param>: C<$arg0> is the first item to write using format.

I<Param>: C<$arg1> is the second item to write using format.

I<Param>: ...

I<Throws>: I<IOException> if an I/O error occurred.

I<Throws>: I<ArgumentNullException> if C<$format> is C<undef>.

I<Remarks>: this method does not perform any formatting of its own: It uses the 
Perl's subroutine I<sprintf>.

  method Write(Int $value)

Writes the text representation of the specified integer value to the standard 
output stream.

I<Param>: C<$value> is the value to write.

I<Throws>: I<IOException> if an I/O error occurred.

  method Write(String $value)

Writes the specified string value to the standard output stream.

I<Param>: C<$value> is the value to write.

I<Throws>: I<IOException> if an I/O error occurred.

  method Write(Object $value)

Writes the text representation of the specified object to the standard output 
stream.

I<Param>: C<$value> is the value to write or C<undef>.

I<Throws>: I<IOException> if an I/O error occurred.

I<Remarks>: If C<$value> is C<undef>, nothing is written and no exception is 
thrown. Otherwise, the stringification method of C<$value> is called to produce 
its string representation, and the resulting string is written to the standard 
output stream.

  method Write(Num $value)

Writes the text representation of the specified floating-point value to the 
standard output stream.

I<Param>: C<$value> is the value to write.

I<Throws>: I<IOException> if an I/O error occurred.

  method Write(Bool $value)

Writes the text representation of the specified boolean value to the standard 
output stream.

I<Param>: C<$value> is the value to write.

I<Throws>: I<IOException> if an I/O error occurred.

=cut

  sub Write {
    assert ( @_ > 1 );
    my $self = assert_Object shift;

    assert_FileHandle $self->Out;
    $! = undef;
    if ( @_ > 1 ) {
      my $format = shift;
      if ( !defined $format ) {
        confess("ArgumentNullException:\n". 
          sprintf("$ResourceString{ArgumentNullException}\n", "format"));
      }
      no warnings 'uninitialized';
      $self->Out->printf($format, @_);
    } elsif ( @_ > 0 ) {
      $self->Out->print(shift);
    }
    confess("IOException:\n$OS_ERROR\n") if $!;
    return;
  }

=item I<WriteLine>

  method WriteLine(Str $format, Item $arg0, Item $arg1, ...)

Writes the text representation of the specified objects, followed by the 
current line terminator, to the standard output stream using the specified 
format information.

I<Param>: C<$format> is a composite format string.

I<Param>: C<$arg0> is the first item to write using format.

I<Param>: C<$arg1> is the second item to write using format.

I<Param>: ...

I<Throws>: I<IOException> if an I/O error occurred.

I<Throws>: I<ArgumentNullException> if C<$format> is C<undef>.

I<Remarks>: this method does not perform any formatting of its own: It uses the 
Perl's subroutine I<sprintf>.

  method WriteLine(String $value)

Writes the specified string value, followed by the current line terminator, to 
the standard output stream.

I<Param>: C<$value> is the value to write.

I<Throws>: I<IOException> if an I/O error occurred.

  method WriteLine(Int $value)

Writes the text representation of the specified integer value, followed by the 
current line terminator, to the standard output stream.

I<Param>: C<$value> is the value to write.

I<Throws>: I<IOException> if an I/O error occurred.

  method WriteLine(Num $value)

Writes the text representation of the specified floating-point value, followed 
by the current line terminator, to the standard output stream.

I<Param>: C<$value> is the value to write.

I<Throws>: I<IOException> if an I/O error occurred.

  method WriteLine(Bool $value)

Writes the text representation of the specified boolean value, followed by the 
current line terminator, to the standard output stream.

I<Param>: C<$value> is the value to write.

I<Throws>: I<IOException> if an I/O error occurred.

  method WriteLine()

Writes the current line terminator to the standard output stream.

I<Throws>: I<IOException> if an I/O error occurred.

  method WriteLine(Object $value)

Writes the text representation of the specified object, followed by the current
line terminator, to the standard output stream.

I<Param>: C<$value> is the value to write or C<undef>.

I<Throws>: I<IOException> if an I/O error occurred.

I<Remarks>: If C<$value> is C<undef> only the line terminator is written. 
Otherwise, the stringification method of C<$value> is called to produce its 
string representation, and the resulting string is written to the standard 
output stream.

=cut

  sub WriteLine {
    assert ( @_ > 0 );
    my $self = assert_Object shift;

    assert_FileHandle $self->Out;
    $! = undef;
    if ( @_ > 1 ) {
      # Intercept redundant warnings in Perl 5.22 and higher
      local $SIG{__WARN__} = sub {
        if ( $] >= 5.022 && warnings::enabled('redundant') ) {
          $_ = shift;
          s/\sat .+?\R$//;
          s/sprintf/WriteLine/g;
          Carp::carp($_);
        }
      };
      my $format = shift;
      if ( !defined $format ) {
        confess("ArgumentNullException:\n". 
          sprintf("$ResourceString{ArgumentNullException}\n", "format"));
      }
      no warnings 'uninitialized';
      $self->Out->say(sprintf($format, @_));
    } elsif ( @_ > 0 ) {
      $self->Out->say(shift);
    } else {
      $self->Out->say();
    }
    confess("IOException:\n$OS_ERROR\n") if $!;
    return;
  }

  # ------------------------------------------------------------------------
  # Subroutines ------------------------------------------------------------
  # ------------------------------------------------------------------------

  no namespace::clean;

=begin private

=item I<CheckOutputDebug>

  sub CheckOutputDebug() : Bool

Checks whether the developer mode is currently activated

I<Returns>: I<true> if the developer mode is currently enabled. 

I<Remarks>: It always returns I<false> on Windows versions older than 
Windows 10.

=cut

  # This is ONLY used in debug builds.  If you have a registry key set,
  # it will redirect Console->Out & Error on console-less applications to
  # your debugger's output window.
  sub CheckOutputDebug {
    return exists(&Win32::IsDeveloperModeEnabled)
        && Win32::IsDeveloperModeEnabled();
  }

=item I<ColorAttributeToConsoleColor>

  sub ColorAttributeToConsoleColor(Int $c) : Int

Converts the color attribute of the Windows console into a color constant.

I<Param>: C<$c> is a color attribute of the Windows Console. 

I<Returns>: a console color constant.

=cut

  sub ColorAttributeToConsoleColor {
    assert ( @_ == 1 );
    my $c = assert_Int shift;

    # Turn background colors into foreground colors.
    if ( ($c & 0xf0) != 0 ) {
      $c = $c >> 4;
    }

    return $c;
  }

=item I<ConsoleColorToColorAttribute>

  sub ConsoleColorToColorAttribute(Int $color, Bool $isBackground) : Int

Converts a color constant into the color attribute of the Windows Console.

I<Param>: C<$color> specifies a color constant that defines the foreground or 
background color.

I<Param>: C<$isBackground> specifies whether the specified color constant is a 
foreground or background color.

I<Returns>: a color attribute of the Windows Console.

=cut

  sub ConsoleColorToColorAttribute {
    assert ( @_ == 2 );
    my $color = assert_Int shift;
    my $isBackground = assert_Bool shift;

    if ( ($color & ~0xf) != 0 ) {
      confess("ArgumentException:\n".
        "$ResourceString{Arg_InvalidConsoleColor}\n");
    }

    my $c = $color;

    # Make these background colors instead of foreground
    if ( $isBackground ) {
      $c *= 16;
    }
    return $c;
  }

=item I<ConsoleHandleIsWritable>

  sub ConsoleHandleIsWritable(Int $outErrHandle) : Bool

Checks whether stdout or stderr are writable.  Do NOT pass
stdin here.

I<Param>: C<$outErrHandle> is a handle to a file or I/O device (for example 
file, console buffer or pipe). The parameter should be created with write 
access.

I<Returns>: I<true> if the specified handle is writable, otherwise I<false>. 

=cut

  sub ConsoleHandleIsWritable {
    assert ( @_ == 1 );
    my $outErrHandle = assert_Int shift;

    # Do NOT call this method on stdin!

    # Windows apps may have non-null valid looking handle values for 
    # stdin, stdout and stderr, but they may not be readable or 
    # writable.  Verify this by calling WriteFile in the 
    # appropriate modes.
    # This must handle console-less Windows apps.

    my $bytesWritten;
    my $junkByte = chr 0x41;
    # We use our own Windows API call for WriteFile because the Win32API::File 
    # version provides a different implementation for the use of the third 
    # parameter (nNumberOfBytesToWrite). 
    # According to the Windows API, it is intended that the value 0 performs a 
    # NULL write!
    require Win32Native;
    my $r = Win32Native::WriteFile($outErrHandle, $junkByte, 0, $bytesWritten, 
      undef);
    # In Win32 apps w/ no console, bResult should be false for failure.
    return !!$r;
  }

=item I<ConsoleInputHandle>

  sub ConsoleInputHandle() : Int

Simplifies the use of I<GetStdHandle(STD_INPUT_HANDLE)>.

I<Returns>: the standard input handle to the standard input device.

=cut

  sub ConsoleInputHandle {
    assert ( @_ == 0 );
    $_consoleInputHandle //= Win32::Console::_GetStdHandle(STD_INPUT_HANDLE);
    return $_consoleInputHandle;
  }

=item I<ConsoleOutputHandle>

  sub ConsoleOutputHandle() : Int

Simplifies the use of I<GetStdHandle(STD_OUTPUT_HANDLE)>.

I<Returns>: the standard output handle to the standard output device.

=cut

  sub ConsoleOutputHandle {
    assert ( @_ == 0 );
    $_consoleOutputHandle //= Win32::Console::_GetStdHandle(STD_OUTPUT_HANDLE);
    return $_consoleOutputHandle;
  }

=item I<GetBufferInfo>

  sub GetBufferInfo() : HashRef
  sub GetBufferInfo(Bool $throwOnNoConsole, Ref[Bool] $succeeded) : HashRef

Simplifies the use of I<GetConsoleScreenBufferInfo()>.

I<Param>: C<$throwOnNoConsole> must be set to I<true> if an exception is to be 
generated in the event of an error and I<false> if an empty input record is to 
be returned instead. 

I<Param>: C<$succeeded> [out] is I<true> if no error occurred and I<false> if an 
error occurred.

I<Returns>: an hash reference with information's about the console.

=cut

  sub GetBufferInfo {
    state $CONSOLE_SCREEN_BUFFER_INFO = {
      dwSize => {
        X => 0,
        Y => 0,
      },
      dwCursorPosition => {
        X => 0,
        Y => 0,
      },
      wAttributes => 0,
      srWindow => {
        Left    => 0,
        Top     => 0,
        Right   => 0,
        Bottom  => 0,
      },
      dwMaximumWindowSize => {
        X => 0,
        Y => 0,
      },
    };

    assert ( @_ == 0 || @_ == 2 );
    my $throwOnNoConsole = @_ ? assert_Bool(shift) : TRUE;
    my $succeeded = @_ ? do { assert_Bool(${$_[0]}); shift }
                       : do { my $junk; \$junk };

    $$succeeded = FALSE;
    my @csbi;
    my $success;

    my $hConsole = ConsoleOutputHandle();
    if ( $hConsole == Win32API::File::INVALID_HANDLE_VALUE ) {
      if ( !$throwOnNoConsole ) {
        return { %$CONSOLE_SCREEN_BUFFER_INFO };
      }
      else {
        confess("IOException:\n$ResourceString{IO_NoConsole}\n");
      }
    }

    # Note that if stdout is redirected to a file, the console handle
    # may be a file.  If this fails, try stderr and stdin.
    $success = do {
      @csbi = Win32::Console::_GetConsoleScreenBufferInfo($hConsole);
      @csbi > 1;
    };
    if ( !$success ) {
      $success = do {
        @csbi = Win32::Console::_GetConsoleScreenBufferInfo(
          Win32::Console::_GetStdHandle(STD_ERROR_HANDLE)
        );
        @csbi > 1;
      };
      if ( !$success ) {
        $success = do {
          @csbi = Win32::Console::_GetConsoleScreenBufferInfo(
            Win32::Console::_GetStdHandle(STD_INPUT_HANDLE)
          );
          @csbi > 1;
        };
      }

      if ( !$success ) {
        my $errorCode = Win32::GetLastError();
        if ( $errorCode == Win32Native::ERROR_INVALID_HANDLE
          && !$throwOnNoConsole
        ) {
          return { %$CONSOLE_SCREEN_BUFFER_INFO };
        }
        confess(sprintf("WinIOError:\n%s\n", 
          Win32::FormatMessage($errorCode)));
      }
    }

    if ( !$_haveReadDefaultColors ) {
      # Fetch the default foreground and background color for the
      # ResetColor method.
      $$_defaultColors = $csbi[wAttributes] & 0xff;
      $_haveReadDefaultColors = TRUE;
    }

    $$succeeded = TRUE;
    return {
      dwSize => {
        X => $csbi[dwSizeX],
        Y => $csbi[dwSizeY],
      },
      dwCursorPosition => {
        X => $csbi[dwCursorPositionX],
        Y => $csbi[dwCursorPositionY],
      },
      wAttributes => $csbi[wAttributes],
      srWindow => {
        Left    => $csbi[srWindowLeft],
        Top     => $csbi[srWindowTop],
        Right   => $csbi[srWindowRight],
        Bottom  => $csbi[srWindowBottom],
      },
      dwMaximumWindowSize => {
        X => $csbi[dwMaximumWindowSizeX],
        Y => $csbi[dwMaximumWindowSizeY],
      },
    }
  }

=item I<GetStandardFile>

  sub GetStandardFile(Int $stdHandleName, Str $access, 
    Int $bufferSize) : FileHandle

This subroutine is only exposed via methods to get at the console.
We won't use any security checks here.

I<Param>: C<$stdHandleName> specified the standard device (C<STD_INPUT_HANDLE>, 
C<STD_OUTPUT_HANDLE> or C<STD_ERROR_HANDLE>).

I<Param>: C<$access> - the possible values of the C<$access> parameter are 
system-dependent. See the documentation of L<Win32API::File/"OsFHandleOpen"> 
to see which values are available.

I<Param>: C<$bufferSize> buffer size.

I<Returns>: a I<FileHandle> of the specified standard device 
(C<STD_INPUT_HANDLE>, C<STD_OUTPUT_HANDLE> or C<STD_ERROR_HANDLE>) or 
L<IO::Null> in the event of an error.

=cut

  sub GetStandardFile {
    assert ( @_ == 3 );
    my $stdHandleName = assert_Int shift;
    my $access = assert_Str shift;
    my $bufferSize = assert_Int shift;

    # We shouldn't close the handle for stdout, etc, or we'll break
    # unmanaged code in the process that will print to console.
    # We should have a better way of marking this on SafeHandle.
    my $handle = Win32::Console::_GetStdHandle($stdHandleName);

    # If someone launches a managed process via CreateProcess, stdout
    # stderr, & stdin could independently be set to INVALID_HANDLE_VALUE.
    # Additionally they might use 0 as an invalid handle.
    if ( !$handle || $handle == Win32API::File::INVALID_HANDLE_VALUE ) {
      return IO::Null->new();
    }

    # Check whether we can read or write to this handle.
    if ( $stdHandleName != STD_INPUT_HANDLE 
      && !ConsoleHandleIsWritable($handle)
    ) {
      # Win32::OutputDebugString(sprintf("Console::ConsoleHandleIsValid for ".
      #   "std handle %ld failed, setting it to a null stream", 
      #   $stdHandleName)) if _DEBUG;
      return IO::Null->new();
    }

    my $useFileAPIs = GetUseFileAPIs($stdHandleName);

    # Win32::OutputDebugString(sprintf("Console::GetStandardFile for std ".
    #   "handle %ld succeeded, returning handle number %d", 
    #   $stdHandleName, $handle)) if _DEBUG;
    my $console = IO::Handle->new();
    my $sh = SafeFileHandle($console, FALSE);
    if ( !Win32API::File::OsFHandleOpen($sh, $handle, $access) ) {
      return IO::Null->new();
    }
    # Do not buffer console streams, or we can get into situations where
    # we end up blocking waiting for you to hit enter twice.  It was
    # redundant.
    return $console;
  }

=item I<GetUseFileAPIs>

  sub GetUseFileAPIs(Int $handleType) : Bool

This subroutine checks whether the file API should be used.

I<Param>: C<$handleType> specified the standard device (C<STD_INPUT_HANDLE>, 
C<STD_OUTPUT_HANDLE> or C<STD_ERROR_HANDLE>).

I<Returns>: I<true> if the specified handle should use the Window File API for 
console access, or I<false> if the Windows Console API should rather be used. 

=cut

  sub GetUseFileAPIs {
    assert ( @_ == 1 );
    my $handleType = assert_Int shift;

    switch: for ($handleType) {

      case: $_ == STD_INPUT_HANDLE and
        return !IsStandardConsoleUnicodeEncoding(__PACKAGE__->InputEncoding) 
          || __PACKAGE__->IsInputRedirected;

      case: $_ == STD_OUTPUT_HANDLE and
        return !IsStandardConsoleUnicodeEncoding(__PACKAGE__->OutputEncoding) 
          || __PACKAGE__->IsOutputRedirected;

      case: $_ == STD_ERROR_HANDLE and 
        return !IsStandardConsoleUnicodeEncoding(__PACKAGE__->OutputEncoding) 
          || __PACKAGE__->IsErrorRedirected;

      default: {
        # This can never happen.
        confess("Unexpected handleType value ($handleType)") if STRICT;
        return TRUE;
      }
    }
  }

=item I<InitializeStdOutError>

  sub InitializeStdOutError(Bool $stdout)

Initialization of standard output or standard error handle.

I<Param>: C<$stdout> is I<true> if a standard output handle is to be 
initialized and I<false> if a standard error handle is to be initialized.

=cut

  # For console apps, the console handles are set to values like 3, 7, 
  # and 11 OR if you've been created via CreateProcess, possibly -1
  # or 0.  -1 is definitely invalid, while 0 is probably invalid.
  # Also note each handle can independently be invalid or good.
  # For Windows apps, the console handles are set to values like 3, 7, 
  # and 11 but are invalid handles - you may not write to them.  However,
  # you can still spawn a Windows app via CreateProcess and read stdout
  # and stderr.
  # So, we always need to check each handle independently for validity
  # by trying to write or read to it, unless it is -1.

  # We do not do a security check here, under the assumption that this
  # cannot create a security hole, but only waste a user's time or 
  # cause a possible denial of service attack.
  sub InitializeStdOutError {
    assert ( @_ == 1 );
    my $stdout = assert_Bool shift;

    # Set up Console->Out or Console->Error.
    { 
      lock($InternalSyncObject);
      if ( $stdout && $_out ) {
        return;
      } elsif ( !$stdout && $_error ) {
        return;
      }

      my $writer;
      my $s;
      if ( $stdout ) {
        $s = __PACKAGE__->OpenStandardOutput(DefaultConsoleBufferSize);
      } else {
        $s = __PACKAGE__->OpenStandardError(DefaultConsoleBufferSize);
      }

      if ( !$s ) {
        if ( _DEBUG && CheckOutputDebug() ) {
          $writer = MakeDebugOutputTextWriter($stdout 
            ? "Console->Out: " 
            : "Console->Error: "
          );
        } else {
          $writer = IO::Null->new();
        }
      }
      else {
        my $encoding = __PACKAGE__->OutputEncoding;
        my $cpi = $encoding->$CodePage();
        $cpi ||= $stdout ? Win32::GetConsoleOutputCP() : Win32::GetACP();
        my $stdxxx = IO::File->new_from_fd(fileno($s), 'w');
        $stdxxx->binmode(":encoding(cp$cpi)");
        $stdxxx->autoflush(TRUE);
        $writer = $stdxxx;
      }
      if ( $stdout ) {
        $_out = $writer;
      } else {
        $_error = $writer;
      }
      assert ( $stdout && $_out || !$stdout && $_error 
        or ~- warn "Didn't set Console::_out or _error appropriately!" 
      );
    }
    return;
  }

=item I<IsAltKeyDown>

  sub IsAltKeyDown(ArrayRef $ir) : Bool

For tracking Alt+NumPad unicode key sequence.

I<Param>: C<$ir> is an array reference to a KeyEvent input record.

I<Returns>: I<true> if C<Alt> key is pressed, otherwise I<false>.

=cut

  # For tracking Alt+NumPad unicode key sequence. When you press Alt key down 
  # and press a numpad unicode decimal sequence and then release Alt key, the
  # desired effect is to translate the sequence into one Unicode KeyPress. 
  # We need to keep track of the Alt+NumPad sequence and surface the final
  # unicode char alone when the Alt key is released. 
  sub IsAltKeyDown { 
    assert ( @_ == 1 );
    my $ir = assert_ArrayRef shift;

    return ($ir->[controlKeyState] 
      & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) != 0;
  }

=item I<IsHandleRedirected>

  sub IsHandleRedirected(Int $ioHandle) : Bool

Detects if a console handle has been redirected.

I<Param>: C<$ioHandle> is a Windows IO handle (for example a handle of a file, 
a console or a pipe).

I<Returns>: I<true> if the specified handle is redirected, otherwise I<false>.

=cut

  sub IsHandleRedirected {
    assert ( @_ == 1 );
    my $ioHandle = assert_Int shift;

    assert ( $ioHandle );
    assert ( $ioHandle != Win32API::File::INVALID_HANDLE_VALUE );

    # If handle is not to a character device, we must be redirected:
    my $fileType = Win32API::File::GetFileType($ioHandle) // 0;
    if ( ($fileType & Win32API::File::FILE_TYPE_CHAR) 
      != Win32API::File::FILE_TYPE_CHAR 
    ) {
      return TRUE;
    }

    # We are on a char device.
    # If GetConsoleMode succeeds, we are NOT redirected.
    my $mode;
    my $success = do {
      Win32::SetLastError(0);
      $mode = Win32::Console::_GetConsoleMode($ioHandle) || 0;
      Win32::GetLastError() == 0;
    };
    return !$success;
  };

=item I<IsKeyDownEvent>

  sub IsKeyDownEvent(ArrayRef $ir) : Bool

To detect pure KeyDown events.

I<Param>: C<$ir> is an array reference to a KeyEvent input record.

I<Returns>: I<true> on a KeyDown event, otherwise I<false>.

=cut

  # Skip non key events. Generally we want to surface only KeyDown event 
  # and suppress KeyUp event from the same Key press but there are cases
  # where the assumption of KeyDown-KeyUp pairing for a given key press 
  # is invalid. For example in IME Unicode keyboard input, we often see
  # only KeyUp until the key is released.  
  sub IsKeyDownEvent {
    assert ( @_ == 1 );
    my $ir = assert_ArrayRef shift;

    return $ir->[eventType] == Win32Native::KEY_EVENT && $ir->[keyDown];
  }

=item I<IsModKey>

  sub IsModKey(ArrayRef $ir) : Bool

Detects if the KeyEvent uses a mod key.

I<Param>: C<$ir> is an array reference to a KeyEvent input record.

I<Returns>: I<true> if the KeyEvent uses a mod key, otherwise I<false>.

=cut

  sub IsModKey {
    assert ( @_ == 1 );
    my $ir = assert_ArrayRef shift;

    # We should also skip over Shift, Control, and Alt, as well as caps lock.
    # Apparently we don't need to check for 0xA0 through 0xA5, which are keys 
    # like Left Control & Right Control. See the Microsoft 'ConsoleKey' for 
    # these values.
    my $keyCode = $ir->[virtualKeyCode];
    return  ($keyCode >= VK_SHIFT && $keyCode <= AltVKCode) 
          || $keyCode == CapsLockVKCode 
          || $keyCode == NumberLockVKCode 
          || $keyCode == VK_SCROLL
  }

=item I<IsStandardConsoleUnicodeEncoding>

  sub IsStandardConsoleUnicodeEncoding(Object $encoding) : Bool

Test if standard console Unicode encoding is activated.

I<Param>: C<$encoding> contains a L<Encode::Encoding> object.

I<Returns>: I<true> if the encoding uses a Windows Unicode encoding or I<false> 
if not.

=cut

  # We cannot simply compare the encoding to Encode::Unicode because it 
  # incorporates BOM and we do not care about BOM. Instead, we compare by 
  # class, codepage and little-endianess only:
  sub IsStandardConsoleUnicodeEncoding {
    assert ( @_ == 1 );
    my $encoding = assert_Object shift;

    my $enc = $encoding->isa('Encode::Unicode') ? $encoding : undef;
    return FALSE if !$enc;

    return StdConUnicodeEncoding->name eq $enc->name
        && StdConUnicodeEncoding->{endian} eq $enc->{endian};
  }

=item I<MakeDebugOutputTextWriter>

  sub MakeDebugOutputTextWriter(Str $streamLabel) : IO::Handle

Creates an I<IO::DebugOutputTextWriter> object (derived from L<IO::Handle>) 
and returns it.

I<Param>: C<$streamLabel> contains a string which is prefixed to each output.

I<Returns>: of an L<IO::Handle> of type I<IO::DebugOutputTextWriter>.

=cut

  sub MakeDebugOutputTextWriter {
    require IO::DebugOutputTextWriter;
    assert ( @_ == 1 );
    my $streamLabel = assert_Str shift;
    my $output = IO::DebugOutputTextWriter->new($streamLabel);
    $output->print("Output redirected to debugger from a bit bucket.");
    return $output;
  }

=item I<SafeFileHandle>

  sub SafeFileHandle(FileHandle $preexistingHandle, 
    Bool $ownsHandle) : FileHandle;

Create a reference to safe an existing file handle.

I<Param>: C<$preexistingHandle> is an I<FileHandle> that represents the 
pre-existing file handle to use.

I<Param>: C<$ownsHandle> should be set to I<true> to reliably release the file 
handle during the closing phase; I<false> to prevent release.

I<Returns>: the specified I<FileHandle>.

=cut

  sub SafeFileHandle {
    assert ( @_ == 2 );
    my $preexistingHandle = assert_FileHandle shift;
    my $ownsHandle = assert_Bool shift;

    my $hNativeHandle = Win32API::File::GetOsFHandle($preexistingHandle);
    if ( $hNativeHandle 
      && $hNativeHandle != Win32API::File::INVALID_HANDLE_VALUE
    ) {
      my $ouFlags = 0;
      if ( Win32API::File::GetHandleInformation($hNativeHandle, $ouFlags)
        && $ouFlags & Win32API::File::HANDLE_FLAG_PROTECT_FROM_CLOSE
      ) {
        $ownsHandle = FALSE;
      }
    }
    if ( !$ownsHandle ) {
      $_leaveOpen->{$preexistingHandle} = $preexistingHandle;
    } else {
      delete $_leaveOpen->{$preexistingHandle};
    }
    return $preexistingHandle;
  }

=end private

=back

=cut

  use namespace::clean;

=head2 Inheritance

Methods inherited from class L<UNIVERSAL>

  can, DOES, isa, VERSION

=cut

}

1;

# ------------------------------------------------------------------------
# Additional Packages ----------------------------------------------------
# ------------------------------------------------------------------------

# see SYNOPSIS using this code
#-------
package # hidden from CPAN
System {
#-------
  use strict;
  use warnings;
  use Exporter qw( import );
  our @EXPORT = qw( Console );
  sub Console() {
    require Win32::Console::DotNet;
    state $instance = Win32::Console::DotNet->instance();
  }
  $INC{'System.pm'} = 1;
}

# see Utilapiset.h and Winuser.h documentation for Beep() and GetKeyState()
#------------
package # hidden from CPAN
Win32Native {
#------------
  use strict;
  use warnings;
  use English qw( -no_match_vars );
  use Win32::API;
  use constant {
    KERNEL32  => 'kernel32',
    USER32    => 'user32',
  };
  BEGIN {
    Win32::API::More->Import(KERNEL32, 
      'BOOL Beep(DWORD dwFreq, DWORD dwDuration)'
    ) or die "Import Beep: $EXTENDED_OS_ERROR";
    Win32::API::More->Import(USER32, 
      'int GetKeyState(int nVirtKey)'
    ) or die "Import GetKeyState: $EXTENDED_OS_ERROR";
    Win32::API::More->Import(KERNEL32,
      'BOOL WriteFile(
        HANDLE    hFile,
        LPCSTR    lpBuffer,
        DWORD     nNumberOfBytesToWrite,
        LPDWORD   lpNumberOfBytesWritten,
        LPVOID    lpOverlapped
      )'
    ) or die "Import WriteFile: $EXTENDED_OS_ERROR";
  }
  $INC{'Win32Native.pm'} = 1;
}

# Most of the content was taken from L</IO::Null>, L</IO::String> and 
# I<system.io.__debugoutputtextwriter.cs>
#--------------------------
package # hidden from CPAN
IO::DebugOutputTextWriter {
#--------------------------
  use strict;
  use warnings;
  use Symbol ();
  use IO::Handle ();
  use Win32;
  our @ISA = qw(IO::Handle);
 
  *CLOSE = *WRITE =
  *close = *write =
  *opened = *eof = *syswrite = *ungetc = *clearerr = *flush =
  *binmode = sub { 1 };

  *TELL = *FILENO =
  *tell = *fileno = sub { -1 };

  *GETC = *READ =
  *getc = *read = *sysread = *error = *getline = sub { '' };

  sub readline {
    return () if wantarray;
    return '';
  }
  *READLINE = \&readline;

  sub getlines { return () }
  sub DESTROY { 1 }

  sub new { # $handle ($class, | $consoleType)
    my $class = shift;
    my $self = bless Symbol::gensym(), ref($class) || $class;
    tie *$self, $self;
    $self->open(@_);
    return $self;
  }
  *new_from_fd = *fdopen = \&new;

  sub open { # $handle ($handle, | $consoleType)
    my $self = shift;
    return $self->new(@_) unless ref($self);
    my $consoleType = shift // '';
    *$self->{_consoleType} = "$consoleType";
    return $self;
  }
  *OPEN = \&open;
 
  sub print { # $success ($handle, @list)
    return undef unless ref(shift);
    Win32::OutputDebugString(join $,//'', @_);
    return 1;
  }
  *PRINT = \&print;

  sub printf { # $success ($handle, $format, @list)
    return undef unless ref(shift);
    Win32::OutputDebugString(sprintf(shift, @_));
    return 1;
  }
  *PRINTF = \&printf;

  sub say { # $success ($handle, @list)
    my $self = shift;
    return undef unless ref($self);
    if ( defined $_[0] ) {
      my $consoleType = *$self->{_consoleType} // '';
      Win32::OutputDebugString(join $,//'', $consoleType, @_);
    } else {
      Win32::OutputDebugString('<null>');
    }
    Win32::OutputDebugString("\n");
    return 1;
  }

  sub TIEHANDLE {
    return $_[0] if ref($_[0]);
    my $class = shift;
    my $self = bless Symbol::gensym(), $class;
    $self->open(@_);
    return $self;
  }

  $INC{'IO/DebugOutputTextWriter.pm'} = 1;
}

# Specifies constants that define foreground and background colors for the 
# console.
#---------------------
package ConsoleColor {
#---------------------
  use strict;
  use warnings;
  use constant _enum => qw(
    Black
    DarkBlue
    DarkGreen
    DarkCyan
    DarkRed
    DarkMagenta
    DarkYellow
    Gray
    DarkGray
    Blue
    Green
    Cyan
    Red
    Magenta
    Yellow
    White
  );
  BEGIN {
    eval "use constant (_enum)[$_] => $_;" foreach 0..(_enum)-1;
  }
  # Returns all valid names (Str) in the enumeration as a list.
  use constant elements =>  grep {defined} _enum;
  # Returns a list of all values (Int) of the enumeration.
  use constant values   =>  grep {defined((_enum)[$_])} 0..(_enum)-1;
  # Returns the number of elements (Int) in the array.
  use constant count    => +grep {defined} _enum;
  # Returns an element (Str) of the array by it's index (Int). You can also 
  # use negative index numbers, just as with Perl's core array handling.
  # If the specified element does not exist, this will return undef.
  sub get { # $name (|$class, $value)
    shift if @_ > 1 && defined($_[0]) && $_[0] eq __PACKAGE__;
    my $key = shift // return;
    (_enum)[$key];
  };
  $INC{'ConsoleColor.pm'} = 1;
}

# Specifies the standard keys on a console.
#-------------------
package ConsoleKey {
#-------------------
  use strict;
  use warnings;
  use constant _enum => qw(
    None
  ), (undef) x 7, qw(
    Backspace
    Tab
  ), (undef) x 2, qw(
    Clear
    Enter
  ), (undef) x 5, qw(
    Pause
  ), (undef) x 7, qw(
    Escape
  ), (undef) x 4, qw(
    Spacebar
    PageUp
    PageDown
    End
    Home
    LeftArrow
    UpArrow
    RightArrow
    DownArrow
    Select
    Print
    Execute
    PrintScreen
    Insert
    Delete
    Help
    D0
    D1
    D2
    D3
    D4
    D5
    D6
    D7
    D8
    D9
  ), (undef) x 7, qw(
    A
    B
    C
    D
    E
    F
    G
    H
    I
    J
    K
    L
    M
    N
    O
    P
    Q
    R
    S
    T
    U
    V
    W
    X
    Y
    Z
    LeftWindows
    RightWindows
    Applications
  ), (undef) x 1, qw(
    Sleep
    NumPad0
    NumPad1
    NumPad2
    NumPad3
    NumPad4
    NumPad5
    NumPad6
    NumPad7
    NumPad8
    NumPad9
    Multiply
    Add
    Separator
    Subtract
    Decimal
    Divide
    F1
    F2
    F3
    F4
    F5
    F6
    F7
    F8
    F9
    F10
    F11
    F12
    F13
    F14
    F15
    F16
    F17
    F18
    F19
    F20
    F21
    F22
    F23
    F24
  ), (undef) x 30, qw(
    BrowserBack
    BrowserForward
    BrowserRefresh
    BrowserStop
    BrowserSearch
    BrowserFavorites
    BrowserHome
    VolumeMute
    VolumeDown
    VolumeUp
    MediaNext
    MediaPrevious
    MediaStop
    MediaPlay
    LaunchMail
    LaunchMediaSelect
    LaunchApp1
    LaunchApp2
  ), (undef) x 2, qw(
    Oem1
    OemPlus
    OemComma
    OemMinus
    OemPeriod
    Oem2
    Oem3
  ), (undef) x 26, qw(
    Oem4
    Oem5
    Oem6
    Oem7
    Oem8
  ), (undef) x 2, qw(
    Oem102
  ), (undef) x 2, qw(
    Process
  ), (undef) x 1, qw(
    Packet
  ), (undef) x 14, qw(
    Attention
    CrSel
    ExSel
    EraseEndOfFile
    Play
    Zoom
    NoName
    Pa1
    OemClear
  );
  BEGIN {
    eval "use constant (_enum)[$_] => $_;" foreach 0..(_enum)-1;
  }
  use constant elements =>  grep {defined} _enum;
  use constant values   =>  grep {defined((_enum)[$_])} 0..(_enum)-1;
  use constant count    => +grep {defined} _enum;
  sub get { # $name (|$class, $value)
    shift if @_ > 1 && defined($_[0]) && $_[0] eq __PACKAGE__;
    my $key = shift // return;
    (_enum)[$key];
  };
  $INC{'ConsoleKey.pm'} = 1;
}

# Describes the console key that was pressed, including the character 
# represented by the console key and the state of the SHIFT, ALT, and CTRL 
# modifier keys.
#-----------------------
package ConsoleKeyInfo {
#-----------------------
  use strict;
  use warnings;
  use Carp qw( confess );
  use Data::Dumper;
  use Scalar::Util qw( looks_like_number );

  sub new { # $object ($class, \%arg | @args)
    my $class = shift;
    return unless $class && (@_ == 0 || @_ == 1 || @_ == 5);
    my $self;
    if ( @_ == 0 ) {
      $self = {
        KeyChar => "\0",
        Key => 0,
        Modifiers => 0,
      }
    } elsif ( @_ == 1 ) {
      return unless ref($_[0])
        && length($_[0]->{KeyChar}) 
        && looks_like_number($_[0]->{Key}) 
        && looks_like_number($_[0]->{Modifiers});
      $self = $_[0];
    } else {
      return unless length($_[0])
        && looks_like_number($_[1]);
      $self = {
        KeyChar => $_[0],
        Key => $_[1],
        Modifiers => ($_[2] ? 2 : 0) | ($_[3] ? 1 : 0) | ($_[4] ? 4 : 0),
      }
    }
    confess 'ArgumentOutOfRangeException' unless
      $self->{Key} >= 0 && $self->{Key} <= 255;
    return bless $self, $class;
  }

  sub Key { # $key ($self)
    my $self = shift;
    return if !ref($self) || @_;
    return $self->{Key};
  }

  sub KeyChar { # $keyChar ($self)
    my $self = shift;
    return if !ref($self) || @_;
    return $self->{KeyChar};
  }

  sub Modifiers { # $modifiers ($self)
    my $self = shift;
    return if !ref($self) || @_;
    return $self->{Modifiers};
  }

  sub Equals { # $bool ($lhs, $rhs)
    my ($lhs, $rhs) = @_;
    return unless ref($lhs) && ref($rhs) && @_ == 2;
    return ref($lhs)         eq ref($rhs)
        && $lhs->{Key}       == $rhs->{Key}
        && $lhs->{KeyChar}   eq $rhs->{KeyChar}
        && $lhs->{Modifiers} eq $rhs->{Modifiers};
  }

  sub ToString {
    my $self = shift;
    return if !ref($self) || @_;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Sortkeys = 1;
    return Dumper({ %$self });
  }

  use overload (
    '""' => sub { ToString(shift) },
    'eq' => sub { Equals(shift, shift) },
    'ne' => sub { !Equals(shift, shift) },
  );

  $INC{'ConsoleKeyInfo.pm'} = 1;
}

# Represents the SHIFT, ALT, and CTRL modifier keys on a keyboard.
#-------------------------
package ConsoleModifiers {
#-------------------------
  use strict;
  use warnings;
  use constant _enum => qw(
    None
    Alt
    Shift
  ), (undef) x 1, qw(
    Control
  );
  BEGIN {
    eval "use constant (_enum)[$_] => $_;" foreach 0..(_enum)-1;
  }
  use constant elements => grep {defined} _enum;
  use constant values   => grep {defined((_enum)[$_])} 0..(_enum)-1;
  use constant count    => +grep {defined} _enum;
  sub get {
    shift if @_ > 1 && defined($_[0]) && $_[0] eq __PACKAGE__;
    my $key = shift // return;
    (_enum)[$key];
  };
  $INC{'ConsoleModifiers.pm'} = 1;
}

__END__

=head1 DEPENDENCIES

This module is based on L<Win32::Console>. Additionally, there are only a few 
dependencies on non-core modules.

The requirements necessary for the runtime are listed below:

=over

=item * L<5.014|http://metacpan.org/release/DAPM/perl-5.14.4>

=item * L<Devel::Assert>

=item * L<Devel::StrictMode>

=item * L<IO::Null>

=item * L<namespace::clean> 

=item * L<Win32::API> 

=item * L<Win32::Console> 

=back

=head1 COPYRIGHT AND LICENCE

 This class provides access to the standard input, standard output
 and standard error streams

 Copyright (c) 2015 by Microsoft Corporation.

 The library files are licensed under MIT licence.

 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

=head1 AUTHORS

=over

=item *

2024, 2025 by J. Schneider E<lt>brickpool@cpan.orgE<gt>

=back

=head1 DISCLAIMER OF WARRANTIES

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

=head1 CONTRIBUTORS

=over

=item *

2008, 2009 by Piotr Roszatycki E<lt>dexter@cpan.orgE<gt> (Code snippet from 
L<constant::boolean>)

=item *

2013-2014, 2017-2023 by Toby Inkster E<lt>tobyink@cpan.orgE<gt> (Code snippet 
from L<Types::Standard> and L<Type::Nano>)

=item *

2020 by Jens Rehsack E<lt>rehsack@cpan.orgE<gt> (Code snippet from 
L<Params::Util::PP>)

=back

=head1 SEE ALSO

L<Win32::Console>, 
L<console.cs|https://github.com/microsoft/referencesource/blob/51cf7850defa8a17d815b4700b67116e3fa283c2/mscorlib/system/console.cs>

=cut
