package Test::Routine::Test;
# ABSTRACT: a test method in a Test::Routine role
$Test::Routine::Test::VERSION = '0.027';
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

version 0.027

=head1 OVERVIEW

Test::Routine::Test is a very simple subclass of L<Moose::Meta::Method>, used
primarily to identify which methods in a class are tests.  It also has
attributes used for labeling and ordering test runs.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
