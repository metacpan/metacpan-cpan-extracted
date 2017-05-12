use strict;
use warnings;
use 5.010;

use DateTime;

use lib '/Users/rjbs/code/hub/list-cell/lib';

{
  package Calendar;
  use Moose;

  has first_cell => (
    is  => 'ro',
    isa => 'Calendar::Cell',
    writer   => '_set_first_cell',
    required => 1,
  );

  sub BUILD {
    my ($self) = @_;
    $self->_ensure_start_sunday;
    $self->_ensure_end_saturday;
  }

  sub _ensure_start_sunday {
    my ($self) = @_;

    my $first = $self->first_cell;

    while ($first->day_of_week != 0) {
      my $prev_cell = Calendar::Cell->new({
        date => $first->date - DateTime::Duration->new(days => 1)
      });

      $first->replace_prev($prev_cell);

      $first = $prev_cell;
    }

    $self->_set_first_cell($first) if $first != $self->first_cell;
  }

  sub _ensure_end_saturday {
    my ($self) = @_;

    my $last = $self->first_cell->last;

    while ($last->day_of_week != 6) {
      my $next_cell = Calendar::Cell->new({
        date => $last->date + DateTime::Duration->new(days => 1)
      });

      $last->replace_next($next_cell);

      $last = $next_cell;
    }
  }
}

{
  package Calendar::Cell;
  use Moose;
  with 'List::Cell';

  has date => (is => 'ro', isa => 'DateTime', required => 1);

  sub day_of_week {
    return $_[0]->date->day_of_week % 7
  }
}

my $cal = Calendar->new({
  first_cell => Calendar::Cell->new({
    date => DateTime->now(time_zone => 'local')
  }),
});

for (my $cell = $cal->first_cell; $cell; $cell = $cell->next) {
  printf "%2s: %s\n", $cell->day_of_week, $cell->date->ymd;
}

