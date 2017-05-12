package autobox::DateTime::Duration;

use strict;
use 5.8.1;
our $VERSION = '0.02';

use autobox;
use DateTime;
use DateTime::Duration;

for my $accessor (qw( day hour minute month second week year )) {
    no strict 'refs';
    my $plural = $accessor . "s";
    *{"SCALAR::$accessor"} = *{"SCALAR::$plural"} = sub {
        DateTime::Duration->new($plural => $_[0]);
    };
}

sub SCALAR::fortnight {
    DateTime::Duration->new(weeks => 2 * $_[0]);
}

*SCALAR::fortnights = \&SCALAR::fortnight;

sub DateTime::Duration::ago {
    my $duration = shift;
    my $dt = $_[0] ? $_[0]->clone : DateTime->now;
    $dt->subtract_duration($duration);
}

*DateTime::Duration::until = \&DateTime::Duration::ago;

sub DateTime::Duration::from_now {
    my $duration = shift;
    my $dt = $_[0] ? $_[0]->clone : DateTime->now;
    $dt->add_duration($duration);
}

*DateTime::Duration::since = \&DateTime::Duration::from_now;

1;
__END__

=for stopwords DateTime ActiveSupport autobox

=head1 NAME

autobox::DateTime::Duration - ActiveSupport equivalent to Perl numeric variables

=head1 SYNOPSIS

  use autobox;
  use autobox::DateTime::Duration;

  # equivalent to DateTime::Duration->new(months => 1, days => 5);
  $duration = 1->month + 2->days;

  # equivalent to DateTime->now->add(years => 2);
  $datetime = 2->years->from_now;

  # equivalent to DateTime->now->add(months => 4, years => 5);
  $datetime = (4->months + 5->years)->from_now;

  # equivalent to DateTime->now->subtract(days => 3);
  $datetime = 3->days->ago;

=head1 DESCRIPTION

autobox::DateTime::Duration is an autobox module to add Time-related
methods to core integer values by using constant overloading. Inspired
by ActiveSupport (Rails) Core extensions to Numeric values.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://api.rubyonrails.org/classes/ActiveSupport/CoreExtensions/Numeric/Time.html>

L<DateTime::Duration>, L<bigint>, L<overload>

=cut
