use v5.12.0;
package Test::Routine::Runner 0.031;
# ABSTRACT: tools for running Test::Routine tests

use Moose;

#pod =head1 OVERVIEW
#pod
#pod A Test::Routine::Runner takes a callback for building test instances, then uses
#pod it to build instances and run the tests on it.  The Test::Routine::Runner
#pod interface is still undergoing work, but the Test::Routine::Util exports for
#pod running tests, described in L<Test::Routine|Test::Routine/Running Tests>, are
#pod more stable.  Please use those instead, unless you are willing to deal with
#pod interface breakage.
#pod
#pod =cut

use Carp qw(confess croak);
use Scalar::Util qw(reftype);
use Test2::API 1.302045 ();
use Try::Tiny;

use Moose::Util::TypeConstraints;

use namespace::clean;

subtype 'Test::Routine::_InstanceBuilder', as 'CodeRef';
subtype 'Test::Routine::_Instance',
  as 'Object',
  where { $_->does('Test::Routine::Common') };

coerce 'Test::Routine::_InstanceBuilder',
  from 'Test::Routine::_Instance',
  via  { my $instance = $_; sub { $instance } };

has _instance_builder => (
  is  => 'ro',
  isa => 'Test::Routine::_InstanceBuilder',
  coerce   => 1,
  traits   => [ 'Code' ],
  init_arg => 'instance_from',
  required => 1,
  handles  => {
    'build_test_instance' => 'execute_method',
  },
);

has description => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub run {
  my ($self) = @_;

  my $test_instance = $self->build_test_instance;

  my @tests = grep { Moose::Util::does_role($_, 'Test::Routine::Test::Role') }
              $test_instance->meta->get_all_methods;

  my $re = $ENV{TEST_METHOD};
  if (length $re) {
    my $filter = try { qr/$re/ } # compile the the regex separately ...
        catch { croak("TEST_METHOD ($re) is not a valid regular expression: $_") };
    $filter = qr/\A$filter\z/;  # ... so it can't mess with the anchoring
    @tests = grep { $_->description =~ $filter } @tests;
  }

  # As a side note, I wonder whether there is any way to format the code below
  # to not look stupid. -- rjbs, 2010-09-28
  my @ordered_tests = sort {
         $a->_origin->{file} cmp $b->_origin->{file}
      || $a->_origin->{nth}  <=> $b->_origin->{nth}
  } @tests;

  Test2::API::run_subtest($self->description, sub {
    TEST: for my $test (@ordered_tests) {
      my $ctx = Test2::API::context;
      if (my $reason = $test->skip_reason($test_instance)) {
        $ctx->skip($test->name, $reason);
      } else {
        $test_instance->run_test( $test );
      }

      $ctx->release;
    }
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Routine::Runner - tools for running Test::Routine tests

=head1 VERSION

version 0.031

=head1 OVERVIEW

A Test::Routine::Runner takes a callback for building test instances, then uses
it to build instances and run the tests on it.  The Test::Routine::Runner
interface is still undergoing work, but the Test::Routine::Util exports for
running tests, described in L<Test::Routine|Test::Routine/Running Tests>, are
more stable.  Please use those instead, unless you are willing to deal with
interface breakage.

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
