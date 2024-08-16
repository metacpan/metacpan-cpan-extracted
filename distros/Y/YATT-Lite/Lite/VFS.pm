package YATT::Lite::VFS;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';
use Exporter qw(import);
use Scalar::Util qw(weaken);
use Carp;
use constant DEBUG_VFS => $ENV{DEBUG_YATT_VFS};
use constant DEBUG_REBUILD => $ENV{DEBUG_YATT_REBUILD};
use constant DEBUG_MRO => $ENV{DEBUG_YATT_MRO};
use constant DEBUG_LOOKUP => $ENV{DEBUG_YATT_VFS_LOOKUP};

require File::Spec;
require File::Basename;

#========================================
# VFS 層. vfs_file (Template) のダミー実装を含む。
#========================================
{
  sub MY () {__PACKAGE__}
  use YATT::Lite::Types
    ([Item => -fields => [qw(cf_name cf_public cf_type)]
      , -constants => [[can_generate_code => 0], [item_category => '']]
      , [Folder => -fields => [qw(Item cf_path cf_parent cf_base
				  cf_entns)]
	 , -eval => q{use YATT::Lite::Util qw(cached_in);}
	 , [File => -fields => [qw(partlist cf_string cf_overlay cf_imported
                                   cf_nlines
				   dependency
				)]
	    , -alias => 'vfs_file']
	 , [Dir  => -fields => [qw(cf_encoding)]
	    , -alias => 'vfs_dir']]]);

  sub YATT::Lite::VFS::Item::after_create {}
  sub YATT::Lite::VFS::Item::item_key {
    (my Item $item) = @_;
    $item->{cf_name};
  }
  sub YATT::Lite::VFS::Folder::configure_parent {
    my MY $self = shift;
    # 循環参照対策
    # XXX: Item に移すべきかもしれない。そうすれば、 Widget->parent が引ける。
    weaken($self->{cf_parent} = shift);
  }
  sub YATT::Lite::VFS::Folder::get_linear_isa_of_entns {
    (my Folder $folder) = @_;
    my $isa = mro::get_linear_isa($folder->{cf_entns});
    wantarray ? @$isa : $isa;
  }

  package YATT::Lite::VFS; BEGIN {$INC{"YATT/Lite/VFS.pm"} = 1}
  sub VFS () {__PACKAGE__}
  use parent qw(YATT::Lite::Object);
  use YATT::Lite::MFields qw/cf_ext_private cf_ext_public cf_cache cf_no_auto_create
		cf_facade cf_base
		cf_import
		cf_entns
		cf_always_refresh_deps
		cf_no_mro_c3
		on_memory
		root extdict
		cf_mark
		n_creates
		cf_entns2vfs_item/;
  use YATT::Lite::Util qw(lexpand rootname extname);
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

    $self->refresh_import if $self->{cf_import};
  }
  sub error {
    my MY $self = shift;
    $self->{cf_facade}->error(@_);
  }
  #========================================

  sub find_neighbor_file {
    (my VFS $vfs, my ($path)) = @_;
    my VFS $other_vfs = $vfs->{cf_facade}->find_neighbor_vfs
      (File::Basename::dirname($path));
    $other_vfs->find_file(File::Basename::basename($path));
  }
  sub find_neighbor_type {
    (my VFS $vfs, my ($kind, $path)) = @_;
    $kind //= -d $path ? 'dir' : 'file';
    if ($kind eq 'file') {
      $vfs->find_neighbor_file($path);
    } elsif ($kind eq 'dir') {
      $vfs->{cf_facade}->find_neighbor($path);
    } else {
      croak "Unknown vfs type=$kind path=$path";
    }
  }

  sub refresh_import {
    (my VFS $vfs) = @_;
    my Folder $root = $vfs->{root};

    my @files = grep {
      -f $_ && defined $vfs->{extdict}{extname($_)}
    } map {
      my $fn = "$root->{cf_path}/$_";
      1 while $fn =~ s,/[^/\.]+/\.\./,/,g;
      glob($fn);
    } lexpand($vfs->{cf_import});

    if (DEBUG_VFS) {
      printf STDERR "# vfs-import to %s from %s (actually: %s)\n"
	, $root->{cf_path}, sorted_dump($vfs->{cf_import}), sorted_dump(\@files);
    }

    foreach my $fn (@files) {
      my Folder $file = $vfs->find_neighbor_file($fn);

      # Skip if it exists.
      next if $root->lookup_1($vfs, $file->{cf_name});

      # 
      $root->{Item}{$file->{cf_name}}
	= $vfs->create(file => $file->{cf_path}, parent => $root
		       , imported => 1
		     );
    }
  }

  #========================================
  sub find_file {
    (my VFS $vfs, my $filename) = @_;
    # XXX: 拡張子をどうしたい？
    my ($name) = $filename =~ m{^(\w+)}
      or croak "Can't extract part name from filename '$filename'";
    my $nameSpec = length($name) == length($filename)
      ? $name : [$name => $filename];
    $vfs->{root}->lookup($vfs, $nameSpec);
  }
  sub list_all_names {
    (my VFS $vfs) = @_;
    $vfs->{root}->list_all_names($vfs);
  }
  sub list_items {
    (my VFS $vfs) = @_;
    $vfs->{root}->list_items($vfs);
  }
  sub list_base {
    (my VFS $vfs) = @_;
    map {
      my Folder $folder = $_; # Actually, only folders can be a 'base'.
      $folder->{cf_path};
    } $vfs->list_internal_base_folders;
  }

  # XXX: Incontrast to list_items, list_internal_base_items returns internal VFS items
  sub list_internal_base_folders {
    (my VFS $vfs) = @_;
    $vfs->{root}->list_base($vfs);
  }
  sub resolve_path_from {
    (my VFS $vfs, my Folder $from, my $fn) = @_;
    my Folder $folder = $from->dirobj;
    my $dirname = $folder->dirname
      or return undef;
    my $abs = do {
      if ($fn =~ /^@/) {
        $vfs->{cf_facade}->app_path_expand($fn);
      } elsif ($fn =~ s!^((?:\.\./)+)!!) {
	# leading upward relpath is treated specially.
	my $up = length($1) / 3;
	my @dirs = File::Spec->splitdir($dirname);
	File::Spec->catfile(@dirs[0.. $#dirs - $up], $fn);
      } else {
	File::Spec->rel2abs($fn, $dirname);
      }
    };
    $abs;
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

  sub find_part_from_entns {
    (my VFS $vfs, my $entns) = splice @_, 0, 2;
    my Folder $folder = $vfs->{cf_entns2vfs_item}{$entns}
      or croak "Unknown entns $entns!";
    $vfs->find_part_from($folder, @_);
  }

  # To limit call of refresh atmost 1, use this.
  sub reset_refresh_mark {
    (my VFS $vfs) = shift;
    $vfs->{cf_mark} = @_ ? shift : {};
  }

  sub re_ext {
    (my VFS $vfs) = @_;
    my $ext = join("|", grep {defined}
                   $vfs->{cf_ext_public}, $vfs->{cf_ext_private});
    qr{$ext};
  }

  sub YATT::Lite::VFS::Folder::lookup {
    print STDERR "# VFS: root->lookup(", sorted_dump(@_[2..$#_]), ")\n"
      if DEBUG_LOOKUP;
    $_[0]->lookup_1(@_[1..$#_])
      // $_[0]->lookup_base(@_[1..$#_])
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

  sub YATT::Lite::VFS::File::lookup_1 {
    (my vfs_file $file, my VFS $vfs, my $nameSpec) = splice @_, 0, 3;
    print STDERR "# VFS:   $file->lookup_1("
      , sorted_dump($nameSpec, @_), ") in (", sorted_dump($file->{cf_path}), ")\n"
      if DEBUG_LOOKUP;
    unless (@_) {
      # ファイルの中には、深さ 1 の name しか無いはずだから。
      # mtime, refresh
      $file->refresh($vfs) unless $vfs->{cf_mark}{refaddr($file)}++;
      my ($name) = lexpand($nameSpec);
      my Item $item = $file->{Item}{$name};
      return $item if $item;
    }
    undef;
  }
  sub YATT::Lite::VFS::Dir::lookup_1 {
    (my vfs_dir $dir, my VFS $vfs, my $nameSpec) = splice @_, 0, 3;
    print STDERR "# VFS:   $dir->lookup_1("
      , sorted_dump($nameSpec, @_), ") in (", sorted_dump($dir->{cf_path}), ")\n"
      if DEBUG_LOOKUP;
    if (my Item $item = $dir->cached_in
	($dir->{Item} //= {}, $nameSpec, $vfs, $vfs->{cf_mark})) {
      if ((not ref $item or not UNIVERSAL::isa($item, Item))
	  and not $vfs->{cf_no_auto_create}) {
	# Special case (mostly for test)
	# data vfs can contain vfs spec (string, array, hash).
        my ($name) = lexpand($nameSpec);
	$item = $dir->{Item}{$name} = $vfs->create
	  (data => $item, parent => $dir, name => $name);
      }
      return $item unless @_;
      if (not $vfs->{cf_no_mro_c3} and $dir->{cf_entns}) {
	$item = $item->lookup_1($vfs, @_);
      } else {
	$item = $item->lookup($vfs, @_);
      }
      return $item if $item;
    }
    undef;
  }
  sub YATT::Lite::VFS::Folder::lookup_base {
    (my Folder $item, my VFS $vfs, my $nameSpec) = splice @_, 0, 3;
    print STDERR "# VFS:      $item->lookup_base("
      , sorted_dump($item->{cf_path}) ,")(", sorted_dump($nameSpec, @_), ")\n"
      if DEBUG_LOOKUP;

    if (not $vfs->{cf_no_mro_c3} and $item->{cf_entns}) {
      (undef, my @super_ns) = @{mro::get_linear_isa($item->{cf_entns})};
      my @super = map {
        my $o = $vfs->{cf_entns2vfs_item}{$_}; $o ? $o : ()
      } @super_ns;
      foreach my $super (@super) {
	my $ans = $super->lookup_1($vfs, $nameSpec, @_) or next;
	return $ans;
      }
    } else {
      my @super = $item->list_base;
      foreach my $super (@super) {
	my $ans = $super->lookup($vfs, $nameSpec, @_) or next;
	return $ans;
      }
    }
    undef;
  }
  sub YATT::Lite::VFS::Folder::list_base {
    my Folder $folder = shift; @{$folder->{cf_base} ||= []}
  }
  sub YATT::Lite::VFS::File::list_base {
    my vfs_file $file = shift;

    # $dir/$file.yatt inherits its own base decl,
    my (@local, @otherdir);
    foreach my Folder $super ($file->YATT::Lite::VFS::Folder::list_base) {
      if ($super->{cf_parent} and $file->{cf_parent} == $super->{cf_parent}) {
	push @local, $super;
      } else {
	push @otherdir, $super;
      }
    }

    push @local, grep {$_} $file->{cf_parent}, $file->{cf_overlay};

    if ($file->{cf_entns} and mro::get_mro($file->{cf_entns}) eq 'c3') {
      print STDERR "use c3 for $file->{cf_entns}"
	, "\n ".sorted_dump([local => map {
	  my Folder $f = $_;
	  mro::get_linear_isa($f->{cf_entns})
	} @local])
	, "\n ".sorted_dump([other => map {
	  my Folder $f = $_;
	  mro::get_linear_isa($f->{cf_entns})
	} @otherdir])
	, "\n" if DEBUG_MRO;
      return (@local, @otherdir);
    } else {
      print STDERR "use dfs for $file->{cf_entns}\n" if DEBUG_MRO;
      return (@otherdir, @local);
    }
  }
  sub YATT::Lite::VFS::File::list_items {
    croak "NIMPL";
  }
  sub YATT::Lite::VFS::Dir::list_all_names {
    (my vfs_dir $in, my VFS $vfs) = @_;
    croak "BUG: vfs is undef!" unless defined $vfs;
    return unless defined $in->{cf_path};
    my (@names, %seen);
    {
      use 5.012;
      my $extRe = $vfs->re_ext;
      local $_;
      opendir my $dh, "$in->{cf_path}/";
      while (readdir $dh) {
        /^(\w+)(?:\.$extRe)?\z/
          or next;
        next if $seen{$1}++;
        push @names, $1;
      }
      closedir $dh;
    }
    @names;
  }
  sub YATT::Lite::VFS::Dir::list_items {
    (my vfs_dir $in, my VFS $vfs) = @_;
    croak "BUG: vfs is undef!" unless defined $vfs;
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
    (my vfs_dir $in, my VFS $vfs, my $nameSpec) = @_;
    return unless defined $in->{cf_path};
    print STDERR "# VFS:   Dir::load(", sorted_dump($nameSpec), ") in $in\n"
      if DEBUG_LOOKUP;
    my ($partName, $realFile) = lexpand($nameSpec);

    # When $partName contains NUL like 'do\0action',
    # we should avoid filesystem testings.
    if ($partName =~ /\0/) {
      print STDERR "# VFS:   -> avoid fs lookup for \\0 in $in\n"
        if DEBUG_LOOKUP;
      return;
    }

    $realFile ||= $partName;

    my $vfsname = "$in->{cf_path}/$realFile";
    my @opt = (name => $partName, parent => $in);
    my ($kind, $path, @other) = do {
      if (ref $nameSpec) {
        my $ext = extname($vfsname);
        (file => $vfsname
         , ($ext eq $vfs->{cf_ext_public}
            ? (public => 1) : ()));
      } elsif (my $fn = $vfs->find_ext($vfsname, $vfs->{cf_ext_public})) {
	(file => $fn, public => 1);
      } elsif ($fn = $vfs->find_ext($vfsname, $vfs->{cf_ext_private})) {
	# dir の場合、 new_tmplpkg では？
	my $kind = -d $fn ? 'dir' : 'file';
	($kind => $fn);
      } elsif (-d $vfsname) {
	return $vfs->{cf_facade}->find_neighbor($vfsname);
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
    # undef $file->{cf_string};
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
    my Item $item = $vfs->create
      (data => $data, name => $lastName, parent => $folder);
    $folder->{Item}{$item->item_key} = $item;
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
      $vfs->fixup_created(\@_, $sub->($vfs, $primary, %rest, type => $kind));
    } else {
      $vfs->{cf_cache}{$primary} ||= do {
	# XXX: Really??
	$rest{entns} //= $vfs->{cf_entns};
	$vfs->fixup_created
	  (\@_, $vfs->can("vfs_$kind")->()->new(%rest, path => $primary
						, type => $kind
					      ));
      };
    }
  }
  sub sorted_dump {
    require Data::Dumper;
    join ", ", map {
      Data::Dumper->new([$_])->Maxdepth(2)->Terse(1)->Indent(0)
        ->Sortkeys(1)->Dump;
    } @_;
  }
  sub fixup_created {
    (my VFS $vfs, my $info, my Folder $folder) = @_;
    if (DEBUG_VFS) {
      printf STDERR "# VFS::create(%s) => %s(0x%x)\n"
        , sorted_dump(@{$info}[1..$#$info])
        , ref $folder, ($folder+0);
    } elsif (DEBUG_LOOKUP) {
      print STDERR "# VFS: created: $folder (path="
        , sorted_dump($folder->{cf_path}), ")\n";
    } else {
      # XXX: This is required for perl 5.18 and before.
    }
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
      }
    }
    if ($folder->{cf_entns}) {
      if (not $vfs->{cf_no_mro_c3}) {
	mro::set_mro($folder->{cf_entns}, 'c3');
      }
      if (defined (my Folder $old = $vfs->{cf_entns2vfs_item}{$folder->{cf_entns}})) {
	if ($old != $folder) {
	  croak "EntNS confliction for $folder->{cf_entns}! old=$old->{cf_path} vs new=$folder->{cf_path}";
	}
      }
      $vfs->{cf_entns2vfs_item}{$folder->{cf_entns}} = $folder;
    }
    $folder->after_create($vfs);
    $folder;
  }

  # XXX: <=> find_part_from_entns
  sub find_template_from_package {
    (my MY $self, my $pkg) = @_;
    $self->{cf_entns2vfs_item}{$pkg};
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

  #
  # This converts all descriptors in Folder->base into real item objects.
  #
  sub YATT::Lite::VFS::Folder::vivify_base_descs {
    (my Folder $folder, my VFS $vfs) = @_;
    foreach my Folder $desc (@{$folder->{cf_base}}) {
      if (ref $desc eq 'ARRAY') {
	#
	# This $desc structure *may* come from Factory->_list_base_spec_in
	#
	if ($desc->[0] eq 'dir') {
	  # To create YATT::Lite with .htyattconfig.xhf, Factory should be involved.
	  $desc = $vfs->{cf_facade}->find_neighbor($desc->[1]);
	} else {
	  $desc = $vfs->create(@$desc);
	}
      }
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
	$vfs->{cf_facade}->find_neighbor($path);
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
