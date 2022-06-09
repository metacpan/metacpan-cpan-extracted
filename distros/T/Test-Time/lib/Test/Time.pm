package Test::Time;
use strict;
use warnings;

use Test::More;

our $VERSION = '0.092';
our $time = CORE::time();

my $pkg = __PACKAGE__;
my $in_effect = 1;

sub in_effect {
	$in_effect;
}

sub __time () {
	if (in_effect) {
		$time;
	} else {
		CORE::time();
	}
}

sub __sleep (;$) {
	if (in_effect) {
		my $sleep = shift || 1;
		$time += $sleep;
		note "sleep $sleep";
	} else {
		CORE::sleep(shift);
	}
}

sub __localtime (;$) {
	my $arg = shift;
	if (in_effect) {
		$arg ||= $time;
	}
	return defined $arg ? CORE::localtime($arg) : CORE::localtime();
}

sub import {
	my ($class, %opts) = @_;
	$in_effect = 1;
	$time = $opts{time} if defined $opts{time};

	*CORE::GLOBAL::time = \&__time;
	*CORE::GLOBAL::sleep = \&__sleep;
	*CORE::GLOBAL::localtime = \&__localtime;
};

sub unimport {
	$in_effect = 0;
}

1;
__END__

=encoding utf8

=head1 NAME

Test::Time - Overrides the time() and sleep() core functions for testing

=head1 SYNOPSIS

    use Test::Time;

    # Freeze time
    my $now = time();

    # Increment internal time (returns immediately)
    sleep 1;

    # Return internal time incremented by 1
    my $then = time();


=head1 DESCRIPTION

Test::Time can be used to test modules that deal with time. Once you C<use> this
module, all references to C<time>, C<localtime> and C<sleep> will be internalized.
You can set custom time by passing time => number after the C<use> statement:

    use Test::Time time => 1;

    my $now = time;    # $now is equal to 1
    sleep 300;         # returns immediately, displaying a note
    my $then = time;   # $then equals to 301

=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
