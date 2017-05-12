
package Test::Float::Iterator;

use strict;
use vars qw($VERSION);
$VERSION = 0.02;

=head1 NAME

Test::Float::Iterator - Internal Test::Float Iterator

=head1 SYNOPSIS

  use Test::Float::Iterator;
  my $it = Test::Float::Iterator->new(\*TEST);
  my $it = Test::Float::Iterator->new(\@array);

  my $line = $it->next;

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY!>

This is a simple iterator wrapper for arrays and filehandles.

=head2 new()

Create an iterator.

=head2 next()

Iterate through it, of course.

=cut

sub new {
    my($proto, $thing) = @_;

    my $self = {};
    if( ref $thing eq 'GLOB' ) {
        bless $self, 'Test::Float::Iterator::FH';
        $self->{fh} = $thing;
    }
    elsif( ref $thing eq 'ARRAY' ) {
        bless $self, 'Test::Float::Iterator::ARRAY';
        $self->{idx}   = 0;
        $self->{array} = $thing;
    }
    else {
        warn "Can't iterate with a ", ref $thing;
    }

    return $self;
}

package Test::Float::Iterator::FH;
sub next {
    my $fh = $_[0]->{fh};

    # readline() doesn't work so good on 5.5.4.
    return scalar <$fh>;
}


package Test::Float::Iterator::ARRAY;
sub next {
    my $self = shift;
    return $self->{array}->[$self->{idx}++];
}

"Steve Peters, Master Of True Value Finding, was here.";
