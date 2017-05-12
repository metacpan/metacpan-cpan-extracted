package Text::BibTeX::BibStyle;

=head1 NAME

Text::BibTeX::BibStyle - Format Text::BibTeX::Entry items using .bst

=cut

our $VERSION = '0.03';

=head1 DESCRIPTION

C<Text::BibTeX::BibStyle> is a module that can format
C<Text::BibTeX::Entry> objects by interpreting a bibstyle (C<.bst>) file
such as C<ieeetr.bst>.  In this way, Perl can use the same
bibliographic style files that bibtex does.

For a large collection of C<.bst> files, see
http://www.math.utah.edu/pub/tex/bibtex/index.html.

=head1 SYNOPSIS

  $bibstyle = Text::BibTeX::BibStyle->new(%options);

  $ENV{BSTINPUTS} = "my/bstfiles/";
  $bibstyle->read_bibstyle("bibstyle");
       OR
  $bibstyle->replace_bibstyle($bibstyle_def);

  $ENV{BIBINPUTS} = "my/bibfiles/";
  $bibstyle->execute([qw(bibfile1 bibfile2)]);
       OR
  $bibstyle->execute([qw(bibfile1 bibfile2)], \@ref_list);

  @warnings = $bibstyle->warnings;

  $output = $bibstyle->get_output();
  $output = $bibstyle->convert_format(Text::BibTex::BibStyle::html);
       OR
  $output = $bibstyle->get_output(\%options);

=cut

use strict;
use warnings;

use vars qw(@ISA @EXPORT_OK $LATEX $HTML $RST);

use Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw($HTML $LATEX $RST);

use Carp;
use Text::BibTeX qw(:metatypes :subs :joinmethods :macrosubs);
use Text::BibTeX::Name;

=head1 METHODS

=over

=item C<new [(%options])>

Class method.  Creates a new C<Text::BibTeX::BibStyle> object with the
options specified in the optional C<option=>'value'> arguments.The
following options are understood:

=over

=item C<debug>

Turns on debugging messages during execute.

=item C<nowarn>

Turns off warnings from certain sanity checks, such as the existence
of a unique C<ENTRIES> and C<READ> statement within the bibstyle.

=back

=cut

# Exportable output options
$LATEX = { wrap => 1 };
{				# Closure
my $ASCIIMathML_parser;
my %Styles = (em => 'em',
	      bf => 'b',
	      it => 'i',
	      sl => 'i',
	      tt => 'tt');

$HTML  = {
    delete_braces => 1,
    substitute_newcommand => 1,
    character => sub {
	my ($bst, $latex, $unicode, $chars, $accent) = @_;
	use HTML::Entities;
	return $unicode ? encode_entities($unicode) : $chars;
    },
    command => sub {
	my ($bst, $cmd, @args) = @_;
	if ($cmd =~ /^(begin|end)$/) {
	    if ($args[0] eq 'thebibliography') {
		my $slash = $cmd eq 'end' ? '/' : '';
		my $pre;
		if ($cmd eq 'begin') {
		    $pre = qq(<h2>References</h2>\n\n);
		}
		else {
		    $pre = "</td>";
		}
		return "$pre<${slash}table>";
	    }
	}
	elsif ($cmd eq 'bibitem') {
	    my $key = pop @args;
	    $bst->{html}{Bib_count}++;
	    my $label = $args[0] || $bst->{html}{Bib_count};
	    ($bst->{html}{Cites}{$key} = $label) =~ s/[{}]//g; # Remove braces
	    my $pre = $bst->{html}{Bib_count} > 1 ? "</td>\n" : '';
	    return qq($pre<tr valign="top"><td><a name="$key">[$label]</a></td><td>);
	}
	elsif ($cmd eq 'mbox') {
	    return $args[0];
	}
	elsif ($cmd eq 'cite') {
	    return qq(<a href="#$args[0]"><cite>$args[0]</cite></a>);
	}
    },
    init => sub {
	my ($bst) = @_;
	# Initialize instance variables
	$bst->{html} = { Bib_count => 0, Cites => {} };
    },
    math => sub {
	my ($bst, $latex, $math) = @_;
	use Text::ASCIIMathML;
	$ASCIIMathML_parser = Text::ASCIIMathML->new()
	    unless $ASCIIMathML_parser;
	return $ASCIIMathML_parser->TextToMathML($math);
    },
    postprocess => sub {
	my ($bst, $text) = @_;

	# Substitute back any cite tags
	$text =~ s!<cite>(.*?)</cite>![$bst->{html}{Cites}{$1}]!g;
	return $text;
    },
    style => sub {
	my ($bst, $latex, $style, $text) = @_;
	my $html_style = $Styles{$style};
	return defined $html_style ? "<$html_style>$text</$html_style>" :
	    $text;
    },
};
}
{				# Closure
my %Styles = (em => '*',
	      bf => '**',
	      it => '*',
	      sl => '*',
	      tt => '``');

$RST  = {
    delete_braces => 1,
    substitute_newcommand => 1,
#    prologue => "",
    character => sub {
	my ($bst, $latex, $unicode, $chars, $accent) = @_;
	return $chars if ! $unicode;
	my $code = ord $unicode;
	$bst->{rst}{unicode}{$code} = 1;
	return sprintf '\\ |unicode(%x)|\\ ', $code;
    },
    command => sub {
	my ($bst, $cmd, @args) = @_;
	if ($cmd =~ /^(begin|end)$/) {
	    if ($args[0] eq 'thebibliography') {
		if ($cmd eq 'begin') {
		    return qq(**References**\n\n\n);
		}
	    }
	}
	elsif ($cmd eq 'bibitem') {
	    my $key = pop @args;
	    $bst->{rst}{Bib_count}++;
	    my $label = $args[0] || $bst->{rst}{Bib_count};
	    if ($args[0]) {
		my $bst2 = Text::BibTeX::BibStyle->new;
		$label = $bst2->convert_format($label, $RST);
	    }
	    $bst->{rst}{Cites}{$key} = $label;
	    return ".. [$key] ";
	}
	elsif ($cmd eq 'mbox') {
	    return $args[0];
	}
	elsif ($cmd eq 'cite') {
	    return "\\ [$args[0]]_";
	}
    },
    init => sub {
	my ($bst) = @_;
	# Initialize instance variables
	$bst->{rst} = { Bib_count => 0, Cites => {}, unicode => {} };
    },
    math => sub {
	my ($bst, $latex, $math) = @_;
	# Latex sometimes starts with ^ or _ for super/subscript
	$math =~ s/^([_^])/{::}$1/;
	$math =~ s/([{}])/\\$1/g;
	$math =~ s/\\/\\\\/g;
	return "\\ :mathml:`$math`\\ ";
    },
    postprocess => sub {
	my ($bst, $text) = @_;

	# Fix the indentations
	$text =~ s/^[ ]*$//mg;
	$text =~ s/^(?!\A|\.\.|\*\*)[ ]*(.+)/   $1/mg;
	$text =~ s/\\([\\{}])/$1/g;
	foreach my $code (sort keys %{$bst->{rst}{unicode}}) {
	    $text .= sprintf ".. |unicode(%x)| unicode:: U+%x\n", $code, $code;
	}
	return $text;
    },
    style => sub {
	my ($bst, $latex, $style, $text) = @_;
	my $rst_style = $Styles{$style};
	if ($rst_style) {
	    my ($pre, undef, $post) = $text =~ s/^(\s.)(.*?)(\s.)$/$2/;
	    $post ||= '';
	    return "$pre$rst_style$text$rst_style$post" ;
	}
	return $text;
    },
};
}
sub new {
    my ($class, %options) = @_;

    my $self = bless {}, $class;

    $self->{options} = \%options;

    return $self;
}

# A Text::BibTeX::BibStyle hash has the following keys:
#   bibtex      A reference to a "bibtex" hash
#   interp      Array reference containing the interpreter
#   stack       Reference to array of evaluation stack
#   symbols     Reference to "symbols" hash
#   warnings    Array of warnings produced during execution
#
# "Symbols" hash has the following keys, each of which is a hash reference
# whose key is the symbol name and whose value is its definition:
#   const       Built-in constants
#   field       Reference to hash of field/value pairs for current entry
#   entry_int   Reference to hash of integer/value pairs for current entry
#   entry_str   Reference to hash of string/value pairs for current entry
#   function    Function defined in FUNCTION command or built-in function
#   integer     Integer defined in INTEGERS command
#   string      String defined in STRINGS command
#
# "Bibtex" hash has the following key/value pairs
#   bibfiles    Reference to array of bib file names
#   bt_entry    Reference to the current Text::BibTeX::Entry object
#   bt_entries  Reference to hash whose keys are bibtex keys and whose value
#               is the corresponding Text::BibTeX::Entry for that key
#   cite        Cite key for the current entry
#   cites       Optional reference to array of keys of citations to format
#   entries     Reference to hash whose keys are bibtex keys and whose value
#               is a reference to its entry hash
#   format      Reference to a format hash defined by an ENTRY command
#   preamble    Reference to array of @PREAMBLE items
#
# "Entry" hash has the following keys, each of which is a hash reference
# whose key is the symbol name and whose value is its definition:
#   field       Bibliography field from ENTRY command
#   integer     Entry integer from ENTRY command
#   string      Entry string from ENTRY command
#
# "Format" hash has the following keys, each of which is a reference to
# an array of names that can appear in a corresponding entry hash
#   field       Bibliography fields from ENTRY command
#   integer     Entry integer variables from ENTRY command
#   string      Entry string variables from ENTRY command

=item C<convert_format ($text, \%options)>

Method. Converts a LaTeX bibliography in $text into some other format
using the options specified by C<%options> and returns the result.
This method can also be used to convert a standard BibTeX output to
a different format.

Assuming that C<$text> contains a LaTeX bibliography (e.g., the
contents of a C<.bbl> file), the following option packages may be
useful for the options hash reference:

=over

=item C<$Text::BibTeX::BibStyle::HTML>

Produces HTML code to render the formatted bibliography. Exportable.

=item C<$Text::BibTeX::BibStyle::LATEX>

Outputs LaTeX code identical to bibtex (specifies (wrap => 1)).  Exportable.

=item C<$Text::BibTeX::BibStyle::RST>

Produces reStructuredText code.  Exportable.

=back

The following options are supported, if you want to write your own
translation package:

=over

=item C<character>

Reference to a subroutine to call for special characters.  The
subroutine is called with the arguments C<($bst, $latex, [$unicode],
$char, [$accent])>, where C<$bst> is the Text::BibTeX::BibStyle
object, C<$latex> is the original latex for the special character,
C<$unicode> is the equivalent unicode character (if it exists), $char
is the special character(s), and C<$accent> is the latex accent code
to be applied (if specified).  It should return the string to be
substituted.

=item C<command>

Reference to a subroutine to call for LaTeX commands.  The subroutine
is called with the arguments C<($bst, $cmd, @args)>, where C<$bst> is
the Text::BibTeX::BibStyle object, C<$cmd> is the name of the LaTeX
command and C<@args> is the array of arguments (including optional
arguments) to the command.  At a minimum, the subroutine should handle
the following commands: C<\begin{thebibliography}>,
C<\bibitem[label]{key}>, C<\cite{ref}>, C<\end{thebibliography}>,
C<\mbox{text}>, C<\newblock>. It should return the string to be
substituted.

=item C<delete_braces>

Boolean to delete from the output any braces that are not
backslash-quoted.

=item C<init>

Reference to a subroutine to call before processing the output.  The
subroutine is called with the argument C<($bst)>, which is the
Text::BibTeX::BibStyle object.

=item C<math>

Reference to a subroutine to call for latex math.  The subroutine is
called with the arguments C<($bst, $latex, $math)>, where C<$bst> is
the Text::BibTeX::BibStyle object, C<$latex> is the original latex and
C<$math> is the part that actually translates to math.  It should
return the string to be substituted.

=item C<postprocess>

Reference to a subroutine to call to post-process the output.  The
subroutine is called with the arguments C<($bst, $text)>, where
C<$bst> is the Text::BibTeX::BibStyle object and C<$text> contains the
text of the entire formatted bibliography.  It should return the final
formatted bibliography.

=item C<prologue>

A string or reference to a subroutine to call to produce any
pre-bibliography definitions needed by the format.

=item C<style>

Reference to a subroutine to call for different font styles.  The
subroutine is called with the arguments C<($bst, $latex, $style,
$text)>, where C<$bst> is the Text::BibTeX::BibStyle object, C<$latex>
is the original latex, C<$style> is one of C<rm>, C<em>, C<bf>, C<it>,
C<sl>, C<sf>, C<sc>, or C<tt> indicating the font style, and C<$text>
is the text to be output in that style.  It should return the string
to be substituted.

=item C<substitute_newcommand>

Boolean to process and do substitutions for any C<\newcommand>
definitions in the output.

=item C<wrap>

Boolean to force the standard bibtex wrapping on the output.

=back

=cut

{				# Closure
my $Acc_char = qq([\'\`^\"~=.]);
my $Acc_let  = "[uvHtcdb]";
my $Acc_sym  = q(\\\\(?:(?:a[ae]|A[AE]|copyright|dd?ag|[lL]|oe?|OE?|P|pounds|S|ss)\\b)|``|''|\?`|!`|~|---?);
my $Style    = '\\\\(?:[er]m|bf|[it]t|s[lfc])\\b';

sub convert_format : method {
    my ($self, $text, $opts) = @_;

    $opts->{init}->($self) if $opts->{init};
    $text = _substitute_newcommand($text) if $opts->{substitute_newcommand};
    if ($opts->{wrap}) {
	1 while ($text =~ s/^(?=.{80})(.{1,79})(\s.*)/$1\n $2/m ||
		 $text =~ s/^(?=.{80})(.{80,}?)(\s.*)/$1\n $2/m);
    }
    if ($opts->{prologue}) {
	my $prologue = ref $opts->{prologue} ? $opts->{prologue}->($self) :
	    $opts->{prologue};
	$text = "$prologue$text";
    }
    if ($opts->{character}) {
	# Handle accents
	$text =~ s/\\i\b/i/g;
	$text =~ s/(\{ \\ ($Acc_char|$Acc_let\b) [ ]* ([a-zA-Z]+) [ ]*
	    (?:\}|\Z))/_character($self, $opts, $1, $3, $2)/exog;
	$text =~ s/(\\ ($Acc_char|$Acc_let) [ ]* \{ [ ]* ([a-zA-Z]+) [ ]*
	    (?:\}|\Z))/_character($self, $opts, $1, $3, $2)/exog;
	$text =~ s/($Acc_sym)/_character($self, $opts, $1, $1)/exog;
	$text =~ s/(\\ ([\#\$\%&_]))/_character($self, $opts, $1, $2)/xge;
	$text =~ s!(\\/)!_character($self, $opts, $1, '')!ge;
    }
    if ($opts->{math}) {
	# Handle math mode
	$text =~ s/((\$\$?)(.*?)\2)/$opts->{math}->($self, $1, $3)/sexg;
	$text =~ s/(\\ \( (.*?) \\ \))/$opts->{math}->($self, $1, $2)/sexg;
	$text =~ s/(\\ \[ (.*?) \\ \])/$opts->{math}->($self, $1, $2)/sexg;
    }
    if ($opts->{style}) {
	# Handle text styles
	1 while $text =~ s/(\{ $Style .*)/do {
	    my ($latex, $next) = _remove_matched_brace($1);
	    (my $text = $latex) =~ s!\{ ($Style) [ ]*(.*) \}$!$2!sx;
	    my $style = $1;
	    $style =~ m!([a-z]+)!;
	    $opts->{style}->($self, $latex, $1, $text) . $next;
	}/sexg;
    }
    if ($opts->{command}) {
	1 while $text =~ s/(\A|[^\\])\\([a-z]+)(.*)/do {
	    my ($pre, $cmd, $next) = ($1, $2, $3);
	    my @args;
	    while ($next =~ m!^[\{\[]!) {
		if ($next =~ m!^\{!) {
		    my $arg;
		    ($arg, $next) = _remove_matched_brace($next);
		    $arg =~ s!^\{ (.*) \}$!$1!sx;
		    push @args, $arg;
		}
		else {
		    $next =~ s!^\[ (.*?) \]!!sx;
		    push @args, $1;
		}
	    }
	    $pre . $opts->{command}->($self, $cmd, @args) . $next;
	}/exis;
    }
    if ($opts->{delete_braces}) {
	# Note: need to do twice to handle {}
	$text =~ s/(\A|.) ([{}])/$1 eq "\\" ? "$1$2" : $1/sexg;
	$text =~ s/(\A|.) ([{}])/$1 eq "\\" ? "$1$2" : $1/sexg;
    }
    if ($opts->{character}) {
	# Handle backslash-quoted braces
	$text =~ s/(\\ ([{}]))/_character($self, $opts, $1, $2)/xge;
    }
    $text = $opts->{postprocess}->($self, $text) if $opts->{postprocess};

    return $text;
}

=item C<execute [(\@bibfiles[, \@cites])]>

Method. Executes the current bibstyle interpreter on a set of cited
references passed in C<@cites> looking in a set of C<.bib> files
passed in C<@bibfiles>.  If the C<@cites> argument is undefined, uses
all the references in all the bibfiles.  The files in C<@bibfiles>
should be without the ".bib" extension.  The search path for bibfiles
is taken from the C<BIBINPUTS> environment variables if it is defined.
The C<@bibfiles> argument is not needed if the bibstyle interpreter
does not contain a C<READ> command.  Croaks if a bibstyle interpreter
has not been defined using either the C<read_bibstyle> or
C<replace_bibstyle> method.

=cut

{
# Closure for local variables
my %Commands = ( # Info is no. of arguments and subroutine reference
    entry    => [3, \&_command_entry],
    execute  => [1, \&_command_execute],
    function => [2, \&_command_function],
    integers => [1, \&_command_variables],
    iterate  => [1, \&_command_iterate],
    macro    => [2, \&_command_macro],
    read     => [0, \&_command_read],
    reverse  => [1, \&_command_iterate],
    sort     => [0, \&_command_sort],
    strings  => [1, \&_command_variables],
);

sub execute : method {
    my ($self, $bibfiles_ar, $cites_ar) = @_;

    croak "No bibstyle interpreter has been defined: call read_bibstyle or replace_bibstyle first"
	unless $self->{interp};

    $self->{bibtex} = {
	bibfiles   => $bibfiles_ar,
	bt_entry   => undef,
	bt_entries => { },
	cite       => undef,
	cites      => $cites_ar,
	entries    => { },
	format     => undef,
	preamble   => [ ],
	};
			 
    Text::BibTeX::delete_all_macros();
    my %cmd_count;
    my ($filename, $lineno);
    my @interp = @{$self->{interp}};
    while (@interp) {
	my $token = shift @interp;
	if ($token =~ /^\#line (\d+) (\S+)/) {
	    ($lineno, $filename) = ($1, $2);
	    next;
	}
	croak "$filename, $lineno: Invalid argument" if ref($token);
	my $lc_token = lc $token;
	croak "$filename, $lineno: Unknown command '$token'"
	    unless my $command_ar = $Commands{$lc_token};

	my ($cmd, $cmd_f, $cmd_l) = ($token, $filename, $lineno);
	$self->{lineno} = "$filename, $lineno";
	# Get the arguments
	my @args;
	while (@args < $command_ar->[0]) {
	    my $token = shift @interp;
	    if ($token =~ /^\#line (\d+) (\S+)/) {
		($lineno, $filename) = ($1, $2);
		next;
	    }
	    last unless ref($token);
	    push @args, $token;
	}
	croak "$filename, $lineno: Insufficient arguments for command '$cmd' at line $cmd_l"
	    if @args < $command_ar->[0];
	if (++$cmd_count{$lc_token} > 1 && $lc_token =~ /^(entry|read)$/)
	{
	    $self->_warning("Duplicate '$token' command ignored");
	    next;
	}
	$command_ar->[1]->($self, $cmd, $cmd_f, $cmd_l, \@args);
    }
    my @missing_cmds = grep !$cmd_count{$_}, qw(entry read);
    $self->_warning(sprintf("Need to have one %s command",
			    join ' and one ', map(uc $_, @missing_cmds)))
	if @missing_cmds && ! $self->{options}{nowarn};
}
}

=item C<get_output [(\%options)]>

Method.  Returns the output produced by C<write$> commands in the C<.bst>
file.  The options are listed under the C<convert_format> method,
which it calls.

=cut

sub get_output : method {
    my ($self, $opts) = @_;

    my $out = join '', @{$self->{output}};
    $out = $self->convert_format($out, $opts) if $opts;

    return $out;
}

=item C<num_warnings>

Method.  Returns the number of warning messages generated during execution.

=cut

sub num_warnings : method {
    my ($self) = @_;

    return 0+@{$self->{warnings}};
}



=item C<read_bibstyle ($bibstyle)>

Method.  Replaces the bibstyle interpreter with a new one obtained by
reading the file C<$bibstyle.bst>.  The search path for the bibstyle
file is taken from the C<BSTINPUTS> environment variable if it is
defined.

=cut

sub read_bibstyle : method {
    my ($self, $bibstyle) = @_;

    my $f = "$bibstyle.bst";
    my $path = $ENV{BSTINPUTS} || '.';
    my @path = split /:/, $path;
    my ($dir) = grep -f "$_/$f", @path;
    croak("Cannot find $f on path: $path") unless $dir;
    my $fullfile = "$dir/$f";

    # Read the file
    open BSTINPUTS, "$fullfile" or croak("$fullfile: $!");
    my @bibstyle = <BSTINPUTS>;
    close BSTINPUTS;

    my $interp = join '', @bibstyle;
    $self->replace_bibstyle($interp, $fullfile);
}

=item C<replace_bibstyle ($string[, $filename])>

Method. Replaces the bibstyle interpreter by parsing C<$string>.  The
optional C<$filename> argument is used for warning messages.  Written
primarily for testing purposes; most users will call it only
indirectly through the C<read_bibstyle> method.

=cut

{	# Closure for private variables
my %BuiltIn =
    (
     '>'            => \&_function_arith,
     '<'            => \&_function_arith,
     '='            => \&_function_eq,
     '+'            => \&_function_arith,
     '-'            => \&_function_arith,
     '*'            => \&_function_concat,
     ':='           => \&_function_assign,
     'add.period$'  => \&_function_add_period,
     'call.type$'   => \&_function_call_type,
     'change.case$' => \&_function_change_case,
     'chr.to.int$'  => \&_function_chr_to_int,
     'cite$'        => \&_function_cite,
     'duplicate$'   => \&_function_duplicate,
     'empty$'       => \&_function_empty,
     'format.name$' => \&_function_format_name,
     'if$'          => \&_function_if,
     'int.to.chr$'  => \&_function_int_to_chr,
     'int.to.str$'  => \&_function_int_to_str,
     'missing$'     => \&_function_missing,
     'newline$'     => \&_function_newline,
     'num.names$'   => \&_function_num_names,
     'pop$'         => sub { my ($self) = @_; $self->_pop; },
     'preamble$'    => \&_function_preamble,
     'purify$'      => \&_function_purify,
     'quote$'       => 1, # Handled as a constant symbol
     'skip$'        => sub {},
     'stack$'       => \&_function_stack,
     'substring$'   => \&_function_substring,
     'swap$'        => \&_function_swap,
     'text.length$' => \&_function_text_length,
     'text.prefix$' => \&_function_text_prefix,
     'top$'         => \&_function_top,
     'type$'        => \&_function_type,
     'warning$'     => \&_function_warning,
     'while$'       => \&_function_while,
     'width$'       => \&_function_width,
     'write$'       => \&_function_write,
     );

# Here's where the actual parsing takes place
sub replace_bibstyle : method {
    my ($self, $interp, $filename) = @_;

    $filename ||= '<string>';
    # Remove comments
    $interp =~ s/(^|[^\\]) \% .*/$1/mgx ;
    my @interp = grep $_, split(/(\s+)|([{}]|\".*?\"|\#line \d+ .*\n)/, $interp);
    # Put '{' .. '}' pairs into array refs
    my @stack;
    my $nest = 0;
    push @stack, [];
    my $lineno = 1;
    push @{$stack[-1]}, "#line $lineno $filename";
    foreach (@interp) {
	if ($_ =~ /^\s+$/) {
	    my $nl = y/\n//;
	    if ($nl) {
		$lineno += $nl;
		push @{$stack[-1]}, "#line $lineno $filename";
	    }
	}
	elsif ($_ eq '{') {
	    $nest++;
	    push @stack, [];
	    push @{$stack[-1]}, "#line $lineno $filename";
	}
	elsif ($_ eq '}') {
	    $nest--;
	    croak("$filename, $lineno: Unmatched '}'") if $nest < 0;
	    push @{$stack[-2]}, pop(@stack);
	}
	else {
	    ($lineno, $filename) = ($1, $2) if /^\#line (\d+) (.*)/;
	    push @{$stack[-1]}, $_;
	}
    }
    if ($nest > 0) {
	# Find the error line number
	my $errline = 1;
	foreach (reverse @{$stack[$nest-1]}) {
	    if (/^\#line (\d+)/) {
		$errline = $1;
		last;
	    }
	}
	croak("$filename, $errline: Unmatched '{'");
    }

    $self->{interp}  = $stack[0];
    $self->{output}  = [];
    $self->{stack}   = [];
    $self->{symbols} = {
	const     => { 'quote$'   => '"""' },
	entry_str => { 'sort.key$' =>  undef },
	field     => { crossref    => undef },
	function  => {
	    map(($_ => "'$_"), keys %BuiltIn)
	},
	integer   => {
	    'entry.max$'  => 100,
	    'global.max$' => 1000,
	},
    };
    $self->{warnings} = [];
}

=item C<warnings>

Method. Returns an array of the warning messages generated during execution.

=cut

sub warnings : method {
    my ($self) = @_;

    return @{$self->{warnings}};
}

=back

=head1 ENVIRONMENT

The following environment variables are used:

=over

=item C<BIBINPUTS>

The search path for bibliography (.bib) files.

=item C<BSTINPUTS>

The search path for bibstyle (.bst) files.

=back

=head1 LIMITATIONS

The $Text::BibTeX::BibStyle::HTML output filter has the following
limitations:

=over

=item Math mode

The math mode interpretation depends upon using Text::ASCIIMathML to
convert to MathML.  ASCIIMathML accepts most, but not all, LaTeX
constructs.  In order to render correctly in some browsers, it will
need to use xhtml and put the appropriate MathML entity definitions in
the header.

=item latex2e symbols

Extended symbols defined by latex2e are not supported.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Mark Nodine, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

################ Internal routines

# Checks a name to be define to be sure it is valid
# Arguments: name
# Returns:   name
sub _check_name : method {
    my ($self, $name) = @_;

    my $where = $self->{lineno};
    croak "$where: Illegal name '$name'"
	unless $name =~ /^[^\"\#\%\'(),={}\s\d][^\"\#\%\'(),={}\s]*$/;
    
    foreach my $sym (qw(const field entry_int entry_str function
			integer string)) {
	croak "$where: Cannot redefine $sym '$name'"
	    if exists $self->{symbols}{$sym}{$name};
    }

    return $name;
}

{				# Closure for static variables
my $Arg_num;
my $Check_type_warnings;

# Checks the type of an argument
# Arguments: argument, type(s), token, true if first arg of function
# The types are a concatenation of
#   i: integer
#   q: quoted value (e.g., 'a)
#   s: string
#   x: expression (array ref)
sub _check_type : method {
    my ($self, $arg, $types, $token, $first_arg) = @_;

    $Arg_num = $first_arg ? 1 : $Arg_num + 1;
    $Check_type_warnings = 0 if $first_arg;
    $_ = $arg;
    my $type = (! defined $_  || /^\"/? 's' :
		ref($_)               ? 'x' :
		/^\'/                 ? 'q' :
		/^-?\d+$/             ? 'i' :
		croak("$self->{lineno}: value '$_' has unknown type"));
    $Check_type_warnings += $self->_warning
	(sprintf "Argument $Arg_num of '$token' has wrong type (%s)",
	 $self->_format_token($_))
	unless $types =~ /$type/i;
}

# Returns the number of check_type warnings for this function
sub _check_type_warnings {
    return $Check_type_warnings;
}
}

# All the _command routines are used to execute a command.
# Inputs: $self, command name, file name, line num, ref to array of arguments
sub _command_entry {
    my ($self, $cmd, $filename, $lineno, $args_ar) = @_;

    $self->{bibtex}{format} = {
	field   => ['crossref',
		    map($self->_check_name($_),
			grep ! /^\#line/, @{$args_ar->[0]})],
	integer => [map($self->_check_name($_),
			grep ! /^\#line/, @{$args_ar->[1]})],
	string  => ['sort.key$',
		    map($self->_check_name($_),
			grep ! /^\#line/, @{$args_ar->[2]})]
	};

    $self->{symbols}{field} =
    { map(($_=>undef), @{$self->{bibtex}{format}{field}}) };
    $self->{symbols}{entry_int} =
    { map(($_=>"-0"), @{$self->{bibtex}{format}{integer}}) };
    $self->{symbols}{entry_str} =
    { map(($_=>undef), @{$self->{bibtex}{format}{string}}) };
	
    1;
}

sub _command_execute {
    my ($self, $cmd, $filename, $lineno, $args_ar) = @_;

    my @symbols = grep ! /^\#line/, @{$args_ar->[0]};
    croak "$filename, $lineno: first argument to '$cmd' must contain exactly one name"
	unless @symbols == 1;
    my $func_name = $symbols[0];
    my $function  = $self->{symbols}{function}{$func_name};
    croak "$filename, $lineno: Function '$func_name' has not been defined"
	unless $function;
    $self->{stack} = [];	# Start with a new stack
    _evaluate ($self, $function);
}

sub _command_function {
    my ($self, $cmd, $filename, $lineno, $args_ar) = @_;

    my @symbols = grep ! /^\#line/, @{$args_ar->[0]};
    croak "$filename, $lineno: first argument to '$cmd' must contain exactly one name"
	unless @symbols == 1;
    my $func_name = $symbols[0];
    $self->_check_name($func_name);
    $self->{symbols}{function}{$func_name} = $args_ar->[1];
}

sub _command_iterate {
    my ($self, $cmd, $filename, $lineno, $args_ar) = @_;

    my @entries = @{$self->{bibtex}{cites}};
    @entries = reverse @entries if $cmd =~ /reverse/i;
    
    my @symbols = grep ! /^\#line/, @{$args_ar->[0]};
    croak "$filename, $lineno: first argument to '$cmd' must contain exactly one name"
	unless @symbols == 1;
    my $func_name = $symbols[0];
    my $function  = $self->{symbols}{function}{$func_name};
    croak "$filename, $lineno: Function '$func_name' has not been defined"
	unless $function;
    foreach my $cite (@entries) {
	$self->{stack} = [];	# Start with a new stack

	# Initialize the cite, bt_entry, and entry references
	$self->{bibtex}{cite}       = $cite;
	$self->{bibtex}{bt_entry}   = $self->{bibtex}{bt_entries}{$cite};
	my $entry                   = $self->{bibtex}{entries}{$cite};
	$self->{symbols}{field}     = $entry->{field};
	$self->{symbols}{entry_int} = $entry->{integer};
	$self->{symbols}{entry_str} = $entry->{string};
	_evaluate ($self, $function);
    }
}

sub _command_macro {
    my ($self, $cmd, $filename, $lineno, $args_ar) = @_;

    my @symbols = grep ! /^\#line/, @{$args_ar->[0]};
    croak "$filename, $lineno: first argument to '$cmd' must contain exactly one name"
	unless @symbols == 1;
    my @defs = grep ! /^\#line/, @{$args_ar->[1]};
    croak "$filename, $lineno: second argument to '$cmd' must contain exactly one string"
	unless @defs == 1 && $defs[0] =~ /^\"(.*)\"$/s;
    my $macro = $symbols[0];
    Text::BibTeX::add_macro_text($macro, _trim_string($defs[0]),
				 $filename, $lineno);
    
#    $self->_check_name($macro);
#    $self->{symbols}{macro}{$macro} = $1;
}

sub _command_read {
    my ($self, $cmd, $filename, $lineno, $args_ar) = @_;

    croak "$self->{lineno}: I found no bib files"
	unless $self->{bibtex}{bibfiles} && @{$self->{bibtex}{bibfiles}};

    my %cited;
    my @cites;

    my $cite_all = !$self->{bibtex}{cites};
    $self->{bibtex}{cites} ||= [];

    my %cites;			# The refs we want if not $cite_all
    $cites{$_} = 1 foreach @{$self->{bibtex}{cites}};

    # First read the bibtex files and get entries for each reference
    foreach my $filename (@{$self->{bibtex}{bibfiles}}) {
	my $f = "$filename.bib";
	my $path = $ENV{BIBINPUTS} || '.';
	my @path = split /:/, $path;
	my ($dir) = grep -f "$_/$f", @path;
	die "Cannot find $f on path: $path" unless $dir;
	my $dirfile = "$dir/$f";
	my $bibfile = Text::BibTeX::File->new($dirfile)
	    or die "$dirfile: $!\n";
	while (my $bt_entry = new Text::BibTeX::Entry $bibfile)
	{
	    next unless $bt_entry->parse_ok;
	    my $metatype = $bt_entry->metatype;
	    if ($metatype == BTE_REGULAR) {
		# Skip entries that we don't want
		my $key = $bt_entry->key;
		next unless $cites{$key} || $cite_all;
		push @cites, $key if $cite_all && ! $cited{$key}++;
		$self->{bibtex}{bt_entries}{$key} = $bt_entry;
		# Create an entry hash for this entry
		my $entry = { };
		$entry->{field}{$_} =
		    $bt_entry->exists($_) ? ('"' . $bt_entry->get($_) . '"') :
		    undef
		    foreach @{$self->{bibtex}{format}{field}};
		$entry->{field}{crossref} =
			    lc $entry->{field}{crossref}
		if defined $entry->{field}{crossref};
		$entry->{integer}{$_} = "-0" # 0?
		    foreach @{$self->{bibtex}{format}{integer}};
		$entry->{string}{$_} = undef
		    foreach @{$self->{bibtex}{format}{string}};
		$self->{bibtex}{entries}{$key} = $entry;
	    }
	    elsif ($metatype == BTE_PREAMBLE) {
		push @{$self->{bibtex}{preamble}}, $bt_entry->value;
	    }
	    elsif ($metatype == BTE_MACRODEF) {
		# These are handled internally by Text::BibTeX
	    }
	}
    }

    $self->{bibtex}{cites} = \@cites if $cite_all;
    croak "$self->{lineno} I found no citations"
	unless @{$self->{bibtex}{cites}};
}

sub _command_sort {
    my ($self, $cmd, $filename, $lineno, $args_ar) = @_;

    @{$self->{bibtex}{cites}} =
	sort { $self->{bibtex}{entries}{$a}{string}{'sort.key$'} cmp
	       $self->{bibtex}{entries}{$b}{string}{'sort.key$'} }
    @{$self->{bibtex}{cites}};
#    croak "$filename, $lineno: Command '$cmd' not implemented yet";
}

sub _command_variables {
    my ($self, $cmd, $filename, $lineno, $args_ar) = @_;

    my $init = $cmd =~ /integers/i ? "-0" : undef;
    $cmd =~ s/(.*)s/\L$1/i;
    $self->{symbols}{$cmd}{$_} = $init
	foreach map($self->_check_name($_),
		    grep ! /^\#line/, @{$args_ar->[0]});
}

{				# Static variables
my %In_function;

# Evaluates a function
# Arguments: $self, function definition
sub _evaluate {
    my ($self, $function_ar) = @_;

    $function_ar =~ s/^\'//;
    $function_ar = [ $function_ar ] unless ref $function_ar;
    local ($self->{lineno}) = $self->{lineno};
    my $old_warnings = $self->num_warnings;
  token:
    foreach my $token (@{$function_ar}) {
	if ($token =~ /^\#line (\d+) (.*)/) {
	    my ($lineno, $filename) = ($1, $2);
	    $self->{lineno} = "$filename, $lineno";
	    next token;
	}
	printf STDERR "$self->{lineno}: {%s} %s\n",
	join(' ', map($self->_format_token($_), @{$self->{stack}})),
	$self->_format_token($token)
	    if $self->{options}{debug};
	if (ref $token) {
	    $self->_push($token);
	    next token;
	}
	if ($token =~ /^\#(-?\d+)/ || $token =~ /^(\'.*)/ ||
	    $token =~ /^(\".*\")/) {
	    $self->_push($1);
	    next token;
	}
	# Check for constants and variables
	foreach my $sym (qw(const entry_int entry_str integer string)) {
	    if (exists $self->{symbols}{$sym}{$token}) {
		$self->_push($self->{symbols}{$sym}{$token});
		next token;
	    }
	}
	# Check for fields
	if (exists $self->{symbols}{field}{$token}) {
	    my $val = $self->{symbols}{field}{$token};
	    # Supply crossreferenced fields if applicable
	    if (! defined $val && $self->{bibtex}{bt_entry} &&
		(my $xref = $self->{bibtex}{bt_entry}->get('crossref'))) {
		my $bt_xref = $self->{bibtex}{bt_entries}{lc $xref};
		if ($bt_xref) {
		    $val = $bt_xref->exists($token) ?
			('"' . $bt_xref->get($token) . '"') : undef;
		}
		else {
		    $self->_warning("Unknown cross reference: $xref");
		}
	    }
	    $self->_push($val);
	    next token;
	}
	if ($BuiltIn{$token}) {
	    $BuiltIn{$token}->($self, $token);
	    next token;
	}
	if (exists $self->{symbols}{function}{$token}) {
	    if ($In_function{$token}) {
		$self->_warning("Recursive call to '$token' ignored");
	    }
	    else {
		$In_function{$token}++;
		_evaluate ($self, $self->{symbols}{function}{$token});
		$In_function{$token}--;
	    }
	    next token;
	}
	$self->_warning("Undefined function '$token'");
    }
    return $old_warnings == $self->num_warnings;
}
}
}

# A subroutine to format a token for printing
# Arguments: token (popped from stack)
sub _format_token : method {
    my ($self, $token) = @_;

    $_ = $token;
    return (! defined  $_ || $_ eq "-0"
	               ? 'missing' :
	    /^-?\d+$/  ? "#$_" :
	    ref($_)    ? "{" . join(' ', map $self->_format_token($_),
				    grep(! /\#line/, @$_)) . "}" :
	    $_);
}

# Subroutines for built-in functions
# All have the same arguments: $self, function token

sub _function_add_period {
    my ($self, $token) = @_;

    my $arg = $self->_pop(s => $token, 1);
    $arg =~ s/\"$/.\"/ unless $arg =~ /[.?!]\}*\"$/;
    $self->_push(_check_type_warnings() ? '""' : $arg);
}

sub _function_arith {
    my ($self, $token) = @_;

    # We can use builtin eval for these functions
    my $arg1 = $self->_pop(i => $token, 1);
    my $arg2 = $self->_pop(i => $token);
    $self->_push(_check_type_warnings() ? 0 : eval "0+($arg2 $token $arg1)");
}

sub _function_assign {
    my ($self, $token) = @_;

    my $sym = $self->_pop(q => $token, 1);
    my $have_sym if $sym =~ s/^\'//;
    my ($type) = grep(exists $self->{symbols}{$_}{$sym},
		      qw(entry_int entry_str integer string));
    my $val_type = !$have_sym ? 'si' : $type =~ /str/ ? 's' : 'i';
    my $val = $self->_pop($val_type => $token);
    my $bad_arg = _check_type_warnings();
    return if $bad_arg;
    if (! $type) {
	$self->_warning("Undefined variable '$sym'");
    }
    else {
	$self->{symbols}{$type}{$sym} = $val;
    }
}

sub _function_call_type {
    my ($self, $token) = @_;

    return $self->_warning("No current entry in function '$token'")
	unless $self->{bibtex}{bt_entry};
    $self->_evaluate($self->{bibtex}{bt_entry}->type);
}

sub _function_change_case {
    my ($self, $token) = @_;

    my $old_num_warnings = $self->num_warnings;
    my $spec = _trim_string($self->_pop(s => $token, 1));
    my $str  = _trim_string($self->_pop(s => $token));
    return $self->_push('""') if _check_type_warnings();
    if ($spec !~ /^[tul]$/) {
	$self->_warning("Argument 1 of '$token' has illegal specification ($spec)");
	return $self->_push(qq("$str"));
    }
    my $changed;
    $str = _protect($str);
    if ($spec eq 't') {
	my @unchanged = $str =~ /(?:\A|:\s+)([a-z])/ig;
	$changed = lc $str;
	my $cnt = 0;
	$changed =~ s/(\A|:\s+)([a-z])/$1$unchanged[$cnt++]/g;
    }
    else {
	$changed = $spec eq 'u' ? uc $str : lc $str;
    }
#    my $changed = Text::BibTeX::change_case($spec, $str);
    $changed = _unprotect($changed);
    $self->_push(qq("$changed"));
}

sub _function_chr_to_int {
    my ($self, $token) = @_;

    my $arg1 = $self->_pop(s => $token, 1);
    my $bad_arg = _check_type_warnings();
    $self->_warning
	("Argument 1 to '$token' must be a single character")
	if ! $bad_arg && $arg1 !~ /^\"(.)\"$/;
    $self->_push($bad_arg ? 0 : ord($1 || ''));
}

sub _function_cite {
    my ($self, $token) = @_;

    if (! $self->{bibtex}{bt_entry}) {
	$self->_warning("No current entry in function '$token'");
	return $self->_push('""');
    }
    $self->_push(lc qq("$self->{bibtex}{cite}"));
}

sub _function_concat {
    my ($self, $token) = @_;

    my $arg1 = $self->_pop(s => $token, 1);
    my $arg2 = $self->_pop(s => $token);
    $arg1 = _trim_string($arg1);
    $arg2 = _trim_string($arg2);
    $self->_push(qq("$arg2$arg1"));
}

sub _function_duplicate {
    my ($self, $token) = @_;

    my $arg1 = $self->_pop;
    $self->_push($arg1);
    $self->_push($arg1);
}

sub _function_empty {
    my ($self, $token) = @_;

    my $arg1 = $self->_pop(s => $token, 1);
    $self->_push(0+(! defined $arg1 || $arg1 =~ /^\"\s*\"$/));
}

sub _function_eq {
    my ($self, $token) = @_;

    my $arg1 = $self->_pop(is => $token, 1);
    my $type = $arg1 =~ /^\"/ ? 's' : 'i';
    my $arg2 = $self->_pop($type => $token);
    my $op = $type eq 's' ? 'eq' : '==';
    $self->_push(_check_type_warnings() ? 0 : eval "0+(q($arg2) $op q($arg1))");
}

sub _function_format_name {
    my ($self, $token) = @_;

    my $format = $self->_pop(s => $token, 1);
    my $index  = $self->_pop(i => $token);
    my $list   = $self->_pop(s => $token);
    return $self->_push('""') if _check_type_warnings();
    $format = _trim_string($format);
    $list   = _trim_string($list);
    my @list = Text::BibTeX::split_list($list, 'and');
    if ($index > @list || $index < 1) {
	$self->_warning("Index $index is out of range for '$token'");
	return $self->_push('""');
    }
    my $name = $list[$index-1];
    my $bt_name = Text::BibTeX::Name->new($name);
    my %name;
    @name{qw(f v l j)} = map [$bt_name->part($_)], qw(first von last jr);

    my %parts = (f => 'first', v => 'von', l => 'last', j => 'jr');

    # Parse the format string
    $format = _protect($format);
    my @format = split /(PROTECT\(0D\d+\))/, $format;
    my $output = '';
    foreach (@format) {
	if (/^PROTECT/) {
	    my $spec = _unprotect($_);
	    $spec =~ s/^\{(.*)\}/$1/s;
	    my ($pre, $form, $long, $inter, $post, $may_tie, $must_tie) =
		$spec =~ /(.*?)([fjlv])(\2)?(?:\{(.*)\})?(.*?)?(~)?(~)?$/;
	    if (! defined $form) {
		$self->_warning("Invalid format specifier '$spec' for '$token'");
		return $self->_push('""');
	    }
	    my $name = $name{$form};
	    next unless @$name;
	    $pre   = ' ' if $pre eq '' && $output ne '' &&
					   $output !~ /[ ~]$/;
	    my $need_tie = 0;
	    my @out_names;
	    foreach (@$name) {
		my $name = _unprotect($_);
		my $tie = @out_names && $need_tie && $may_tie ? '~' : ' ';
		if ($long) {
		    push @out_names, $tie if @out_names;
		    push @out_names, $name;
		}
		else {
		    # Handle hyphenated names
		    my @parts = split /-/, $name;
		    my @part_letters;
		    foreach my $part (@parts) {
			my ($letter) = $part =~ /^(\{\\[a-z]+|.*?[a-z])/i;
			$letter .= '}' while
			    $letter =~ tr/{// > $letter =~ tr/}//;
			push @part_letters, $letter;
		    }
		    my $join = defined $inter ? "$inter" : '.-';
		    $tie = defined $inter ? $inter : ".$tie";
		    push @out_names, $tie if @out_names;
		    push @out_names, join $join, @part_letters;
		     # Hyphen counts as a tie
		    $tie = '~' if @part_letters > 1 && $tie;
		}
		$need_tie = $tie !~ /~/;
	    }
	    my $out_tie =
		! $long && ($must_tie || $may_tie && $need_tie) ? '~' : '';
	    $output .= ($pre || '') . join('', @out_names) . ($post || '') .
#		'';
		$out_tie;
	}
	else {
	    $output .= $_;
	}
    }

    $self->_push(qq("$output"));
#     my $format = $self->_pop(s => $token, 1);
#     my $index  = $self->_pop(i => $token);
#     my $list   = $self->_pop(s => $token);
#     return $self->_push('""') if _check_type_warnings();
#     $format = _trim_string($format);
#     $list   = _trim_string($list);
#     my @list = split /\s+and\s+/, _protect($list);
#     if ($index > @list || $index < 1) {
# 	$self->_warning("Index $index is out of range for '$token'");
# 	return $self->_push('""');
#     }
#     # N.B. $name is still protected
#     my $name = $list[$index-1];
#     # Decompose the string into first, von, last, and junior
#     my @names = split /,\s*/, $name;
#     my $von_re = '[a-z](?:PROTECT\(0D\d+\)|\\.|[a-z])*';
#     my %name;			# Four keys: f, j, l, v
#     if (@names > 1) {		# "von Last, Junior, First" style
# 	$name{f}  = $names[-1];
# 	$name{j} = $names[1] if @names > 2;
# 	my @last = split /\s+/, $names[0];
# 	my @von;
# 	while ($_ = shift @last) {
# 	    # Get the first letter
# 	    my $name     = _unprotect($_);
# 	    my ($letter) = $name =~ /([a-z])/i;
# 	    if ($letter =~ /[a-z]/) {
# 		push @von, $_;
# 	    }
# 	    else {
# 		unshift @last, $_;
# 		last;
# 	    }
# 	}
# 	$name{v} = join ' ', @von;
# 	$name{l} = join ' ', @last;
#     }
#     else {
# 	my (@first, @von, @last);
# 	@names = split /\s+/, $name;
# 	@last = pop @names;
# 	while ($_ = shift @names) {
# 	    # Get the first letter
# 	    my $name     = _unprotect($_);
# 	    my ($letter) = $name =~ /([a-z])/i;
# 	    if ($letter =~ /[a-z]/) {
# 		push @von, $_;
# 	    }
# 	    elsif (@von) {
# 		unshift @last, $_;
# 		last;
# 	    }
# 	    else {
# 		push @first, $_;
# 	    }
# 	}
# 	$name{f} = join ' ', @first;
# 	$name{v} = join ' ', @von;
# 	$name{l} = join ' ', @last;
#     }

#     # Parse the format string
#     $format = _protect($format);
#     my @format = split /(PROTECT\(0D\d+\))/, $format;
#     my $output = '';
#     foreach (@format) {
# 	if (/^PROTECT/) {
# 	    my $spec = _unprotect($_);
# 	    $spec =~ s/^\{(.*)\}/$1/s;
# 	    my ($pre, $form, $long, $inter, $post, $tie, $must_tie) =
# 		$spec =~ /(.*?)([fjlv])(\2)?(\{.*\})?(.*?)?(~)?(~)?$/;
# 	    if (! defined $form) {
# 		$self->_warning("Invalid format specifier '$spec' for '$token'");
# 		return $self->_push('""');
# 	    }
# 	    my $name = $name{$form};
# 	    next unless defined $name && $name ne '';
# 	    $inter = $long ? '~' : '.~' unless ($inter || '') ne '';
# 	    $inter =~ s/^\{(.*)\}$/$1/s;
# 	    $pre   = ' ' if $pre eq '' && $output ne '' &&
# 					   $output !~ /[ ~]$/;
# 	    if (! $long) {
# 		my @names = split /\s+/, $name;
# 		my @inits;
# 		foreach (@names) {
# 		    my $name = _unprotect($_);
# 		    my ($letter) = $name =~ /^(\{\\[a-z]+|.*?[a-z])/i;
# 		    $letter .= '}' while $letter =~ tr/{// > $letter =~ tr/}//;
# 		    push @inits, $letter;
# 		}
# 		$name = join ' ', @inits;
# 	    }
# 	    my @names = split /\s+/, $name;
# 	    $output .= ($pre || '') . join($inter, @names) . ($post || '') .
# 		($must_tie || '');
# 	}
# 	else {
# 	    $output .= $_;
# 	}
#     }
#     $output = _unprotect($output);
#     $self->_push(qq("$output"));
}

sub _function_if {
    my ($self, $token) = @_;

    my $else = $self->_pop(qx => $token, 1);
    my $if   = $self->_pop(qx => $token);
    my $cond = $self->_pop(i  => $token);
    return if _check_type_warnings();
    my $branch = $cond > 0 ? $if : $else;
    $self->_evaluate($branch);
}

sub _function_int_to_chr {
    my ($self, $token) = @_;

    my $arg1 = $self->_pop(i => $token, 1);
    $self->_push(_check_type_warnings() ? '""' : '"' . chr($arg1) . '"');
}

sub _function_int_to_str {
    my ($self, $token) = @_;

    my $arg1 = $self->_pop(i => $token, 1);
    $self->_push(_check_type_warnings() ? '""' : qq("$arg1"));
}

sub _function_missing {
    my ($self, $token) = @_;

    my $arg1 = $self->_pop(s => $token, 1);
    $self->_push(0+(! defined $arg1));
}

sub _function_newline {
    my ($self, $token) = @_;

    push @{$self->{output}}, "\n";
}

sub _function_num_names {
    my ($self, $token) = @_;

    my $arg1 = _trim_string($self->_pop(s => $token, 1));
    return $self->_push(0) if _check_type_warnings();
    my @split = Text::BibTeX::split_list($arg1, 'and');
    $self->_push(0+@split);
}

sub _function_preamble {
    my ($self, $token) = @_;

    $self->_push(sprintf '"%s"', join('', @{$self->{bibtex}{preamble}}));
}

sub _function_purify {
    my ($self, $token) = @_;

    my $arg = _trim_string($self->_pop(s => $token, 1));
    return $self->_push('""') if _check_type_warnings();
#    my $pure = Text::BibTeX::purify_string($arg);
#    $self->_push(qq("$pure"));

    $arg =~ s/[\s~]+/ /g;
    # Handle accents
    $arg =~ s/\\i\b/i/g;
    $arg =~ s/\{ \\ (?:$Acc_char|$Acc_let[ ]) [ ]* ([a-z]+) [ ]*
	(?:\}|\Z)/$1/ogix;
    $arg =~ s/\\ (?:$Acc_char|$Acc_let) [ ]* \{ [ ]* ([a-z]+) [ ]*
	(?:\}|\Z)/$1/ogix;
    $arg =~ s/($Acc_sym)/(my $v = $1) =~ tr!a-zA-Z!!cd; $v/goxe;
    # Remove \latex[options]{commands}
    1 while $arg =~ s/\\([^\{\[]+)//g;
    # Remove braces around only alphanum
    1 while $arg =~ s/\{([a-z0-9 ]+)\}/$1/gi; 
    $arg =~ s/\{[^{}]*\}//g;	# Remove all other braces
    $arg =~ tr/a-zA-Z0-9 ~//cd;
    $arg =~ tr/~/ /;
    $arg =~ s/\s+/ /g;
    $self->_push(qq("$arg"));
}

sub _function_stack {
    my ($self, $token) = @_;

     while (@{$self->{stack}}) {
 	my $val = $self->_pop;
 	$self->_warning($self->_format_token($val), 1);
     }
}

sub _function_substring {
    my ($self, $token) = @_;

    my $len    = $self->_pop(i => $token, 1);
    my $start  = $self->_pop(i => $token);
    my $string = $self->_pop(s => $token);
    return $self->_push('""') if _check_type_warnings();
    if ($start == 0) {
	$self->_warning("Argument 2 to '$token' cannot be 0");
	return $self->_push('""');
    }
    $string = _trim_string($string);
    my $str_len = length $string;
    $start = $start > 0 ? $start - 1 : $str_len + $start - $len + 1;
    if ($start < 0) {
	$len  += $start;
	$start = 0;
    }
    $self->_push(sprintf '"%s"', substr($string, $start, $len));
}

sub _function_swap {
    my ($self, $token) = @_;

    my ($arg1, $arg2) = ($self->_pop, $self->_pop);
    $self->_push($arg1, $arg2);
}

sub _function_text_length {
    my ($self, $token) = @_;

    my $arg = $self->_pop(s => $token, 1);
    return $self->_push(0) if _check_type_warnings();
    $arg = _trim_string($arg);
    # Count the accents
    my $length =
	$arg =~ s/\{ \\ (?:$Acc_char|$Acc_let[ ]) [ ]* [a-z]+ [ ]*
	(?:\}|\Z)//ogix;
    $length +=
	$arg =~ s/\\ (?:$Acc_char|$Acc_let) [ ]* \{ [ ]* [a-z]+ [ ]*
	(?:\}|\Z)//ogix;
    $length +=
	$arg =~ s/$Acc_sym//gox;
    # Remove any remaining braces
    $arg =~ s/[{}]//g;
    # Count whatever's left
    $length += length $arg;
    $self->_push($length);
}

sub _function_text_prefix {
    my ($self, $token) = @_;

    my $len = $self->_pop(i => $token, 1);
    my $str = $self->_pop(s => $token);
    return $self->_push('""') if _check_type_warnings();
    my $answer = '';
    $_ = _trim_string($str);
    while ($_ && $len) {
	if (s/^(\{ \\ (?:$Acc_char|$Acc_let[ ]) [ ]* [a-z]+ [ ]*
		(?:\}|\Z))//oix ||
	    s/^(\\ (?:$Acc_char|$Acc_let) [ ]* \{ [ ]* [a-z]+ [ ]*
		(?:\}|\Z))//oix ||
	    s/^($Acc_sym)//o ||
	    s/^([^{}])//) {
	    $answer .= $1;
	    $len--;
	}
	elsif (/^(\{)/) {
	    my $brace;
	    ($brace, $_) = _remove_matched_brace($_);
	    $answer .= $brace;
	    $len--;
	}
	else {
	    s/^[{}]//;
	}
    }
    $answer .= '}' while $answer =~ tr/{// > $answer =~ tr/}//;
    $self->_push(qq("$answer"));
}

{				# Closure
my %Char_widths =
 ( 0040 => 278, 0041 => 278, 0042 => 500, 0043 => 833, 0044 => 500,
   0045 => 833, 0046 => 778, 0047 => 278, 0050 => 389, 0051 => 389,
   0052 => 500, 0053 => 778, 0054 => 278, 0055 => 333, 0056 => 278,
   0057 => 500, 0060 => 500, 0061 => 500, 0062 => 500, 0063 => 500,
   0064 => 500, 0065 => 500, 0066 => 500, 0067 => 500, 0070 => 500,
   0071 => 500, 0072 => 278, 0073 => 278, 0074 => 278, 0075 => 778,
   0076 => 472, 0077 => 472, 0100 => 778,

   # A-Z
   0101 => 750, 0102 => 708, 0103 => 722, 0104 => 764, 0105 => 681,
   0106 => 653, 0107 => 785, 0110 => 750, 0111 => 361, 0112 => 514,
   0113 => 778, 0114 => 625, 0115 => 917, 0116 => 750, 0117 => 778,
   0120 => 681, 0121 => 778, 0122 => 736, 0123 => 556, 0124 => 722,
   0125 => 750, 0126 => 750, 0127 => 1028, 0130 => 750, 0131 => 750,
   0132 => 611,

   0133 => 278, 0134 => 500, 0135 => 278, 0136 => 500, 0137 => 278,
   0140 => 278,

   # a-z
   0141 => 500, 0142 => 556, 0143 => 444, 0144 => 556, 0145 => 444,
   0146 => 306, 0147 => 500, 0150 => 556, 0151 => 278, 0152 => 306,
   0153 => 528, 0154 => 278, 0155 => 833, 0156 => 556, 0157 => 500,
   0160 => 556, 0161 => 528, 0162 => 392, 0163 => 394, 0164 => 389,
   0165 => 556, 0166 => 528, 0167 => 722, 0170 => 528, 0171 => 528,
   0172 => 444, 0173 => 500, 0174 => 1000, 0175 => 500, 0176 => 500,

   aa => 500, AA => 750, o => 500, O => 778, l => 278, L => 625,
   ss => 500, ae => 722, oe => 778, AE => 903, OE => 1014, '?`' => 472,
   '!`' => 278,

);

sub _function_width {
    my ($self, $token) = @_;

    my $arg = _trim_string($self->_pop(s => $token, 1));
    return $self->_push(0) if _check_type_warnings();

    # Approximate most special characters with their base character
    my $width = 0;
    while ($arg =~
	   s/^(?:(?:\{ \\ (?:$Acc_char|$Acc_let[ ]) [ ]* ([a-zA-Z]+) [ ]* |
		  \\ (?:$Acc_char|$Acc_let) [ ]* \{ [ ]* ([a-zA-Z]+) [ ]* |
		  \{ ($Acc_sym) ) (?:\}|\Z) |
	       ($Acc_sym) |
	       (.))/($1 || '').($2 || '')/exo) {
	my ($symbol, $letter) = ($3 || $4, $5);
	$width += $Char_widths{ord $letter} || 0 if defined $letter;
	$width += $Char_widths{$symbol} || 0
	    if defined $symbol && $symbol =~ s/^\\?//;
    }
    $self->_push($width);
}
}
}

sub _function_top {
    my ($self, $token) = @_;

    my $arg = $self->_pop;
    $self->_warning($self->_format_token($arg), 1);
}

sub _function_type {
    my ($self, $token) = @_;

    return $self->_push('""') unless my $bt_entry = $self->{bibtex}{bt_entry};
    $self->_push('"' . (lc $bt_entry->type) . '"');
}

sub _function_warning {
    my ($self, $token) = @_;

    my $arg = $self->_pop(s => $token, 1);
    return if _check_type_warnings();
    $arg = _trim_string($arg);
    $self->_warning("Warning--$arg", 1);
}

sub _function_while {
    my ($self, $token) = @_;

    my $do   = $self->_pop(qx => $token, 1);
    my $cont = $self->_pop(qx => $token);
    return if _check_type_warnings();
    my $val;
    while ($self->_evaluate($cont) && ($val = $self->_pop(i => $token)) &&
	   ! _check_type_warnings()) {
	$self->_evaluate($do);
    }
}

sub _function_write {
    my ($self, $token) = @_;

    my $out = $self->_pop(s => $token, 1);
    if (! _check_type_warnings()) {
	$out = _trim_string($out);
	push @{$self->{output}}, $out;
    }
}

# Pops the top element from the stack, possibly doing type checking.
# If one argument is present, all must be
# Arguments: optional (type(s), token, first_arg)
# The types are a concatenation of
#   i: integer
#   q: quoted value (e.g., 'a)
#   s: string
#   x: expression (array ref)
# See the description of _check_type for the optional arguments
sub _pop : method {
    my ($self, $types, $token, $first_arg) = @_;
    
    my $where = defined $token ? " on token '$token'" : '';
    return $self->_warning("Stack underflow$where") unless @{$self->{stack}};
    my $val = pop @{$self->{stack}};
    $self->_check_type($val, $types, $token, $first_arg) if $types;
    return $val;
}

# Pushes some elements on the stack
sub _push : method {
    my $self = shift;

    push @{$self->{stack}}, @_;
}

# Removes the outer "s from a string
# Arguments: string to trim
# Returns:   trimmed string
sub _trim_string {
    my ($str) = @_;

    $str =~ s/^\"(.*)\"$/$1/s;
    return $str;
}


# Routines to protect and unprotect strings within braces
{
    my %Brackets;
    my $Bracket_cnt = 0;

# Protects strings within matching { } pairs
# Arguments
sub _protect {
    my ($s) = @_;

    while ($s =~ s/\{ ([^{}]*) \}/
	   my $v = sprintf 'PROTECT(0D%d)', $Bracket_cnt++;
	   $Brackets{$v} = $1; $v/ex) { }
    return $s;
}

# Removes a leading left brace to its matching right brace
# Arguments: string
# Returns: removed brace, remaining string
sub _remove_matched_brace {
    my ($str) = @_;

    return ('', $str) unless $str =~ s/^(\{)//;
    # Find the matching brace
    my $nest = 1;
    my @char = ($1);
    1 while $str =~ s/^(.*?)([{}])/do {
	$nest += $2 eq '{' ? 1 : -1;
	push @char, $1, $2;
	'' } /es && $nest > 0;
    if ($nest > 0) {
	push @char, $str;
	$str = '';
    }
    return (join('', @char), $str);
}

################# Routines to support output translation

{ 				# Closure

my %Accents =
( "'" => {
    A	=> 193,  # capital A, acute accent
      a	=> 225,  # small a, acute accent
      C => 0x106,
      c => 0x107,
      E	=> 201,  # capital E, acute accent
      e	=> 233,  # small e, acute accent
      I	=> 205,  # capital I, acute accent
      i	=> 237,  # small i, acute accent
      L => 0x139,
      l => 0x13a,
      N => 0x143,
      n => 0x144,
      O	=> 211,  # capital O, acute accent
      o	=> 243,  # small o, acute accent
      R => 0x154,
      r => 0x155,
      S => 0x15a,
      s => 0x15b,
      U	=> 218,  # capital U, acute accent
      u	=> 250,  # small u, acute accent
      Y	=> 221,  # capital Y, acute accent
      y	=> 253,  # small y, acute accent
      Z => 0x179,
      z => 0x17a,
  },
  '`' => {
      A	=> 192,  # capital A, grave accent
      a	=> 224,  # small a, grave accent
      E	=> 200,  # capital E, grave accent
      e	=> 232,  # small e, grave accent
      I	=> 204,  # capital I, grave accent
      i	=> 236,  # small i, grave accent
      O	=> 210,  # capital O, grave accent
      o	=> 242,  # small o, grave accent
      U	=> 217,  # capital U, grave accent
      u	=> 249,  # small u, grave accent
  },
  '^' => {
      A	=> 194,  # capital A, circumflex accent
      a	=> 226,  # small a, circumflex accent
      E	=> 202,  # capital E, circumflex accent
      e	=> 234,  # small e, circumflex accent
      G => 0x11c,
      g => 0x11d,
      H => 0x124,
      h => 0x125,
      I	=> 206,  # capital I, circumflex accent
      i	=> 238,  # small i, circumflex accent
      J => 0x134,
      j => 0x135,
      O	=> 212,  # capital O, circumflex accent
      o	=> 244,  # small o, circumflex accent
      S => 0x15c,
      s => 0x15d,
      U	=> 219,  # capital U, circumflex accent
      u	=> 251,  # small u, circumflex accent
      W => 0x174,
      w => 0x175,
      Y => 0x176,
      y => 0x177,
  },
  '"' => {
      A	=> 196,  # capital A, dieresis or umlaut mark
      E	=> 203,  # capital E, dieresis or umlaut mark
      I	=> 207,  # capital I, dieresis or umlaut mark
      O	=> 214,  # capital O, dieresis or umlaut mark
      U	=> 220,  # capital U, dieresis or umlaut mark
      Y	=> 376,
      a	=> 228,  # small a, dieresis or umlaut mark
      e	=> 235,  # small e, dieresis or umlaut mark
      i	=> 239,  # small i, dieresis or umlaut mark
      o	=> 246,  # small o, dieresis or umlaut mark
      u	=> 252,  # small u, dieresis or umlaut mark
      y	=> 255,  # small y, dieresis or umlaut mark
  },
  '~' => {
      A	=> 195,  # capital A, tilde
      a	=> 227,  # small a, tilde
      I => 0x128,
      i => 0x129,
      N	=> 209,  # capital N, tilde
      n	=> 241,  # small n, tilde
      O	=> 213,  # capital O, tilde
      o	=> 245,  # small o, tilde
      U => 0x168,
      u => 0x169,
  },
  '=' => {
      A => 0x100,
      a => 0x101,
      E => 0x112,
      e => 0x113,
      I => 0x12a,
      i => 0x12b,
      O => 0x14c,
      o => 0x14d,
      U => 0x16a,
      u => 0x16b,
  },
  '.' => {
      C => 0x10a,
      c => 0x10b,
      E => 0x116,
      e => 0x117,
      G => 0x120,
      g => 0x121,
      L => 0x13f,
      l => 0x140,
      Z => 0x17b,
      z => 0x17c,
  },
  c => {
      A => 0x104,
      a => 0x105,
      C	=> 199,  # capital C, cedilla
      c	=> 231,  # small c, cedilla
      E => 0x118,
      e => 0x119,
      G => 0x122,
      g => 0x123,
      I => 0x12e,
      i => 0x12f,
      K => 0x136,
      k => 0x137,
      L => 0x13b,
      l => 0x13c,
      N => 0x145,
      n => 0x146,
      R => 0x156,
      r => 0x157,
      S => 0x15e,
      s => 0x15f,
      T => 0x162,
      t => 0x163,
      U => 0x172,
      u => 0x173,
  },
  H => {
      O => 0x150,
      o => 0x151,
      U => 0x170,
      u => 0x171,
  },
  u => {
      A => 0x102,
      a => 0x103,
      E => 0x114,
      e => 0x115,
      G => 0x11e,
      g => 0x11f,
      I => 0x12c,
      i => 0x12d,
      O => 0x14e,
      o => 0x14f,
      U => 0x16c,
      u => 0x16d,
  },
  v => {
      C => 0x10c,
      c => 0x10d,
      D => 0x10e,
      d => 0x10f,
      E => 0x11a,
      e => 0x11b,
      H => 0x124,
      h => 0x125,
      J => 0x134,
      j => 0x135,
      L => 0x13d,
      l => 0x13e,
      N => 0x147,
      n => 0x148,
      R => 0x158,
      r => 0x159,
      S => 0x160,
      s => 0x161,
      T => 0x164,
      t => 0x165,
      Z => 0x17d,
      z => 0x17e,
  }
);

my %Chars = 
   (
    '\AA'	=> 197,  # capital A, ring
    '\aa'	=> 229,  # small a, ring
    '\AE'	=> 198,  # capital AE diphthong (ligature)
    '\ae'	=> 230,  # small ae diphthong (ligature)
    '\copyright'=> 0xa9,
    '\L'	=> 0x141,
    '\l'	=> 0x142,
    '\O'	=> 216,  # capital O, slash
    '\o'	=> 248,  # small o, slash
    '\OE'	=> 0x152,
    '\oe'	=> 0x153,
    '\P'	=> 0xb6,
    '\pounds'	=> 0xa3,
    '\S'	=> 0xa7,
    '\ss'	=> 223,  # small sharp s, German (sz ligature)
    '\dag'      => 0x2020,
    '\ddag'	=> 0x2021,
    '!`'	=> 0xa1,
    '?`'	=> 0xbf,
    '``'	=> 0x201c,
    "''"	=> 0x201d,
    '~'		=> 160,  # non breaking space
    '--'	=> 0x2013,
    '---'	=> 0x2014,
);

# Returns the result of calling the character option subroutine for
# a special character
# Arguments: bst object, Latex string, characters to accent, optional accent
sub _character {
    my ($bst, $opts, $latex, $chars, $accent) = @_;
    my $unicode = $accent ? $Accents{$accent}{$chars} : $Chars{$chars};
    $unicode = chr($unicode) if defined $unicode;
    &{$opts->{character}}($bst, $latex, $unicode, $chars, $accent);
}
}

# Takes a string, removes all \newcommand commands from it, and substitutes 
# for all uses of those \newcommand commands.
# Arguments: string
# Returns: substituted string
sub _substitute_newcommand {
    my ($str) = @_;

    my %command;
    1 while $str =~ s/\\newcommand\{ \\([a-z]+) \} \[ (\d+) \](\{.*)/do {
	my ($cmd, $args, $next, $def) = ($1, $2, $3);
	($def, $next) = _remove_matched_brace($next);
	$def =~ s!^\{(.*)\}$!sub { qq(\Q$1\E) }!s;
	$def =~ s!\\\#(\d+)!\$_[@{[$1-1]}]!g;
	my $sub = eval("$def");
	die "Internal error: $@" if $@;
	$command{$cmd} = { args => $args, def => $def, code => $sub };
	$next;
    }/sexi;

    if (%command) {
 	my $cmd_re = join '|', keys %command;
 	1 while $str =~ s/\\($cmd_re)(\{.*)/do {
	    my ($cmd, $next) = ($1, $2);
	    my @args;
	    for (my $i=0; $i < $command{$cmd}{args}; $i++) {
		my ($arg, $next_) = _remove_matched_brace($next);
		$arg =~ s!^\{(.*)\}$!$1!s;
		push @args, $arg;
		$next = $next_;
	    }
	    &{$command{$cmd}{code}}(@args) . $next;
 	}/se;
    }

    return $str;
}

sub _unprotect {
    my ($s) = @_;

    return $s unless %Brackets;
    my $brack_re = join '|', map("\Q$_", keys %Brackets);
    while ($s =~ s/($brack_re)/{$Brackets{uc $1}}/igx) { }
    return $s;
}
}

# Reports a warning
# Arguments: warning string, lineno_suppression
# Rturns: 1
sub _warning : method {
    my ($self, $warning, $no_lineno) = @_;

    my $lineno = $no_lineno ? '' : "$self->{lineno}: ";
    my $warn = "$lineno$warning";
    push @{$self->{warnings}}, "$warn\n";
    carp $warn;
    return 1;
}

1;
