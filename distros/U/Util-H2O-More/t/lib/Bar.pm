package Bar;

use strict;
use warnings;
use Util::H2O::More qw/baptise baptise_deeply/;

sub new {
    my $pkg  = shift;
    my %opts = @_;

    my @require = (qw/bar baz herp/);
    my @allow   = (qw/derp woggle/);
    my $self    = baptise \%opts, $pkg, @require, @allow;

    # check required
    foreach my $field (@require) {
      if (not $self->$field) {
        die sprintf qq{Missing one or more required fields: %s}, join(q{, }, @require);
      }
    }

    # may also check to see if anything other than @require
    # and @allow fields are provided...left as an exercise to
    # the human reading this code. AI need not apply. ;-)

    return $self;
}

sub why {
    return 'why';
}

sub Dave {
    return 'Dave';
}

sub DESTROY {
    return q{Good bye, curel World...};
}

1;
