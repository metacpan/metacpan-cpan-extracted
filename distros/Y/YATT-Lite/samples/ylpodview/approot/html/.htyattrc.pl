use strict;
use YATT::Lite::Util qw(lexpand);
use YATT::Lite qw/*CON/;

use fields qw/cf_docpath
	      cf_lang_available
	      cf_mod_overlay
	     /;

sub after_new {
  (my MY $self) = @_;
  $self->SUPER::after_new;
  $self->{cf_lang_available} //= [qw/en ja/];
}

Entity alt_lang => sub {
  my ($this, $list) = @_;
  $list //= do {
    my MY $self = $this->YATT;
    $self->{cf_lang_available};
  };
  $this->entity_alternative($this->entity_current_lang, $list);
};

Entity search_pod => sub {
  my ($this, $modname) = @_;

  my MY $yatt = $this->YATT;
  if (my $prefix = $yatt->{cf_mod_overlay}) {
    $modname =~ s{^$prefix}{};
  }
  $yatt->search_pod($modname, $this->entity_suffix_list);
};

sub search_pod {
  my ($yatt, $modname, @lang_suf) = @_;
  my $modfn = modname2fileprefix($modname);
  my $debug = -r "$yatt->{cf_dir}/.htdebug";
  my @dir = lexpand($yatt->{cf_docpath});
  my @suf = (map("$_.pod", @lang_suf ? @lang_suf : ("")), ".pm", "");
  my @found;
  foreach my $dir (@dir) {
    foreach my $suf (@suf) {
      my $fn = "$dir/$modfn$suf";
      my $found = -f $fn;
      $CON->logdump(debug => ($found ? "found" : "not found"), $fn) if $debug;
      next unless $found;
      return $fn unless wantarray;
      push @found, $fn
    }
  }
  @found;
};

Entity suffix_list => sub {
  my ($this) = @_;
  my $lang = $this->entity_current_lang;
  if ($lang eq $this->entity_default_lang) {
    return ('')
  } else {
    return (".$lang", '');
  }
};

Entity podtree => sub {
  my ($this, $fn) = @_;
  unless (-r $fn) {
    die "Can't read '$fn'";
  }

  $this->YATT->podtree($fn);
};

sub podtree {
  my ($yatt, $fn) = @_;
  require Pod::Simple::SimpleTree;
  my $parser = Pod::Simple::SimpleTree->new;
  $parser->accept_targets(qw(html css code image));
  #XXX: open my $fh, "<:encoding(utf-8)", $fn or die "Can't open $fn: $!";
  my $tree = $parser->parse_file($fn)->root;
  &YATT::Lite::Breakpoint::breakpoint();
  postprocess($tree);
  wantarray ? @$tree : $tree;
};

sub cmd_podtree {
  my ($yatt, $mod) = @_;
  require YATT::Lite::Util;
  my ($fn) = $yatt->search_pod($mod)
    or die "Not found: $mod\n";
  foreach my $item ($yatt->podtree($fn)) {
    print YATT::Lite::Util::terse_dump($item), "\n";
  }
}

sub postprocess {
  my ($list) = @_;
  my $hash = $list->[1];
  for (my $i = $#$list; $i >= 2; $i--) {
    # <<<Backward<<<
    ref $list->[$i] and $list->[$i][0] eq 'X'
      or next;
    my ($xref) = splice @$list, $i;
    push @{$hash->{X}}, $xref->[-1];
  }
  foreach my $item (@{$list}[2..$#$list]) {
    # >>>Forward>>>
    next unless ref $item;
    postprocess($item);
    $item->[0] =~ s/-/_/g;
  }
}

Entity bar2underscore => sub {
  my ($this, $str) = @_;
  $str =~ s/-/_/g;
  $str;
};

Entity read_xhf => sub {
  my $this = shift;
  $this->YATT->read_file_xhf(@_);
};

Entity podsection => sub {
  my $this = shift;
  my $group; $group = sub {
    my ($list, $curlevel, @init) = @_;
    my @result = ($curlevel, @init);
    while (@$list) {
      my ($lv) = $list->[0][0] =~ /^head(\d+)$/;
      unless (defined $lv) {
	push @result, shift @$list;
      } elsif ($lv > $curlevel) {
	push @result, $group->($list, $lv, shift @$list);
      } else {
	# $lv <= $curlevel
	last;
      }
    }
    return \@result;
  };
  my ($root, $atts, @tree) = $this->entity_podtree(@_);
  my @result;
  push @result, $group->(\@tree, 1, shift @tree) while @tree;
  @result;
};

Entity is_smartmobile => sub {
  my $this = shift;
  # XXX: PSGI
  $ENV{HTTP_USER_AGENT}
    && $ENV{HTTP_USER_AGENT} =~ /\b(iPhone|iPad|iPod|iOS|Android|webOS)\b/;
};

sub section_enc {
  my ($str) = @_;
  $str =~ s/^\s+|\s+$//g;
  $str =~ s{(?:(\s+) | ([^\s0-9A-Za-z_]+))}{
    $1 ? ('_' x length($1))
      : join('', map {sprintf "-%02X", unpack("C", $_)} split '', $2)
    }exg;
  "--$str";
}


Entity list2id => sub {
  my ($this, $list, $start) = @_;
  unless (ref $list) {
    section_enc($list);
  } else {
    join "", map {
      ref $_ ? $this->entity_list2id($_, 2) : section_enc($_);
    } @$list[($start // 2) .. $#$list];
  }
};

Entity lremoveKey => sub {
  my ($this, $key, $list, $until) = @_;
  return unless ref $list;
  $until //= 0;
  for (my $i = $#$list; $i >= $until; $i--) {
    ref $list->[$i] and $list->[$i][0] eq $key
      or next;
    splice @$list, $i;
  }
  $list;
};

Entity podlink => sub {
  my ($this, $name, $atts) = @_;
  defined (my $type = $atts->{type})
    or return '#--undef--';

  if ($type eq 'pod') {
    my $url = do {
      if (my $to = $atts->{to} || $CON->param('mod')) {
	$CON->mkurl("/$name/$to", undef, mapped_path => 1, local => 1);
      } else {
	$CON->mkurl();
      }
    };
    if (my $sect = $atts->{section}) {
      $url .= '#'. section_enc($sect);
    }
    return $url;
  } elsif ($type eq 'url') {
    return "$atts->{to}"; # to stringify.
  } else {
    return "#-unknown-linktype-$type";
  }
};

Entity trim_leading_ws => sub {
  my ($this, $str) = @_;
  my ($head, @rest) = split /\n/, $str;
  if ($head =~ s/^\s+//) {
    my $prefix = $&;
    s/^$prefix// for @rest;
  }
  join "\n", $head, @rest;
};


sub pod_info {
  my ($fn) = @_;
  open my $fh, '<:encoding(utf8)', $fn or die "Can't open $fn: $!";
  # &YATT::Lite::Breakpoint::breakpoint();
  my ($podname, $lang) = $fn =~ m{([^/\.]+)(?:\.(\w+))?\.pod$};
  $lang ||= EntNS->entity_default_lang();
  local $_;
  while (<$fh>) {
    chomp;
    # Note: eof($fh) is important to avoid flip-flop stay on.
    my $line = /^=head1 NAME/ .. (/^[^\s=].*/ || eof($fh))
      or next;
    # Encode::encode("utf-8", $_)
    return [$podname, $lang, $_] if $line =~ /E0$/
  }
  return;
}

Entity docpath_files => sub {
  my ($this, $ext) = @_;
  my YATT $yatt = $this->YATT;
  my ($dir) = lexpand($yatt->{cf_docpath})
    or return;

  # &YATT::Lite::Breakpoint::breakpoint();
  $ext =~ s/^\.*/./;
  my $current_lang = $this->entity_current_lang;

  if (-r (my $fn = "$dir/index.lst")) {
      open my $fh, '<', $fn or die "Can't open $fn: $!";
      chomp(my @lines = <$fh>);
      my @info;
      foreach my $name (@lines) {
	my $rec = [$name, []
		   , $yatt->{cf_mod_overlay}
		   ? "$yatt->{cf_mod_overlay}::$name" : $name
		   , ""];
	foreach my $info (map {pod_info($_)} glob("$dir/$name*$ext")) {
	  my ($name, $lang, $title) = @$info;
	  push @{$rec->[1]}, $lang;
	  if ($lang eq $current_lang) {
	    $rec->[-1] = $title;
	  }
	}
	push @info, $rec if @{$rec->[1]};
      }
      @info;
  } else {
    my %gathered;
    foreach my $info (map { pod_info($_) } glob("$dir/*$ext")) {
      my ($name, $lang, $title) = @$info;
      $gathered{$name} //= [$name, [], ""];
      if ($lang eq $current_lang) {
	$gathered{$name}[2] = $title;
      } else {
	push @{$gathered{$name}[1]}, $lang;
      }
    }
    sort {$$a[0] cmp $$b[0]} values %gathered;
  }
};

sub modname2fileprefix {
  my ($mod) = @_;
  $mod =~ s,::,/,g;
  $mod =~ s,^/+|/+$,,g;
  $mod;
}

Entity test => sub {
  my ($this, $text) = @_;
  $text;
};
