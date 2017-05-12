package latest::feature;

BEGIN {
  eval 'require feature';
  if ( $@ ) {
    eval 'sub import {}';    # NOP if we don't have feature
  }
  else {
    our @ISA = qw( feature );
    eval 'sub unknown_feature_bundle {}'; # Ignore unknown bundle errors
  }
}

package latest;

use warnings;
use strict;
use version;

use Carp;

=head1 NAME

latest - Use the latest Perl features

=head1 VERSION

This document describes latest version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use latest;
  
=head1 DESCRIPTION

The line

  use latest;

is roughly equivalent to

  use strict;
  use warnings;
  use $];

except that 'use $]' doesn't work.

The main use case is to

  use latest;

at the top of your tests to shake out any obscure problems that might
result from your code being used by a program that requires the latest
Perl version.

=cut

sub import {
  strict->import;
  warnings->import;
  ( my $v = version->new( $] )->normal ) =~ s/^v/:/;
  latest::feature->import( $v );
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
latest requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-latest@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
