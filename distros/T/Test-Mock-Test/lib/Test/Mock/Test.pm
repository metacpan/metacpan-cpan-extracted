package Test::Mock::Test;

use 5.006001;

$VERSION = 0.01;

use strict;
use warnings;

use Carp;
use Scalar::Util 1.11 'set_prototype';
use Symbol qw/ qualify_to_ref qualify /;

require Test::More;

our $no_test_builder = 0;
our $builder = Test::More->builder;

my %mocks = (
             "Test::More" => {
                              proto_S_S   => [qw( ok )],
                              proto_SS_S  => [qw( is isnt like unlike isa_ok )],
                              proto_SSS_S => [qw( cmp_ok )],

                              noproto_2   => [qw( is_deeply )],

                              can_ok      => [qw( can_ok )],
                              fail        => [qw( fail )],
                              use_ok      => [qw( use_ok )],
                              require_ok  => [qw( require_ok )],
                             },
             "Test::Deep" => {
                              noproto_2   => [qw( cmp_bag cmp_deeply )],
                             },
            );

sub import {
        foreach (@_) {
                $no_test_builder = 1 if /no_test_builder/;
        }

        ## no critic (ProhibitStringyEval)
        ## needed for sub prototypes
        if ($no_test_builder)
        {
                eval '
                      sub proto_S_S   ($;$)   { 1 };
                      sub proto_SS_S  ($$;$)  { 1 };
                      sub proto_SSS_S ($$$;$) { 1 };
                      sub fail        (;$)    { 1 };
                      sub can_ok      ($@)    { 1 };
                      sub use_ok      ($;@)   { 1 };
                      sub require_ok  ($)     { 1 };
                      sub noproto_2   ($$;$)  { 1 };
                     ';
        }
        else
        {
                eval '
                      sub proto_S_S   ($;$)   { $builder->ok( 1, $_[1] ) };
                      sub proto_SS_S  ($$;$)  { $builder->ok( 1, $_[2] ) };
                      sub proto_SSS_S ($$$;$) { $builder->ok( 1, $_[3] ) };
                      sub fail        (;$)    { $builder->ok( 1, @_ ) };
                      sub can_ok      ($@)    { $builder->ok( 1, "class->can(...)") };
                      sub use_ok      ($;@)   { $builder->ok( 1, "use ".$_[0].";" ) };
                      sub require_ok  ($)     { $builder->ok( 1, "require ".$_[0].";" ) };
                      sub noproto_2   ($$;$)  { $builder->ok( 1, $_[2] ) };
                     ';
        }
}


CHECK {
        no strict "refs";

        for my $module (keys %mocks) {
                for my $mocksub (keys %{$mocks{$module}}) {
                        for my $sub (@{$mocks{$module}{$mocksub}}) {
                                my $glob          = qualify_to_ref($sub => $module);
                                my $mocksub_proto = set_prototype(sub { &{$mocksub} }, prototype \&$glob);
                                {
                                        no warnings 'redefine';
                                        *{$module."::".$sub} = $mocksub_proto;
                                        *{"main" ."::".$sub} = $mocksub_proto if *{"main" ."::".$sub};
                                }
                        }
                }
        }
}

1;

__END__

=head1 NAME

Test::Mock::Test - Mock Test::* code to succeed or do nothing.

=head1 ABOUT

This module mocks typical test function from modules

  Test::More
  Test::Most
  Test::Deep

to always return ok. In particular this means their test functionality
is skipped, so the overhead of the tests is dropped and reduced to
only the function call overhead.

You can use this, for instance, to reuse test scripts as benchmarks
where the overhead of the test code stands in the way of measuring the
actual code runtime. The ratio of that overhead, however, depends on
the test script, e.g. tests around Test::Deep with big data structures
bring them in.

=head1 SYNOPSIS

The module executes mocking during load so you can activate the module
from the outside, like this:

  perl -MTest::Mock::Test t/sometest.t

If you even want to avoid the overhead of the underlying
Test::Builder::ok() calls you can skip them this way:

  perl -MTest::Mock::Test=no_test_builder t/sometest.t


=head1 AUTHOR

Steffen Schwigon, C<< <schwigon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-mock-test at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Mock-Test>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Mock::Test


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Mock-Test>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Mock-Test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Mock-Test>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Mock-Test/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Steffen Schwigon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
