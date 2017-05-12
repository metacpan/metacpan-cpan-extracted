package
  MyBuilder;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use File::Find;
use File::Basename ();
use File::Path;

use base qw(Module::Build File::Spec);
use Module::CPANfile;

sub lexpand {
  return unless defined $_[0];
  %{$_[0]};
}

sub my_cpanfile_specs {
  my ($pack) = @_;
  my $file = Module::CPANfile->load("cpanfile");
  my $prereq = $file->prereq_specs;
  my %args;
  %{$args{requires}} = lexpand($prereq->{runtime}{requires});
  foreach my $phase (qw/configure runtime build test/) {
    %{$args{$phase . "_requires"}} = lexpand($prereq->{$phase}{requires});
  }
  %{$args{recommends}} = (map {lexpand($prereq->{$_}{recommends})}
			  keys %$prereq);
  %args
}

#
# To include yatt_dist as_is
#
sub process_yatt_dist_files {
  my ($self) = @_;

  $self->pm_files(\ my %pm_files);
  $self->pod_files(\ my %pod_files);

  foreach my $desc ([pm => \%pm_files], [pod => \%pod_files]) {
    my ($ext, $map) = @$desc;
    my ($src, $dest) = ("Lite.$ext", "lib/YATT/Lite.$ext");
    $map->{$src} = $dest;
    $self->_yatt_dist_ensure_blib_copied($src, $dest);
  }

  # Lite/ should go into blib/lib/YATT/Lite
  find({no_chdir => 1, wanted => sub {
	  return $self->prune if /^\.git|^lib$/;
	  return if -d $_;
	  my $dest;
	  if (/\.pm$/) {
	    $dest = \%pm_files
	  } elsif (/\.pod$/) {
	    $dest = \%pod_files
	  } else {
	    return;
	  }
	  my $d = $dest->{$_} = "lib/YATT/$_";
	  $self->_yatt_dist_ensure_blib_copied($_, $d);
	}}, "Lite");

  # scripts/ and elisp/ also should go into blib/lib/YATT/
  # XXX: This may be changed to blib/lib/YATT/Lite/ or somewhere else.
  find({no_chdir => 1, wanted => sub {
	  return $self->prune if /^\.git|^lib$/;
	  return if -d $_;
	  return unless m{/yatt[^/]*$|\.el$};
	  my $d = $pm_files{$_} = "lib/YATT/$_";
	  $self->_yatt_dist_ensure_blib_copied($_, $d);
	  }}, 'scripts', 'elisp');
}

sub _yatt_dist_ensure_blib_copied {
  my ($self, $from, $dest) = @_;
  my $to = $self->catfile($self->blib, $dest);
  if ($ENV{DEBUG_BUILD}) {
    print STDERR "$from => $to\n";
  } else {
    $self->copy_if_modified(from => $from, to => $to);
  }
}

sub prune {
  $File::Find::prune = 1;
}

#========================================
#
# To remove leading 'v' from dist_version.
#

sub dist_version {
  my ($self) = @_;
  my $ver = $self->SUPER::dist_version
    or die "Can't detect dist_version";
  $ver =~ s/^v//;
  $ver;
}

1;
__END__

# Please ignore below.

$build->add_build_element($elem);

$build->process_${element}_files($element);

$build->_find_file_by_...;

$self->copy_if_modified(from => $fn, to => $self->catfile($self->blib, $dest));

    ExtUtils::Install::install(
      $self->install_map, $self->verbose, 0, $self->{args}{uninst}||0
    );

$self->install_map

$self->install_types
 # install_base => installbase_relpaths
 # prefix       => prefix_relpaths
 # else         => install_sets(installdirs)
 # +
 # %{install_path}

 $localdir = catdir($blib, $type);
 $dest = $self->install_destination($type)

 $map{$localdir} = $dest;


_default_install_paths
 =>
  * install_sets
  * install_base_relpaths
  * prefix_relpaths
  


ACTION_code

ACTION_install

