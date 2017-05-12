package Math::Business::SMA;

use strict;
use warnings;
use Carp;

1;

sub tag { (shift)->{tag} }

sub recommended { croak "no recommendation" }

sub new {
    my $class = shift;
    my $this  = bless {
        val => [],
        cur => undef,
        rec => 1,
    }, $class;

    my $days = shift;
    if( defined $days ) {
        $this->set_days( $days );
    }

    return $this;
}

sub set_days {
    my $this = shift;
    my $arg  = int(shift);

    croak "days must be a positive non-zero integer" if $arg <= 0;

    $this->{val} = [];
    delete $this->{SMA};
    $this->{days} = $arg;
    $this->{tag} = "SMA($this->{days})";
}

sub insert {
    my $this = shift;
    my $val  = $this->{val};
    my $N    = $this->{days};

    croak "You must set the number of days before you try to insert" if not defined $N;

    while( defined(my $PM = shift) ) {
        push @$val, $PM;

        if( @$val >= $N ) {
            if( defined( my $s = $this->{SMA} ) ) {
                my $old = shift @$val;
                $this->{SMA} = $s - $old/$N + $PM/$N;

            } else {
                my $sum = 0;
                   $sum += $_ for @$val;

                $this->{SMA} = $sum/$N;
            }
        }
    }
}

sub query {
    my $this = shift;

    return $this->{SMA};
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::SMA - Technical Analysis: Simple Moving Average

=head1 SYNOPSIS

  use Math::Business::SMA;

  my $avg = new Math::Business::SMA;
     $avg->set_days(7);

  my @closing_values = qw(
      3 4 4 5 6 5 6 5 5 5 5
      6 6 6 6 7 7 7 8 8 8 8
  );

  # choose one:
  $avg->insert( @closing_values );
  $avg->insert( $_ ) for @closing_values;

  if( defined(my $q = $avg->query) ) {
      print "value: $q.\n";

  } else {
      print "value: n/a.\n";
  }

For short, you can skip the set_days() by suppling the setting to new():

  my $longer_avg = new Math::Business::SMA(10);

=head1 AUTHOR

Paul Miller C<< <jettero@cpan.org> >>

I am using this software in my own projects...  If you find bugs, please please
please let me know.  There is a mailing list with very light traffic that you
might want to join: L<http://groups.google.com/group/stockmonkey/>.

=head1 COPYRIGHT

Copyright © 2013 Paul Miller

=head1 LICENSE

This is released under the Artistic License. See L<perlartistic>.

=head1 SEE ALSO

perl(1), L<Math::Business::StockMonkey>, L<Math::Business::StockMonkey::FAQ>, L<Math::Business::StockMonkey::CookBook>

L<http://en.wikipedia.org/wiki/Simple_moving_average>

=cut
