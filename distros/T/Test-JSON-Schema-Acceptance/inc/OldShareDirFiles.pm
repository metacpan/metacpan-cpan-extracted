use strict;
use warnings;
package inc::OldShareDirFiles;
use Moose;
with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::BeforeRelease';
use Dist::Zilla::File::InMemory;
use Capture::Tiny 'capture';
use Path::Tiny;
use namespace::autoclean;

# for every file leaving the test suite, we must replace it with an empty file so ->_test_data can
# filter it out, because File::ShareDir::Install cannot remove old files when installing a new
# sharedir over top. see https://rt.cpan.org/Ticket/Display.html?id=92084#txn-1324511

has removed => ( is => 'ro', isa => 'ArrayRef[Str]', required => 1 );
sub mvp_multivalue_args { qw(removed) };

sub gather_files {
  my $self = shift;

  foreach my $filename (@{$self->removed}) {
    my $content = path('share/tests')->subsumes($filename) ? '[]'
      : path('share/remotes')->subsumes($filename) ? '{}'
      : die "don't know how to handle filename '$filename'";

    $self->add_file(Dist::Zilla::File::InMemory->new({ name => $filename, content => $content }))
  }
  return;
}

sub before_release {
  my $self = shift;

  my $distname = $self->zilla->name;
  my $version = $self->zilla->version;

  my ($diff, $error) = capture {
    system('diff', '-u', $distname.'-'.sprintf("%.3f", $version-0.001).'/MANIFEST', $distname.'-'.$version.'/MANIFEST');
  };

  die $error if $error;

  # skip old share/tests/draft-future -- not officially supported by any implementation
  # (now known as draft-next)
  $diff =~ s{^-share/tests/draft-future/.+\n}{}gm;

  if (my @missing = map s/^-//r, grep m{^-share/}, split /\n/, $diff) {
    $self->log_fatal(join "\n", '',
      'These files were removed from the test suite and must be added to the config for [=inc::OldShareDirFiles]:',
      @missing,
      '',
    );
  }
}

1;
