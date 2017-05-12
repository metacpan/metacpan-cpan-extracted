package generics;

use strict;
use warnings;

our $VERSION = '0.04';

sub import {
	my ($self) = shift;
	# return if they dont pass anything in (use generics;)
	return unless @_;
	# otherwise ...
	my ($class, @params) = @_;
	# turn off strict refs cause we are messing with stuff
	no strict 'refs';
	# turn off warnings, so we dont get
	# the function redefinition warning
	# or the prototype mismatch as well
	no warnings qw(redefine prototype once);
	# find out who called us
	my ($calling_package, $file, $line) = caller();
	# this is for:
	# 	use generics params => (*params*);
	# it just pre-initializes the sub routines 
	# so they can be called like constants
	# if you do not then define those params
	# later on, the methods will just return undefined
	if ($class eq "params") {
		# create a hash for to hold the 
		# valid parameters
		%{"${calling_package}::GENERIC_PARAMS"} = () unless %{"${calling_package}::GENERIC_PARAMS"};
		map {
			# check for duplicate parameters
			# basically just see if the param 
			# already exists in the hash of 
			# valid params
			(!exists(${"${calling_package}::GENERIC_PARAMS"}{$_})) ||  die "generics exception: attempted duplicate parameter creation in $calling_package in file: $file on line: $line.\n";
			# this creates a subroutine that returns undef.
			# this prevents Perl from thinking that this 
			# subroutine doesnt exist, but allows you to
			# to catch it as an error.
			my $name = $_;
			*{"${calling_package}::$_"} = sub { die "generics exception: ${calling_package}::$name is an undefined parameter (and has no default)\n" };
			# add the latest param as a key in the valid
			# params hash, and increment it by one
			${"${calling_package}::GENERIC_PARAMS"}{$_}++;
			} @params;
		return;
	}
	elsif ($class eq "inherit") {
		# if you want to inherit generic params, 
		# but still have your own, then you need
		# to do this:
		# 	use generics inherit => "My::Base::Class";
		# and it will allow one to inherit from
		# the base class. it can be called alone
		# or in conjunction with other calls to generics
		# which therby either create or overwrite the
		# generic params alreay inherited.
		# NOTE:
		# we create a function in the calling package which 
		# returns the value of the function from the base 
		# packages so that we are truely inheriting from it. 
		# But keep in mind that this all happens at runtime,
		# so if the generic parameters are changed in 
		# the calling package then it will override these 
		# parameters, because that change will happen at
		# compile time and therefore override this function.
		# NOTE:
		# any changes made to the params of the base package 
		# will be reflected in the calling package since the 
		# inheritance is performed at runtime.
		my $base_package = $params[0];
		%{"${calling_package}::GENERIC_PARAMS"} = %{"${base_package}::GENERIC_PARAMS"};
		foreach my $param_key (keys %{"${base_package}::GENERIC_PARAMS"}) {
			*{"${calling_package}::${param_key}"} = sub { &{"${base_package}::${param_key}"}() };
		}
		return;
	}
	# before we go any further lets make sure 
	# the parameters are even key value pairs
 	(@params && ($#params % 2) != 0) || die "generics exception: uneven parameter assigments of generics in $calling_package in file: $file on line: $line.\n";
	my %params = @params;
	# this is for:
	# 	use generics default_params => (*params and default values*);
	# it sets up the generic parameters and 
	# fills them with a default value.
	# NOTE: 
	# there is no need to check for
	# duplicate params here, because they 
	# will get swallowed up by the hash 
	# assignment. 
	if ($class eq "default_params") {
		# create a hash for to hold the 
		# valid parameters, unless we already
		# have one (meaning someone has done
		# and "inherit" somewhere.
		%{"${calling_package}::GENERIC_PARAMS"} = () unless %{"${calling_package}::GENERIC_PARAMS"};
		while (my ($key, $value) = each %params) {
			# add the latest param as a key in the valid
			# params hash, and increment it by one
			${"${calling_package}::GENERIC_PARAMS"}{$key}++;
			*{"${calling_package}::$key"} = $value if (ref($value) eq "CODE");
			*{"${calling_package}::$key"} = sub { $value } if (!ref($value) || (ref($value) ne "CODE"));
		}
	}
	# this is for:
	#	use generics *package* => (*params and values*);
	# this is when the module is loaded and 
	# before you use it in any code. It populates
	# the generic parameters with the new 
	# values that are passed.
	else {
		# get the hash of valid params
		my %valid_params = %{"${class}::GENERIC_PARAMS"};
		while (my ($key, $value) = each %params) {
			# before we assign anything, check
			# to see that the key we are assigning
			# is a valid param in the generic module
			(exists($valid_params{$key})) || die "generics exception: $key is not a valid generic parameter for $class in $calling_package in file: $file on line: $line.\n";
			# if we get past the exception, then all
			# is cool and we can assign the parameter
			*{"${class}::$key"} = $value if (ref($value) eq "CODE");
			*{"${class}::$key"} = sub () { $value } if (!ref($value) || (ref($value) ne "CODE"));
		}
	}
}

## NOTE:
# if ever you need to change the module configuration
# you will need to re-import the the configuration. Here
# is a way to do that (without having to say import which
# wouldnt make as much sense semanticaly).
# Keep in mind though that this will not restore the default
# values originally assigned in the class, it will just overwrite
# the current ones. 
# 
# this will be needed very rarely. If you find yourself using it
# you should question the reason first, and only use it as a last 
# resort.
*change_params = \&import;

# to support module reloading

sub has_generic_params {
	my ($self, $package_name) = @_;
	no strict 'refs';
	return exists ${"${package_name}::"}{GENERIC_PARAMS} ? 1 : 0;
}

sub dump_params {
	my ($self, $package_name) = @_;
	no strict 'refs';
	return map {
			($_ => &{"${package_name}::$_"}())
			} keys %{"${package_name}::GENERIC_PARAMS"};
}

1;
__END__

=head1 NAME

generics - pragmatic module for perl-ish generics

=head1 SYNOPSIS

    package MyModule;
    
    # for use from within a package
    use generics params => qw(
                PARAMETER
                );
    
    # another use from within a package
    # and setting a default value for a
    # parameter
    use generics default_params => (
                PARAMETER => "A value"
                );
                
    # ... outside of the MyModule package 
    
    # using it from outside a package
    # to change the packages parameters
    use generics MyModule => (
                PARAMETER => "A new value"
                );
                
    # ... elsewhere in the source            
    
    package MyDerivedModule;
    
    use base qw(MyModule);
    
    # generic parameters can be inherited too
    use generics inherit => "MyModule";
    
    # see DESCRIPTION below for a better understanding 
    # of this module and how it can be used

=head1 DESCRIPTION

=head2 What are generics?    

Generics and generic programming is style of programming which aims to make more generalized software compontents. It is more prevelant in strongly typed langauges like Ada95, C++ (through the STL) and more recently in C# 2.0 and Java 1.5. On a very simple level, generics allow these langauges to achieve a level of type polymorphism where they didn't have that before. Here is a simplistic pseudo-C++/C#/Java-style example of generics:

  class Stack : <T> {
    _stack = array of T;
  
    T pop { ... }
    void push (T item) { ... }
  }
  
  // create the Stack instance with 
  // a type parameter here
  Stack<int> my_stack = new Stack<int> 

The C<T> is the generic parameter, which represents a generic type that the stack holds. When we create an instance of C<Stack>, the generic type parameter is assigned and the object is actually then of type C<Stack<int>>, which is different than say, C<Stack<float>>. 

This is a very limited and simple type of generics, languages like Ada 95 support a more extensive version of generics which allow not only for the defferment of types, but also of values, functions and procedures within the Ada package. Here is an example of a generic Stack package in Ada 95:

  generic
    -- "private" means essentially "any type at all"
    type Item_Type is private;
    -- our Stack need a size, which is an integer 
    -- and here we default it to 100
    Size : Integer := 100;
  package Stack is
    -- ... implementation here
  end Stack;

  -- create a new "instance" of the Stack package
  -- that uses integers as its type, and whose size
  -- is defaulted to 100
  package Int_Stack is new Stack (Item_Type => Integer);

Here we created not only a generic type for the Stack to hold, but also allowed the size of the stack to be determined, but also have a default. You can also make a function or procedure a generic parameter in Ada. 

Much of what is going on behind the scenes with these generics is that the compiler is able to retain the langauges type-safety while still providing a facility for type-polymorphism. Like I said, this is usually something needed by strongly-typed languages, and more specifically, those of the "type-checking" variety.  By now you are wondering what does all this have to do with perl? 

=head2 Generics in perl

Perl is not strongly typed, and it doesn't really do any type-checking, and will do type-casting when neseccary. It's (sort of) type-polymorphic as well, meaning you can treat most all of your types reasonably the same.  Sure things like C<==> and C<!=> vs. C<eq> and C<ne> can be annoying, but they are surrmountable problems. So why would I need generics in perl you say?

This module aims to provide a perl-ish form of generics, which is similar too, but not exaclty like what I desribe above. Perl doesn't really need the type flexibility of generics, but it can use the more advanced features of Ada 95 style generics, such as defining values and functions as generic parameters. Since we do not need the compiler optimizations gotten by declaring the generic parameters on of each of our instances, we can define them for the specific package itself rather than just an instance of it.

It is possible to view this pragma as providing the facility to manage package configuration parameters. It was actually inspired by the C<constant> pragma, and the desire to assign those constants across package boundries.

=head2 How do I use generics?

The easiest way to explain the details behind how this module works, and how one would work with it, through examples. This example is that of a "Session" object. Here is some sample code:

    use Session;
    
    # set the generic params
    use generics Session => (
                SESSION_TIMEOUT => 30, 
                SESSION_ID_LENGTH => 20
                );
    
    # create a Session object instance
    my $s = Session->new();

Generics are used here as a way of configuring the Session object to have a 30 minute timeout period and generate a session id that is 20 characters long. Any Session object you create after the C<use generics> declaration will utilize those configuration parameters. 

While it would be just as simple to just add the parameters to the Session object constructor and configure it each time, this way is actually cleaner and faster. It is cleaner, because you need not have to remember the parameters each time you create a new Session object (especially since they are unlikely to change throughout the life of your application). And it is faster because the use generics declaration will actually set the parameters during the compilation of the Session object, and not at run-time when you create the object.

The only drawback to the compilation time configuration is that once the module is compiled, those values are set. Of course this is not a drawback if you do not plan on changing the parameters, and want them to stay as they are through the life of your application. If your generics are designed well you will never have a need to change the parameters during runtime. If however you do need to change things are runtime, there is a way with the C<change_params> method (see below). 

=head2 Configuring generics for a package

There is also another side to generics. The side that lives within the actual package you are attempting to configure. There a few options available to you here. First is to set paramters without defaults. Here is an example:

    package Session;
    
    use generics params  => qw(
        SESSION_TIMEOUT
        SESSION_ID_LENGTH
        );

This will tell generics the parameters available within the package, and create stub subroutines for them. These stub routines will throw an exception if they are called before they are configured. However, these stub routines make it possible to use the parameters in your code and allow the module to still compile and run with both strict and warnings on.

The other option, is to assign defaults to the parameters in the package itself. Here is an example:

    package Session;
    
    use generics default_params => (
        SESSION_TIMEOUT => 30,
        SESSION_ID_LENGTH => 20
        );

This example does just what the previous one does in terms of setting up the valid parameters for the Session package, but it also assigns default parameters. With the defaults, you don't have to do anything and the package would just use the installed default values. But using defaults, you have another option, which is to set as many params as you want/need. For instance:

    use generics Session => (SESSION_TIMEOUT => 120);

This code will utilize the default setting for the C<SESSION_ID_LENGTH> param, but change the C<SESSION_TIMEOUT> param to be 120 minutes. 

=head2 Types of generic parameters

Up until now, our generic parameters have been plain scalar values, but they can also be scalar reference variables as well. This means hash references, array references and also subroutine references. The following bit of code is a  valid use of generics:

    use generics Session => (
        SESSION_TIMEOUT => sub {
                if (((rand() * 100) % 2) == 0) {
                    return 30;
                }
                else {
                    return 120;
                }
            },
        SESSION_ID_LENGTH => 20
        );

The above code uses an anonymous subroutine, which will set the session timeout to 30 minutes if a random number is even, otherwise it sets it to 120. This of course is kind of silly, but it just illustrates that you have alot of flexibility with generics.

It is worth noting that there is no type-checking done by generics, so it is possible to set a default to one type, and then assign it to a different type. More than likely this will change in subsequent versions of this module, so exploiting this is not recommended. 

When using the generic parameters in the package, they should be used just like constants that are created with the C<constant> pragma. They are actually just subroutines which the perl compiler will inline. It is important to keep this in mind when using the parameters inside your package code, in particular in situations where your parameter would be interpreted as a string (ex: a hash key, interpolated into a string). Here is an example of how it might be used in the Session package:

    sub getSessionId {
        my @chars = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
        return join "" => map { 
                    $chars[((rand() * 100) % scalar @chars)] 
                    } (1 .. SESSION_ID_LENGTH);
    } 

=head2 Generics and OOP

The generics pragma also is built with Object Oriented programming in mind. Since the parameters created are actually subroutines, they are easily inherited with only a few changes.

Inheritance of generic parameters is not automatic. In order to inherit the same generic parameters as your base class, you must tell generics to do so, like this:

    package MySession;
    
    use base qw(Session);
    
    use generics inherit => "Session";

What this does is to actually duplicate the available generic parameters in the derived class, allowing them to be assigned to seperately from the base class. But up until those parameters are assigned, they will be aliases to those in the base class. Meaning that your derived class B<will> inherit any and all changes in the base classes generic parameters. Once you assign them for your derived class though, you have disolved that relationship. This allows the default parameters to be carried over from base class to the derived class. 

It is worth nothing that generics will not actually test to see if your package actually inherits from the class you say it does. This is because all our generics happens at compile time, and we can not know for sure at that time what your base class might be. We go on faith that you will do only what makes sense. 

It is also important to note that your generic parameters will usually not be virtual. Meaning that in the example above of the C<getSessionId> method, the C<SESSION_ID_LENGTH> parameter will be that of the base class if the C<getSessionId> method itself is not overridden. If this is not your desired behavior, then it is easily changed with one small addition to the code to make the parameter work properly as a virtual method.

    sub getSessionId {
        my @chars = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
        return join "" => map { 
                    $chars[((rand() * 100) % scalar @chars)] 
                    } (1 .. $self->SESSION_ID_LENGTH);
    } 

This is not considered a feature, although it can be desireable behavior at times. However it may be fixed in subsequent versions of this module, so reliance upon it is not suggested. 

=head1 METHODS

=over 4

=item B<change_params ($package, @generic_params)>

If ever you need to change the module configuration you will need to re-import the the configuration. Here is a way to do that (without having to say import which wouldnt make as much sense semanticaly). Keep in mind though that this will not restore the default values originally assigned in the class, it will just overwrite the current ones. 

This will be needed very rarely. If you find yourself using it you should question the reason first, and only use it as a last resort.

=item B<has_generic_params ($package)>

This method is a predicate, returning true (1) if the C<$package> has generic parameters and false (0) otherwise.

=item B<dump_params ($package)>

This will dump a hash of the generic parameters. One important thing to note is that it will execute the parameters, so this may not be very useful for subtroutine ref parameters.

=back

=head1 TO DO

=over 5

=item * Make inherited generics proper virtual method citizens. 

=item * Possibly add type-checking to generic parameters.

=item * Possibly for mixed params and default params in the same package.

=back

=head1 BUGS

None that I am aware of. The code is pretty thoroughly tested (see L<CODE COVERAGE> below) and is based on an (non-publicly released) module which I had used in production systems for about 2 years without incident. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module's test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt branch   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 /generics.pm                   98.8  100.0  100.0   92.3  100.0   16.5   98.5
 t/10_generics_test.t          100.0    n/a    n/a  100.0    n/a   19.1  100.0
 t/20_generics_inherit_test.t  100.0    n/a    n/a  100.0    n/a   44.7  100.0
 t/30_generics_errors_test.t   100.0    n/a    n/a  100.0    n/a   19.4  100.0
 t/test_lib/Base.pm            100.0    n/a   33.3  100.0    0.0    0.7   85.0
 t/test_lib/Broken.pm          100.0    n/a    n/a  100.0    n/a    0.2  100.0
 t/test_lib/BrokenThree.pm     100.0    n/a    n/a  100.0    n/a    0.2  100.0
 t/test_lib/BrokenTwo.pm       100.0    n/a    n/a  100.0    n/a    0.2  100.0
 t/test_lib/Derived.pm         100.0    n/a    n/a  100.0    n/a    0.3  100.0
 t/test_lib/Session.pm         100.0    n/a   33.3  100.0    n/a    3.6   91.3
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                          99.6  100.0   73.3   98.5   66.7  100.0   98.1
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

Nothing I can think of yet. But this module was inspired by the C<constant> pragma, and the desire to assign those constants across module lines. It borrows some of its ideas from other languages, in particular Ada and C++/STL, although our generics are not instance oriented as theirs are. 

If you want to learn more about generics and generic programming, just Googling the phrase "generic programming" produces many useful links.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
