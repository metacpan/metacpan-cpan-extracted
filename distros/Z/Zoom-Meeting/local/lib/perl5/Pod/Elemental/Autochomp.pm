package Pod::Elemental::Autochomp 0.103006;
# ABSTRACT: a paragraph that chomps set content

use namespace::autoclean;
use Moose::Role;

use Pod::Elemental::Types qw(ChompedString);

#pod =head1 OVERVIEW
#pod
#pod This role exists primarily to simplify elements produced by the Pod5
#pod transformer.
#pod
#pod =cut

# has '+content' => (
#   coerce => 1,
#   isa    => ChompedString,
# );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Autochomp - a paragraph that chomps set content

=head1 VERSION

version 0.103006

=head1 OVERVIEW

This role exists primarily to simplify elements produced by the Pod5
transformer.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
