package ctflags::long;

our $VERSION = '0.01';

use 5.006;
use strict;
use warnings;
use Carp;

use ctflags::check;
use ctflags::memory;
use ctflags;

sub import {
  my $self=shift;
  my ($package)=caller;

  eval {
    while (@_) {
      my $key=shift;
      if (my ($name, $ns, $long)=
	  $key=~m{^
		  (?:
		   ($identifier_re) # constant name,
		   =
		  )?                # optional.
		  ($ns_re)          # namespace
		  :
		  ($alias_re)       # long name
		  $
		 }xo ) {
	$name=$long unless defined $name;
	ctflags::export_sub($package, $name,
			    resolve_ctflag_alias($ns, $long))
      }
      elsif ($key eq 'package') {
	$package=shift;
	check_package $package;
      }
      else {
	die "unknow option or invalid export specification '$key'\n";
      }
    }
  };
  if ($@) { chomp $@; croak $@ };
}

1;
__END__

=head1 NAME

ctflags::long - use ctflags with long names

=head1 SYNOPSIS

  use ctflags::long;


=head1 ABSTRACT

Reference ctflags with long names instead of using single letters.

=head1 DESCRIPTION

After C<ctflags::config> has been used to assign long names to
ctflags, this package can be used to import the flags as normal Perl
constants but refering to the flags by its long name. i.e.:

  use ctflags::config long => 'foo:bar=b';
  use ctflags::long 'my_bar=foo:bar';

the first line creates an alias for foo:b as foo:bar, the second line
imports foo:bar (and so, foo:b) as constant my_bar.

=head2 EXPORT

The requested flags


=head1 SEE ALSO

L<ctflags>, L<ctflags::parse>, L<ctflags::config> and L<constant>.

=head1 AUTHOR

Salva, E<lt>salva@nonetE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador Fandiño García

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
