package Text::EP3;

=head1 NAME

EP3 - The Extensible Perl PreProcessor

=head1 SYNOPSIS

  # Use options and files from command-line
  use Text::EP3;
  [use Text::EP3::{Extension}] # Language Specific Modules
  # create the PreProcessor object
  my $preprocessor = new Text::EP3 file;
  # do the preprocessing, using command-line options from @ARGV
  $preprocessor->ep3_execute;

  # Set options and files from the Perl script
  use Text::EP3;
  [use Text::EP3::{Extension}] # Language Specific Modules
  # create the PreProcessor object
  my $preprocessor = new Text::EP3 file;
  # configure the PreProcessor object (optional)
  $preprocessor->ep3_output_file([$filename]);
  $preprocessor->ep3_modules([@modules]);
  $preprocessor->ep3_includes([@include_directories]);
  $preprocessor->ep3_reset;
  $preprocessor->ep3_start_comment([$string]);
  $preprocessor->ep3_end_comment([$string]);
  $preprocessor->ep3_line_comment([$string]);
  $preprocessor->ep3_delimiter([$string]);
  $preprocessor->ep3_gen_depend_list([$value]);
  $preprocessor->ep3_keep_comments([$value]);
  $preprocessor->ep3_protect_comments([$value]);
  $preprocessor->ep3_defines($string1=$string2);
  # do the preprocessing
  $preprocessor->ep3_process([$filename, [$condition]]);

=head1 DESCRIPTION

EP3 is a Perl5 program that preprocesses STDIN or some set 
of input files and produces an output file. 
EP3 only works on input files and produces output files. It seems to me that
if you want to preprocess arrays or somesuch, you should be using perl.
EP3 was first developed to provide
a flexible preprocessor for the Verilog hardware
description language. Verilog presents some problems that 
were not easily solved by using cpp or m4. I wanted to be
able to use a normal preprocessor, but extend its functionality. 
So I wrote EP3 - the Extensible Perl PreProcessor. The main
difference between EP3 and other preprocessors is its built-in
extensibility. Every directive in EP3 is really a method defined
in EP3, one of its submodules, or embedded in the file that is 
being processed. By linking the directive name
to the associated methods, other methods could
be added, thus extending the preprocessor.

Many of the features of EP3 can be modified via command line switches. For
every command line switch, there is an also accessor method. 

=over 4

=item Directives and Method Invocation

Directives are preceded with the a user 
defined delimeter. The default delimeter is `@'. This 
delimeter was chosen to avoid conflicts with other 
preprocessor delimeters (`#' and the Verilog backtick), 
as well as Verilog syntax that might be found a the 
beginning of a line (`$', `&', etc.). A directive is 
defined in Perl as 
the beginning of the line, any amount of whitespace, 
and the delimeter immediately followed by Perl word 
characters (0-9A-Za-z_).

EP3 looks for directives, strips off the delimeter, and then 
invokes a method of the same name. The standard 
directives are defined within the EP3 program. Library 
or user defined directives may be loaded as perl 
modules either via the use command or from a command 
line switch for inclusion at the 
beginning of the EP3 run. Using the "include" directive 
coupled with the "perl_begin/end" directives 
perl subroutines (and hence 
EP3 directives) may be dynamically included during 
the EP3 run.

=item Directive Extension Method 1: The use command.

A module may be included with the use statement provided that it pushes its
package name onto EP3's @ISA array (thus telling EP3 to inherit its methods).
For a Verilog module whose filename is Verilog.pm and has the package name
Text::EP3::Verilog, the following line must be included ...

    push (@Text::EP3::ISA, qw(Text::EP3::Verilog));

This package can then be simply included in whatever script you are using to
call EP3 with the line:

    use Text::EP3::Verilog;

All methods within the module are now available to EP3 as directives.

=item Directive Extension Method 2: The command line switch.

A module can be included at run time with the -module modulename switch on the
command line (assuming the ep3_parse_command_line method is invoked). The
modulename is assumed to have a .pm extension and exist somewhere in the
directories specified in @INC. 
All methods within the module are now available to EP3 as directives.

=item Directive Extension Method 3: The ep3_modules accessor method.

Modules can be added by using the accessor method ep3_modules. 

    $preprocessor->ep3_modules("module1","module2", ....);

All methods within the module are now available to EP3 as directives.

=item Directive Extension Method 4: Embedded in the source code or included files.

Using the perl_begin and perl_end directives to delineate perl sections,
subroutines can be declared (as methods) anywhere in a processed file or in a
file that the process file includes. In this way, runtime methods are made
available to EP3. For example ...

    1 Text to be printed ...
    @perl_begin
    sub hello {
        my $self = shift;
        print "Hello there\n";
    }
    @perl_end
    2 Text to be printed ...
    @hello
    3 Text to be printed ...
    
    would result in
    1 Text to be printed ...
    2 Text to be printed ...
    Hello there 
    3 Text to be printed ...

Using this method, libraries of directives can be built and included with the
include directive (but it is recommended that they be moved into a module when
they become static).


=item Input Files and Processing

Input files are processed one line at a time. The 
EP3 engine attempts to perform substitutions with 
elements stored in macro/define/replace lists. All directive 
lines are preprocessed before being evaluated (the only 
exception being the key portions of the if[n]def and 
define directives). Directive lines can be extended 
across multiple lines by placing the `\' character at the 
end of each line. Comments are normally protected 
from the preprocessor, but protection can be 
dynamically turned off and then back on. From a 
command line switch, comments can also be deleted 
from the output.


=item Output Files

EP3 typically writes output to Perl's STDOUT, but 
can be assigned to any output file. EP3 can also be run 
in "dependency check" mode via a command line 
switch. In this mode, normal output is suppressed, and 
all dependent files are output in the order accessed.
NOTE! EP3 uses the select call to change the default output
file for included perl blocks. However, if you are using 
a method invocation of ep3, note that the default output
for the rest of your script will be changed as well. 
(This can be easily worked with, but should be known beforehand).

Most parameters can be modified before invoking EP3 including
directive string, comment delimeters, comment protection
and inclusion, include path, and startup defines.

=back

=head1 Standard Directives

EP3 defines a standard set of preprocessor 
directives with a few special additions that integrate the 
power of Perl into the coded language.

=over 4

=item The define directive

@define key definition
The define directive assigns the definition to the 
key. The definition can contain any character including 
whitespace. The key is searched for as an individual 
word (i.e the input to be searched is tokenized on Perl 
word boundaries). The definition contains everything 
from the whitespace following the key until the end of 
the line. 

=item The replace directive

@replace key definition
The replace directive is identical to the define 
directive except that the substitution is performed if the 
key exists anywhere, not just on word boundaries.

=item The macro directive 

@macro key(value[,value]*) definition
The macro directive tokenizes as the define 
directive, replacing the key(value,...) text with the 
definition and saving the value list. The definition is 
then parsed and the original macro values are replaced 
with the saved values.

=item The eval directive

@eval key expr
The eval directive first evaluates the expr using 
Perl. Any valid Perl expr is accepted. This key is then 
defined with the result of the evaluation.

=item The include directive

@include <file> or "file" [condition]
The include directive looks for the "file" in the 
present directory, and <file> anywhere in the include 
path (definable via command line switch). Included 
files are recursively evaluated by the preprocessor. If 
the optional condition is specified, only those lines in 
between the text strings "@mark condition_BEGIN" 
and "@mark condition_END" will be included. The 
condition can be any string. For example if the file "file.V" contains the
following lines:

    1 Stuff before
    @mark PORT_BEGIN
    2 Stuff middle
    @mark PORT_END
    3 Stuff after

Then any file with the following line:

    @include "file.V" PORT 

will include the following line from file.V

    2 Stuff middle

This is useful for partial inclusion of files (like port list specifications
in Verilog).

=item The enum directive

@enum a,b,c,d,...
enum generates multiple define's with each 
sequential element receiving a 1 up count from the 
previous element. Default starts at 0. If any element is a 
number, the enum value will be set to that value.

=item The ifdef and ifndef directives

@ifdef and @ifndef key
Conditional compilation directives. The key is 
defined if it was placed in the define/replace list by 
define, replace, or any command that generates a define 
or replace.

=item The if directive

@if expr
The expression is evaluated using Perl. The 
expression can be any valid Perl expression. This 
allows for a wide range of conditional compilation. 

=item The elif [elsif] directive

@[elif|elsif] key | expr
The else if directive. Used for either "if[n]def" or 
"if".

=item The else directive

@else 
The else directive. Used for either "if[n]def" or 
"if".

=item The endif directive

@endif
The conclusion of any "if[n]def" or "if" block.

=item The comment directive

@comment on|off|default|previous
The comment switch can be one of "on", "off", 
"default", or "previous". This is used to turn comments 
on or off in the resultant file. This directive is very 
useful when including other files with commented 
header descriptions. By using "comment off" and 
"comment previous" surrounding a header the output 
will not see the included files comments. Using 
"comment on" with "comment previous" insures that 
comments are included (as in an attached synthesis 
directive file). The default comment setting is on. This 
can be altered by a command line switch. The 
"comment default" directive will restore the comment 
setting to the EP3 invocation default.

=item The protect directive

@protect on|off|default|previous

The protect switch can be one of "on", "off", 
"default", or "previous". This is used to turn protection
of comments from macro substitution on or off in the resultant file.

By using "protect off" and "protect previous" surrounding 
a section of code, any comments in the section will be subject to
macro substitution. The default comment setting is on. This 
can be altered by a command line switch. The 
"protect default" directive will restore the protect 
setting to the EP3 invocation default.

=item The ep3 directive

@ep3 on|off
The "ep3 off" directive turns off preprocessing 
until the "ep3 on" directive is encountered. This can 
greatly speed up processing of large files where 
postprocessing is only necessary in small chunks. 

=item The perl_begin and perl_end directives

@perl_begin
perl code here ....
(Single line and multi-line output mechanisms are available)

@> text to be output after variable interpolation
or 

@>> text to be output 

    after variable interpolation

    @<<

@perl_end

The "perl" directives provide the underlying 
language with all of the power of 
perl, embedded in the preprocessed code. Anything 
enclosed within the "perl_begin" and "perl_end" 
directives will be evaluated as a Perl script. This can be 
used to include a subroutine that can later be called as a 
directive. Using this type of extension, directive 
libraries can be developed and included to perform a 
variety of powerful source code development features. 
This construct can also be used to mimic and expand 
the VHDL generate capabilities. The "@>" and "@>> @<<" directives
from within a perl_[begin|end] block directs ep3 to 
perform variable interpolation on the given line and 
then print it to the output.

=item The debug directive

@debug on|off|value
The debug directive enables debug statements to go to the output file. The
debug statements are preceded by the Line Comment string. Currently the debug
values that will enable printouts are the following:

    0x01  1  - Primary messages (Entering Subroutines)
    0x02  2  - ep3_process Engine
    0x04  4  - define (replace, macro, eval, enum)
    0x08  8  - include
    0x10  16 - if (else, ifdef, etc.)
    0x20  32 - perl_begin/end

=back

=head1 EP3 Constructor

=over 8

=item Text::EP3->new

Returns an EP3 preprocessor object, on which you can call the methods listed below.
Takes no arguments.

=back

=head1 EP3 Methods

EP3 defines several methods that can be invoked by the user.

=over 8

=item ep3_execute

Execute sets up EP3 to act like a perl script. It parses the command line,
includes any modules specified on the command line, loads in any specified
modules, does any preexisting defines, sets up the output files,
and then processes the input. Sort of the whole shebang.

=item ep3_parse_command_line

ep3_parse_command_line does just that - parses the command line looking for EP3
options. It uses the GetOpt::Long module.

=item ep3_modules

This method will find and include any modules specified as arguments. It
expects just the name and will append .pm to it before doing a require.
The module returns the methods specified in the objects methods array.

=item  ep3_output_file

ep3_output_file  determines what the output should be (either the processed
text or a list of dependencies) and where it should go. It then proceeds to
open the required output files.
NOTE! - this module uses select to change the default output file.
The module returns the output filename.

=item  ep3_reset 

ep3_reset resets all of the internal EP3 lists (defines, replaces, keycounts,
etc.) so that a user can do multiple files independently from within one
script.

=item  ep3_process([$filename [, $condition]]) 

ep3_process is the guts of the whole thing. It takes a filename as input and
produces the specified output. This is the method that is iteratively called
by the include directive. A null filename will cause ep3_process to look for
filenames in ARGV.

=item ep3_includes([@include_directories])

This method will add the specified directories to the ep3 include path.

=item ep3_defines($string1=$string2);

This method will initialize defines with string1 defined as string 2. It
initializes all of the defines in the objects Defines array. 

=item ep3_end_comment([$string]);

This method sets the end_comment string to the value specifed.
If null, the method returns the current value.

=item ep3_start_comment([$string]);

This method sets the start_comment string to the value specifed.
If null, the method returns the current value.

=item ep3_line_comment([$string]);

This method sets the end_commenline string to the value specifed.
If null, the method returns the current value.

=item ep3_delimiter([$string]);

This method sets the directive delimiter string to the value specifed.
If null, the method returns the current value.

=item ep3_delimeter([$string]);

A synonym for ep3_delimiter, for backwards compatibility.

=item ep3_gen_depend_list([$value]);

This method enables/disables dependency list generation. When
gen_depend_list is 1, a dependency list is generated. When it is 0,
normal operation occurs.
If null, the method returns the current value.

=item ep3_sync_lines([$value]);

This method enables/disables output of synchronisation lines, as generated by cpp and m4.
These lines start with the current delimiter string, and contain the line number and 
filename of the following output line.

=item ep3_keep_comments([$value]);

This method sets the keep_comments variable to the value specifed.
If null, the method returns the current value.

=item ep3_protect_comments([$value]);

This method sets the protect_comments variable to the value specifed.
If null, the method returns the current value.

=back

=head1 EP3 Options

EP3 Options can be set from the command line (if ep3_execute or ep3_parse_command_line is invoked) or the internal variables can be explicitly set.

=over 8

=item [-no]protect

    Should comments be protected from substution? 
    Default: 1

=item [-no]comment

    Should comments be passed to the output?
    Default: 1

=item [-no]depend

    Are we generating a dependency list or simply processing?
    Default: 0

=item -delimeter string

    The directive delimeter - can be a string
    Default: @

=item -define string1=string2

    Defines from the command line. 
    Multiple -define options can be specified
    Default: ()

=item -includes directory

    Where to look for include files. 
    Multiple -include options can be specified
    Default: ()

=item -output_filename filename

    Where to place the output. 
    Default: STDOUT

=item -modules filename

    Modules to load (just the module name, expecting to find module.pm somewhere in @INC. 
    Multiple -modules options can be specified
    Default: ()

=item -line_comment string

    The Line Comment string. 
    Default: //

=item -start_comment string

    The Start Comment string. 
    Default: /*

=item -end_comment string

    The End Comment string. 
    Default: */

=back

=head1 AUTHOR

Module created by Gary Spivey, spivey@ieee.org

Version 1.10 changes by Michael Attenborough, michael doht attenborough aht physics doht org

Many thanks to Steve Bresson for his help, ideas, and code ...

=head1 SEE ALSO

perl(1).

=cut

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Exporter;
use FileHandle;
use Getopt::Long;
use Cwd;
use Carp;
use AutoLoader;
use Env; # Make environment variables available

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
@EXPORT_OK = qw(
);

$VERSION = '1.10';

# Set an unused default here just to avoid warnings
$Text::EP3::Dependfile_Handle = *STDOUT;

sub new {

    my $package = shift;
    my $self = {};

    # Set up Defaults
    $self->{Protect_Default} = 1;   # Should comments be protected from 
                                    #  substitutions?
    $self->{Keep_Default} = 1;      # Should comments be passed to the 
                                    #  output?
    $self->{Gen_Depend_List} = 0;   # Are we generating a dependency list or 
                                    #  simply processing
    $self->{Delimeter} = '@';       # The directive delimeter
    $self->{Defines} = [];          # Defines from the command line
    $self->{Include_Directory} =[]; # Where to look for include files 
    $self->{Output_Filename} = 'STDOUT';   # Where to place the output
    $self->{Modules}=[];            # Modules to load
    $self->{Line_Comment} = '//';   # The Line Comment string
    $self->{Start_Comment} = '/*';  # The Start Comment string
    $self->{End_Comment} = '*/';    # The End Comment string
    $self->{In_Perl_Begin} = 0;     # The Perl_Begin marker
    $self->{Debug} = 0;             # The Debug value
    $self->{Keycount} = 0;          # The Initial count of keys
    $self->{Sync_Lines} = 0;        # Should we generate C-preprocessor-style 
                                    # source file name and line number information?
    $self->{Keep_Comments} = $self->{Keep_Default};
    $self->{Protect_Comments} = $self->{Protect_Default};
    $self->{DPAT} = quotemeta $self->{Delimeter};

    bless $self, $package ;
}

sub ep3_execute {
# The ep3_execute method is used to invoke EP3 as though it were a perl script. 
# The calling perl script would look like this:
#
# require 5;
# use Text::EP3;
# use Text::EP3::Verilog; #(or any other optional modules)
# $self->ep3_execute;
#
# 
    my $self = shift;
    $self->ep3_parse_command_line;
    # Determine what the output file should be (can be set on the command line)
    $self->ep3_output_file;
    # Modules to be loaded can be passed in from the command line
    $self->ep3_modules;
    # Process the defines
    $self->ep3_defines;
    # Process the input file
    $self->ep3_process;
}

sub ep3_parse_command_line {
# Parse the command line using the Getopt::Long module
#
    my $self = shift;
    my $usage = "Usage:\t$0\n\t[-include dir]\n\t[-define key [value]]\n\t[-delimeter string]\n\t[-module modulename]\n\t[-[no]comments]\n\t[-[no]protect]\n\t[-[no]depend]\n\tfile1 [file2 .. filen]\n";
die $usage if (! (&GetOptions (
    "comments!" => \$self->{Keep_Default},        # Pass comments to output?
    "sync_lines!" => \$self->{Sync_Lines},        # Output sync lines?
    "protect!" => \$self->{Protect_Default},      # Protect comments from 
        					  #   substitution?
    "depend!" => \$self->{Gen_Depend_List},       # Are we generating dependency
                                                  #   list or simply processing?
    "delimeter=s" => \$self->{Delimeter},         # The directive delimiter 
    "delimiter=s" => \$self->{Delimeter},         # The directive delimiter 
    "define=s@" => $self->{Defines},              # Defines from command line
    "include=s@" => $self->{Include_Directory},   # Where to find include files
    "output_filename=s" => \$self->{Output_Filename},      
                                                  # Where to place the output
    "modules=s@" => $self->{Modules},             # Modules to load
    "line_comment=s" => \$self->{Line_Comment},   # The Line Comment string
    "start_comment=s" => \$self->{Start_Comment}, # The Start Comment string
    "end_comment=s" => \$self->{End_Comment},     # The End Comment string
)));
    # Set the current comment markers to the defaults (i.e. command line
    # specifies defaults.
    $self->{Keep_Comments} = $self->{Keep_Default};
    $self->{Protect_Comments} = $self->{Protect_Default};
    $self->{DPAT} = quotemeta $self->{Delimeter};
}

sub ep3_reset {
# Reset the preprocessor variables (typically called in between
# multiple distinct files to be preprocessed)
# Note, this does not reset any EP3 of the values set by new, 
# if they have been altered by the user, they will not be changed by ep3_reset.
    my $self = shift;
    undef $self->{Keyline};
    undef $self->{Keyfile};
    undef $self->{Define_List};
    undef $self->{Replace_List};
    undef $self->{Keyfind};
    undef $self->{Macro_Value};
    undef $self->{Macro_Vars};
    $self->{Keycount} = 0;
}



sub ep3_process {
# This is the EP3 engine (along with the _ep3_do_subs routine) ... 
# Process takes a filename as input (the file to be preprocessed).
    my $self = shift;
    local $Text::EP3::filehandle;             # The Input_Filehandle
    local $Text::EP3::filename;
    $Text::EP3::filename = shift if @_;
    my $condition;                   # Are there any conditions on this file?
    $condition = '';
    $condition = shift if @_ ;
    #$condition = shift @_ ;
    #@_ ? $condition = shift : $condition = '';
    my $condition_satisfied;      
    my $condition_start;
    my $condition_end;
    my $in_comment;		
    my $original;	
    my $text_portion;
    my $new_comment_portion = '';
    my $old_comment_portion = '';
    my @pieces;
    my $x;
    my $method;
    my $chomped;
    my @string;
    my $start_pattern = quotemeta $self->{Start_Comment}; 
    my $end_pattern = quotemeta $self->{End_Comment}; 
    my $line_pattern = quotemeta $self->{Line_Comment}; 
    my $result;
    my $sync_start_sent = 0;
     
    print "$self->{Line_Comment}EP3->ep3_process: Entered ep3_process. Line $Text::EP3::line of $Text::EP3::filename: process file:$Text::EP3::filename condition:$condition\n"	if $self->{Debug} & 1;

    $Text::EP3::filehandle = new FileHandle;
    # See which kind of file we are processing
    if (! defined $Text::EP3::filename) {
        # If there is no Input_Filename, 
        if ($#ARGV >= 0) {
            # Set the filename and open the input files ...
            # Is there a better way to do this??
            $Text::EP3::filename = $ARGV[0] if ($#ARGV == 0);
            $Text::EP3::filename = "<" . join (',',@ARGV) . ">" if ($#ARGV >= 1);
            my $filelist = join(' ',@ARGV);
            $result = open($Text::EP3::filehandle,"perl -e 'while (<>) {print;}' $filelist |");
        }
        else {
            # Else just use stdin
            $Text::EP3::filehandle = *STDIN;
            $Text::EP3::filename = 'STDIN';
            $result = 1;
        }
    }
    else {
        $result = open($Text::EP3::filehandle, $Text::EP3::filename);
    }

    die "Could not open $Text::EP3::filename" if (!$result );
    

    # Check for a condition
    # Conditions are used to include files segments, instead of the whole file.
    # If there is a condition, see if it has been satisfied
    if ($condition ne '') {
        $condition_satisfied = 0;
    }
    else {
        $condition_satisfied = 1;
    }
    # Set up the flags on which to look for a condition ...
    # Conditions segments are marked using the mark directive ...
    # If the condition is PORT, the start would be $self->{Delimeter}mark PORT_BEGIN 
    # and the end would be $self->{Delimeter}mark PORT_END
    # @mark PORT_BEGIN
    #  .. lines to include ..
    # @mark PORT_END
    $condition_start = $condition . "_BEGIN";
    $condition_end = $condition . "_END";
 
    $in_comment = 0;

    while (<$Text::EP3::filehandle>) {
        $Text::EP3::line = $.;
        if ($self->{Sync_Lines} && $condition_satisfied && !$sync_start_sent) {
            $sync_start_sent = 1;
            print "\n$self->{Delimeter} $Text::EP3::line \"$Text::EP3::filename\" 1\n" 
        }
        #print "$self->{Line_Comment}EP3->ep3_process:$Text::EP3::line of $Text::EP3::filename: $_"	if $self->{Debug} & 2;
        # First, resolve multiline directives into single line
        # i.e.  make a line that ends in a backslash and whitespace join with
        # the next line
        while (/^\s*$self->{DPAT}\w.*\\\n$/) {
            #print "Got a splitter\n" if $self->{Debug} & 2;
            s/\\\s*\n$//;
            $_ .= <$Text::EP3::filehandle>;
            $Text::EP3::line = $.;
        }
 
        # $original is saved so that we can tell if a blank line was there
        #  before comment deletion
        $original = $_;
 
        #Check if this is  a conditional include
        if ($condition ne '') {
            # If we have found a condition start ....
            if (/^\s*$self->{DPAT}mark\s+$condition_start/) {
                print "$self->{Line_Comment}EP3->ep3_process: Found $condition_start. Looking for $condition_end\n" if 2 & $self->{Debug};
                $condition_satisfied = 1; # Turn on preprocessing
            }
            # continue reading (skip this line) if the condition is not satisfied
            next if ( ! $condition_satisfied);
            if (/^\s*$self->{DPAT}mark\s+$condition_end/) {
                print "$self->{Line_Comment}EP3->ep3_process: Matching $condition_end\n"    if 2 & $self->{Debug};
                $condition_satisfied = 0; # Turn off preprocessing
            }
        }
 
 
        # Do something with comments
        if ( ($self->{Protect_Comments}) || (! $self->{Keep_Comments}) ) {
            $text_portion = $new_comment_portion = $old_comment_portion = '';
            (@pieces) = split /($start_pattern|$end_pattern|$line_pattern)/;
            while ($#pieces >= 0) {
                $x = shift (@pieces);
                #start comment
                if ($x eq $self->{Start_Comment}) {
                    #print "$self->{Line_Comment}EP3->ep3_process: Got comment start\n" if $self->{Debug} & 2;
                    if ($in_comment) {
                        $new_comment_portion .= $x;
                    }
                    else {
                        $new_comment_portion .= $x;
                        $in_comment = 1;
                    }
                }
                #end comment
                elsif ($x eq $self->{End_Comment}) {
                    #print "$self->{Line_Comment}EP3->ep3_process: Got comment end\n" if $self->{Debug} & 2;
                    if ($in_comment) {
                        $in_comment = 0;
                        # end a comment from a previous line
                        if ($new_comment_portion eq '') {
                            $old_comment_portion .= $x;
                        }
                        # end a comment from a current line
                        else {
                           $new_comment_portion .= $x;
                        }
                     }
                     else {
                         carp "end of comment without prior start of comment on line $Text::EP3::line of file $Text::EP3::filename:";
                         $text_portion .= $x;
                     }
                }
                #line comment
                elsif ($x eq $self->{Line_Comment}) {
                    #print "$self->{Line_Comment}EP3->ep3_process: Got comment line\n" if $self->{Debug} & 2;
                    if ($in_comment) {
                        $new_comment_portion .= $x;
                    }
                    else {
                        $new_comment_portion .= $x;
                        #flush the line
                        while ($#pieces >= 0) {
                            $new_comment_portion .= shift(@pieces);
                        }
                    }
                }
                #text
                else {
                    if ($in_comment) {
                        #print "$self->{Line_Comment}EP3->ep3_process: Got comment text\n" if $self->{Debug} & 2;
                       if ($new_comment_portion eq '') {
                           $old_comment_portion .= $x;
                       }
                       #  a comment from a current line
                       else {
                           $new_comment_portion .= $x;
                       }
                    }
                    else {
                       $text_portion .= $x;
                    }
                }
            }
            $_ = $text_portion;
        }
         
        # Now do the substitutions
        $self->_ep3_do_subs() ;
  
        # If this was a directive line ... then lets invoke the directive method
        if (/^(\s*)$self->{DPAT}\w+/) {
            # get rid of any leading spaces and save them in case any
            # directive wants to use them
            $self->{Indent} = $1;
            # get the method token
            @string = split(' ',$_);
            $method = substr($string[0],1,length($string[0])-1);
            #print "$self->{Line_Comment}EP3->ep3_process: attempting to call method ->$method<-\n" if $self->{Debug} & 2;

            # call method if it is available - 
            # I feel that it is pretty important to be able to cover
            # text cases that look like directives and aren't - this is a pretty
            # good check.
            if ( ! $self->can($method)) {
                if ( $self->{In_Perl_Begin} <= 0) { # Normal Case
                    carp "Unknown Directive $self->{Delimeter}$method, Line $Text::EP3::line of file $Text::EP3::filename, Passing to output:";
                }
            }
            else {
                # Get rid of the strict so that user's routines are a little more
                # flexible ... They can always put strict in their routines if
                # they want them ...
                no strict;
                $self->$method($_);
                use strict;
                # Clear the line so that nothing prints
                $_ = '';
            }
        }
        if (! $self->{Keep_Comments}) {
            # delete the blank lines which are a result of comment deletion
            if ( ($original ne $_) && (/^\s*$/) ) {
                $_ = '';
            }
            else {
                # put the newline back if it was inside a comment
                $_ .= "\n" if ($_ !~ /\n$/);
            }
        }
        if (($self->{Protect_Comments}) && ($self->{Keep_Comments}) ) {
            # move the trailing \n in the text portion to the end of the line
            # e.g.  the line
            # hello /* barney */
            # should not result in ...
            # hello 
            # /* barney */
            # Which it would if the newline part of the text portion gets placed
            # before the comment at the end of the text portion.
            $chomped = chomp;
            $_ = $old_comment_portion . $_ . $new_comment_portion;
            $_ .=  "\n" if $chomped;
            #print "$self->{Line_Comment}EP3->ep3_process: comment portion = ->$new_comment_portion<-\n" if $self->{Debug} & 2;
        }
  
        if ( $self->{In_Perl_Begin} <= 0) {   # Normal Case 
            print "$_";
        }  
        else {  # Oh! We're in a perl_begin diversion. Stash it away.
            push(@{$self->{Perl_Lines}}, $_);
        }
    }
}
 
sub _ep3_save_directive {
# This subroutine splits off the portion of a directive line to be preotected
# from substitution and saves it in the save_directive variable
    my $self = shift;
    my $line = shift;
    my $save_directive;
    my @ret;
    if (defined $self->{DPAT} && $line =~ /^(\s*$self->{DPAT}\w+)/) {
        print "$self->{Line_Comment}EP3->_ep3_save_directive: Saving the directives on a delimeter line\n" if $self->{Debug} & 2;
        # Save the directive ..
        $save_directive = $1;
        # What to do for substitutions inside of directive lines? 
        # perform substitutions unless requesting not to?
        if ( $line =~ (/^(\s*$self->{DPAT}if[n]*def\s+\w+)/) || 
                      (/^(\s*$self->{DPAT}define\s+\w+)/)    ||
        	      (/^(\s*$self->{DPAT}macro\s+\w+)/)     || 
        	      (/^(\s*$self->{DPAT}replace\s+\w+)/) ) {
            #For these directives, save the directive and the key so that
            #substititions are not performed on them.
            $save_directive = $1;
            $line =~ s/$save_directive//;
        }
        else {
            #Here, just protect the directive itself
            $line =~ s/$save_directive//;
        }
    }
    else {
        #If not a directive, then clear the save directive marker
        $save_directive = '';
    }

    @ret = ($save_directive,$line);
    #print "$self->{Line_Comment}EP3->_ep3_save_directive: Returning directive ->$save_directive<-\n" if $self->{Debug} & 2;
    #print "$self->{Line_Comment}EP3->_ep3_save_directive: Returning \$_ ->$_<-\n" if $self->{Debug} & 2;
    return (@ret);
  
}

sub _ep3_do_subs
{
# This is the actual guts of the module - where the substitutions take place
    my $self = shift;
    my($key) = @_;
    my (@macvars, $newmacro, @newvars, $newvar, $var, $save_directive);

    # Should we do substitutions on this line?
    ($save_directive,$_) = $self->_ep3_save_directive($_);

    # We have to pull the keys out in the order that we received them
    foreach $key (@{$self->{Keylist}}) {
    # First see if this key is in the line... this is simply a timesaver
    # Tried other types of timesavers (study, building search databases and
    # functions, but the simple approach proved fastest for most every
    # application.
        if (index($_, $key) >= 0) {
            # Check for defined macros first
            if (defined $self->{Macro_Value}{$key} ) {
                if( /(^|\W)$key\((.*)\)(\W|$)/ ) {
                @newvars = split(',',$2);
                @macvars = split (',',$self->{Macro_Vars}{$key});
                die "Macro and definition have different number of variables" if ($#newvars != $#macvars);
                $newmacro = $self->{Macro_Value}{$key};
                foreach $var (@macvars) {
                    $newvar = shift (@newvars);
                    $newmacro =~ s/(^|\W)\Q$var\E(\W|$)/$1$newvar$2/g;
                }
                s/(^|\W)$key\(.*\)(\W|$)/$1$newmacro$2/g;
                #print "/*<$1$key(.*)$2> replaced by macro definition <$1$newmacro$2>\n*/" if $self->{Debug} & 2;
              }
            }
            # Then check for defines
            elsif (defined $self->{Define_List}{$key} ) {
                if( s/(^|\W)$key(\W|$)/$1$self->{Define_List}{$key}$2/g ){
                    #print "/*<$1$key$2> defined with <$1$self->{Define_List}{$key}$2>\n*/"	if $self->{Debug} & 2;
                }
            }
            # And finally replaces
            elsif (defined $self->{Replace_List}{$key} ) {
                if( s/$key/$self->{Replace_List}{$key}/g){
                    #print "/*<$key> replaced with <$self->{Replace_List{$key}>\n*/"	if $self->{Debug} & 2;
                }
            }
        }
    }
    # Put the protected directive portion back on the line
    $_ = $save_directive . $_;
}

sub replace;
sub define;
sub macro;
sub undef;
sub include;
sub elif;
sub elsif;
sub else;
sub ifndef;
sub ifdef;
sub endif;
sub if;
sub enum;
sub eval;
sub perl_begin;
sub perl_end;
sub _ep3_output_code;
sub mark;
sub ep3;
sub protect;
sub comment;
sub debug;

sub ep3_end_comment ;
sub ep3_start_comment ;
sub ep3_line_comment ;
sub ep3_delimiter ;
sub ep3_delimeter ;
sub ep3_gen_depend_list ;
sub ep3_keep_comments ;
sub ep3_sync_lines ;
sub ep3_protect_comments ;
sub ep3_modules ;
sub ep3_includes ;
sub ep3_defines ;
sub ep3_require_modules ;
sub ep3_output_file ;

1;

__END__
sub replace
# replace is simply a define that doesn't tokenize
# usage: @replace key value
{
    my $self = shift;
    print "$self->{Line_Comment}EP3->replace: Entered replace.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    $self->define (@_);
}

sub define
# Replace tokenized keys with the strings that follow 
# usage: @define key value
# (unless called by replace)
{
    my $self = shift;
    my(@input_string) = @_;
    my(@string);
    my($inline, $directive, $key);
 
    $inline = $input_string[0];
    @string = split(' ',$inline);
    print "$self->{Line_Comment}EP3->define: Entered define.  Line $Text::EP3::line of $Text::EP3::filename  The key is $string[1]\n"	if $self->{Debug} & 1;
 
    # parse key string
    $directive = shift @string;
    $key = shift @string;
 
    # make sure there is a key
    if ($key eq '') {
        die "No key definition in $self->{Delimeter}$directive, line $Text::EP3::line of $Text::EP3::filename";
    }
 
    # make sure we haven't seen this key
    if (defined $self->{Keyline}{$key}) {
        #carp "Key $key at line $Text::EP3::line in $Text::EP3::filename was previously defined at line $self->{Keyline}{$key} in file $self->{Keyfile}{$key}:";
        print "$self->{Line_Comment}EP3->define: Key $key at line $Text::EP3::line in $Text::EP3::filename was previously defined at line $self->{Keyline}{$key} in file $self->{Keyfile}{$key}:" if $self->{Debug} & 4;
    }
 
    # If there is no replacement string (i.e. just a define) make the
    # replacement string a null
    if ($#string < 0) {
        #$inline = $key . "\n";
        $inline = "\n";
    }
 
    $inline =~ s/^$directive[\s]*$key\s//;
    chomp ($inline);
    @string = ($directive,$key,$inline);
 
    # mark the self->{Keyline} with the current line number. This marks it as used, 
    # and also gives us a little info as to where.
    $self->{Keyline}{$key} = $Text::EP3::line;
    $self->{Keyfile}{$key} = $Text::EP3::filename;
 
    # place it in the key list and bump the keycount
    $self->{Keylist}[$self->{Keycount}] = $key;
    $self->{Keycount}++;
    # save the keycount in the self->{Keyfind} array to make undefines easy
    $self->{Keyfind}{$key} = $self->{Keycount};
 
    # add the stuff to replace the key with to the self->{Define_List}

    if ($directive =~ /^\s*$self->{DPAT}define/) {
        $self->{Define_List}{$key} = $inline;
        print "$self->{Line_Comment}EP3->define: Key = $key, defined as ->$self->{Define_List}{$key}<-\n" if $self->{Debug} & 4;
    }
    elsif ($directive =~ /^\s*$self->{DPAT}replace/) {
        $self->{Replace_List}{$key} = $inline;
        print "$self->{Line_Comment}EP3->define: Key = $key, replace with ->$self->{Replace_List}{$key}<-\n" if $self->{Debug} & 4;
    }
}

sub macro
# Perform macro substitution
# usage: @macro key(a,b) f(a,b)
{
    my $self = shift;
    my(@input_string) = @_;
    my(@string);
    my($inline, $directive, $key);
    my($macro_name, $macro_vars, $newline);
 
    $inline = $input_string[0];
    @string = split(' ',$inline);
    print "$self->{Line_Comment}EP3->macro: Entered macro.  Line $Text::EP3::line of $Text::EP3::filename  $string[0] $string[1]\n"	if $self->{Debug} & 1;
 
    # parse key string
    $directive = shift @string;
    $key = shift @string;
 
    # make sure there is a key
    if ($key eq '') {
        die "No key definition in $self->{Delimeter}$directive, line
        $Text::EP3::line of $Text::EP3::filename";
    }
 
    $inline =~ s/^$directive[\s]+\Q$key\E\s//;
 
    chomp ($inline);
    @string = ($directive,$key,$inline);
 
    if ($key =~ /(\w+)\((.*)\)/) {
        $macro_name = $1;
        $macro_vars = $2;
        if ($macro_vars !~ /^[\w+,]*\w+$/) {
            die "Bad macro variable $macro_vars";
        }
    }
    else {
        # This really isn't a macro now is it ....
        # So lets just make it a define ...  maybe with a carp ...
        carp "The macro definition at line $Text::EP3::line of $Text::EP3::filename contains no variables ... doing $self->{Delimeter}define instead:";
        $newline = $input_string[0];
        $newline =~ s/^(\s*$self->{DPAT})macro/$1define/;
        return( $self->define($newline));
    }
 
 
    # mark the self->{Keyline} with the current line number. This marks it as used, 
    # and also gives us a little info as to where.
    $self->{Keyline}{$macro_name} = $Text::EP3::line;
    $self->{Keyfile}{$macro_name} = $Text::EP3::filename;
 
    # place it in the key list and bump the keycount
    $self->{Keylist}[$self->{Keycount}] = $macro_name;
    $self->{Keycount}++;
    # save the keycount in the self->{Keyfind} array to make undefines easy
    $self->{Keyfind}{$macro_name} = $self->{Keycount};
 
    $self->{Macro_Value}{$macro_name} = $inline;
    $self->{Macro_Vars}{$macro_name} = $macro_vars;
    print "$self->{Line_Comment}EP3->macro: Macro = $macro_name, defined as ->$self->{Macro_Value}{$macro_name}<-\n" if $self->{Debug} & 4;
    print "$self->{Line_Comment}EP3->macro:    with variables $self->{Macro_Vars}{$macro_name}\n" if $self->{Debug} & 255;
}

sub undef
# Undefine a key
# usage: @undef key
{
    my $self = shift;
    my(@input_string) = @_;
    my(@string);
    my($inline, $directive, $key);
 
    $inline = $input_string[0];
    @string = split(' ',$inline);
    print "$self->{Line_Comment}EP3->undef: Entered undef.  Line $Text::EP3::line of $Text::EP3::filename  $string[0] $string[1]\n"	if $self->{Debug} & 1;
 
    # parse key string
    $directive = shift @string;
    $key = shift @string;
 
    # make sure there is a key
    if ($key eq '') {
        die "No key definition in $self->{Delimeter}$directive, line
        $Text::EP3::line";
    }
 
    # Error if there is extraneous stuffs.
    if ($#string >= 0) {
        die "Extraneous information: $self->{Delimeter}directive $key ->" . join (' ',@string) . " <-\n";
    }
 
    # make sure we have seen this key
    if ($self->{Keyline}{$key} eq '') {
        carp "Key $key on line $Text::EP3::line of file $Text::EP3::filename not previously defined:" if $self->{Debug} & 4;
    }
    else {
        splice (@{$self->{Keylist}},$self->{Keyfind}{$key},1);
        delete $self->{Keyline}{$key} if exists $self->{Keyline}{$key};
        delete $self->{Keyfile}{$key} if exists $self->{Keyfile}{$key};
        delete $self->{Define_List}{$key} if exists $self->{Define_List}{$key};
        delete $self->{Replace_List}{$key} if exists $self->{Replace_List}{$key};
        delete $self->{Keyfind}{$key} if exists $self->{Keyfind}{$key};
        delete $self->{Macro_Value}{$key} if exists $self->{Macro_Value}{$key};
        delete $self->{Macro_Vars}{$key} if exists $self->{Macro_Vars}{$key};
    }
 
}

sub include
# Include a file for processing
# usage: @include "file"  or <file>
# the @{$self->{Include_Directory}} is the search path if the file is included with
# <>, if the file is included with "", then the current directory is prepended
# to @${self->{Include_Directory}).
{
    my $self = shift;
    my (@input_string) = @_;
    my (@string);
    my ($inline, $directive, $key);
    my ($condition);
    my ($file, $result, $dir);
    my ($current_dir);
    my $start_pattern = quotemeta $self->{Start_Comment}; 
    my $line_pattern = quotemeta $self->{Line_Comment}; 
    my $return_line = $Text::EP3::line + 1;
 
    $inline = $input_string[0];
    @string = split(' ',$inline);
    print "$self->{Line_Comment}EP3->include: Entered include.  Line $Text::EP3::line of $Text::EP3::filename   $string[1]\n"		if $self->{Debug} & 1;
 
    # parse key string
    $directive = shift @string;
    $file = shift @string;
 
    # make sure there is a key
    if ($file eq '') {
       die "No file for $directive";
    }

    # check for conditional string
    #@string ? $condition = shift @string : $condition = '';
    $condition = shift @string ;
    print "$self->{Line_Comment}EP3->include: $directive condition is $condition\n" if $self->{Debug} & 8;
 
    if (!defined $condition || $condition =~ /(^$line_pattern|^$start_pattern)/ ) {
        $condition = '';	# Was a comment. ignore.
    }
 
    if ($file =~ /"(.*)"/) {
        $current_dir = cwd();
        $file = $1;
    }
    elsif ($file =~ /<(.*)>/) {
        $current_dir = '';
        $file = $1;
    }
    else {
        die "$directive: invalid include $file";
    }

    #Check if the file is absolute.
    $result = 0;
    if ($file =~ /^\//) {
        $result = 1 if (-e $file);
    }
    else {
        foreach $dir ($current_dir, @{$self->{Include_Directory}}) {
            print "$self->{Line_Comment}EP3->include: Checking $dir/$file\n" if
            $self->{Debug} & 8;
            $result = 1 if (-e "$dir/$file");
            if ($result) {
                print "$self->{Line_Comment}EP3->include: include: $dir/$file\n"	if $self->{Debug} & 8;
                # Change file so it is now absolute.
                $file = "$dir/$file";
                last; # got one, so exit the loop
            }
        }
    }
 
    if (! $result) {
        die "$directive: couldn't find $file: $!";
    }
    else {
        # Print the file in the dependlist and then read it
        print $Text::EP3::Dependfile_Handle "$file\n" if $self->{Gen_Depend_List};
        print "$self->{Line_Comment}EP3->include: include: Getting ready to iterate with file ->$file<- and condition ->$condition<-\n"	if $self->{Debug} & 8;
        # Iteratively process this file
        $self->ep3_process ($file, $condition);
    }
    print "\n$self->{Delimeter} $return_line \"$Text::EP3::filename\" 2\n" if $self->{Sync_Lines};
}

sub elif
# The basic elsif
# usage: @elif condition
{
    my $self = shift;
    print "$self->{Line_Comment}EP3->elif: Entered elif.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    $self->else(@_);
}

sub elsif
# The basic elsif
# usage: @elsif condition
{
    my $self = shift;
    print "$self->{Line_Comment}EP3->elsif: Entered elsif.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    $self->else(@_);
}


sub else
# Skip to endif if there is an ifdef in progress.
# The basic else
# usage: @else
{
    my $self = shift;
    my(@input_string) = @_;
    my(@string);
    my($inline, $directive, $initifdef);
 
    print "$self->{Line_Comment}EP3->else: Entered else.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    $inline = $input_string[0];
    @string = split(' ',$inline);
 
    # parse key string
    $directive = shift @string;
 
    if (! $self->{Ifdef}) {
        die "Unexpected $directive";
    }
 
    print "$self->{Line_Comment}EP3->else: Got an else or el[s]if: Ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
    # Set initifdef = to the current count for nesting checks
    $initifdef = $self->{Ifdef};
    while (<$Text::EP3::filehandle>) {
        $Text::EP3::line = $.;
        if (/^\s*$self->{DPAT}if/) {
            # Inside of loops, keep an index for the ifdef
            $self->{Ifdef} ++;
            print "$self->{Line_Comment}EP3->else: Upping ifdef count = $self->{Ifdef}\n" if $self->{Debug} & 16;
        }
  
        if (/^\s*$self->{DPAT}endif/) {
            $self->{Ifdef}--;
            print "$self->{Line_Comment}EP3->else: Got an endif: Ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
            print "$self->{Line_Comment}EP3->else:               level = $initifdef\n" if $self->{Debug} & 16;
            # If this is still in a nested loop, pass it by
            next if $initifdef <= $self->{Ifdef};
            #break out of while loop
            last;
        }
    }
    print "The else or el[s]if is done: Ifdef = $self->{Ifdef}\n" if $self->{Debug}
    &16;
}

sub ifndef
# Skip to endif if there is an the key is not defined
# The basic ifndef
# usage: @ifndef key
{
    my $self = shift;
    print "$self->{Line_Comment}EP3->ifndef: Entered ifndef.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    $self->ifdef(@_);
}

sub ifdef
# Read to endif if the key is defined. Otherwise, ignore to endif
# The basic ifdef
# usage: @ifdef key
{
    my $self = shift;
    my(@input_string) = @_;
    my(@string);
    my($inline, $directive, $key, $skip, $initifdef);
 
    print "$self->{Line_Comment}EP3->ifdef: Entered ifdef.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    $inline = $input_string[0];
    @string = split(' ',$inline);
 
    # parse key string
    $directive = shift @string;
    $key = shift @string;
 
    # Bumb up the ifdef count if this is a new ifdef
    if ($directive !~ /^\s*$self->{DPAT}el[s]*if/) {
        $self->{Ifdef}++;
    }
 
    print "checking if self->{Keyline}{$key} is defined ->$self->{Keyline}{$key}<-\n" if $self->{Debug} & 16;
    print "directive = $directive\n" if $self->{Debug} & 16;
    print "Ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
 
    # see if the key is defined
    if (! defined $self->{Keyline}{$key}) {
        $skip = 1;
    }
 
    #This is opposite of the ifndef
    if ($directive =~ /^\s*$self->{DPAT}ifndef/) {
        print "We have and ifndef\n" if $self->{Debug} & 16;
        $skip = !($skip);
    }
 
    # If skip, continue until endif
    if ($skip) {
        # Set initifdef = to the current count for nesting checks
        $initifdef = $self->{Ifdef};
        while (<$Text::EP3::filehandle>) {
            $Text::EP3::line = $.;
            if (/^\s*$self->{DPAT}if/) {
                # Inside of loops, keep an index for the ifdef
                $self->{Ifdef} ++;
                print "Upping ifdef level = $self->{Ifdef}\n" if $self->{Debug} & 16;
            }
   
            if (/^\s*$self->{DPAT}else/) {
                # If this is in a nested loop, pass it by
                print " Got an else: Ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
                next if $initifdef < $self->{Ifdef};
                #break out of while loop
                last;
            }
            if (/^\s*$self->{DPAT}el[s]*if/) {
                # If this is in a nested loop, pass it by
                print "$self->{Line_Comment}EP3->ifdef: Got an el[s]if: Ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
                next if $initifdef < $self->{Ifdef};
                #break out of while loop
                $self->ifdef($_);
                last;
            }
            if (/^\s*$self->{DPAT}endif/) {
                $self->{Ifdef}--;
                print "$self->{Line_Comment}EP3->ifdef: Got an endif: Ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
                print "$self->{Line_Comment}EP3->ifdef:               level = $initifdef\n" if $self->{Debug} & 16;
                # If this is still in a nested loop, pass it by
                next if $initifdef <= $self->{Ifdef};
                #break out of while loop
                last;
            }
        }
    }
}

sub endif
# Conclude an open if{def} structure
# The basic endif
# usage: @endif
{
    my $self = shift;
    print "$self->{Line_Comment}EP3->endif: Entered endif.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    $self->{Ifdef}--;
    print "$self->{Line_Comment}EP3->endif: ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
    if ($self->{Ifdef} < 0) {
        die "Unexpected $self->{Delimeter}endif";
    }
}

sub if
# Read to endif if the expr evaluates true. Otherwise, ignore to endif
# The basic if, except that any perl expression can be evaluated
# usage: @if expr
{
    my $self = shift;
    my(@input_string) = @_;
    my(@string);
    my($inline, $directive, $expr, $skip, $ifkeynum, $result, $initifdef);
 
    print "$self->{Line_Comment}EP3->if: Entered if.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    $inline = $input_string[0];
    @string = split(' ',$inline);
 
    # parse key string
    $directive = shift @string;
    $expr =  join(' ',@string);	# Put together the rest of it
 
    # Bumb up the ifdef count if this is a new ifdef
    if ($directive !~ /^\s*$self->{DPAT}el[s]*if/) {
        $self->{Ifdef}++;
    } 
    # see if the expression evaluates
    no strict;
    $result = eval($expr);
    die "Error in the if clause at line $Text::EP3::line of $Text::EP3::filename -> $@" if $@;
    print "$self->{Line_Comment}EP3->if: $expr evaluates to $result\n" if
    $self->{Debug} & 16;
    if (! $result) {
        $skip = 1;
    }
    use strict;

    # If skip, continue until endif
    if ($skip) {
        # Set initifdef = to the current count for nesting checks
        $initifdef = $self->{Ifdef};
        while (<$Text::EP3::filehandle>) {
            $Text::EP3::line = $.;
            if (/^\s*$self->{DPAT}if/) {
                # Inside of loops, keep an index for the ifdef
                $self->{Ifdef} ++;
                print "$self->{Line_Comment}EP3->if: Upping ifdef level = $self->{Ifdef}\n" if $self->{Debug} & 16;
            }
   
            if (/^\s*$self->{DPAT}else/) {
                # If this is in a nested loop, pass it by
                print "$self->{Line_Comment}EP3->if: Got an else: Ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
                next if $initifdef < $self->{Ifdef};
                #break out of while loop
                last;
            }
            if (/^\s*$self->{DPAT}el[s]*if/) {
                # If this is in a nested loop, pass it by
                print "$self->{Line_Comment}EP3->if: Got an el[s]if: Ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
                next if $initifdef < $self->{Ifdef};
                #break out of while loop
                # We must first parse this line for substitutions
                $self->_ep3_do_subs();
                $self->if($_);
                last;
            }
            if (/^\s*$self->{DPAT}endif/) {
                $self->{Ifdef}--;
                print "$self->{Line_Comment}EP3->if: Got an endif: Ifdef = $self->{Ifdef}\n" if $self->{Debug} & 16;
                print "$self->{Line_Comment}EP3->if:               level = $initifdef\n" if $self->{Debug} & 16;
                # If this is still in a nested loop, pass it by
                next if $initifdef <= $self->{Ifdef};
                #break out of while loop
                last;
            }
        }
    }
}

sub enum
# Emulate enumerated lists by generating multiple defines
# usage: @enum key,key,key,[value],key, ...
{
    my $self = shift;
    my ($inline) = @_;		# Single arg: Cmd line
    my (@string,@dlist,$count);
    my ($directive, $key);
    my ($sigstring);
    my ($ecom)="$self->{Line_Comment}EP3->enum: ";
    my $signals;

    $count = 0;				# default initial value
    $sigstring = '';			# default initial value
    @string = split(' ',$inline);	# Split at spaces
    $directive = shift @string;		# Pop off the @enum
    $signals =  join(' ',@string);	# Put together
    $signals =~ s/ //g;			# Elim spaces
    @dlist = split(',',$signals);	# Split into list at commas
 
    print "$self->{Line_Comment}EP3->enum: Entered enum.  Line $Text::EP3::line of $Text::EP3::filename   $string[1]\n"		if $self->{Debug} & 1;
 
    # parse key string
    foreach $key (@dlist) {
        if ( $key =~ /^[0-9]*$/){
            # We can reinitialize the count at any point
            $count = $key;
        }
        else { # define the key as the number
            $directive = "$self->{Delimeter}define";
            $sigstring = "${directive} ${key} ${count}\n";
            $ecom .= " $key=${count},";
            $self->define($sigstring);
            $count++;
        }
    }
    # Remove trailing ','
    $ecom =~ s/,$//;
    print $ecom . "\n" if $self->{Debug} & 4;;
}

sub eval
# eval perl expressions and define the key with the result
# usage: @eval key expr
{
    my $self = shift;
    my(@input_string) = @_;
    my(@string);
    my($inline, $directive, $key, $expr, $result, $newstring);
 
    print "$self->{Line_Comment}EP3->eval: Entered eval.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    $inline = $input_string[0];
    @string = split(' ',$inline);
 
    # parse key string
    $directive = shift @string;
    $key = shift @string;
    $expr =  join(' ',@string);
    no strict;
    $result = eval ($expr);
    use strict;
    die "Error in the eval clause at line $Text::EP3::line of $Text::EP3::filename-> $@" if $@;
 
    $directive = "$self->{Delimeter}define";
    $newstring = "$directive $key $result\n";
 
    $self->define($newstring);
}

 
 
sub perl_begin
# Read to perl_end and then evaluate the lines read
# usage: @perl_begin
# lines can be interpolated and then printed by using the output directives,
# @> and @>>  @<<.  Lines preceded with @> will be interpolated and printed. 
# Lines in betwee @>> and @<< will be interpolated and printed.
# subroutines can be declared as methods and then called by EP3 as directives.
{
    my $self = shift;
    my(@input_string) = @_;
    my(@string);
    my($inline, $directive, $expr, $skip, $ifkeynum);
    my($method_name);
    my(@subroutines) = ();
  
    print "$self->{Line_Comment}EP3->eval: Entered perl_begin.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    # print "In perl_begin...\n";
    $inline = $input_string[0];
    @string = split(' ',$inline);
    $self->{In_Perl_Begin}++;
    while (<$Text::EP3::filehandle>) {
        $Text::EP3::line = $.;
        # Treat directives with \ at the end as one line.
        while (/^\s*[$self->{DPAT}][\w>]+.*\\\s*\n/) {
            print "Got a splitter\n" if $self->{Debug} & 32;
            s/\\\s*\n$//;
            $_ .= <$Text::EP3::filehandle>;
            $Text::EP3::line = $.;
        }
        if ( ! /^\s*$self->{DPAT}perl_end/ ){
            print "$self->{Line_Comment}EP3->eval: Processing ->$_" if $self->{Debug} & 32;
            $self->_ep3_do_subs();
            #print "$self->{Line_Comment}EP3->eval: Now ->$_" if $self->{Debug} & 32;
            # Change $self->{Delimeter}> and $self->{Delimeter}>> references to be code includers
            # i.e. call _ep3_output_code on the affected lines
            # $self->{Delimeter}> is a single line,
            # $self->{Delimeter}>> is a multi-line closed by $self->{Delimeter}<<
            s/^(\s*)$self->{DPAT}>>/\$self->_ep3_output_code (qq($1   /;
            s/$self->{DPAT}<<\s*$/));\n/;
            s/^(\s*)$self->{DPAT}>(.*)/\$self->_ep3_output_code (qq($1  $2));/;
            # Now change any other directives into funtion calls
            if (/^\s*sub\s+(\w+)/) {
                # add any subroutines being declared to a list
                push (@subroutines, $1);
                print "$self->{Line_Comment}EP3->eval: Adding $1 to the subroutine list.\n" if $self->{Debug} & 32;
            }
            if (/^\s*$self->{DPAT}(\w+)/ ) {
                print "$self->{Line_Comment}EP3->eval: It's a Directive instance!\n" if $self->{Debug} & 32;
                # if a line beginning with @... is found, check to see
        	# if it is a method that has already been defined,
        	# or a subroutine being defined. If it is, assume it
        	# to be a directive statement. (This avoids confusion
        	# with perl constructs (arrays if the delimeter is an '@')
        	$method_name = $1;
                if ( ($self->can($method_name)) || (grep /^$method_name$/,@subroutines)) {
        	    ##############################################
        	    # Deal with directives inside the perl script
        	    ##############################################
        	    # Set it up so that it does interpolate
        	    # This makes directive behavior different within
        	    # The PERL construct as it is without, but gives
        	    # the added benefit of being able to interpolate 
        	    # on directive keys as well as definitions, which
        	    # is likely why we are in the PERL construct to
        	    # begin with.
                    # Change the directive to a method invocation for
        	    # perl evaluation
                    s/^(\s*)$self->{DPAT}(\w+)\s+(.*)/$1\$self->$2("\$self->{Delimeter}$2 $3\n");/ ;
                    print "$self->{Line_Comment}EP3->eval: Directive line is now ->$_" if $self->{Debug} & 32;
                }
            }
            push(@{$self->{Perl_Lines}}, $_);
        }
        else {
            $self->perl_end($_);
            last;		# Done!
        }
    }
}
 
sub perl_end
# the end of the included perl script
# usage: @perl_end
{
    my $self = shift;
    print "$self->{Line_Comment}EP3->perl_end: Entered perl_end.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    # print "In perl_end.\n";
    if ( $self->{In_Perl_Begin} > 0){
        $self->{In_Perl_Begin}--;
  
        print "perl_end: Evaluating...\n" if $self->{Debug} & 32;
        # see if the key is defined
        no strict; # Turn of strict for embedded evaluations
        eval "@{$self->{Perl_Lines}}"; 
        if ($@){
            use strict;
            # There was an error in the evaluation!
            die "Error in the PERL script ending at line $Text::EP3::line of $Text::EP3::filename -> $@" if $@;
        }
  
        @{$self->{Perl_Lines}} = ();     # Empty it out
    }
  
    $self->{In_Perl_Begin} = 0;          # All done.
}

sub _ep3_output_code {
# This is not a directive, but can be called from within a perl_begin block
#  when the block is being used to generate actual code.
#  This make the code easier to read.
# EX:
# for ($j = 0; $j < 7; $j = $j + 1)
# EP3->_ep3_output_code (qq(
#    case ($j) begin
#      ...
#    end
# ));
    my $self = shift;
    my ($line);

    foreach $line (@_) {
       print "$line\n";
    }
}

# Placeholder for the mark directive. Actually handled by the ep3_process routine
# usage: @mark key_BEGIN
# usage: @mark key_END
sub mark
{
    my $self = shift;
}

# Turn ep3 on or off
# usage: @ep3 on|off
sub ep3
{
    my $self = shift;
    my(@input_string) = @_;
    print "$self->{Line_Comment}EP3->perl_end: Entered ep3.  Line $Text::EP3::line of $Text::EP3::filename   $input_string[1]\n"		if $self->{Debug} & 1;
 
    my $inline = $input_string[0];
    my @string = split(' ',$inline);
 
    my $directive = shift @string;
    my $key = shift @string;
    if ($key =~ /off/i) {
        print "$self->{Line_Comment}EP3->perl_end: ep3 off.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
        while (<$Text::EP3::filehandle>) {
            $Text::EP3::line = $.;
            if (/$self->{DPAT}ep3\s*on/i) {
                last;
            }
            else {
                print 
            }
        }
        print "$self->{Line_Comment}EP3->perl_end: ep3 on.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 1;
    }
    elsif ($key =~ /off/i) {
        carp "ep3 on issued without a ep3 off at line $Text::EP3::line of $Text::EP3::filename:";
    }
}

# Turn comment protection (should substitution be done inside comments?) 
# one of on,off,pervious value, default value
# usage: @protect on|off|previous|default
sub protect
{
    my $self = shift;
    print "$self->{Line_Comment}EP3->protect: Entered PROTECT.  Line $Text::EP3::line of $Text::EP3::filename\n"		if $self->{Debug} & 2;
    $self->comment(@_);
}

# Turn comment inclusion 
# one of on,off,pervious value, default value
# usage: @comment on|off|previous|default
sub comment
{
    my $self = shift;
    my(@input_string) = @_;
    my($inline, $directive, $key);
    $inline = $input_string[0];
    print "$self->{Line_Comment}EP3->comment: Entered comment.  Line $Text::EP3::line of $Text::EP3::filename    $input_string[1]\n"		if $self->{Debug} & 2;
    my @string = split(' ',$inline);
 
    $directive = shift @string;
    $key = shift @string;
    if ($key =~ /on/i) {
       # Set previous up so source that the comment routine can restore them
       $self->{Keep_Previous} = $self->{Keep_Comments};
       $self->{Protect_Previous} = $self->{Protect_Comments};
       if ($directive =~ /comment/){
          $self->{Keep_Comments} = 1;
       }
       else
       {
          $self->{Protect_Comments} = 1;
       }
    }
    elsif ($key =~ /off/i) {
        # Set previous up so source that the comment routine can restore them
        $self->{Keep_Previous} = $self->{Keep_Comments};
        $self->{Protect_Previous} = $self->{Protect_Comments};
        if ($directive =~ /comment/){
            $self->{Keep_Comments} = 0;
        }
        else {
            $self->{Protect_Comments} = 0;
        }
    }
    elsif ($key =~ /PRE/i) {
        if ($directive =~ /comment/){
            $self->{Keep_Comments} = $self->{Keep_Previous};
        }
        else {
            $self->{Protect_Comments} = $self->{Protect_Previous};
        }
    }
    elsif ($key =~ /DEF/i) {
        if ($directive =~ /comment/){
            $self->{Keep_Comments} = $self->{Keep_Default};
        }
        else {
            $self->{Protect_Comments} = $self->{Protect_Default};
        }
    }
    else {
        die("Unkown $directive key, $key\n");
    }
}

# Turn Debugging on (prints lines to output file, not STDERR)
# usage: @debug on|off|value
# the on value is 1, the off value is 0
# 
# Debug values are 
# 0x01  1  - Primary messages (Entering Subroutines)
# 0x02  2  - ep3_process Engine
# 0x04  4  - define (replace, macro, eval, enum)
# 0x08  8  - include
# 0x10  16 - if (else, ifdef, etc.)
# 0x20  32 - perl_begin/end
sub debug
{ 
    my $self = shift;
    my($inline)=@_;	# first line only
    my(@words)= split(' ',$inline);
    print "$self->{Line_Comment}EP3->debug: Entered debug.  Line $Text::EP3::line of $Text::EP3::filename  $words[1]\n" if $self->{Debug} & 1;
  
    if($#words < 1){
        print "$self->{Line_Comment}EP3->debug: Debug Currently Set to $self->{Debug}\n";
    } 
    elsif ($words[1] =~ /on/i){
        $self->{Debug} = 1;
        print "$self->{Line_Comment}EP3->debug: debug set to $self->{Debug}\n";
    } 
    elsif ($words[1] =~ /off/i){
        $self->{Debug} = 0;
        print "$self->{Line_Comment}EP3->debug: debug set to $self->{Debug}\n";
    } 
    elsif ($words[1] =~ /0x[a-h0-9]+/i){ # Allow  0x##
        $self->{Debug} = oct($words[1]);
        print "$self->{Line_Comment}EP3->debug: debug set to $self->{Debug}\n";
    } 
    elsif ($words[1] =~ /(~0|\d+)/i){ # Allow #'s or ~0 or 0x##
        $self->{Debug} = 0 | $words[1];		# Numeric Value
        print "$self->{Line_Comment}EP3->debug: debug set to $self->{Debug}\n";
    } 
    else {
        print "$self->{Line_Comment}EP3->debug: Ignoring $inline\n";
    }
}

sub ep3_end_comment {
    my $self = shift;
    @_ ? $self->{End_Comment} = shift : $self->{End_Comment};
}

sub ep3_start_comment {
    my $self = shift;
    @_ ? $self->{Start_Comment} = shift : $self->{Start_Comment};
}

sub ep3_line_comment {
    my $self = shift;
    @_ ? $self->{Line_Comment} = shift : $self->{Line_Comment};
}

sub ep3_delimeter {
    my $self = shift;
    if (@_) {
        $self->{Delimeter} = shift;
        $self->{DPAT} = quotemeta $self->{Delimeter};
    }
    $self->{Delimeter};
}

sub ep3_delimiter { 
    my $self = shift;
    $self->ep3_delimeter(@_);
}

sub ep3_gen_depend_list {
    my $self = shift;
    @_ ? $self->{Gen_Depend_List} = shift : $self->{Gen_Depend_List};
}

sub ep3_keep_comments {
    my $self = shift;
    @_ ? $self->{Keep_Comments} = shift : $self->{Keep_Comments};
}

sub ep3_sync_lines {
    my $self = shift;
    @_ ? $self->{Sync_Lines} = shift : $self->{Sync_Lines};
}

sub ep3_protect_comments {
    my $self = shift;
    @_ ? $self->{Protect_Comments} = shift : $self->{Protect_Comments};
}

sub ep3_modules {
# If any modules are specified on the command line, load them dynamically.
    my $self = shift;
    my $module;
    my $filename;
    @{$self->{Modules}} = @_ if (@_) ;
    foreach $module (@{$self->{Modules}}) {
        $filename = $module . ".pm";
        next if $INC{$filename};
        require $filename;
        $module->import();
    }
    @{$self->{Modules}};
}

sub ep3_includes {
    my $self = shift;
    @_ ? @{$self->{Include_Directory}} = @_ : @{$self->{Include_Directory}};
}

sub ep3_defines {
    my $self = shift;
    if (@_) {
        @{$self->{Defines}} = @_;
    }
    my ($define, $directive, $delimeter);
    my ($key, $definition, @string);
    foreach $define (@{$self->{Defines}}) {
        $directive = $self->{Delimeter} . 'define';
        $delimeter = index($define,'=',$[);
        if ($delimeter > $[) {
            $key = substr($define,$[,$delimeter);
            $definition = substr($define,$delimeter + 1);
            @string = join(' ',$directive,$key,$definition);
        }
        else {
            @string = ($directive, $define);
        }
        $self->define(@string);
    }
    @{$self->{Defines}};
}


sub ep3_output_file {
# Set the output files ...
# Both the $Outfile_Handle and the $Text::EP3::Dependfile_Handle
# are set to new filehandles (empty) at the beginning of the routine. The 
# users requested output file is then opened and attached to the appropriate 
# filehandle.
    my $self = shift;
    my $Outfile_Handle;
    my $filehandle;
    my $filename;
    if (@_ ) {
        $filename = $self->{Output_Filename} = shift;
    }
    else {
        $filename = $self->{Output_Filename};
    }
    $Text::EP3::Dependfile_Handle = new FileHandle;
    $Outfile_Handle = new FileHandle;
    $filehandle = new FileHandle;
    if ($filename ne 'STDOUT') {
        open($filehandle, ">$filename") || die "Couldn't open output file $filename: $!";
    }
    else {
        $filehandle = *STDOUT;
    }

    if ($self->{Gen_Depend_List}) { # Just print the dependencies
        $Text::EP3::Dependfile_Handle = $filehandle;
    }
    else { # Normal output
        $Outfile_Handle = $filehandle;
    }
    # Make $Outfile_Handle the default output file
    select $Outfile_Handle;
    $self->{Outfile_Handle} = $Outfile_Handle;
    $filename;
}

1;
