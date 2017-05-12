package Text::FillIn;
use Carp;
use FileHandle;
use strict;
use vars qw($VERSION %DEFAULT);
$VERSION = '0.05';

# Set a bunch of defaults
%DEFAULT = (
	'path' => ['.'],
	'$hook' => 'find_value',
	'&hook' => 'run_function',
	'Ldelim' => '[[',
	'Rdelim' => ']]',
	'text' => '',
	'properties' => {},
	'object' => undef,
);

sub new {
	my $package = shift;
	my $text = shift;
	
	my $self = {
		%DEFAULT,
		'text' => $text,
	};

	# Copy the special structures so we don't share their memory
	$self->{'properties'} = { %{$self->{'properties'}} };
	$self->{'path'} = [ @{$self->{'path'}} ];
	
	return bless ($self, $package);
}

sub get_file {
	my $self = shift;
	my $file = shift;
	
	if ($file eq 'null') {
		$self->{'text'} = '';
		return;
	}
	
	# Find out what file to open:
	my $realfile;
	if ($file =~ /^\//) {
		$realfile = $file;
	} else {
		foreach my $dir ($self->path()) {
			if ( -f "$dir/$file" ) {
				$realfile = "$dir/$file";
				last;
			}
		}
	}

	unless ($realfile  and  -f $realfile) {
		warn ("Can't find file '$file' in (@{[$self->path()]})");
		return 0;
	}

	my $fh = new FileHandle($realfile);
	unless ( defined $fh ) {
		warn ("Can't open $realfile: $!");
		$self->{'text'} = '';
		return 0;
	}
	
	$self->{'text'} = join('', $fh->getlines );
	return 1;
}

sub Ldelim { my $s = shift; $s->_prop('Ldelim', @_) }
sub Rdelim { my $s = shift; $s->_prop('Rdelim', @_) }
sub text   { my $s = shift; $s->_prop('text',   @_) }
sub object { my $s = shift; $s->_prop('object', @_) }

sub hook {
	my $self = shift;
	my $char = shift;
	return $self->_prop($char.'hook', @_);
}

sub path {
	my $self = shift;
	return @{ (@_ ? $self->_prop('path', [@_]) : $self->_prop('path')) };
}

sub property {
	my $self = shift;
	my $prop = shift;
	
	# Which SV we should get or set - this object only, or the default
	my $get_set = (ref $self ? \($self->{'properties'}{$prop}) : \($DEFAULT{'properties'}{$prop}));
	
	if (@_) {
		# Set the property
		$$get_set = shift;
	}
	return $$get_set;
}


sub interpret {
	my $self = shift;
	$self->_interpret_engine('collect');
}

sub interpret_and_print {
	my $self = shift;
	$self->_interpret_engine('print');
}

# Deprecated - use text()
sub set_text {
	my $self = shift;
	my $text = shift;
	
	$self->{'text'} = $text;
}

# Deprecated - use text()
sub get_text {
	my $self = shift;
	
	return $self->{'text'};
}

# Deprecated - use property()
sub get_property {
	my $self = shift;
	my $prop_name = shift;
	
	return $self->{'properties'}->{$prop_name};
}

# Deprecated - use property()
sub set_property {
	my $self = shift;
	my $prop_name = shift;
	my $prop_val = shift;
	
	$self->{'properties'}->{$prop_name} = $prop_val;
}



############################# Private functions

sub _prop {
	my $self = shift;
	my $prop = shift;
	
	# Which SV we should get or set - this object only, or the default
	my $get_set = (ref $self ? \($self->{$prop}) : \($DEFAULT{$prop}));
	
	if (@_) {
		# Set the property
		$$get_set = shift;
	}
	return $$get_set;
}

sub _deal_with {
	my ($text, $style, $outref) = @_;
	if ($style eq 'print') {
		print $text;
	} elsif ($style eq 'collect') {
		${$outref} .= $text;
	}
}

sub _interpret_engine {

	my $self = shift;
	my $style = shift;
	my ($first_right, $first_left, $last_left, $out_text, $save);
	my $debug = 0;
	my $text = $self->{'text'};   # Duplicates memory, I'll clean up later
	
	my ($ld, $rd) = ($self->Ldelim(), $self->Rdelim());
	warn "Delimiters are $ld and $rd" if $debug;

	while (1) {

		warn ("interpreting '$text'") if $debug;
		# Shave off any leading plain text before the first real [[
		my ($prelength, $pretext);
		$first_left = &_real_index($text, $ld);
		warn ("first left is at $first_left") if $debug;
		if ( $first_left == -1 ) {
			# No more to do, just spit out the text
			$self->_unquote(\$text);
			&_deal_with($text, $style, \$out_text);
			last;
			
		} elsif ($first_left > 0) { # There's a real [[ here
			$pretext = substr($text, 0, $first_left);
			$self->_unquote(\$pretext);
			&_deal_with($pretext, $style, \$out_text);
			substr($text, 0, $first_left) = '';
			next;
		}
		
		# There's now a real [[ at position 0.
		# Find the first right delimiter and fill in before it:
		$first_right = &_real_index($text, $rd);
		warn ("first right is at $first_right") if $debug;
		$last_left = &_real_index(substr($text, 0, $first_right), $ld, 1);
		warn ("last left is at $last_left") if $debug;
		
		if ($first_right == -1) { # Something's amiss, abort
			warn ("Problem interpreting text " . substr($text, 0, $first_right));
			&_deal_with($text, $style, \$out_text);
			last;
		}
		# Fill in the text in between the first right delimiter and the last left delimiter before it:
		substr($text, $last_left, $first_right - $last_left + length($rd)) =
		   $self->_do_interpret(substr($text, $last_left, $first_right - $last_left + length($rd)));
	}
	return $out_text;
}

sub _real_index {
	# Finds the first occurrence of $exp in $text before 
	# position $before that doesn't follow a backslash
	
	my $text = shift;
	my $exp = shift;
	my $last = shift;
	
	if ($last) {
		if ($text =~ /  (.*)(^|[^\\]) \Q$exp/sx) {
			return(length($1) + length($2));
		} else {
			return -1;
		}
	} else {
		if ($text =~ / (.*?)(^|[^\\]) \Q$exp/sx) {
			return (length($1) + length($2));
		} else {
			return -1;
		}
	}
}

sub _unquote {
	my $self = shift;
	my $textref = shift;
	
	my ($ldx, $rdx) = map {quotemeta} ($self->Ldelim(), $self->Rdelim());
	${$textref} =~ s/ \\( $ldx | $rdx ) /$1/xgs;
}

sub _do_interpret {
	my $self = shift;
	my $string = shift;
	
	my ($ldx, $rdx) = map {quotemeta} ($self->Ldelim(), $self->Rdelim());
	
	unless ($string =~ /^ $ldx \s*  ([\W])  (.*?) \s*  $rdx $/sx ) {
		# Looks like we weren't meant to see this - but we can't interpret it again either
		carp ("Can't interpret template chunk '$string'");
		return;
	}
	my ($char, $guts) = ($1, $2);
	
	my ($hook, $object);
	if (defined ($hook = $self->hook($char))) {
		no strict('refs');  # Allow symbolic name substitution for a little while
		if (defined ($object = $self->object())) {
			return $object->$hook($guts, $char);
		} else {
			return &{$hook}($guts, $char);
		}
	} else {
		croak ("No interpret hook defined for type '$1'");
	}
}


############################ Sample hook functions ##########################


sub find_value { $main::TVars{ $_[0] } }

sub run_function {
   # Usage: $result = &run_function("some_function(param1,param2,param3)");
	my $text = shift;
   my ($function_name, $args) = $text =~ /(\w+)\((.*)\)/
      or die ("Can't understand function call '$text'");
	no strict('refs');  # Allow symbolic name substitution for a little while
   return &{"TExport::$function_name"}( split(/,/, $args) );
}


1;

__END__


=head1 NAME

Text::FillIn.pm - a class implementing a fill-in template

=head1 SYNOPSIS

 use Text::FillIn;
 
 # Set the functions to do the filling-in:
 Text::FillIn->hook('$', sub { return ${$_[0]} });  # Hard reference
 Text::FillIn->hook('&', "main::run_function");     # Symbolic reference
 sub run_function { return &{$_[0]} }
 
 $template = new Text::FillIn('some text with [[$vars]] and [[&routines]]');
 $filled_in = $template->interpret();  # Returns filled-in template
 print $filled_in;
 $template->interpret_and_print();  # Prints template to currently 
                                    # selected filehandle
 
 # Or
 $template = new Text::FillIn();
 $template->set_text('the text is [[ $[[$var1]][[$var2]] ]]');
 $TVars{'var1'} = 'two_';
 $TVars{'var2'} = 'parter';
 $TVars{'two_parter'} = 'interpreted';
 $template->interpret_and_print();  # Prints "the text is interpreted"
 
 # Or
 $template = new Text::FillIn();
 $template->get_file('/etc/template_dir/my_template');  # Fetches a file
 
 # Or
 $template = new Text::FillIn();
 $template->path('.', '/etc/template_dir');  # Where to find templates
 $template->get_file('my_template'); # Gets ./my_template or 
                                     # /etc/template_dir/my_template

=head1 DESCRIPTION

This module provides a class for doing fill-in templates.  These templates may be used
as web pages with dynamic content, e-mail messages with fill-in fields, or whatever other
uses you might think of.  B<Text::FillIn> provides handy methods for fetching files
from the disk, printing a template while interpreting it (also called streaming),
and nested fill-in sections (i.e. expressions like [[ $th[[$thing2]]ing1 ]] are legal).

Note that the version number here is 0.04 - that means that the interface may change
a bit.  In fact, it's already changed some with respect to 0.02 (see the CHANGES file).
In particular, the $LEFT_DELIM, $RIGHT_DELIM, %HOOK, and @TEMPLATE_PATH variables are 
gone, replaced by a default/instance variable system.

I might also change the default hooks or something.  Please read the CHANGES file before upgrading
to find out whether I've changed anything you use.

In this documentation, I generally use "template" to mean "an object of class Text::FillIn".

=head2 Defining the structure of templates

=over 4

=item * delimiters

B<Text::FillIn> has some special variables that it uses to do its work.  You can set
those variables and customize the way templates get filled in.

The delimiters that set fill-in sections of your form apart from the rest of the
form are generally B<[[> and B<]]>, but they don't have to be, you can set 
them to whatever you want.  So you could do this:

 Text::FillIn->Ldelim('{');
 Text::FillIn->Rdelim('}');
 $template->set_text('this is a {$variable} and a {&function}.');

Whatever you set the delimiter to, you can put backslashes before them in your
templates, to force them to be interpreted as literals:

 $template->set_text('some [[$[[$var2]][[$var]]]] and \[[ text \]]');
 $template->interpret_and_print();
 # Prints "some stuff and [[ text ]]"

You cannot currently have several different kinds of delimiters in a single template.

=item * interpretation hooks

In order to interpret templates, C<Text::FillIn> needs to know how to treat
different kinds of [[tags]] it finds.  The way it accomplishes this is through
"hook functions."  These are various functions that C<Text::FillIn> will run
when confronted with various kinds of fill-in fields.  There are two 
hooks provided by default:

 Text::FillIn->hook('$') is \&find_value,
 Text::FillIn->hook('&') is \&run_function.

So if you leave these hooks the way they are, when B<Text::FillIn> sees
some text like "some [[$vars]] and some [[&funk]]", it will run
C<&Text::FillIn::find_value> to find the value of [[$vars]], and it will
run C<&Text::FillIn::run_function> to find the value of [[&funk]].  This
is based on the first non-whitespace character after the delimiter,
which is required to be a non-word character (no letters, numbers, or
underscores).  You can define hooks for any non-word character you want:

 $template = new Text::FillIn("some [[!mushrooms]] were in my shoes!");
 $template->hook('!', "main::scream_it");  # or \&scream_it
 sub scream_it {
    my $text = shift;
    return uc($text); # Uppercase-it
 }
 $new_text = $template->interpret();
 # Returns "some MUSHROOMS were in my shoes!"

Every hook function will be passed all the text between the delimiters, without
any surrounding whitespace or the leading identifier (the & or $, or whatever).
Hooks can be given as either hard references or symbolic references,
but if they are symbolic, they need to use the complete package name and everything.

Beginning in version 0.04, you may use some object's methods as hook functions.  For
example, if you have a template C<$template> and another object C<$myObj>, you can 
instruct C<$template> to call C<$myObj-E<gt>find_value()> and 
C<$myObj-E<gt>run_function()> to fill in templates.  See the C<$template-E<gt>object()> 
method below.

=item * the default hook functions

The hook functions installed with the shipping version of this module are
C<&Text::FillIn::find_value> and C<&Text::FillIn::run_function>.  They are 
extremely simple.  I suggest you take a look at them to see how they work.
What follows here is a description of how these functions will fill in your
templates.

The C<&find_value> function looks for an entry in a hash called %main::TVars.
So put an entry in this hash if you want it to be available to templates:

 my $template = new Text::FillIn( 'hey, [[$you]]!' );
 $::TVars{'you'} = 'Sam';
 $template->interpret_and_print();  # Prints "hey, Sam!"

The C<&run_function> function looks for a function in the C<TExport> package and
runs it.  The reason it doesn't look in the main package is that you probably
don't want to make all the functions in your program available to the templates
(not that putting all your program's functions in the main package is always
the greatest programming style).  Here are a couple of ways to make functions
available:

 sub TExport::add_numbers {
    my $result;
    foreach (@_) {
       $result += $_;
    }
    return $result;
 }

 #  or, if you like:
 
 package TExport;
 sub add_numbers {
    my $result;
    foreach (@_) {
       $result += $_;
    }
    return $result;
 }

The C<&run_function> function will split the argument string at commas, and pass
the resultant list to your function:

 my $template = new Text::FillIn(
    'Pi is about [[&add_numbers(3,.1,.04,.001,.0006)]]'
 );
 $template->interpret_and_print;


In the original version of C<Text::FillIn>, I didn't provide any hook functions.
I expected people to write their own, partly because I didn't want to stifle
creativity or anything.  I now include hook functions because the ones I give
will probably work okay for most people, and providing them means it's easier
to use the module right out of "the box."  But I hope you won't be afraid to write
your own hooks - if mine don't work well for you, by all means go ahead and
replace them with your own.  If you think you've written some really killer hooks,
let me know.  I may include cool ones with future distributions.


=item * template directories

You can tell C<Text::FillIn> where to look for templates:

 Text::FillIn->path('.', '/etc/template_dir');
 $template->get_file('my_template'); # Gets ./my_template or /etc/template_dir/my_template

=back



=head1 METHODS

=over 4

=item * new Text::FillIn($text)

This is the constructor, which means it returns a new object of type B<Text::FillIn>.
If you feed it some text, it will set the template's text to be what you give it:

 $template = new Text::FillIn("some [[$vars]] and some [[&funk]]");

=item * $template->get_file( $filename );

This will look for a template called $filename (in the directories given in 
B<$template-E<gt>path()>) and slurp it in.  If $filename starts with / , 
then B<Text::FillIn> will treat $filename as an absolute path, and not search 
through the directories for it:

 $template->get_file( "my_template" );
 $template->get_file( "/weird/place/with/template" );

The default path is ('.').

=item * $template->interpret()

Returns the interpreted contents of the template:

 $interpreted_text = $template->interpret();

This, along with interpret_and_print, are the main point of this whole module.

=item * $template->interpret_and_print()

Interprets the [[ fill-in parts ]]  of a template and prints the template,
streaming its output as much as possible.  This means that if it encounters
an expression like "[[ stuff [[ more stuff]] ]]", it will fill in [[ more stuff ]],
then use the filled-in value to resolve the value of [[ stuff something ]],
and then print it out.

If it encounters an expression like "stuff1 [[thing1]] stuff2 [[thing2]]",
it will print stuff1, then the value of [[thing1]], then stuff2, then the
value of [[thing2]].  This is as streamed as possible if you want nested
brackets to resolve correctly.

=back

The following methods all get and/or set certain attributes of the template.  They can
all be called as instance methods, a la C<$template-E<gt>Ldelim()>, or as static methods,
a la C<Text::FillIn-E<gt>Ldelim()>.  Using an instance method only changes the given
template, it does not affect the properties of any other template.  Using a static method
will change the default behavior of all templates created in the future.

I think I need to reserve the right to change what happens when you create a template
$t, then change the default behavior of all templates, then call $t->interpret() -- 
should it use the new defaults or the old defaults?  Currently it uses the old
defaults, but that might change.

=over 4

=item * $template->Ldelim($new_delimiter)

=item * $template->Rdelim($new_delimiter)

Get or set the left or right delimiter.  When called with no arguments, simply returns the
delimiter.  When called with an argument, sets the delimiter.

=item * $template->text($new_text)

Get or set the contents of the template.

=item * $template->path($dir1, $dir2, ...)

Get or set the list of directories to search for templates in.  The path is used
in the get_file() method.

=item * $template->hook($character, $hook_function)

Get or set the functions for filling in the sections of the template between delimiters.  
The first argument is the non-word character the hook is installed under.  The second
argument, if present, is the function to install as a hook.  It may either be a
hard reference to a function, a string containing the fully package-qualified
name of a function, or if you're using objects to fill in your template, a method name.
See also the subsection on interpretation hooks in the DESCRIPTION section.

=item * $template->object($obj)

As of version 0.04, you may use method calls on an arbitrary object as
template hooks.  This can be very powerful.  Your code might look like this:

 $t   = new Text::FillIn("some [[$animal]]s");
 $obj = new MyClass(animal=>'chicken');  # Create some object
 $t->object($obj);  # Tell $t to use methods of $obj as hooks
 $t->hook('$', 'lookup_var');  # Set the method name for '$'
 $t->interpret_and_print();  # Calls $obj->lookup_var()

The object methods will be passed the same arguments as regular (static) hook functions.

=item * $template->property( $name, $value );

This method lets you get and set arbitrary properties of the template, like
this:

 $template->property('color', 'blue');  # Set the color
 # ... some code...
 $color = $template->property('color'); # Get the color

The B<Text::FillIn> class doesn't actually pay any attention whatsoever to
the properties - it's purely for your own convenience, so that small changes
in functionality can be achieved without having to subclass B<Text::FillIn>.

=back

=head1 COMMON MISTAKES

If you want to use nested fill-ins on your template, make sure things get 
printed in the order you think they'll be printed.  If you have something like this:
C<[[$var_number_[[&get_number]]]]>, and your &get_number I<prints> a number,
you won't get the results you probably want.  B<Text::FillIn> will print your number,
then try to interpret C<[[$var_number_]]>, which probably won't work.  

The solution is to make &get_number I<return> its number rather than I<print> it.  
Then B<Text::FillIn> will turn C<[[$var_number_[[&get_number]]]]> into 
C<[[$var_number_5]]>, and then print the value of C<$var_number_5>.  That's 
probably what you wanted.

=head1 TO DO

The deprecated methods get_text(), set_text(), get_property(), and set_property()
will be removed in version 0.06 and greater.  Use text() and property() instead.

By slick use of local() variables, it would be possible to have Text::FillIn keep track of when 
it's doing nested tags and when it's not, allowing the user to nest tags using arbitrary
depth and not have to worry about the above "common mistake."  This would let hook
functions be oblivious to whether they're supposed to print their results or return them,
since Text::FillIn would keep track of it all.  This will take some doing on my part, 
but it's not insurmountable.  It would probably involve evaluating the tags from
the outside in, rather than the inside out.

=head1 BUGS

The interpreting engine can be fooled by certain backslashing sequences like C<\\[[$var]]>,
which looks to it like the C<[[> is backslashed.  I think I know how to fix this, but I need 
to think about it a little.

=head1 AUTHOR

Ken Williams (ken@forum.swarthmore.edu)

Copyright (c) 1998 Swarthmore College. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
