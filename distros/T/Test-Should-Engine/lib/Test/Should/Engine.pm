package Test::Should::Engine;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.04';

use Carp ();
use Storable ();

our @CARP_NOT = (__PACKAGE__);

sub run {
    my ($class, $pattern, $subject, @args) = @_;

    if ($pattern =~ /^should_not_(.+)$/) {
        $pattern = "should_$1";
        return !$class->run($pattern, $subject, @args);
    } elsif ($pattern eq 'should_be_ok' || $pattern eq 'should_be_true') {
        return !!$subject;
    } elsif ($pattern eq 'should_be_false') {
        return !$subject;
    } elsif ($pattern eq 'should_be_undef') {
        return not defined($subject);
    } elsif ($pattern eq 'should_be_empty') {
        if (ref $subject eq 'ARRAY') {
            return (@$subject == 0);
        } else {
            return length($subject) == 0;
        }
    } elsif ($pattern eq 'should_be_equal') {
        local $Storable::canonical = 1;
        return Storable::nfreeze(\$subject) eq Storable::nfreeze(\$args[0]);
    } elsif ($pattern =~ /^should_be_an?$/) {
        return UNIVERSAL::isa($subject, $args[0]);
    } elsif ($pattern eq 'should_be_above') {
        return $subject > $args[0];
    } elsif ($pattern eq 'should_be_below') {
        return $subject < $args[0];
    } elsif ($pattern eq 'should_match') {
        return !!($subject =~ $args[0]);
    } elsif ($pattern eq 'should_have_length') {
        if (ref $subject eq 'ARRAY') {
            return (@$subject == $args[0]);
        } else {
            return length($subject) == $args[0];
        }
    } elsif ($pattern eq 'should_include') {
        if (ref $subject eq 'ARRAY') {
            for (@$subject) {
                return 1 if $_ eq $args[0];
            }
            return 0;
        } else {
            return index($subject, $args[0]) >= 0;
        }
    } elsif ($pattern eq 'should_throw') {
        eval {
            $subject->()
        };
        if (ref $args[0] eq 'Regexp') {
            return $@ =~ $args[0];
        } else {
            return !!$@;
        }
    } elsif ($pattern eq 'should_have_keys') {
        my %copy = %$subject;
        for (@args) {
            return 0 unless exists $copy{$_};
            delete $copy{$_};
        }
        return keys(%copy) == 0;
    } else {
        Carp::croak("Unknown pattern: $pattern");
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Test::Should::Engine - Should it be OK?

=head1 SYNOPSIS

    use Test::Should::Engine;

    Test::Should::Engine->run('should_be_ok', 1);

=head1 DESCRIPTION

Test::Should::Engine is yet another assertion library for Perl5.

You don't need to use this module directly. This module may include to other testing libraries.

B<This module is currently under development. API MAY change WITHOUT notice.>

=head1 METHOD

=over 4

=item Test::Should::Engine->run($pattern, $subject, @args);

This method checks the $subject by $pattern with @args and return boolean value.

=back

=head1 RULES

In this section, the code uses L<Test::Should>.

=over 4

=item should_be_ok

    1->should_be_ok()

Assert truthfulness.

=item should_be_empty

    []->should_be_empty()
    ''->should_be_empty()

On ArrayRef, it doesn't have a elements.

On String, the length is zero.

=item should_be_equal

    [1,2,3]->should_be_equal([1,2,3])

strict equality.

=item should_be_a / should_be_an

    MyObj->new()->should_be_a('MyObj');
    MyObj->new()->should_be_an('ARRAY');

Checks type.

=item should_be_above

    9->should_be_above(4)

Assert numeric value above the given value.

=item should_be_below

    2->should_be_below(4)

Assert numeric value below the given value.

=item should_match

    'hoge'->should_match(qr/h.ge/);

Assert regexp match.

=item should_have_length

    'hoge'->should_have_length(4);
    [1,2,3]->should_have_length(3);

Assert the length has a value of the given number.

=item should_include

    # array
    [1,2,3]->should_include(3)
    [1,2,3]->should_not_include(4)

    # string
    'foo bar baz'.should.include('foo')

Assert the subject includes a value.

=item should_throw

Assert an exception is thrown:

    (sub { die })->should_throw();

Assert an exception is not thrown:

    (sub { 1 })->should_not_throw();

Assert exception message matches regexp:

    (sub { die "Foo" })->should_throw(qr/F/);

=item should_not_*

Invert the result.

=back

=head1 USAGE

You can embed this module to your code by following style :)

I'll be release this style module named by Test::Should.

You can see more details in t/01_autobox.t.

    use Test::Should::Engine;
    use Test::More;

    {
        package UNIVERSAL;
        sub DESTROY { }
        our $AUTOLOAD;
        sub AUTOLOAD {
            $AUTOLOAD =~ s/.*:://;
            my $test = Test::Should::Engine->run($AUTOLOAD, @_);
            Test::More->builder->ok($test);
        }
    }

    # and test code
    (bless [], 'Foo')->should_be_ok();
    (bless [], 'Foo')->should_be_a('Foo');
    (bless [], 'Foo')->should_not_be_a('Bar');

    done_testing;

=head1 FAQ

=over 4

=item Why do you split a distribution from Test::Should?

Test::Should depends to autobox. autobox is not needed by some users.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

Most part of features are ported from L<https://github.com/visionmedia/should.js>, thanks!

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
