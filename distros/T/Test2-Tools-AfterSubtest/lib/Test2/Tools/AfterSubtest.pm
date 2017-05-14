package Test2::Tools::AfterSubtest;
use strict;
use warnings;
use base 'Exporter';
use Test2::API qw/context_do/;

our @EXPORT = qw/after_subtest/;

sub after_subtest {
    context_do {
        my ($ctx, $cb) = @_;
        $ctx->hub->listen(sub {
            $cb->() if ref($_[1]) eq 'Test2::Event::Subtest';
        }, inherit => 1);
    } @_;
}

=pod

=encoding UTF-8

=head1 NAME

Test2::Tools::AfterSubtest - Test2 after_subtest callback

=head1 DESCRIPTION

Exports an C<after_subtest> function that can be passed a callback to be
executed after every subtest.

Useful for things like cleaning up the database after each test.

=head1 SYNOPSIS

  use Test2::Bundle::More;
  use Test2::Tools::AfterSubtest;
  after_subtest(sub {
    diag 'Subtest has finished;
  });
  subtest 'test' => sub {
    ok('subtest runs');
  };

=cut

1;
