package Util::Medley::Package;
$Util::Medley::Package::VERSION = '0.043';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Kavorka '-all';
use Scalar::Util;

=head1 NAME

Util::Medley::Package - Utility methods for packages.

=head1 VERSION

version 0.043

=cut

=head1 SYNOPSIS

  my $pkg = Util::Medley::Package->new;

  #
  # positional  
  #
  say $pkg->basename('Foo::Bar');
  say $pkg->basename(Foo::Bar->new);

  #
  # named pair
  #
  say $pkg->basename(pkg => 'Foo::Bar');
  say $pkg->basename(pkg => Foo::Bar->new);
   
=cut

########################################################

=head1 DESCRIPTION

A module that provides utility methods for dealing with packages

=cut

########################################################

=head1 ATTRIBUTES

none

=head1 METHODS

=head2 basename

Returns basename for a given string or object.  For example, Foo::Bar::Biz 
yields 'Biz'.

=over

=item usage:

 say $pkg->basename('Foo::Bar');
 say $pkg->basename(Foo::Bar->new);

 say $pkg->basename(name => 'Foo::Bar');
 say $pkg->basename(pkg => Foo::Bar->new);
 
=item args:

=over

=item pkg [Str|Object]

A string or object.

=back

=back
   
=cut

multi method basename (Str|Object :$pkg!) {

	my $name;
	if (Scalar::Util::blessed($pkg)) {
		$name = ref($pkg);
	}
	else {
		$name = $pkg;
	}		
		
    my @a = split( /::/, $name );
    return pop @a;
}

multi method basename (Str|Object $pkg) {

	return $self->basename(pkg => $pkg);
}

1;
