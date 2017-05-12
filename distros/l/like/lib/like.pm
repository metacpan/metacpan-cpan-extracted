package like;

use latest;

use Carp;

=head1 NAME

like - Declare support for an interface

=head1 VERSION

This document describes like version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  package MyThing;

  use like qw( some::interface );

  # later

  if ( MyThing->isa( 'some::interface' ) ) {
    print "Yes it is!\n";
  }
  
=head1 DESCRIPTION

Allows a package to declare that it ISA named interface without that
interface having to pre-exist.

This

  package MyThing;

  use like qw( some::interface );

is equivalent to

  package some::interface; # make the package exist

  package MyThing;

  use vars qw( @ISA );
  push @ISA, 'some::interface';

The like declaration is intended to declare that your package
conforms to some interface without needing to have the consumer of that
interface installed.

There is no test that your package really does conform to any interface
(see L<Moose>); you're just declaring your intent.

=cut

sub import {
  my ( $class, @isa ) = @_;
  my $caller = caller;
  no strict 'refs';
  for my $isa ( @isa ) {
    @{"${isa}::ISA"} = () unless @{"${isa}::ISA"};
  }
  push @{"${caller}::ISA"}, @isa;
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
like requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-like@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
