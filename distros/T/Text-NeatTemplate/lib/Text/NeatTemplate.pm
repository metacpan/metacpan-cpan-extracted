package Text::NeatTemplate;
$Text::NeatTemplate::VERSION = '0.1300';
use strict;
use warnings;

=head1 NAME

Text::NeatTemplate - a fast, middleweight template engine.

=head1 VERSION

version 0.1300

=head1 SYNOPSIS

    use Text::NeatTemplate;

    my $tobj = Text::NeatTemplate->new();

    $result = $tobj->fill_in(data_hash=>\%data,
			     show_names=>\%names,
			     template=>$text);

=head1 DESCRIPTION

This module provides a simple, middleweight but fast template engine,
for when you need speed rather than complex features, yet need more features
than simple variable substitution.

=head2 Markup Format

The markup format is as follows:

=over

=item {$varname}

A variable; will display the value of the variable, or nothing if
that value is empty.

=item {$varname:format}

A formatted variable; will apply the formatting directive(s) to
the value before displaying it.

=item {?varname stuff [$varname] more stuff}

A conditional.  If the value of 'varname' is not empty, this will
display "stuff value-of-variable more stuff"; otherwise it displays
nothing.

    {?var1 stuff [$var1] thing [$var2]}

This would use both the values of var1 and var2 if var1 is not
empty.

=item {?varname stuff [$varname] more stuff!!other stuff}

A conditional with "else".  If the value of 'varname' is not empty, this
will display "stuff value-of-variable more stuff"; otherwise it displays
"other stuff".

This version can likewise use multiple variables in its display parts.

    {?var1 stuff [$var1] thing [$var2]!![$var3]}

=item {&funcname(arg1,...,argN)}

Call a function with the given args; the return value of the
function will be what is put in its place.

    {&MyPackage::myfunc(stuff,[$var1])}

This would call the function myfunc in the package MyPackage, with the
arguments "stuff", and the value of var1.

Note, of course, that if you have a more complicated function and
are processing much data, this will slow things down.

=back

=head2 Limitations

To make the parsing simpler (and therefore faster) there are certain
restrictions in what this module can do:

=over

=item *

One cannot escape '{' '}' '[' or ']' characters.  However, the substitution
is clever enough so that you may be able to use them inside conditional
constructs, provided the use does not resemble a variable.

For example, to get a value surrounded by {}, the following
will not work:

{{$Var1}}

However, this will:

{?Var1 {[$Var1]}}

=item *

One cannot have nested variables.

=item *

Conditionals are limited to testing whether or not the variable
has a value.  If you want more elaborate tests, or tests on more
than one value, you'll have to write a function to do it, and
use the {&function()} construct.

=item *

Function arguments (as given with the {&funcname(arg1,arg2...)} format)
cannot have commas in them, since commas are used to separate the
arguments.

=back

=head2 Justification For Existence

When I was writing SQLite::Work, I originally tried using L<Text::Template>
(my favourite template engine) and also tried L<Text::FillIn>.  Both
of them had some lovely, powerful features.  Unfortunately, they were
also relatively slow.  In testing them with a 700-row table, using
Text::Template took about 15 seconds to generate the report, and using
Text::FillIn took 45 seconds!  Rolling my own very simple template
engine cut the time down to about 7 seconds.

The reasons for this aren't that surprising.  Because Text::Template
is basically an embedded Perl engine, it has to run the interpreter
on each substitution.  And Text::FillIn has a lot to do, what with being
very generic and very recursive.

The trade-off for the speed-gain of Text::NeatTemplate is that
it is quite simple.  There is no nesting or recursion, there are
no loops.  But I do think I've managed to grab some of the nicer features
of other template engines, such as limited conditionals, and formatting,
and, the most powerful of all, calling external functions.

This is a middleweight engine rather than a lightweight one, because
I needed more than just simple variable substitution, such as one
has with L<Template::Trivial>.  I consider the trade-off worth it,
and others might also, so I made this a separate module.

=head1 FORMATTING

As well as simple substitution, this module can apply formatting
to values before they are displayed.

For example:

{$Money:dollars}

will give the value of the I<Money> variable formatted as a dollar value.

Formatting directives are:

=over

=item alpha

Convert to a string containing only alphanumeric characters
(useful for anchors or filenames)

=item alphadash

Convert to a string containing alphanumeric characters, dashes
and underscores; spaces are converted to underscores.
(useful for anchors or filenames)

=item alphahash

Convert to a string containing only alphanumeric characters
and then prefix with a hash (#) character
(useful for anchors or tags)

=item alphahyphen

Convert to a string containing alphanumeric characters, dashes
and underscores; spaces are converted to hyphens.
(useful for anchors or filenames)

=item comma_front

Put anything after the last comma at the front (as with an author name)
For example, "Smith,Sarah Jane" becomes "Sarah Jane Smith".

=item dollars

Return as a dollar value (float of precision 2)

=item email

Convert to a HTML mailto link.

=item float

Convert to float.

=item hmail

Convert to a "humanized" version of the email, with the @ and '.'
replaced with "at" and "dot".  This is useful to prevent spambots
harvesting email addresses.

=item html

Convert to simple HTML (simple formatting)

=item int

Convert to integer

=item itemI<num>

Assume that the value is multiple values separated by the "pipe" symbol (|) and
select the item with an index of I<num> (starting at zero)

=item items_I<directive>

Assume that the value is multiple values separated by the "pipe" symbol (|) and
split the values into an array, apply the I<directive> directive to them, and
join them together with a space.

=item itemsjslash_I<directive>

Like items_I<directive>, but the results are joined together with a slash between them.

=item itemslashI<num>

Assume that the value is multiple values separated by the "slash" symbol (/) and
select the item with an index of I<num> (starting at zero)
Good for selecting out components of pathnames.

=item lower

Convert to lower case.

=item month

Convert the number value to an English month name.

=item namedalpha

Similar to 'alpha', but prepends the 'name' of the value.
Assumes that the name is only alphanumeric.

=item nth

Convert the number value to a N-th value.  Numbers ending with 1 have 'st'
appended, 2 have 'nd' appended, 3 have 'rd' appended, and everything
else has 'th' appended.

=item percent

Show as if the value is a percentage.

=item pipetocomma

Assume that the value is multiple values separated by the "pipe" symbol (|) and replace
those with a comma and space.

=item pipetoslash

Assume that the value is multiple values separated by the "pipe" symbol (|) and replace
those with a forward slash (/).

=item proper

Convert to a Proper Noun.

=item string

Return the value with no change.

=item title

Put any trailing ",The" ",A" or ",An" at the front (as this is a title)

=item truncateI<num>

Truncate to I<num> length.

=item upper

Convert to upper case.

=item url

Convert to a HTML href link.

=item wikilink

Format the value as the most common kind of wikilink, that is [[I<value>]]

=item wordsI<num>

Give the first I<num> words of the value.

=back

=cut


=head1 CLASS METHODS

=head2 new

my $tobj = Text::NeatTemplate->new();

Make a new template object.

=cut

sub new {
    my $class = shift;
    my %parameters = @_;
    my $self = bless ({%parameters}, ref ($class) || $class);

    return ($self);
} # new


=head1 METHODS

=head2 fill_in

Fill in the given values.

    $result = $tobj->fill_in(data_hash=>\%data,
			     show_names=>\%names,
			     template=>$text);

The 'data_hash' is a hash containing names and values.

The 'show_names' is a hash saying which of these "variable names"
ought to be displayed, and which suppressed.  This can be useful
if you want to use a more generic template, and then dynamically
suppress certain values at runtime.

The 'template' is the text of the template.

=cut
sub fill_in {
    my $self = shift;
    my %args = (
	data_hash=>undef,
	show_names=>undef,
	template=>undef,
	@_
    );

    my $out = $args{template};
    $out =~ s/{([^}]+)}/$self->do_replace(data_hash=>$args{data_hash},show_names=>$args{show_names},targ=>$1)/eg;

    return $out;
} # fill_in

=head2 get_varnames

Find variable names inside the given template.

    @varnames = $tobj->get_varnames(template=>$text);

=cut
sub get_varnames {
    my $self = shift;
    my %args = (
	template=>undef,
	@_
    );
    my $template = $args{template};

    return '' if (!$template);

    my %varnames = ();
    # { (the regex below needs matching)
    while ($template =~ m/{([^}]+)}/g)
    {
	my $targ = $1;

	if ($targ =~ /^\$(\w+[-:\w]*)$/)
	{
	    my $val_id = $1;
	    $varnames{$val_id} = 1;
	}
	elsif ($targ =~ /^\?([-\w]+)\s(.*)!!(.*)$/)
	{
	    my $val_id = $1;
	    my $yes_t = $2;
	    my $no_t = $3;

	    $varnames{$val_id} = 1;

	    foreach my $substr ($yes_t, $no_t)
	    {
		while ($substr =~ /\[(\$[^\]]+)\]/)
		{
		    $varnames{$1} = 1;
		}
	    }
	}
	elsif ($targ =~ /^\?([-\w]+)\s(.*)$/)
	{
	    my $val_id = $1;
	    my $yes_t = $2;

	    $varnames{$val_id} = 1;
	    while ($yes_t =~ /\[(\$[^\]]+)\]/)
	    {
		$varnames{$1} = 1;
	    }
	}
	elsif ($targ =~ /^\&([-\w:]+)\((.*)\)$/)
	{
	    # function
	    my $func_name = $1;
	    my $fargs = $2;
	    while ($fargs =~ /\[(\$[^\]]+)\]/)
	    {
		$varnames{$1} = 1;
	    }
	}
    }
    return sort keys %varnames;
} # get_varnames

=head2 do_replace

Replace the given value.

    $val = $tobj->do_replace(targ=>$targ,
			     data_hash=>$data_hashref,
			     show_names=>\%show_names);

Where 'targ' is the target value, which is either a variable target,
or a conditional target.

The 'data_hash' is a hash containing names and values.

The 'show_names' is a hash saying which of these "variable names"
ought to be displayed, and which suppressed.

This can do templating by using the exec ability of substitution, for
example:

    $out =~ s/{([^}]+)}/$tobj->do_replace(data_hash=>$data_hash,targ=>$1)/eg;

=cut
sub do_replace {
    my $self = shift;
    my %args = (
	targ=>'',
	data_hash=>undef,
	show_names=>undef,
	@_
    );
    my $targ = $args{targ};

    return '' if (!$targ);
    if ($targ =~ /^\$(\w+[-:\w]*)$/)
    {
	my $val = $self->get_value(val_id=>$1,
	    data_hash=>$args{data_hash},
	    show_names=>$args{show_names});
	if (defined $val)
	{
	    return $val;
	}
	else # not a variable -- return nothing
	{
	    return '';
	}
    }
    elsif ($targ =~ /^\?([-\w]+)\s(.*)!!(.*)$/)
    {
	my $val_id = $1;
	my $yes_t = $2;
	my $no_t = $3;
	my $val = $self->get_value(val_id=>$val_id,
	    data_hash=>$args{data_hash},
	    show_names=>$args{show_names});
	if ($val)
	{
	    $yes_t =~ s/\[(\$[^\]]+)\]/$self->do_replace(data_hash=>$args{data_hash},show_names=>$args{show_names},targ=>$1)/eg;
	    return $yes_t;
	}
	else # no value, return alternative
	{
	    $no_t =~ s/\[(\$[^\]]+)\]/$self->do_replace(data_hash=>$args{data_hash},show_names=>$args{show_names},targ=>$1)/eg;
	    return $no_t;
	}
    }
    elsif ($targ =~ /^\?([-\w]+)\s(.*)$/)
    {
	my $val_id = $1;
	my $yes_t = $2;
	my $val = $self->get_value(val_id=>$val_id,
	    data_hash=>$args{data_hash},
	    show_names=>$args{show_names});
	if ($val)
	{
	    $yes_t =~ s/\[(\$[^\]]+)\]/$self->do_replace(data_hash=>$args{data_hash},show_names=>$args{show_names},targ=>$1)/eg;
	    return $yes_t;
	}
	else # no value, return nothing
	{
	    return '';
	}
    }
    elsif ($targ =~ /^\&([-\w:]+)\((.*)\)$/)
    {
	# function
	my $func_name = $1;
	my $fargs = $2;
        # split the args first, and replace each one separately
        # just in case the data values have commas
        my @fargs = split(/,/,$fargs);
        my @processed = ();
        foreach my $fa (@fargs)
        {
	    $fa =~ s/\[(\$[^\]]+)\]/$self->do_replace(data_hash=>$args{data_hash},show_names=>$args{show_names},targ=>$1)/eg;
            push @processed, $fa;
        }
	{
	    no strict('refs');
	    return &{$func_name}(@processed);
	}
    }
    else
    {
	print STDERR "UNKNOWN ==$targ==\n";
    }
    return '';
} # do_replace

=head2 get_value

$val = $tobj->get_value(val_id=>$val_id,
			data_hash=>$data_hashref,
			show_names=>\%show_names);

Get and format the given value.

=cut
sub get_value {
    my $self = shift;
    my %args = (
	val_id=>'',
	data_hash=>undef,
	show_names=>undef,
	@_
    );
    my ($varname, @formats) = split(':', $args{val_id});

    my $value;
    if (exists $args{data_hash}->{$varname})
    {
	if (!$args{show_names}
	    or $args{show_names}->{$varname})
	{
	    $value = $args{data_hash}->{$varname};
	}
	else
	{
	    return '';
	}
    }
    else
    {
	return undef;
    }

    # we have a value to format
    foreach my $format (@formats) { 
	$value = $self->convert_value(value=>$value,
	    format=>$format,
	    name=>$varname); 
    }
    if ($value and $self->{escape_html})
    {
	# filter out some HTML stuff
	$value =~ s/ & / &amp; /g;
    }
    return $value;
} # get_value

=head2 convert_value

    my $val = $tobj->convert_value(value=>$val,
				   format=>$format,
				   name=>$name);

Convert a value according to the given formatting directive.

See L</FORMATTING> for details of all the formatting directives.


=cut
sub convert_value {
    my $self = shift;
    my %args = @_;
    my $value = $args{value};
    my $style = $args{format};
    my $name = $args{name};

    $value ||= '';
    ($_=$style) || ($_ = 'string');
    SWITCH: {
	/^upper/i &&     (return uc($value));
	/^lower/i &&     (return lc($value));
	/^int/i &&       (return (defined $value ? int($value) : 0));
	/^float/i &&     (return (defined $value && sprintf('%f',($value || 0))) || '');
	/^string/i &&    (return $value);
	/^trunc(?:ate)?(\d+)/ && (return substr(($value||''), 0, $1));
	/^dollars/i &&
	    (return (defined $value && length($value)
		     && sprintf('%.2f',($value || 0)) || ''));
	/^percent/i &&
	    (return (($value<0.2) &&
		     sprintf('%.1f%%',($value*100))
		     || sprintf('%d%%',int($value*100))));
	/^url/i &&    (return "<a href='$value'>$value</a>");
	/^wikilink/i &&    (return "[[$value]]");
	/^email/i &&    (return "<a mailto='$value'>$value</a>");
	/^hmail/i && do {
	    $value =~ s/@/ at /;
	    $value =~ s/\./ dot /g;
	    return $value;
	};
	/^html/i &&	 (return $self->simple_html($value));
	/^title/i && do {
	    $value =~ s/(.*)[,;]\s*(A|An|The)$/$2 $1/;
	    return $value;
	};
	/^comma_front/i && do {
	    $value =~ s/(.*)[,]([^,]+)$/$2 $1/;
	    return $value;
	};
	/^proper/i && do {
	    $value =~ s/(^w|\b\w)/uc($1)/eg;
	    return $value;
	};
	/^month/i && do {
	    return $value if !$value;
	    return ($value == 1
		    ? 'January'
		    : ($value == 2
		       ? 'February'
		       : ($value == 3
			  ? 'March'
			  : ($value == 4
			     ? 'April'
			     : ($value == 5
				? 'May'
				: ($value == 6
				   ? 'June'
				   : ($value == 7
				      ? 'July'
				      : ($value == 8
					 ? 'August'
					 : ($value == 9
					    ? 'September'
					    : ($value == 10
					       ? 'October'
					       : ($value == 11
						  ? 'November'
						  : ($value == 12
						     ? 'December'
						     : $value
						    )
						 )
					      )
					   )
					)
				     )
				  )
			       )
			    )
			  )
			  )
	    );
	};
	/^nth/i && do {
	    return $value if !$value;
	    return ($value =~ /1[123]$/
		    ? "${value}th"
		    : ($value =~ /1$/
		       ? "${value}st"
		       : ($value =~ /2$/
			  ? "${value}nd"
			  : ($value =~ /3$/
			     ? "${value}rd"
			     : "${value}th"
			    )
			 )
		      )
		   );
	};
	/^facettag/i && do {
	    $value =~ s!/! !g;
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
	    $value =~ s/[^\w\s:_-]//g;
	    $value =~ s/\s\s+/ /g;
	    $value =~ s/ /_/g;
	    $value = join(':', $name, $value);
	    return $value;
	};
	/^namedalpha/i && do {
	    $value =~ s/[^a-zA-Z0-9]//g;
	    $value = join('_', $name, $value);
	    return $value;
	};
	/^alphadash/i && do {
	    $value =~ s!/! !g;
	    $value =~ s/[^a-zA-Z0-9_\s-]//g;
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
	    $value =~ s/\s\s+/ /g;
	    $value =~ s/ /_/g;
	    return $value;
	};
	/^alphahyphen/i && do {
	    $value =~ s!/! !g;
	    $value =~ s/[^a-zA-Z0-9_\s-]//g;
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
	    $value =~ s/\s\s+/ /g;
	    $value =~ s/ /-/g;
	    return $value;
	};
	/^alphahash/i && do {
	    $value =~ s/[^a-zA-Z0-9]//g;
            $value = "#${value}";
	    return $value;
	};
	/^alpha/i && do {
	    $value =~ s/[^a-zA-Z0-9]//g;
	    return $value;
	};
	/^pipetocomma/i && do {
	    $value =~ s/\|/, /g;
	    return $value;
	};
	/^pipetoslash/i && do {
	    $value =~ s/\|/\//g;
	    return $value;
	};
	/^words(\d+)/ && do {
	    my $ct = $1;
	    ($ct>0) || return '';
	    my @sentence = split(/\s+/, $value);
	    my (@words) = splice(@sentence,0,$ct);
	    return join(' ', @words);
	};
	/^wlink_(\w+)/ && do {
	    my $prefix = $1;
	    return "[[$prefix/$value]]";
	};
	/^tagify/i && do {
	    $value =~ s/\|/,/g;
	    $value =~ s!/! !g;
	    $value =~ s/!/ /g;
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
	    $value =~ s/[^\w,\s_-]//g;
	    $value =~ s/\s\s+/ /g;
	    $value =~ s/ /_/g;
	    return $value;
	};
	/^item(\d+)/ && do {
	    my $ct = $1;
	    ($ct>=0) || return '';
	    my @items = split(/\|/, $value);
	    return $items[$ct];
	};
	/^itemslash(\d+)/ && do {
	    my $ct = $1;
	    ($ct>=0) || return '';
	    my @items = split(/\//, $value);
	    return $items[$ct];
	};
	/^items_(\w+)/ && do {
	    my $next = $1;
	    my @items = split(/[\|,]\s*/, $value);
	    my @next_items = ();
	    foreach my $item (@items)
	    {
		push @next_items, $self->convert_value(%args, value=>$item, format=>$next);
	    }
	    return join(' ', @next_items);
	};
	/^itemsjslash_(\w+)/ && do {
	    my $next = $1;
	    my @items = split(/[\|,]\s*/, $value);
	    my @next_items = ();
	    foreach my $item (@items)
	    {
		push @next_items, $self->convert_value(%args, value=>$item, format=>$next);
	    }
	    return join(' / ', @next_items);
	};
	/^itemsjcomma_(\w+)/ && do {
	    my $next = $1;
	    my @items = split(/[\|,]\s*/, $value);
	    my @next_items = ();
	    foreach my $item (@items)
	    {
		push @next_items, $self->convert_value(%args, value=>$item, format=>$next);
	    }
	    return join(',', @next_items);
	};

	# otherwise, give up
	return "  {{{ style $style not supported }}}  ";
    }
} # convert_value

=head2 simple_html

$val = $tobj->simple_html($val);

Do a simple HTML conversion of the value.
bold, italic, <br>

=cut
sub simple_html {
    my $self = shift;
    my $value = shift;

    $value =~ s#\n[\s][\s][\s]+#<br/>\n&nbsp;&nbsp;&nbsp;&nbsp;#sg;
    $value =~ s#\s*\n\s*\n#<br/><br/>\n#sg;
    $value =~ s#\*([^*]+)\*#<i>$1</i>#sg;
    $value =~ s/\^([^^]+)\^/<b>$1<\/b>/sg;
    $value =~ s/\#([^#<>]+)\#/<b>$1<\/b>/sg;
    $value =~ s/\s&\s/ &amp; /sg;
    return $value;
} # simple_html

=head1 Callable Functions

=head2 safe_backtick

{&safe_backtick(myprog,arg1,arg2...argN)}

Return the results of a program, without risking evil shell calls.
This requires that the program and the arguments to that program
be given separately.

=cut
sub safe_backtick {
    my @prog_and_args = @_;
    my $progname = $prog_and_args[0];

    # if they didn't give us anything, return
    if (!$progname)
    {
	return '';
    }
    # call the program
    # do a fork and exec with an open;
    # this should preserve the environment and also be safe
    my $result = '';
    my $fh;
    my $pid = open($fh, "-|");
    if ($pid) # parent
    {
	{
	    # slurp up the result all at once
	    local $/ = undef;
	    $result = <$fh>;
	}
	close($fh) || warn "$progname program script exited $?";
    }
    else # child
    {
	# call the program
	# force exec to use an indirect object,
	# so that evil shell stuff will die, even
	# for a program with no arguments
	exec { $progname } @prog_and_args or die "$progname failed: $!\n";
	# NOTREACHED
    }
    return $result;
} # safe_backtick

=head2 format_items

{&format_items(fieldname,value,delim,outdelim,format,prefix,suffix)}

Format a field made of multiple items.

=cut
sub format_items {
    my $fieldname = shift;
    my $value = shift;
    my @args = @_;

    # if they didn't give us anything, return
    if (!$fieldname)
    {
	return '';
    }
    if (!$value)
    {
	return '';
    }

    my $delim = $args[0] || '|';
    my $outdelim = $args[1] || ' ';
    my $format = $args[2] || 'raw';
    my $prefix = $args[3] || '';
    my $suffix = $args[4] || '';
    $delim =~ s/comma/,/g;
    $delim =~ s/pipe/|/g;
    $delim =~ s!slash!/!g;
    $outdelim =~ s/comma/,/g;
    $outdelim =~ s/pipe/|/g;
    $outdelim =~ s!slash!/!g;
    my @items = split(/\Q$delim\E\s*/, $value);
    my @next_items = ();
    foreach my $item (@items)
    {
        push @next_items,
        Text::NeatTemplate->convert_value(name=>$fieldname,
                                          value=>$item,
                                          format=>$format);
    }
    return $prefix . join($outdelim, @next_items) . $suffix;
} # format_items


=head1 REQUIRES

    Test::More

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the module.

Therefore you will need to change the PERL5LIB variable to add
/home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 SEE ALSO

L<Text::Template>
L<Text::FillIn>
L<Text::QuickTemplate>
L<Template::Trivial>
L<Template::Toolkit>
L<HTML::Template>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.org/tools

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2006 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Text::NeatTemplate
__END__
