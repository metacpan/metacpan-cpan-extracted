# the iPerl engine Text::iPerl.pm
#
# Inverse Perl Preprocessor for Arbitrary Documents
#
# Copyright © 1999, 2000, Daniel Pfeiffer <occitan@esperanto.org>
#
# iPerl may be copied only under the terms of either the Artistic License or
# the GNU General Public License, which may be found in the Perl 5.0 source kit.
#
# Info and latest version are at http://beam.to/iPerl/

=head1 NAME

Text::iPerl - engine for bringing any text documents alive
with bits of embedded Perl

=head1 SYNOPSIS

  use Text::iPerl;
  include 'documentname';

or

  perl -MText::iPerl -e include <infile >outfile

See L<iperl> for a far more comfortable command-line variant

=head1 DESCRIPTION

This is the engine of an inverse Perl interpreter, which controls normal text
with macro invocations and specially marked bits of Perl.  This setup of the
document is always the same, though details may vary according to the style in
effect.  (See C<set_style>.)  The engine is invoked with C<include>, or its
variants C<include_filehandle> and C<include_string>.  It treats a given
document in two phases, with two or three aspects:

=head2 Markup Style

Bits of Perl to be evaluated have to be specially marked up as such.  How this
is done differs greatly depending on the style in effect.  But apart from
different syntaxes there are only two fundamental ways in which Perl can be
embedded: non-printing and printing.  Not all styles provide both ways.  The
difference between these two ways is to be seen as default-functionality and
is not restrictive.  Non-printing Perl may very well use the print statement,
or system-commands to output something via C<STDOUT> into the output stream.
If system-commands are used you should first turn on autoflushing (C<$| = 1>)
to ensure that output order is preserved.

=head2 Perl

The whole document is actually reinverted or transformed into a
Perl-programme, where each bit of normal text gets transformed into a
semicolon-terminated Perl-statement.  The markup around bits of non-printing
Perl simply gets removed and a terminating semicolon added, which almost never
hurts.  If you want a bit of non-printing Perl to control the preceding or
following bit of normal text, you can prevent the semicolon by starting or
ending the Perl code with C<\;>.  You can delimit the bit of normal text with
a bit of non-printing Perl containing only a semicolon.

Printing bits of Perl, on the other hand, get passed as an argument list to a
print statement, or to printf, if it starts with C<%>.  If a printing bit of
Perl is empty, C<$_> is printed.  If it is a literal integer,
C<$_[I<n>]> is printed.

There are several interesting things you can do with syntactically incomplete
bits of Perl.  You can seal the fate of the following bit of plain text by
preceding it with an expression followed by C<and> or C<or> and terminated
with C<\;>.  Or you can have dangling curly braces of an
C<if-elsif-else>-statement.  They might also be of a loop, which will likely
contain one or more printing bits of Perl.

Dangling curly braces may even be of a sub, which will then print the
contained plain text when called.  Likewise they may be of an anonymous sub
which could be the second argument to C<define>.

There are no syntactic extensions to Perl, just a couple of variables and
functions like C<include> or C<define>.

=head2 Macros

Normal text gets output as is, unless we have macro-definitions.  If macros
are defined, at runtime every bit of normal text gets repeatedly scanned for
macros, which are expanded until no more macro invocations are found,
i.e. macro expansions occur depth-first.  Macros are functions returning a
string.  If they also print something, that comes in the output stream before
the returned string and is not subject to repeated scanning.  Scanning starts
again where the last macro was found, so if a macro returns what might be the
second part of a macro name together with the preceding text, that is not
found.  (See C<define>, C<undefine> & C<macro>.)

Macro invocations consist of the macro name, a string of letters, digits and
underscores, optionally usually immediately followed by a parenthesized Perl
parameter list.  Note that even if the macro is surrounded by a bit of Perl
with a C<my>-variable, that variable will not be visible, since macro
invocations are evaluated later, not seen at compile time.  Depending on the
style, macro invocations may be surrounded by additional syntactic sugar.
(See C<$macro_start> and friends.)

=head1 @EXPORT

Text::iPerl exports the following functions by default:

C<include>, C<include_string>, C<include_filehandle>, C<define>, C<undefine>,
C<macro>

=head2 @EXPORT_OK

Text::iPerl optionally exports the following function and variables:

C<set_style>, C<$cache>, C<$comment_level>, C<debug>, C<%debug>, C<$documents>,
C<@documents>, C<$joiner>, C<$macro_end>, C<$macro_name_end>, C<$macro_start>,
C<$macro_start_dollar1>, C<$max_macro_growth>, C<$max_macro_expansions>,
C<$printfer>, C<%trace>

=cut





package Text::iPerl;

use 5.004;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(include include_string define undefine macro);
@EXPORT_OK = qw(set_style $style @autostyle_by_name @autostyle_by_contents
		$cache debug %debug $documents @documents $header
		$max_macro_growth $max_macro_expansions $macro_start_dollar1
		$macro_start $macro_name_end $macro_end $comment_level $joiner
		$printfer %trace);
$VERSION = 0.6;


@include = ('/usr/include', @INC);

$style = 'auto';
@autostyle_by_name =
    ('\.(?:p[cChH]|p[ch]pp|[cChH]p?|[ch]ppp?)$' => cpp,
     '\.(?:pm[4c]|m[4c]p?)$' => m4,
     '\.(?:ppod|podp?|pm|pl)$' => pod,
     '\.(?:p(?:sg|ht|w|x)ml|(?:sg|ht|w|x)mlp?)$' => xml);
@autostyle_by_contents =
    ('^|[][\s\S]*' => control,
     '<script\s[^>]*runat\s*=\s*[\'\"]?server\b.*?>|<(?:server|perl)\b.*?>' =>
	xml,
     'perl\((?:<\s*[\s\S]*?\s*>|\{\s*[\s\S]*?\s*\}|\})\)' => m4,
     '^=perl\b|[PM]<[\s\S]*?>' => pod,
     '<\{[\s\S]*?\}>' => xml,
     '!\{[\s\S]*?\}!|!<[\s\S]*?>!|^!' => bang,
     '^#' => cpp);

$cache = 1;
$comment_level = 1;

$max_macro_expansions = $max_macro_growth = 1000;

$joiner = '\\\\;';
$printfer = '%';

$documents = 0;
@documents = ();

sub debug($$);
sub set_style($;@);


# internal utilities


sub _case($@) {
    my( $str, @conds ) = @_;
    while( @conds ) {
	return $conds[1] if
	    $str =~ /$conds[0]/m;
	splice @conds, 0, 2;
    }
    undef;
}



sub _compile($$) {
    local $prog = '';		# locals don't do closure in eval
    my @_Text_iPerl;
    local( $style, $macro_start, $macro_name_end, $macro_end,
	   $macro_start_dollar1, $splitter ) =
	( $style, $macro_start, $macro_name_end, $macro_end,
	  $macro_start_dollar1, $splitter );
    {
	my $string = @_ ? $_[0] : $_;
	if( $style =~ /^auto/ ) {
	    my $orig_style = $style;
	    my $det_style =
		($string =~
		    /\A(?:\#!.+\n)?
		     .*-\*-.*\b iPerl-style:\s*"(.+?)" .*-\*-/mx) ? $1 :
		(substr( $string, -3000 ) =~
		    /^(.*?)[ \t]* Local\ Variables: [ \t]*(.*)$
		     (?:^\1 .+ \2\n)*?
		     ^\1[ \t]* iPerl-style:\s*"(.+?)" [ \t]*\2$
		     (?:^\1 .+ \2\n)*?
		     ^\1[ \t]* End: [ \t]*\2$
		     (?:(?!\n).)*\Z/mx) ? $3 :
		_case( $_[1], @autostyle_by_name ) ||
		_case( $string, @autostyle_by_contents );
	    if( $det_style ) {
		set_style $det_style;
		$style = "auto: $style";
	    } elsif( $orig_style eq 'auto' ) {
		die "No style determined for $_[1]";
	    }
	}
	my( $bol, $length, $text, @res ) = 1;
	while( 1 ) {
	    @res = &$splitter( $string,
			       $bol ? '^' : '(?!\A)^',
			       ${['\Z',
				  $bol ? '^' : '(?!\A)^',
				  $bol ? '^[^\S\n]*' : '(?!\A)^[^\S\n]*',
				  '']}[$comment_level],
			       ${['',
				  '$ \n?',
				  '[^\S\n]*$ \n?',
				  '']}[$comment_level] );
	    for( $res[0] ) {
		next unless defined and $length = length;
		$text = ( $length < 20 and ! /[\\']/ ) ?
		    "'$_'" :
		    ('$_Text_iPerl[' .
		     (push( @_Text_iPerl, $_ ) - 1) .
		     ']');
		$prog .= (/[a-zA-Z0-9_]/ ?
		    'Text::iPerl::_output ' :
		    'print ') . $text . ';';
	    }
	    for( $res[1] ) {
		next unless defined;
		/\A\s*($printfer\s*)?(.*?)\s*\Z/s;
		$prog .= 'print' . ($1 ? 'f' : '') . ' STDOUT (' .
		    ($2 eq int( $2 ) ? "\$_[$2]" : $2 || '$_') ."\n);";
	    }
	    for( $res[2] ) {
		next unless defined;
		/\A\s*($joiner\s*)?(.*?)\s*($joiner\s*)?\Z/s;
		chop $prog if defined $1 && ';' eq substr $prog, -1, 1;
		$prog .= defined $3 ? " $2 " : " $2\n;";
	    }
	last unless defined $res[3];
	    $string = $res[3];
	    $bol = defined $res[4] && "\n" eq substr $res[4], -1, 1;
	}
    }
    debug c => sub {
	print "Generated code: {\n\$style = '$style';\n\n";
	my $j = 0;
	foreach( @_Text_iPerl ) {
	    local $_ = $_;
	    s/\\/\\\\/g;
	    s/'/\\'/g;
	    print "my \$_Text_iPerl[$j] = '$_';\n\n";
	    $j++;
	}
	print "\f\n$prog\n} # Generated code\n";
    };

    push @_Text_iPerl,
	$macro_start, $macro_name_end, $macro_end, $splitter, $_[1];
    $prog = qq{
	local( \$style, \$macro_start_dollar1,
	       \$macro_start, \$macro_name_end, \$macro_end,
	       \$splitter ) =
	    ( '$style', $macro_start_dollar1, \@_Text_iPerl[-5..-2] );
	push \@documents, \$_Text_iPerl[-1];
#line 1 '$_[1]'
	$prog
    };
    if( $cache and $prog !~ /\bsub\b/ ) {	# $] >= 5.099
	# Fixed nested closure when? (see comp.lang.perl.misc 2000-07-22)
	$prog = eval "sub{$prog}";
	die $@ if $@;
    } else {
	$prog = [$prog, @_Text_iPerl];
    }
    $prog;
}



sub _eval($) {
#local $^W=1;
    {
	my $package = caller 1;
	$_[0] = "package $package; $_[0]";
	debug E => $_[0];
    }
    my $result = eval $_[0];
    die $@ if $@;
    $result;
}



sub _output($) {
    if( defined $header ) {
	print $header;
	undef $header;
    }
    my( $string ) = @_;
    if( $defines ) {
	my( $i, $length, $args ) = ( 0, 0, '' );
	my $max_length = $max_macro_growth * length $string;
	my( $macro, $post );
	local $macrodef;
	while( $string =~
	       /$macro_start($defines)$macro_name_end(\(.*?\))?($macro_end)/s )
	{
	    print $`;
	    $length += length $`;
	    if( $macro_start_dollar1 ) {
		print $1;
		$length += length $1;
		$macro = $2;
		$args = $3; $end = $4;
	    } else {
		$macro = $1;
		$args = $2; $end = $3;
	    }
	    $post = $';
	    $macrodef = $defines{$macro};
	    $macrodef = $defines{$$macrodef} || $$macrodef
		while defined ref $macrodef and ref( $macrodef ) eq 'SCALAR';
	    while( (!$end) && $args =~ tr/(/(/ > $args =~ tr/)/)/ ) {
		$post =~ /^(.*?\))($macro_end)/s or
		    die "missing ')' for inlined macro ``$macro''";
		$args .= $1; $end = $2; $post = $';
	    }
	    $args ||= '()';
	    $package = caller;
	    $macrodef = _eval "\n#line 0 'inlined macro \"$macro\"'\n" .
		(ref( $macrodef ) ?
		 "&\$Text::iPerl::macrodef$args" :
		 "$macrodef$args");
	    $string = $macrodef . $post;
	    debug \$macro => sub {
		print $macro . (($debug{V} || $debug{a}) && $args) .
		    (($debug{V} || $debug{e}) && " -> $macrodef") .
		    "\n";
	    };
	    die 'Factor $Text::iPerl::max_macro_growth exceeded'
		if $max_length < $length + length $string;
	    die '$Text::iPerl::max_macro_expansions exceeded'
		if $max_macro_expansions < ++$i;
	}
    }
    print $string;
    '';
}



sub _run($) {
    debug i => (caller 1)[3] . ":@documents";
    $documents++;
    local @documents = @documents;
    if( 'CODE' eq ref $_[0] ) {
	&{$_[0]};
    } else {
	my @_Text_iPerl = @{$_[0]};
	eval shift @_Text_iPerl;
	die $@ if $@;
    }
    '';
}





# Most functions which don't return anything meaningful, explicitly return '',
# so as to be useable as (or - like _output & _run - implicitly in) a macro.

=head1 FUNCTIONS

=over

=item debug WHEN, STRING

=item debug WHEN, CODEREF

=cut

sub debug($$) {
    return '' unless %debug || %trace;
    my( $when, $what ) = @_;
    return '' unless $debug{V}
	or ref( $when ) ? $debug{t} || $trace{${$when}} : $debug{$when};
    my $oldfh = select STDERR;
    my $msg = 'iPerl-debug:';
    if( $debug{F} || $debug{V} ) {
	$msg .= ($documents[-1] || (caller 1)[1]) . ':';
    } elsif( $debug{f} ) {
	my $file = $documents[-1] || (caller 1)[1];
	$file =~ s!.*/!!;
	$msg .= $file . ':';
    } elsif( $debug{L} ) {
	my @caller = (caller 0)[0..2];
	push @caller, (caller 1)[3..5];
	$msg .= "@caller:";
    }
    if( ref $what ) {
	print "$msg ";
	&{$what}( @rest );
    } elsif( $what ) {
	print "$msg $what\n";
    }
    select $oldfh;
    '';
}



=item define I<STRING>, I<EXPR>

=item define I<STRING>

=item define

Defines a macro whose value may be interpolated into bits of plain text in
scalar context.  I<STRING> or C<$_> should be a string consisting of letters,
digits and underscores, which is the name of the macro.  I<EXPR> is the body
of the macro.  If it is a reference to a function the macro interpolation will
call that.  If it is a string-reference the macro is an alias to that macro or
to that Perl-builtin, which doesn't allow a function reference to be taken.
If it is missing, the macro is a soft reference to a Perl-function of the same
name.

If the second argument is a string (should be single-quoted), its variables
will be interpolated at the moment the macro gets called.  The macro arguments
may of course be accessed as C<'... $_[0] ... $_[1] ...'>, but there is a more
comfortable possibility.  The first argument to C<define> may contain
parameter specifications in parentheses after the name.  These are a comma
separated list of scalar variables with optionally a list variable at the end.
Each of these variables may be assigned to, giving the named parameter a
default value.

For styles like C<cpp> which don't allow embedding Perl-expressions into the
document, you can use any one of the following to get a Perl-evaluating macro:

  define PERL => '@_';
  define 'PERL( $eval = $_ )', '$eval';
  define PERL => sub { $_[0] };
  define PERL => sub { print $_[0]; '' };

The first allows multiple arguments, to be separated by C<$">.  The second
gives a Perl-typical default argument of C<$_>.  The third simply evaluates
one argument.  The fourth does the same, but, the value being printed, it will
not be reparsed for further macro-invocations.

=cut

sub define(;$$) {
    my( $macro, $str, $args ) = @_ ? @_ : $_;
    ( $macro, $args ) = split /(?=[^a-zA-Z0-9_])/, $macro, 2
	if my $havestr = (1 < @_);
    debug \$macro => sub {
	print "define $macro" . (($debug{V} || $debug{a}) && $args) .
	    (($debug{V} || $debug{e}) && $havestr ? " -> $str" : ' <-') .
	    "\n";
    };
    $defines .= ($defines && '|') . $macro
	unless $defines{$macro};
    if( ref $str ) {
	$defines{$macro} = $str;
    } elsif( ! $havestr ) {
	$defines{$macro} = $macro;
    } elsif( defined $args ) {
	$args =~ s/^\s*\(\s*(.*)\s*\)\s*$/$1/;
	my @defaults;
	my @args_nodefaults;
	foreach( split /\s*,\s*/, $args ) {
	    push @defaults,
		"$1 = $2 unless " . ($1 =~ /^\s*$/ && "defined ") . "$1;"
		if s/(.+)\s*=\s*(.+)/$1/;
	    push @args_nodefaults, $_;
	}
	if( @args_nodefaults ) {
	    local $" = ',';
	    $args = "my( @args_nodefaults ) = \@_;";
	} else {
	    $args = '';
	}
	if( defined $str ) {
	    $str =~ s/"/\\"/g;
	    $defines{$macro} = _eval qq{sub {
		$args
		@defaults
		"$str"
	    }};
	}
    } elsif( defined $str ) {
	$str =~ s/"/\\"/g;
	$defines{$macro} = _eval qq{sub {
	    "$str"
	}};
    }
    '';
}



=item include I<EXPR>, I<REPEATCOUNT>, I<HUSH>

=item include I<EXPR>, I<REPEATCOUNT>

=item include I<EXPR>

=item include

Includes a document, parsing it as iPerl and merging the result into the
current output.  I<EXPR> works just like in C<open>.  If no filename is given,
reads from C<STDIN>.  If filename is not a full path, then if called from
within a known file, the file is searched in the directory of that document,
else in the current directory.  If it is not found there, the directories in
C<@opt_I> followed by those in C<@include> are searched, unless filename
starts with F<./>.

The second argument may be an integer (often C<1>), meaning to include the
file only if that filename hasn't already been included that many times.
Since this can be fooled by multiple links to the same file, or if you use
chdir, the second argument may also be a reference to an integer (e.g. C<\1>).
In that case the physical identity of the file is used, rather than the
filename.

The third argument, when true, means to continue silently when the file was
not found.

Note that include is simply a Perl function, thus a run-time affair.  This
means that if you define any functions within the included document, they are
not known within the including one.  You can either mark them as such for the
compiler (ampersand and/or parens) or you can place the include statement
within a C<BEGIN {}> block.

=cut

sub include(;$$$) {
    my( $file, $count, $hush ) = @_;
    my $string;
    if( !defined $file or $file eq '-' ) {
	$file = '<STDIN>';
	return _run $cache{$file}
	    if $cache && defined $cache{$file};
	local $/ = undef;
	$string = <STDIN>;
    } else {
	my @include = (@opt_I, @include);
	if( ref $file ) {
	    $file = $$file;
	} elsif( $file =~ /^<?\s*\// ) {
	    goto CHECK;
	} elsif( $file =~ /^<?\s*\.\/|^<\s*&|\|$/ ) {
	    goto READ;
	} else {
	    my $dir;
	    foreach( reverse @documents ) {
		next if /[>|]$/;
		($dir = $_) =~ s|/[^/]*?$||;
		last;
	    }
	    unshift @include, ($dir || '.');
	}
	$file =~ s/^<\s*//;
	foreach( @include ) {
	    $_ .= "/$file";
	    if( -f ) {
		debug p => "Found file $_";
	    } else {
		debug p => "Tried file $_";
		next;
	    }
	    $file = $_;
	    last;
	}
      CHECK:
	my $ref = join ':', (stat $file)[0,1];
	if( ! defined $count ) {
	} elsif( ref $count ) {
	    return unless $$count > $refcount{$ref};
	} elsif( $count ) {
	    return unless $count > $count{$file};
	}
	$refcount{$ref}++;
	$count{$file}++;
	if( $cache ) {
	    $cache{$file} = ''
		if defined $cachetime{$file}
		and $cachetime{$file} < (stat _)[9];
	    $cachetime{$file} = (stat _)[9];
	    return _run $cache{$file}
		if defined $cache{$file};
	}
      READ:
	local $/ = undef;
	local *FILE;
	unless( open FILE, $file ) {
	    if( defined( $hush ) && $hush ) {
		return;
	    } else {
		die "cannot open $file";
	    }
	}
	$string = <FILE>;
	close FILE;
    }
    _run( $cache ?
	  $cache{$file} = _compile $string, $file :
	  _compile $string, $file );
}


=item include_filehandle I<FILEHANDLE>

Likewise, but reads from the I<FILEHANDLE>.

  #! /usr/local/bin/perl
  use Text::iPerl;
  include_filehandle DATA;
  __END__
  Self-parsing iPerl document goes here.

=cut

sub IO::Handle::include_filehandle(*) {
    _run _compile do {{		# 'do' in 5.004 ignores 'local'
	local *FH = $_[0];
	local $/ = undef;
	<FH>;
    }}, '<FILEHANDLE>';
}



=item include_string I<EXPR>

=item include_string

Likewise, but parses I<EXPR> or C<$_> if none.

=cut


sub include_string(;$$) {
    _run _compile @_ ? $_[0] : $_,
	  $_[1] || '<STRING>';
}



=item macro I<STRING>

=item macro

Returns undef or the macro-definition of I<STRING>, either as a
code-reference, or the name as a string if the macro is a soft reference to a
Perl function.  Without an argument returns the list of defined macro-names.

  if( defined macro 'mymacro' ) { ... }
  foreach( macro ) { ... }

=cut

sub macro(;$) {
    if( @_ ) {
	return $defines{$_[0]} if defined $defines{$_[0]};
	undef;
    } else {
	return sort keys %defines;
    }
}



=item return

The normal Perl keyword, returns from a document when used at its top-level,
i.e. outside of functions, macros or macro invocations, save for the m4-style
pseudo-macros.  This means, that the rest of the document is not processed and
output.



=item set_style I<STRING>[, I<ARGUMENT> ...]

=item set_style I<CODEREF>

Set one of the following iPerl-styles.  The various styles are more or less
adapted to various document types.  But of course any style can be used
anywhere.  Sometimes this requires some extra care, for example HTML documents
may contain the sequence C<!E<lt>> which can lead to startling effects when
used with the bang style.

It can sometimes be useful to have two different styles in a document, for
example if you want to do some time-consuming offline treatment in a document
that will nevertheless later be an active web-document.

The macro invocation style is the only one to be immediately effective, being
a runtime affair.  The styles for embedded bits of Perl, being a compiletime
affair, only become effective for the next iPerl-documents to be included.

The mnemonic for the variously used C<{...}> is a Perl block, though here it
is simply a stretch of interpolated Perl code, that does B<not> define a
block.  The mnemonic for C<E<lt>...E<gt>> is a Perl input operator, but
inverted here, since the document reads from Perl code.  I<STRING> may be one
of the following:

=over

=cut


sub set_style($;@) {
    my $orig_style = $style;
    $style = shift;
    $macro_start = $macro_end = '\b';
    $macro_end = '';
    $macro_start_dollar1 = 0;


=item 'bang'

=item 'unix'

Everything on the same line after C<#> is deleted depending on
C<$comment_level>.

Lines starting with a C<!> are bits of Perl.  This reminds of interactive unix
programs which thus allow a shell escape.

Perl within lines, potentially spanning several lines, is enclosed in C<!{>
and C<}!>.  This reminds of Perl blocks, but does not delimit a block.  As a
special case C<!}!> without whitespace is equivalent to C<!{}}!>, i.e. one
closing brace.

Perl values to be printed to the document are enclosed in C<!E<lt>> and
C<E<gt>!>.  This reminds of the Perl read operator, inverted here in that the
document reads from a Perl expression.

Macros may be optionally preceded by C<&>, useful to set them off from
preceding alphanumeric characters.

=cut

    if( $style eq 'bang' or $style eq 'unix' ) {
	$splitter = sub {
	    return $`,  $1,  $2 || $3 || $4,  $',  $&
		if $_[0] =~ /
		    $_[2]\# .* $ $_[3] |
		    !< ([\s\S]*?) >! |
		    !\{ ([\s\S]*?) \}! | !(\})! |
		    $_[1]! (.*) \n?
		/mx;
	    $_[0];
	};
	$macro_start = '&?\b';
    }


=item 'control'

Lines starting with a C<^A> are bits of Perl.  This reminds of the beginning
of the alphabet, hence of the line.

Perl within lines, potentially spanning several lines, is enclosed in C<^B>
and C<^E>.  This reminds of beginning and end.

Perl values to be printed to the document are enclosed in C<^P> and
C<^E>.  This reminds of print and end.

=cut

    elsif( $style eq 'control' ) {
	$splitter = sub {
	    return $`,  $1,  $2 || $3,  $',  $&
		if $_[0] =~ /
		     ([\s\S]*?)  |
		     ([\s\S]*?)  |
		    $_[1] (.*) \n?
		/mx;
	    $_[0];
	};
    }


=item 'cpp'

Everything on the same line after C<//> or from C</*> upto next C<*/> is
deleted depending on C<$comment_level>.

Lines starting with a C<#> are bits of Perl.  They may be continued over
several lines, as long as each line ends with a C<\>.

=cut

    elsif( $style eq 'cpp' ) {
	$splitter = sub {
	    if( $_[0] =~ /
		    $_[2]\/(?:\/.*$ \n? | \*(?:(?!\*\/)[\s\S])*?\*\/$_[3]) |
		    $_[1]^\# ( (?:.*\\\n)* .*) \n?
		/mx )
	    {
		my( $pre, $match, $post, $all ) = ($`,  $1,  $', $&);
		$match =~ s/\\$//mg;
		return $pre,  undef,  $match,  $post, $all;
	    }
	    $_[0];
	};
    }


=item generic => I<COMMENT>, I<BEFOREPRINT>, I<AFTERPRINT>,
I<BEFORE>, I<AFTER>

Arguments are 5 regexps, which may not make backreferences via parentheses.
This allows you to define your own simple style.  Anything matching I<COMMENT>
is simply ignored.  I<BEFOREPRINT> and I<AFTERPRINT> markup a printing bit of
Perl.  And I<BEFORE> and I<AFTER> markup a plain bit of Perl.

=cut

    elsif( $style eq 'generic' ) {
	my @style = @_;
	map { $_ ||= '[^\s\S]' } @style;
	$splitter = sub {
	    return $`,  $1,  $2,  $'
		if $_[0] =~ /
		    $_[2] $style[0] $_[3] |
		    $style[1] ([\s\S]*?) $style[2] |
		    $style[3] ([\s\S]*?) $style[4]
		/mx;
	    $_[0];
	};
    }


=item 'm4'

Perl within lines, potentially spanning several lines, is enclosed in the
pseudo-macro C<perl({> and C<})>.  This reminds of Perl blocks, but does not
delimit a block.  As a special case C<perl(})> without whitespace is
equivalent to C<perl({}})>, i.e. one closing brace.

Perl values to be printed to the document are enclosed in the pseudo-macro
C<perl(E<lt>> and C<E<gt>)>.  This reminds of the Perl read operator, inverted
here in that the document reads from a Perl expression.

Everything from the pseudo-macro C<dnl> through end of line is deleted.

The customary m4 macros C<decr>, C<define> (iPerl semantics), C<defn>,
C<errprint>, C<eval>, C<ifdef>, C<ifelse>, C<include> (iPerl semantics),
C<incr>, C<index>, C<len>, C<maketemp>, C<m4exit>, C<sinclude>, C<substr>,
C<syscmd>, C<sysval>, C<traceoff>, C<traceon>, C<translit> (with an additional
optional 4th argument for the modifiers of tr) and C<undefine> are predefined.

The customary m4 macros C<changecom>, C<changequote>, C<divert>, C<divnum>,
C<dumpdef>, C<m4wrap>, C<popdef>, C<pushdef>, C<shift> and C<undivert> are not
implemented.

No macro expansion takes place after a C<#>.  This could be changed with
C<$macro_start> and friends, but note that the above mentioned pseudo-macros
are already expanded at compile-time.  Changing this within the document would
lead to two different comment-styles being used.

Remember that macro arguments are Perl code, not just bits of quoted or
unquoted string.

=cut

    elsif( $style eq 'm4' ) {
	$splitter = sub {
	    return $` . $1,  $2,  $3 || $4,  $'
		if $_[0] =~ /
		    ^ ([^#\n]*?) \b
			(?:dnl\b.* \n? |
			perl\( (?: < ([\s\S]*?) > |
				\{ ([\s\S]*?) \} | (\}) ) \))
		/mx;
	    $_[0];
	};
	$max_macro_growth = 10000;
	$macro_start = '((?:^|\n)[^#\n]*?)\b';
	$macro_start_dollar1 = 1;
	foreach( qw(define eval include index substr undefine) ) {
	    define;
	}
	define decr => sub { $_[0] - 1 };
	define defn => \&macro;
	define errprint => sub { print STDERR @_ };
	define ifdef => sub { defined macro( $_[0] ) ? $_[1] : $_[2] };
	define ifelse => sub {
	    while( defined( $_[1] ) && $_[1] ) {
		return $_[2] if $_[0] eq $_[1];
		splice @_, 0, 3;
	    }
	    $_[0];
	};
	define incr => sub { $_[0] + 1 };
	define len => \'length';
	define m4exit => \'exit';
	define maketemp => sub { ($_[0] eq 'XXXXX') ? $$ : $_[0] };
	define sinclude => sub { include $_[0], $_[1], 1 };
	define syscmd => sub { local $| = 1; $sysval = system @_; '' };
	define sysval => sub { $sysval / 256 };
	define traceoff => sub {
	    if( @_ ) {
		foreach( @_ ) {
		    delete $trace{$_};
		}
	    } else {
		delete $debug{t};
	    }
	};
	define traceon => sub {
	    if( @_ ) {
		foreach( @_ ) {
		    $trace{$_} = 1;
		}
	    } else {
		$debug{t} = 1;
	    }
	};
	define translit => sub {
	    local $_ = $_[0];
	    _eval "tr/$_[1]/$_[2]/" . (defined( $_[3] ) ? $_[3] : '');
	    $_;
	};
    }


=item pod => I<ARG>

=item 'pod'

This style can do two things with files containing pod (plain old
documentation).  For one thing, if I<ARG> is true, it can eliminate any pod
from document.  It then does nothing else.  This allows pod to reside in any
file.

For another, if I<ARG> is missing or false, the pod is extracted from the
file, processed with embedded Perl, allowing pods to be dynamic and spread
across several files.  The Perl embedded within the pod has nothing to do with
the programme that contains the pod, even if that is a Perl programme.  This
is because, from a pod-point-of-view, everything that is not pod is ignored.

Paragraphs starting with C<=for perl> or multiple paragraphs surrounded by
C<=begin perl> and C<=end perl> contain plain Perl code that can control the
pod.

Perl within paragraphs, is enclosed in C<PE<lt>{> and C<}E<gt>>.  This reminds
of Perl blocks, but does not delimit a block.  As a special case
C<PE<lt>}E<gt>> without whitespace is equivalent to C<PE<lt>{}}E<gt>>,
i.e. one closing brace.

Perl values to be printed to the document are enclosed in C<PE<lt>> and
C<E<gt>>.  This reminds of the Perl read operator, inverted here in that the
document reads from a Perl expression.

C<ME<lt>> and C<E<gt>> delimit a macro call within a paragraph.

=cut

    elsif( $style eq 'pod' ) {
	my( $last_documents, $in_pod );
	$splitter = $_[0] ? sub {
	    return $`,  undef,  undef,  $'
		if $_[0] =~ /
		    (?:\A\n*|\n\n)= [\s\S]*?
		    (\Z|\n\n=cut\b [\s\S]*? (?=\Z|\n\n))
		/mx;
	    $_[0];
	} : sub {
	    if( $last_documents != $documents ) {
		$last_documents = $documents;
		$in_pod = 0;
		$_[0] = "\n\n" . $_[0];
	    } elsif( $in_pod ) {
		return $_[0] unless $_[0] =~ /
		    (?:\n\n)=(cut|for\s+perl)\b ([\s\S]*?) ?(?=\Z|\n\n) |
		    (?:\n\n)=begin\s+perl\b ([\s\S]*?)
			?(?:\Z|\n\n=end\s+perl|(?=\n\n=cut\b)) |
		    P<\{ ([\s\S]*?) \}> | P<(\})> |
		    P< ([\s\S]*?) >
		/mx;
		if( $1 eq 'cut' ) {
		    $in_pod = 0;
		    return $`,  undef,  undef,  $';
		} else {
		    return $`,  $6,  $2 || $3 || $4 || $5 ,  $';
		}
	    }
	    if( $_[0] =~ /(?=\n\n=)/ ) {
		$in_pod = 1;
		return undef,  undef,  undef,  $';
	    }
	    '';
	};
	$macro_start = 'M<';
	$macro_end = '>';
    }


=item 'xml'

=item 'sgml'

Everything from C<E<lt>!--> upto next C<--E<gt>> is deleted depending on
C<$comment_level>.

Bits of Perl are enclosed in C<E<lt>script runat=serverE<gt>> and
C<E<lt>/scriptE<gt>> or C<E<lt>serverE<gt>> and C<E<lt>/serverE<gt>>.
Attributes, such as C<language=Perl> are ignored but recomended to prevent
mistreatment by other parsers.  More general alternate tags are
C<E<lt>perlE<gt>> and C<E<lt>/perlE<gt>>.  As a more convenient (though
probably not XML or SGML compliant) alternative, closer to the other
iPerl-styles, bits of Perl may be enclosed in C<E<lt>{> and C<}E<gt>>.  As a
special case C<E<lt>}E<gt>> without whitespace is equivalent to
C<E<lt>{}}E<gt>>, i.e. one closing brace.  The alternatives are likely not
recognized by WISIWYG-HTML editors, not being proper HTML, and even the server
tag might be a Netscape feature, which other editors cannot handle.  Even the
C<script> tag can be problematic since it may conditionally include one
stretch of text or another, which cannot be done with Javascript, thus
confusing an editor which unconditionally sees both stretches of text.

Perl values to be printed to the document are enclosed in C<&E<lt>> and
C<E<gt>;>.  This reminds of the Perl read operator, inverted here in that the
document reads from a Perl expression.  Alternately, only within C<E<lt>> and
C<E<gt>> (actually C<E<lt>> is not checked for, due to the forward looking
nature of the parser, but should anyway be present before any C<E<gt>>), Perl
values to be printed to the document are enclosed in a pair of C<`>.  When
this is not followed by a C<=> the result is surrounded with double quotes.

Entities (iPerl macros) are enclosed in C<&> and C<;>.  If the enclosed text
is not a defined macro, it is left as an XML entity.

=cut

    elsif( $style eq 'xml' or $style eq 'sgml' ) {
	$splitter = sub {
	    return $`,  defined( $1 ) ? $1 :
		($2 && ($3 ? "$2, '$3'" : "'\"', $2, '\"'")),
		$4 || $5 || $6 || $7 || $8,  $',  $&
		if $_[0] =~ /
		    $_[2]<!--(?:(?!-->)[\s\S])*?-->$_[3] |
		    &<([\s\S]*?)>; |
		    `([^<>]+?)`(\s*=)?(?=[^<>]*>) |
		    <script\s[^>]*runat\s*=\s*[\'\"]?server\b.*?> ([\s\S]*?)
			<\/script> |
		    <server\b.*?> ([\s\S]*?) <\/server> |
		    <perl\b.*?> ([\s\S]*?) <\/perl> |
		    <\{ ([\s\S]*?) \}> | <(\})>
		/mix;
	    $_[0];
	};
	$macro_start = '&';
	$macro_end = ';';
    }


=item I<CODEREF>

B<NOTE: Since the parsing of a document has to be made more efficient, the way
this I<CODEREF> works will be totally changed in the future.>

Sets a function and returns the old one, which may have been a builtin one.

The function gets four arguments, 0) a string containing the yet unparsed
rest of the document, 1) a subregexp to match a beginning of line, 2) a
subregexp to put before a comment matcher and 3) a subregexp to put after a
comment matcher.  The regexps are only relevant if your style cares about
beginnings of line or comments.  The comment regexps are provided depending on
C<$comment_level>.  Regexps 1) and 2) also depend on whether the last match
(optional 5th return value, see below) ended with a newline.  Otherwise the
beginning of string will not match a beginning of line.

It gets called repeatedly during parsing of a document and should return a
list of 4 or 5 elements: 0) leading plain text, 1) printing Perl expr, 2)
plain Perl, 3) the rest to be treated next time and optionally 4) the matched
string or at least its last character.  Those elements not matching anything
should be C<undef>, epsecially 1) since if it is the empty string, C<$_> will
get printed at that point.  When it returns undef as the rest, it won't get
called again for that document.

=back

=cut

    elsif( 'CODE' eq ref $style ) {
	my $old = $splitter;
	$splitter = $style;
	$style = '<CODEREF>';
	$old;
    } else {
	die "unknown style '$style'";
    }
    '';
}



=item undefine I<EXPR>

=item undefine

Removes the definedness of I<EXPR> or C<$_>.

=back

=cut

sub undefine(;$) {
    my( $macro ) = @_;
    $macro ||= $_;
    debug \$macro => "undefine $macro";
    $defines =
	join '|',
	grep !/^$macro$/,
	split /\|/, $defines;
    delete $defines{$macro};
    '';
}

1;

__END__





=head1 VARIABLES

=over


=item @autostyle_by_contents

Hash-like list of regexps to match against document to determine the mode to
use when C<$style> starts with C<'auto'>.  Unlike a hash, this list is
processed sequentially until a match is found.


=item @autostyle_by_name

Hash-like list of regexps to match against filenames (actually against
C<$documents[-1]>) to determine the mode to use when C<$style> starts with
C<'auto'>.  Unlike a hash, this list is processed sequentially until a match is
found.


=item $cache

Make C<include> cache the compiled form of the document for quick reuse when
called again for the same file if C<true>.

Due to a Perl-bug with nested closures, source code, rather than byte code, is
cached when it contains the word sub.


=item $comment_level

What to do with comments in a document when compiling it.  Concerns comments
in the host part (like C</* ... */> in style cpp), not Perl comments.  Values
are:

B<C<0>>:  Do not touch comments in document.

B<C<1>>:  Remove comments in document, when they go exactly from a beginning of
line to an end of line.

B<C<2>>:  Like B<C<1>>, but there may be whitespace before the comment start or
after the comment end.

B<C<3>>:  Remove all comments in document.

This may be hairy, since iPerl has no knowledge of the host document's syntax
and will remove everything that looks like a comment.  In Perl or Korn shell,
for example, C<#> does not start a comment in all syntactic contexts.  Or a C
programme might contain C</* ... */> within a string.  So this variable
defaults to C<1>, which is fairly safe.


=item %debug

Perform debugging for all flags associated with a true value:

  c   generated Perl code
  E   show intern evaluations
  F   say current input file fullname
  f   say current input file basename
  i   say calls to include-functions
  L   say location where debugger was called internally
  p   show searching files in @include
  t   trace for all macro calls, not only those in %trace
  V   automatically implies any other letter

The following flags are only relevant if C<t> is set or for macros in C<%trace>:

  a   show actual arguments
  e   show expansion

You can add any other letter if you intend to use it in your own calls to
C<debug>.


=item $documents

Incremented for each document included.


=item @documents

Contains the list of all nested includes currently active, innermost last.
Where a filename is not known for the document, contains the strings
C<'E<lt>FILEHANDLEE<gt>'>, C<'E<lt>STDINE<gt>'> or C<'E<lt>STRINGE<gt>'>.


=item @include

Second list of directories where C<include> searches for files not found in
the same directory as the file where C<include> was called.  Defaults to
F</usr/include> followed by the contents of C<@INC>.


=item $joiner

Regexp (defaults to C<\;>) to match what must be at the beginning or end of a
bit of Perl to suppress the semicolon at that point.


=item $macro_end

=item $macro_name_end

=item $macro_start

=item $macro_start_dollar1

C<$macro_start>, C<$macro_name_end> and C<$macro_end> are regexps describing
the syntactic sugar which is eliminated around macro invocations.  If, as in
style m4, C<$macro_start> has to look backwards, it should contain one
paren-pair matching the portion of text not to discard, and
C<$macro_start_dollar1> should then be true.  These change every time a
C<set_style> is called explicitly or implicitly.

If C<$macro_start> and C<$macro_name_end> don't contain the regexp C<\b>,
macros will be found in the middle of words.  Or you can use the latter
variable to allow whitespace before the argument list, or prevent it
alltogether with a negative lookahead for a parenthesis.


=item $max_macro_growth

One bit of plain text may grow by no more than this factor through macro
expansions.


=item $max_macro_expansions

In one bit of plain text no more than this many macro expansions may occur.


=item @opt_I

First list of directories where C<include> searches for files not found in the
same directory as the file where C<include> was called.  This is not set by
C<Text::iPerl> but is used if set outside.  The strange name comes from the
fact that C<iperl> like the various invokers of the C preprocessor and some m4
implementations use the C<-I> option for this.


=item $preoutput_handler

B<Not yet implemented.>

Coderef called and reset every time iPerl wants to output a bit of plain text.
Will normally be set by programmes to offer some initialization that can be
overridden by the beginning of a document.


=item $printfer

Regexp (defaults to C<%>) to match what must be at the beginning of a printing
bit of Perl to use printf instead of print.


=item $style

This is the name of the style currently in effect.  If this starts with
C<'auto'>, the style used for an included document is determined in three steps
as follows.  This variable is then set to C<auto: I<style>>.

=over

=item Style specified in the file

This is identical to Emacs' local variables specification inside a file. There
are two possibilities (here shown for style bang): On the first line, or on
the second if the first line is a shebang magic number (C<#! I<interpreter>>),
with possibly other semicolon separated variables for use by Emacs:

  -*- iPerl-style: "bang" -*-

Or, within the last 3000 characters of the document and not followed by a page
break (C<^L>), C</*> and C<*/> being examples of optional comment delimiters,
which, if present, must however be identical on all lines, with possibly other
specification-lines only used by Emacs:

  /* Local Variables: */
  /* iPerl-style: "bang" */
  /* End: */


The style must be given as a double-quoted literal string.  This can appear
anywhere, i.e. in a bit of Perl as a comment or string or in the host
document.  If neither of these appear the next step is tried.

=item Document-name matched against C<@autostyle_by_name>

If no match is found, the next step is tried.

=item Document-contents matched against C<@autostyle_by_contents>

If no match is found, the style of the including document is maintained.  If
there is none, we die.

=back


=item @_Text_iPerl

Closure needed for internal purposes visible within your document.  The
effects of changing this variable are not defined.


=item %trace

Debug macro operations for all macros who's name is associated with a true
value, irrespective of the flags in C<%debug>.


=back


=head1 SEE ALSO

L<iperl>, L<web-iPerl>, L<iPerl.el>, L<perl>, http://beam.to/iPerl/
