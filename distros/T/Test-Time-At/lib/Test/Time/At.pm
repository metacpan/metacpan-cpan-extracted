package Test::Time::At;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Test::Time;
use Scalar::Util qw(blessed);

use parent qw(Exporter);
our @EXPORT = qw(do_at sub_at);

sub do_at (&$) {
    my ($code, $time) = @_;
    my $epoch = (blessed $time && $time->can('epoch')) ? $time->epoch : $time + 0;
    local $Test::Time::time = $epoch;
    $code->();
}

sub sub_at (&$) {
    my ($code, $time) = @_;
    return sub { do_at(\&$code, $time) };
}

1;

__END__

=encoding utf-8

=head1 NAME

Test::Time::At - Do a test code, specifying the time

=head1 SYNOPSIS

    use Test::Time time => 1;
    use Test::Time::At;
    use Test::More;

    my $now = time; # $now is equal to 1 (by Test::Time)

    do_at {
        my $now_in_this_scope = time; # $now_in_this_scope is equal to 1000
        sleep 100; # returns immediately
        my $then_in_this_scope = time; # $then_in_this_scope is equal to 1100
    } 1000;

    my $then = time; # After do_at, time is equal to 1 again

=head1 DESCRIPTION

Test::Time::At supports to specify the time to do a test code.  You have to use L<Test::Time> with this module.

=head1 METHODS

=head2 do_at(&$)

Do a code at specifying epoch time.  You can specify the instance which has the method named 'epoch'.

    # You can specify epoch time
    do_at {
        my $now = time
    } 1000;

    # You can also specify the instance, for example Time::Piece and DateTime
    do_at {
        my $now = time
    } DateTime->new(year => 2015, month => 8, day => 10);

    do_at {
        my $now = time
    } Time::Piece->strptime('2015-08-10T06:29:10', '%Y-%m-%dT%H:%M:%S');

=head2 sub_at(&$)

sub_at is useful if you want to specify the time for subtest.  this prevents the nest from becoming deeper.

    subtest 'I want to this subtest on Aug. 10, 2015' => sub_at {
        my $now = time;
    } DateTime->new(year => 2015, month => 8, day => 10);

=head1 SEE ALSO

L<Test::Time>

=head1 LICENSE

Copyright (C) shibayu36.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

shibayu36 E<lt>shibayu36@gmail.comE<gt>

nanto_vi (TOYAMA Nao) E<lt>nanto@moon.email.ne.jpE<gt>

=cut

