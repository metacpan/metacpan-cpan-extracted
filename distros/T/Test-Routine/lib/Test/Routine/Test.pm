package Test::Routine::Test;
# ABSTRACT: a test method in a Test::Routine role
$Test::Routine::Test::VERSION = '0.029';
use Moose;
extends 'Moose::Meta::Method';

with 'Test::Routine::Test::Role';

#pod =head1 OVERVIEW
#pod
#pod Test::Routine::Test is a very simple subclass of L<Moose::Meta::Method>, used
#pod primarily to identify which methods in a class are tests.  It also has
#pod attributes used for labeling and ordering test runs.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Routine::Test - a test method in a Test::Routine role

=head1 VERSION

version 0.029

=head1 OVERVIEW

Test::Routine::Test is a very simple subclass of L<Moose::Meta::Method>, used
primarily to identify which methods in a class are tests.  It also has
attributes used for labeling and ordering test runs.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
