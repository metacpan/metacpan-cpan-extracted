package Tie::Handle::CSV::Hash;

use 5.006;
use strict;
use warnings;

use Carp 'cluck';

use overload '""' => \&_stringify, fallback => 1;

sub _new
   {
   my ($class, $parent) = @_;
   my %self;
   tie(%self, $class, $parent);
   bless \%self, $class;
   }

sub TIEHASH
   {
   my ($class, $parent) = @_;
   my $opts      = *$parent->{opts};
   my $self      = bless
      {
      data   => {},
      csv_xs => $opts->{csv_parser},
      header => $opts->{header},
      },
      $class;

   $self->{'lc'} = defined $opts->{'key_case'} && lc $opts->{'key_case'} eq 'any';
   return $self;
   }

sub STORE
   {
   my ($self, $key, $value) = @_;
   $key = lc $key if $self->{lc};
   $self->{'data'}{$key} = $value;
   }

sub FETCH
   {
   my ($self, $key) = @_;
   $key = lc $key if $self->{lc};
   return $self->{'data'}{$key};
   }

sub EXISTS
   {
   my ($self, $key) = @_;
   $key = lc $key if $self->{lc};
   exists $self->{'data'}{$key};
   }

sub DELETE
   {
   my ($self, $key) = @_;
   $key = lc $key if $self->{lc};
   delete $self->{'data'}{$key};
   }

sub CLEAR
   {
   my ($self) = @_;
   %{ $self->{'data'} } = ();
   }

sub FIRSTKEY
   {
   my ($self) = @_;
   $self->{'keys'} = [ @{ $self->{'header'} } ];
   return shift @{ $self->{'keys'} };
   }

sub NEXTKEY
   {
   my ($self) = @_;
   @{ $self->{'keys'} }
      ? return shift @{ $self->{'keys'} }
      : return;
   }

sub _stringify
   {
   my ($self) = @_;
   my $under_tie = tied %{ $self };
   my $keys   = $under_tie->{'header'};
   if ($under_tie->{'lc'})
      {
      $keys = [ map { lc($_) } @{ $keys } ];
      }
   my @values = @{ $under_tie->{'data'} }{ @{ $keys } };
   my $csv_xs    = $under_tie->{csv_xs};
   $csv_xs->combine(@values)
      || croak $$csv_xs->error_input();
   return $csv_xs->string();
   }

sub _init_store
   {
   my ($self, $values) = @_;
   my $under_tie = tied %{ $self };
   my $keys   = $under_tie->{'header'};
   if ($under_tie->{'lc'})
      {
      $keys = [ map { lc($_) } @{ $keys } ];
      }
   my $data = $under_tie->{data};
   @{ $data }{ @{ $keys } } = @{ $values };
   }

1;

__END__

=head1 NAME

Tie::Handle::CSV::Hash - Support class for L<Tie::Handle::CSV>

=cut
