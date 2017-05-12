# reform.pm
#
# Third millenium syntax for Perl 5 OOP.
# Written by Henning Koch <jaz@netalive.org>.

use strict;
package reform;

our $VERSION = 0.3;

use Filter::Simple;

# Filters the code of a package.
# This is going to be even more ugly than usual as we
# want to preserve whitespace so line numbers won't change.
sub process
{
	
	my ($code) = @_;
	
	$code =~ s/ \b fields (\s+) ([\w\s\,]+) (\s*) \;
	          /$1 . process_fields($2) . $3
	          /xse;
	          
	$code =~ s/ \b sub (\s+) (\w+) (\s*)                   # 1:space 2:subname 3:space
	                   (\( (.*?) \))? (\s*)                # 4:paramsbracket 5:params 6:space
	                   (: \s* \w+ (\(\w+\))? )? (\s*) \{   # 7:fullattr 8:attrparam 9:space
	          / "sub" . $1 . $2 . $3 . 
	                    $7 . $9 . $6 . 
	            "{ my(\$self" . ($5? ", $5" : "") . ") = \@_; "
	          /xseg;

	$code =~ s/ \b package (\s+) ([\w\:]+) 
	            ((\s*) \< (\s*) ([\w\:\,\s]+))? (\s*) \;
	          /
	           "package" . $1 . $2 . "; " . 
	           "use strict; no strict 'subs'; " .
	           $4 . $5 . 
	           process_bases($6) .
	           "use base 'Class'; " .
	           "use reform::implicit; " .
	           $7
	          /xse;

	# print "-----------------\n$code\n-----------\n";
	
	$code . "\n1;";

}

# Processes a "fields" directive.
sub process_fields
{
	my($list) = @_;
	
	$list =~ s/(\w+) ([\s,]*)
	          /"class->add_field('$1'); " . remove_commas($2)
	          /gesx;

	$list;
}

# Processes inheritance directives.
sub process_bases
{
	my($list) = @_;
	
	$list =~ s/([\w\:]+) ([\s,]*)
	          /"use base '$1'; " . remove_commas($2)
	          /gesx;
	          
	$list;
}


# Removes commas from a string.
sub remove_commas
{
	my($str) = @_;
	$str =~ s/,//g;
	$str;
}


# Called upon use.
FILTER 
{
	s/^(.*)$/process($1)/es;
}

"";


# Every reformed package inherits from Class.
package Class;

use reform::Property;

# Saves fields by class
my %fields;

# Basic constructor. When you need custom contructors,
# don't overwrite this - overwrite "initialize".
sub new
{
	my $class = shift;
	my $self = {};
	bless($self, $class);
	$self->_tie_field($_) for $self->fields;
	$self->initialize(@_);
	$self;
}


# Called by constructor. When you need custom contructors,
# overwrite this method rather than "new".
sub initialize
{
}

# Create accessors for a field.
# The accessors actually work on self->{_field}, which is "tied"
# to self->{field} through the methods get_field and set_field.
sub add_field
{
	my($self, $field) = @_;
	my $class = $self;
	ref $class and $class = ref $class;
	eval "sub $class\:\:$field : lvalue { \$_[0]->{_$field} }";
	eval "sub $class\:\:get_$field { \$_[0]->{_$field} }"
		unless $class->can("get_$field");
	eval "sub $class\:\:set_$field { \$_[0]->{_$field} = \$_[1] }"
		unless $class->can("set_$field");
	$@ and die "Could not add field $field for class $class: $@";
	push @{$fields{$class}}, $field;
	ref $self and $self->_tie_field($field);
}

# Goes through all classes in %fields and returns fields
# of any class that is a parent of self (or is self's class).
sub fields
{
	my($self) = @_;
	my %re; # Hash to weed out duplicates
	foreach my $class (keys %fields) {
		if($self->isa($class)) {
			map { $re{$_} = 1 } @{$fields{$class}};
		}
	}
	keys %re;
}

# Ties getter/setter methods to a field accessor.
sub _tie_field
{
	my($self, $field) = @_;
	tie $self->{"_$field"}, 'reform::Property', $self, $field;
}

#sub _call_base_method
#{
#	my($self, $method) = (shift, shift);
#	my $class = $self;
#	ref $class and $class = ref $class;
#	print "$self\n";
#	my @re = eval "package $class; \$self->SUPER::$method(\@_)";
#	$@ and die "Error calling base method: $@";
#	@re;
#}


=head1 NAME

reform - Third millenium syntax for Perl 5 OOP

=head1 SYNOPSIS

    use reform;

    package Class < Base;

    fields foo,
           bar,
           baz;

    sub initialize($foo, $bar, $baz)
    {
        base->initialize($foo);
        self->foo = $foo;
        self->bar = $bar;
        self->baz = $baz;
    }

    sub method
    {
        print "Hi there";
        class->static_method();
    }

    sub get_foo
    {
    	print "Getting self->foo!";
    	return self->{foo};
    }

    sub set_foo($value)
    {
    	print "Setting self->foo!";
    	self->{foo} = $value;
    }

=head1 DESCRIPTION

This module provides a less awkward syntax for Perl 5 OOP.
C<reform> must be the B<first> thing to be used in your code,
even above your package declaration.

=head2 Shorthand inheritance

Rather than using the cumbersome C<use base 'Parent'> you may write:

    package Child < Parent;

=head2 Shorthand parameters

It is no longer necessary to fish method parameters out of C<@_>:

    sub method($foo, $bar)
    {
        print "First param: $foo";
        print "Second param: $bar";
    }

=head2 Implicit self, class and base

References to the instance, the class (package) and the base class
are implicitely provided as C<self>, C<class> and C<base>:

    sub method
    {
        self->instance_method();
        class->static_method();
        base->super_class_method();
    }

=head2 Pretty field accessors

You may omit the curly brackets in C<self-E<gt>{foo}> if you declare
your field names using C<fields>:

    fields foo, bar;

    sub method {
        self->foo = "some value";
        print self->foo;
    }

You may intercept read and write access to instance fields by overwriting
getter and setter methods:

    fields foo;

    sub get_foo
    {
        print "Getting foo!";
        return self->{foo};
    }

    sub set_foo($value)
    {
        print "Setting foo!";
        self->{foo} = $value;
    }

Note that you must wrap the field names in curly brackets
to access the actual C<self-E<gt>{foo}> inside of getter and
setter methods.

=head2 Clean constructors

All reformed packages inherit a basic constructor C<new> from the C<Class> package.
When you need custom contructors, don't overwrite C<new> - overwrite C<initialize>:

    use reform;
    package Amy;

    fields foo,
           bar;

    sub initialize($foo)
    {
        self->foo = $foo;
    }

You may call the constructor of a base class by calling C<base-E<gt>initialize()>.

=head2 Dynamically adding field accessors

When you need to dynamically add field accessors, use C<self-E<gt>add_field($field)>:

    sub method
    {
        self->add_field('boo');
        self->boo = 55;
    }

Note that all objects constructed after a use of C<add_field> will also
bear the new accessors.

You may request a list of all fields currently assigned to a class by
calling C<self-E<gt>fields> or C<class-E<gt>fields>;

=head1 INSTALLING

This package should have come with three files:
C<reform.pm>, C<reform/implicit.pm> and C<reform/Property.pm>.

The only somewhat exotic CPAN package you will need to run this
is C<Filter::Simple> <L<http://search.cpan.org/~dconway/Filter-Simple-0.79/lib/Filter/Simple.pm>>.
This package comes included with Perl 5.8, so you only need to act when you're running Perl 5.6.

=head2 Installing Filter::Simple on Windows

Open a command prompt and type:

    ppm install Filter
    ppm install Text-Balanced

Now copy the document at L<http://search.cpan.org/src/DCONWAY/Filter-Simple-0.79/lib/Filter/Simple.pm>
to C<c:\perl\site\lib\Filter\Simple.pm> or wherever you store your packages.

=head2 Installing Filter::Simple anywhere else

I guess copying C<Filter::Util::Call>, C<Text::Balanced>, C<Filter::Simple> and all their prerequisites
from CPAN should work.

=head1 EXPORTS

C<self>, C<class>, C<base>.

=head1 BUGS

Plenty I'm sure.

=head1 UPDATES

Will be posted to CPAN.

=head1 COPYRIGHT

Copyright (C) 2004 Henning Koch. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Henning Koch <jaz@netalive.org>

=cut

1;
