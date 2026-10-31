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
require File::Glob;

#========================================
# VFS 層. vfs_file (Template) のダミー実装を含む。
#========================================
{
  sub MY () {__PACKAGE__}
  use YATT::Lite::Types
    ([Item => -fields => [qw(name public type)]
      , -constants => [[can_generate_code => 0], [item_category => '']]
      , [Folder => -fields => [qw(_Item path parent base
                                  _argmacro_dict
				  entns)]
	 , -eval => q{use YATT::Lite::Util qw(cached_in);}
	 , [File => -fields => [qw(_partlist _boundarylist
                                   string overlay imported
                                   nlines
				   _dependency
				   _dependents
				)]
	    , -alias => 'vfs_file']
	 , [Dir  => -fields => [qw(encoding page_prefix)]
	    , -alias => 'vfs_dir']]]);

  sub YATT::Lite::VFS::Item::after_create {}
  # item_key の符号化は class メソッド item_key_for($name) に集約する。
  # Action/Entity などの subclass (YATT::Lite::Core) が override する。GH-256
  sub YATT::Lite::VFS::Item::item_key_for {
    (my $class, my $name) = @_;
    $name;
  }
  sub YATT::Lite::VFS::Item::item_key {
    (my Item $item) = @_;
    $item->item_key_for($item->{name});
  }
  # 通常の Item は自分自身を返す。<!yatt:import> の alias Part
  # (YATT::Lite::Core::Import) がこれを override する。GH-256
  sub YATT::Lite::VFS::Item::resolve_alias { $_[0] }
  sub YATT::Lite::VFS::Folder::configure_parent {
    my MY $self = shift;
    # 循環参照対策
    # XXX: Item に移すべきかもしれない。そうすれば、 Widget->parent が引ける。
    weaken($self->{parent} = shift);
  }
  sub YATT::Lite::VFS::Folder::get_linear_isa_of_entns {
    (my Folder $folder) = @_;
    my $isa = mro::get_linear_isa($folder->{entns});
    wantarray ? @$isa : $isa;
  }
  sub YATT::Lite::VFS::Folder::list_parts {
    (my Folder $folder) = @_;
    return unless $folder->{_Item};
    values %{$folder->{_Item}};
  }
  sub YATT::Lite::VFS::File::page_name {
    (my File $file) = @_;
    my Dir $parent = $file->{parent};
    return undef unless defined $parent->{page_prefix};
    $parent->{page_prefix} . $file->{name};
  }

  package YATT::Lite::VFS; BEGIN {$INC{"YATT/Lite/VFS.pm"} = 1}
  sub VFS () {__PACKAGE__}
  use parent qw(YATT::Lite::Object);
  use YATT::Lite::MFields qw/ext_private ext_public cache no_auto_create
		facade base
		import
		entns
		always_refresh_deps
		no_mro_c3
		_on_memory
		_root _extdict
		mark
		_n_creates
		entns2vfs_item/;
  use YATT::Lite::Util qw(lexpand rootname extname);
  sub default_ext_public {'yatt'}
  sub default_ext_private {'ytmpl'}
  sub new {
    my ($class, $spec) = splice @_, 0, 2;
    (my VFS $vfs, my @task) = $class->SUPER::just_new(@_);
    foreach my $desc ([1, ($vfs->{ext_public}
				  ||= $vfs->default_ext_public)]
		      , [0, ($vfs->{ext_private}
			     ||= $vfs->default_ext_private)]) {
      my ($value, @ext) = @$desc;
      $vfs->{_extdict}{$_} = $value for @ext;
    }

    if ($spec) {
      my Folder $root = $vfs->root_create
	(linsert($spec, 2, $vfs->cf_delegate(qw(entns))));
      # Mark [data => ..] vfs as on_memory
      $vfs->{_on_memory} = 1 if $spec->[0] eq 'data' or not $root->{path};
    }

    $$_[0]->($vfs, $$_[1]) for @task;
    $vfs->after_new;
    $vfs;
  }
  sub after_new {
    my MY $self = shift;
    confess __PACKAGE__ . ": facade is empty!" unless $self->{facade};
    weaken($self->{facade});

    $self->refresh_import if $self->{import};
  }
  sub error {
    my MY $self = shift;
    $self->{facade}->error(@_);
  }
  #========================================

  sub find_neighbor_file {
    (my VFS $vfs, my ($path)) = @_;
    my VFS $other_vfs = $vfs->{facade}->find_neighbor_vfs
      (File::Basename::dirname($path));
    $other_vfs->find_file(File::Basename::basename($path));
  }
  sub find_neighbor_type {
    (my VFS $vfs, my ($kind, $path)) = @_;
    $kind //= -d $path ? 'dir' : 'file';
    if ($kind eq 'file') {
      $vfs->find_neighbor_file($path);
    } elsif ($kind eq 'dir') {
      $vfs->{facade}->find_neighbor($path);
    } else {
      croak "Unknown vfs type=$kind path=$path";
    }
  }

  sub refresh_import {
    (my VFS $vfs) = @_;
    my Folder $root = $vfs->{_root};

    my @files = grep {
      -f $_ && defined $vfs->{_extdict}{extname($_)}
    } map {
      my $fn = "$root->{path}/$_";
      1 while $fn =~ s,/[^/\.]+/\.\./,/,g;
      glob($fn);
    } lexpand($vfs->{import});

    if (DEBUG_VFS) {
      printf STDERR "# vfs-import to %s from %s (actually: %s)\n"
	, $root->{path}, sorted_dump($vfs->{import}), sorted_dump(\@files);
    }

    foreach my $fn (@files) {
      my Folder $file = $vfs->find_neighbor_file($fn);

      # Skip if it exists.
      next if $root->lookup_1($vfs, $file->{name});

      # 
      $root->{_Item}{$file->{name}}
	= $vfs->create(file => $file->{path}, parent => $root
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
    $vfs->{_root}->lookup($vfs, $nameSpec);
  }
  sub list_all_names {
    (my VFS $vfs) = @_;
    $vfs->{_root}->list_all_names($vfs);
  }
  sub list_items {
    (my VFS $vfs) = @_;
    $vfs->{_root}->list_items($vfs);
  }
  sub list_base {
    (my VFS $vfs) = @_;
    map {
      my Folder $folder = $_; # Actually, only folders can be a 'base'.
      $folder->{path};
    } $vfs->list_internal_base_folders;
  }

  # XXX: Incontrast to list_items, list_internal_base_items returns internal VFS items
  sub list_internal_base_folders {
    (my VFS $vfs) = @_;
    $vfs->{_root}->list_base($vfs);
  }
  sub resolve_path_from {
    (my VFS $vfs, my Folder $from, my $fn) = @_;
    # $fn usually comes from a decoded template string while paths are
    # octets in YATT. Joining a utf8-flagged string with an octet dirname
    # makes perl hand the utf8-encoded form to the filesystem. GH-275
    utf8::encode($fn) if utf8::is_utf8($fn);
    my Folder $folder = $from->dirobj;
    my $dirname = $folder->dirname
      or return undef;
    my $abs = do {
      if ($fn =~ /^@/) {
        $vfs->{facade}->app_path_expand($fn);
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
    $vfs->{_root}->lookup($vfs, @_);
  }
  sub find_part_from {
    (my VFS $vfs, my $from) = splice @_, 0, 2;
    my Item $item = $from->lookup($vfs, @_);
    if ($item and $item->isa($vfs->Folder)) {
      (my Folder $folder = $item)->{_Item}{''}
    } else {
      $item;
    }
  }

  sub find_part_from_entns {
    (my VFS $vfs, my $entns) = splice @_, 0, 2;
    my Folder $folder = $vfs->{entns2vfs_item}{$entns}
      or croak "Unknown entns $entns!";
    $vfs->find_part_from($folder, @_);
  }

  # kind 指定の part 検索 dispatcher。kind ごとの検索ロジック
  # (item-key の符号化を含む) は _find_kind_part__$kind として
  # subclass (YATT::Lite::Core) が定義する。GH-256
  sub find_kind_part_from {
    (my VFS $vfs, my ($from, $kind, $name)) = @_;
    my $sub = $vfs->can("_find_kind_part__$kind")
      or croak "Unknown part kind: $kind";
    $sub->($vfs, $from, $name);
  }

  # To limit call of refresh atmost 1, use this.
  sub reset_refresh_mark {
    (my VFS $vfs) = shift;
    $vfs->{mark} = @_ ? shift : {};
  }

  sub re_ext {
    (my VFS $vfs) = @_;
    my $ext = join("|", grep {defined}
                   $vfs->{ext_public}, $vfs->{ext_private});
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
    $file->{parent};
  }

  sub YATT::Lite::VFS::Dir::dirname {
    (my vfs_dir $dir) = @_;
    $dir->{path};
  }
  sub YATT::Lite::VFS::File::dirname {
    (my vfs_file $file) = @_;
    if (my $parent = $file->{parent}) {
      $parent->dirname;
    } elsif (my $path = $file->{path}) {
      File::Basename::dirname(File::Spec->rel2abs($path));
    } else {
      undef;
    }
  }

  use Scalar::Util qw(refaddr);
  sub YATT::Lite::VFS::File::fake_filename {
    (my vfs_file $file) = @_;
    $file->{path} // $file->{name};
  }

  sub YATT::Lite::VFS::File::lookup_1 {
    (my vfs_file $file, my VFS $vfs, my $nameSpec) = splice @_, 0, 3;
    print STDERR "# VFS:   $file->lookup_1("
      , sorted_dump($nameSpec, @_), ") in (", sorted_dump($file->{path}), ")\n"
      if DEBUG_LOOKUP;
    unless (@_) {
      # ファイルの中には、深さ 1 の name しか無いはずだから。
      # mtime, refresh
      $file->refresh($vfs) unless $vfs->{mark}{refaddr($file)}++;
      my ($name) = lexpand($nameSpec);
      my Item $item = $file->{_Item}{$name};
      # import alias はここでソース側 Part へ解決する。GH-256
      # (data vfs では _Item に生の文字列等も入りうるので Item の時だけ)
      return $item->resolve_alias($vfs)
        if $item and ref $item and UNIVERSAL::isa($item, Item);
      return $item if $item;
    }
    undef;
  }
  sub YATT::Lite::VFS::Dir::lookup_1 {
    (my vfs_dir $dir, my VFS $vfs, my $nameSpec) = splice @_, 0, 3;
    print STDERR "# VFS:   $dir->lookup_1("
      , sorted_dump($nameSpec, @_), ") in (", sorted_dump($dir->{path}), ")\n"
      if DEBUG_LOOKUP;
    if (my Item $item = $dir->cached_in
	($dir->{_Item} //= {}, $nameSpec, $vfs, $vfs->{mark})) {
      if ((not ref $item or not UNIVERSAL::isa($item, Item))
	  and not $vfs->{no_auto_create}) {
	# Special case (mostly for test)
	# data vfs can contain vfs spec (string, array, hash).
        my ($name) = lexpand($nameSpec);
	$item = $dir->{_Item}{$name} = $vfs->create
	  (data => $item, parent => $dir, name => $name);
      }
      return $item unless @_;
      if (not $vfs->{no_mro_c3} and $dir->{entns}) {
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
      , sorted_dump($item->{path}) ,")(", sorted_dump($nameSpec, @_), ")\n"
      if DEBUG_LOOKUP;

    if (not $vfs->{no_mro_c3} and $item->{entns}) {
      (undef, my @super_ns) = @{mro::get_linear_isa($item->{entns})};
      my @super = map {
        my $o = $vfs->{entns2vfs_item}{$_}; $o ? $o : ()
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
    my Folder $folder = shift; @{$folder->{base} ||= []}
  }
  sub YATT::Lite::VFS::File::list_base {
    my vfs_file $file = shift;

    # $dir/$file.yatt inherits its own base decl,
    my (@local, @otherdir);
    foreach my Folder $super ($file->YATT::Lite::VFS::Folder::list_base) {
      if ($super->{parent} and $file->{parent} == $super->{parent}) {
	push @local, $super;
      } else {
	push @otherdir, $super;
      }
    }

    push @local, grep {$_} $file->{parent}, $file->{overlay};

    if ($file->{entns} and mro::get_mro($file->{entns}) eq 'c3') {
      print STDERR "use c3 for $file->{entns}"
	, "\n ".sorted_dump([local => map {
	  my Folder $f = $_;
	  mro::get_linear_isa($f->{entns})
	} @local])
	, "\n ".sorted_dump([other => map {
	  my Folder $f = $_;
	  mro::get_linear_isa($f->{entns})
	} @otherdir])
	, "\n" if DEBUG_MRO;
      return (@local, @otherdir);
    } else {
      print STDERR "use dfs for $file->{entns}\n" if DEBUG_MRO;
      return (@otherdir, @local);
    }
  }
  sub YATT::Lite::VFS::File::list_items {
    croak "NIMPL";
  }
  sub YATT::Lite::VFS::Dir::list_all_names {
    (my vfs_dir $in, my VFS $vfs) = @_;
    croak "BUG: vfs is undef!" unless defined $vfs;
    return unless defined $in->{path};
    my (@names, %seen);
    {
      use 5.012;
      my $extRe = $vfs->re_ext;
      local $_;
      opendir my $dh, "$in->{path}/";
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
    return unless defined $in->{path};
    my %dup;
    my @exts = map {
      if (defined $_ and not $dup{$_}++) {
	$_
      } else { () }
    } ($vfs->{ext_public}, $vfs->{ext_private});
    my %dup2;
    map {
      my $name = substr($_, length($in->{path})+1);
      $name =~ s/\.\w+$//;
      $dup2{$name}++ ? () : $name;
    # Not CORE::glob: it splits the pattern on whitespace in the path. GH-275
    } File::Glob::bsd_glob("$in->{path}/[a-z]*.{".join(",", @exts)."}");
  }
  #----------------------------------------
  sub YATT::Lite::VFS::Dir::load {
    (my vfs_dir $in, my VFS $vfs, my $nameSpec) = @_;
    return unless defined $in->{path};
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

    # A (part) name must never escape $in->{path}. Request-derived names
    # are already restricted to \w+ in WebMVC0::Connection; this is the
    # last line of defense for every other caller.
    foreach my $n ($partName, $realFile) {
      next unless defined $n;
      if ($n =~ m{/} or $n =~ m{\.\.}) {
        croak "Invalid part name (contains '/' or '..'): $n";
      }
    }

    $realFile ||= $partName;
    # Template-derived names are decoded strings; paths are octets. GH-275
    utf8::encode($realFile) if utf8::is_utf8($realFile);

    my $vfsname = "$in->{path}/$realFile";
    my @opt = (name => $partName, parent => $in);
    my ($kind, $path, @other) = do {
      if (ref $nameSpec) {
        my $ext = extname($vfsname);
        (file => $vfsname
         , ($ext eq $vfs->{ext_public}
            ? (public => 1) : ()));
      } elsif (my $fn = $vfs->find_ext($vfsname, $vfs->{ext_public})) {
	(file => $fn, public => 1);
      } elsif ($fn = $vfs->find_ext($vfsname, $vfs->{ext_private})) {
	# dir の場合、 new_tmplpkg では？
	my $kind = -d $fn ? 'dir' : 'file';
	($kind => $fn);
      } elsif (-d $vfsname) {
	return $vfs->{facade}->find_neighbor($vfsname);
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
    undef $file->{_partlist};
    undef $file->{_boundarylist};
    undef $file->{_Item};
    # undef $file->{string};
    undef $file->{base};
    $file->{_dependency} = +{};
  }
  sub YATT::Lite::VFS::Dir::refresh {}
  sub YATT::Lite::VFS::File::refresh {
    (my vfs_file $file, my VFS $vfs) = @_;
    return unless $$file{path} || $$file{string};
    # XXX: mtime!
    my @part = do {
      local $/; split /^!\s*(\w+)\s+(\S+)[^\n]*?\n/m, do {
	if ($$file{path}) {
	  open my $fh, '<', $$file{path}
	    or die "Can't open '$$file{path}': $!";
	  scalar <$fh>
	} else {
	  $$file{string};
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
    Scalar::Util::weaken($file->{_dependency}{$wpath} = $other);
    $other->add_dependent($file) if UNIVERSAL::isa($other, File);
  }
  sub YATT::Lite::VFS::File::add_dependent {
    (my File $file, my File $other) = @_;
    Scalar::Util::weaken($file->{_dependents}{refaddr($other)} = $other);
  }
  sub YATT::Lite::VFS::File::list_dependents {
    (my File $file) = @_;
    defined (my $deps = $file->{_dependents})
      or return;
    grep {defined} values %$deps;
  }
  sub YATT::Lite::VFS::File::list_dependency {
    (my File $file, my $detail) = @_;
    defined (my $deps = $file->{_dependency})
      or return;
    if ($detail) {
      wantarray ? map([$_ => $deps->{$_}], keys %$deps) : $deps;
    } else {
      values %$deps;
    }
  }
  sub refresh_deps_for {
    (my MY $self, my File $file) = @_;
    print STDERR "refresh deps for: ", $file->{path}, "\n" if DEBUG_REBUILD;
    foreach my $dep ($file->list_dependency) {
      unless ($self->{mark}{refaddr($dep)}++) {
	print STDERR " refreshing: ", $dep->{path}, "\n" if DEBUG_REBUILD;
	$dep->refresh($self);
      }
    }
  }

  #========================================
  sub add_to {
    (my VFS $vfs, my ($path, $data)) = @_;
    my @path = ref $path ? @$path : $path;
    my $lastName = pop @path;
    my Folder $folder = $vfs->{_root};
    while (@path) {
      my $name = shift @path;
      $folder = $folder->{_Item}{$name} ||= $vfs->create
	(data => {}, name => $name, parent => $folder);
    }
    # XXX: path を足すと、memory 動作の時に困る
    my Item $item = $vfs->create
      (data => $data, name => $lastName, parent => $folder);
    $folder->{_Item}{$item->item_key} = $item;
  }
  #========================================
  sub root {(my VFS $vfs) = @_; $vfs->{_root}}

  # special hook for root creation.
  sub root_create {
    (my VFS $vfs, my ($kind, $primary, %rest)) = @_;
    $rest{entns} //= $vfs->{entns};
    $vfs->{_root} = $vfs->create($kind, $primary, %rest);
  }
  sub create {
    (my VFS $vfs, my ($kind, $primary, %rest)) = @_;
    # XXX: $vfs は className の時も有る。
    if (my $sub = $vfs->can("create_$kind")) {
      $vfs->fixup_created(\@_, $sub->($vfs, $primary, %rest, type => $kind));
    } else {
      $vfs->{cache}{$primary} ||= do {
	# XXX: Really??
	$rest{entns} //= $vfs->{entns};
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
        , sorted_dump($folder->{path}), ")\n";
    } else {
      # XXX: This is required for perl 5.18 and before.
    }
    # create の直後、 after_create より前に、mark を打つ。そうしないと、 delegate で困る。
    if (ref $vfs) {
      $vfs->{_n_creates}++;
      $vfs->{mark}{refaddr($folder)}++;
    }

    if (my $path = $folder->{path} and not defined $folder->{name}) {
      $path =~ s/\.\w+$//;
      $path =~ s!.*/!!;
      $folder->{name} = $path;
    }

    if (my Folder $parent = $folder->{parent}) {
      if (defined $parent->{entns}) {
	$folder->{entns} = join '::'
	  , $parent->{entns}, $folder->{name};
	# XXX: base 指定だけで済むべきだが、Factory を呼んでないので出来ないorz...
	YATT::Lite::MFields->add_isa_to
	    ($folder->{entns}, $parent->{entns});
      }
    }
    if ($folder->{entns}) {
      if (not $vfs->{no_mro_c3}) {
	mro::set_mro($folder->{entns}, 'c3');
      }
      if (defined (my Folder $old = $vfs->{entns2vfs_item}{$folder->{entns}})) {
	if ($old != $folder) {
	  croak "EntNS confliction for $folder->{entns}! old=$old->{path} vs new=$folder->{path}";
	}
      }
      $vfs->{entns2vfs_item}{$folder->{entns}} = $folder;
    }
    $folder->after_create($vfs);
    $folder;
  }

  # XXX: <=> find_part_from_entns
  sub find_template_from_package {
    (my MY $self, my $pkg) = @_;
    $self->{entns2vfs_item}{$pkg};
  }

  sub create_data {
    (my VFS $vfs, my ($primary)) = splice @_, 0, 2;
    if (ref $primary) {
      # 直接 Folder slot にデータを。
      my vfs_dir $item = $vfs->vfs_dir->new(@_);
      $item->{_Item} = $primary;
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
    foreach my Folder $desc (@{$folder->{base}}) {
      if (ref $desc eq 'ARRAY') {
	#
	# This $desc structure *may* come from Factory->_list_base_spec_in
	#
	if ($desc->[0] eq 'dir') {
	  # To create YATT::Lite with .htyattconfig.xhf, Factory should be involved.
	  $desc = $vfs->{facade}->find_neighbor($desc->[1]);
	} else {
	  $desc = $vfs->create(@$desc);
	}
      }
      # parent がある == parent から指されている。なので、 weaken する必要が有る。
      weaken($desc) if $desc->{parent};
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
    return if $file->{overlay};
    return unless $file->{path};
    my $rootname = rootname($file->{path});
    my @found = grep {-d $$_[-1]} ([1, $rootname]
				   , [0, "$rootname.$vfs->{ext_private}"]);
    if (@found > 1) {
      $vfs->error(q|Don't use %1$s and %1$s.%2$s at once|
		  , $rootname, $vfs->{ext_private});
    } elsif (not @found) {
      return;
    }
    $file->{overlay} = do {
      my ($public, $path) = @{$found[0]};
      if ($public) {
	$vfs->{facade}->find_neighbor($path);
      } else {
	$vfs->create
	  (dir => $path, parent => $file->{parent});
      }
    };
  }
  #----------------------------------------
  sub YATT::Lite::VFS::File::declare_base {
    (my vfs_file $file, my ($spec), my VFS $vfs, my $part) = @_;
    my ($kind, $path) = split /=/, $spec, 2;
    # XXX: 物理 path だと困るよね？ findINC 的な処理が欲しい
    # XXX: 帰属ディレクトリより強くするため、先頭に。でも、不満。
    unshift @{$file->{base}}, $vfs->create($kind => $path);
    weaken($file->{base}[0]);
    $file->{_Item}{''} .= $part;
  }
  sub YATT::Lite::VFS::File::add_widget {
    (my vfs_file $file, my ($name, $part)) = @_;
    push @{$file->{_partlist}}, $file->{_Item}{$name} = $part;
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
