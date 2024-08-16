package YATT::Lite::CGen; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use constant DEBUG_REBUILD => $ENV{DEBUG_YATT_REBUILD};

use base qw(YATT::Lite::VarMaker);
use YATT::Lite::MFields qw/curtmpl curwidget curtoks
	      altgen needs_escaping depth
	      cf_cgen_loader
	      cf_only_parse
	      cf_no_lineinfo cf_check_lineno
	      no_last_newline
	      cf_vfs cf_parser cf_sink scope
	      cf_lcmsg_sink
	      cf_prefer_call_for_entity
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
  $self->{cf_vfs}->error(q{sink is empty}) unless $self->{cf_sink};
  return if defined $tmpl->{product}{$type};
  local $self->{depth} = 1 + ($self->{depth} // 0);
  my $pkg = $tmpl->{product}{$type} = $tmpl->{cf_entns};
  if (not defined $tmpl->{product}{$type}) {
    croak "package for product $type of $tmpl->{cf_path} is not defined!";
  } else {
    print STDERR "# generating $pkg for $type code of "
      . ($tmpl->{cf_path} // "(undef)") . "\n"
      if DEBUG_REBUILD;
  }
  $self->{cf_parser}->parse_body($tmpl)
    if not $kind or not $self->{cf_only_parse}
      or $self->{cf_only_parse}{$kind};
  $self->setup_inheritance_for($spec, $tmpl);
  my @res = $self->generate($tmpl, $kind);
  if (my $sub = $self->{cf_sink}) {
    $sub->({folder => $tmpl, package => $pkg, kind => 'body'
	     , depth => $self->{depth}}
	    , @res);
  }
  $pkg;
}

sub with_template {
  (my MY $self, my Template $tmpl, my ($task, @args)) = @_;
  local $self->{curtmpl} = $tmpl;
  local $self->{curline} = 1;
  if (ref $task eq 'CODE') {
    $task->($self, @args);
  } else {
    my ($meth, @rest) = YATT::Lite::Util::lexpand($task);
    $self->$meth(@rest, @args);
  }
}

sub generate {
  (my MY $self, my Template $tmpl) = splice @_, 0, 2;
  my $kind = shift if @_;
  # XXX: Rewrite this with with_template
  local $self->{curtmpl} = $tmpl;
  local $self->{curline} = 1;
  ($self->generate_preamble($self->{curtmpl})
   , map {
    my Part $part = $_;
    if (not $kind or not $self->{cf_only_parse}
	or $kind eq $part->{cf_kind}) {
      my $sub = $self->can("generate_$part->{cf_kind}")
	or die $self->generror("Can't generate part type: '%s'"
			       , $part->{cf_kind});
      $sub->($self, $part, $part->{cf_name}, $tmpl->{cf_path});
    } else {
      ();
    }
  } @{$tmpl->{partlist}});
}

sub setup_inheritance_for {
  (my MY $self, my $spec, my Template $tmpl) = @_;
  $self->ensure_generated_for_folders($spec, $tmpl->list_base);
}

#========================================
sub altgen {
  (my MY $self, my $ns) = @_;
  # ns 一つに付き 高々 1回しか、can しないで済むように... と言っても、cgen 自体が複数個作られたら..
  unless (exists $self->{altgen}{$ns}) {
    $self->{altgen}{$ns} = do {
      if (my $sub = $self->can("create_altgen_$ns")) {
	sub {
	  # 毎回, new し直す。
	  $sub->($self)->generate_node(@_);
	};
      }
    };
  }
  $self->{altgen}{$ns};
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
  for (my $scope = $self->{scope}; $scope; $scope = $scope->[1]) {
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
  $self->{cf_vfs}->find_part_from($self->{curtmpl}, @path)
    || $self->{cf_vfs}->find_part_from($self->{curtmpl}, $ns, @path);
}

sub generror {
  my MY $self = shift;
  my Template $tmpl = $self->{curtmpl};
  my ($pkg, $file, $line) = caller;
  my %opts = ($self->_tmpl_file_line($self->{curline}), callerinfo());
  $self->_error(\%opts, @_);
}
sub _error {
  my MY $self = shift;
  $self->{cf_vfs}->error(@_);
}
sub _tmpl_file_line {
  (my MY $self, my $ln) = @_;
  my Template $tmpl = $self->{curtmpl};
  (tmpl_file => $tmpl->{cf_path} // $tmpl->{cf_name}
   , defined $ln ? (tmpl_line => $ln) : ());
}

sub add_curline {
  (my MY $self, my $text) = @_;
  $self->{curline} += numLines($text);
  $text;
}

sub sync_curline {
  (my MY $self, my $lineno) = @_;
  return unless defined $lineno;
  my $diff = $lineno - $self->{curline};
  die "curline exceeds expected lineno! expect $lineno, curline=$self->{curline}\n" if $self->{cf_check_lineno} and $diff < 0;
  $self->{curline} = $lineno;
  $diff > 0 ? "\n" x $diff : ();
}
# <!yatt:widget ...> や <yatt:call ...> の直後の改行を,
# ソース上のみの(出力しない)改行に変換する。
sub cut_next_nl {
  my MY $self = shift;
  # undef は返したくないので。
  return wantarray ? () : ''
    unless $self->{curtoks}
    and @{$self->{curtoks}} and $self->{curtoks}[0] =~ /^\r?\n$/;
  return wantarray ? () : ''
    if @{$self->{curtoks}} == 1; # 最後の一個の改行は、残す。これは "}\n" のため
  $self->{curline}++;
  shift @{$self->{curtoks}};
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
