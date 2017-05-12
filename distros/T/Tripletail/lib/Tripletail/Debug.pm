# -----------------------------------------------------------------------------
# Tripletail::Debug - TL デバッグ用クラス
# -----------------------------------------------------------------------------
package Tripletail::Debug;
use strict;
use warnings;
use Data::Dumper ();
use Tripletail;

sub _INIT_HOOK_PRIORITY() { 1_000_000_000 }; # 順序は問わない。
sub _PRE_REQUEST_HOOK_PRIORITY() { 1_000_000_000 } # 最後でなければならない。 
sub _OUTPUT_FILTER_PRIORITY() { 1_000_000_000 } # 最後でなければならない。

our $_INSTANCE;

1;

sub _getInstance {
	my $class = shift;

	if(!$_INSTANCE) {
		$_INSTANCE = $class->__new(@_);
	}

	$_INSTANCE;
}


sub __new {
	my $class = shift;
	my $group = shift;
	my $this = bless {} => $class;

	$this->{group} = defined $group ? $group : 'Debug';
	$this->{enabled} = $TL->INI->get($this->{group} => enable_debug => undef);
	$this->{popup_type} = $TL->INI->get($this->{group} => 'popup_type', 'none');

	$this->{warn_logging} = $TL->INI->get($this->{group} => 'warn_logging', 1);
	$this->{warn_popup} = $TL->INI->get($this->{group} => 'warn_popup', 1);

	$this->{log_popup} = $TL->INI->get($this->{group} => 'log_popup', 1);

	$this->{request_logging} = $TL->INI->get($this->{group} => 'request_logging', 1);
	$this->{request_popup} = $TL->INI->get($this->{group} => 'request_popup', 1);
	$this->{request_logging_max} = $TL->parseQuantity($TL->INI->get($this->{group} => 'request_logging_max', 0));

	$this->{content_logging} = $TL->INI->get($this->{group} => 'content_logging', 1);
	$this->{content_popup} = $TL->INI->get($this->{group} => 'content_popup', 1);
	$this->{content_logging_max} = $TL->parseQuantity($TL->INI->get($this->{group} => 'content_logging_max', 0));
	$this->{content_popup_max} = $TL->parseQuantity($TL->INI->get($this->{group} => 'content_popup_max', 0));

	$this->{template_logging} = $TL->INI->get($this->{group} => 'template_logging', 1);
	$this->{template_popup} = $TL->INI->get($this->{group} => 'template_popup', 1);

	$this->{db_logging} = $TL->INI->get($this->{group} => 'db_logging', 1);
	$this->{db_popup} = $TL->INI->get($this->{group} => 'db_popup', 1);
	$this->{db_logging_level} = $TL->INI->get($this->{group} => 'db_logging_level', 1);
	$this->{db_profile} = $TL->INI->get($this->{group} => 'db_profile', 1);

	$this->{location_debug} = $TL->INI->get($this->{group} => 'location_debug', 0);

	$this->reset;

	if($this->{enabled}) {
		# 最後に呼ばれるpreRequestハンドラを登録。
		$TL->setHook(
			'preRequest',
			_PRE_REQUEST_HOOK_PRIORITY,
			sub {
				if($this->{request_logging}) {
					$this->__log_request;
				}
			},
		);

		# 最初に呼ばれるinitハンドラを登録。
		$TL->setHook(
			'init',
			_INIT_HOOK_PRIORITY,
			sub {
				# 自分自身をContentFilterとして登録。
				$TL->setContentFilter(
					[__PACKAGE__, _OUTPUT_FILTER_PRIORITY], this => $this
				);
			},
		);

		if($this->{warn_logging} or $this->{warn_popup}) {
			$SIG{__WARN__} = sub {
				my $msg = shift;

				Tripletail::_isa($msg, 'Tripletail::Error') or $msg = $TL->newError(warn => $msg);

				if($this->{warn_logging}) {
					$TL->_log(__PACKAGE__, "Warn: $msg");
				}

				if($this->{warn_popup}) {
					push @{$this->{warn_log}}, $msg;
				}
			};
		}
	}

	$this;
}

sub reset {
	my $this = shift;

	$this->{header} = undef;
	$this->{header_buf} = '';
	$this->{filter_buf} = '';
	$this->{db_log} = [];
	$this->{db_log_data} = {};
	$this->{dl_log} = [];
	$this->{form_log} = [];
	$this->{tl_log} = [];
	$this->{warn_log} = [];
	$this->{template_log} = [];
	$this->{explain_cache} = {};
	$this->{popup} = [];
}

sub __log_request {
	my $this = shift;

	# $TL->CGIの内容と%ENVの内容をログに吐く。
	my $log = '';

	if($TL->{CGIORIG}) {
		foreach my $key (sort $TL->{CGIORIG}->getKeys) {
			foreach my $value ($TL->{CGIORIG}->getValues($key)) {
				$log .= "[CGI:$key] $value\n";
			}
		}
	}

	foreach my $key (sort keys %ENV) {
		$log .= "[ENV:$key] $ENV{$key}\n";
	}

	my $lim = $this->{request_logging_max};
	if($lim and length($log) > $lim) {
		substr($log, $lim) = '...';
	}
	$TL->_log(__PACKAGE__, "Request Log:\n$log");
}

#--------- Tripletail::Template専用
sub _templateLog {
	my $this = shift;
	# node => Tripletail::Template::Node
	# type => new / expand / add / setForm / extForm/ addHiddenForm / addSessionCheck / toStr / flush
	#
	# ---[new]
	# 追加引数無し
	#
	# ---[expand]
	# args => HASH Ref
	# any  => 真偽値
	#
	# ---[setattr]
	# args => HASH Ref
	#
	# ---[add]
	# 追加引数無し
	#
	# ---[setForm]
	# form => Tripletail::Form
	# name => フォーム名
	#
	# ---[extForm]
	# name => フォーム名
	#
	# ---[addHiddenForm]
	# form => Tripletail::Form
	# name => フォーム名
	#
	# ---[addSessionCheck]
	# name => フォーム名
	#
	# ---[toStr]
	# 追加引数無し
	#
	# ---[flush]
	# 追加引数無し

	if(!$this->{enabled}
	|| (!$this->{template_popup} && !$this->{tamplate_logging})
	|| !$this->{template_log}) {
		return $this;
	}

	my $opts = { @_ };
	my $node = $opts->{node};

	# nodeはTripletail::Templateオブジェクトでなくノードパスとする。(/foo/bar形式)
	$opts->{node} = $node->_nodePath;

	# "fpath"を追加。このテンプレートがファイルから生成されたなら、そのファイル名。
	my $root;
	for($root = $node; $root->{parent}; $root = $root->{parent}) {}
	$opts->{fpath} = defined $root->{fpath} ? $root->{fpath} : '(file path unknown)';

	# formがあれば、それのcloneを保持。
	my $form = $opts->{form};
	if($form) {
		$opts->{form} = $form->clone;

		if(!length($opts->{name})) {
			$opts->{name} = '(anonymous form)';
		}
	}

	if($this->{template_popup}) {
		push @{$this->{template_log}}, $opts;
	}
	if($this->{template_logging}) {
		my $params_dump = '';
		if($opts->{type} eq 'expand') {
			$params_dump .= sprintf("Any: %d\n", $opts->{any});
		}
		if($opts->{type} eq 'setForm' || $opts->{type} eq 'addHiddenForm') {
			$params_dump .= sprintf("Form Name: %s\n", $opts->{name});
			foreach my $key ($opts->{form}->getKeys) {
				$params_dump .= sprintf("  %s = %s\n", $key, $opts->{form}->get($key));
			}
		}
		if($opts->{type} eq 'extForm') {
			$params_dump .= sprintf("Form Name: %s\n", $opts->{name});
		}
		if($opts->{type} eq 'addSessionCheck') {
			$params_dump .= sprintf("Form Name: %s\n", $opts->{name});
		}
		if($opts->{type} eq 'expand' || $opts->{type} eq 'setAttr') {
			foreach my $key (sort keys %{$opts->{args}}) {
				my $val = $opts->{args}{$key};
				defined($val) or $val = '(null)';
				$params_dump .= sprintf("  %s = %s\n", $key, $val);
			}
		}

		$TL->_log(
			__PACKAGE__,
			sprintf(
				"Template Trace [TYPE:$opts->{type}][FPATH:$opts->{fpath}][NODE:$opts->{node}]\n".
				"%s",
				$params_dump,
			)
		);
	}

	$this;
}

#--------- Tripletail::DB専用
sub _dbLog {
    my $this = shift;
    my $opts = shift;

    if (!$this->{enabled}
    || (!$this->{db_popup} && !$this->{db_logging})
    || !$this->{db_log}) {
        return $this;
    }

	# パラメータはData::Dumperでのダンプを保存しておく。
	my $params_dump = Data::Dumper->new([$opts->{params}])
		->Indent(0)->Terse(1)->Deepcopy(1)->Dump;

	if($this->{db_logging}
	&& ($this->{db_profile} >= 1
	|| $this->{db_logging_level} >= 1)) {
		$TL->_log(
			__PACKAGE__,
			sprintf(
				"DB Trace [Map: %s][Set: %s][DB: %s][ID: %d]\n".
				"Elapsed: %s seconds\n".
				"Query:\n".
				"%s\n".
				"Parameters:\n".
				"%s",
				$opts->{group},
				$opts->{set},
				$opts->{db},
				$opts->{id},
				$opts->{elapsed},
				$opts->{query},
				$params_dump,
			)
		);
	}

    if ($Tripletail::IN_EXTENT_OF_STARTCGI) {
        
        push @{$this->{db_log}}, {
            group   => $opts->{group},
            set     => $opts->{set},
            db      => $opts->{db},
            id      => $opts->{id},
            query   => $opts->{query},
            params  => $params_dump,
            elapsed => $opts->{elapsed},
            error   => $opts->{error},
        };

        push(@{$this->{db_log_data}{$opts->{id}}}, $opts->{names});
    }

	$this;
}

sub _dbLogData {
    my $this = shift;
    my $opts = shift;

    if (!$this->{enabled}
    || (!$this->{db_popup} && !$this->{db_logging})
    || !$this->{db_log}
    || ($this->{db_logging_level} <= 1)) {
        return $this;
    }

	my $dump;
	my $data;
	if(ref($opts->{data}) eq 'ARRAY') {
		foreach my $data (@{$opts->{data}}) {
			$dump = (defined($data) ? $data : '(undef)') . "\n";
		}
		$data = [ @{$opts->{data}} ];
	} elsif(ref($opts->{data}) eq 'HASH') {
		$this->{db_log_data}{$opts->{id}}[0] = [ sort keys %{$opts->{data}} ];
		$data = [];
		foreach my $key (sort keys %{$opts->{data}}) {
			push(@$data, $opts->{data}{$key});
			$dump .= $key . ': ' . (defined($opts->{data}{$key}) ? $opts->{data}{$key} : '(undef)' ) . "\n";
		}
	}

	if($this->{db_logging} && $this->{db_logging_level} >= 2) {
		$TL->_log(
			__PACKAGE__,
			sprintf("DB Trace [ID: %d]\n%s", $opts->{id}, $dump)
		);
	}

	push(@{$this->{db_log_data}{$opts->{id}}}, $data);
	$this;
}

#--------- Tripletail::Form専用

sub _formLog {
	my $this = shift;
	my $opts = { @_ };

	if (!$this->{enabled}
	|| !$this->{request_logging}
	|| !$this->{request_popup}) {
		return $this;
	}

	# スタックを辿り、最初に現れたTripletail::以外のパッケージが作ったフレームを見て、
	# ファイル名と行番号を得る。
	my $loc = '';
	for(my $i = 0;; $i++) {
		my ($pkg, $fname, $lineno) = caller $i;
		if($pkg !~ m/^Tripletail::/) {
			$fname =~ m!([^/]+)$!;
			$fname = $1;

			$loc = sprintf '%s:%d', $fname, $lineno;

			last;
		}
	}

	my $log = '';
	my $data = '';

	$log .= "Type: $opts->{type}\n";
	$log .= "Loc: $loc\n";

	if(exists($opts->{key})) {
		$data .= "Key: $opts->{key}\n";
	}
	if(exists($opts->{value})) {
		$data .= "Value: $opts->{value}\n";
	}
	if(exists($opts->{data})) {
		my $data_dump = Data::Dumper->new([$opts->{data}])
			->Indent(0)->Terse(1)->Deepcopy(1)->Dump;
		$data .= "Data: $data_dump\n";
	}
	if(exists($opts->{form})) {
		my $form_dump = Data::Dumper->new([$opts->{form}])
			->Indent(0)->Terse(1)->Deepcopy(1)->Dump;
		$data .= "Form: $form_dump\n";
	}

	if($this->{request_logging}) {
		$TL->_log(__PACKAGE__, "Form Log:\n$log$data");
	}

	if($this->{request_popup}) {
		push @{$this->{form_log}}, {
			type  => $opts->{type},
			loc   => $loc,
			data  => $data,
		};
	}

	$this;
}

#--------- $TL->log
sub _tlLog {
	my $this = shift;
	my $opts = { @_ };

	if (!$this->{enabled}
	|| !$this->{log_popup}
	|| !$this->{tl_log}) {
		return $this;
	}

	my @time = localtime;
	$time[5] += 1900;
	$time[4]++;

	push @{$this->{tl_log}}, {
		group => $opts->{group},
		log   => $opts->{log},
		time  => sprintf(
			'%04d-%02d-%02d %02d:%02d:%02d',
			@time[5, 4, 3, 2, 1, 0],
		),
	};
	$this;
}

#--------- Tripletail::startCgi

sub _implant_disperror_popup {
	my $this = shift;

	$this->__db_explain;

	if($this->{enabled}
	&& $this->{popup}
	&& $this->{popup_type} ne 'none') {
		$this->__implant_template_popup;
		$this->__implant_warn_popup;
		$this->__implant_db_popup;
		$this->__implant_log_popup;
		$this->__implant_request_popup;
		$this->__implant_content_popup;
		$TL->dump(POPUP => $this->{popup});
		$TL->dump(POPUPOBJ => $this);

		my $output = $this->__flush_popup;
		$this->reset;
		return $output;
	}

	$this->reset;

	'';
}

#--------- Tripletail::Filter
sub _new {
	my $class = shift;
	my $opts = { @_ };

	$opts->{this};
}

sub print {
	my $this = shift;
	my $data = shift;

	if(!$this->{enabled}) {
		return $data;
	}

	$this->{filter_buf} .= $data;

	if( $this->{popup_type} eq 'none' )
	{
		return $data;
	}else
	{
		# buffering to rewrite after data gathered.
		return '';
	}
}

sub flush {
	my $this = shift;

	$this->__db_explain;

	if($this->{content_logging}) {
		my $content = $this->{filter_buf};
		my $lim = $this->{content_logging_max};
		if($lim && length($content) > $lim) {
			substr($content, $lim) = '...';
		}
		$TL->_log(__PACKAGE__, "Content Log:\n$content");
	}

	my $data = $this->{filter_buf}; # ローカルなコピー

	while($data =~ s/^(.*?(?:\r?\n|\r))//) {
		$this->{header_buf} .= $1;

		if($this->{header_buf} =~ m/(?:\r?\n|\r){2}$/) {
			# 二つ連続した改行コードで終わっている => ヘッダの終わり
			$this->{header} = {};
			foreach(split /\r?\n|\r/, $this->{header_buf}) {
				if(m/^(.+?):\s*(.+)$/) {
					my $array = $this->{header}{lc $1};
					if(!$array) {
						$array = $this->{header}{lc $1} = [];
					}
					push @$array, $2;
				}
			}

			my $ct = $this->{header}{'content-type'}[0];
			if(!$ct || $ct !~ m/html/i) {
				# htmlを出力しているのでなければポップアップは無効に。
				$this->{popup} = undef;
			}

			# charset判定
			my $charset = 'Shift_JIS';
			if($ct && $ct =~ m/charset=([^;]+)/i) {
				$charset = $1;
			}
			$this->{header}{_CHARSET_} = $charset;

			last;
		}
	}

	if($this->{filter_buf} =~ m|</head>|i
	&& $this->{popup}
	&& $this->{popup_type} ne 'none') {
		$this->__implant_template_popup;
		$this->__implant_warn_popup;
		$this->__implant_db_popup;
		$this->__implant_log_popup;
		$this->__implant_request_popup;
		$this->__implant_content_popup;

		my $html = $this->__flush_popup;
		$this->{filter_buf}=~ s|</head>|$html</head>|;
	}

	my $result;
	if( $this->{popup_type} eq 'none' )
	{
		$result = '';
	}else
	{
		# return buffered and rewritten html.
		$result = $this->{filter_buf};
	}

	$this->reset;

	$result;
}

sub __flush_popup {
	my $this = shift;

	if(!@{$this->{popup}}
	|| $this->{popup_type} eq 'none') {
		return '';
	}

	if($this->{popup_type} eq 'multiple') {
		my $script = qq~
<script type="text/javascript"><!--
  var win, doc;
~;
		foreach my $popup (@{$this->{popup}}) {
			# ヘッダとフッタを付ける
			my ($header, $footer) = $this->__tmpl_master_popup;

			$header->node('anchor')->add(
				ID    => $popup->[1],
				TITLE => $popup->[0],
			);

			my $header_popup = $this->__implant_popup(
				funcname => '_tl_debug_HEADER_' . $popup->[1],
				html     => $header->toStr,
				no_push  => 1,
			);
			my $footer_popup = $this->__implant_popup(
				funcname => '_tl_debug_FOOTER_' . $popup->[1],
				html     => $footer->toStr,
				no_push  => 1,
			);

			$script .= qq~
  win = window.open("", "_tl_debug_popup_window_$popup->[1]_", "");
  if (win) {
    doc = win.document;
    doc.open();
~;
			foreach my $parts ($header_popup, $popup, $footer_popup) {
				$script .= $parts->[2]; # 関数定義
				$script .= "  $parts->[1](doc);\n"; # 関数呼出し
			}
			$script .= qq~
    doc.close();
  }
~;
		}
	$script .= qq~
// --></script>
~;
	} elsif($this->{popup_type} eq 'single') {
		# ヘッダとフッタを付ける
		my ($header, $footer) = $this->__tmpl_master_popup;

		foreach my $popup (@{$this->{popup}}) {
			$header->node('anchor')->add(
				ID    => $popup->[1],
				TITLE => $popup->[0],
			);
		}

		unshift @{$this->{popup}},
			$this->__implant_popup(
				funcname => '_tl_debug_HEADER_',
				html     => $header->toStr,
				no_push  => 1,
			);
		push @{$this->{popup}},
			$this->__implant_popup(
				funcname => '_tl_debug_FOOTER_',
				html     => $footer->toStr,
				no_push  => 1,
			);

		my $script = qq~
<script type="text/javascript"><!--
  var win = window.open("", "_tl_debug_popup_window_", "");
  if (win) {
    var doc = win.document;
    doc.open();
~;
		foreach my $popup (@{$this->{popup}}) {
			$script .= $popup->[2]; # 関数定義
			$script .= "  $popup->[1](doc);\n"; # 関数呼出し
		}
		$script .= qq~
    doc.close();
  }
// --></script>
~;

		$script;
	} else {
		die "invalid popup_type: [$this->{popup_tipe}]\n";
	}
}

sub __db_explain {
	my $this = shift;

	if($this->{db_log} && @{$this->{db_log}}) {
		my $explain_id = 0;
		foreach my $entry (@{$this->{db_log}}) {
			next if($entry->{error});
			if($this->__checkIfExplainable($entry->{query})) {
				my $explain = $this->__explain(
					$entry->{group}, $entry->{set}, $entry->{db},
					$entry->{query}, $entry->{params}
				);
				$this->{explain_log}[$explain_id] = $explain;
				$explain_id++;
				my $query = $TL->escapeTag($entry->{query});
				$query =~ s~^\s*|\s*$~~g;

				my $explain_dump = '';
				my @maxcolumn;
				foreach my $row (@$explain) {
					for(my $i = 0; $i < @$row; $i++) {
						$maxcolumn[$i] = length($row->[$i])
							if(!$maxcolumn[$i] || $maxcolumn[$i] < length($row->[$i]));
					}
				}
				foreach my $row (@$explain) {
					$explain_dump .= ' | ';
					for(my $i = 0; $i < @$row; $i++) {
						$explain_dump .= ' ' x ($maxcolumn[$i] - length($row->[$i])) . $row->[$i] . ' | ';
					}
					$explain_dump .= "\n";
				}

				if($this->{db_logging}) {
					$TL->_log(
						__PACKAGE__,
						sprintf(
							"DB Trace [Map: %s][Set: %s][DB: %s][ID: %d]\n".
							"Elapsed: %s seconds\n".
							"Query:\n".
							"%s\n".
							"Parameters:\n".
							"%s\n".
							"Explain:\n".
							"%s",
							$entry->{group},
							$entry->{set},
							$entry->{db},
							$entry->{id},
							$entry->{elapsed},
							$query,
							$entry->{params},
							$explain_dump
						)
					);
				}
			}

		}
	}
}


sub __implant_db_popup {
	my $this = shift;

	if($this->{db_log} and @{$this->{db_log}}
	&& $this->{db_popup}) {
		my $t = $this->__tmpl_db_popup;

		local *expand_table = sub {
			my $node = shift;
			my $fetched = shift;

			foreach my $label (@{$fetched->[0]}) {
				$node->node('label')->add(
					LABEL => $label,
				);
			}

			foreach my $row (@$fetched[1 .. @$fetched-1]) {
				foreach my $column (@$row) {
					$node->node('rows')->node('column')->add(
						COLUMN => (defined $column ? $column : '(NULL)'),
					);
				}
				$node->node('rows')->add;
			}
		};

		my $explain_id = 0;
		my $fetch_id = 0;
		foreach my $entry (@{$this->{db_log}}) {
			if($this->{db_profile} >= 2 && $this->__checkIfExplainable($entry->{query})) {

				next if($entry->{error});

				$t->node('entry')->node('explain-link')->add(
					EXPLAIN_ID => $explain_id,
				);

				my $explain = $this->{explain_log}[$explain_id];

				expand_table(
					$t->node('entry')->node('explain-frame'),
					$explain
				);

				$t->node('entry')->node('explain-frame')->add(
					EXPLAIN_ID => $explain_id,
				);

				$explain_id++;
			}

			if($this->{db_logging_level} >= 2 && $this->__checkIfFetchable($entry->{query})) {
				$t->node('entry')->node('fetch-link')->add(
					FETCH_ID => $fetch_id,
				);

				my $fetched = $this->{db_log_data}{$entry->{id}};

				expand_table(
					$t->node('entry')->node('fetch-frame'),
					$fetched
				);


				$t->node('entry')->node('fetch-frame')->add(
					FETCH_ID => $fetch_id,
				);

				$fetch_id++;
			}

			my $query = $TL->escapeTag($entry->{query});
			$query =~ s~^\s*|\s*$~~g;
			$query =~ s~\n~<br />~g;
			$query =~ s~(--[^\n]+)~<span class="comment">$1</span>~g;
			$query =~ s~(/\*.+?\*/)~<span class="comment">$1</span>~sg;

			my $params = $TL->escapeTag($entry->{params});
			$params =~ s~\s~&nbsp;~g;
			$params =~ s~\n~<br />~g;

			$t->node('entry')->setAttr(
				QUERY       => 'raw',
				PARAMS      => 'raw',
			);
			$t->node('entry')->add(
				GROUP       => $entry->{group},
				SET         => $entry->{set},
				DB          => $entry->{db},
				QUERY       => $query,
				PARAMS      => $params,
				ELAPSED     => "$entry->{elapsed} sec",
			);
		}

		$this->__implant_popup(
			html     => $t->toStr,
			title    => 'DB使用ログ',
			funcname => '_tl_debug_db_popup_',
		);
	}
}

sub __implant_template_popup {
	my $this = shift;

	if($this->{template_log} && @{$this->{template_log}}) {
		my $log = $this->{template_log};
		$this->{template_log} = undef; # これ以降はTempateログを取らない。

		my $t = $this->__tmpl_template_popup;

		foreach my $entry (@$log) {
			my %params = %$entry;

            my $force_defined = sub {
                my $value = shift;

                defined $value ? $value : '(null)';
            };

			if($entry->{type} eq 'expand' || $entry->{type} eq 'setattr') {

                # イテレータをリセットする代わりにコピーを取る。
                my %copy = %{$entry->{args}};
				while (my ($key, $value) = each %copy) {
                    
					defined($value) or $value = '(null)';
					$t->node('entry')->node($entry->{type})->node('arg')->add(
						KEY => $key, VALUE => $force_defined->($value),
					);
				}
				delete $params{args};
			} elsif($entry->{type} eq 'setForm' || $entry->{type} eq 'addHiddenForm') {
				foreach my $key ($entry->{form}->getKeys) {
					foreach my $value ($entry->{form}->getValues($key)) {
						$t->node('entry')->node($entry->{type})->node('pair')->add(
							KEY => $key, VALUE => $force_defined->($value),
						);
					}
				}
				delete $params{form};
			}

			my $type = delete $params{type};
			my $fpath = delete $params{fpath};
			my $node = delete $params{node};

			$t->node('entry')->node($entry->{type})->add(%params);
			$t->node('entry')->add(
				TYPE  => $type,
				FPATH => $fpath,
				NODE  => $node,
			);
		}

		$this->__implant_popup(
			html     => $t->toStr,
			title    => 'テンプレート使用ログ',
			funcname => '_tl_debug_template_popup_',
		);
	}

	$this;
}

sub __implant_warn_popup {
	my $this = shift;

	if($this->{warn_log} && @{$this->{warn_log}}) {
		my $t = $this->__tmpl_warn_popup;

		foreach my $entry (@{$this->{warn_log}}) {
			my $content = $TL->escapeTag($entry);
			$content =~ s~\n~<br />~g;
			$content =~ s~\s~&nbsp;~g;

			$t->node('entry')->setAttr(
				CONTENT     => 'raw',
			);
			$t->node('entry')->add(
				CONTENT     => $content,
			);
		}

		$this->__implant_popup(
			html     => $t->toStr,
			title    => 'warn',
			funcname => '_tl_debug_warn_popup_',
		);
	}

	$this;
}

sub __implant_log_popup {
	my $this = shift;

	if($this->{tl_log} && @{$this->{tl_log}}) {
		# $TL->logのログ
		my $log = $this->{tl_log};
		$this->{tl_log} = undef; # これ以降は$TL->logログを取らない

		my $t = $this->__tmpl_log_popup;

		foreach my $entry (@$log) {
			my $content = $TL->escapeTag($entry->{log});
			$content =~ s~[ \t]~&nbsp;~g;
			$content =~ s~\n~<br />~g;

			$t->node('entry')->setAttr(
				CONTENT     => 'raw',
			);
			$t->node('entry')->add(
				GROUP       => $entry->{group},
				TIME        => $entry->{time},
				CONTENT     => $content,
			);
		}

		$this->__implant_popup(
			html     => $t->toStr,
			title    => '$TL->logログ',
			funcname => '_tl_debug_log_popup_',
		);
	}

	$this;
}

sub __implant_request_popup {
	my $this = shift;

	if($this->{request_popup} && $TL->{CGIORIG}) {
		# $TL->CGIの内容と%ENVの内容
		my $t = $this->__tmpl_request_popup;

		foreach my $key (sort $TL->{CGIORIG}->getKeys) {
			foreach my $value (sort $TL->{CGIORIG}->getValues($key)) {
				$t->node('cgi')->add(
					KEY   => $key,
					VALUE => $value,
				);
			}
		}

		$t->node('form')->setAttr(DATA => 'br');
		foreach my $data (@{$this->{form_log}}) {
			$t->node('form')->add($data);
		}

		foreach my $key (sort keys %ENV) {
			foreach my $value ($ENV{$key}) {
				$t->node('env')->add(
					KEY   => $key,
					VALUE => $value,
				);
			}
		}

		$this->__implant_popup(
			html     => $t->toStr,
			title    => 'リクエスト情報',
			funcname => '_tl_debug_request_popup_',
		);
	}

	$this;
}

sub __implant_content_popup {
	my $this = shift;

	if($this->{content_popup} && length($this->{filter_buf})) {
		my $t = $this->__tmpl_content_popup;

		my $content = $this->{filter_buf};
		my $lim = $this->{content_popup_max};
		if($lim && length($content) > $lim) {
			substr($content, $lim) = '...';
		}
		$content = $TL->charconv($content, 'auto' => 'UTF-8');

		$t->setAttr(VALUE => 'br');
		$t->expand(VALUE => $content);

		$this->__implant_popup(
			html     => $t->toStr,
			title    => 'コンテンツ情報',
			funcname => '_tl_debug_content_popup_',
		);
	}

	$this;
}

sub __implant_popup {
	my $this = shift;
	my $opts = do {
		my %args = @_;
		\%args;
	};
	my $funcname = $opts->{funcname};
	my $html = $opts->{html};
	my $title = $opts->{title};
	my $no_push = $opts->{no_push};

	my $script = "  function $funcname(doc) {\n";
	if(defined($title)) {
		$script .= qq{    doc.writeln("    <h1 id=\\"$funcname\\">$title</h1>");\n};
	}
	my $functions;
	my $line = 0;
	foreach(split /\r?\n|\r/, $html) {
		if( (++$line%1000)==0 )
		{
			if( !$functions )
			{
				$script =~ s/^  function (\w+)/  function $1_001/;
				$functions = 1;
			}
			++$functions;
			$script .= "  }\n";
			my $fname = sprintf('%s_%03d',$funcname,$functions);
			$script .= "  function $fname(doc) {\n";
		}
		# ポップアップウインドウのHTMLの全ての行を、
		# doc.writeln("..."); という形にする。
		s/\\/\\\\/g;
		s/"/\\"/g;
		s/--/"+"-"+"-"+"/g;
		s!//!"+"/"+"/"+"!g;
		s!</script>!"+"<"+"/sc"+"ript>"+"!g;
		$script .= qq{    doc.writeln("$_");\n};
	}
	$script .= "  }\n";
	if( $functions )
	{
		$script .= "  function $funcname(doc) {\n";
		foreach my $i (1..$functions)
		{
			my $fname = sprintf('%s_%03d', $funcname, $i);
			$script .= "    $fname(doc);\n";
		}
		$script .= "  }\n";
	}
	
	$script =~ s/\n/\r\n/g;
	$script = $TL->charconv($script, 'utf8' => $this->{header}{_CHARSET_});
	
	my $popup = [$title, $funcname, $script];
	if(!$no_push) {
		push @{$this->{popup}}, $popup;
	}

	$popup;
}

#--------------- DB関連

sub __checkIfExplainable {
	my $this = shift;
	my $sql = shift;

	$this->__findCommand($sql) eq 'SELECT';
}

sub __checkIfFetchable {
	my $this = shift;
	my $sql = shift;

	my $allowed = {
		SHOW => 1,
		EXPLAIN => 1,
		DESC => 1,
		SELECT => 1,
	};

	$allowed->{$this->__findCommand($sql)};
}

sub __findCommand {
	my $this = shift;
	my $sql = shift;
	while(1) {
		$sql =~ s/^\s*//;

		if($sql =~ s|^/\*.+?\*/||) {
			next;
		} elsif($sql =~ s,--.+?(?:\r?\n|\r),,) {
			next;
		} elsif($sql =~ m|^(\w+)|) {
			return uc $1;
		} else {
			die __PACKAGE__."#__findCommand: found no commands in sql [$sql] (SQLからコマンドを見つけることができませんでした)\n";
		}
	}
}

sub __explain {
	my $this = shift;
	my $group = shift;
	my $dbset = shift;
	my $dbname = shift; # undef可
	my $query = shift;
	my $params = shift;

	if(!$this->{explain_cache}{$group}) {
		$this->{explain_cache}{$group} = {};
	}

	if(my $cached = $this->{explain_cache}{$group}{$query}) {
		return $cached;
	}

	$this->{explain_cache}{$group}{$query} =
	$this->__executeSql($group, $dbset, $dbname, "EXPLAIN $query", $params);
}

sub __executeSql {
	my $this = shift;
	my $group = shift;
	my $dbset = shift;
	my $dbname = shift; # undef可
	my $query = shift;
	my $params = shift;

	# 内部用のクエリはデバッグログに残さない
	local($this->{db_log});
	$this->{db_log} = undef;

	$params = do {
        local($@);
        eval $params; # Dumpしてあったものを戻す
    };
    
	my $DB = $TL->getDB($group);

	my $sth = $DB->execute(\$dbset => $query, @$params);

	my $result = [];
	$result->[0] = [ @{$sth->nameArray} ]; # 0番目がフィールド名

	while(my $row = $sth->fetchArray) {
		foreach my $col (@$row) {
			$col = '(null)' if(!defined($col));
		}
		push @$result, [ @$row ];
	}

	$result;
}

#------------- CSS 及びテンプレート

sub __popup_css {
	my $this = shift;
	my $is_opera = ($ENV{HTTP_USER_AGENT}||'')=~/Opera/i;
	qq{
    <style>
      * {
        margin: 0;
        padding: 0;
      }

      body {
        font-size: 100%;
        color: black;
        background-color: white;
        text-align: left;
        margin-bottom: 50px;
@{[ $is_opera ? '        overflow: scroll;' : '' ]}
      }

      a {
        text-decoration: none;
        color: #880000;
        border-color: #660000;
        border-style: dotted;
        border-width: 0 0 1px 0;
      }

      h1 {
        font-size: 150%;
        text-align: left;

        color: #eecc22;
        border-color: #eecc22;
        border-width: 1px;
        border-style: dashed;
        padding: 3px;

        margin-top: 60px;
        margin-bottom: 0;
        margin-right: 2%;
        margin-left: 2%;
      }

      h2 {
        font-size: 130%;
        color: #888833;
        background-color: #ffeebb;
        border-style: solid;
        border-width: 2px 2px 2px 10px;
        border-color: #eecc22;
        padding: 3px;

        margin-top: 10px;
        margin-bottom: 10px;
        margin-right: 2%;
        margin-left: 2%;
      }

      h1 + table {
        margin-top: 10px;
      }

      table {
        width: 94%;
        margin-left: 2%;
        margin-right: 2%;
      }

      table table {
        width: 100%;
        background-color: #ddddbb;
        margin: 2px;
      }

      td, th {
        background-color: #ffffdd;
        border-style: dashed;
        border-width: 1px;
        border-color: #ddddbb;
        padding: 2px;
        margin: 2px;
      }
      th {
        font-weight: bold;
        background-color: #eeeecc;
      }

      li {
        margin: 3px 0 2px 0;
      }

      dt, dl {
        margin: 1px;
        padding: 2px;
      }
      dt {
        font-weight: bold;
      }
      dd {
        margin-left: 30px;
      }
      dl dl {
        margin-left: 30px;
      }
      dl dl dt {
        background-color: #eeeecc;
      }
      dl dl dd {
        background-color: #ffffee;
        margin-left: 1px;
      }

      ol, ul {
        list-style-type: none;
      }

      .comment {
        font-size: 90%;
        color: #aa0000;
      }

      .initial-hidden {
        display: none;
      }

      .controller {
        position: fixed;
        top: 0;
        width: 100%;
        color: #888833;
        background-color: #ffffbb;
        border-style: solid;
        border-width: 0 0 2px 0;
        border-color: #cccc22;
        padding: 3px;

        font-size: 120%;
        font-weight: bold;
      }
      .controller a {
        font-size: 80%;
      }

      .footer {
        position: fixed;
        bottom: 0;
        font-size: 80%;
        color: #888833;
        background-color: #ffffbb;
        border-style: solid;
        border-width: 2px 0 0 0;
        border-color: #cccc22;
        padding: 3px;
        margin: 5px 0 0 0;
      }
    </style>};
}

sub __iframe_css {
	my $this = shift;
	qq{
    <style>
      * {
        margin: 0;
        padding: 0;
      }

      body {
        font-size: 100%;
        color: black;
        background-color: #ffffdd;
        text-align: left;
      }

      table {
        width: 100%;
      }

      td, th {
        background-color: #ffffdd;
        border-style: dashed;
        border-width: 1px;
        border-color: #ddddbb;
        padding: 2px;
        margin: 2px;
      }
    </style>};
}

sub __tmpl_master_popup {
	my $this = shift;
	my $charset = $this->{header}{_CHARSET_} || 'UTF-8';
	my $css = $this->__popup_css;
	my $group = $this->{group};

	my @result;

	push @result, $TL->newTemplate->setTemplate( # ヘッダ
		qq{<?xml version="1.0" encoding="$charset"?>
<!DOCTYPE html
          PUBLIC "-//W3C//DTD XHTML 1.1//EN"
          "http://www.w3.org/TR/xhtml11.dtd">
<html xml:lang="ja" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=$charset" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <title>[Tripletail::Debug] デバッグ情報</title>
    $css
    <script type="text/javascript"><!--
      function scroll_to_anchor(id) {
        var elem = document.getElementById(id);
        window.scroll(0, elem.offsetTop - 60);
      }
    // --></script>
  </head>
  <body>
    <div class="controller">
      <p>[Tripletail::Debug] デバッグ情報</p>
      <p>
        <!begin:anchor>
        <a href="javascript:scroll_to_anchor('<&ID>')"><&TITLE></a>
        <!end:anchor>
      </p>
    </div>
});

	push @result, $TL->newTemplate->setTemplate( # フッタ
		qq{
  <p class="footer">
      このウインドウはTripletail::Debugが表示しています。
      表示をやめるには、 ini ファイル [$group] セクションの enable_debug を無効にして下さい。
    </p>
  </body>
</html>
});

	@result;
}

sub __tmpl_template_popup {
	my $this = shift;

	$TL->newTemplate->setTemplate(qq{
    <table>
      <tr>
        <th>操作</th><th>ファイル</th><th>ノード</th><th>パラメータ</th>
      </tr>
      <!begin:entry>
      <tr>
    <td><&TYPE></td><td><&FPATH></td><td><&NODE></td>
    <td>
      <!begin:new><!end:new>
      <!begin:set><!end:set>
      <!begin:load><!end:load>
      <!begin:setattr>
          <dl>
            <dt>args</dt>
              <dl>
                <!begin:arg>
                <dt><&KEY></dt><dd><&VALUE></dd>
                <!end:arg>
              </dl>
          </dl>
          <!end:setattr>
      <!begin:expand>
          <dl>
            <dt>any</dt><dd><&ANY></dd>
            <dt>args</dt>
              <dl>
                <!begin:arg>
                <dt><&KEY></dt><dd><&VALUE></dd>
                <!end:arg>
              </dl>
          </dl>
          <!end:expand>
          <!begin:add><!end:add>
          <!begin:setForm>
      <dl>
        <dt>name of form</dt><dd><&NAME></dd>
        <dt>content</dt>
              <dl>
                <!begin:pair>
                <dt><&KEY></dt><dd><&VALUE></dd>
                <!end:pair>
              </dl>
      </dl>
          <!end:setForm>
          <!begin:extForm>
      <dl>
        <dt>name of form</dt><dd><&NAME></dd>
      </dl>
          <!end:extForm>
          <!begin:addHiddenForm>
      <dl>
        <dt>name of form</dt><dd><&NAME></dd>
        <dt>content</dt>
              <dl>
                <!begin:pair>
                <dt><&KEY></dt><dd><&VALUE></dd>
                <!end:pair>
              </dl>
      </dl>
          <!end:addHiddenForm>
          <!begin:addSessionCheck>
      <dl>
          <dt>name of form</dt><dd><&NAME></dd>
      </dl>
          <!end:addSessionCheck>
          <!begin:toStr><!end:toStr>
          <!begin:flush><!end:flush>
        </td>
      </tr>
      <!end:entry>
    </table>
});
}

sub __tmpl_request_popup {
	my $this = shift;

	$TL->newTemplate->setTemplate(qq{
    <h2>CGI</h2>
    <table>
      <!begin:cgi>
      <tr><th><&KEY></th><td><&VALUE></td></tr>
      <!end:cgi>
    </table>
    <table>
      <!begin:form>
      <tr><td><&LOC></td><th><&TYPE></th><td><&DATA></td></tr>
      <!end:form>
    </table>

    <h2>ENV</h2>
    <table>
      <!begin:env>
      <tr><th><&KEY></th><td><&VALUE></td></tr>
      <!end:env>
    </table>
});
}

sub __tmpl_content_popup {
	my $this = shift;

	$TL->newTemplate->setTemplate(qq{
    <h2>Content</h2>
    <table>
      <tr><td><&VALUE></td></tr>
    </table>
});
}

sub __tmpl_log_popup {
	my $this = shift;

	$TL->newTemplate->setTemplate(qq{
    <table>
      <tr><th>グループ</th><th rowspan="2">内容</th></tr>
      <tr><th>時刻</th></tr>
      <!begin:entry>
      <tr><td><&GROUP></td><td rowspan="2"><&CONTENT></td></tr>
      <tr><td><&TIME></td></tr>
      <!end:entry>
    </table>
});
}

sub __tmpl_warn_popup {
	my $this = shift;

	$TL->newTemplate->setTemplate(qq{
    <table>
      <tr><th>warnメッセージ</th></tr>
      <!begin:entry>
      <tr><td><&CONTENT></td></tr>
      <!end:entry>
    </table>
});
}

sub __tmpl_db_popup {
	my $this = shift;

	$TL->newTemplate->setTemplate(qq{
    <table>
      <tr>
        <th>グループ</th>
        <th>セット</th>
        <th>コネクション</th>
        <th>クエリ</th>
        <th>パラメータ</th>
        <th>execute実行時間</th>
        <th>詳細</th>
      </tr>
      <!begin:entry>
      <tr>
        <td><&GROUP></td>
        <td><&SET></td>
        <td><&DB></td>
    <td><&QUERY></td>
    <td><&PARAMS></td>
    <td><&ELAPSED></td>
    <td>
      <ul>
        <!begin:explain-link>
        <li>
          <a href="javascript:tl_debug_toggle_display('TL_EXPLAIN_<&EXPLAIN_ID>')">
        Explain
          </a>
        </li>
        <!end:explain-link>
        <!begin:fetch-link>
        <li>
          <a href="javascript:tl_debug_toggle_display('TL_FETCH_<&FETCH_ID>')">
        結果
          </a>
        </li>
        <!end:fetch-link>
      </ul>
    </td>
      </tr>
      <!begin:explain-frame>
      <tr>
    <td colspan="7">
      <div class="initial-hidden" id="TL_EXPLAIN_<&EXPLAIN_ID>">
        <table>
          <tr><!begin:label><th><&LABEL></th><!end:label></tr>
          <!begin:rows>
          <tr><!begin:column><td><&COLUMN></td><!end:column></tr>
          <!end:rows>
        </table>
      </div>
    </td>
      </tr>
      <!end:explain-frame>
      <!begin:fetch-frame>
      <tr>
    <td colspan="7">
      <div class="initial-hidden" id="TL_FETCH_<&FETCH_ID>">
        <table>
          <tr><!begin:label><th><&LABEL></th><!end:label></tr>
          <!begin:rows>
          <tr><!begin:column><td><&COLUMN></td><!end:column></tr>
          <!end:rows>
        </table>
      </div>
    </td>
      </tr>
      <!end:fetch-frame>
      <!end:entry>
    </table>

    <script type="text/javascript"><!--
    function tl_debug_toggle_display(id) {
      var elem = document.getElementById(id);
      if (elem.style.display == "block") {
        elem.style.display = "none";
      }
      else {
        elem.style.display = "block";
      }
    }
    // --></script>
});
}


__END__

=encoding utf-8

=head1 NAME

Tripletail::Debug - TL デバッグ用クラス

=head1 DESCRIPTION

このクラスは C<use Tripletail> 時に自動的に読み込まれる．

L<ini|Tripletail::Ini> で L</"enable_debug"> を0以外にセットすると、
以後デバッグ機能が有効になる。
L<ini|Tripletail::Ini> グループ名は "Debug" でなければならない。

公開されているメソッドは存在しない。

=head2 METHODS

=over 4

=item C<< flush >>

内部メソッド

=item C<< print >>

内部メソッド

=item C<< reset >>

内部メソッド

=back


=head2 Ini パラメータ

=over 4

=item enable_debug

  enable_debug = 1

デバッグ機能を使用するか否か。省略可能。

1の場合、有効。
0の場合、無効。
デフォルトは0。

無効にした場合、全てのデバッグオプションの設定は無効となる。

=item popup_type

  popup_style = single

デバッグ情報のポップアップ表示の機能選択。可能な値は C<'none'>, C<'single'>, C<'multiple'> 。省略可能。

=over 8

=item none

　ポップアップ表示しない（デフォルト）
　noneに設定した場合、xxxxxx_popupでポップアップを指定しても無視される。

=item single

一つのウインドウに全情報を表示

=item multiple

表示する情報の個数分のウインドウを表示

=back

=item warn_logging

  warn_logging = 1

warnメッセージをログに残すか否か。省略可能。

1の場合、残す。
0の場合、残さない。
デフォルトは1。

=item warn_popup

  warn_popup = 1

warnメッセージをポップアップ表示するように出力を加工するか否か。省略可能。

1の場合、加工する。
0の場合、加工しない。
デフォルトは1。

=item log_popup

  log_popup = 1

L<< $TL->log|Tripletail/"log" >> されたログをポップアップ表示するように出力を加工するか否か。省略可能。

1の場合、加工する。
0の場合、加工しない。
デフォルトは1。

=item request_logging

  request_logging = 1

受け取ったリクエストデータの内容と、$CGI への変更履歴をログに残すか否か。省略可能。

1の場合、残す。
0の場合、残さない。
デフォルトは1。

=item request_logging_max

  request_logging_max = 100K

１回に出力するログの最大サイズの指定。0で無制限。省略可能。

デフォルトは0。

=item request_popup

  request_popup = 1

受け取ったリクエストデータの内容と、$CGI への変更履歴を別ウィンドウでポップアップするように、出力を加工するか否か。省略可能。

1の場合、加工する。
0の場合、加工しない。
デフォルトは1。

=item content_logging

  content_logging = 1

応答コンテンツをログに残すか否か。省略可能。

1の場合、残す。
0の場合、残さない。
デフォルトは1。

=item content_logging_max

  content_logging_max = 100K

１回のログの最大サイズ。0で無制限。省略可能。

デフォルトは0。

=item content_popup

  content_popup = 1

応答コンテンツを別ウィンドウでポップアップするように出力を加工するか否か。省略可能。

1の場合、加工する。
0の場合、加工しない。
デフォルトは1。

=item content_popup_max

  content_logging_max = 100K

１回のポップアップで表示する最大サイズ。0で無制限。省略可能。

デフォルトは0

=item template_logging

  template_logging = 1

使用した L<テンプレート|Tripletail::Template> ファイル名と、展開の内容をログに残すか否か。省略可能。

1の場合、残す。
0の場合、残さない。
デフォルトは1。

=item template_popup

  template_popup = 1

使用した L<テンプレート|Tripletail::Template>ァイル名と、展開の内容を、別ウィンドウでポップアップするように出力を加工するか否か省略可能。

1の場合、加工する。
0の場合、加工しない。
デフォルトは1。

ポップアップで表示するためには、出力するコンテンツに </head> を含む HTML が存在しなければならない。

=item db_logging

  db_logging = 1

L<DB|Tripletail::DB> へのクエリをログに残すか否か。省略可能。

1の場合、残す。
0の場合、残さない。
デフォルトは1。

db_logging_level及びdb_profileにて残すログの内容を設定可能。

=item db_popup

  db_popup = 1

L<DB|Tripletail::DB> へのクエリログをポップアップ表示するように出力を加工するか否か。省略可能。

1の場合、加工する。
0の場合、加工しない。
デフォルトは1。

=item db_logging_level

  db_logging_level = 2

L<DB|Tripletail::DB> へのクエリをログに残す際、応答内容をどの程度残すかを設定する。省略可能。

1の場合、DBへ発行したクエリ文と実行時間を残す。
2の場合、DBへ発行されたクエリ文と実行時間に加え、応答内容を残す。
デフォルトは1。

=item db_profile

  db_profile = 1

L<DB|Tripletail::DB> へのクエリをログに残す際、実行計画をどこまで残すかを設定する。省略可能。

1の場合、DBへ発行したクエリ文と実行時間を残す。
2の場合、DBへ発行されたクエリ文と実行時間に加え、実行計画を残す。
デフォルトは1。

=item location_debug

  location_debug = 1

L<< $TL->location|Tripletail/"location" >> でリダイレクトする際に、Locationヘッダの代わりに、HTML画面を表示する。
利用しない場合、すぐにリダイレクトするため、デバッグ情報を確認する時間が取れない。

1の場合、HTML画面を表示する。
0の場合、HTML画面を表示せず、Locationヘッダを出力する。
デフォルトは0。

=item 設定例

  [Debug]
  enable_debug=1
  popup_type=single
  warn_logging=1
  warn_popup=1
  log_popup=1
  request_logging=0
  request_logging_max=0
  request_popup=1
  content_logging=0
  content_logging_max=0
  content_popup=1
  content_popup_max=0
  template_logging=0
  template_popup=0
  db_logging=1
  db_popup=1
  db_logging_level=1
  db_profile=1
  location_debug=1

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::DB>

=item L<Tripletail::Filter>

=item L<Tripletail::InputFilter>

=item L<Tripletail::Template>

=back

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
