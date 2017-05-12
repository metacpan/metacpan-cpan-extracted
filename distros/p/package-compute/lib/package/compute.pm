package package::compute;

use 5.008;
use strict;
use warnings;

BEGIN {
	$package::compute::AUTHORITY = 'cpan:TOBYINK';
	$package::compute::VERSION   = '0.005';
}

use B::Hooks::Parser 0.08 qw();
use Carp qw(confess);

my $count = 0;

sub import
{
	my ($class, $name) = @_;
	
	my $caller = caller;
	my $pkg;
	
	if (not defined $name)
	{
		$pkg = $caller;
	}
	elsif (!ref $name and $name eq '-anon')
	{
		$pkg = sprintf('%s::__ANON__::%s', $class, ++$count);
	}
	elsif (!ref $name and $name eq '-filename')
	{
		# figure out where we're called from
		my (undef, $filename) = caller;

		# figure out where it got loaded via %INC.
		for my $k (sort keys %INC)
		{
			if ($INC{$k} eq $filename)
			{
				$pkg = $k;
				$pkg =~ s<[/\\]><::>g;
				$pkg =~ s<\.pm$><>i; # can this be uppercase on some platforms?
				last;
			}
		}
	}
	else
	{
		$pkg = __RPACKAGE__($name, $caller);
	}
	
	confess("package::compute could not determine package name, died")
		unless defined $pkg;
	
	B::Hooks::Parser::inject("; package $pkg;")
		unless $pkg eq $caller;
	
	no strict 'refs';
	*{"$pkg\::__RPACKAGE__"} = \&__RPACKAGE__;
}

sub __RPACKAGE__
{
	my ($name, $caller) = @_;
	$caller ||= scalar caller;
	return $caller unless defined $name;
	
	my $count;
	while (ref $name eq 'CODE')
		{ $name = $name->($caller); die "too deep" if ++$count > 7 }
	if ($name =~ /^[.]+(?:::|'|\/)/)
		{ $name = "$caller\::$name" }
	
	my @pkg = grep { length and $_ ne '.' } split /(?:::|'|\/)/, $name;
	my @final;
	foreach (@pkg)
	{
		push @final, $_;
		next unless /^([.]+)/;
		confess "invalid relative package path" if length $1 > @final;
		splice(@final, -(length $1));
	}
	
	return join q/::/, @final;
}

1;

__END__

=head1 NAME

package::compute - stop hard-coding your package names

=head1 SYNOPSIS

   package Foo::Bar;  # this is a hard-coded package name
   use 5.010;
   
   {
      use package::compute "../Quux";
      say __PACKAGE__;              # says "Foo::Quux";
      say __RPACKAGE__("./Xyzzy");  # says "Foo::Quux::Xyzzy";
      
      sub hello { say __PACKAGE__ };
   }
   
   say __PACKAGE__;   # says "Foo::Bar" (lexically scoped!)
   Foo::Quux->hello;  # says "Foo::Quux"

=head1 DESCRIPTION

This module allows you to compute package names on the fly at compile
time, rather than hard-coding them as barewords. It is the solution to
the problem (if indeed you consider it to be a problem at all) that you
cannot write this in Perl:

   package $blah;

This module uses L<B::Hooks::Parser> to accomplish its evil goals.

Using this module at all is probably a very bad idea.

=head2 Package Specification

The general syntax for specifying a package with this module is:

   use package::compute EXPR;

Where EXPR is an arbitrary expression which will (caveat!) be evaluated
at compile time, and interpreted roughly the way Perl interprets package
names, with the following bonus features:

=over

=item *

If the package name expression is a coderef, then that coderef is
called and the return value is used instead.

=item *

Slashes may be used to separate package name components in addition
to the usual Perl C<< "::" >> and deprecated C<< "'" >> package
separators.

=item *

The component C<< "." >> at the start of the package name refers to the
caller. (C<< "." >> elsewhere is a no-op.)

=item *

The component C<< ".." >> climbs "up" the package hierarchy.

=item *

The component C<< "..." >> climbs "up" the package hierarchy by two
levels. Et cetera.

=back

Thus the following are all valid ways of expressing package "Foo::Bar":

   ### 
   use package::compute "Foo::Bar";
   ####
   
   ### Using a coderef
   use package::compute sub { join q(::) qw( Foo Bar ) };
   ####
   
   #### Relative package name
   package Foo;
   use package::compute "./Bar";
   ####
   
   ### Climbing the package hierarchy
   package Foo::XXX;
   use package::compute "../Bar";
   ####
   
   ### Climbing the package hierarchy twice
   package Foo::XXX::YYY;
   use package::compute "../../Bar";
   ####
   
   ### Climbing the package hierarchy twice - shortcut
   package Foo::XXX::YYY;
   use package::compute ".../Bar";
   ####

As a special case, you can also do:

   use package::compute -filename;

Which will attempt to determine the package name based on the filename it
is defined in, much like C<autopackage> does.

Also:

   use package::compute -anon;

Will compute an "anonymous" (i.e. arbitrary) package name.

=head2 Utility Function

This module also exports a utility function:

=over

=item C<< __RPACKAGE__($name) >>

Returns a package name as a string, computed in the same way as
C<< use package::compute >> does. An example of its use for object-oriented
code:

	package MyProject;
	
	{
		use package::compute './Person';
		use Moose;
		has name => (is => 'ro');
	}
	
	my $bob = __RPACKAGE__('./Person')->new(name => "Robert");

As you can see, this makes it possible to avoid hard-coded references to
the MyProject::Person class.

C<< __RPACKAGE__ >> doesn't support the special C<< -filename >> and 
C<< -anon >> options.

It is possible to import the C<< __RPACKAGE__ >> function alone, without
the package declaration magic using:

   use package::compute undef;

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=package-compute>.

=head1 SEE ALSO

L<autopackage>,
L<Package::Relative>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

