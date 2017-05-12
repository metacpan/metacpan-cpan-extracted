package variable;

require 5.006;

use strict;
use warnings::register;
use warnings;
no  warnings 'syntax';


our $VERSION = '2009110702';
our %declared;

sub croak {
    require Carp;
    goto &Carp::croak (@_);
}

my %keywords         = map {$_ => 1} qw /BEGIN INIT CHECK END DESTROY AUTOLOAD/;
my %forced_into_main = map {$_ => 1} qw /STDIN STDOUT STDERR ARGV ARGVOUT
                                         ENV INC SIG/;
my %forbidden        = (%keywords, %forced_into_main);

sub import {
    my $package = shift;
    return unless @_;         # Ignore 'use variable;'.
    my $caller  = caller;
    my $name    = shift;

    croak "Can't use undef as variable name" unless defined $name;

    if ($name =~ /^_?[^\W_\d]\w*\z/ && !$forbidden {$name}) {
        # Ok.
    }
    elsif ($forced_into_main {$name} and $caller ne 'main') {
        croak "Variable name '$name' is forced into main::";
    }
    elsif ($name =~ /^__/) {
        croak "Variable name '$name' begins with '__'";
    }
    elsif ($name =~ /^[A-Za-z_]\w*\z/) {
	# Perhaps give a warning.
        if (warnings::enabled ()) {
            if ($keywords {$name}) {
                warnings::warn ("Variable name '$name' is a Perl keyword");
            }
            elsif ($forced_into_main {$name}) {
                warnings::warn ("Variable name '$name' is forced into " .
                                "package main::");
            }
            else {
                warnings::warn ("Variable name '$name' has unknown problems");
            }
        }
    }
    elsif ($name =~ /^[01]?\z/) {
        if (@_) {
            croak "Variable name '$name' is invalid";
        }
        else {
            croak "Variable name looks like a boolean value";
        }
    }

    else {
        # Must have bad characters.
        croak "Variable name '$name' has invalid characters";
    }

    if (@_ > 1) {
        croak "Variables have to be scalar";
    }

    {   
        no strict 'refs';
        my $value = shift;    # Might be undef, which is ok.
        my $full  = "${caller}::$name";
        $declared {$full} ++;
        *$full    = sub () : lvalue {$value};
    }
}

1;

__END__

=pod

=head1 NAME 

variable - Perl pragma to declare (scalar) variables without a leading C<$>.

=head1 SYNOPSIS

    use variable  spam  =>  17;
    use variable  eggs  =>  spam + 25;
    use variable "i";            # Makes "i" undefined.
    use variable  arr   =>  [qw /aap noot mies wim zus jet/];

    print eggs, "\n";            # Print 42.
          eggs += 27;
    print eggs, "\n";            # Print 69.

    for (i = 0; defined (arr -> [i]); i ++) {
        print arr -> [i], " ";   # Print aap noot mies wim zus jet.
    }

=head1 DESCRIPTION

This simple module allows you to create scalar variables that do not need
a leading C<$>. This will make people coming from a B<C> or a B<Python>
background feel more at home.

=head1 NOTES

This module requires perl 5.6.0.

The values given to the variables are evaluated in list context. You may
wish to override this by using C<scalar>.

These variables do not directly interpolate into doublequotish strings,
although you may do so indirectly. (See the perlref manpage for details
about how this works.)

    print "The value of eggs is ${\eggs}.\n";

This only works for scalar variables, not arrays or hashes.

Naming of variables follow the same rules as in C<constant.pm>. Names must
begin with a letter or underscore. Names beginning with a double underscore
are reserved. Some poor choices for names will generate warnings, if warnings
are enabled at compile time.

Variable symbols are package scoped (rather than block scoped, as
C<use strict;> is. That is, you can refer to a variable from 
package C<Other> as C<Other::var>.

As with all C<use> directives, defining a variable happens at compile time.
This, it's probably not correct to put a variable declaration inside of
a conditional statement (like C<if ($foo) {use variable ...}>).

Omitting the value for a symbol gives it the value of C<undef>. This isn't
so nice as it may sound, though, because in this case you must either
quote the symbol name, or use a big arrow C<< => >> with nothing to point to.
It is probably best to declare these explicitly.

    use variable bacon  =>  ();
    use variable ham    =>  undef;

The result from evaluating a list constant in a scalar context is B<not>
documented, and is not guaranteed to be any particular value in the
future. In particular, you should not rely upon it being the number of
elements in the list, especially since it is not B<necessarily> that value
in the current implementation.

In the rare case in which you need to discover at run time whether a
particular variable has been declared via this module, you may use
this function to examine the hash C<%variable::declared>. If the given
variable name does not include a package name, the current package is
used.

    sub declared ($) {
        use variable;                   # don't omit this!
        my $name =  shift;
           $name =~ s/^::/main::/;
        my $pkg  =  caller;
        my $full = $name =~ /::/ ? $name : "${pkg}::$name";
        $variable::declared {$full};
    }



=head1 BUGS

A variable with the name in the list
C<STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG>
is not allowed anywhere but in package C<main::>, for technical reasons.

You can get into trouble if you use variables in a context which
automatically quotes barewords (as is true for any subroutine call).
For example, you can't say C<$hash {variable}> because
C<variable> will be interpreted as a string. Use
C<$hash {variable ()}> or C<$hash {+variable}> to prevent the
bareword quoting mechanism from kicking in. Similarly, since the
C<< => >> operator quotes a bareword immediately to its left,
you have to say C<< variable () => 'value' >> (or simple use a comma
in place of the big arrow) instead of C<< variable => 'value' >>

=head1 DEVELOPMENT
 
The current sources of this module are found on github,
L<< git://github.com/Abigail/variable.git >>.

=head1 AUTHOR

This package was written by Abigail, L<< cpan@abigail.be >>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000, 2009, Abigail

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 THANKS

The author wishes to thank EFNet's B<#python> IRC channel for
the inspiration to write this module.

A lot of the code and documentation of C<constant.pm> was cut and
pasted in.

=cut
