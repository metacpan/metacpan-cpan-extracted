# -----------------------------------------------------------------------------
# Tripletail::Error - 内部クラス
# -----------------------------------------------------------------------------
package Tripletail::Error;
use strict;
use warnings;
use Data::Dumper;
#use Smart::Comments;
use Tripletail;
use overload
  '""'     => \&_stringify,
  fallback => 1;

sub _POST_REQUEST_HOOK_PRIORITY() { 2_000_000_000 } # Debug よりも後

my $PADWALKER_AVAILABLE; # PadWalker が利用可能であるかどうか。undef / 1 / 0

my $VARIABLE_LENGTH_LIMIT = 32 * 1024; # 1変数あたりの表示する最大長 (バイト)

my $DEFAULT_ERROR_TEMPLATE = &__load_default_error_template();

my $TRACE_ALLOWANCE_OF_CURRENT_REQUEST;

# 最後に発生した DB のエラー。内容は任意のハッシュ。
our $LAST_DB_ERROR;

1;

# -----------------------------------------------------------------------------
# $TL->newError($type, $msg);
# $TL->newError($type, $msg, $title);
#
sub _new {
	# スタックトレースを持った例外オブジェクトを生成する。
	# 返されたインスタンスは "" 演算子によって文字列化が可能である。
	my $class = shift;
	my $type = shift; # 'error' / 'warn' / 'file-update' / 'memory-leak'
	my $msg = shift; # $@
	my $title = shift; # 任意の文字列
	my $this = bless {} => $class;

	$this->{message} = $msg;
	$this->{type} = $type;
	$this->{title} = $title || "Error: $msg";
	$this->{frames} = []; # Tripletail::Error::Frame
	$this->{source} = {}; # ファイルパス => 中身
	$this->{show_trace} = undef;
	$this->{show_vars}  = undef;
	$this->{show_src}   = undef;
	$this->{suppress_internal} = 1;
	$this->{appear} = 'sudden'; # sudden/usertrap
	$this->{on_require} = undef; # undef/1.
	$this->{http_status_code} = undef;
	$this->{http_status_line} = undef;
	$this->{db_error} = undef;

	if( $msg =~ /: we are getting too large (file|request) which exceeds the limit. |: Post Error: request size was too big to accept. / )
	{
		$this->{http_status_code} = 413;
		$this->{http_status_line} = "413 Request Entity Too Large";
	}else
	{
		$this->{http_status_code} = 500;
		$this->{http_status_line} = "500 Internal Server Error";
	}

	my $switch = $TL->INI->get(TL => 'stacktrace', 'onlystack');
	if ($switch eq 'none') {
		# skip
	}
	elsif ($switch eq 'onlystack') {
		$this->{show_trace} = 1;
	}
	elsif ($switch eq 'full') {
		$this->{show_trace} = 1;
		$this->{show_vars}  = 1;
		$this->{show_src}   = 1;
	}
	else {
		die "Unknown stacktrace type: $switch (stacktraceの指定が不正です)";
	}

	if ($this->{show_trace} and not $this->is_trace_allowed) {
		$this->{show_trace} = undef;
	}

	if ($this->{show_trace}) {
		# TLのdieハンドラから呼ばれるかも知れないので、無限再帰を防ぐ。
		local $SIG{__DIE__} = 'DEFAULT';
		local($@);
		eval {
			$this->_fetch_frames;
		};
		if ($@) {
			print STDERR $@;
			exit 1;
		}
	}

    if (our $LAST_DB_ERROR) {
        $this->{db_error} = $LAST_DB_ERROR->force;
    }

    $TL->setHook(
        'postRequest',
        _POST_REQUEST_HOOK_PRIORITY,
        sub {
            $TRACE_ALLOWANCE_OF_CURRENT_REQUEST = undef;
        });

	$this;
}

sub type {
	shift->{type};
}

sub title {
	shift->{title};
}

sub message {
	my $this = shift;
	my $new  = shift;

	if ($new) {
		$this->{message} = $new;
	}
	$this->{message};
}

sub _fetch_frames {
	my $this = shift;

	if (not defined $PADWALKER_AVAILABLE) {
		eval {
			require PadWalker;
		};
		$PADWALKER_AVAILABLE = ($@ ? 0 : 1);
	}

	my $found_die_handler;
	my $level = 0;
	my $pad_level = 0;
	
	$this->{appear} = 'sudden'; # sudden/usertrap
	for (my $i = 0; my @c = caller $i; $i++) {
		my ($package, $filename, $line, $sub, $hasargs,
			$wantarray, $evaltext, $is_require, $hints, $bitmask) = @c;

		if ($sub =~ /^Tripletail::__die_handler_for_(localeval|startup)$/) {
			$sub = 'Tripletail::((die handler))';
			
			$found_die_handler = 1;
		}
		elsif ($sub eq '(eval)') {
			if ($is_require) {
				$sub = "((require/use $package))";
				if( $this->{appear} eq 'sudden' )
				{
					$this->{on_require} = 1;
				}
			}
			else {
				if( $this->{appear} eq 'sudden' && $package!~/^Tripletail\b/ )
				{
					$this->{appear} = 'usertrap';
				}
				if (defined $evaltext) {
					$evaltext =~ s!\s*|\s*!!g;
					if (length($evaltext) > 30) {
						substr($evaltext, 27) = '...';
					}
					$sub = sprintf '((eval "%s"))', $evaltext;
				}
				else {
					$sub = '((eval))';
				}
			}
			$sub = $package . '::' . $sub;
		}

		if ($hasargs) {
			$pad_level++;
		}
		else {
			next; # 関数呼出しのみ考慮。evalで作られたフレームは飛ばす。
			# peek_my/peek_our でも eval のフレームは飛ばされる。
			# (pod には取る引数が caller と同じだと書いてあるけど嘘…)
		}

		$this->{suppress_internal} and not $found_die_handler
		  and next; # まだ die ハンドラが見えていない

		my $frame = Tripletail::Error::Frame->new(
			$level++, $filename, $line, $sub);

		if ($this->{show_vars} and $PADWALKER_AVAILABLE) {
			# ローカル変数を取得
			my $mines = PadWalker::peek_my($pad_level);
			my $ours  = PadWalker::peek_our($pad_level);

			while (my ($name, $ref) = each %$mines) {
				$frame->set_variable("my $name", $ref);
			}

			while (my ($name, $ref) = each %$ours) {
				$frame->set_variable("our $name", $ref);
			}

			#my @args;
			#do {
			#	package DB;
			#	@c = caller $i + 1;
			#	@args = @DB::args;
			#};
			#$frame->set_variable('@_', \@args);
		}

		if ($this->{show_src}) {
			# ソースコードを取得
			if (not exists $this->{source}{$filename}) {
				my $src;
				if (-r $filename) {
					$src = $TL->readTextFile($filename);
				}
				$this->{source}{$filename} = $src;
			}
		}

		push @{$this->{frames}}, $frame;
	}
}

sub is_trace_allowed {
	my $this = shift;

    if (defined(my $ret = $TRACE_ALLOWANCE_OF_CURRENT_REQUEST)) {
        $ret;
    }
    else {
        my $ret;

        my $masks = $TL->INI->get(TL => stackallow => '');

        if (my $remote = $ENV{REMOTE_ADDR}) {
            if($TL->newValue->set($remote)->isIpAddress($masks)) {
                # マッチした
                $TL->log(__PACKAGE__,
                         "[$remote] matched to [$masks]. stack trace is allowed");
                
                $ret = 1;
            }
            else {
                # どれにもマッチしなかった。
                $TL->log(
                    __PACKAGE__, sprintf(
                        "[%s] didn't match to any of [%s]. stack trace is not allowed",
                        $remote, $masks));
                
                $ret = 0;
            }
        }
        else {
            # CGI として起動されたのではないようなので、
            # 無条件にスタックトレースの表示を許す。
            $TL->log(__PACKAGE__,
                     "\$ENV{REMOTE_ADDR} is not set. stack trace is allowed.");

            $ret = 1;
        }

        $TRACE_ALLOWANCE_OF_CURRENT_REQUEST = $ret;
        $ret;
    }
}

sub toHtml {
	my $this = shift;

	my $t = $TL->newTemplate->setTemplate($DEFAULT_ERROR_TEMPLATE);

	if ($this->{show_trace} and $this->is_trace_allowed) {
		my $msg = $this->{message};
		if( my $dberr = $this->{db_error} )
		{
			$msg .= "\nDB Error: ".Data::Dumper->new([$dberr])->Terse(1)->Dump();
		}
		$t->node('style-for-detail')->add({});
		$t->node('detail')->setAttr({
			MESSAGE => 'br',
		})->expand(
			TYPE    => $this->{type},
			MESSAGE => "$msg",
		   );
	}
	else {
		$t->node('style-for-header-only')->add({});
		$t->node('header-only')->setAttr({
			MESSAGE => 'br',
		})->add(
			TYPE    => $this->{type},
			MESSAGE => "$this->{message}",
		   );

		$t->expand(
            SELECTED_LV  => 0,
			LAST_HILITED => 0,
		   );
		return $t->toStr;
	}

    # 初期状態で選択するスタックレベルは、０から順にフレームを辿って行
    # き、最初に見付けた Tripletail:: 名前空間外のフレームのレベルとする。但し
    # 全てのフレームが Tripletail:: であれば、レベル０を使用する。
    my $default_level = 0;
    for (my $i = 0; $i < @{$this->{frames}}; $i++) {
		my $frame = $this->{frames}[$i];
		my $next = ($i == @{$this->{frames}} - 1 ?
					  undef : $this->{frames}[$i + 1]);
        
        if ($next and $next->func !~ m/^Tripletail::/) {
            $default_level = $i;
            last;
        }
    }

	for (my $i = 0; $i < @{$this->{frames}}; $i++) {
		my $frame = $this->{frames}[$i];
		my $next = ($i == @{$this->{frames}} - 1 ?
					  undef : $this->{frames}[$i + 1]);

		if ($i == $default_level) {
			$t->node('detail')->node('frame')->node('selected')->add;
		}

		$t->node('detail')->node('frame')->add(
			LEVEL  => $i,
			FILE   => $frame->fpath,
			LINE   => $frame->line,
			CALLER => (defined $next ? $next->func : '((basement))'),
			CALLEE => $frame->func,
		   );
	}

	# JavaScript から読む為のデータを展開
	for (my $i = 0; $i < @{$this->{frames}}; $i++) {
		my $frame = $this->{frames}[$i];
		my $next = ($i == @{$this->{frames}} - 1 ?
					  undef : $this->{frames}[$i + 1]);

		# 変数
		while (my ($name, $value) = each %{$frame->vars}) {

            $value =~ s!</script>!</sc"+"ript>!ig;
            
			$t->node('scripts')->node('js-vars')->node('var')->setAttr(
				NAME  => 'js',
				VALUE => 'js',
			   );
			$t->node('scripts')->node('js-vars')->node('var')->add(
				NAME  => $name,
				VALUE => $value,
			   );
		}
		$t->node('scripts')->node('js-vars')->add(
			LEVEL => $frame->level,
		   );

		while (my ($name, $value) = each %{$frame->vars_shallow}) {

            $value =~ s!</script>!</sc"+"ript>!ig;
            
			$t->node('scripts')->node('js-vars-shallow')->node('var')->setAttr(
				NAME  => 'js',
				VALUE => 'js',
			   );
			$t->node('scripts')->node('js-vars-shallow')->node('var')->add(
				NAME  => $name,
				VALUE => $value,
			   );
		}
		$t->node('scripts')->node('js-vars-shallow')->add(
			LEVEL => $frame->level,
		   );

		# フレーム
		$t->node('scripts')->node('js-frame')->setAttr(
			FILE => 'js',
			FUNC => 'js',
		   );
		$t->node('scripts')->node('js-frame')->add(
			LEVEL => $frame->level,
			FILE  => $frame->fpath,
			LINE  => $frame->line,
			FUNC  => (defined $next ? $next->func : '((basement))'),
		   );
	}
	# ソース
	foreach my $fpath (keys %{$this->{source}}) {
		$this->_foreach_source_line(
			$fpath, sub {
				my ($linenum, $src) = @_;

				$src = $TL->escapeJs($src);
				$src =~ s!</script>!</sc"+"ript>!i;
		
				$t->node('scripts')->node('js-src')->node('line')->setAttr(
					LINE => 'raw',
				   );
				$t->node('scripts')->node('js-src')->node('line')->add(
					LINE => $src,
				   );
			});
		$t->node('scripts')->node('js-src')->setAttr(
			FILE   => 'js',
		   );
		$t->node('scripts')->node('js-src')->add(
			FILE   => $fpath,
		   );
	}

	my $frame = $this->{frames}[$default_level];

	# デフォルトで表示される変数は Lv. 0 の変数であり、表示されるソース
	# は Lv. 0 のソースである。これは後で JavaScript によって書き換えら
	# れる可能性がある。
	if (not $this->{show_vars}) {
		$t->node('detail')->node('vars-unavail')->add(
			REASON => 'iniファイル、[TL]グループの "stacktrace" の設定値が'.
			  ' "full" になっていません。');
	}
    elsif (not $frame) {
        $t->node('detail')->node('vars-unavail')->setAttr(
            REASON => 'raw',
           );
        $t->node('detail')->node('vars-unavail')->add(
            REASON =>
              q{スタックトレースを取得できませんでした。} .
              q{$SIG{__DIE__} ハンドラが置き換えられた状態でエラーが発生した可能性があります。<br />} .
              q{エラー内容が勝手に書き換えられるのを防ぐなどの理由で一時的に $SIG{__DIE__} } .
              q{ハンドラを置き換える際には、次のようにして、発生したエラーを再度 die して下さい。<br /><br />} .
              q[<pre>eval {] . "\n" .
              q[  $SIG{__DIE__} = 'DEFAULT';] . "\n" .
              q[  # エラーが発生する処理] . "\n" .
              q[};] . "\n" .
              q[if ($@) {] . "\n" .
              q[  die $@;  # 再度エラーを発生させる] . "\n" .
              q[}</pre>],
           );
    }
	elsif (not $PADWALKER_AVAILABLE) {
		$t->node('detail')->node('vars-unavail')->setAttr(
			REASON => 'raw',
		   );
		$t->node('detail')->node('vars-unavail')->add(
			REASON => '<a href="http://search.cpan.org/~robin/PadWalker/">PadWalker</a> が利用不可能です。');
	}
	else {
		foreach my $name (sort {$a cmp $b} keys %{$frame->vars_shallow}) {
			$t->node('detail')->node('vars-avail')->node('var')->add(
				NAME  => $name,
				VALUE => $frame->vars_shallow->{$name},
			   );
		}
		$t->node('detail')->node('vars-avail')->add;
	}

	if (not $this->{show_src}) {
		$t->node('detail')->node('src-unavail')->add(
			REASON => 'iniファイル、[TL]グループの "stacktrace" の設定値が'.
			  ' "full" になっていません。');
	}
    elsif (not $frame) {
        $t->node('detail')->node('src-unavail')->add(
            REASON =>
              q{スタックトレースを取得できませんでした。}
             );
    }
	elsif (not defined $this->{source}{$frame->fpath}) {
		$t->node('detail')->node('src-unavail')->add(
			REASON => 'ソースファイル "%s" を読み込む事が出来ません。');
	}
	else {
		$this->_foreach_source_line(
			$frame, sub {
				my ($linenum, $src) = @_;

				$t->node('detail')->node('src-avail')->node('line')->node(
					$frame->line == $linenum ? 'caller-line' : 'other-line')->add(
						SOURCE   => $src,
						LINE_NUM => $linenum,
					   );
				$t->node('detail')->node('src-avail')->node('line')->add;
			});
		$t->node('detail')->node('src-avail')->add;
	}

    if ($frame) {
        $t->node('scripts')->add({
            SELECTED_LV  => $frame->level,
            LAST_HILITED => $frame->line,
           });
        $t->expand(
            SELECTED_LV  => $frame->level,
            LAST_HILITED => $frame->line,
           );
    }
    else {
        $t->node('scripts')->add({
            SELECTED_LV  => 0,
            LAST_HILITED => 0,
           });
        $t->expand(
            SELECTED_LV  => 0,
            LAST_HILITED => 0,
           );
    }

	$t->node('detail')->add;
	$t->toStr;
}

sub _stringify {
	# 文字列化は標準エラーやメール等への出力を目的として行われる為、ソー
	# スコードは省かれる。ローカル変数が省かれるかどうかは設定に依る。
	my $this = shift;
	my $dump_vars = ($TL->INI->get(TL => 'errorlog', 1) > 2);
	my $omission_threshold = 100; # 100 バイトを越える変数は二回以上出力しない
	my $already_dumped = {}; # 値 => [名前, レベル]
	
	my $ret;

	$ret = sprintf "[%s] message: %s\n", $this->{type}, $this->{message};

	for (my $i = 0; $i < @{$this->{frames}}; $i++) {
		my $frame = $this->{frames}[$i];
		my $next = ($i == @{$this->{frames}} - 1 ?
					  undef : $this->{frames}[$i + 1]);
		
		$ret .= sprintf(
			"[stack][%d] file: %s (line %d) \@ %s ==> %s\n",
			$i,
			$frame->fpath,
			$frame->line,
			(defined $next ? $next->func : '((basement))'),
			$frame->func,
		   );

		if ($dump_vars) {
			my @sorted = sort keys %{$frame->vars};

			foreach my $name (@sorted) {
				my $value = $frame->vars->{$name};

				$ret .= sprintf("     %s = ", $name);

				if (length($value) >= $omission_threshold) {
					if (my $before = $already_dumped->{$value}) {
						$ret .= sprintf(
							"already dumped as %s at frame %d. skip...\n",
							$before->[0], $before->[1]);
						next;
					}
					else {
						$already_dumped->{$value} = [$name, $i];
					}
				}

				my @lines = split /\r?\n|\n/, $value;
				for (my $i = 0; $i < @lines; $i++) {
					if ($i == 0) {
						$ret .= "$lines[$i]\n";
					}
					elsif ($i == @lines - 1) {
						$ret .= "     $lines[$i];\n";
					}
					else {
						$ret .= "     $lines[$i]\n";
					}
				}
			}
		}
	}

	$ret;
}

sub _foreach_source_line {
	my ($this, $fpath, $f) = @_;
	ref $fpath and
	  $fpath = $fpath->fpath; # Tripletail::Error::Frame を許す

	my $src = $this->{source}{$fpath};

	my @lines = split /\r?\n|\r/, (defined $src ? $src : '');
	for (my $i = 0; $i < @lines; $i++) {
		$f->(
			$i + 1, sprintf('%5d |  %s', $i + 1, $lines[$i]));
	}
}

package Tripletail::Error::Frame;
use strict;
use warnings;

sub new {
	my $class = shift;
	my $this = bless {} => $class;

	$this->{level}  = shift;
	$this->{fpath}  = shift;
	$this->{line}   = shift;
	$this->{func}   = shift;
	$this->{vars}         = {}; # '$foo' => 666
	$this->{vars_shallow} = {}; # '$doo' => 'ARRAY(0x81940f8)'
	$this;
}

sub level  { shift->{level}  }
sub fpath  { shift->{fpath}  }
sub line   { shift->{line}   }
sub func   { shift->{func}   }
sub vars   { shift->{vars}   }
sub vars_shallow { shift->{vars_shallow} }

sub set_variable {
	my $this = shift;
	my $name = shift;
	my $ref  = shift;

	my $postprocess = sub {
		local($_);
		$_ = shift;
		
		s!^\\!!;
		s!^\s*|\s*$!!g;
		($name =~ m/[\@\%]/) and do {
			s!^[\[\{]!(!;
			s![\]\}]$!)!;
		};

		if (length > $VARIABLE_LENGTH_LIMIT) {
			substr($_, $VARIABLE_LENGTH_LIMIT - 3) = '...';
		}

		$_;
	};

	my $dump = Data::Dumper->new([$ref])
	  ->Indent(1)->Purity(0)->Useqq(1)->Terse(1)->Deepcopy(1)
	  ->Quotekeys(0)->Sortkeys(1)->Deparse(1)->Maxdepth(7)->Dump;
	$this->{vars}{$name} = $postprocess->($dump);

	my $shallow = Data::Dumper->new([$ref])
	  ->Indent(1)->Purity(0)->Useqq(1)->Terse(1)->Deepcopy(1)
	  ->Quotekeys(0)->Sortkeys(1)->Deparse(1)->Maxdepth(1)->Dump;
	$this->{vars_shallow}{$name} = $postprocess->($shallow);
	
	$this;
}

package Tripletail::Error;
sub __load_default_error_template
{
	# {{ DEFAULT_ERROR_TEMPLATE:
	<<'END';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11.dtd">
<html xml:lang="ja" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta name="robots" content="noindex,nofollow,noarchive" />
    <title>[TL] 内部エラー</title>
    <style>
      * {
       margin: 0;
       padding: 0;
      }
      
      body {
          background-color: #ddddbb;
          color: #333322;
          padding: 0px;
          font-size: 90%;
      }

      h1 {
          font-size: 150%;
          background-color: #eeeecc;
          border-style: inset;
          border-color: #ddddbb;
          border-width: 1px;
          padding: 3px;
      }

      h2 {
          font-size: 120%;
          background-color: #ccccaa;
          padding: 2px 3px;
      }

      .message {
          padding: 3px;
          font-size: 110%;
          font-weight: bold;
      }
    </style>

    <!begin:style-for-header-only>
    <!end:style-for-header-only>
    <!begin:style-for-detail>
    <style>
      table {
          width: 100%;
      }

      th, td {
          margin: 1px;
          border-style: dashed;
          border-width: 1px;
          border-color: #aaaa88;
          padding: 2px;
      }

      th {
          background-color: #d4d4b2;
      }

      .small {
          font-size: 85%;
      }

      /* ヘッダ */
      .header-pane {
          position: absolute;
          width: 50%;
          height: 15%;
          overflow: auto;

          background-color: #ddbbbb;
      }

      /* スタック */
      .stack-pane {
          position: absolute;
          width: 50%;
          height: 45%;
          top: 15%;
          background-color: #d8d8b6;
          overflow: auto;
      }

      .stack-pane .selected {
          color: #cc0000;
      }

      #stack-description {
          display: none;
      }

      /* 変数詳細 */
      #variable-detail {
          position: absolute;
          width: 50%;
          height: 60%;
          background-color: #554433;
          opacity: 0.90;
          z-index: 1;

          color: white;
          overflow: auto;
      }
      #variable-detail pre {
          padding: 15px;
      }
      #variable-detail .header {
          font-size: 200%;
          font-weight: bold;
      }

      /* 変数 */
      .variables-pane {
          position: absolute;
          width: 50%;
          height: 60%;
          left: 50%;
          overflow: auto;
      }

      .variables-pane .name {
          width: 15%;
      }
      .variables-pane pre {
          max-height: 100px; /* この値はスクリプトで上書きされ得る */
          overflow: auto;
          width: 100%;
      }

      #var-description {
          display: none;
      }

      /* ソース */
      .source-pane {
          position: absolute;
          width: 100%;
          height: 40%;
          top: 60%;
          background-color: #d5d5b3;
          overflow: auto;
      }

      .source-pane .caller {
          background-color: #ddbbbb;
          border-style: solid;
          border-width: 1px;
          border-color: #ccaaaa;

          margin-left: -1px;
      }
    </style>

    <!--[if IE]>
    <style>
      #variable-detail {
          filter:alpha(opacity=90);
      }
    </style>
    <![endif]-->
    <!end:style-for-detail>

    <!begin:scripts>
    <script type="text/javascript">
      var env = {
          selected_lv : <&SELECTED_LV>,
          last_hilited: <&LAST_HILITED>
      };

      var colours = {
          general: { inactive: "#ddddbb", active: "#eeeecc" },

          tl     : { inactive: "#ddddcc", active: "#eeeedd" },
          cgi    : { inactive: "#ddeecc", active: "#eeffdd" },
          other  : { inactive: "#eeddbb", active: "#ffeecc" }
      };

      var vars_data = {
          <!begin:js-vars>
            <&LEVEL>: {
                <!begin:var>"<&NAME>": "<&VALUE>",<!end:var>
                "": null
            },
          <!end:js-vars>
          "": null
      };

      var vars_shallow_data = {
          <!begin:js-vars-shallow>
            <&LEVEL>: {
                <!begin:var>"<&NAME>": "<&VALUE>",<!end:var>
                "": null
            },
          <!end:js-vars-shallow>
          "": null
      };

      var frame_data = {
          <!begin:js-frame>
            <&LEVEL>: {
                fpath: "<&FILE>", line: <&LINE>, func: "<&FUNC>"
            },
          <!end:js-frame>
          "": null
      };

      var src_data = {
          <!begin:js-src>
            "<&FILE>": [
                <!begin:line>"<&LINE>",<!end:line>
                null],
          <!end:js-src>
          "": null
      };

      function on_load() {
          jump_to_caller_line();
          show_hiddens();
          adjust_pre_size();
          fix_stack_colour();
      }

      function is_var_worth_expanding(lv, name) {
          var data = vars_data[lv];
          var value = data[name];

          var shallow_data = vars_shallow_data[lv];
          var shallow = shallow_data[name];

          return value != shallow;
      }

      function enter_var(name) {
          var lv = env.selected_lv;
          if (!is_var_worth_expanding(lv, name)) {
              return;
          }

          foreach_var_cols(
              name, function (td) {
                  td.style.backgroundColor = colours.general.active;
              });
      }

      function leave_var(name) {
          var lv = env.selected_lv;
          if (!is_var_worth_expanding(lv, name)) {
              return;
          }

          foreach_var_cols(
              name, function (td) {
                  td.style.backgroundColor = colours.general.inactive;
              });
      }

      function expand_var(name) {
          var lv = env.selected_lv;
          if (!is_var_worth_expanding(lv, name)) {
              return;
          }

          var old = document.getElementById("variable-detail");
          if (old) {
              old.parentNode.removeChild(old);
          }

          var div = document.createElement("variable-detail");
          div.id = "variable-detail";
          div.onclick = function () {
              div.parentNode.removeChild(div);
          };
          
          var data = vars_data[lv];
          var value = data[name];

          var header = document.createElement("span");
          header.className = "header";
          header.appendChild(
              document.createTextNode(name));

          var text = " = " + value.replace(/\r?\n|\n/g, "\r\n") + ";";

          var pre = document.createElement("pre");
          pre.appendChild(header);
          pre.appendChild(document.createTextNode(text));
          div.appendChild(pre);

          var body = document.getElementsByTagName("body")[0];
          body.appendChild(div);
      }

      function adjust_pre_size() {
          // IE の為の調整。IEはスクリプトが指定した width や height を無視し、
          // 非公開の基準に従って大きさを自在に決定する。
          // その基準を外部から推し量る事は全く不可能である。
          if (navigator.appName.indexOf("Internet Explorer") == -1) {
              return;
          }

          var limit = 100;

          var vars = document.getElementById("variables");
          if (!vars) {
              return;
          }

          var pres = vars.getElementsByTagName("pre");
          for (var i = 0; i < pres.length; i++) {
              var pre = pres[i];

              if (pre.className == "limit-size") {
                  if (limit < pre.offsetHeight) {
                      pre.style.height = limit + "px";
                  }

                  var wwidth = document.body.clientWidth;
                  pre.style.width = (wwidth / 2 * 0.85 - 20) + "px";
              }
          }
      }

      function jump_to_caller_line() {
          var src_pane = document.getElementById("source-pane");

          var frame = frame_data[env.selected_lv];
          if (!frame) {
              return;
          }

          var caller = document.getElementById("srcline-" + frame.line);
          if (!caller) {
              return;
          }

          /* src_pane の scrollTop を caller の位置により調整する */
          var y = caller.offsetTop
              - src_pane.offsetHeight / 2
              + caller.offsetHeight / 2;
          if (y < 0) {
              y = 0;
          }
          src_pane.scrollTop = y;
      }

      function show_hiddens() {
          var hiddens = ["stack-description", "var-description"];

          for (var i in hiddens) {
              var elem = document.getElementById(hiddens[i]);
              if (elem) {
                  var cond_val = 1;

                  if (elem.getAttribute("condition")) {
                      cond_val = eval(elem.getAttribute("condition"));
                  }

                  if (cond_val) {
                      elem.style.display = "block";
                  }
              }
          }
      }

      function fix_stack_colour() {
          var stack = document.getElementById("stack");
          if (!stack) {
              return;
          }
          var tbody = stack.getElementsByTagName("tbody")[0];

          var child = tbody.firstChild;
          while (child) {
              if (child.tagName && child.tagName.toLowerCase() == "tr") {
                  var tr = child;
                  var m = /^frame:(\d+)$/.exec(tr.id);

                  if (m) {
                      var lv = m[1];

                      foreach_stack_cols(
                          lv, function(td) {
                              td.style.backgroundColor =
                                  get_stack_colour(lv).inactive;
                          });
                  }
              }
              child = child.nextSibling;
          }
      }

      function get_stack_colour(lv) {
          var frame = frame_data[lv];

          if (frame.func.indexOf("Tripletail::") == 0) {
              return colours.tl;
          }

          var deepest_frame;
          var deepest_lv;
          for (var i in frame_data) {
              if (deepest_lv == null || deepest_lv < i) {
                  deepest_frame = frame_data[i];
                  deepest_lv = i;
              }
          }

          if (frame.fpath == deepest_frame.fpath) {
              return colours.cgi;
          }

          return colours.other;
      }

      function is_stack_worth_selecting() {
          /* 変数またはソースコードの少なくとも一方が利用可能でなければ、
             スタックを選択する事の意味が無い。*/

          var variables = document.getElementById("variables");
          var source    = document.getElementById("source-lines");
          return variables || source;
      }

      function enter_stack(lv) {
          if (!is_stack_worth_selecting() || lv == env.selected_lv) {
              return;
          }

          foreach_stack_cols(
            lv, function(td) {
                td.style.backgroundColor = get_stack_colour(lv).active;
            });
      }

      function leave_stack(lv) {
          foreach_stack_cols(
            lv, function(td) {
                td.style.backgroundColor = get_stack_colour(lv).inactive;
            });
      }

      function select_stack(lv) {
          if (!is_stack_worth_selecting()) {
              return;
          }

          if (lv == env.selected_lv) {
              jump_to_caller_line();
              return;
          }

          /* selected クラスに指定される行を変更 */
          var old = document.getElementById("frame:" + env.selected_lv);
          old.className = "frame";

          var tr = document.getElementById("frame:" + lv);
          tr.className = "frame selected";

          /* 変数一覧を作り直す */
          rebuild_var_list(lv);
          
          /* ソースコード各行を作り直す */
          rebuild_src_list(lv);
          update_src_hilite(lv);

          env.selected_lv = lv;

          adjust_pre_size();
          jump_to_caller_line();
      }

      function rebuild_var_list(lv) {
          var table = document.getElementById("variables");
          if (!table) {
              return;
          }

          remove_rows_except_the_first(table);

          var data = vars_shallow_data[lv];
          var sorted_keys = [];

          for (var key in data) {
              if (key != "") {
                  sorted_keys.push(key);
              }
          }
          sorted_keys = sorted_keys.sort();

          var tbody = table.getElementsByTagName("tbody")[0];
          for (var i in sorted_keys) {
              var name  = sorted_keys[i];
              var value = data[name];

              var tr = document.createElement("tr");
              tr.id = "var:" + name;
              var tmp = { name: name };
              with (tmp) {
                  tr.onmouseover = function () { enter_var(name);  };
                  tr.onmouseout  = function () { leave_var(name);  };
                  tr.onmousedown = function () { expand_var(name); };
              }

              var td_name = document.createElement("td");
              td_name.className = "name";
              td_name.appendChild(
                  document.createTextNode(name));

              var td_value = document.createElement("td");
              td_value.className = "value small";

              /* IE は、改行コードを CRLF にしないと改行してくれない。バグ？ */
              var pre = document.createElement("pre");
              pre.appendChild(
                  document.createTextNode(value.replace(/\r?\n|\n/g, "\r\n")));
              td_value.appendChild(pre);

              tr.appendChild(td_name);
              tr.appendChild(td_value);
              tbody.appendChild(tr);
          }
      }

      function rebuild_src_list(lv) {
          // 行番号が違うだけでソースファイルが同じであれば、
          // 各行の class を変更するだけで良い。
          if (frame_data[env.selected_lv].fpath == frame_data[lv].fpath) {
              return;
          }

          var area = document.getElementById("source-lines-area");
          if (!area) {
              return;
          }
          remove_children(area);

          var lines = document.createElement("div");
          lines.className = "lines";
          lines.id = "source-lines";

          var frame = frame_data[lv];
          var src = src_data[frame.fpath];

          for (var i = 0; i < src.length; i++) {
              if (src[i] == null) {
                  continue;
              }

              var pre = document.createElement("pre");
              pre.id = "srcline-" + (i + 1);

              pre.appendChild(
                  document.createTextNode(src[i]));
              lines.appendChild(pre);
          }

          area.appendChild(lines);
      }

      function update_src_hilite(lv) {
          var old = document.getElementById("srcline-" + env.last_hilited);
          if (old) {
              old.className = "";
          }

          var frame = frame_data[lv];
          var caller = document.getElementById("srcline-" + frame.line);
          if (!caller) {
              return;
          }
          caller.className = "caller";

          env.last_hilited = frame.line;
      }

      function remove_children(elem) {
          var child = elem.firstChild;
          while (child) {
              var next = child.nextSibling;
              elem.removeChild(child);
              child = next;
          }
      }

      function remove_rows_except_the_first(table) {
          // table 要素の先頭以外の tr を消す。
          var tbody = table.getElementsByTagName("tbody")[0];
          var skipped;

          var child = tbody.firstChild;
          while (child) {
              if (child.tagName && child.tagName.toLowerCase() == "tr") {
                  if (skipped) {
                      var next = child.nextSibling;
                      tbody.removeChild(child);
                      child = next;
                      continue;
                  }
                  else {
                      skipped = true;
                  }
              }
              child = child.nextSibling;
          }
      }

      function foreach_cols(tr, name, f) {
          var child = tr.firstChild;
          while (child) {
              if (child.tagName && child.tagName.toLowerCase() == "td") {
                  f(child);
              }
              child = child.nextSibling;
          }
      }

      function foreach_var_cols(name, f) {
          var tr = document.getElementById("var:" + name);
          foreach_cols(tr, name, f);
      }

      function foreach_stack_cols(lv, f) {
          var tr = document.getElementById("frame:" + lv);
          foreach_cols(tr, name, f);
      }
    </script>
    <!end:scripts>
  </head>
  <body onload="on_load()">
    <!begin:header-only>
      <h1>[TL] 内部エラー</h1>

      <h2>タイプ: <&TYPE></h2>

      <p class="message">
        <&MESSAGE>
      </p>
    <!end:header-only>

    <!begin:detail>
    <div class="header-pane">
      <p class="message">
        <&MESSAGE>
      </p>
    </div>

    <div class="stack-pane">
      <table id="stack">
        <tr>
          <th>Lv.</th>
          <th>ファイル</th>
          <th>行</th>
          <th>呼出し元</th>
          <th>呼出し先</th>
        </tr>
        <!begin:frame>
        <tr class="frame <!begin:selected>selected<!end:selected>"
            id="frame:<&LEVEL>"
            onmouseover="enter_stack(<&LEVEL>)"
            onmouseout="leave_stack(<&LEVEL>)"
            onmousedown="select_stack(<&LEVEL>)">
          <td><&LEVEL></td>
          <td class="small"><&FILE></td>
          <td><&LINE></td>
          <td><&CALLER></td>
          <td><&CALLEE></td>
        </tr>
        <!end:frame>
      </table>
      <p id="stack-description" condition="is_stack_worth_selecting()">
        フレームをクリックすると、そのフレームが選択されます。
      </p>
    </div>

    <div class="variables-pane">
      <h1>[TL] 内部エラー</h1>

      <h2>タイプ: <&TYPE></h2>

      <!begin:vars-avail>
        <table id="variables">
          <tr>
            <th>変数名</th>
            <th>値</th>
          </tr>
          <!begin:var>
          <tr id="var:<&NAME>"
              onmouseover="enter_var('<&NAME>')"
              onmouseout="leave_var('<&NAME>')"
              onmousedown="expand_var('<&NAME>')">
            <td class="name"><&NAME></td>
            <td class="value small"><pre><&VALUE></pre></td>
          </tr>
          <!end:var>
        </table>
        <p id="var-description">
          内部が省略表示されている変数をクリックすると、その内容が展開表示されます。
        </p>
      <!end:vars-avail>
      <!begin:vars-unavail>
        <p>
          変数一覧を表示する事が出来ません。
          理由:
        </p>
        <p>
          <&REASON>
        </p>
      <!end:vars-unavail>
    </div>
    
    <div class="source-pane" id="source-pane">
      <h2>ソースコード</h2>

      <!begin:src-avail>
      <div id="source-lines-area">
        <div class="lines" id="source-lines">
          <!begin:line>
            <!begin:caller-line>
              <pre class="caller" id="srcline-<&LINE_NUM>"><&SOURCE></pre>
            <!end:caller-line>
            <!begin:other-line><pre id="srcline-<&LINE_NUM>"><&SOURCE></pre><!end:other-line>
          <!end:line>
        </div>
      </div>
      <!end:src-avail>
      <!begin:src-unavail>
        <p>
          ソースコードを表示する事が出来ません。
          理由:
        </p>
        <p>
          <&REASON>
        </p>
      <!end:src-unavail>
    </div>
    <!end:detail>
  </body>
</html>
END
	# DEFAULT_ERROR_TEMPLATE:}}
}

__END__

=encoding utf-8

=head1 NAME

Tripletail::Error - 内部クラス

=head1 DESCRIPTION

L<Tripletail> によって内部的及び L<fault_handler|Tripletail/fault_handler>
で使用される。

=head2 METHODS

=over 4

=item C<< message >>

エラーメッセージ。(C<$@>)

=item C<< title >>

短い説明。
省略時は "C<Error: $message>";

=item C<< type >>

エラー情報の種別。

=over

=item 'C<error>'

実行時エラーに関する情報。

=item 'C<warn>'

警告に関する情報。

=item 'C<file-update>'

スクリプト等の更新検出。

=item 'C<memory-leak>'

メモリ制限。

=back

=item C<< toHtml >>

HTML化。

=item C<< is_trace_allowed >>

内部メソッド

=back

=head1 SEE ALSO

L<Tripletail>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

HP : http://tripletail.jp/

=back

=cut
