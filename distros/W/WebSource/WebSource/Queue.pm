package WebSource::Queue;

use strict;
use Carp;
use File::Spec;
use File::Copy;
use LockFile::Simple qw(lock trylock unlock);
use WebSource::Envelope;
use DateTime;

=head1 NAME

WebSource::Queue - Object encapusalting a filesystem based queue

=head1 DESCRIPTION

  A WebSource::Queue is used to access objects saved in a filesystem based queue.

=head1 SYNOPSIS

  use WebSource::Queue;
  ...
  my $queue = WebSource::Queue->new(
             directory => $path
             ...
       );
  ...
  $queue->enqueue($env);
  ...
  $queue->dequeue($env);

=head1 METHODS

=cut

sub new {
  my $class = shift;
  my %params = @_;
  $params{directory} or croak("No directory specified for queue");
  my $self = bless \%params, $class;
  return $self;
}

sub _lockfilepath {
  my $self = shift;
  return File::Spec->catfile($self->{directory},".lock");
}

sub enqueue {
  my ($self,$env) = @_;
  lock($self->_lockfilepath);
  my $dt = DateTime->now();
  my $itemname = $dt->ymd('') . $dt->hms('');  
  my $itembase = File::Spec->catfile($self->{directory},$itemname);
  my $itemcand = $itembase . '.itm';
  my $ext = "";
  while(-f $itemcand) {
    $ext++;
    $itemcand = $itembase . $ext . '.itm';
  }
  $env->to_file($itemcand);
  unlock($self->_lockfilepath);
}

sub dequeue {
  my ($self,$env) = @_;
  lock($self->_lockfilepath);
  my $dir = $self->{directory};
  my $itemfile;
  foreach my $cand (<${dir}*.itm>) {
    if(-f $cand) {
      $itemfile = $cand;
      last;
    }
  }
  if($itemfile) {
    move($itemfile, $itemfile . '.process');
    $itemfile = $itemfile . '.process';
  }
  unlock($self->_lockfilepath);
  if($itemfile) {
    return WebSource::Envelope->new_from_file($itemfile); 
  } else {
    return undef;
  }
}

=head1 SEE ALSO

WebSource

=cut

1;
