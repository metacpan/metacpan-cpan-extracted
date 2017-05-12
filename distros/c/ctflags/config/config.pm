package ctflags::config;

our $VERSION = '0.01';

use 5.006;
use strict;
use warnings;
use Carp;

use ctflags::memory;
use ctflags::check;

sub arrayorsplit ($ ) {
  my $val=shift;
  return @{$val} if 'ARRAY' eq ref $val;
  return split /[\s,]+/, $val;
}

sub import {
  my $self=shift;
  eval {
    while (@_) {
      my $key=shift;
      if ($key eq 'alias' or $key eq 'long') {
	my $alias=shift;
	check_defopt $alias, 'alias';
	foreach (arrayorsplit $alias) {
	  if ( m{^
		 ($ns_re)    # $1=namespace
		 :
		 ($identifier_re) # $2=name
		 =
		 ($flag_re)  # $3=flag
		 $
		}x ) {
	    set_ctflag_alias $1, $2, $3;
	  }
	  else {
	    die "invalid alias specification '$_'\n";
	  }
	}
      }
      elsif ($key eq 'restriction') {
	my $rest=shift;
	check_defopt $rest, 'restriction';
	foreach (arrayorsplit $rest) {
	  if (m{^
		($ns_re)    # $1=namespace
		:
		($flagset_re) # $2=flagset
		$
	       }x ) {
	    restrict_ctflags $1, $2;
	  }
	  else {
	    die "invalid restriction specification '$_'\n";
	  }
	}
      }
      else {
	die "unknow option '$key'\n";
      }
    }
  };
  if ($@) { chomp $@; croak $@ };
}


1;
__END__


=head1 NAME

ctflags::config - configure ctflags

=head1 SYNOPSIS

  use ctflags::config long => 'foo:long_name=f',
                      restriction => 'foo:bar';

=head1 ABSTRACT

ctflags::config configure ctflags allowing to define aliases and to
restrict which ctflags can be used.

=head1 DESCRIPTION

=head2 LONG NAMES

To create long aliases for flags use the C<alias> or C<long> key when
'using' the package:

  use ctflags::config alias => 'foo:long_name=f';

makes foo:long_name take the same value as foo:f.

Long flag names are usable with the C<ctflags::long> module.

=head2 RESTRICTING FLAGS

The restriction keyword allos to limit the flags that are valid inside
a namespace. i.e.

  use ctflags::config restriction => 'foo:bar';

limits the valid flag names in the namespace C<foo> to be C<b>, c<A>
and C<r>, trying to use any other name will cause an exception.

=head2 EXPORT

None.

=head1 SEE ALSO

L<ctflags>, L<ctflags::long>.

=head1 AUTHOR

Salvador FandiE<241>o Garcia, E<lt>sfandino@yahoo.comE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Salvador FandiE<241>o Garcia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
