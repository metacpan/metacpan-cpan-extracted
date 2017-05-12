# -*- mode: perl; coding: utf-8 -*-
package YATT::LRXML::Parser;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(YATT::Class::Configurable);
use YATT::Fields
  (qw(^tokens
      cf_tree
      metainfo
      nsdict
      nslist
      re_splitter
      re_ns
      re_attlist
      re_entity

      re_arg_decls

      elem_kids

      cf_special_entities

      cf_untaint
      cf_debug
      cf_registry
    )
   , [cf_html_tags  => {input => 1, option => 0
			, form => 0, textarea => 0, select => 0}]
   , [cf_tokens        => qw(comment declarator pi tag entity)]
  );

use YATT::Util;
use YATT::Util::Taint;
use YATT::Util::Symbol qw(fields_hash);
use YATT::LRXML::Node;

use YATT::LRXML ();
use YATT::LRXML::MetaInfo ();

sub MetaInfo () { 'YATT::LRXML::MetaInfo' }
sub Scanner () { 'YATT::LRXML::Scanner' }
sub Builder () { 'YATT::LRXML::Builder' }
sub Cursor () { 'YATT::LRXML::NodeCursor' }

sub after_configure {
  my MY $self = shift;
  $self->SUPER::after_configure;
  $$self{re_ns} = $self->re_ns(0);
  $$self{re_splitter} = $self->re_splitter(1, $$self{re_ns});
  $$self{re_attlist}  = $self->re_attlist(2);
  $$self{re_arg_decls} = $self->re_arg_decls(1);
  {
    my %re_cached = map {$_ => 1} grep {/^re_/} keys %{fields_hash($self)};
    my @token_pat = $self->re_tokens(2);
    while (@token_pat) {
      my ($name, $pattern) = splice @token_pat, 0, 2;
      push @{$self->{elem_kids}}, [$name, qr{^$pattern}];
      next unless $re_cached{"re_$name"};
      $self->{"re_$name"} = $pattern;
    }
  }
}

sub configure_namespace {
  shift->metainfo->configure(namespace => shift);
}

sub configure_metainfo {
  (my MY $self) = shift;
  if (@_ == 1) {
    $self->{metainfo} = shift;
  } elsif (not $self->{metainfo}) {
    # @_ == 0 || > 1
    $self->{metainfo} = MetaInfo->new(@_);
  } else {
    $self->{metainfo}->configure(@_);
  }
  $self->{metainfo}
}

sub metainfo {
  (my MY $self) = shift;
  $self->{metainfo} ||= $self->configure_metainfo;
}

sub parse_handle {
  (my MY $self, my ($fh)) = splice @_, 0, 2;
  $self->configure_metainfo(@_);
  $self->after_configure;
  if (my $layer = $self->{metainfo}->cget('iolayer')) {
    binmode $fh, $layer;
  }
  my $scan = $self->tokenize(do {
    local $/;
    my $data = <$fh>;
    $self->{cf_untaint} ? untaint_any($data) : $data;
  });
  $self->organize($scan);
}

sub parse_string {
  my MY $self = shift;
  $self->configure_metainfo(splice @_, 1);
  $self->after_configure;
  my $scan = $self->tokenize($_[0]);
  $self->organize($scan);
  # $self->{cf_document}->set_tokens($self->{tokens});
  # $self->{cf_document}->set_tree($tree);
}

#========================================

sub scanner {
  (my MY $self) = @_;
  $self->Scanner->new(array => $self->{tokens}, index => 0
		      , linenum => 1
		      , metainfo => $self->{metainfo});
}

sub tree {
  my MY $self = shift;
  my $cursor = $self->call_type(Cursor => new => $self->{cf_tree}
				, metainfo => $self->{metainfo});
  #$cursor->configure(path => $self->Cursor->Path->new($self->{cf_tree}));
  $cursor;
}

sub new_root_builder {
  (my MY $self, my Scanner $scan) = @_;
  if (my $reg = $self->{cf_registry}) {
    $reg->new_root_builder($self, $scan);
  } else {
    require_and($self->Builder
		, new => $self->{cf_tree} = $self->create_node('root')
		, undef
		, startpos  => 0
		, startline => $scan->{cf_linenum}
		, linenum   => $scan->{cf_linenum});
  }
}

sub organize {
  (my MY $self, my Scanner $scan) = @_;
  my $builder = $self->new_root_builder($scan);
  while ($scan->readable) {
    my $text = $scan->read;
    $builder->add($scan, $text) if $text ne '';
    last unless $scan->readable;
    my ($toktype, @match) = $scan->expect($self->{elem_kids});
    unless (defined $toktype) {
      $self->build_scanned($builder, $scan
			   , unknown => undef, $scan->read);
      next;
    }

    if (my $sub = $self->can("build_$toktype")) {
      # declarator も complex 扱いにした方が良いね。
      $builder = $sub->($self, $scan, $builder, \@match);
    } else {
      # easy case.
      my ($ns, $body) = @match;
      $self->build_scanned($builder, $scan
			   , $toktype => $ns, $body);
    }
  }
  if ($builder->{cf_endtag} and $builder->{parent}) {
    die "Missing close tag '$builder->{cf_endtag}'"
      ." at line $builder->{cf_startline}"
      .$scan->{cf_metainfo}->in_file." \n";
  }
  
  if (wantarray) {
    ($self->tree, $self->{metainfo});
  } else {
    $self->tree;
  }
}

sub build_scanned {
  (my MY $self, my Builder $builder, my Scanner $scan) = splice @_, 0, 3;
  my $node = $self->create_node(@_);
  node_set_nlines($node, $scan->{cf_last_nol});
  $builder->add($scan, $node);
}

sub build_pi {
  (my MY $self, my Scanner $scan, my Builder $builder, my ($match)) = @_;
  $self->build_scanned($builder, $scan
		       , pi => $match->[0]
		       , $self->parse_entities($match->[1]));
  $builder;
}

sub build_entity {
  (my MY $self, my Scanner $scan, my Builder $builder, my ($match)) = @_;
  $self->build_scanned($builder, $scan
		       , entity => $self->parse_entpath($match->[0]));
  $builder;
}

sub build_tag {
  (my MY $self, my Scanner $scan, my Builder $builder, my ($match)) = @_;
  my ($close, $html, $ns, $tagname, $attlist, $is_ee) = @$match;
  $tagname ||= $html;

  if ($close) {
    $builder->verify_close($tagname, $scan);
    # そうか、ここで attribute element からの脱出もせにゃならん。
    # switched product 方式なら、parent は共通、かな？
    return $builder->parent;
  }

  my ($is_att, $nodetype, $qflag) = do {
    if (defined $ns and $ns =~ s/^:(?=\w)//) {
      (1, attribute => YATT::LRXML::Node->quoted_by_element($is_ee));
    } else {
      my $type = do {
	if (defined $html) {
	  $is_ee = $self->{cf_html_tags}{lc($html)};
	  'html';
	} else {
	  'element'
	}
      };
      (0, $type => $is_ee ? EMPTY_ELEMENT : 0);
    }
  };

  my $element = $self->create_node([$nodetype, $qflag]
				   , $html
				   ? $html
				   : [$ns, split /[:\.]/, $tagname]);
  $self->parse_attlist($attlist, $element);

  unless ($is_ee) {
    # <yatt:normal>...</yatt:normal>, <:yatt:attr>...</:yatt:attr>
    $builder->add($scan, $element)->open($element, endtag => $tagname);
  } elsif ($is_att) {
    # <:yatt:attr />...
    $builder->switch($element);
  } else {
    # <yatt:empty_elem />
    node_set_nlines($element, $scan->{cf_last_nol});
    $builder->add($scan, $element);
  }
}

#========================================

sub build_declarator {
  (my MY $self, my Scanner $scan, my Builder $builder, my ($match)) = @_;
  my ($ns, $tagname, $attlist) = @$match;

  my $element = $self->create_node(declarator =>
				   [$ns, $tagname]);
  push @$element, $self->parse_arg_decls(\$attlist);
  node_set_nlines($element, $scan->{cf_last_nol});
  if (my $reg = $self->{cf_registry}) {
    $reg->new_decl_builder($builder, $scan, $element, $self);
  } else {
    $builder->add($scan, $element);
  }
}

sub re_arg_decls {
  (my MY $self, my ($capture)) = @_;
  die "re_arg_decls(capture=0) is not yet implemented!" unless $capture;
  my ($SQ, $DQ) = ($self->re_sqv(2), $self->re_dqv(2));
  my $BARE = qr{([^=\-\'\"\s<>/\[\]%]+ | /(?!>))}x;
  my $ENT = qr{%([\w\:\.]+(?:[\w:\.\-=\[\]\{\}\(,\)]+)?);}x;
  qr{^ \s* -- (.*?) --   # 1
   |^ \s* $ENT           # 2
   |^ \s* (\])           # 3
   |^ \s+
     (?: (\w+)\s*=\s*)?  # 4
     (?: $SQ             # 5
     | $DQ               # 6
     | $BARE             # 7
     | (\[)(?:\s* (\w+(?:\:\w+)*)) # 8, 9
     )
  }xs;
  # '[ word' を一括で取り出すのは、次に ^\s+ を残しておくため.
}

sub re_decl_entity {
  (my MY $self, my ($capture)) = @_;
  qr{%([\w\:\.]+(?:[\w:\.\-=\[\]\{\}\(,\)]+)?);}x;
}

sub parse_arg_decls {
  (my MY $self, my ($strref)) = @_;
  my @args;
  while ($$strref =~ s{$$self{re_arg_decls}}{}x) {
    print STDERR "parse_arg_decls: ", join("|", map {
      defined $_ ? $_ : "(null)"
    } $&
		      , $1 # comment
		      , $2 # ENT
		      , $3 # ]
		      , $4 # name
		      , $5 # '..'
		      , $6 # ".."
		      , $7 # bare
		      , $8 # [
		      , $9 #  leader
		     ), "\n" if $self->{cf_debug};
    if (defined $1) { # comment
      push @args, $self->create_node(decl_comment => undef, $1);
    } elsif (defined $2) {      # ENT
      push @args
	, $self->create_node([entity => 1] => $self->parse_entpath($2));
    } elsif (defined $3) { # ]
      last;
    } else {
      # $4 # name
      # $5 # '..'
      # $6 # ".."
      # $7 # bare
      # $8 # ]
      if (defined $8) { # [
	# XXX: hard coded.
	push @args, my $nest = $self->create_node([attribute => 3], $4, $9);
	push @$nest, $self->parse_arg_decls($strref);
      } else {
	# XXX: dummy.
	push @args, $self->create_attlist('', $4, '=', $5, $6, $7);
      }
    }
  }
  print STDERR "REST<$$strref>\n" if $self->{cf_debug};
  @args;
}

#========================================

sub parse_attlist {
  my MY $self = shift;
  my $result = $_[1];		# Yes. this *is* intentional.
  # XXX: タグ内改行がここでカウントされなくなる。
  if (defined $_[0] and my @match = $_[0] =~ m{$$self{re_attlist}}g) {
    push @$result, $self->create_attlist(@match);
  }
  $result;
}

sub parse_entities {
  my MY $self = shift;
  # XXX: 行番号情報を受け取れた方が、嬉しいのだが…
  return undef unless defined $_[0]; # make sure single scalar is returned.
  return '' if $_[0] eq '';
  return $_[0] unless defined $$self{re_entity};
  my @tokens = split $$self{re_entity}, $_[0];
  return $tokens[0] if @tokens == 1;
  my @result;
  for (my $i = 0; $i < @tokens; $i += 2) {
    push @result, $tokens[$i] if $tokens[$i] ne "";
    push @result
      , $self->create_node(entity => $self->parse_entpath($tokens[$i+1]))
	if $i+1 < @tokens;
  }
  if (wantarray) {
    @result;
  } elsif (@result > 1) {
    [TEXT_TYPE, undef, @result];
  } else {
    $result[0];
  }
}

sub parse_entpath {
  (my MY $self, my ($entpath)) = @_;
  my @name;
  push @name, $1 while $entpath =~ s{^[\.\:]?(\w+)(?=[\.\:]|$)}{};
  # :func(), array[], hash{} is stored in node_body.
  # In &SA(); case, node_name is undef.
  (@name ? \@name : undef
   , $entpath eq "" ? () : $entpath);
}

#========================================

sub tokenize {
  my MY $self = shift;
  $self->{tokens} = [split $$self{re_splitter}, $_[0]];
  if (my MetaInfo $meta = $self->{metainfo}) {
    # $meta->{tokens} = $self->{tokens};
  }
  $self->scanner;
}

sub token_patterns {
  my ($self, $token_types, $capture, $ns) = @_;
  my $wantarray = wantarray;
  my @result;
  foreach my $type (@$token_types) {
    my $meth = "re_$type";
    push @result
      , $wantarray ? $type : ()
      , $self->$meth($capture, $ns);
  }
  return @result if $wantarray;
  my $pattern = join "\n | ", @result;
  qr{$pattern}x;
}

#----------------------------------------

sub re_splitter {
  (my MY $self, my ($capture, $ns)) = @_;
  my $body = $self->re_tokens(0, $ns);
  $capture ? qr{($body)} : $body;
}

sub re_tokens {
  (my MY $self, my ($capture, $ns)) = @_;
  $self->token_patterns($self->{cf_tokens}, $capture, $ns);
}

#
# re_tag(2) returns [ /, specialtag, ns, tag, attlist, / ]
#
sub re_tag {
  (my MY $self, my ($capture, $ns)) = @_;
  my $namepat = $self->token_patterns([qw(tagname_html tagname_qualified)]
				      , $capture, $ns);
  my $attlist = $self->re_attlist;
  if (defined $capture and $capture > 1) {
    qr{<(/)? (?: $namepat) ($attlist*) \s*(/)?>}xs;
  } else {
    my $re = qr{</? $namepat $attlist* \s*/?>}xs;
    $capture ? qr{($re)} : $re;
  }
}

#----------------------------------------

sub re_name {
  my ($self, $capture) = @_;
  my $body = q{[\w\-\.]+};
  $capture ? qr{($body)} : qr{$body};
}

sub re_ns {
  my ($self, $capture, $nslist, $additional) = @_;
  die "re_ns capture is not yet implemented" if $capture;
  $nslist ||= $self->{nslist} = do {
    my $meta = $self->metainfo;
    $self->{nsdict} = $meta->nsdict;
    $meta->cget('namespace');
  };
  unless (@$nslist) {
    '';
  } else {
    my $pattern = join "|", map {ref $_ ? @$_ : $_} @$nslist
      , !$additional ? () : ref $additional ? @$additional : $additional;
    qq{(?:$pattern)};
  }
}

sub re_nsname {
  my ($self, $capture) = @_;
  my $body = q{[\w\-\.:]+};
  $capture ? qr{($body)} : qr{$body};
}

sub re_tagname_qualified {
  my ($self, $capture, $ns) = @_;
  $ns = $$self{re_ns} unless defined $ns;
  my $name = $self->re_nsname;
  if (defined $capture and $capture > 1) {
    qr{ ( :?$ns) : ($name) }xs;
  } else {
    my $re = qq{ :?$ns : $name };
    $capture ? qr{($re)}xs : qr{$re}xs;
  }
}

sub re_tagname_html {
  (my MY $self, my ($capture, $ns)) = @_;
  my $body = join "|", keys %{$self->{cf_html_tags}};
  $capture ? qr{($body)}i : qr{$body}i;
}

#----------------------------------------

sub re_attlist {
  my ($self, $capture) = @_;
  my $name =  $self->re_nsname;
  my $value = $self->re_attvalue($capture);
  my $sp = q{\s+};
  my $eq = q{\s* = \s*};
  if (defined $capture and $capture > 1) {
    qr{($sp|\b) (?:($name) ($eq))? $value}xs;
  } else {
    my $re = qr{(?:$sp|\b) (?:$name $eq)? $value}xs;
    $capture ? qr{($re)} : $re;
  }
}

sub re_attvalue {
  my ($self, $capture) = @_;
  my ($SQ, $DQ, $NQ) =
    ($self->re_sqv($capture),
     $self->re_dqv($capture),
     $self->re_bare($capture));
  qr{$SQ | $DQ | $NQ}xs;
}

sub re_sqv {
  my ($self, $capture) = @_;
  my $body = qr{(?: [^\'\\]+ | \\.)*}x;
  $body = qr{($body)} if $capture;
  qr{\'$body\'}s;
}

sub re_dqv {
  my ($self, $capture) = @_;
  my $body = qr{(?: [^\"\\]+ | \\.)*}x;
  $body = qr{($body)} if $capture;
  qr{\"$body\"}s;
}

sub re_bare;
*re_bare = \&re_bare_torelant;

sub re_bare_strict {
  shift->re_nsname(@_);
}

sub re_bare_torelant {
  my ($self, $capture) = @_;
  my $body = qr{[^\'\"\s<>/]+ | /(?!>)}x;
  $capture ? qr{($body+)} : qr{$body+};
}

sub strip_bs {
  shift;
  $_[0] =~ s/\\(\.)/$1/g;
  $_[0];
}

#----------------------------------------

sub re_declarator {
  my ($self, $capture, $ns) = @_;
  my $namepat = $self->re_tagname_qualified($capture, $ns);
  my $arg_decls = q{[^>]};
  # $self->re_arg_decls(0);
  # print "<<$arg_decls>>\n";
  if (defined $capture and $capture > 1) {
    qr{<! (?: $namepat) ($arg_decls*?) \s*>}xs;
  } else {
    my $re = qr{<! $namepat $arg_decls*? \s*>}xs;
    $capture ? qr{($re)} : $re;
  }
}

sub re_comment {
  my ($self, $capture, $ns) = @_;
  $ns = $self->re_prefix($capture, $ns, '#');
  $capture ? qr{<!--$ns\b(.*?)-->}s : qr{<!--$ns\b.*?-->}s;
}

sub re_pi {
  my ($self, $capture, $ns) = @_;
  $ns = $self->re_prefix($capture, $ns);
  my $body = $capture ? qr{(.*?)}s : qr{.*?}s;
  qr{<\?\b$ns\b$body\?>}s;
}

sub re_entity {
  shift->re_entity_pathexpr(@_);
}

# normal entity
sub re_entity_strict {
  my ($self, $capture, $ns) = @_;
  $ns = defined $ns ? qq{$ns\:} : qr{\w+:};
  my $body = $self->re_nsname;
  if (defined $capture and $capture > 1) {
    qr{&$ns($body);}xs;
  } else {
    my $re = qr{&$ns$body;}xs;
    $capture ? qr{($re)} : $re;
  }
}

# extended (subscripted) entity.
sub re_entity_subscripted {
  my ($self, $capture, $ns) = @_;
  $ns = defined $ns ? qq{$ns\:} : qr{\w+:};
  my $name = $self->re_nsname;
  my $sub = $self->re_subscript;
  my $body = qq{$name$sub*};
  if (defined $capture and $capture > 1) {
    qr{&($ns)($body);}xs;
  } else {
    my $re = qr{&$ns$body;}xs;
    $capture ? qr{($re)} : $re;
  }
}

# This cannot handle matching paren, of course;-).
sub re_subscript {
  my $name = shift->re_nsname;
  qr{[\[\(\{]
     [\w\.\-\+\$\[\]\{\}]*?
     [\}\)\]]
   |\. $name
   |\: [/\$\.\-\w]+
  }xs;
}

# more extended
sub re_entity_pathexpr {
  my ($self, $capture, $ns) = @_;
  $ns = $self->re_prefix(0, $self->entity_ns($ns), '');
  my $body = qr{[\w\$\-\+\*/%<>\.=\@\|!:\[\]\{\}\(,\)]*};
  if (defined $capture and $capture > 1) {
    qr{&($ns\b$body);}xs;
  } else {
    my $re = qr{&$ns\b$body;}xs;
    $capture ? qr{($re)} : $re;
  }
}

sub entity_ns {
  my ($self, $ns) = @_;
  my $special = $self->{cf_special_entities}
    or return $ns;
  # XXX: die "entity_ns \$ns ($ns) is not yet implemented" if defined $ns;
  $self->re_ns(0, undef, $special);
}

#
sub re_prefix {
  (my MY $self, my ($capture, $ns, $pre, $suf)) = @_;
  $ns = $$self{re_ns} unless defined $ns;
  $pre = '' unless defined $pre;
  $suf = '' unless defined $suf;
  if (defined $ns and $ns ne '') {
    $ns = "($ns)" if $capture && $capture > 1;
    qq{$pre$ns$suf};
  } else {
    ''
  }
}

1;
