package YATT::Lite::Walker;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use YATT::Lite::Breakpoint;
sub MY () {__PACKAGE__}
use mro 'c3';

use Exporter qw/import/;
our @EXPORT = qw/walk/;
our @EXPORT_OK = (@EXPORT, qw/walk_vfs_folders/);

use YATT::Lite::Factory;
use YATT::Lite::Util qw/lexpand/;

sub walk {
  (my %opts) = @_;

  my $self = delete $opts{factory} or Carp::croak "factory is missing!";
  my $fromList = delete $opts{from} // $self->{cf_doc_root};
  my $nameRe = delete $opts{name_match};
  my $noSymlink = delete $opts{ignore_symlink};

  my ($forWidget) = grep {defined} (delete $opts{widget}, delete $opts{part});
  $forWidget //= sub {
    my ($args) = @_;
    print $args->{widget}, "\n";
  };
  my $forItem = delete $opts{item} // sub {
    my ($args) = @_;
    print "# ", $args->{tree}->cget('path'), "\n";
  };

  if (%opts) {
    Carp::croak "Unknown options for traverse: ".join(", ", sort keys %opts);
  }

  my %seen;
  my $walk; $walk = sub {
    my ($vfs, $tree, $prefix) = @_;
    $forItem->({tree => $tree, vfs => $vfs});
    my $path = $tree->cget('path');
    return if -l $path and $noSymlink;
    if ($tree->can_generate_code) {
      # Template
      $seen{$path}++;
      foreach my $part ($tree->list_parts) {
        my $partName = $part->cget('name');
        my @path = (@{$prefix // []}, $partName || ());
        next unless @path;
        my $wname = do {
          if (UNIVERSAL::isa($part, 'YATT::Lite::Core::Widget')) {
            join(":", @path);
          } else {
            $partName;
          }
        };
        if ($nameRe and $wname !~ $nameRe) {
          next;
        }
        $forWidget->({part => $part, name => $wname, kind => $part->{cf_kind}});
      }
    } else {
      # Dir
      foreach my $itemName ($tree->list_all_names($vfs)) {
        my $subtree = $tree->lookup_1($vfs, $itemName)
          or next;
        next if $seen{$subtree->{cf_path}}++;
        $walk->($vfs, $subtree, [@{$prefix // []}, $itemName]);
      }
    }

    foreach my $superItem ($tree->list_base) {
      next if $seen{$superItem->{cf_path}}++;
      $walk->($vfs, $superItem);
    }
  };

  foreach my $fromPath (lexpand($fromList)) {
    my ($dir, $rootName) = do {
      if (-d $fromPath) {
        ($fromPath, '')
      } else {
        my ($fn, $dn, $ext)
          = File::Basename::fileparse($fromPath, qr{\.\w+\z});
        ($dn, $fn, $ext);
      }
    };

    my $yatt = $self->load_yatt($dir);
    my $vfs = $yatt->get_trans;

    my $rootPart = $rootName
      ? $vfs->find_file($rootName)
      : $vfs->{root};

    $walk->($vfs, $rootPart);
  }
}

sub walk_vfs_folders {
  (my %opts) = @_;

  my $self = delete $opts{factory} or Carp::croak "factory is missing!";
  my $fromList = delete $opts{from} // $self->{tmpldirs};
  my $noSymlink = delete $opts{ignore_symlink};

  my $dirAction = delete $opts{dir} // sub {
    my ($dir, $vfs) = @_;
    # print join("\t", dir => $yatt->cget('dir'), $yatt->EntNS), "\n";
    print join("\t", dir => $dir->cget('path'), $dir->cget('entns')), "\n";
  };

  my $fileAction = delete $opts{file} // sub {
    my ($tmpl) = @_;
    print join("\t", file => $tmpl->cget('path'), $tmpl->cget('entns')), "\n";
  };

  if (%opts) {
    Carp::croak "Unknown options for traverse: ".join(", ", sort keys %opts);
  }

  my %seen;
  my $walk; $walk = sub {
    my (@dirName) = @_;
    foreach my $dirName (@dirName) {
      next if $seen{$dirName}++;
      next if -l $dirName and $noSymlink;
      my $yatt = $self->load_yatt($dirName);
      my $vfs = $yatt->get_vfs;
      $dirAction->($vfs->root, $yatt);
      my @subDir;
      foreach my $name ($vfs->list_all_names) {
        my $path = "$dirName/$name";
        next unless -e $path;
        if (-d $path) {
          push @subDir, $path;
        } else {
          next if $seen{$path}++;
          my $tmpl = $yatt->find_part($name);
          my $realFn = $tmpl->cget('path');
          next if -l $realFn and $noSymlink;
          $fileAction->($tmpl, $yatt);
        }
      }

      $walk->(@subDir) if @subDir;

      $walk->($yatt->list_base);
    }
  };

  $walk->(lexpand($fromList));
}

1;
