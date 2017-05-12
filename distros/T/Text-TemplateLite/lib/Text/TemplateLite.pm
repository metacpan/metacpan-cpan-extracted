package Text::TemplateLite;

use 5.006;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);
use Text::TemplateLite::Renderer;

=head1 NAME

Text::TemplateLite - Pure-Perl text templates with bare-bones syntax,
compact size, and limitable resource usage

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Text::TemplateLite;

    my $tpl = Text::TemplateLite->new;

    $tpl->set('Hello, <<$who>>');
    print $tpl->render({ who => 'world' })->result;
    # Generates "Hello, world"

    my $rdr = $tpl->new_renderer;
    print $rdr->render({ who => 'universe' })->result;
    # Generates "Hello, universe" with a configurable and
    # reusable renderer (see Text::TemplateLite::Renderer)

=head1 DESCRIPTION

=head2 Overview

Text::TemplateLite is intended primarily for "string-sized" templating
(e.g. for message localization rather than entire "pages") using compact
(terse?) templates with a (relatively) simple syntax.

It is anticipated that templates may (at least sometimes) be entered or
managed by users whose skill set does not include "Perl programmer"
(perhaps a web site administrator, translator, or non-Perl programmer).

Basic length and execution limits provide a measure of protection against
accidental or malicious time- and/or space-based resource attacks. These
are managed by the rendering companion class,
L<Text::TemplateLite::Renderer>.

By design, only basic functionality is included in this module. Use parts
or all of the L<Text::TemplateLite::Standard> function library and/or
create your own custom library to extend its capabilities.

=head2 Syntax

A template consists of literal text and template code. Any text between
"<<" and ">>" that does not contain "<<" or ">>" is treated as template
code. Everything else is literal text.

Template code can contain sequences in any combination of the following:

=over

=item Comments

Anything from "/*" to the closest "*/" is ignored and does not count
as a step (see L<"Steps">).

=item String Literals

To include literal text within code text, surround the text with single
quotes (') or double quotes ("). You can "escape" either kind of quote
or < or > in either kind of string by preceding it with a backslash
(\', \", \<, or \>). Use '<\<' or '>\>' to generate "<<" or ">>" within
code text.

No variable substitution is performed within either kind of string literal.

=item Numeric Literals

Numeric literals consist of an optional minus sign and one or more
digits, optionally followed by a decimal point and additional digits.

=item Variable Substitutions

A dollar sign ($) followed by a name consisting of one or more letters,
digits, underscores (_), and/or non-initial periods (.) will be replaced
by the corresponding value from the variables supplied either at rendering
time or set during template execution.

Variables can also store nested templates. Substituting a variable
containing a nested template executes the nested template. These templates
can be passed parameters using the same syntax as function calls. The
parameters will appear in the nested template as template variables "$1",
"$2", etc. Parameter "$0" will contain the number of parameters.

Parameters after a non-template variable are ignored, unevaluated.

    $foo /* variable or nested template without parameters */
    "$foo is " $foo /* only the second $foo is substituted */
    $foo('hey', 'there') /* nested template(?) with parameters */

See L<Text::TemplateLite::Standard/"TEMPLATE FUNCTIONS"> for information
on creating nested templates.

In future releases, periods in variable names may have structural meaning
(e.g. to support lists or maps). Do not write templates that expect "$a"
to be unrelated to "$a.b" or "$a.5", for example. For now, however, periods
are just part of the name.

=item Function And External Template Calls

Any other combination of alpha-numeric characters, or combination of symbols
other than parentheses or comma, are treated as the name of a function or
external template call. Either may optionally be passed a list of zero or
more parameters, surrounded by parentheses and separated by commas.

Parameters to external templates should be provided in "name, value" pairs.

    cr nl /* call "cr" and "nl" without parameters */
    foo('hey', 'there') /* pass foo two strings (or hey=there) */

See L<Text::TemplateLite::Standard/"TEMPLATE FUNCTIONS"> for some related
functions.

Calls to unregistered names will instead call a definition with a zero-length
name, if registered, or L<"undef_call($name, $args, $renderer)"> otherwise.

=back

=head2 Steps

Each element (literal, substitution, call, etc.) evaluated during template
execution is counted as a "step". For example:

    $=('a', 2)     /*  3 steps: $=, 'a', and 2 */
    ??(=($a, 1),   /* +4 steps: ??, =, $a, and 1 */
      '$a is 1',   /*  1 step not eval'd/counted (= was false) */
      =($a, 2),    /* +3 steps: =, $a, 2 */
      '$a is 2',   /* +1 step: '$a is 2' */
      'other')     /*  1 step not eval'd/counted (not reached) */
    /* renders '$a is 2' in 11 steps */

    ?*(<($a, 4), 'loop' $=('a', +($a, 1)))
    /* 1 step: ?*
      +3 steps: <, $a, 4 (assuming $a is 2 from above)
      +6 steps: 'loop', $=, 'a', +, $a, 1 ($a becomes 3)
      +3 steps: <, $a, 4
      +6 steps: 'loop', $=, 'a', +, $a, 1 ($a becomes 4)
      +3 steps: <, $a, 4 (now false, so loop stops)
      renders 'looploop' in 22 steps */

=head1 USER METHODS

This section describes methods for normal usage.

=head2 new( )

This returns a new Text::TemplateLite template engine.

=cut

sub new {
    my ($class) = @_;

    return bless {
    }, $class;
}

=head2 register($name, $definition)

Register a function (coderef definition) or an external template
(Text::TemplateLite definition).

    $ttl->register('my_function', sub {
      my ($name, $args, $renderer) = @_;
      "You called function $name." });

    my $other_ttl = Text::TemplateLite->new();
    $other_ttl->set('You called an external template.');
    $ttl->register('external_tpl', $other_ttl);

If you register a definition with a zero-length name, it will be called
in place of any call to an undefined function or external template instead
of using the default undefined-call handler,
L<"undef_call($name, $args, $renderer)">.

Library functions (registered as coderefs) are passed three parameters:

=over

=item $name

This is the name of the function as it was invoked from the template.

=item $args

This is an arrayref of code sequences for any parameters passed from the
template. See L<"execute_sequence($code, $renderer)"> and
L<"execute_each($list, $renderer)">.

=item $renderer

This is the instance of L<Text::TemplateLite::Renderer> that is managing
rendering of the template.

=back

=cut

sub register {
    my ($self, $name, $def) = @_;

    $self->{defs}{$name} = $def;
    return $self;
}

=head2 unregister($name)

Unregister a function or external template definition.

=cut

sub unregister {
    my ($self, $name) = @_;

    delete($self->{defs}{$name});
    return $self;
}

=head2 set($string)

Set or change the template string (see L<"Syntax">) and return the
template object.

=cut

sub set {
    my ($self, $template) = @_;

    delete($self->{code});

    my @parts = split(/<<(?!<)((?:[^<>]|<[^<]|>[^>])*)>>/s, $template);
    my @code;

    # Template "text<<code>>text<<code>>..." => (text, code, text, code, ...)
    for (my $literal = 1; @parts; $literal = !$literal) {
	if (length(my $part = shift(@parts))) {
	    if ($literal) {
		# Even elements are literal text.
		push(@code, [ "''" => $part ]);
	    } else {
		# Odd elements are template code text.
		my @tokens = $self->get_tokens($part);
		push(@code, $self->parse_list(\@tokens, []));
	    }
	}
    }

    $self->{code} = \@code;

    return $self;
}

=head2 new_renderer( )

Returns a new renderer companion object assigned to this template
engine. See L<Text::TemplateLite::Renderer>.

=cut

sub new_renderer {
    return Text::TemplateLite::Renderer->new->template(shift);
}

=head2 render(\%variables)

Create a new renderer via L<"new_renderer( )">, render the template,
and return the renderer (not the result).

=cut

sub render {
    my $self = shift;

    return $self->new_renderer->render(@_);
}

=head1 AUTHOR METHODS

This section describes methods generally only used by library function
authors.

=head2 execute_sequence($code, $renderer)

Execute the code step(s), if any, in the sequence $code using renderer
$renderer.

A code sequence looks like:

    [ \@step1code, \@step2code, ... ]

This method is useful for "progressive" evaluation of individual parameters to
functions. It is also used to execute the code resulting from each section
of template code in a template.

Execution may stop or step results may be truncated in response to
exceeded execution limits or a stop set in the rendering information.

A sequence consisting of a single function call can return multiple values
if execute_sequence is called in array context. Otherwise, the concatenation
of step values is returned.

=cut

sub execute_sequence {
    my ($self, $code, $renderer) = @_;

    # Return nothing on empty sequence or rendering stop.
    return wantarray? (): ''
      if !$code || !@$code || $renderer->info->{stop};

    my $max_len = $renderer->limit('step_length');
    my @parts;

    if (wantarray && @$code == 1) {
	# A one-step sequence may return multiple values.
	@parts = $self->execute_step($code->[0], $renderer);

	if (defined($max_len)) {
	    # Enforce the step-length limit value-by-value.
	    foreach (@parts) {
		if (length > $max_len) {
		    $_ = substr($_, 0, $max_len);
		    $renderer->exceeded_limits('step_length');
		}
	    }
	}
	return @parts;
    }

    # Combine all the parts of a multi-step sequence into a single value.
    # The result must not exceed the step-length limit.
    foreach (@$code) {
	my $part = join('', $self->execute_step($_, $renderer));

	if (defined($max_len)) {
	    # Enforce the length limit for the entire sequence.
	    my $part_len = length($part);
	    if ($part_len > $max_len) {
		push(@parts, substr($part, 0, $max_len));
		$renderer->exceeded_limits('step_length');
		last;
	    }
	    $max_len -= $part_len;
	}

	push(@parts, $part);
    }

    return join('', @parts);
}

=head2 execute_each($list, $renderer)

Execute an arrayref of code sequences and return a corresponding array
of results. This is typically used by library functions to "bulk evaluate"
their list of call parameters.

    $ttl->register('echo', sub {
	my ($name, $args, $renderer) = @_;

	"$name(" . join(', ', $renderer->execute_each($args))
	  . ")";
    });
    $ttl->set(q{<<echo('hello', 'world')>>});
    $ttl->render; # renders "echo(hello, world)"

    $ttl->register('uses2', sub {
	my ($name, $args, $renderer) = @_;

	join('', $renderer->template->execute_each(@{$args}[0, 1]));
    });
    $ttl->set(q{<<uses2('just','these','not','those'>>});
    $ttl->render; # renders "justthese" using 3 steps (not 5)

=cut

sub execute_each {
    my ($self, $list, $renderer) = @_;

    return map($self->execute_sequence($_, $renderer), @$list);
}

=head2 execute_step($code, $renderer)

Execute one code step $code with renderer $renderer unless the total_steps
limit has been reached, in which case the total_steps limit is marked
exceeded.

=cut

sub execute_step {
    my $self = shift;
    my ($code, $renderer) = @_;

    # This is a hack in case someone wants to sub-class step execution
    return $renderer->step? $self->_execute_step(@_): ();
}

=head2 _execute_step($code, $renderer)

This method does the "heavy lifting" after execute_step checks resource
usage.

The step $code can be one of the following:

    [ "''" => $literal ]
    [ '$' => $var_name ]
    [ '()' => $fn_or_tpl [ \@a1codeseq, \@a2codeseq, ... ] ]

A variable substitution is executed as a nested template if it's value
looks like this:

    [ '<>' => \@code_sequence ]

=cut

sub _execute_step {
    my ($self, $code, $renderer) = @_;
    my $type = $code->[0];
    my $value;

    # Figure out what to do in this step...

    # [ "''" => $string ] : Return a literal.
    if ($type eq "''") {
	return $code->[1];
    }

    # Note: The only currently supported array values are internal
    # templates. They look like this: [ '<>' => \@code_sequence ]
    # Other array values are ignored.

    # [ '$' => $name ] : Interpolate a variable (possibly an internal template).
    if ($type eq '$') {
	$value = $renderer->vars->{$code->[1]};

	# Check for an internal template.
	return ((@$value && $value->[0] eq '<>')?
	  $self->execute_template($value->[1], [], $renderer): '')
	  if ref($value) eq 'ARRAY';

	# Ordinary variable substitution.
	return defined($value)? $value: '';
    }

    # [ '()' => $name, [ @arg_code_sequences ] ] :
    # Call a function or a template (possibly with parameters).
    if ($type eq '()') {
	my $name = $code->[1];

	if ($name =~ /^\$([a-zA-Z0-9_\.]+)$/) {
	    $value = $renderer->vars->{$1};

	    if (ref($value) eq 'ARRAY') {
		return ((@$value && $value->[0] eq '<>')?
		  $self->execute_template($value->[1], $code->[2], $renderer):
		  ());
	    }

	    # Ignore any call parameters and revert to plain variable
	    # substitution.
	    return defined($value)? $value: '';
	}

	$value = $self->{defs}{$name};

	# Call an external template's renderer if available.
	return $renderer->render_external($value,
	  { $self->execute_each($code->[2], $renderer) })->result
	  if blessed($value) && $value->can('render');

	# Call a registered function (or an undefined-call handler).
	unless (ref($value) eq 'CODE') {
	    $value = $self->{defs}{''};
	    $value = \&undef_call unless ref($value) eq 'CODE';
	}
	return &$value($name, $code->[2], $renderer);
    }

    croak "Unrecognized " . blessed($self) . " step-type: $type";
}

=head2 execute($renderer)

Execute the main template code with renderer $renderer and return the result.

You shouldn't need to use this method unless you're building or sub-classing
a renderer.

=cut

sub execute {
    my ($self, $renderer) = @_;

    return scalar($self->execute_sequence($self->{code}, $renderer));
}

=head2 execute_template($code, $args, $renderer)

This executes the code from a nested template after saving any
previous numeric variables and then setting $0 and parameters $1 through
$I<n>.

Any previous numeric variables are restored before returning.

You shouldn't need this method except possibly if you're extending
nested template functionality in some way.

=cut

sub execute_template {
    my ($self, $code, $args, $renderer) = @_;
    my (%save_vars, $vars, $result);

    # Save and remove any previously existing numbered parameters.
    $vars = $renderer->vars;
    $save_vars{$_} = delete($vars->{$_}) foreach (grep(/^\d+$/, keys(%$vars)));

    # Save arguments as numbered parameters $1..$n.
    # Set $0 to the number of arguments.
    $vars->{0} = @$args;
    for (my $i = 0; $i < @$args; ++$i) {
	$vars->{$i + 1} = $self->execute_sequence($args->[$i], $renderer);
    }

    $result = $self->execute_sequence($code, $renderer);

    # Remove current numbered parameters and restore anything we removed.
    delete($vars->{$_}) foreach grep(/^\d+$/, keys(%$vars));
    @$vars{keys(%save_vars)} = values(%save_vars);

    return $result;
}

=head2 undef_call($name, $args, $renderer)

This function is the default undefined-call handler called by the
L<"_execute_step($code, $renderer)"> method if no zero-length name is
currently registered.

It increments the C<undef_calls> count in the rendering information and
returns no value.

=cut

sub undef_call {
    my ($name, $args, $renderer) = @_;

    ++$renderer->info->{undef_calls};
    return ();
}

=head1 PARSING METHODS

These methods are used for parsing. If you extend these in a sub-class it's
likely to get ugly pretty quickly.

=head2 get_tokens($text)

Split template code text into tokens and return them as a list.

=cut

sub get_tokens {
    my ($self, $text) = @_;

    return grep(!/^\s*$/, split(
      /(
      \/\*.*?\*\/	# \/* comment *\/
      |
      '(?:\\'|[^'])*'	# 'string'
      |
      "(?:\\"|[^"])*"	# "string"
      |
      \$[a-zA-Z0-9_][a-zA-Z0-9_\.]*	# $vari.able
      |
      [a-zA-Z_][a-zA-Z0-9_]*	# alpha-numeric function
      |
      -?\d+(?:\.\d*)?	# integer or floating numeric literal
      |
      [(),]		# (parameter, lists)
      |
      \s+
      )/x,
      $text));
}

=head2 parse_list(\@tokens, \@stops)

Parse a block of code from the token list up to one of the stop
symbols. This might be an entire code segment or parts of a call's
parameter list. The code tree is returned.

=cut

sub parse_list {
    my ($self, $tokens, $stops) = @_;
    my (@code, $token);

    while (@$tokens) {
	$token = shift(@$tokens);

	# Remove comments
	next if $token =~ /^\/\*.*\*\/$/s;

	# String literals
	if ($token =~ /^'(.*)'$/s || $token =~ /^"(.*)"$/s) {
	    push(@code, [ "''" => $self->unescape($1) ]);
	    next;
	}

	# Numeric literals
	if ($token =~ /^-?\d+(?:\.\d*)?$/) {
	    push(@code, [ "''" => $token ]);
	    next;
	}

	# Variables or internal template calls
	if ($token =~ /^\$([a-zA-Z0-9_]+)$/) {
	    if (@$tokens && $tokens->[0] eq '(') {
		push(@code, $self->parse_call($token, $tokens));
	    } else {
		push(@code, [ '$' => $1 ]);
	    }
	    next;
	}

	# Check stop list
	foreach (@$stops) {
	    if ($token eq $_) {
		unshift(@$tokens, $token);
		return @code;
	    }
	}

	# Function or external template call, with or without parameters
	push(@code, $self->parse_call($token, $tokens));
    }

    return @code;
}

=head2 parse_call($name, $tokens)

Parse a parameter list if one follows in the token stream and return the
code tree for a call to the function or template in $name.

=cut

sub parse_call {
    my ($self, $name, $tokens) = @_;
    my (@args, $token);

    if (@$tokens && $tokens->[0] eq '(') {
	shift(@$tokens);
	while (@$tokens) {
	    $token = $tokens->[0];
	    shift(@$tokens) if $token eq ',' || $token eq ')';
	    last if $token eq ')';

	    if ($token ne ',') {
		# The argument continues to the next ',' or ')'.
		my @code = $self->parse_list($tokens, [',', ')']);
		push(@args, \@code) if @code;
	    }
	}
    }

    # [ '()' => $name, [ \@arg0_code_seq, \@arg1_code_seq, ... ] ]
    return [ '()' => $name, \@args ];
}

=head2 unescape($string)

Un-escape backslashed characters for string literals.

=cut

sub unescape {
    my ($self, $string) = @_;

    $string =~ s/\\(.)/$1/g;
    return $string;
}

=head1 AUTHOR

Brian Katzung, C<< <briank at kappacs.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-templatelite at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-TemplateLite>. I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::TemplateLite

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-TemplateLite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-TemplateLite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-TemplateLite>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-TemplateLite/>

=back

=head1 SEE ALSO

L<Text::TemplateLite::Renderer> (the companion class to
Text::TemplateLite for rendering management) and
L<Text::TemplateLite::Standard> (for standard library functions,
with examples)

L<Mason> ("powerful, high-performance templating for web and beyond")

L<Text::Template> (an alternative template system based on embedding
Perl code in templates)

L<Template::ToolKit> (an alternative template system [based on "including
the kitchen sink"])

L<http://illusori.co.uk/blog/categories/template-roundup/> for a
comparison of template modules

=head2 EVEN MORE TEMPLATE MODULES

L<Bricklayer::Templater>,
L<dTemplate>,
L<HTML::Macro>,
L<Mojo::Template>,
L<NTS::Template>,
L<Parse::Template>,
L<Ravenel>,
L<Solution>,
L<Template::Alloy>,
L<Template::Like>,
L<Template::Object>,
L<Template::Recall>,
L<Template::Replace>,
L<Template::Sandbox>,
L<Template::Tiny>,
L<Tenjin>,
L<Text::ClearSilver>,
L<Text::Clevery>,
L<Text::FillIn>,
L<Text::Macro>,
L<Text::Macros>,
L<Text::Merge>,
L<Text::MicroMason>,
L<Text::Printf>,
L<Text::ScriptTemplate>,
L<Text::SimpleTemplate>,
L<Text::TagTemplate>,
L<Text::Templar>,
L<Text::Template::Simple>
L<Text::Templet>,
L<Text::Tmpl>,
L<Text::Xslate>

... and probably some I missed.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Katzung.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Text::TemplateLite

