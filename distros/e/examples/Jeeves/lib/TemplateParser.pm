package TemplateParser;
use strict;
#-----------------------------------------------------------------------------
# This package parses a template file in the format explained below, and
# translates it into Perl code. See jeeves for where this package fits
# into the scheme of things.
# The template file recognizes the following directives ...
#   (keywords are case insensitive)
#   @OPENFILE <filename> [options] - closes the previous output file, 
#         the new file. 
#         Options: 
#            -append - open the file in append mode
#            -no_overwrite - do not overwrite the file if it already exists. 
#                  This is useful if you want to generate the file only once.
#            -only_if_different - puts all the output into a temp file, does a 
#                  diff with the given file, and overwrites it if the two 
#                  files differ - useful in a make environment, where you
#                  don't want to unnecessarily touch the file if the contents
#                  are the same, to preserve timestamps
#
#   @PERL <perl code> - Inserts the perl code in the output file untranslated
#   @FOREACH <var> [perl condition code] - iterates thru the array @var, using 
#                  the iterator variable $var_i. The iteration works 
#                  wherever the condition is true.
#
#   @END - terminates the loop
#   @//  - comment line, not reproduced in the intermediate perl file
#   All other lines in the template are left essentially untranslated.
#-----------------------------------------------------------------------------

sub parse {
    # Args : template file, intermediate perl file
    my ($pkg,$template_file, $inter_file) = @_;
    unless (open (T, $template_file)) {
        warn "$template_file : $@";
        return 1;
    }
    open (I, "> $inter_file") || 
        die "Error opening intermediate file $inter_file : $@";
    
    emit_opening_stmts($template_file);
    my $line;
    while (defined($line = <T>)) {
        if ($line !~ /^\s*\@/) { # Is it a command?
            emit_text($line);
            next;
        } 
        if ($line =~ /^\s*\@OPENFILE\s*(.*)\s*$/i) {
            emit_open_file ($1);
        } elsif ($line =~ /^\s*\@FOREACH\s*(\w*)\s*(.*)\s*/i) {
            emit_loop_begin ($1,$2);
        } elsif ($line =~ /^\s*\@END/i) {
            emit_loop_end();
        } elsif ($line =~ /^\s*\@PERL(.*)/i) {
            emit_perl("$1\n");
        };
    }
    emit_closing_stmts();
    
    close(I);
    return 0;
}


# All pieces of output code are within a "here" document terminated 
# by _EOC_
#

#----------------------------------------------------------------------
# emit_opening_stmts
# ==> emit ("Convert ROOT's properties to global variable names")
#
sub emit_opening_stmts {
    my $template_file = shift;
    emit("# Created automatically from $template_file");
    emit(<<'_EOC_');

use Ast;
use JeevesUtil;

$tmp_file = "jeeves.tmp";

sub open_file;
if (! (defined ($ROOT) && $ROOT)) {
    die "ROOT not defined";
}

$file = "> -";
open (F, $file) || die $@;
$code = "";
$ROOT->visit();
_EOC_
}

#------------------------------------------------------------------------
# emit_open_file 
# ==> emit ("Close the previous file, and open the new filename for output
#

sub emit_open_file {
    my $file = shift;
    my $no_overwrite      = ($file =~ s/-no_overwrite//gi) ? 1 : 0;
    my $append            = ($file =~ s/-append//gi) ? 1 : 0;
    my $only_if_different = ($file =~ s/-only_if_different//gi) ? 1 : 0;
    $file =~ s/\s*//g;
    emit (<<"_EOC_");
# Line $.
open_file(\"$file\", $no_overwrite, $only_if_different, $append);
_EOC_
}


#----------------------------------------------------------------------
# emit_loop_begin
# ==> emit ("manufacture an iterator name, and visit each element in 
#            that array")                              
# The best way to understand this code is to execute the schema compiler
# and look at the intermediate perl code.
#

sub emit_loop_begin {
    my $l_name = shift; # Name of the list variable
    my $condition = shift;
    my $l_name_i = $l_name . "_i";
emit (<<"_EOC_");
# Line $.
foreach \$$l_name_i (\@\${$l_name}) {
    \$$l_name_i->visit ();
_EOC_
    if ($condition) {
    emit ("next if (! ($condition));\n");
    }
}

#----------------------------------------------------------------------
sub emit_loop_end {
    emit(<<"_EOC_");
#Line $.
    Ast->bye();
}
_EOC_
}

#----------------------------------------------------------------------
sub emit_perl {
    emit($_[0]);
}

#----------------------------------------------------------------------
sub emit_text {
    chomp $_[0];
    # Escape quotes in the text
    $_[0] =~ s/"/\\"/g;
    $_[0] =~ s/'/\\'/g;
    emit(<<"_EOC_");
output("$_[0]\\n");
_EOC_
}

#----------------------------------------------------------------------
sub emit_closing_stmts {
    emit(<<'_EOC_');
Ast->bye();
close(F);
unlink ($tmp_file);

sub open_file {
    my ($a_file, $a_nooverwrite, $a_only_if_different, $a_append) = @_;

    #First deal with the file previously opened
    close (F);
    if ($only_if_different) {
        if (JeevesUtil::compare ($orig_file, $curr_file) != 0) {
            rename ($curr_file, $orig_file) || 
            die "Error renaming $curr_file  to $orig_file";
        }
    }

    #Now for the new file ...
    $curr_file = $orig_file = $a_file;
    $only_if_different = ($a_only_if_different && (-f $curr_file)) ? 1 : 0;
    $no_overwrite = ($a_nooverwrite && (-f $curr_file))  ? 1 : 0;
    $mode =  ($a_append) ? ">>" : ">";

    if ($only_if_different) {
        unlink ($tmp_file);
        $curr_file = $tmp_file;
    }

    if (! $no_overwrite) {
        open (F, "$mode $curr_file") || die "could not open $curr_file";
    }
}

sub output {
    print F @_ if (! $no_overwrite) 
}
1;
_EOC_
}

#----------------------------------------------------------------------
sub emit {
    print I $_[0];
}

1; # returns 1 if successfully compiled












