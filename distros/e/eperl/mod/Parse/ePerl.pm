##        ____           _ 
##    ___|  _ \ ___ _ __| |
##   / _ \ |_) / _ \ '__| |
##  |  __/  __/  __/ |  | |
##   \___|_|   \___|_|  |_|
## 
##  ePerl -- Embedded Perl 5 Language
##
##  ePerl interprets an ASCII file bristled with Perl 5 program statements
##  by evaluating the Perl 5 code while passing through the plain ASCII
##  data. It can operate both as a standard Unix filter for general file
##  generation tasks and as a powerful Webserver scripting language for
##  dynamic HTML page programming. 
##
##  ======================================================================
##
##  Copyright (c) 1996,1997 Ralf S. Engelschall, All rights reserved.
##
##  This program is free software; it may be redistributed and/or modified
##  only under the terms of either the Artistic License or the GNU General
##  Public License, which may be found in the ePerl source distribution.
##  Look at the files ARTISTIC and COPYING or run ``eperl -l'' to receive
##  a built-in copy of both license files.
##
##  This program is distributed in the hope that it will be useful, but
##  WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
##  Artistic License or the GNU General Public License for more details.
##
##  ======================================================================
##
##  ePerl.pm -- Perl interface to the ePerl parser (Perl part)
##

package Parse::ePerl;


#   requirements and runtime behaviour
require 5.00325;
use strict;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

#   imports
require Exporter;
require DynaLoader;
require AutoLoader;
use Carp;
use Cwd qw(fastcwd);
#use Safe;

#   interface
@ISA    = qw(Exporter DynaLoader);
@EXPORT = qw();

#   private version number
$VERSION = do { my @v=("2.2.13"=~/\d+/g); sprintf "%d."."%02d"x$#v,@v }; 

#   dynaloader bootstrapping
bootstrap Parse::ePerl $VERSION;


#   untainting a variable: for restricted environments like 
#   Apache/mod_perl under which our caller Apache::ePerl could run
sub Untaint {
   my ($var) = @_;

   #   see perlsec(1)
   ${$var} =~ m|^(.*)$|s;
   ${$var} = $1;
}


##
##  Preprocess -- run the ePerl preprocessor over the script
##                which expands #include directives
##

sub Preprocess ($) {
    my ($p) = @_;
    my ($result, $ocwd);

    #   error if no input or no output
    if (   not $p->{Script}
        || not $p->{Result}) {
        return 0;
    }

    #   set defaults
    $p->{INC} ||= [ '.' ];

    #   switch to directory of file
    if ($p->{Cwd}) {
        Untaint(\$p->{Cwd});
        $ocwd = fastcwd();
        chdir($p->{Cwd});
    }

    #   use XS part: PP (preprocessor)
    $result = PP(
        $p->{Script}, 
        $p->{INC}
    );

    #   restore Cwd
    chdir($ocwd) if ($p->{Cwd});

    if ($result eq '') {
        return 0;
    }
    else {
        ${$p->{Result}} = $result;
        return 1;
    }
}


##
##  Translate -- translate a plain Perl script from 
##               bristled code to plain Perl code
##

sub Translate ($) {
    my ($p) = @_;
    my ($result);

    #   error if no input or no output
    if (   not $p->{Script}
        || not $p->{Result}) {
        return 0;
    }

    #   set defaults
    $p->{BeginDelimiter}  ||= '<:';
    $p->{EndDelimiter}    ||= ':>';
    $p->{CaseDelimiters}  ||= 0;
    $p->{ConvertEntities} ||= 0;

    #   use XS part: Bristled2Plain
    $result = Bristled2Plain(
        $p->{Script}, 
        $p->{BeginDelimiter},
        $p->{EndDelimiter},
        $p->{CaseDelimiters},
        $p->{ConvertEntities}
    );

    if ($result eq '') {
        return 0;
    }
    else {
        ${$p->{Result}} = $result;
        return 1;
    }
}


##
##  Precompile -- precompile a plain Perl script to 
##                internal Perl code (P-code) by storing
##                the script into a subroutine
##

sub Precompile ($) {
    my ($p) = @_;
    my ($error, $func, $ocwd);

    #   error if no input or no output
    if (   not $p->{Script}
        || not $p->{Result}) {
        return 0;
    }

    #   capture the warning messages which
    #   usually are send to STDERR and
    #   disable the die of the interpreter
    $error = '';
    local $SIG{'__WARN__'} = sub { $error .= $_[0]; };
    local $SIG{'__DIE__'};

    #   switch to directory of file
    if ($p->{Cwd}) {
        Untaint(\$p->{Cwd});
        $ocwd = fastcwd();
        chdir($p->{Cwd});
    }

    #   precompile the source into P-code
    #my $cp = new Safe("Safe::ePerl");
    #$func = $cp->reval('$func = sub {'.$p->{Script}.'};');
    Untaint(\$p->{Script});
    eval("\$func = sub {" . $p->{Script} . "};");
    $error = "$@" if ($@);

    #   restore Cwd
    chdir($ocwd) if ($p->{Cwd});

    #   return the result
    if ($error) {
        $error =~ s|\(eval \d+\)|$p->{Name}| if ($p->{Name});
        ${$p->{Error}} = $error if ($p->{Error});
        $@ = $error;
        return 0;
    }
    else {
        ${$p->{Result}} = $func;
        $@ = '';
        return 1;
    }
}


##
##  Evaluate -- evaluate a script which is either
##              give as a P-code reference or as
##              a plain Perl script

sub Evaluate ($) {
    my ($p) = @_;
    my ($stdout, $stderr, %OENV, $ocwd);
    my ($result, $error);

    #   error if no input or no output
    if (   not $p->{Script}
        || not $p->{Result}) {
        return 0;
    }

    #   capture STDOUT and STDERR
    $stdout = tie(*STDOUT, 'Parse::ePerl');
    $stderr = tie(*STDERR, 'Parse::ePerl');

    #   setup the environment
    if ($p->{ENV}) {
        %OENV = %ENV;
        %ENV  = %{$p->{ENV}};
    }

    #   switch to directory of file
    if ($p->{Cwd}) {
        $ocwd = fastcwd();
        chdir($p->{Cwd});
    }

    #   capture the warning messages which
    #   usually are send to STDERR (and which
    #   cannot be captured by our tie!) plus
    #   disable the die of the interpreter
    $error = '';
    local $SIG{'__WARN__'} = sub { $error .= $_[0]; };
    local $SIG{'__DIE__'}  = sub { $error .= $_[0]; };

    #   now evaluate the script which 
    #   produces content on STDOUT and perhaps
    #   additionally on STDERR
    if (ref($p->{Script})) {
        #   a P-code reference
        &{$p->{Script}};
    }
    else {
        #   a plain code string
        eval $p->{Script};
    }

    #   retrieve captured data from STDOUT
    $result = ${$stdout};

    #   retrieve either the error message 
    #   (on syntax errors) or the generated data 
    #   on STDERR (when generated by the script)
    $error ||= ${$stderr};
    $error =~ s|\(eval \d+\)|$p->{Name}| if (defined($error) && $p->{Name});

    #   restore Cwd
    chdir($ocwd) if ($p->{Cwd});

    #   restore environment
    %ENV = %OENV if ($p->{ENV});

    #   remove capturing mode from STDOUT/STDERR
    undef($stdout);
    undef($stderr);
    untie(*STDOUT);
    untie(*STDERR);

    #   set the result
    ${$p->{Result}} = $result;
    ${$p->{Error}}  = $error if ($p->{Error});

    #   return the result codes
    if ($error) {
        $@ = $error;
        return 0;
    }
    else {
        $@ = '';
        return 1;
    }
}


##
##  Expand -- the steps Translate & Evaluate
##            just combined into one step
##

sub Expand ($) {
    my ($p) = @_;
    my ($rc, $script);

    #   error if no input or no output
    if (   not $p->{Script}
        || not $p->{Result}) {
        return 0;
    }

    if (not Translate($p)) {
        return 0;
    }
    $script = $p->{Script};
    $p->{Script} = ${$p->{Result}};
    $rc = Evaluate($p);
    $p->{Script} = $script;
    return $rc;
}


##
##  Capture -- methods for capturing a filehandle
##             (used by Evaluate) via this class
##

sub TIEHANDLE {
    my ($class, $c) = @_;
    return bless(\$c,$class);
}

sub PRINT {
    my ($self) = shift;
    ${$self} .= join('', @_);
}

sub PRINTF {
    my ($self) = shift;
    my ($fmt) = shift;
    ${$self} .= sprintf($fmt, @_);
}


#   sometimes Perl wants it...
sub DESTROY { };


1;
##EOF##
__END__

=head1 NAME

Parse::ePerl - Perl interface to the ePerl parser

=head1 SYNOPSIS

  use Parse::ePerl;

  $rc = Parse::ePerl::Preprocess($p);
  $rc = Parse::ePerl::Translate($p);
  $rc = Parse::ePerl::Precompile($p);
  $rc = Parse::ePerl::Evaluate($p);
  $rc = Parse::ePerl::Expand($p);

=head1 DESCRIPTION

Parse::ePerl is the Perl 5 interface package to the functionality of the ePerl
parser (see eperl(1) for more details about the stand-alone program). It
directly uses the parser code from ePerl to translate a bristled script into a
plain Perl script and additionally provides functions to precompile such
scripts into P-code and evaluate those scripts to a buffer.

All functions are parameterized via a hash reference C<$p> which provide the
necessary parameters. The result is a return code C<$rc> which indicates
success (1) or failure (0).

=head2 B<PREPROCESSOR: $rc = Parse::ePerl::Preprocess($p)>

This is the ePerl preprocessor which expands C<#include> directives.
See eperl(1) for more details.

Possible parameters for C<$p>:

=over 4

=item I<Script>

Scalar holding the input script in source format.

=item I<Result>

Reference to scalar receiving the resulting script in bristled Perl format.

=item I<INC>

A reference to a list specifying include directories. Default is C<\@INC>.

=back

=head2 B<TRANSLATION: $rc = Parse::ePerl::Translate($p)>

This is the actual ePerl parser, i.e. this function converts a bristled
ePerl-style script (provided in C<$p->{Script}> as a scalar) to a plain Perl
script. The resulting script is stored into a buffer provided via a scalar
reference in C<$p->{Result}>. The translation is directly done by the original
C function Bristled2Plain() from ePerl, so the resulting script is exactly the
same as with the stand-alone program F<eperl>.

Possible parameters for C<$p>:

=over 4

=item I<Script>

Scalar holding the input script in bristled format.

=item I<Result>

Reference to scalar receiving the resulting script in plain Perl format.

=item I<BeginDelimiter>

Scalar specifying the begin delimiter.  Default is ``C<E<lt>:>''.

=item I<EndDelimiter>

Scalar specifying the end delimiter.  Default is ``C<:E<gt>>''.

=item I<CaseDelimiters>

Boolean flag indicating if the delimiters are case-sensitive (1=default) or
case-insensitive (0).

=back

Example: The following code 

  $script = <<'EOT';
  foo
  <: print "bar"; :>
  quux
  EOT
  
  Parse::ePerl::Translate({
      Script => $script,
      Result => \$script,
  });

translates the script in C<$script> to the following plain Perl format:

  print "foo\n";
  print "bar"; print "\n";
  print "quux\n";

=head2 B<COMPILATION: $rc = Parse::ePerl::Precompile($p);>

This is an optional step between translation and evaluation where the plain
Perl script is compiled from ASCII representation to P-code (the internal Perl
bytecode). This step is used in rare cases only, for instance from within
Apache::ePerl(3) for caching purposes.

Possible parameters for C<$p>:

=over 4

=item I<Script>

Scalar holding the input script in plain Perl format, usually the result from
a previous Parse::ePerl::Translate(3) call.

=item I<Result>

Reference to scalar receiving the resulting code reference. This code can be
later directly used via the C<&$var> construct or given to the
Parse::ePerl::Evaluate(3) function.

=item I<Error>

Reference to scalar receiving possible error messages from the compilation
(e.g.  syntax errors).

=item I<Cwd>

Directory to switch to while precompiling the script.

=item I<Name>

Name of the script for informal references inside error messages.

=back

Example: The following code 

  Parse::ePerl::Precompile({
      Script => $script,
      Result => \$script,
  });

translates the plain Perl code (see above) in C<$script> to a code reference
and stores the reference again in C<$script>. The code later can be either
directly used via C<&$script> instead of C<eval($script)> or passed to the
Parse::ePerl::Evaluate(3) function.

=head2 B<EVALUATION: $rc = Parse::ePerl::Evaluate($p);>

Beside Parse::ePerl::Translate(3) this is the second main function of this
package. It is intended to evaluate the result of Parse::ePerl::Translate(3)
in a ePerl-like environment, i.e. this function tries to emulate the runtime
environment and behavior of the program F<eperl>. This actually means that it
changes the current working directory and evaluates the script while capturing
data generated on STDOUT/STDERR.

Possible parameters for C<$p>:

=over 4

=item I<Script>

Scalar (standard case) or reference to scalar (compiled case) holding the
input script in plain Perl format or P-code, usually the result from a
previous Parse::ePerl::Translate(3) or Parse::ePerl::Precompile(3) call.

=item I<Result>

Reference to scalar receiving the resulting code reference. 

=item I<Error>

Reference to scalar receiving possible error messages from the evaluation
(e.g. runtime errors).

=item I<ENV>

Hash containing the environment for C<%ENV> which should be used while
evaluating the script.

=item I<Cwd>

Directory to switch to while evaluating the script.

=item I<Name>

Name of the script for informal references inside error messages.

=back

Example: The following code 

  $script = <<'EOT';
  print "foo\n";
  print "bar"; print "\n";
  print "quux\n";
  EOT

  Parse::ePerl::Evaluate({
      Script => $script,
      Result => \$script,
  });

translates the script in C<$script> to the following plain data:

  foo
  bar
  quux

=head2 B<ONE-STEP EXPANSION: $rc = Parse::ePerl::Expand($p);>

This function just combines, Parse::ePerl::Translate(3) and
Parse::ePerl::Evaluate(3) into one step. The parameters in C<$p> are the union
of the possible parameters for both functions. This is intended as a
high-level interface for Parse::ePerl.

=head1 AUTHOR

 Ralf S. Engelschall
 rse@engelschall.com
 www.engelschall.com

=head1 SEE ALSO

eperl(1)

Web-References:

  Perl:  perl(1),  http://www.perl.com/
  ePerl: eperl(1), http://www.engelschall.com/sw/eperl/

=cut

##EOF##
