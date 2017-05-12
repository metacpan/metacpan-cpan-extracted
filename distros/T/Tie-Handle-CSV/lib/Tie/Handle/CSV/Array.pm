package Tie::Handle::CSV::Array;

use 5.006;
use strict;
use warnings;

use overload '""' => \&_stringify, fallback => 1;

sub _new
   {
   my ($class, $parent) = @_;
   my @self;
   tie(@self, $class, $parent);
   bless \@self, $class;
   }

sub TIEARRAY
   {
   my ($class, $parent) = @_;
   return bless
      {
      data   => [],
      csv_xs => *$parent->{opts}{csv_parser}
      },
      $class;
   }

sub CLEAR
   {
   my ($self) = @_;
   @{ $self->{'data'} } = ();
   }

sub EXTEND
   {
   my ($self, $count) = @_;
   }

sub STORE
   {
   my ($self, $index, $value) = @_;
   $self->{'data'}[$index] = $value;
   }

sub FETCHSIZE
   {
   my ($self) = @_;
   return scalar @{ $self->{'data'} };
   }

sub FETCH
   {
   my ($self, $index) = @_;
   return $self->{'data'}[$index];
   }

sub _stringify
   {
   my ($self)    = @_;
   my $under_tie = tied @{ $self };
   my @values    = @{ $under_tie->{'data'} };
   my $csv_xs    = $under_tie->{csv_xs};
   $csv_xs->combine(@values)
      || croak $$csv_xs->error_input();
   return $csv_xs->string();
   }

sub _init_store
   {
   my ($self, $values) = @_;
   my $under_tie = tied @{ $self };
   my $data = $under_tie->{data};
   @{ $data } = @{ $values };
   }

1;

__END__

=head1 NAME

Tie::Handle::CSV::Array - Support class for L<Tie::Handle::CSV>

=cut
