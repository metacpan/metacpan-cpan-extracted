
package XML::NamespaceFactory;
use strict;
use Carp;

# ABSTRACT: Simple factory objects for SAX namespaced names.
our $VERSION = '1.02'; # VERSION

use vars qw($VERSION $AUTOLOAD);
use overload '""'  => \&toString,
			 'cmp' => \&cmpString,
			 '%{}' => \&toHash;

sub new {
	my $class = ref($_[0]) ? ref(shift) : shift;
	my $ns = shift;
	confess "Parameter \$ns required." unless defined $ns;
	return bless \$ns;
}

sub AUTOLOAD {
	$AUTOLOAD =~ s/^.*::([^:]+)/$1/;
	return "{$_[0]}$AUTOLOAD";
}

# overloaders
sub toString { return ${$_[0]}; }
sub toHash {
	tie my %h, 'XML::NamespaceFactory::TiedHash', $_[0];
	return \%h;
}
sub cmpString {
	my $ns = shift;
	my $cmp = shift;
	my $rev = shift;
	my $res = ( $$ns eq $cmp ) ? 0 : 1;
	return $rev ? - $res : $res;
}


package XML::NamespaceFactory::TiedHash;

sub TIEHASH {
	my $class = shift;
	my $ns = shift;
	return bless [$ns], $class;
}

sub FETCH {
	my $self = shift;
	my $key = shift;
	return "{" . $self->[0] . "}" . $key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::NamespaceFactory - Simple factory objects for SAX namespaced names.

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  use XML::NamespaceFactory;
  my $FOO = XML::NamespaceFactory->new('http://foo.org/ns/');
  
  print $FOO->title;            # {http://foo.org/ns/}title
  print $FOO->{'bar.baz-toto'}; # {http://foo.org/ns/}bar.baz-toto

=head1 DESCRIPTION

Simply create a new XML::NamespaceFactory object with the namespace
you wish to use as its single parameter. If you wish to use the empty
namespace, simply pass in an empty string (but undef will not do).

Then, when you want to get a JClark name, call a method on that object
the name of which is the local name you wish to have. It'll return the
JClark notation for that local name in your namespace.

Unfortunately, some local names legal in XML are not legal in Perl. To
circumvent this, you can use the hash notation in which you access a key
on the object the name of which is the local name you wish to have. This
will work just as the method call name but will accept more characters.
Note that it does not check that the name you ask for is a valid XML
name. This form is more general but slower.

If this is not clear, hopefully the SYNOPSIS should help :)

=head1 ABSTRACT

A number of accessors for namespaces in SAX use the JClark notation,
{namespace}local-name. Those are a bit painful to type repeatedly, and
somewhat error-prone as hash keys. This module makes life easier.

=head1 AUTHORS

=over 4

=item *

Robin Berjon <robin@knowscape.com>

=item *

Chris Prather <chris@prather.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robin Berjon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
