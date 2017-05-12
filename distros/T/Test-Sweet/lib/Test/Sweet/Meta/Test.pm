package Test::Sweet::Meta::Test;
BEGIN {
  $Test::Sweet::Meta::Test::VERSION = '0.03';
}
# ABSTRACT: object representing a test case
use Moose;
use MooseX::Types::Moose qw(CodeRef);
use Test::Sweet::Types qw(SuiteClass);

use namespace::autoclean;

has 'test_body' => (
    is       => 'ro',
    isa      => CodeRef,
    required => 1,
);

sub run {
    my ($self, $suite_class, @user_args) = @_;
    $self->test_body->($suite_class, $self, @user_args);
}

# so roles can before/after/around these
sub BUILD    {}
sub DEMOLISH {}

1;



=pod

=head1 NAME

Test::Sweet::Meta::Test - object representing a test case

=head1 VERSION

version 0.03

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
