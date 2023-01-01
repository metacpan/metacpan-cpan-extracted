package Test::Named;

use 5.035010;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our $VERSION = 0.03;
our @EXPORT_OK = ( );
our @EXPORT = qw( main before_launch before_exit );

my $pre_test;
my $post_test;

sub main {

    &$pre_test if defined $pre_test;

    my @args  = @_;

    if (@args) {
        for my $name (@args) {
            die "No test method test_$name\n"
                unless my $func = caller->can( 'test_' . $name );
            $func->();
        }
        &$post_test if defined $post_test;
        return 0;
    }

    foreach my $sub (grep(/^test_/, keys %main::)) {
        no strict 'refs';
        caller->$sub();
    }

    &$post_test if defined $post_test;
    return 0;
}

sub before_launch {
    my $ref = shift;
    die 'Not a CODE reference for before_launch' unless ref $ref eq 'CODE';
    $pre_test = $ref;
}

sub before_exit {
    my $ref = shift;
    die 'Not a CODE reference for before_exit' unless ref $ref eq 'CODE';
    $post_test = $ref;
}

1;
__END__

=head1 NAME

Test::Named - Perl extension for named tests. Inspired on this:

http://www.modernperlbooks.com/mt/2013/05/running-named-perl-tests-from-prove.html

=head1 SYNOPSIS

  #################
  #   WITH PLAN   #
  #################

  # load your fav test harness
  use Test::More tests => 3;
  use Test::Named;

  # load module to test
  use_ok(Foo::Bar);

  # run all tests unless named test specified
  exit main( @ARGV );

  # named tests are declared using test_ prefix
  sub test_foo {
    ...
  }
  sub test_bar {

  }
  etc..

  #################
  #    NO PLAN    #
  #################

  # load your fav test harness - no plan
  use Test::More;
  use Test::Named;

  # load module to test
  use_ok(Foo::Bar);

  # use hooks to setup before and after testing
  before_launch(sub { ok(1, 'Before Launch Executed') });
  before_exit( sub { done_testing() });

  # run all tests unless named test specified
  exit main( @ARGV );

  # named tests are declared using test_ prefix
  sub test_foo {
    ...
  }
  sub test_bar {

  }
  etc..

  #################
  #   RUN TESTS   #
  #################

  prove -v -I lib/ t/*
  prove -v -I lib/ t/TestFile.t
  prove -v -I lib/ t/TestFile.t :: foo
  prove -v -I lib/ t/TestFile.t :: bar

=head1 DESCRIPTION

This module is a very thin wrapper that allows easy named testing
much like JUnit-based testing frameworks.

=head2 EXPORT

This module exports a subroutine named main() and two hooks before_lauch and before_exit that are setup
using code references (see SYNOPSIS above)

=head1 SEE ALSO

https://github.com/aimass/Test-Named

=head1 AUTHOR

Alejandro Imass, https://github.com/aimass

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Alejandro Imass

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.35.10 or,
at your option, any later version of Perl 5 you may have available.


=cut
