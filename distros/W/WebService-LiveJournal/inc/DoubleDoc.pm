package inc::DoubleDoc;

use Moose;
use v5.10;
with 'Dist::Zilla::Role::FileMunger';

sub munge_files
{
  my($self) = @_;

  my($nexgen) = grep { $_->name eq 'lib/WebService/LiveJournal.pm' } @{ $self->zilla->files };
  my($legacy) = grep { $_->name eq 'lib/WebService/LiveJournal/Client.pm' } @{ $self->zilla->files };
  
  $self->zilla->log_fatal("couldn't find nexgen and legacy versions")
    unless defined $nexgen && defined $legacy;

  my @pod = split /\n/, $legacy->content;
  chomp @pod;
  while(defined $pod[0] && $pod[0] ne '=pod')
  { shift @pod }

  for(@pod)
  {
    last if s{^WebService::LiveJournal::Client - }{WebService::LiveJournal - };
  }
  
  #my $readme = $self->zilla->root->file('README.pod')->absolute;
  #$readme->spew(join "\n", @pod);
  #$self->zilla->log("writing $readme");
  
  my @nexgen = split /\n/, $nexgen->content;
  while(defined $nexgen[-1] && $nexgen[-1] ne '=pod')
  { pop @nexgen }
  pop @nexgen;

  $nexgen->content(join("\n", @nexgen, @pod));  
}

1;
