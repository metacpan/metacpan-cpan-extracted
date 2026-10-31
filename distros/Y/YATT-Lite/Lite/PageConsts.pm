package YATT::Lite::PageConsts;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use MOP4Import::Base::CLI_JSON -as_base
  , [fields => qw(_pages _page_loc _file _line)];

use File::Spec;
use List::Util qw(first);

use YATT::Lite::Util qw(globref);
require YATT::Lite::MFields;

# The instance registered by define_page(s). The receiver can be a class name,
# or an object created elsewhere (eg. by cli_run) which has no pages.
sub _registered {
  my ($self_or_class) = @_;
  if (ref $self_or_class and $self_or_class->{_pages}) {
    $self_or_class;
  } else {
    $self_or_class->instance;
  }
}

# The instance registered into $callpack itself (not inherited one),
# created and registered on the first call.
sub _instance_for {
  my ($pack, $callpack, $file, $line) = @_;
  if (my $sub = *{globref($callpack, 'instance')}{CODE}) {
    return $sub->();
  }
  my MY $self = $pack->new;
  $self->{_file} = File::Spec->rel2abs($file);
  $self->{_line} = $line;
  $self->register_into($callpack);
  $self;
}

sub define_page :MetaOnly {
  my ($pack, $page, $consts) = @_;
  my ($callpack, $file, $line) = caller;
  my MY $self = $pack->_instance_for($callpack, $file, $line);
  # Remember where each page is defined, for locate_page/locate_const.
  $self->add_page($page, $consts, File::Spec->rel2abs($file), $line);
}

sub define_pages_from_hash :MetaOnly {
  my ($pack, $pages) = @_;
  my ($callpack, $file, $line) = caller;
  ref $pages eq 'HASH'
    or Carp::croak("define_pages_from_hash takes a HASH ref of pages");
  my MY $self = $pack->_instance_for($callpack, $file, $line);
  # Locations of these pages are unknown; locate_page guesses them.
  $self->add_page($_, $pages->{$_}) for sort keys %$pages;
  $self;
}

sub add_page {
  (my MY $self, my ($page, $consts, $file, $line)) = @_;
  ref $consts eq 'HASH'
    or Carp::croak("Constants of page '$page' must be a HASH ref");
  if ($self->{_pages}{$page}) {
    my $where = do {
      if (my $loc = $self->{_page_loc}{$page}) {
        " at $loc->[0] line $loc->[1]";
      } else {
        "";
      }
    };
    my $redef = defined $file ? ", redefined at $file line $line" : "";
    die "Page '$page' is already defined$where$redef\n";
  }
  $self->{_pages}{$page} = $consts;
  $self->{_page_loc}{$page} = [$file, $line] if defined $file;
  $self;
}

sub register_into :MetaOnly {
  (my MY $self, my $pkg) = @_;
  YATT::Lite::MFields->add_isa_to($pkg, MY);
  *{globref($pkg, 'instance')} = sub { $self };
  *{globref($pkg, 'import')} = sub {
    my $callpack = caller;
    $self->inject_into($callpack, @_[1..$#_]);
  };
}

sub inject_into {
  (my MY $self, my ($destpkg, $page, %opts)) = @_;
  my $failok = delete $opts{missing_ok};
  if (keys %opts) {
    Carp::croak "Unknown options: ".join(", ", sort keys %opts);
  }
  $page ||= do {
    if (my $sub = $self->can("page_name")) {
      $sub->($self)
    }
  };
  unless (defined $page and $page ne '') {
    Carp::croak("page name is not specified");
  }
  my $vars = $self->find_consts($page)
    or $failok or Carp::croak("No such page: $page");

  # print STDERR "# injecting vars (@{[keys %$vars]})in $page\n"
  #   , YATT::Lite::Util::terse_dump($self);

  foreach my $name (keys %$vars) {
    my $value = $vars->{$name};
    if ($failok and ref $value and UNIVERSAL::can($value, 'varname')
        and UNIVERSAL::can($value, 'value')) {
      # For $failok case (== from yatt)
      my $glob = globref($destpkg, $value->varname($name));
      (*$glob) = map {ref $_ ? $_ : \ $_} $value->value;
    } else {
      my $glob = globref($destpkg, $name);
      *$glob = do {
        if (not ref $value or ref $value eq 'ARRAY' or ref $value eq 'HASH') {
          \ $value
        } else {
          $value;
        }
      };
      # 関数の場合は、関数だけでなく、スカラ変数にも入れておく。
      *$glob = \ $value if ref $value eq 'CODE';
    }
  }
}


*find_vars = *find_consts;
*find_vars = *find_consts;
sub find_consts :Doc(Find constant(s) for specified PAGE/NAME) {
  my MY $self = shift->_registered;
  my ($page, $varname) = @_;
  my $page_vars = $self->{_pages}{$page}
    or return;
  if (not defined $varname) {
    $page_vars;
  } else {
    $page_vars->{$varname};
  }
}

sub const_type :Doc(Type of yatt variable for the constant VALUE) {
  my ($self_or_class, $value) = @_;
  if (not ref $value) {
    'text';
  } elsif (ref $value eq 'ARRAY') {
    'list'
  } elsif (ref $value eq 'CODE') {
    'expr'
  } elsif (UNIVERSAL::can($value, 'varname')
           and UNIVERSAL::can($value, 'value')) {
    'html';
  } else {
    'scalar';
  }
}

#========================================
# Locations in the source of the pagevars module (for LanguageServer).
# const_key_regexp and page_key_regexp can be overridden in the
# pagevars module to support local notations.

sub source_lines {
  (my MY $self, my $file) = @_;
  open my $fh, '<', $file
    or return;
  <$fh>;
}

# "NAME =>" of a constant.
sub const_key_regexp {
  (my MY $self, my $name) = @_;
  qr/(?:^|[\s,{(])(['"]?)\Q$name\E\1\s*=>/;
}

# Key of PAGE in a hash of pages ("$PAGES{PAGE} =" or "PAGE =>").
# Only used for pages registered by define_pages_from_hash.
sub page_key_regexp {
  (my MY $self, my $page) = @_;
  qr/(?:^|[\s,{(])(['"]?)\Q$page\E\1\s*(?:=>|\}\s*=)/;
}

# The line which starts a define_page call.
sub page_call_regexp {
  (my MY $self) = @_;
  qr/\bdefine_page\b/;
}

# Block of PAGE in @$lines as 0-based ($start, $end), or empty list.
sub page_block_range {
  (my MY $self, my ($page, $lines)) = @_;
  if (my $loc = $self->{_page_loc}{$page}) {
    # From define_page of PAGE to just before the next define_page.
    my ($file, $line) = @$loc;
    my @recorded = sort {$a <=> $b}
      map {$_->[1]} grep {$_->[0] eq $file} values %{$self->{_page_loc}};
    my ($prev) = reverse grep {$_ < $line} @recorded;
    my ($next) = grep {$_ > $line} @recorded;
    my $start = $self->_page_call_start($lines, $line - 1, $prev // 0);
    my $end = defined $next
      ? $self->_page_call_start($lines, $next - 1, $line) - 1
      : $#$lines;
    return ($start, $end);
  }
  my $page_re = $self->page_key_regexp($page);
  my $start = first {$lines->[$_] =~ $page_re} 0 .. $#$lines;
  return unless defined $start;
  my @other_re = map {$self->page_key_regexp($_)}
    grep {$_ ne $page} keys %{$self->{_pages}};
  my $end = first {
    my $text = $lines->[$_];
    grep {$text =~ $_} @other_re;
  } $start+1 .. $#$lines;
  ($start, defined $end ? $end - 1 : $#$lines);
}

# caller reports the line of the statement executed last before the call,
# which can be inside a block (map, grep, do) in the arguments.
# So look back (down to index $lower) for the line which starts the call.
sub _page_call_start {
  (my MY $self, my ($lines, $i, $lower)) = @_;
  my $call_re = $self->page_call_regexp;
  for (my $j = $i; $j >= $lower; $j--) {
    return $j if defined $lines->[$j] and $lines->[$j] =~ $call_re;
  }
  $i;
}

sub locate_page :Doc(Locate the definition of PAGE as file and line) {
  my MY $self = shift->_registered;
  my ($page) = @_;
  $self->{_pages}{$page}
    or return;
  if (my $loc = $self->{_page_loc}{$page}) {
    my ($start) = $self->page_block_range($page
                                          , [$self->source_lines($loc->[0])]);
    return ($loc->[0], $start + 1);
  }
  my $file = $self->{_file}
    or return;
  my ($start) = $self->page_block_range($page, [$self->source_lines($file)]);
  ($file, defined $start ? $start + 1 : $self->{_line});
}

# Looks for the key of NAME in the block of PAGE first, then anywhere
# in the file (for common values), then falls back to the page itself.
sub locate_const :Doc(Locate the definition of constant NAME for PAGE as file and line) {
  my MY $self = shift->_registered;
  my ($page, $name) = @_;
  my $page_vars = $self->{_pages}{$page}
    or return;
  exists $page_vars->{$name}
    or return;
  my $file = do {
    if (my $loc = $self->{_page_loc}{$page}) {
      $loc->[0];
    } else {
      $self->{_file};
    }
  } or return;
  my @lines = $self->source_lines($file);
  my $const_re = $self->const_key_regexp($name);

  if (my ($start, $end) = $self->page_block_range($page, \@lines)) {
    foreach my $i ($start .. $end) {
      return ($file, $i+1) if $lines[$i] =~ $const_re;
    }
  }
  if (defined(my $i = first {$lines[$_] =~ $const_re} 0 .. $#lines)) {
    return ($file, $i+1);
  }
  $self->locate_page($page);
}

sub as_html {
  my ($text) = @_;
  bless \ $text, 'YATT::Lite::PageConsts::html';
}

package
  YATT::Lite::PageConsts::html;
use overload '""' => 'value';
sub varname {shift; 'html_'. shift}
sub value {${shift()}}


1;
