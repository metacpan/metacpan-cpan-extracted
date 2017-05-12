package Test::Wrapper;
BEGIN {
  $Test::Wrapper::AUTHORITY = 'cpan:YANICK';
}
$Test::Wrapper::VERSION = '0.3.0';
# ABSTRACT: Use Test::* tests outside of a TAP context


use Moose;
use Moose::Exporter;

use Test::Builder;

no warnings qw/ uninitialized /;    # I know, I'm a bad boy

Moose::Exporter->setup_import_methods( as_is => ['test_wrap'] );


sub test_wrap {
    my ( $test, %args ) = @_;

    my @tests = ref $test ? @$test : ($test);

    my $package = __PACKAGE__;
    my $level = 1;

    ($package) = caller $level++ while $package eq __PACKAGE__;

    for my $t (@tests) {

        my $to_wrap = join '::', $package, $args{prefix} . $t;

        my $original = join '::', $package, $t;
        my $original_ref = eval '\&' . $original;

        my $proto = prototype $original_ref;
        $proto &&= "($proto)";

        no warnings qw/ redefine /;

        eval sprintf <<'END', $to_wrap, $proto;
            sub %s %s {
                Test::Wrapper->run_test( $t, $original_ref, @_ );
            }
END

        die $@ if $@;
    }
}


has [qw/ diag output todo /] => ( is => 'ro', );

sub is_success {
    return $_[0]->output =~ /^ok/;
}

has "_test_args" => (
    traits => [ 'Array' ],
    isa => 'ArrayRef',
    is => 'ro',
    default => sub { [] },
    handles => {
        test_args => 'elements',
    },
);

has "test_name" => (
    isa => 'Str',
    is => 'ro',
);


sub BUILD {
    my $self = shift;

    # we don't need the commenting
    $self->{diag} =~ s/^\s*#//mg;
}

sub run_test {
    my( undef, $name, $original_ref, @args ) = @_;
    $name =~ s/^:://;

    local $Test::Builder::Test = undef;

    my $builder = Test::Builder->new;

    $builder->{Have_Plan}        = 1;
    $builder->{Have_Output_Plan} = 1;
    $builder->{Expected_Tests}   = 1;

    $builder->{History} = Test::Builder2::History->create
        if Test::More->VERSION >= 2;

    $builder->output( \my $output );
    $builder->failure_output( \my $failure);
    $builder->todo_output( \my $todo );

    $original_ref->( @args );

    return Test::Wrapper->new(
        test_name => $name,
        _test_args => \@args,
        output    => $output,
        diag      => $failure,
        todo      => $todo,
    );

}


use overload
  'bool' => 'is_success',
  '""'   => sub { $_[0]->diag };

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Wrapper - Use Test::* tests outside of a TAP context

=head1 VERSION

version 0.3.0

=head1 SYNOPSIS

    use Test::Wrapper;
    use Test::More;

    test_wrap( 'like' );

    # doesn't output anything
    my $test = like 'foo' => qr/bar/;

    unless ( $test->is_success ) {
        print "test failed, diag output is: ", $test->diag;
    }

=head1 DESCRIPTION

This module for the occasions where a C<Test::*> test would
be perfect for what you want to do, but the module doesn't provide
an helper function that doesn't produce TAP. 

C<Test::Wrapper> exports a single function, C<test_wrap>, in the calling package,
which wraps the desired testing functions.  After being wrapped, the test
functions will not emit TAP anymore, but rather return a C<Test::Wrapper>
object.

It must be noted that C<Test::Wrapper> only works with test modules inheriting
from L<Test::Builder::Module>.

Finally, C<Test::Wrapper> will not mess up the L<Test::Builder>, which means
that if you really want, you can use it within a test file. For example, this
would work:

    use strict;
    use warnings;

    use Test::More tests => 1;

    use Test::Differences;
    use Test::Wrapper;

    test_wrap( 'eq_or_diff' );

    my $test = eq_or_diff "foo", "bar";

    ok $test, "eq_or_diff passed" or diag $test->diag;

=head1 EXPORTED METHOD

=head2 test_wrap( $test | \@tests, %params )

Wraps the given test or tests such that, when invoked, they will
not emit TAP output but return a C<Test::Wrapper> object.

The parameters the function accepts are:

=over

=item prefix 

If defined, a wrapped function named '$prefix_<original_name>' will
be created, and the original test function will be left alone.

    use Test::More;
    use Test::Wrapper;

    test_wrap( 'like', prefix => 'wrapped_' );

    like "foo" => qr/bar/;   # will emit TAP

                             # will not emit TAP
    my $test = wrapped_like( "yadah" => qw/ya/ );

Note that since the wrapped function will be created post-compile time, 
its prototype will not be effective, so parenthesis have to be used.

    test_wrap( 'is' );
    test_wrap( 'like', prefix => 'wrapped' );

        # prototype of the original function makes
        # it magically work
    my $t1 = is $foo => $bar; 

        # this, alas, will break
    my $t2 = like $foo => qr/$baz/;

        # ... so you have to do this instead
    my $t2 = like( $foo => qr/$baz/ );

=back

=head1 Attributes

=head2 diag

Diagnostic message of the test. Will be empty if the test passed.
The leading '#' of each line of the raw TAP output are stripped down.

=head2 is_success

Is C<true> if the test passed, C<false> otherwise.

=head2 todo

TODO message of the test.

=head2 output

TAP result of the test '(I<ok 1 - yadah>'). 

=head2 test_name

Name of the wrapped test.

=head2 test_args

The list of arguments passed to the test.

=head1 OVERLOADING

=head2 Boolean context

In a boolean context, the object will returns the value given by its
C<is_success> attribute.

    test_wrap( 'like' );

    my $test = like $foo => $bar;

    if ( $test ) {
        ...
    }

=head2 Stringify

If stringified, the object will return the content of its C<diag> attribute.

    print $test unless $test;

    # equivalent to 
    
    unless ( $test->is_success ) {
        print $test->diag;
    }

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
