@rem = q{--* Perl *--
@::# (emacs/sublime) -*- mode: perl; tab-width: 4; coding: dos; -*-
@::# "bin/xx.bat" 0.960 (from "PL.#no-dist/bin/xx.bat.PL")
@setlocal &:: localize ENV changes until sourcing is pending
@echo off
:: eXpand and eXecute command line
:: similar to linux xargs

:: ToDO: perl must be referenced here as 'perl.exe' to avoid infinite recursion if this is called via a 'perl.BAT' batch script as "xx perl.exe $*"; using shell aliasing will avoid this complication, but is there another way to keep the script here clean of expectation of perl as PERL.EXE?
:: ToDO: clean up documentation/comments
:: ToDO: remove TCC/4NT compatiblity code

:: parent environment is kept untouched except as modified by "sourcing" of target command line text or executable output
:: contains batch file techniques to allow "sourcing" of target command line text or executable output
:: :"sourcing" => running commands in the parents environmental context, allowing modification of parents environment variables and current working directory (CWD)

:: NOTE: TCC/4NT quirk => use %% for %, whereas CMD.exe % => as long as it does not introduce a known variable (eg, for CMD, %not_a_var => %not_a_var although %windir => C:\WINDOWS)

set "ERRORLEVEL=" &:: defensively reset ERRORLEVEL (avoiding any prior pinned value)

set _xx_bat=nul

::echo *=%*

if [%1]==[-s]  ( goto :find_unique_temp )
if [%1]==[-so] ( goto :find_unique_temp )
goto :find_unique_temp_PASS

:: find bat file for sourcing and instantiate it with a 1st line of text
:find_unique_temp
set _xx_bat="%temp%\xx.bat.source.%RANDOM%.%RANDOM%.bat"
if EXIST %_xx_bat% ( goto :find_unique_temp )
echo @:: %_xx_bat% TEMPORARY file > %_xx_bat%
:find_unique_temp_PASS

:: %_xx_bat% is now quoted [or it is simply "nul" and doesn't need quotes]
::echo _xx_bat=%_xx_bat%

:: TCC/4NT
:: DISABLE [1] TCC command aliasing (aliasing may loop if perl is aliased to use this script to sanitize its arguments), [2] over-interpretation of % characters, [3] redirection, [4] backquote removal from commands
if 01 == 1.0 ( setdos /x-14567 )

if NOT [%_xx_bat%]==[nul] ( goto :source_expansion )
::echo "perl output - no -s/-so"
::perl.exe -x -S %0 %*      &:: if needed to avoid infinite recursion while using a PERL.BAT script
perl -x -S %0 %*
set "_ERROR=%ERRORLEVEL%" &:: save ERRORLEVEL into _ERROR for later processing
if "%_ERROR%" == "0" ( goto :NO_EXIT_ERROR )
perl -e "exit 0"
if NOT "%ERRORLEVEL%" == "0" (
    echo "ERROR: perl is required, but it is not executable; please install Perl and/or add perl to the PATH [see http://strawberryperl.com]"
    )
:: propagate ERRORLEVEL (via %_ERROR%)
goto #_undefined_label_# 2>nul || "%COMSPEC%" /d /c exit %_ERROR%
:NO_EXIT_ERROR
endlocal
goto :_DONE

:source_expansion
:: sourcing COMMAND vs command OUTPUT is handled within the perl portion of the script (so, handle both the same within the BAT)
:: setdos /x0 needed? how about for _xx_bat execution? anyway to save RESET back to prior settings without all env vars reverting too? check via TCC help on setdos and endlocal
:: ? how to set setdos back to previous value instead of /x0 -- prob must use endlocal to do this
:: ? need to reset setdos PRIOR to executing perl -s -S ... ?
if 01 == 1.0 ( setdos /x0 )
echo @echo OFF >> %_xx_bat%
::echo perl output [source expansion { perl -x -S %0 %* }]
::perl.exe -x -S %0 %* >> %_xx_bat%     &:: if needed to avoid infinite recursion while using a PERL.BAT script
perl -x -S %0 %* >> %_xx_bat%
set _ERROR=%ERRORLEVEL%
::echo "sourcing - BAT created"
if NOT "%_ERROR%" == "0" (
::  echo _ERROR=%ERROR%
    erase %_xx_bat% 1>nul 2>nul
    perl -e 0
    if "%ERRORLEVEL%" == "0" (
        echo "ERROR: perl is required, but it is not executable; please install and/or add perl to the PATH"
        )
    goto #_undefined_label_# 2>nul || "%COMSPEC%" /d /c exit %_ERROR%
    )
::echo "sourcing & cleanup..."
:: propagate exit code from _xx_bat after it is sourced
endlocal & call :source_and_erase %_xx_bat%
if NOT "%ERRORLEVEL" == "0" ( set "ERRORLEVEL=" & goto #_undefined_label_# 2>nul || "%COMSPEC%" /d /c exit %_ERROR% )
set "ERRORLEVEL=" &:: un-pin ERRORLEVEL
goto :_DONE

::
:source_and_erase &:: ( SOURCE_FILE ) ## SOURCE_FILE is already quoted, if needed
:: NOTE: returns with ERRORLEVEL *pinned* to the value obtained while sourcing SOURCE_FILE
::echo [exec "%1%"]
call %1
set "ERRORLEVEL=%ERRORLEVEL%" &:: pin ERRORLEVEL prior to erase (which resets it based on outcome)
::echo FINAL [erase TEMP (file=%1)]
erase %1 1>nul 2>nul
goto :EOF
::

:_DONE
goto :endofperl
@rem };
#!perl -w --
#NOTE: use '#line NN' (where NN = actual_line_number + 1) to set perl line # for errors/warnings; NOTE: 'actual_line_number' is from the *output* file not the template
#line 104

## TODO: add normal .pl utility documentation/POD, etc [IN PROCESS]

# xx [OPTIONS] <command> <arg(s)>
# execute <command> with parsed <arg(s)>
# BAT file to work around Win32 I/O redirection bugs with execution of '.pl' files via the standard Win32 filename extension execution mechanism (see URLref: [pl2bat : ADVANTAGES] http://search.cpan.org/dist/perl/win32/bin/pl2bat.pl#ADVANTAGES , specifically regarding pipelines and redirection for further explanation)
# see linux 'xargs' and 'source' commands for something similar
# FIXED (for echo): note: command line args are dequoted so commands taking string arguments and expecting them quoted might not work exactly the same (eg, echo 'a s' => 'a s' vs xx echo 'a s' => "a s")
#   NOTE: using $"<string>" => "<string>" quote preservation behavior can overcome this issue (eg, xx perl -e $"print 'test'")
#       [??] $"<string>" under bash ignores the $ if C or POSIX locale in force, and only leaves string qq'd if translated to another locale
#   NOTE: or use another method to preserve quotes for appropriate commands (such as "'"'<string'"'" (noisy but it works)

#TODO: add option to see "normal", "dosify", and "unixify" options for echo/args to see what a command using Win32::CommandLine will get
#   ??  -a = -ad => expanded arguments as xx.bat would for an another executable (dosified)
#   ??  -au => unixify
#   ??  -ai => normal (non-d/u expansion) == default expansion of arguments as a perl exe using Win32::commandLine::argv()
##TODO (-d and -u options)
# -d: => dosify [default]
# -d:all => dosify='all'
# -u: => unixify
# -u:all => unixify='all'
#
# ==> DON'T do this, leave xx as is. it's to expand/execute cmd.exe commands which have no internal expansion ability. add another utility to show what expansion occurs for each type of expansion option.

# TODO: add option to reverse all canonical forward slashes in options to backslash to avoid interpretation as options by commands
# TODO: add option to NOT quote a command (such as for echo) and take the special processing out of the code? (what about the echo.bat situation, maybe 'alias echo=xx -Q echo $*' or 'alias echo.bat=xx echo.bat' or would that not solve it....)

# Script Summary

=for stopwords CMD eXpand eXecute pl2bat

=head1 NAME

xx - eXpand (reparse) and eXecute the command line

=head1 VERSION

This document describes C<xx>, v 0.960.

=head1 SYNOPSIS

xx [-s|-so] [B<<option(s)>>] B<<command>> [B<<argument(s)>>]

=begin HIDDEN-OPTIONS

Options:

        --version       version message
    -?, --help          brief help message

=end HIDDEN-OPTIONS

=head1 OPTIONS

=over

=item -s

Expand the command line (using Win32::CommandLine) and then B<source> the resulting expanded command. This allows B<modification of the current process environment> by the expanded command line. NOTE: MUST be the first argument.

=item -so

Expand the command line (using Win32::CommandLine) and then B<source> the B<OUTPUT> of the execution of the expanded command. This allows B<modification of the current process environment> based on the OUTPUT of the execution of the expanded command line. NOTE: MUST be the first argument.

=item --echo, -e

Print (but do not execute) the results of expanding the command line.

=item --args, -a

Print detailed information about the command line and it's expansion, including all resulting ARGS (B<without> executing the resultant expansion).

=item --version

=item --usage

=item --help, -?

=item --man

Print the usual program information

=back

=head1 REQUIRED ARGUMENTS

=over

=item <command>

COMMAND...

=back

=head1 DESCRIPTION

B<xx> will read expand the command line and execute the COMMAND.

NOTE: B<xx> is designed for use with legacy commands to graft on better command line interpretation behaviors. Generally, it's not necessary to use B<xx> on commands which already use Win32::CommandLine::argv(), as the command line will be re-interpreted. If that's the behavior desired, that's fine; but think about it.
??? what about pl2bat-wrapped perl scripts? Since the command line is used within the wrapping batch file, is it clean for the .pl file or does it need xx wrapping as well?

=head1 EXAMPLES

Here are some examples of what's possible in the standard CMD shell:

    xx $( perl -MConfig -e "print $Config{cc}" ) $(perl -MExtUtils::Embed -e ccopts) foo.c -o foo

    xx $( perl -MConfig -e "print $Config{cc}" ) $(perl -MExtUtils::Embed -e ccopts) -c bar.c -o bar.o

=for future-documentation
    xx $( perl -MConfig -e "print $Config{ld}" ) $("perl -MExtUtils::Embed -e ldopts 2>nul") bar.o

=cut
use strict;
use warnings;

# VERSION: Major.minor[_alpha]  { minor is ODD => alpha/beta/experimental; minor is EVEN => stable/release }
# * NOTE: simple decimal ("boring") versions are preferred (see: <http://www.dagolden.com/index.php/369/version-numbers-should-be-boring>[`@`](https://archive.is/7PZQL))
# * NOTE: *two-line* version definition is intentional so that Module::Build / CPAN get a correct alpha version, but users receive a simple decimal version
{
    ; ## no critic ( RequireConstantVersion )
    our $VERSION = '0.960';    # VERSION definition
    $VERSION =~ s/_//g;                   # numify VERSION (needed for alpha versions)
}

use Pod::Usage;

use Carp::Assert;

use FindBin;                              # NOTE: BEGIN is used in FindBin; this can incompatible with any other modules using FindBin; so, DON'T use with any *module* submitted to CPAN; ## URLref: [perldoc::FindBin - Known Issues] http://perldoc.perl.org/FindBin.html#KNOWN-ISSUES

use ExtUtils::MakeMaker;

#-- config
#my %fields = ( 'quotes' => qq("'`), 'seperators' => qq(:,=) ); #"

#-- getopt
use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat no_permute pass_through); ## # no_permute/pass_through to parse all args up to 1st unrecognized or non-arg or '--'
# PRE-parse for nullglob option before initial expansion of command line (to avoid double expansion of the command line and possible subshell side-effects)
my %ARGV = ();
GetOptions( \%ARGV, 'echo|e|s', 'so', 'args|a', 'nullglob=s', 'help|h|?|usage', 'man', 'version|ver|v' );
if ( exists $ARGV{'nullglob'} ) { $ENV{'nullglob'} = $ARGV{'nullglob'}; }

my $showUsage = ( @ARGV < 1 );    # show usage only if no arguments (check _before_ a possible nullglob replacement of any/all globs by NULL)

use Win32::CommandLine;

@ARGV = Win32::CommandLine::argv( { dosify => 'true', dosquote => 'true' } );    # if eval { require Win32::CommandLine; }; ## depends on Win32::CommandLine (and installed with it) so we want the error if its missing or unable to load

#-- do main getopt
##use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat no_permute pass_through); ##   # no_permute/pass_through to parse all args up to 1st unrecognized or non-arg or '--'
%ARGV = ();
# NOTE: the 'source' option '-s' is bundled into the 'echo' option since 'source' is exactly the same as 'echo' to the internal perl script. Sourcing is done by wrapping the BAT script by executing the output of the perl script.
GetOptions( \%ARGV, 'echo|e|s', 'so', 'args|a', 'nullglob=s', 'help|h|?|usage', 'man', 'version|ver|v' );
#Getopt::Long::VersionMessage() if $ARGV{'version'};
do { print q{} . ( File::Spec->splitpath($0) )[2] . qq{ v$::VERSION} . qq{\n}; exit(0); } if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage( { -verbose => 2 } ) if $ARGV{'man'};

pod2usage(1) if $showUsage;

if ( $ARGV{args} ) {
    my $cl = Win32::CommandLine::command_line();
    print ' $ENV{CMDLINE}' . " = `" . ( $ENV{CMDLINE} ? $ENV{CMDLINE} : '<null>' ) . "`\n";
    print 'command_line()' . " = `$cl`\n";
}

## unfortunately the args (which are correct at this point) are reparsed while going to the target command through CreateProcess() (PERL BUG: despite explicit documentation in PERL that system bypasses the shell and goes directly to execvp() for scalar(@ARGV) > 1 although there is no obvious work around since execvp() doesn't really exist in Win32 and must be emulated through CreateProcess())
## so, we must protect the ARGs from CreateProcess() reparsing destruction
## echo is a special case (it must get it's command line directly, skipping the ARGV reparsed arguments of CreateProcess()... so check and don't re-escape quotes) for 'echo'
### checking for echo is a bit complicated any command starting with echo followed by a . or whitespace is treated as an internal echo command unless a file exists which matches the entire 1st argument, then it is executed instead
#if ((-e $ARGV[0]) || not $ARGV[0] =~ m/^\s*echo(.|\s*)/)
#   { ## protect internal ARGV whitespace and double quotes by escaping them and surrounding the ARGV with another set of double quotes
#   ## ???: do we need to just protect the individual whitespace and quote runs individually instead of a whole ARGV quote surround?
#   ## ???: do we need to protect other special characters (such as I/O redirection and continuation characters)?
#   for (1..$#ARGV) {if ($ARGV[$_] =~ /\s/ || $ARGV[$_] =~ /["]/) {$ARGV[$_] =~ s/\"/\\\"/g; $ARGV[$_] = '"'.$ARGV[$_].'"'}; }
#   }
# [2009-02-18] the protection is now automatically done already with the 'dosify' option above ... ? remove it for echo or just note the issue? or allow command line control of it instead? command line control might be problematic => finding the command string without reparsing the command line multiple times (could cause side effects if $(<COMMAND>) is implemented => make it similar to -S (solo and only prior to 1st non-option?)
#       == just note that echo has no command line parsing

# TODO: check echo %% "%%" => echo % % => % % [doesn't work for TCC or CMD]

# untaint
$ENV{PATH} =~ /\A(.*)\z/mxs;
$ENV{PATH} = ( defined $1 ? $1 : undef );

if ( $ARGV{args} ) {
    for ( my $i = 0 ; $i < @ARGV ; $i++ ) { print '$ARGV' . "[$i] = `$ARGV[$i]`\n"; }
}

#system { $ARGV[0] } @ARGV;     # doesn't see "echo" as a command (?? might be a problem for all CMD built-ins)
if ( not $ARGV{args} ) {
    ## TODO: REDO this comment -- unfortunately the args (which are correct at this point) are reparsed while going to the target command through CreateProcess() (PERL BUG: despite explicit documentation in PERL that system bypasses the shell and goes directly to execvp() for scalar(@ARGV) > 1 although there is no obvious work around since execvp() doesn't really exist in Win32 and must be emulated through CreateProcess())
    if ( $ARGV{echo} ) { print join( " ", @ARGV ); }
    else {
        if ( $ARGV{so} ) { my $x = join( " ", @ARGV ); print `$x`; exit( $? >> 8 ); }
        else             { exit( ( system @ARGV ) >> 8 ); }
    }
}

__END__
:endofperl
