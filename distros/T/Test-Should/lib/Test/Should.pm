package Test::Should;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.04';
use Test::Should::Engine;
use Data::Dumper ();

use parent qw/autobox/;

sub import {
    my $class = shift;

    $class->SUPER::import(
        'DEFAULT' => 'Test::Should::Impl::Default',
        'UNDEF'   => 'Test::Should::Impl::Default',
        'CODE' => 'Test::Should::Impl::Code',
    );
}

my $ddf = sub {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::MaxDepth = 0;
    Data::Dumper::Dumper(@_);
};

sub _autoload {
    my $method = shift;
    my $test = Test::Should::Engine->run($method, @_);
    my $builder = Test::Builder->new();
    $builder->ok($test, join('',
        $ddf->($_[0]),
        ' ',
        $method,
        $_[1] ? ' ' . $ddf->($_[1]) : ''
    ));
}

package # hide from pause
    Test::Should::Impl::Code;
use parent -norequire, qw/Test::Should::Impl/;

sub should_change {
    my ($modifier, $checker) = @_;
    my $first = $checker->();
    $modifier->();
    my $second = $checker->();

    my $builder = Test::Builder->new();
    $builder->isnt_eq($first, $second, 'should_change');

    return Test::Should::Term::ShouldChange->new(
        first => $first,
        second => $second,
    );
}

package # hide from pause
    Test::Should::Term::ShouldChange;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub by {
    my ($self, $by) = @_;
    my $builder = Test::Builder->new();
    $builder->is_eq($self->{second}, $by, "changed by $by");
}

package # hide from pause
    Test::Should::Impl::Default;

package # hide from pause
    UNIVERSAL;

sub DESTROY { }

our $AUTOLOAD;
sub AUTOLOAD {
    $AUTOLOAD =~ s/.*:://;
    if ($AUTOLOAD =~ /^should_/) {
        Test::Should::_autoload("$AUTOLOAD", @_);
    } else {
        Carp::croak("Unknown method: $AUTOLOAD");
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Test::Should - Should it be OK??

=head1 SYNOPSIS

    use Test::More;
    use Test::Should;

    1->should_be_ok;
    [1,2,3]->should_include(3);

    done_testing;

    # testing result:
    ok 1 - 1 should_be_ok
    ok 2 - [1,2,3] should_include 3
    1..2

=head1 DESCRIPTION

Test::Should is yet another testing library to write human readable test case.

And this module generates human readable test case description.

B<This is a development release. I may change the API in the future>

For more method name details, please look L<Test::Should::Engine>

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
