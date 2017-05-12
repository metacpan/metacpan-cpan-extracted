package
  MyBuilder;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use File::Find;
use File::Basename ();
use File::Path;

use base qw(Module::Build File::Spec);

sub find_dist_packages {
  my ($self) = @_;

  my $primary_ver = $self->dist_version;

  $primary_ver =~ s/^v//;

  my %dist_packs = ($self->module_name
		    , {file => $self->dist_version_from
		       , version => $primary_ver});

  my $pm_files = $self->pm_files;
  foreach my $realfile (keys %$pm_files) {
    my $pack = $pm_files->{$realfile};
    $pack =~ s!^lib/!!;
    $pack =~ s!/!::!g;
    $pack =~ s!\.pm$!!;
    $dist_packs{$pack} = +{file => $realfile
			   , version => $primary_ver};
  }

  \%dist_packs;
}

1;
__END__

