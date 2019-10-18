use 5.008006;
use strict;
use warnings;

package methods::import;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use namespace::clean qw();
use Sub::Util qw();

sub import {
	my $caller = caller;
	my $class  = shift;
	return $class->import_into($caller, @_);
}

sub method_list {
	require Carp;
	Carp::croak("No methods listed to import");
}

{
	my %bools = (-keep => 1);
	sub _get_opt {
		my $class  = shift;
		my ($list) = @_;
		my $opts =
			ref($list->[0]) eq 'HASH'     ? shift @$list :
			ref($list->[0]) eq 'ARRAY' ? $class->_hashify(shift @$list) :
			{};
		while (@$list and !ref($list->[0]) and exists($bools{$list->[0]})) {
			my $thing = shift @$list;
			$opts->{$thing} = $bools{$thing};
		}
		return $opts;
	}
	sub _hashify {
		shift;
		@_ = @{+shift};
		my %r;
		while (@_) {
			my $thing  = shift;
			$r{$thing} = exists($bools{$thing}) ? 1 : shift;
		}
		\%r;
	}
}

sub import_into {
	my $class  = shift;
	my $caller = shift;
	my $using;
	
	@_ = $class->method_list unless @_;
	my $default_opts = $class->_get_opt(\@_);
	
	push @_, 'using' unless grep !ref && /^using$/, @_;
	
	while (@_) {
		my $method = shift;
		my $opts   = $class->_get_opt(\@_);
		if ($method =~ /=/) {
			($method, $opts->{-as}, $opts->{-prototype}) = split /=/, $method;
		}
		$opts = { %$default_opts, %$opts };
		$opts->{'-using'} ||= \$using;
		$class->import_method($caller, $method, $opts);
	}
	return;
}

sub import_method {
	my $class  = shift;
	my ($caller, $method, $opts) = @_;
	my $coderef = $class->make_coderef($method, $opts);
	$class->install_coderef($caller, $coderef, $method, $opts);
}

sub make_coderef {
	my $class  = shift;
	my ($method, $opts) = @_;
	my $curry = $opts->{'-curry'} || [];
	my $coderef;
	if ($method eq 'using') {
		$coderef = sub {
			return ${$opts->{'-using'}} unless @_;
			my ($object, $coderef) = @_;
			my $old = ${$opts->{'-using'}};
			${$opts->{'-using'}} = $object;
			return $old unless $coderef;
			my @r;
			if (wantarray) {
				@r = $coderef->();
			}
			elsif (defined wantarray) {
				$r[0] = $coderef->();
			}
			else {
				$coderef->(); 1;
			}
			${$opts->{'-using'}} = $old;
			wantarray ? @r : $r[0];
		};
	}
	else {
		$coderef = sub {
			defined(my $object = defined(${$opts->{'-using'}}) ? ${$opts->{'-using'}} : $_)
				or $class->croak_undefined($method, $opts);
			$object->$method(@$curry, @_);
		};
	}
	if (defined $opts->{-prototype}) {
		$coderef = Sub::Util::set_prototype($opts->{-prototype}, $coderef);
	}
	return $coderef;
}

sub install_coderef {
	my $class = shift;
	my ($caller, $coderef, $method, $opts) = @_;
	my $as = $opts->{'-as'} || $method;
	return if $as eq '-';
	$coderef = Sub::Util::set_subname("$caller\::$as", $coderef);
	do {
		no strict 'refs';
		*{"$caller\::$as"} = $coderef;
	};
	'namespace::clean'->import(-cleanee => $caller, $as)
		unless $opts->{'-keep'};
}

sub croak_undefined {
	my $class = shift;
	my ($method, $opts) = @_;
	my $as = $opts->{'-as'} || $method;
	require Carp;
	Carp::croak("Can't call method \"$method\" (via imported sub \"$as\") because \$_ is not defined");
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

methods::import - import methods to be used like keywords

=head1 SYNOPSIS

The following calls C<< get >> on the C<< $ua >> object.

 use HTTP::Tiny;
 
 my $ua = HTTP::Tiny->new;
 for ($ua) {
   use methods::import qw(get post);
   
   my $response = get 'http://www.example.com/';
 }

Alternative:

 use HTTP::Tiny;
 use methods::import qw(get post);
 
 my $ua = HTTP::Tiny->new;
 
 using $ua, sub {
   my $response = get 'http://www.example.com/';
 };

=head1 DESCRIPTION

methods::import simplifies the task of calling a lot of methods on a single
object.

Instead of:

  $thing->set_foo(1);
  $thing->process();
  $thing->set_foo(2);
  $thing->set_bar(3);
  $thing->process;

You can write:

 for ($thing) {
   use methods::import qw( set_foo set_bar process );
   
   set_foo 1;
   process;
   set_foo 2;
   set_bar 3;
   process;
 }
 
 # You cannot call process() here because it was lexical

As well as C<< set_foo >> and the other functions explicitly named in the
import list, methods::import will B<always> export a function called
C<using>.

C<using> can be used as an alternative to setting C<< $_ >> to point
to an object.

 use methods::import qw( set_foo set_bar process );
 
 using $thing, sub {
   set_foo 1;
   process;
   set_foo 2;
   set_bar 3;
   process;
 };

=head2 Renaming Imports

An equals sign allows you to rename the imported wrappers.

 use methods::import qw( set_foo=foo set_bar=bar process );
 
 using $thing, sub {
   foo 1;
   process;
   foo 2;
   bar 3;
   process;
 };

Even the C<using> function can be renamed:

 use methods::import qw( set_foo=foo set_bar=bar process using=processing );
 
 processing $thing, sub {
   foo 1;
   process;
   foo 2;
   bar 3;
   process;
 };

=head2 How C<< using >> Works

When you import the wrappers, an scalar variable is created in the lexical
scope of all the wrappers being imported. The wrappers will attempt to call
the method on this scalar variable if it is defined, and fall back to
C<< $_ >> otherwise.

C<using> accepts an object and a coderef. It sets the scalar variable to
point to the object, calls the coderef, then restores the scalar variable
to whatever it was before (usally undef). It then returns the return value
from calling the coderef.

This means:

 use methods::import qw( foo using=using1 );
 use methods::import qw( bar using=using2 );
 
 using1 $something, sub {
   bar();
 };

C<< bar() >> is being called on an undefined object, because C<using1>
only sets the target object for C<foo>, not C<bar>.

As a utility, if C<< using >> is called with no parameters, it will simply
return the current target object. Or if C<< using >> is called with one
parameter, it will set the target object and return any previous target
object.

 use methods::import qw( set_foo set_bar process );
 
 using $thing;
 set_foo 1;
 process;
 set_foo 2;
 set_bar 3;
 process;
 
 using->some_other_method();

=head2 Nested Imports

 use methods::import qw(get);
 using LWP::UserAgent->new, sub {
   use methods::import qw(headers using=using_response);
   using_response get('http://example.com'), sub {
     my $headers = headers();
   };
 };

=head2 Currying

It is possible to curry leading arguments to a method:

 use methods::import
   "foo",
   "foo" => { -as => "foo_123", -curry => [1,2,3] };
 
 using $thing;
 foo(1, 2, 3, 4);     # $thing->foo(1, 2, 3, 4)
 foo_123(4);          # same

Note that the C<< -as >> option has the same effect as C<< = >> in the
import list. C<< = >> is just a shortcut.

=head2 Prototypes

 use methods::import "foo" => { -prototype => '&' };
 
 using $thing;
 foo { ... };      # $thing->foo(sub { ... });

There is a shortcut for this too:

 use methods::import qw( foo=foo=& );
 use methods::import qw( foo==& );     # leaves `-as` blank

=head2 Call Stack

methods::import doesn't make any attempt to hide the wrapper functions
it exports. They will show up on the call stack.

=head2 Lexical Exports

methods::import uses L<namespace::clean> to fake lexical imports.

 {
   use methods::import qw(foo);
   using $object;
   foo();
 }
 # Neither using() nor foo() are defined here.

You can switch off this behaviour by passing C<< -keep >> as the first
option to C<import>:

 {
   use methods::import qw(-keep foo);
   using $object;
   foo();
 }
 # using() and foo() are still defined here.

Or it can be done on a function by function basis:

 use methods::import (
   "foo"    => { -keep => 1 },
   "bar"    => { -keep => 0 },
   "using"  => { -keep => 1 },
 );

=head2 Inheriting from C<< methods::import >>

If your class inherits from methods::import it can provide a C<method_list>
function that supplies a default list of methods for C<import>.

For example:

 package HTTP::Tiny::Keywords;
 use HTTP::Tiny;
 use parent 'methods::import';
 sub method_list { qw( get post using=set_ua) }
 1;

And a module using your HTTP::Tiny::Keywords might do this:

 use HTTP::Tiny::Keywords;
 
 set_ua HTTP::Tiny->new;
 my $response = get 'http://www.example.com/';

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=methods-import>.

=head1 SEE ALSO

C<with>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

