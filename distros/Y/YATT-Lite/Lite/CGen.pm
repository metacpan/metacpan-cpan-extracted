package YATT::Lite::CGen; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use constant DEBUG_REBUILD => $ENV{DEBUG_YATT_REBUILD};

use YATT::Lite::Util::AsBase qw/-as_base import/;

use base qw(YATT::Lite::VarMaker);
use YATT::Lite::MFields qw/_curtmpl _curwidget _curtoks
	      _altgen _needs_escaping _depth
	      cgen_loader
	      only_parse
	      no_lineinfo check_lineno
	      yatt_no_last_newline
	      vfs parser sink
	      _scope
	      lcmsg_sink
	      prefer_call_for_entity
	      no_conditional_call
	      pagevars
			  /
  ;

use YATT::Lite::Core qw(Template Part Folder);
use YATT::Lite::Constants;
use YATT::Lite::Util qw(callerinfo numLines);

sub ensure_generated_for_folders {
  (my MY $self, my $spec) = splice @_, 0, 2;
  foreach my Folder $folder (@_) {
    if ($folder->can_generate_code) {
      $self->ensure_generated($spec, $folder);
    }
  }
}

sub ensure_generated {
  (my MY $self, my $spec, my Template $tmpl) = @_;
  my ($type, $kind) = ref $spec ? @$spec : $spec;
  $self->{vfs}->error(q{sink is empty}) unless $self->{sink};
  return if defined $tmpl->{_product}{$type};
  local $self->{_depth} = 1 + ($self->{_depth} // 0);
  my $pkg = $tmpl->{_product}{$type} = $tmpl->{entns};
  if (not defined $tmpl->{_product}{$type}) {
    croak "package for product $type of $tmpl->{path} is not defined!";
  } else {
    print STDERR "# generating $pkg for $type code of "
      . ($tmpl->{path} // "(undef)") . "\n"
      if DEBUG_REBUILD;
  }
  $self->{parser}->parse_body($tmpl)
    if not $kind or not $self->{only_parse}
      or $self->{only_parse}{$kind};
  $self->setup_inheritance_for($spec, $tmpl);
  # <!yatt:import> のソースも先に generate しておく。
  # (子の glob 代入が eval される時点でソース側の sub が必要) GH-256
  if (my @import_srcs = $tmpl->list_import_sources) {
    $self->ensure_generated_for_folders($spec, @import_srcs);
  }
  my @res = $self->generate($tmpl, $kind);
  if (my $sub = $self->{sink}) {
    $sub->({folder => $tmpl, package => $pkg, kind => 'body'
	     , depth => $self->{_depth}}
	    , @res);
  }
  $pkg;
}

sub with_template {
  (my MY $self, my Template $tmpl, my ($task, @args)) = @_;
  local $self->{_curtmpl} = $tmpl;
  local $self->{_curline} = 1;
  if (ref $task eq 'CODE') {
    $task->($self, @args);
  } else {
    my ($meth, @rest) = YATT::Lite::Util::lexpand($task);
    unless ($meth) {
      Carp::croak "meth is undef";
    }
    my $sub = $self->can($meth) or do {
      Carp::croak "No such method $meth";
    };
    $sub->($self, @rest, @args);
  }
}

sub generate {
  (my MY $self, my Template $tmpl) = splice @_, 0, 2;
  my $kind = shift if @_;
  # XXX: Rewrite this with with_template
  local $self->{_curtmpl} = $tmpl;
  local $self->{_curline} = 1;
  local $self->{_scope} = $self->generate_page_scope($tmpl);
  ($self->generate_preamble($self->{_curtmpl})
   , map {
    my Part $part = $_;
    if (not $kind or not $self->{only_parse}
	or $kind eq $part->{kind}) {
      $self->generate_part($tmpl, $part);
    } else {
      ();
    }
  } @{$tmpl->{_partlist}});
}

sub generate_part {
  (my MY $self, my Template $tmpl, my Part $part) = @_;
  my $sub = $self->can("generate_$part->{kind}")
    or die $self->generror("Can't generate part type: '%s'"
                           , $part->{kind});
  local $self->{yatt_no_last_newline} = $part->{yatt_no_last_newline};
  $sub->($self, $part, $part->{name}, $tmpl->{path});
}

sub generate_page_scope {
  +{}
}

sub setup_inheritance_for {
  (my MY $self, my $spec, my Template $tmpl) = @_;
  $self->ensure_generated_for_folders($spec, $tmpl->list_base);
}

#========================================
sub altgen {
  (my MY $self, my $ns) = @_;
  # ns 一つに付き 高々 1回しか、can しないで済むように... と言っても、cgen 自体が複数個作られたら..
  unless (exists $self->{_altgen}{$ns}) {
    $self->{_altgen}{$ns} = do {
      if (my $sub = $self->can("create_altgen_$ns")) {
	sub {
	  # 毎回, new し直す。
	  $sub->($self)->generate_node(@_);
	};
      }
    };
  }
  $self->{_altgen}{$ns};
}
sub create_altgen_js {
  require YATT::Lite::CGen::JS;
  my MY $self = shift;
  new YATT::Lite::CGen::JS
    ($self->cf_delegate(qw(vfs parser no_lineinfo check_lineno)));
}
#========================================
sub find_var {
  (my MY $self, my $varName, my $check) = @_;
  confess "Undefined varName for find_var!" unless defined $varName;
  for (my $scope = $self->{_scope}; $scope; $scope = $scope->[1]) {
    if (defined (my $var = $scope->[0]{$varName})) {
      next if $check and not $check->($var);
      return $var;
    }
  }
}
sub find_callable_var {
  (my MY $self, my $varName) = @_;
  $self->find_var($varName, sub {shift->callable});
}
sub lookup_widget {
  (my MY $self, my ($ns, @path)) = @_;
  # ns 抜きと、有りで一回ずつ検索する
  $self->{vfs}->find_part_from($self->{_curtmpl}, @path)
    || $self->{vfs}->find_part_from($self->{_curtmpl}, $ns, @path);
}

sub generror {
  my MY $self = shift;
  my Template $tmpl = $self->{_curtmpl};
  my ($pkg, $file, $line) = caller;
  my %opts = ($self->_tmpl_file_line($self->{_curline}), callerinfo());
  $self->_error(\%opts, @_);
}
# generror の行番号指定版 (LRXML の synerror_at に相当)。
# 例: die $cgen->generror_at($node->[NODE_LNO], ...)
sub generror_at {
  (my MY $self, my $ln) = splice @_, 0, 2;
  my %opts = ($self->_tmpl_file_line($ln // $self->{_curline}), callerinfo());
  $self->_error(\%opts, @_);
}
sub _error {
  my MY $self = shift;
  $self->{vfs}->error(@_);
}
sub _tmpl_file_line {
  (my MY $self, my $ln) = @_;
  my Template $tmpl = $self->{_curtmpl};
  (tmpl_file => $tmpl->{path} // $tmpl->{name}
   , defined $ln ? (tmpl_line => $ln) : ());
}

sub add_curline {
  (my MY $self, my $text) = @_;
  $self->{_curline} += numLines($text);
  $text;
}

sub sync_curline {
  (my MY $self, my $lineno) = @_;
  return unless defined $lineno;
  my $diff = $lineno - $self->{_curline};
  die "curline exceeds expected lineno! expect $lineno, curline=$self->{_curline}\n" if $self->{check_lineno} and $diff < 0;
  $self->{_curline} = $lineno if $lineno > $self->{_curline};
  $diff > 0 ? "\n" x $diff : ();
}
# <!yatt:widget ...> や <yatt:call ...> の直後の改行を,
# ソース上のみの(出力しない)改行に変換する。
sub cut_next_nl {
  my MY $self = shift;
  # undef は返したくないので。
  return wantarray ? () : ''
    unless $self->{_curtoks}
    and @{$self->{_curtoks}} and $self->{_curtoks}[0] =~ /^\r?\n$/;
  return wantarray ? () : ''
    if @{$self->{_curtoks}} == 1; # 最後の一個の改行は、残す。これは "}\n" のため
  $self->{_curline}++;
  shift @{$self->{_curtoks}};
}

sub mkscope {
  my MY $self = shift;
  return unless @_;
  my $scope = ref $_[-1] eq 'ARRAY' ? pop : [pop];
  while (@_) {
    $scope = [pop, $scope];
  }
  $scope;
}

sub terse_dump {
  my MY $self = shift;
  YATT::Lite::Util::terse_dump(@_);
}

sub node_sync_curline {
  (my MY $self, my $node) = @_;
  $self->sync_curline($node->[NODE_LNO]);
}

1;
