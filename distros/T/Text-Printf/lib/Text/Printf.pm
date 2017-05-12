=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Text::Printf - A simple, lightweight text fill-in class.

=head1 VERSION

This documentation describes version 1.03 of Text::Printf, June 9, 2008.

=cut

package Text::Printf;

use strict;
use warnings;
use Readonly;

$Text::Printf::VERSION = '1.03';
use vars '$DONTSET';
Readonly::Scalar $DONTSET => [];    # Unique identifier

# Always export the $DONTSET variable
# Always export the *printf subroutines
sub import
{
    my ($pkg) = caller;
    no strict 'refs';
    *{$pkg.'::DONTSET'}  = \$DONTSET;
    *{$pkg.'::tprintf'}  = \&tprintf;
    *{$pkg.'::tsprintf'} = \&tsprintf;
}

# Declare exception classes
use Exception::Class
(
    'Text::Printf::X' =>
        { description => 'Generic Text::Printf exception',
        },
    'Text::Printf::X::ParameterError' =>
        { isa         => 'Text::Printf::X',
          description => 'Error in parameters to Text::Printf method',
        },
    'Text::Printf::X::OptionError' =>
        { isa         => 'Text::Printf::X',
          fields      => 'name',
          description => 'A bad option was passed to a Text::Printf method',
        },
    'Text::Printf::X::KeyNotFound' =>
        { isa         => 'Text::Printf::X',
          fields      => 'symbols',
          description => 'Could not resolve one or more symbols in template text',
        },
    'Text::Printf::X::NoText' =>
        { isa         => 'Text::Printf::X',
          description => 'No text to expand',
        },
    'Text::Printf::X::InternalError' =>
        { isa         => 'Text::Printf::X',
          fields      => 'additional_info',
          description => 'Internal Text::Printf error.  Please contact the author.'
        },
);

# Early versions of Exception::Class didn't define this useful subroutine
if (!defined &Exception::Class::Base::caught)
{
    # Class method to help caller catch exceptions
    no warnings qw(once redefine);
    *Exception::Class::Base::caught = sub
    {
        my $class = shift;
        return Exception::Class->caught($class);
    }
}

# Croak-like location of error
sub Text::Printf::X::location
{
    my ($pkg,$file,$line);
    my $caller_level = 0;
    while (1)
    {
        ($pkg,$file,$line) = caller($caller_level++);
        last if $pkg !~ /\A Text::Printf/x  &&  $pkg !~ /\A Exception::Class/x
    }
    return "at $file line $line";
}

# Die-like location of error
sub Text::Printf::X::InternalError::location
{
    my $self = shift;
    return "at " . $self->file() . " line " . $self->line()
}

# Override full_message, to report location of error in caller's code.
sub Text::Printf::X::full_message
{
    my $self = shift;

    my $msg = $self->message;
    return $msg  if substr($msg,-1,1) eq "\n";

    $msg =~ s/[ \t]+\z//;   # remove any trailing spaces (is this necessary?)
    return $msg . q{ } . $self->location() . qq{\n};
}

# Comma formatting.  From the Perl Cookbook.
sub commify ($)
{
    my $rev_num = reverse shift;  # The number to be formatted, reversed.
    $rev_num =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $rev_num;
}


## Constructor
# $object = Text::Printf->new($boilerplate, $options);
sub new
{
    my $class = shift;
    my $self  = \do { my $anonymous_scalar };
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}


{ # encapsulation enclosure

    # Attributes
    my %boilerplate_for;
    my %delimiters_for;
    my %regex_for;
    my %value_hashes_for;
    my %defaults_for;
    my %bad_keys_of;

    ## Initializer
    # $obj->_initialize($boilerplate, $options);
    sub _initialize
    {
        my $self = shift;

        # Check whether any attribute has a value from another, earlier object.
        # This should never happen, if DESTROY is working, and nobody calls
        # _initialize on an already-initialized object.
        {
            my   @occupied;
            push @occupied, '%boilerplate_for'   if exists $boilerplate_for {$self};
            push @occupied, '%delimiters_for'    if exists $delimiters_for  {$self};
            push @occupied, '%regex_for'         if exists $regex_for       {$self};
            push @occupied, '%value_hashes_for'  if exists $value_hashes_for{$self};
            push @occupied, '%defaults_for'      if exists $defaults_for    {$self};
            push @occupied, '%bad_keys_of'       if exists $bad_keys_of     {$self};

            Text::Printf::X::InternalError->throw(
                message         => 'Internal programing error: contact author.',
                additional_info => join(', ', @occupied))
                if @occupied;
        }

        # Check number and type of parameters
        # Legal possibilities:  (), ($scalar), ($hashref), ($scalar, $hashref);
        my $whoami = ref($self) . " constructor";

        my $boilerplate;
        my $options_ref;

        if (@_ == 1)
        {
            my $arg = shift;
            Text::Printf::X::ParameterError->throw('Text may not be set to an undefined value')
                if !defined $arg;

            my $ref = ref $arg;
            if ($ref eq '')
            {
                $boilerplate = $arg;
            }
            elsif ($ref eq 'HASH')
            {
                $options_ref = $arg;
            }
            else
            {
                $ref = _decode_ref($arg);
                Text::Printf::X::ParameterError->throw(
                    "Solo argument to $whoami should be scalar or hashref, not $ref");
            }
        }
        elsif (@_ == 2)
        {
            my $arg = shift;
            Text::Printf::X::ParameterError->throw('Text may not be set to an undefined value')
                if !defined $arg;

            my $ref = ref $arg;
            if ($ref eq '')
            {
                $boilerplate = $arg;
            }
            else
            {
                $ref = _decode_ref($arg);
                Text::Printf::X::ParameterError->throw(
                    "First argument to $whoami should be a scalar, not $ref");
            }

            $arg = shift;
            $ref = ref($arg);
            if ($ref ne 'HASH')
            {
                $ref = _decode_ref($arg);
                Text::Printf::X::ParameterError->throw(
                    "Second argument to $whoami must be hash ref, not $ref");
            }
            $options_ref = $arg;
        }
        elsif (@_ > 2)
        {
            Text::Printf::X::ParameterError->throw("Too many parameters to $whoami");
        }


        $boilerplate_for{$self} = $boilerplate;
        if (exists $options_ref->{delimiters})
        {
            my $delim = $options_ref->{delimiters};

            Text::Printf::X::OptionError->throw(
                message => "Bad option to $whoami\n"
                           . "delimiter value must be array reference",
                name => 'delimiter')
                unless ref($delim) eq 'ARRAY';

            Text::Printf::X::OptionError->throw(
                message => "Bad option to $whoami\n"
                           . "delimiter arrayref must have exactly two values",
                name => 'delimiter')
                unless @$delim == 2;

            my ($ref0, $ref1) = (ref ($delim->[0]), ref ($delim->[1]));
            Text::Printf::X::OptionError->throw(
                message => "Bad option to $whoami\n"
                           . "delimiter values must be strings or regexes",
                name => 'delimiter')
                unless ($ref0 eq q{}  ||  $ref0 eq 'Regexp')
                    && ($ref1 eq q{}  ||  $ref1 eq 'Regexp');

            $delimiters_for{$self} = [ $ref0? $delim->[0] : quotemeta($delim->[0]),
                                       $ref0? $delim->[1] : quotemeta($delim->[1]) ];
        }
        else
        {
            $delimiters_for{$self} = [ quotemeta('{{'), quotemeta('}}') ];
        }

        # $1 is the keyword plus its delimiters; $2 is the keyword by itself.
        # $3 is the printf format, if any; $4 is the extended format.
        $regex_for{$self} =
            qr/(                                         # $1: capture whole expression
                 $delimiters_for{$self}[0]               # Opening delimiter
                 (\w+)                                   # $2: keyword
                 (?:  :                                  # Maybe a colon and...
                      %? ( (?: \+ (?=[^+]{2}) )? [-<>]?  \+?
                                 [\d.]* [A-Za-z]{1,2} )  #   $3: ...a printf format
                      (?:   :                            #   and maybe another colon
                            ([,\$]+) )?                  #   $4: and extended format chars
                 )?
                 $delimiters_for{$self}[1]               # Closing delimiter
              )/xsm;

        return;
    }

    sub DESTROY
    {
        my $self = shift;

        # Free up the hash entries we're using.
        delete $boilerplate_for {$self};
        delete $delimiters_for  {$self};
        delete $regex_for       {$self};
        delete $value_hashes_for{$self};
        delete $defaults_for    {$self};
        delete $bad_keys_of     {$self};
    }

    # Stack up hash values for later substitution
    sub pre_fill
    {
        my $self = shift;

        # Validate the parameters
        foreach my $arg (@_)
        {
            Text::Printf::X::ParameterError->throw("Argument to pre_fill() is not a hashref")
                if ref $arg ne 'HASH';
        }
        push @{ $value_hashes_for{$self} }, @_;
        return;
    }

    # Stack up hash values for later substitution
    sub default
    {
        my $self = shift;

        # Validate the parameters
        foreach my $arg (@_)
        {
            Text::Printf::X::ParameterError->throw("Argument to default() is not a hashref")
                if ref $arg ne 'HASH';
        }
        push @{ $defaults_for{$self} }, @_;
        return;
    }

    # Clear any pre-stored hashes
    sub clear_values
    {
        my $self = shift;
        $value_hashes_for{$self} = [];
        $defaults_for    {$self} = [];
        return;
    }

    # Set or change the boilerplate (template) text
    sub text
    {
        my $self = shift;

        # No arguments?  Return the text.
        return $boilerplate_for{$self}
              unless @_;

        my $text = shift;
        Text::Printf::X::ParameterError->throw('Too many parameters to text()')
              if @_;
        Text::Printf::X::ParameterError->throw('Text may not be set to an undefined value')
              if !defined $text;

        $boilerplate_for{$self} = $text;
        return;
    }

    # Do the replacements.
    sub fill
    {
        my $self = shift;
        my @fill_hashes = @_;

        # Validate the parameters
        foreach my $arg (@fill_hashes)
        {
            Text::Printf::X::ParameterError->throw('Argument to fill() is not a hashref')
                if ref $arg ne 'HASH';
        }

        my @hashes;
        push @hashes, @{ $value_hashes_for{$self}}  if exists $value_hashes_for{$self};
        push @hashes, @fill_hashes;
        push @hashes, @{ $defaults_for    {$self}}  if exists $defaults_for    {$self};

        # Fetch other attributes
        my $str = $boilerplate_for{$self};
        defined $str or Text::Printf::X::NoText->throw('Template text was never set');
        my $rex = $regex_for{$self};

        # Do the subsitution
        $bad_keys_of{$self} = [];
        $str =~ s/$rex/$self->_substitution_of(\@hashes, $1, $2, $3, $4)/ge;

        # Any unfulfilled substitutions?
        my $bk = $bad_keys_of{$self};    # shortcut for the next few lines
        if (@$bk > 0)
        {
            my $s = @$bk == 1? q{} : 's';
            my $bad_str = join ', ', @$bk;
            $bad_keys_of{$self} = [];   # reset in case exception is caught.
            Text::Printf::X::KeyNotFound->throw(
                message => "Could not resolve the following symbol$s: $bad_str",
                symbols => $bk);
        }

        return $str;
    }

    # Helper function for regular expression in fill(), above.
    sub _substitution_of
    {
        my $self = shift;
        my ($values_aref, $whole_expr, $keyword, $format, $extend) = @_;

        Value_Hash: foreach my $hashref (@$values_aref)
        {
            next unless exists $hashref->{$keyword};

            my $value = $hashref->{$keyword};

            # Special DONTSET value: leave the whole expression intact
            return $whole_expr
                if ref($value) eq 'ARRAY'  &&  $value eq $DONTSET;

            $value = q{}  if !defined $value;
            return $value if !defined $format;

            $format =~ tr/<>/-/d;
            $value = sprintf "%$format", $value;

            # Special extended formatting
            if (defined $extend)
            {
                # Currently, ',' and '$' are defined
                my $v_len = length $value;
                $value = commify $value     if index ($extend, ',') >= 0;
                $value =~ s/([^ ])/\$$1/    if index ($extend, '$') >= 0;
                my $length_diff = length($value) - $v_len;
                $value =~ s/^ {0,$length_diff}//;
                $length_diff = length($value) - $v_len;
                $value =~ s/ {0,$length_diff}$//;
            }

            return $value;
        }

        # Never found a match?  Pity.
        # Store the bad keyword, and leave it intact in the string.
        push @{ $bad_keys_of{$self} }, $keyword;
        return $whole_expr;
    }

    # Debugging routine -- dumps a string representation of the object
    sub _dump
    {
        my $self = shift;
        my $out = q{};

        $out .= qq{Boilerplate: "$boilerplate_for{$self}"\n};
        $out .= qq{Delimiters: [ "$delimiters_for{$self}[0]", "$delimiters_for{$self}[1]" ]\n};
        $out .= qq{Regex: $regex_for{$self}\n};
        $out .= qq{Value hashes: [\n};
        my $i = 0;
        my $vals = $value_hashes_for{$self} || [];
        for my $h (@$vals)
        {
            $out .= "    $i {\n";
            foreach my $k (sort keys %$h)
            {
                $out .= "        qq{$k} => qq{$h->{$k}}\n";
            }
            $out .= "       },\n";
            ++$i;
        }
        $out .= "]\n";

        my $bad_keys = $bad_keys_of{$self} || [];
        $out .= qq{Bad keys: [} . join(", ", @$bad_keys) . "]\n";;
        return $out;
    }

} # end encapsulation enclosure



# printf-like convenience functions

sub tprintf
{
    # First arg a filehandle?
    my $fh;
    if (ref $_[0] eq 'GLOB'  ||  UNIVERSAL::can($_[0], 'print'))
    {
        $fh = shift;
        Text::Printf::X::ParameterError->throw
            ("tprintf() requires at least one non-handle argument")
            if @_ < 1;
    }

    my $string = t_printf_guts('tprintf', @_);

    if ($fh)
    {
        if (UNIVERSAL::can($fh, 'print'))
        {
            $fh->print($string);
        }
        else
        {
            print {$fh} $string;
        }
    }
    else
    {
        print $string;
    }
}

sub tsprintf
{
    return t_printf_guts('tsprintf', @_);
}

sub tfprintf
{
    Text::Printf::X::ParameterError->throw
        ("tfprintf() requires at least two arguments")
        if @_ < 2;

    my $fh = shift;
    print {$fh} t_printf_guts('tfprintf', @_);
}

sub t_printf_guts
{
    my $which = shift;
    Text::Printf::X::ParameterError->throw
        ("$which() requires at least one argument")
        if @_ == 0;

    my $format = shift;
    my @value_hashes = @_;

    # Validate the parameters
    foreach my $arg (@value_hashes)
    {
        Text::Printf::X::ParameterError->throw
            ("Argument to $which() is not a hashref")
            if ref $arg ne 'HASH';
    }

    my $template = Text::Printf->new ($format);
    return $template->fill(@value_hashes);
}

sub _decode_ref
{
    my $ref = ref $_[0];
    return $ref eq '' ? 'scalar'
         : $ref . ' ref';
}

1;
__END__


=head1 SYNOPSIS

C<printf>-like usage:

 # Print (to default filehandle, or explicit filehandle).
 tprintf ($format, \%values);
 tprintf ($filehandle, $format, \%values)

 # Render to string.
 $result = tsprintf ($format, \%values);

Prepared-template usage:

 # Create a template:
 $template = Text::Printf->new($format, \%options);

 # Set (or change) the template text:
 $template->text($format);

 # Set default values:
 $template->default(\%values);

 # Set some override values:
 $template->pre_fill(\%values);

 # Fill it in, rendering the result string:
 $result = $template->fill(\%values);


=head1 OPTIONS

 delimiters => [ '{{', '}}' ];              # may be strings
 delimiters => [ qr/\{\{/, qr/\}\}/ ];      # and/or regexps


=head1 DESCRIPTION

There are many templating modules on CPAN.  They're all far, far more
powerful than Text::Printf.  When you need that power, they're
wonderful.  But when you don't, they're overkill.

This module provides a very simple, lightweight, quick and easy
templating mechanism for when you don't need those other
powerful-but-cumbersome modules.

There are two ways to use this module: an immediate (printf-like)
way, and a delayed (prepared) way.

For the immediate way, you simply call L</tprintf> or L</tsprintf>
with a boilerplate string and the values to be inserted/formatted.
See the following section for information on how to format the
boilerplate string.  This is somewhat easier than using plain
C<printf> or C<sprintf>, since the name of the value to be inserted is
at the same place as its format.

For the prepared way, you create a template object that contains the
boilerplate text.  Again, see the next section for information on how
to format it properly.  Then, when it is necessary to render the final
text (with placeholders filled in), you use the L</fill> method,
passing it one or more references of hashes of values to be
substituted into the original boilerplate text.  The special value
C<$DONTSET> indicates that the keyword (and its delimiters) are to
remain in the boilerplate text, unsubstituted.

That's it.  No flow control, no executable content, no filesystem
access.  Never had it, never will.

=head1 TEMPLATE FORMAT

When you create a template object, or when you use one of the
printf-like functions, you supply a I<template>, which is a string
that contains I<placeholders> that will be filled in later (by the
L</fill> method).  All other text in the template will remain
undisturbed, as-is, unchanged.

I<Examples:>

 'This is a template.'
 'Here's a placeholder: {{fill_me_in}}'
 'Can occur multiple times: {{name}} {{phone}} {{name}}'
 'Optionally, can use printf formats: {{name:20s}} {{salary:%.2f}}'
 'Fancier formats: {{salary:%.2f:,$}}'

Substitution placeholders within the text are indicated by keywords,
set off from the surrounding text by a pair of delimiters.  By default
the delimters are C<{{> and C<}}>, because that's easy to remember,
and since double curly braces are rare in programming languages (and
in natural languages).

Keywords between the delimiters must be comprised entirely of "word"
characters (that is, alphabetics, numerics, and the underscore), and
there must be I<no spaces or other characters> between the keyword and
its delimiters.  This strictness is considered a feature.

Each keyword may optionally be followed (still within the delimiters)
by a colon (C<:>) and a printf format.  If a format is specified, it
will be used to format the entry when expanded.  The format may omit
the leading C<%> symbol, or it may include it.

If a printf format is supplied, it may optionally be followed by
another colon and zero or more special "extended formatting"
characters.  Currently, two such characters are recognized: C<,>
(comma) and C<$> (dollar sign).  Each of these is only useful if the
placeholder is being replaced by a number.  If a comma character is
used, commas will be inserted every three positions to the left of the
decimal point.  If a dollar-sign character is used, a dollar sign will
be placed immediately to the left of the first digit of the number.

A printf format may be preceeded by a "C<->" sign to indicated that
the string or number is to be left-justified within the field width.
The default is right-justification.  (This is how all C<printf>s work)
I personally have a hard time remembering that.  So instead of a minus
sign, you can use a less-than sign ("C<E<lt>>") to indicate left-
justification, or a greater-than sign ("C<E<gt>>") to indicate
right-justification.

To sum up, the following are examples of valid printf-style formats:

         d    integer
         x    hexadecimal
        5d    integer, right-justified, minimum 5 positions
       -5d    integer, left-justified, minimum 5 positions
       <5d    Same
       >5d    Same, only right-justified
       .2f    floating-point, two decimal places
      .10s    string, maximum 10 positions
    10.10s    string, exactly 10 positions, right-justified
   <10.10s    string, exactly 10 positions, left-justified

=head1 COMMON MISTAKE

If Text::Printf does not expand a placeholder, check to make sure that
you did not include any spaces around the placeholder name, and did
not use any non-"word" (regex C<\W>) characters in the name.
Text::Printf is very strict about spaces and other characters; this is
so that a non-placeholder does not get expanded by mistake.

 Right: {{lemon}}
 Right: {{pi:%.9f}}
 Wrong: {{ lemon }}
 Wrong: {{lemon pie}}
 Right: {{lemon_pie}}
 Wrong: {{pi: %.9f}}

Text::Printf will silently leave incorrectly-formatted placeholders
alone.  This is in case you are generating code; you don't want
something like

 sub foo {{$_[0] => 1}};

to be mangled or to generate errors.

=head1 METHODS

=over 4

=item new

Constructor.

 $template_object = Text::Printf->new($boilerplate, \%options);

Creates a new Text::Printf object.  Both parameters are optional.

The C<boilerplate> parameter specifies the template pattern that is to
be printed; presumably it has placeholders to be filled in later.  If
you do not specify it here in the constructor, you must specify it via
the L</text> method before you call L</fill>.

The C<options> parameter specifies options to control how the object
behaves.  Currently, the only option permitted is C<delimiters>, which
is a reference to an array of two strings (or compiled regular
expresions): a starting delimiter and an ending delimiter.

=item text

 $template->text($boilerplate);

Sets the template pattern text that will be printed (presumably it has
placeholders to be filled in later).  It is an error to pass C<undef>
to this method or to omit the C<boilerplate> argument.

=item fill

Render the formatted string.

 $result_string = $template->fill($hashref);
 $result_string = $template->fill($hashref, $hashref, ...);

Replaces all of the placeholders within the template with values from
the hashref(s) supplied.

For each placeholder, the hashrefs are examined in turn for a matching
key.  As soon as one is found, the template moves on to the next
placeholder.  Another way of looking at this behavior is "The first
hashref that fulfills a given placeholder... wins."

If the resulting value is the special constant C<$DONTSET>, the
placeholder is left intact in the template.

If no value for a placeholder is found among any of the hash
references passed, an exception is thrown.

=item pre_fill

Set values without rendering.

 $template->pre_fill($hashref, ...);

Specifies one or more sets of key=>value pairs to be used by the
L</fill> method in addition to (and higher priority than) the ones
passed to L</fill>.

This can be useful if some template values are set when the template
is created, but the template is filled elsewhere in your program, and
you don't want to pass variables around.  It is also useful if
different parts of your program fill different parts of the template.

=item default

Set default values without rendering.

 $template->default($hashref, ...);

Like L</pre_fill>, specifies key=>value pairs to be used by L</fill>,
but where L</pre_fill>'s values have a higher priority than those
specified by L</fill>, L</default>'s are I<lower>.  This can be used
at the time the object is created to give default values that only get
used if the call to L</fill> (or L</pre_fill>) don't override them.

=item clear_values

Clear all default and pre-filled values.

 $template->clear_values();

Removes any L</pre_fill>ed or L</default> hash references in the
object.

=back

=head1 FUNCTIONS

=over 4

=item tprintf

Render and print.

 tprintf $format, \%values

Like Perl's printf, tprintf takes a format string and a list of
values.  Unlike Perl's printf, the placeholders and values have names.
Like Perl's printf, the result string is sent to the default
filehandle (usually STDOUT).

This is equivalent to:

 my $template = Text::Printf->new ($format);
 print $template->fill (\%values);

tprintf returns the same value as printf.

If the first argument is a filehandle, or any sort of object that
supports a C<print> method, output is sent there instead of to the
default filehandle.

The original inspiration for this module came as the author was
scanning through a long and complex list of arguments to a printf
template, and kept losing track of which value went into which
position.

=item tsprintf

Render to string.

 $string = tsprintf $format, \%values;
 $string = tsprintf $filehandle, $format, \%values;

Same as L</tprintf>, except that it returns the formatted string
instead of sending it to the default filehandle.

This is equivalent to:

 $string = do { my $t = Text::Printf->new($format);
                $t->fill (\%values)  };

=back

=head1 EXAMPLES

 $book_t = Text::Printf->new('<i>{{title}}</i>, by {{author}}');

 $bibl_1 = $book_t->fill({author => "Stephen Hawking",
                          title  => "A Brief History of Time"});
 # yields: "<i>A Brief History of Time</i>, by Stephen Hawking"

 $bibl_2 = $book_t->fill({author => "Dr. Seuss",
                          title  => "Green Eggs and Ham"});
 # yields: "<i>Green Eggs and Ham</i>, by Dr. Seuss"

 $bibl_3 = $book_t->fill({author => 'Isaac Asimov'});
 # Dies with "Could not resolve the following symbol: title"

 $bibl_4 = $book_t->fill({author => 'Isaac Asimov',
                          title  => $DONTSET });
 # yields: "<i>{{title}}</i>, by Isaac Asimov"

 # Example using format specification:
 $report_line = Text::Printf->new('{{Name:-20s}} {{Grade:10d}}');
 print $report_line->fill({Name => 'Susanna', Grade => 4});
 # prints "Susanna                       4"

 $line = tsprintf '{{Name:-20s}} {{Grade:10d}}', {Name=>'Gwen', Grade=>6};
 # $line is now "Gwen                          6"

 tprintf *STDERR, '{{number:-5.2f}}', {number => 7.4};
 # prints "7.40 " to STDERR.

 # Example using extended formatting characters:
 $str = tsprintf '{{widgets:%10d:,}} at {{price:%.2f:,$}} each',
                   {widgets => 1e6, price => 1234};
 # $str is now: " 1,000,000 at $1,234.00 each"

=head1 EXPORTS

This module exports the following symbols into the caller's namespace:

 $DONTSET
 tprintf
 tsprintf

=head1 REQUIREMENTS

This module is dependent upon the following other CPAN modules:

 Readonly
 Exception::Class

=head1 DIAGNOSTICS

Text::Printf uses L<Exception::Class> objects for throwing exceptions.
If you're not familiar with Exception::Class, don't worry; these
exception objects work just like C<$@> does with C<die> and C<croak>,
but they are easier to work with if you are trapping errors.

All exceptions thrown by Text::Printf have a base class of
Text::Printf::X.  You can trap errors with an eval block:

 eval { $letter = $template->fill(@hashrefs); };

and then check for errors as follows:

 if (Text::Printf::X->caught())  {...

You can look for more specific errors by looking at a more specific
class:

 if (Text::Printf::X::KeyNotFound->caught())  {...

Some exceptions provide further information, which may be useful
for your exception handling:

 if (my $ex = Text::Printf::X::OptionError->caught())
 {
     warn "Bad option: " . $ex->name();
     ...

If you choose not to (or cannot) handle a particular type of exception
(for example, there's not much to be done about a parameter error),
you should rethrow the error:

 if (my $ex = Text::Printf::X->caught())
 {
     if ($ex->isa('Text::Printf::X::SomethingUseful'))
     {
         ...
     }
     else
     {
         $ex->rethrow();
     }
 }

=over 4

=item * Parameter errors

Class: C<Text::Printf::X::ParameterError>

You called a Text::Printf method with one or more bad parameters.
Since this is almost certainly a coding error, there is probably not
much use in handling this sort of exception.

As a string, this exception provides a human-readable message about
what the problem was.

=item * Failure to set template text

Class: C<Text::Printf::X::NoText>

You created a template object with no template text, and you never
subsequently called the L</text> method to set the template text,
and you called L</fill> to render the text.

=item * Option errors

Class C<Text::Printf::X::OptionError>

There's an error in one or more options passed to the constructor
L</new>.

This exception has one method, C<name()>, which returns the name of
the option that had a problem (for example, 'C<delimiters>').

As a string, this exception provides a human-readable message about
what the problem was.

=item * Unresolved symbols

Class C<Text::Printf::X::KeyNotFound>

One or more subsitution keywords in the template string were not found
in any of the value hashes passed to L</fill>, L</pre_fill>, or
L</default>.  This exception is thrown by L</fill>.

This exception has one method, C<symbols()>, which returns a reference
to an array containing the names of the keywords that were not found.

As a string, this exception resolves to C<"Could not resolve the
following symbols:"> followed by a list of the unresolved symbols.

=item * Internal errors

Class C<Text::Printf::X::InternalError>

Something happened that I thought couldn't possibly happen.  I would
be grateful if you would send me an email message detailing the
circumstances of the error.

=back

=head1 AUTHOR / COPYRIGHT

Copyright (c) 2005-2008 by Eric J. Roode, ROODE I<-at-> cpan I<-dot-> org

All rights reserved.

To avoid my spam filter, please include "Perl", "module", or this
module's name in the message's subject line, and/or GPG-sign your
message.

This module is copyrighted only to ensure proper attribution of
authorship and to ensure that it remains available to all.  This
module is free, open-source software.  This module may be freely used
for any purpose, commercial, public, or private, provided that proper
credit is given, and that no more-restrictive license is applied to
derivative (not dependent) works.

Substantial efforts have been made to ensure that this software meets
high quality standards; however, no guarantee can be made that there
are no undiscovered bugs, and no warranty is made as to suitability to
any given use, including merchantability.  Should this module cause
your house to burn down, your dog to collapse, your heart-lung machine
to fail, your spouse to desert you, or George Bush to be re-elected, I
can offer only my sincere sympathy and apologies, and promise to
endeavor to improve the software.

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.4.9 (Cygwin)

iEYEARECAAYFAkhNwvIACgkQwoSYc5qQVqouUQCdFaj/sTSvQpaiGX85zznYGd6m
7xkAn2cVvf5xay/mV04TiqAXlCVoq1IT
=xQ2H
-----END PGP SIGNATURE-----

=end gpg
