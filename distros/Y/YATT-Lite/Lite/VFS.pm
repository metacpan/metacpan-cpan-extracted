package YATT::Lite::VFS;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Exporter qw(import);
use Scalar::Util qw(weaken);
use Carp;
use constant DEBUG_VFS => $ENV{DEBUG_YATT_VFS};
use constant DEBUG_REBUILD => $ENV{DEBUG_YATT_REBUILD};

require File::Spec;
require File::Basename;

#========================================
# VFS 層. vfs_file (Template) のダミー実装を含む。
#========================================
{
  sub MY () {__PACKAGE__}
  use YATT::Lite::Types
    ([Item => -fields => [qw(cf_name cf_public)]
      , [Folder => -fields => [qw(Item cf_path cf_parent cf_base
				  cf_entns)]
	 , -eval => q{use YATT::Lite::Util qw(cached_in);}
	 , [File => -fields => [qw(partlist cf_string cf_overlay
				   dependency
				)]
	    , -alias => 'vfs_file']
	 , [Dir  => -fields => [qw(cf_encoding)]
	    , -alias => 'vfs_dir']]]);

  sub YATT::Lite::VFS::Item::after_create {}
  sub YATT::Lite::VFS::Folder::configure_parent {
    my MY $self = shift;
    # 循環参照対策
    # XXX: Item に移すべきかもしれない。そうすれば、 Widget->parent が引ける。
    weaken($self->{cf_parent} = shift);
  }

  package YATT::Lite::VFS; BEGIN {$INC{"YATT/Lite/VFS.pm"} = 1}
  sub VFS () {__PACKAGE__}
  use parent qw(YATT::Lite::Object);
  use YATT::Lite::MFields qw/cf_ext_private cf_ext_public cf_cache cf_no_auto_create
		cf_facade cf_base
		cf_entns
		cf_always_refresh_deps
		on_memory
		root extdict
		cf_mark
		n_creates
		pkg2folder/;
  use YATT::Lite::Util qw(lexpand rootname terse_dump);
  sub default_ext_public {'yatt'}
  sub default_ext_private {'ytmpl'}
  sub new {
    my ($class, $spec) = splice @_, 0, 2;
    (my VFS $vfs, my @task) = $class->SUPER::just_new(@_);
    foreach my $desc ([1, ($vfs->{cf_ext_public}
				  ||= $vfs->default_ext_public)]
		      , [0, ($vfs->{cf_ext_private}
			     ||= $vfs->default_ext_private)]) {
      my ($value, @ext) = @$desc;
      $vfs->{extdict}{$_} = $value for @ext;
    }

    if ($spec) {
      my Folder $root = $vfs->root_create
	(linsert($spec, 2, $vfs->cf_delegate(qw(entns))));
      # Mark [data => ..] vfs as on_memory
      $vfs->{on_memory} = 1 if $spec->[0] eq 'data' or not $root->{cf_path};
    }

    $$_[0]->($vfs, $$_[1]) for @task;
    $vfs->after_new;
    $vfs;
  }
  sub after_new {
    my MY $self = shift;
    confess __PACKAGE__ . ": facade is empty!" unless $self->{cf_facade};
    weaken($self->{cf_facade});
  }
  sub error {
    my MY $self = shift;
    $self->{cf_facade}->error(@_);
  }
  #========================================
  sub find_file {
    (my VFS $vfs, my $filename) = @_;
    # XXX: 拡張子をどうしたい？
    my ($name) = $filename =~ m{^(\w+)}
      or croak "Can't extract part name from filename '$filename'";
    $vfs->{root}->lookup($vfs, $name);
  }
  sub list_items {
    (my VFS $vfs) = @_;
    $vfs->{root}->list_items($vfs);
  }
  sub resolve_path_from {
    (my VFS $vfs, my Folder $folder, my $fn) = @_;
    my $dirname = $folder->dirname
      or return undef;
    File::Spec->rel2abs($fn, $dirname)
  }

  #========================================
  sub find_part {
    my VFS $vfs = shift;
    $vfs->{root}->lookup($vfs, @_);
  }
  sub find_part_from {
    (my VFS $vfs, my $from) = splice @_, 0, 2;
    my Item $item = $from->lookup($vfs, @_);
    if ($item and $item->isa($vfs->Folder)) {
      (my Folder $folder = $item)->{Item}{''}
    } else {
      $item;
    }
  }

  # To limit call of refresh atmost 1, use this.
  sub reset_refresh_mark {
    (my VFS $vfs) = shift;
    $vfs->{cf_mark} = @_ ? shift : {};
  }

  sub YATT::Lite::VFS::Dir::dirobj { $_[0] }
  sub YATT::Lite::VFS::File::dirobj {
    (my vfs_file $file) = @_;
    $file->{cf_parent};
  }

  sub YATT::Lite::VFS::Dir::dirname {
    (my vfs_dir $dir) = @_;
    $dir->{cf_path};
  }
  sub YATT::Lite::VFS::File::dirname {
    (my vfs_file $file) = @_;
    if (my $parent = $file->{cf_parent}) {
      $parent->dirname;
    } elsif (my $path = $file->{cf_path}) {
      File::Basename::dirname(File::Spec->rel2abs($path));
    } else {
      undef;
    }
  }

  use Scalar::Util qw(refaddr);
  sub YATT::Lite::VFS::File::fake_filename {
    (my vfs_file $file) = @_;
    $file->{cf_path} // $file->{cf_name};
  }

  sub YATT::Lite::VFS::File::lookup {
    (my vfs_file $file, my VFS $vfs, my $name) = splice @_, 0, 3;
    unless (@_) {
      # ファイルの中には、深さ 1 の name しか無いはずだから。
      # mtime, refresh
      $file->refresh($vfs) unless $vfs->{cf_mark}{refaddr($file)}++;
      my Item $item = $file->{Item}{$name};
      return $item if $item;
    }
    # 深さが 2 以上の (name, @_) については、継承先から探す。
    $file->lookup_base($vfs, $name, @_);
  }
  sub YATT::Lite::VFS::Dir::lookup {
    (my vfs_dir $dir, my VFS $vfs, my $name) = splice @_, 0, 3;
    if (my Item $item = $dir->cached_in
	($dir->{Item} //= {}, $name, $vfs, $vfs->{cf_mark})) {
      if ((not ref $item or not UNIVERSAL::isa($item, Item))
	  and not $vfs->{cf_no_auto_create}) {
	$item = $dir->{Item}{$name} = $vfs->create
	  (data => $item, parent => $dir, name => $name);
      }
      return $item unless @_;
      $item = $item->lookup($vfs, @_);
      return $item if $item;
    }
    $dir->lookup_base($vfs, $name, @_);
  }
  sub YATT::Lite::VFS::Folder::lookup_base {
    (my Folder $item, my VFS $vfs, my $name) = splice @_, 0, 3;
    my @super = $item->list_base;
    foreach my $super (@super) {
      my $ans = $super->lookup($vfs, $name, @_) or next;
      return $ans;
    }
    undef;
  }
  sub YATT::Lite::VFS::Folder::list_base {
    my Folder $folder = shift; @{$folder->{cf_base} ||= []}
  }
  sub YATT::Lite::VFS::File::list_base {
    my vfs_file $file = shift;

    # $dir/$file.yatt inherits its own base decl,
    my @super = $file->YATT::Lite::VFS::Folder::list_base;

    # $dir ($dir's bases will be called in $dir->lookup),
    push @super, $file->{cf_parent} if $file->{cf_parent};

    # and then directory named $dir/$file.ytmpl (or "$dir/$file")
    push @super, $file->{cf_overlay} if $file->{cf_overlay};

    @super;
  }
  sub YATT::Lite::VFS::File::list_items {
    die "NIMPL";
  }
  sub YATT::Lite::VFS::Dir::list_items {
    (my vfs_dir $in, my VFS $vfs) = @_;
    return unless defined $in->{cf_path};
    my %dup;
    my @exts = map {
      if (defined $_ and not $dup{$_}++) {
	$_
      } else { () }
    } ($vfs->{cf_ext_public}, $vfs->{cf_ext_private});
    my %dup2;
    map {
      my $name = substr($_, length($in->{cf_path})+1);
      $name =~ s/\.\w+$//;
      $dup2{$name}++ ? () : $name;
    } glob("$in->{cf_path}/[a-z]*.{".join(",", @exts)."}");
  }
  #----------------------------------------
  sub YATT::Lite::VFS::Dir::load {
    (my vfs_dir $in, my VFS $vfs, my $partName) = @_;
    return unless defined $in->{cf_path};
    my $vfsname = "$in->{cf_path}/$partName";
    my @opt = (name => $partName, parent => $in);
    my ($kind, $path, @other) = do {
      if (my $fn = $vfs->find_ext($vfsname, $vfs->{cf_ext_public})) {
	(file => $fn, public => 1);
      } elsif ($fn = $vfs->find_ext($vfsname, $vfs->{cf_ext_private})) {
	# dir の場合、 new_tmplpkg では？
	my $kind = -d $fn ? 'dir' : 'file';
	($kind => $fn);
      } elsif (-d $vfsname) {
	return $vfs->{cf_facade}->create_neighbor($vfsname);
      } else {
	return undef;
      }
    };
    $vfs->create($kind, $path, @opt, @other);
  }
  sub find_ext {
    (my VFS $vfs, my ($vfsname, $spec)) = @_;
    foreach my $ext (!defined $spec ? () : ref $spec ? @$spec : $spec) {
      my $fn = "$vfsname.$ext";
      return $fn if -e $fn;
    }
  }
  #========================================
  # 実験用、ダミーのパーサー
  sub YATT::Lite::VFS::File::reset {
    (my File $file) = @_;
    undef $file->{partlist};
    undef $file->{Item};
    undef $file->{cf_string};
    undef $file->{cf_base};
    $file->{dependency} = +{};
  }
  sub YATT::Lite::VFS::Dir::refresh {}
  sub YATT::Lite::VFS::File::refresh {
    (my vfs_file $file, my VFS $vfs) = @_;
    return unless $$file{cf_path} || $$file{cf_string};
    # XXX: mtime!
    my @part = do {
      local $/; split /^!\s*(\w+)\s+(\S+)[^\n]*?\n/m, do {
	if ($$file{cf_path}) {
	  open my $fh, '<', $$file{cf_path}
	    or die "Can't open '$$file{cf_path}': $!";
	  scalar <$fh>
	} else {
	  $$file{cf_string};
	}
      };
    };
    $file->add_widget('', shift @part);
    while (my ($kind, $name, $part) = splice @part, 0, 3) {
      if (defined $kind and my $sub = $file->can("declare_$kind")) {
	$sub->($file, $name, $vfs, $part);
      } else {
	$file->can("add_$kind")->($file, $name, $part);
      }
    }
  }

  sub YATT::Lite::VFS::File::add_dependency {
    (my File $file, my $wpath, my File $other) = @_;
    Scalar::Util::weaken($file->{dependency}{$wpath} = $other);
  }
  sub YATT::Lite::VFS::File::list_dependency {
    (my File $file, my $detail) = @_;
    defined (my $deps = $file->{dependency})
      or return;
    if ($detail) {
      wantarray ? map([$_ => $deps->{$_}], keys %$deps) : $deps;
    } else {
      values %$deps;
    }
  }
  sub refresh_deps_for {
    (my MY $self, my File $file) = @_;
    print STDERR "refresh deps for: ", $file->{cf_path}, "\n" if DEBUG_REBUILD;
    foreach my $dep ($file->list_dependency) {
      unless ($self->{cf_mark}{refaddr($dep)}++) {
	print STDERR " refreshing: ", $dep->{cf_path}, "\n" if DEBUG_REBUILD;
	$dep->refresh($self);
      }
    }
  }

  #========================================
  sub add_to {
    (my VFS $vfs, my ($path, $data)) = @_;
    my @path = ref $path ? @$path : $path;
    my $lastName = pop @path;
    my Folder $folder = $vfs->{root};
    while (@path) {
      my $name = shift @path;
      $folder = $folder->{Item}{$name} ||= $vfs->create
	(data => {}, name => $name, parent => $folder);
    }
    # XXX: path を足すと、memory 動作の時に困る
    $folder->{Item}{$lastName} = $vfs->create
	(data => $data, name => $lastName, parent => $folder);
  }
  #========================================
  sub root {(my VFS $vfs) = @_; $vfs->{root}}

  # special hook for root creation.
  sub root_create {
    (my VFS $vfs, my ($kind, $primary, %rest)) = @_;
    $rest{entns} //= $vfs->{cf_entns};
    $vfs->{root} = $vfs->create($kind, $primary, %rest);
  }
  sub create {
    (my VFS $vfs, my ($kind, $primary, %rest)) = @_;
    # XXX: $vfs は className の時も有る。
    if (my $sub = $vfs->can("create_$kind")) {
      $vfs->fixup_created(\@_, $sub->($vfs, $primary, %rest));
    } else {
      $vfs->{cf_cache}{$primary} ||= do {
	# XXX: Really??
	$rest{entns} //= $vfs->{cf_entns};
	$vfs->fixup_created
	  (\@_, $vfs->can("vfs_$kind")->()->new(%rest, path => $primary));
      };
    }
  }
  sub fixup_created {
    (my VFS $vfs, my $info, my Folder $folder) = @_;
    printf STDERR "# VFS::create(%s) => %s(0x%x)\n"
      , terse_dump(@{$info}[1..$#$info])
      , ref $folder, ($folder+0) if DEBUG_VFS;
    # create の直後、 after_create より前に、mark を打つ。そうしないと、 delegate で困る。
    if (ref $vfs) {
      $vfs->{n_creates}++;
      $vfs->{cf_mark}{refaddr($folder)}++;
    }

    if (my $path = $folder->{cf_path} and not defined $folder->{cf_name}) {
      $path =~ s/\.\w+$//;
      $path =~ s!.*/!!;
      $folder->{cf_name} = $path;
    }

    if (my Folder $parent = $folder->{cf_parent}) {
      if (defined $parent->{cf_entns}) {
	$folder->{cf_entns} = join '::'
	  , $parent->{cf_entns}, $folder->{cf_name};
	# XXX: base 指定だけで済むべきだが、Factory を呼んでないので出来ないorz...
	YATT::Lite::MFields->add_isa_to
	    ($folder->{cf_entns}, $parent->{cf_entns});
	$vfs->{pkg2folder}{$folder->{cf_entns}} = $folder;
      }
    }
    $folder->after_create($vfs);
    $folder;
  }
  sub create_data {
    (my VFS $vfs, my ($primary)) = splice @_, 0, 2;
    if (ref $primary) {
      # 直接 Folder slot にデータを。
      my vfs_dir $item = $vfs->vfs_dir->new(@_);
      $item->{Item} = $primary;
      $item;
    } else {
      $vfs->vfs_file->new(public => 1, @_, string => $primary);
    }
  }
  sub YATT::Lite::VFS::Folder::vivify_base_descs {
    (my Folder $folder, my VFS $vfs) = @_;
    foreach my Folder $desc (@{$folder->{cf_base}}) {
      if (ref $desc eq 'ARRAY') {
	# XXX: Dirty workaround.
	if ($desc->[0] eq 'dir') {
	  # To create YATT::Lite with .htyattconfig.xhf, Factory should be involved.
	  $desc = $vfs->{cf_facade}->create_neighbor($desc->[1]);
	} else {
	  $desc = $vfs->create(@$desc);
	}
      }
      $desc = $vfs->create(@$desc) if ref $desc eq 'ARRAY';
      # parent がある == parent から指されている。なので、 weaken する必要が有る。
      weaken($desc) if $desc->{cf_parent};
    }
  }
  sub YATT::Lite::VFS::Dir::after_create {
    (my vfs_dir $dir, my VFS $vfs) = @_;
    $dir->YATT::Lite::VFS::Folder::vivify_base_descs($vfs);
    # $dir->refresh($vfs);
    $dir;
  }
  # file 系は create 時に必ず refresh. refresh は decl のみ parse.
  sub YATT::Lite::VFS::File::after_create {
    (my vfs_file $file, my VFS $vfs) = @_;
    $file->refresh_overlay($vfs);
    $file->refresh($vfs);
  }
  sub YATT::Lite::VFS::File::refresh_overlay {
    (my vfs_file $file, my VFS $vfs) = @_;
    return if $file->{cf_overlay};
    return unless $file->{cf_path};
    my $rootname = rootname($file->{cf_path});
    my @found = grep {-d $$_[-1]} ([1, $rootname]
				   , [0, "$rootname.$vfs->{cf_ext_private}"]);
    if (@found > 1) {
      $vfs->error(q|Don't use %1$s and %1$s.%2$s at once|
		  , $rootname, $vfs->{cf_ext_private});
    } elsif (not @found) {
      return;
    }
    $file->{cf_overlay} = do {
      my ($public, $path) = @{$found[0]};
      if ($public) {
	$vfs->{cf_facade}->create_neighbor($path);
      } else {
	$vfs->create
	  (dir => $path, parent => $file->{cf_parent});
      }
    };
  }
  #----------------------------------------
  sub YATT::Lite::VFS::File::declare_base {
    (my vfs_file $file, my ($spec), my VFS $vfs, my $part) = @_;
    my ($kind, $path) = split /=/, $spec, 2;
    # XXX: 物理 path だと困るよね？ findINC 的な処理が欲しい
    # XXX: 帰属ディレクトリより強くするため、先頭に。でも、不満。
    unshift @{$file->{cf_base}}, $vfs->create($kind => $path);
    weaken($file->{cf_base}[0]);
    $file->{Item}{''} .= $part;
  }
  sub YATT::Lite::VFS::File::add_widget {
    (my vfs_file $file, my ($name, $part)) = @_;
    push @{$file->{partlist}}, $file->{Item}{$name} = $part;
  }

  sub linsert {
    my @ls = @{shift()};
    splice @ls, shift, 0, @_;
    wantarray ? @ls : \@ls;
  }
}

use YATT::Lite::Breakpoint;
YATT::Lite::Breakpoint::break_load_vfs();

1;
