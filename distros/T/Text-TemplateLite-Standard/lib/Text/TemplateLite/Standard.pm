package Text::TemplateLite::Standard;

use 5.006;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

=head1 NAME

Text::TemplateLite::Standard - Standard function library for templates
using Text::TemplateLite

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

our %map = (

    # Conditional and logical

    '?' => \&fn_ifeach,
    ifea => \&fn_ifeach,
    '??' => \&fn_ifelse,
    ifel => \&fn_ifelse,

    ':conditional' => [ qw/ ? ifea ?? ifel / ],

    '&&' => \&fn_log_and,
    '||' => \&fn_log_or,
    '!' => \&fn_log_not,

    ':logical' => [ qw/ && || ! / ],

    # Iteration

    '?*' => \&fn_test_rpt, # test/execute/repeat (like while)
    wh => \&fn_test_rpt,
    '*?' => \&fn_test_rpt, # execute/test/repeat (like do-while)
    dowh => \&fn_test_rpt,

    ':iteration' => [ qw/ ?* wh *? dowh / ],

    # Character/string

    cr => sub { "\r"; },
    gg => sub { ">>"; },
    ht => sub { "\t"; },
    lf => sub { "\n"; },
    ll => sub { "<<"; },
    nl => sub { "\n"; },
    sp => sub { " "; },

    ':character' => [ qw/ cr gg ht lf ll nl sp / ],

    '$;' => \&fn_join,
    join => \&fn_join,
    '$;;' => \&fn_join4,
    join4 => \&fn_join4,
    len => \&fn_length,
    '$/' => \&fn_split,
    split => \&fn_split,
    '$-' => \&fn_substr,
    substr => \&fn_substr,
    trim => \&fn_trim,

    x => \&fn_str_rpt,

    cmp => \&fn_scmp,
    eq => \&fn_seq,
    ge => \&fn_sge,
    gt => \&fn_sgt,
    le => \&fn_sle,
    lt => \&fn_slt,
    ne => \&fn_sne,

    ':string' => [ qw{ $; join $;; join4 len $/ split $- substr trim
      cmp eq ge gt le lt ne } ],

    # Numeric

    '+' => \&fn_add,
    '-' => \&fn_neg_sub,
    '*' => \&fn_mul,
    '/' => \&fn_div,
    '%' => \&fn_mod,

    int => \&fn_int,
    max => \&fn_max,
    min => \&fn_min,

    '<=>' => \&fn_ncmp,
    '=' => \&fn_neq,
    '>=' => \&fn_nge,
    '>' => \&fn_ngt,
    '<=' => \&fn_nle,
    '<' => \&fn_nlt,
    '!=' => \&fn_nne,

    '&' => \&fn_bin_and,
    '|' => \&fn_bin_or,
    '^' => \&fn_bin_xor,
    '~' => \&fn_complement,

    ':numeric' => [ qw{ + - * / % int max min <=> = >= > <= < != / } ],
    ':bitwise' => [ qw/ & | ^ ~ / ],

    # Template function

    tpl => \&fn_set_template,
    '<$>' => \&fn_ext_equal,

    ':template' => [ qw/ tpl <$> / ],

    # Miscellaneous

    '$=' => \&fn_var_equal,
    void => \&fn_void,

    ':misc' => [ qw/ $= void / ],
    ':miscellaneous' => ':misc',

    # More groups

    ':basic' => [ qw/ :conditional :logical :character :string
      :numeric :bitwise :misc / ],

    ':all' => [ qw/ :basic :iteration x :template / ],

);

=head1 SYNOPSIS

    use Text::TemplateLite;
    use Text::TemplateLite::Standard;

    my $ttl = Text::TemplateLite->new;

    # Register basic functions
    Text::TemplateLite::Standard::register($ttl, ':basic');

    # Register all functions
    Text::TemplateLite::Standard::register($ttl, ':all');

    # Register specific functions
    Text::TemplateLite::Standard::register($ttl, @list);

=head1 DESCRIPTION

This module provides a library of standard functions for templates using
Text::TemplateLite.

=head1 PERL FUNCTIONS

The functions in this section can be called from Perl code. The other
sections describe functions that can be added to and called from
L<Text::TemplateLite> template engines.

=head2 register($template, @list)

This registers the specified functions or function-group tags with the
specified template engine. It returns the template engine.

The template engine must respond to the method
L<"register($name, $definition)">, where C<$definition> is a coderef
expecting three parameters: the name of the function as called from
the template, an arrayref of parameter code sequences, and an object
instance compatible with L<Text::TemplateLite::Renderer>.

=cut

sub register {
    my ($ttl, @list) = @_;
    my ($mapping, $type);

    foreach (@list) {
	$type = ref($mapping = $map{$_});

	if ($type eq 'CODE') {
	    $ttl->register($_, $mapping);
	} elsif ($type eq 'ARRAY') {
	    register($ttl, @$mapping);
	}
    }

    return $ttl;
}

=head2 get_numbers($args, $renderer)

This is a helper function to evaluate and return parameters as
numbers. (Non-numbers are returned as 0.)

=cut

sub get_numbers {
    my ($args, $renderer) = @_;
    my @args = $renderer->execute_each($args);

    foreach (@args) {
	$_ = 0 unless looks_like_number($_);
    }

    return @args;
}

=head1 FUNCTION GROUP TAGS

Use these tags to conveniently register groups of related functions.

=over

=item :logical

&&, !!, and !

=item :conditional

?, ifea, ??, and ifel

=item :iteration

?*, wh, *?, and dowh

=item :character

cr ("\r"), gg (">>"), ht ("\t"), lf ("\n"), ll ("<<"), nl ("\n"), and sp (" ")

=item :string

$;, join, $;;, join4, len, $-, substr,
cmp, eq, ge, gt, le, lt, and ne

=item :numeric

+, -, *, /, %, int, max, min,
<=>, =, >=, >, <=, <, and !=

=item :bitwise

&, |, and !

=item :template

tpl, <$>

=item :misc or :miscellaneous

$=, void

=item :basic

:conditional, :logical, :character, :string, :numeric,
:bitwise, and :misc

=item :all

:basic, x, :iteration, and :template

=back

=head1 LOGICAL FUNCTIONS

=head2 &&(condition, ...)

This function, "logical and", evaluates each condition in turn. If any
condition is empty or zero, evaluation stops and "0" is returned. If
all conditions are true, "1" is returned.

=cut

sub fn_log_and {
    my ($name, $args, $renderer) = @_;
    my $value;

    foreach (@$args) {
	$value = $renderer->execute_sequence($_);
	return 0 unless length($value) && $value ne '0';
    }

    return 1;
}

=head2 ||(condition, ...)

This function, "logical or", evaluates each condition in turn. If any
condition is non-empty and non-zero, evaluation stops and "1" is
returned. If all conditions are false, "0" is returned.

=cut

sub fn_log_or {
    my ($name, $args, $renderer) = @_;
    my $value;

    foreach (@$args) {
	$value = $renderer->execute_sequence($_);
	return 1 if length($value) && $value ne '0';
    }

    return 0;
}

=head2 !(condition)

This function, "logical not", evaluates the condition. If it is non-empty
and non-zero, the result is "0". Otherwise, the result is "1".

=cut

sub fn_log_not {
    my ($name, $args, $renderer) = @_;
    my $value = $renderer->execute_sequence($args->[0]);

    return ((length($value) && $value ne '0')? 0: 1);
}

=head1 CONDITIONAL FUNCTIONS

=head2 ?(expression, ...)

=head2 ifea(expression, ...)

This function, "if each", returns each non-empty expression. Expressions
may be multi-valued.

    tpl('dear', 'Dear ' $;;(' and ', ', ', ', ', ', and ',
      ?($1, $2, $3, $4, $5, $6, $7, $8, $9)) ',')
    $dear('Dick', 'Jane') /* Dear Dick and Jane, */
    $dear('Tom', 'Dick', 'Harry') /* Dear Tom, Dick, and Harry, */

=cut

sub fn_ifeach {
    my ($name, $args, $renderer) = @_;

    return grep(defined && length, $renderer->execute_each($args));
}

=head2 ??(condition, expression, ..., default?)

=head2 ifel(condition, expression, ..., default?)

This function, "if else", takes any number of (condition, expression) pairs,
optionally followed by a default. Each condition is evaluated in turn. The
(possibly multi-valued) expression corresponding to the first non-empty,
non-zero condition is evaluated and returned. If no conditions are satisifed,
the (possibly multi-valued) default expression is evaluated and returned
(if supplied).

=cut

sub fn_ifelse {
    my ($name, $args, $renderer) = @_;
    my @args = @$args;
    my ($cond, $ret);

    while (@args > 1) {
	$cond = $renderer->execute_sequence(shift(@args));
	$ret = shift(@args);

	return $renderer->execute_sequence($ret)
	  if length($cond) && $cond ne '0';
    }

    return $renderer->execute_sequence($args[0]) if @args;
    return wantarray? (): '';
}

=head1 ITERATION FUNCTIONS

=head2 ?*(condition, code)

=head2 wh(condition, code)

This function, "while", executes the specified code repeatedly as long as
the condition remains true (non-empty and non-zero). If the condition is
not initially true, the code will never be executed.

It returns a list (in array context) or the concatenation of the results of
executing the code.

=head2 *?(code, condition)

=head2 dowh(code, condition)

This function, "do-while", executes the specified code repeatedly as long
as the condition remains true (non-empty and non-zero). The code is
executed before the condition is evaluated and so will run at least once.

It returns a list (in array context) or the concatenation of the results of
executing the code.

=cut

sub fn_test_rpt {
    my ($name, $args, $renderer) = @_;
    my (@results, @temp, $code, $cond);
    my $max_len = $renderer->{limits}{step_length};
    my $value;

    if ($name ne '*?' && $name !~ /^do/) {
	# test/exec/repeat (AKA "while") form (condition, code)
	($cond, $code) = @$args;
	$value = $renderer->execute_sequence($cond);
	return wantarray? (): '' unless length($value) && $value ne '0';
    } else {
	# exec/test/repeat (AKA "do while") form (code, condition)
	($code, $cond) = @$args;
    }

    do {
	if (defined($max_len)) {
	    push(@results, @temp = $renderer->execute_sequence($code));
	    $max_len -= length(join('', @temp));
	    $renderer->exceeded_limits('step_length') if $max_len < 0;
	} else {
	    push(@results, $renderer->execute_sequence($code));
	}
	$value = $renderer->execute_sequence($cond);
    } while (length($value) && $value ne '0' && !$renderer->exceeded_limits);

    return wantarray? @results: join('', @results);
}

=head1 CHARACTERS

cr ("\r"), gg (">>"), ht ("\t"), ll ("<<"), nl ("\n"), and sp (" ")

=head1 STRING FUNCTIONS

=head2 $;(separator, expression, ...)

=head2 join(separator, expression, ...)

This function returns the concatenation of all the values of all the
(possibly multi-valued) expression parameters, separated by separator.

    $;(',', 'a', 'b', 'c') /* a,b,c */
    $;(',', 'a', ?('b', 'c')) /* a,b,c */
    $;(',', 'a', ''?('b', 'c')) /* a,bc */

=cut

sub fn_join {
    my ($name, $args, $renderer) = @_;
    my @args = $renderer->execute_each($args);
    my $sep = shift(@args);

    return join($sep, @args);
}

=head2 $;;(sep2, first_sep, middle_sep, last_sep, expression, ...)

=head2 join4(sep2, first_sep, middle_sep, last_sep, expression, ...)

This function returns the concatenation of all values of all expression
parameters, separated by separators. If there are exactly two values, only
the "sep2" separator is used. If there are three or more values, "first_sep"
is used first, "last_sep" is used last, and "middle_sep" is used between all
other values.

The intent is to support "a and b" and "a, b, and c" styles of
context-dependent joins while working either left-to-right or right-to-left.

=cut

sub fn_join4 {
    my ($name, $args, $renderer) = @_;
    my @args = $renderer->execute_each($args);
    my ($sep2, $sep1, $sep, $sepn) = splice(@args, 0, 4);

    return '' unless (@args);
    return @args if (@args == 1);
    return join($sep2, @args) if (@args == 2);

    my $first = shift(@args);
    my $last = pop(@args);
    return "$first$sep1" . join($sep, @args) . "$sepn$last";
}

=head2 len(value)

This function returns the length (in characters) of the specified value.

=cut

sub fn_length {
    my ($name, $args, $renderer) = @_;

    return length($renderer->execute_sequence($args->[0]));
}

=head2 $/(separator, string, nth?)

=head2 split(separator, string, nth?)

This function splits the string into parts using the specified separator. If
nth is specified, that part (counting from 0) is returned. Otherwise, all
the parts are returned (as separate values).

=cut

sub fn_split {
    my ($name, $args, $renderer) = @_;
    my $sep = $renderer->execute_sequence($args->[0]);
    my $string = $renderer->execute_sequence($args->[1]);
    my @parts = split(/\Q$sep/, $string);

    if (@$args > 2) {
	my $nth = $renderer->execute_sequence($args->[2]);
	return $parts[$nth] if looks_like_number($nth);
    }

    return @parts;
}

=head2 x(string, count)

This function returns the concatenation of count copies of string. Extra
care is taken to avoid exceeding the step_length limit (see
L<Text::TemplateLite::Renderer/"limit($type, $limit)">).

    x('-#',5)'-' /* -#-#-#-#-#- */

=cut

sub fn_str_rpt {
    my ($name, $args, $renderer) = @_;
    my @args = $renderer->execute_each([ @{$args}[0, 1] ]);

    $args[1] = 0 unless looks_like_number($args[1]);

    if ($args[1] && defined(my $max_len = $renderer->{limits}{step_length})) {
	my $max_times = int($max_len / length($args[0]));

	if ($max_times < $args[1]) {
	    $renderer->exceeded_limits('step_length');
	    if (!$max_times) {
		$args[0] = substr($args[0], 0, $max_len);
		++$max_times;
	    }
	    $args[1] = $max_times;
	}
    }

    return $args[0] x $args[1];
}

=head2 $-(string, offset?, length?)

=head2 substr(string, offset?, length?)

This function returns the substring of length length beginning at offset
offset. It uses Perl's substr, so negative offsets and lengths work the
same way.

=cut

sub fn_substr {
    my ($name, $args, $renderer) = @_;
    my @args = $renderer->execute_each([ @{$args}[0..2] ]);
    $args[1] = 0 if @args > 1 && !looks_like_number($args[1]);
    $args[2] = 0 if @args > 2 && !looks_like_number($args[2]);

    # substr(@args)
    return '' unless @args;
    return $args[0] if @args == 1;
    return substr($args[0], $args[1]) if @args == 2;
    return substr($args[0], $args[1], $args[2]);
}

=head2 trim(string, ...)

This function returns each string parameter with leading and trailing
white space removed.

=cut

sub fn_trim {
    my ($name, $args, $renderer) = @_;
    my @args = $renderer->execute_each($args);

    $_ =~ s/^\s+|\s+$//g foreach @args;
    return @args;
}

=head2 cmp(string1, string2)

This function returns -1, 0, or 1 depending on whether string1 is less than,
equal to, or greater than string2 (using the C<cmp> operator in Perl).

=cut

sub fn_scmp {
    my ($name, $args, $renderer) = @_;
    my @args = $renderer->execute_each([ @{$args}[0, 1] ]);

    return ((defined($args[0])? $args[0]: '') cmp
      (defined($args[1])? $args[1]: ''));
}

=head2 eq(string1, string2)

=head2 ge(string1, string2)

=head2 gt(string1, string2)

=head2 le(string1, string2)

=head2 lt(string1, string2)

=head2 ne(string1, string2)

These functions return true if string1 is equal to (eq), greater than or
equal to (ge), greater than (gt), less than or equal to (le), less than
(le), or not equal to (ne) string2.

=cut

sub fn_seq { fn_scmp(@_) == 0; }
sub fn_sge { fn_scmp(@_) >= 0; }
sub fn_sgt { fn_scmp(@_) > 0; }
sub fn_sle { fn_scmp(@_) <= 0; }
sub fn_slt { fn_scmp(@_) < 0; }
sub fn_sne { fn_scmp(@_) != 0; }

=head1 NUMERIC FUNCTIONS

=head2 +(number, ...)

This function returns the sum of its numeric parameters
(or 0 if there aren't any).

=cut

sub fn_add {
    my ($name, $args, $renderer) = @_;
    my $sum = 0;
    my $value;

    foreach (@$args) {
	$value = $renderer->execute_sequence($_);
	$sum += $value if looks_like_number($value);
    }

    return $sum;
}

=head2 -(number)

The "unary minus" form of this function returns the negative of the number.

=head2 -(number1, number2)

The "binary minus" form of this function returns the difference
C<number1 - number2>.

=cut

sub fn_neg_sub {
    my ($name, $args, $renderer) = @_;
    my @args = get_numbers([ @{$args}[0, 1] ], $renderer);

    return 0 if !@args;
    return -$args[0] if @args == 1;
    return $args[0] - $args[1];
}

=head2 *(number, ...)

This function returns the product of its numeric parameters
(or 1 if there aren't any).

=cut

sub fn_mul {
    my ($name, $args, $renderer) = @_;
    my $prod = 1;
    my $value;

    foreach (@$args) {
	$value = $renderer->execute_sequence($_);
	$prod *= $value if looks_like_number($value);
    }

    return $prod;
}

=head2 /(number1, number2)

This function returns the quotient of number1 divided by number2. It returns
an empty string if number2 is zero.

=cut

sub fn_div {
    my ($name, $args, $renderer) = @_;
    my @args = get_numbers([ @{$args}[0, 1] ], $renderer);

    return ((@args == 2 && $args[1])? ($args[0] / $args[1]): '');
}

=head2 %(number1, number2)

This function returns the remainder of number1 divided by number2. It returns
an empty string if number2 is zero.

=cut

sub fn_mod {
    my ($name, $args, $renderer) = @_;
    my @args = get_numbers([ @{$args}[0, 1] ], $renderer);

    return ((@args == 2 && $args[1])? ($args[0] % $args[1]): '');
}

=head2 &(number, ...)

This function returns the binary "and" of its numeric parameters
(or ~0 if there aren't any).

=cut

sub fn_bin_and {
    my ($name, $args, $renderer) = @_;
    my $result = ~0;
    my $value;

    foreach (@$args) {
	$value = $renderer->execute_sequence($_);
	$result &= 0+$value if looks_like_number($value);
    }

    return $result;
}

=head2 |(number, ...)

This function returns the binary "or" of its parameters
(or 0 if there aren't any).

=cut

sub fn_bin_or {
    my ($name, $args, $renderer) = @_;
    my $result = 0;
    my $value;

    foreach (@$args) {
	$value = $renderer->execute_sequence($_);
	$result |= 0+$value if looks_like_number($value);
    }

    return $result;
}

=head2 ^(number, ...)

This function returns the binary "exclusive-or" ("xor") of its parameters
(or 0 if there aren't any).

=cut

sub fn_bin_xor {
    my ($name, $args, $renderer) = @_;
    my $result = 0;
    my $value;

    foreach (@$args) {
	$value = $renderer->execute_sequence($_);
	$result ^= 0+$value if looks_like_number($value);
    }

    return $result;
}

=head2 ~(number)

This function returns the one's complement of number.

=cut

sub fn_complement {
    my ($name, $args, $renderer) = @_;
    my $value = $renderer->execute_sequence($args->[0]);

    return looks_like_number($value)? ~(0+$value): ~0;
}

=head2 int(number)

This function returns the integer portion of number.

=cut

sub fn_int {
    my ($name, $args, $renderer) = @_;
    my $value = $renderer->execute_sequence($args->[0]);

    return looks_like_number($value)? int($value): 0;
}

=head2 max(number, ...)

This function returns the maximum of its numeric parameters
(or any empty string if there aren't any).

=cut

sub fn_max {
    my ($name, $args, $renderer) = @_;
    my ($max, $value);

    foreach (@$args) {
	if (looks_like_number($value = $renderer->execute_sequence($_))) {
	    $max = $value if !defined($max) || $value > $max;
	}
    }

    return defined($max)? $max: '';
}

=head2 min(number, ...)

This function returns the minimum of its numeric parameters
(or any empty string if there aren't any).

=cut

sub fn_min {
    my ($name, $args, $renderer) = @_;
    my ($min, $value);

    foreach (@$args) {
	if (looks_like_number($value = $renderer->execute_sequence($_))) {
	    $min = $value if !defined($min) || $value < $min;
	}
    }

    return defined($min)? $min: '';
}

=head2 <=>(number1, number2)

This function returns -1, 0, or 1 depending on whether number1 is less than,
equal to, or greater than number2 (using the C<< <=> >> operator in Perl).

=cut

sub fn_ncmp {
    my ($name, $args, $renderer) = @_;
    my @args = get_numbers([ @{$args}[0, 1] ], $renderer);

    return $args[0] <=> $args[1];
}

=head2 =(number1, number2)

=head2 >=(number1, number2)

=head2 >(number1, number2)

=head2 <=(number1, number2)

=head2 <(number1, number2)

=head2 !=(number1, number2)

These functions return true if number1 is equal to (=), greater than or
equal to (>=), greater than (>), less than or equal to (<=), less than
(<), or not equal to (!=) number2.

=cut

sub fn_neq { fn_ncmp(@_) == 0; }
sub fn_nge { fn_ncmp(@_) >= 0; }
sub fn_ngt { fn_ncmp(@_) > 0; }
sub fn_nle { fn_ncmp(@_) <= 0; }
sub fn_nlt { fn_ncmp(@_) < 0; }
sub fn_nne { fn_ncmp(@_) != 0; }

=head1 TEMPLATE FUNCTIONS

=head2 tpl(name, code)

This function creates a template within the template. The code is stored in
the variable with the specified name and can be called later within the
main template as C<$name> or C<$name(parameters)>. The parameters will appear
as variables C<$1>, C<$2>, etc. Parameter C<$0> will be set to the number of
parameters supplied.

It returns no value.

=cut

sub fn_set_template {
    my ($name, $args, $renderer) = @_;

    if (@$args) {
	my $vname = $renderer->execute_sequence($args->[0]);
	$renderer->vars->{$vname} = [ '<>', $args->[1] || [] ];
    }

    return ();
}

=head2 <$>(int_name1, ext_name1, ..., ext_name?)

This function allows you to retrieve variable values from the most recent
external template call.

Parameters are interpreted as as many pairs as possible. The first
parameter in each pair is a variable name in the current template; the
second is a variable name in the external template whose value will be
assigned to the variable in the current template.

If there are an odd number of parameters, the value of the external
variable named last will be the return value of the function call. Otherwise,
no value is returned.

    <$>('my_a', 'a', 'my_b', 'b', 'c')
    /* Copies the values of $a and $b in the last external template
       into $my_a and $my_b in the current template. Returns the
       value of $c from the external template. */

If there has been no external template call, nothing happens and nothing
is returned.

=cut

sub fn_ext_equal {
    my ($name, $args, $renderer) = @_;
    my $ext_rend = $renderer->last_renderer;

    return wantarray? (): '' unless $ext_rend;

    my @args = @$args;
    my $locvars = $renderer->vars;
    my $extvars = $ext_rend->vars;
    my ($locname, $extname);

    while (@args > 1) {
	($locname, $extname) = $renderer->execute_each([ splice(@args, 0, 2) ]);
	$locvars->{$locname} = $extvars->{$extname};
    }

    if (@args) {
	$extname = $renderer->execute_sequence($args[0]);
	my $value = $extvars->{$extname};
	return defined($value)? $value: '';
    }

    return wantarray? (): '';
}

=head1 MISCELLANEOUS FUNCTIONS

=head2 $=(name1, expr1, ..., ret_name?)

This function takes any number of (possibly multi-valued) parameters. The
maximum even number of resulting values are interpreted as (name, value)
pairs, assigning each value to the variable with the preceding name.

If there are an odd number of parameters, the value of the variable named
by the last parameter is returned. Otherwise, no value is returned.

    $=('prev', $var, 'var', +($var, 1))
    /* sets $prev to the current value of $var,
       adds 1 to $var, and returns nothing */

    $=('a', 2, 'b'$a, 3, 'b'$a)
    /* sets $a to 2, sets $b2 to 3, and returns $b2 */

=cut

sub fn_var_equal {
    my ($name, $args, $renderer) = @_;
    my @args = $renderer->execute_each($args);
    my ($key, $value);

    while (@args > 1) {
	($key, $value) = splice(@args, 0, 2);
	$renderer->vars->{$key} = $value;
    }

    if (@args) {
	$value = $renderer->vars->{$args[0]};
	return defined($value)? $value: '';
    }

    return wantarray? (): '';
}

=head2 void(expression, ...)

This function evaluates each expression but returns nothing.

You probably won't need this unless you add functions with side effects
that return something when they shouldn't.

=cut

sub fn_void {
    my ($name, $args, $renderer) = @_;

    $renderer->execute_sequence($_) foreach (@$args);
    return wantarray? (): '';
}

=head1 AUTHOR

Brian Katzung, C<< <briank at kappacs.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-templatelite at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-TemplateLite-Standard>. I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::TemplateLite::Standard

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-TemplateLite-Standard>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-TemplateLite-Standard>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-TemplateLite-Standard>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-TemplateLite-Standard/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Katzung.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Text::TemplateLite::Standard

=begin pod_coverage

=head2 fn_log_and

=head2 fn_log_or

=head2 fn_log_not

=head2 fn_ifeach

=head2 fn_ifelse

=head2 fn_test_rpt

=head2 fn_join

=head2 fn_join4

=head2 fn_length

=head2 fn_split

=head2 fn_trim

=head2 fn_str_rpt

=head2 fn_substr

=head2 fn_scmp

=head2 fn_seq

=head2 fn_sge

=head2 fn_sgt

=head2 fn_sle

=head2 fn_slt

=head2 fn_sne

=head2 fn_add

=head2 fn_neg_sub

=head2 fn_mul

=head2 fn_div

=head2 fn_mod

=head2 fn_bin_and

=head2 fn_bin_or

=head2 fn_bin_xor

=head2 fn_complement

=head2 fn_int

=head2 fn_max

=head2 fn_min

=head2 fn_ncmp

=head2 fn_neq

=head2 fn_nge

=head2 fn_ngt

=head2 fn_nle

=head2 fn_nlt

=head2 fn_nne

=head2 fn_set_template

=head2 fn_ext_equal

=head2 fn_var_equal

=head2 fn_void

=end pod_coverage
