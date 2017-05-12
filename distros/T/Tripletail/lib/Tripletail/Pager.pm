# -----------------------------------------------------------------------------
# Tripletail::Pager - ページング処理
# -----------------------------------------------------------------------------
package Tripletail::Pager;
use strict;
use warnings;
use Tripletail;

1;

sub _new {
    my $class = shift;
    my $DB    = Tripletail::_isa($_[0], 'Tripletail::DB')
              ? shift
              : $TL->getDB(shift);

    my $this = bless {} => $class;

    $this->{db    } = $DB;
    $this->{dbtype} = $DB->getType;

	$this->{pagesize} = 30;
	$this->{current} = 1;
	$this->{maxlinks} = 10;
	$this->{formkey} = 'pageid';
	$this->{formparam} = undef;
	$this->{pagingtype} = 0;
	$this->{tolink} = undef;

    #結果群
	$this->{maxpages} = undef;
	$this->{linkstart} = undef;
	$this->{linkend} = undef;
	$this->{maxrows} = undef;
	$this->{beginrow} = undef;
	$this->{rows} = undef;

	$this->setFormParam(undef);
	$this;
}

sub setToLink {
	my $this = shift;
	my $tolink = shift;

	if(ref($tolink)) {
		die __PACKAGE__."#setToLinkp: arg[1] is a reference. [$tolink] (第1引数がリファレンスです)\n";
	}

	$this->{tolink} = $tolink;
	$this;
}

sub setDbGroup {
	my $this = shift;
	my $dbgroup = shift;

	if(ref($dbgroup)) {
		die __PACKAGE__."#setDbGroup: arg[1] is a reference. [$dbgroup] (第1引数がリファレンスです)\n";
	}

    $this->{db    } = $TL->getDB($dbgroup);
    $this->{dbtype} = $this->{db}->getType;
    $this;
}

sub setPageSize {
	my $this = shift;
	my $size = shift;

	if(!defined($size)) {
		die __PACKAGE__."#setPageSize: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($size)) {
		die __PACKAGE__."#setPageSize: arg[1] is a reference. [$size] (第1引数がリファレンスです)\n";
	} elsif($size !~ /^\d+$/ || $size <= 0) {
		die __PACKAGE__."#setPageSize: arg[1] is not a positive number. [$size] (第1引数が正の整数ではありません)\n";
	}

	$this->{pagesize} = $size;
	$this;
}

sub setCurrentPage {
	my $this = shift;
	my $page = shift;

	if(!defined($page)) {
		die __PACKAGE__."#setCurrentPage: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($page)){
		die __PACKAGE__."#setCurrentPage: arg[1] is a reference. [$page] (第1引数がリファレンスです)\n";
	} elsif($page !~ /^\d+$/ || $page <= 0) {
		die __PACKAGE__."#setCurrentPage: arg[1] is not a positive number. [$page] (第1引数が正の整数ではありません)\n";
	}

	$this->{current} = $page;
	$this;
}

sub setMaxLinks {
	my $this = shift;
	my $maxlinks = shift;

	if(!defined($maxlinks)) {
		die __PACKAGE__."#setMaxLinks: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($maxlinks)){
		die __PACKAGE__."#setMaxLinks: arg[1] is a reference. [$maxlinks] (第1引数がリファレンスです)\n";
	} elsif($maxlinks !~ /^\d+$/ || $maxlinks <= 0) {
		die __PACKAGE__."#setMaxLinks: arg[1] is not a positive number. [$maxlinks] (第1引数が正の整数ではありません)\n";
	}

	$this->{maxlinks} = $maxlinks;
	$this;
}

sub setFormKey {
	my $this = shift;
	my $key = shift;

	if(!defined($key)) {
		die __PACKAGE__."#setFormKey: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($key)) {
		die __PACKAGE__."#setFormKey: arg[1] is a reference. [$key] (第1引数がリファレンスです)\n";
	}

	$this->{formkey} = $key;
	$this;
}

sub setFormParam {
	my $this = shift;
	my $form = shift;

	if(!defined($form)) {
		$this->{formparam} = $TL->newForm;
	} elsif(ref($form) eq 'HASH') {
		$this->{formparam} = $TL->newForm($form);
	} else {
		if(ref($form) ne 'Tripletail::Form') {
			die __PACKAGE__."#setFormParam: arg[1] is not an instance of Tripletail::Form. [$form] (第1引数がFormオブジェクトではありません)\n";
		} else {
			$this->{formparam} = $form->clone;
		}
	}

	$this;
}

sub setPagingType {
	my $this = shift;
	my $type = shift;

	if(!defined($type)) {
		die __PACKAGE__."#setPagingType: arg[1] is not defined. (第1引数が指定されていません)\n";
	} elsif(ref($type)) {
		die __PACKAGE__."#setPagingType: arg[1] is a reference. [$type] (第1引数がリファレンスです)\n";
	} elsif($type !~ /^[01]$/) {
		die __PACKAGE__."#setPagingType: arg[1] is neither 0 nor 1. [$type] (第1引数は0か1のみ指定できます)\n";
	}

	$this->{pagingtype} = $type;
	$this;
}

sub getPagingInfo {
	my $this = shift;

	$this;
}

sub paging {
	my $this = shift;
	$this->_paging(0, @_);
}

sub pagingArray {
	my $this = shift;
	$this->_paging(1, @_);
}

sub pagingHash {
	my $this = shift;
	$this->_paging(2, @_);
}

sub _set_limitoffset {
    my $this = shift;
    my $query = shift;

    # 何行目から表示すれば良いのか計算。
    $this->{beginrow} = ($this->{current} - 1) * $this->{pagesize};

    # LIMITを勝手に付ける。
    if($this->{dbtype} eq 'mysql') {
        $query .= sprintf "\nLIMIT %d, %d", $this->{beginrow}, $this->{pagesize};
    }
    else {
        $query .= sprintf "\nLIMIT %d\nOFFSET %d", $this->{pagesize}, $this->{beginrow};
    }

    $query;
}

sub _paging {
	my $this = shift;
	my $resulttype = shift; # 0:件数(Row展開有), 1:配列(Row展開無), 2:ハッシュ(Row展開無)
	my $node = shift;
	my $query = shift;
	my @params = @_;
	my $result;

    my $DB = $this->{db};

	if(ref($query) eq 'ARRAY') {
		($query, $this->{maxrows}) = @$query;
	}

	if(!defined($node)) {
		die __PACKAGE__."#paging: ARG[2] is not defined. (第2引数が指定されていません)\n";
	} elsif(ref($node) ne 'Tripletail::Template::Node') {
		die __PACKAGE__."#paging: ARG[2] is a reference. [$node] (第2引数がリファレンスです)\n";
	}
	
	if(!defined($query)) {
		die __PACKAGE__."#paging: ARG[3] is not defined. (第3引数が指定されていません)\n";
	} elsif(ref($query)) {
		die __PACKAGE__."#paging: ARG[3] is a reference. [$query] (第3引数がリファレンスです)\n";
	}

	my $query_back = $query;

	if(defined($this->{maxrows})) {
		if(ref($this->{maxrows})) {
			die __PACKAGE__."#paging: ARG[3] is a reference. [$this->{maxrows}] (第3引数がリファレンスです)\n";
		} elsif($this->{maxrows} !~ /^\d+$/ || $this->{maxrows} < 0) {
			die __PACKAGE__."#paging: ARG[3] is not a positive number. [$this->{maxrows}] (第3引数が正の整数ではありません)\n";
		}
	} else {
	# SQL_CALC_FOUND_ROWSを勝手に付ける。
        if($this->{dbtype} eq 'mysql') {
            $query =~ s/SELECT/SELECT SQL_CALC_FOUND_ROWS/i;
        }
	}
    
    $query = $this->_set_limitoffset($query);

	# SQL実行
	if($resulttype == 0) {
		my $sth = $DB->execute($query, @params);
		while(my $row = $sth->fetchHash) {
			$node->node('Row')->add($row);
		}
		$this->{rows} = $sth->rows + 0;
		$result = $this->{rows};
	} elsif($resulttype == 1) {
		$result = $DB->selectAllArray($query, @params);
		$this->{rows} = scalar(@$result);
	} elsif($resulttype == 2) {
		$result = $DB->selectAllHash($query, @params);
		$this->{rows} = scalar(@$result);
	}

    # 全部で何件あるか調べる
    if ($this->{dbtype} eq 'mysql') {
        unless (defined($this->{maxrows})) {
            my $sth   = $DB->execute(q{SELECT FOUND_ROWS() as ROWS});
            my $count = $sth->fetchArray;
            $sth->finish;

            $this->{maxrows} = $count->[0];
        }
    }
    else {
        unless (defined($this->{maxrows})) {
            my $count_query = $query_back;
            my $replaced    = $count_query =~ s/SELECT.+?FROM/SELECT COUNT(*) FROM/si;
            if (!$replaced) {
                die __PACKAGE__."#paging, failed to rewrite the SELECT statement to count total number of rows.".
                  " (総行数を得るための SELECT 文の書換に失敗しました。)\n";
            }

            my $sth   = $DB->execute($count_query, @params);
            my $count = $sth->fetchArray;
            $sth->finish;

            $this->{maxrows} = $count->[0];
        }
    }

	if($this->{maxrows} == 0) {
		# 検索結果が無かった
		return 0;
	}

	# 総頁数
	$this->{maxpages} = int(($this->{maxrows} - 1) / $this->{pagesize}) + 1;
	if($this->{current} > $this->{maxpages}) {
		# 存在する頁数を越えて現在頁が設定されている。
		if($this->{pagingtype} == 1){
			# typeが1なので最大ページを現在のページに設定して再検索。
			$this->{current} = $this->{maxpages};

            $query_back = $this->_set_limitoffset($query_back);

			if($resulttype == 0) {
				my $sth = $DB->execute($query_back, @params);
				while(my $row = $sth->fetchHash) {
					$node->node('Row')->add($row);
				}
				$this->{rows} = $sth->rows + 0;
				$result = $this->{rows};
			} elsif($resulttype == 1) {
				$result = $DB->selectAllArray($query_back, @params);
				$this->{rows} = scalar(@$result);
			} elsif($resulttype == 2) {
				$result = $DB->selectAllHash($query_back, @params);
				$this->{rows} = scalar(@$result);
			}
		} else {
			# typeが0なのでここで終了。
			# ページリンク
			$this->{linkstart} = $this->{maxpages} - int($this->{maxlinks} / 2);
			if($this->{linkstart} < 1) {
				$this->{linkstart} = 1;
			}

			$this->{linkend} = $this->{linkstart} + $this->{maxlinks} - 1;
			if($this->{linkend} > $this->{maxpages}) {
				$this->{linkend} = $this->{maxpages};

				# linkendを変えたので、startの方を再度変更
				$this->{linkstart} = $this->{linkend} - $this->{maxlinks} + 1;
				if($this->{linkstart} < 1) {
					$this->{linkstart} = 1;
				}
			}

			return undef;
		}
	}

	# リンクその他を展開
	if($this->{current} == 1) {
		$node->node('NoPrevLink')->add;
	} else {
		$node->node('PrevLink')->add(
			PREVLINK => $this->{formparam}->set(
					$this->{formkey} => $this->{current} - 1
				)->toLink($this->{tolink}),
		);
	}

	if($this->{current} == $this->{maxpages}) {
		$node->node('NoNextLink')->add;
	} else {
		$node->node('NextLink')->add(
			NEXTLINK => $this->{formparam}->set(
					$this->{formkey} => $this->{current} + 1
				)->toLink($this->{tolink}),
		);
	}

	# ページリンク
	$this->{linkstart} = $this->{current} - int($this->{maxlinks} / 2);
	if($this->{linkstart} < 1) {
		$this->{linkstart} = 1;
	}

	$this->{linkend} = $this->{linkstart} + $this->{maxlinks} - 1;
	if($this->{linkend} > $this->{maxpages}) {
		$this->{linkend} = $this->{maxpages};

		# linkendを変えたので、startの方を再度変更
		$this->{linkstart} = $this->{linkend} - $this->{maxlinks} + 1;
		if($this->{linkstart} < 1) {
			$this->{linkstart} = 1;
		}
	}

    # 必須でないノード
    if ($node->exists('PageNumLinks')) {
        foreach my $i ($this->{linkstart} .. $this->{linkend}) {
            if($i == $this->{current}) {
                $node->node('PageNumLinks')->node('ThisPage')->add(
                    PAGENUM => $i,
                   );
            }
            else {
                $node->node('PageNumLinks')->node('OtherPage')->add(
                    PAGELINK => $this->{formparam}->set(
						$this->{formkey} => $i,
                       )->toLink($this->{tolink}),
                    PAGENUM  => $i,
                   );
            }
            $node->node('PageNumLinks')->add;
        }
    }
	
	if($node->exists('MaxRows')) {
		$node->node('MaxRows')->add(MAXROWS => $this->{maxrows});
	}

	if($node->exists('FirstRow')) {
		$node->node('FirstRow')->add(FIRSTROW => $this->{beginrow} + 1);
	}

	if($node->exists('LastRow')) {
		$node->node('LastRow')->add(LASTROW => $this->{beginrow} + $this->{rows});
	}

	if($node->exists('MaxPages')) {
		$node->node('MaxPages')->add(MAXPAGES => $this->{maxpages});
	}

	if($node->exists('CurPage')) {
		$node->node('CurPage')->add(CURPAGE => $this->{current});
	}

	$result;
}


__END__

=encoding utf-8

=head1 NAME

Tripletail::Pager - ページング処理

=head1 SYNOPSIS

  my $DB = $TL->getDB('DB');
  my $pager = $TL->newPager($DB);
  $pager->setCurrentPage($CGI->get('pageid'));

  my $t = $TL->newTemplate('template.html');
  if($pager->paging($t->node('paging'), 'SELECT * FROM foo WHERE a = ?', 999)) {
    $t->node('paging')->add;
  } else {
    $t->node('nodata')->add;
  }

=head1 DESCRIPTION

ページング処理を行う。

決められた形式のTripletail::Templateノードに展開する。

=head2 テンプレート形式

  <!begin:paging>
    <!begin:PrevLink><a href="<&PREVLINK>">←前ページ</a><!end:PrevLink>
    <!begin:NoPrevLink>←前ページ<!end:NoPrevLink>
    <!begin:PageNumLinks>
      <!begin:ThisPage><&PAGENUM><!end:ThisPage>
      <!begin:OtherPage>
        <a href="<&PAGELINK>"><&PAGENUM></a>
      <!end:OtherPage>
    <!end:PageNumLinks>
    <!begin:NextLink><a href="<&NEXTLINK>">次ページ→</a><!end:NextLink>
    <!begin:NoNextLink>次ページ→<!end:NoNextLink>
    ...
    <!begin:MaxRows>全<&MAXROWS>件<!end:MaxRows>
    <!begin:FirstRow><&FIRSTROW>件目から<!end:FirstRow>
    <!begin:LastRow><&LASTROW>件目までを表示中<!end:LastRow>
    <!begin:MaxPages>全<&MAXPAGES>ページ<!end:MaxPages>
    <!begin:CurPage>現在<&CURPAGE>ページ目<!end:CurPage>
    ...
    <!begin:Row>
      <!-- 行データを展開する ＜＆ＸＸＸ＞ タグを半角で記述する -->
    <!end:Row>
    ...
  <!end:paging>
  <!-- 以下は Pager クラスの処理とは関係ないため、無くても良い -->
  <!begin:nodata>
    一件もありません
  <!end:nodata>

必須でないノードは次の通り:
  
  PageNumLinks, MaxRows, FirstRow, LastRow, MaxPages, CurPage

これらのノードが存在しない場合は、単に無視される。

Rowノードは L</paging> メソッドを利用する場合のみ使用される。

L</pagingArray> や L</pagingHash> メソッドを利用する場合、
メソッド実行によって paging ノードが展開されるため、
その外側にデータ用のノードをおかなければならないことに注意する必要がある。

例えば以下のようなテンプレートとなり、メソッドの戻値を
ループの中で Rowノードに展開するような形となる。

  <!begin:paging>
    <!begin:PrevLink><a href="<&PREVLINK>">←前ページ</a><!end:PrevLink>
    <!begin:NoPrevLink>←前ページ<!end:NoPrevLink>
    <!begin:PageNumLinks>
      <!begin:ThisPage><&PAGENUM><!end:ThisPage>
      <!begin:OtherPage>
        <a href="<&PAGELINK>"><&PAGENUM></a>
      <!end:OtherPage>
    <!end:PageNumLinks>
    <!begin:NextLink><a href="<&NEXTLINK>">次ページ→</a><!end:NextLink>
    <!begin:NoNextLink>次ページ→<!end:NoNextLink>
    ...
    <!begin:MaxRows>全<&MAXROWS>件<!end:MaxRows>
    <!begin:FirstRow><&FIRSTROW>件目から<!end:FirstRow>
    <!begin:LastRow><&LASTROW>件目までを表示中<!end:LastRow>
    <!begin:MaxPages>全<&MAXPAGES>ページ<!end:MaxPages>
    <!begin:CurPage>現在<&CURPAGE>ページ目<!end:CurPage>
    ...
    ...
  <!end:paging>
  <!begin:Row>
    <!-- 行データを展開する ＜＆ＸＸＸ＞ タグを半角で記述する -->
  <!end:Row>
  <!-- 以下は Pager クラスの処理とは関係ないため、無くても良い -->
  <!begin:nodata>
    一件もありません
  <!end:nodata>

=head2 METHODS

=over 4

=item $TL->newPager

  $pager = $TL->newPager($db_object)

Pagerオブジェクトを作成。
DBオブジェクトを渡す。

DBのグループ名を渡すこともできるが、この指定方法は今後削除される可能性がある。(obsolute)

引数を指定しなかった場合、デフォルトのDBグループが使用されるが、将来はエラーに変更される可能性がある。

=item setDbGroup

  $pager->setDbGroup($db_group)

非推奨。DBのオブジェクトをnewPagerで渡すことを推奨する。
使用するDBのグループ名を指定する。

=item setPageSize

  $pager->setPageSize($line)

1ページに表示する行数を指定する。デフォルトは30。

=item setCurrentPage

  $pager->setCurrentPage($nowpage)

現在のページ番号を指定する。デフォルトは1。

=item setMaxLinks

  $pager->setMaxLinks($maxlinks)

各ページへのリンクを最大幾つ表示するかを指定する。デフォルトは10。

=item setFormKey

  $pager->setFormKey('PAGE')

ページ移動リンクに挿入される、ページ番号キーを指定する。デフォルトは"pageid"。

=item setFormParam

  $pager->setFormParam($form_obj)
  $pager->setFormParam($hashref)

ページ移動リンクに追加されるフォームを指定する。デフォルトでは何も追加されない。

=item setToLink

  $pager->setToLink($url)

ページ移動リンクに使用されるURLを指定する。デフォルトでは自分自身へのリンクを使用する。

=item setPagingType

  $pager->setPagingType($type)

ページングの種類を選ぶ。

0の場合、最終ページを超えたページを指定した場合、undefが返る。
1の場合、最終ページを超えたページを指定した場合、最終ページが返る。

設定しなかった場合は0が設定される。

但し、1を選択した場合で、最終ページを超えるページを指定した場合、SQLを再度発行するため、通常より遅くなる。

=item getPagingInfo

  my $info = $pager->getPagingInfo

各種パラメータを返す。パラメータの内容は以下の通り。セットされてない場合はundefがセットされている。

=over 4

=item $info->{db}

DBオブジェクト。

または、使用するグループ名。（obsolute）

=item $info->{pagesize}

1ページに表示する行数

=item $info->{current}

表示する（された）ページ番号

=item $info->{maxlinks}

リンクの最大数

=item $info->{formkey}

ページ移動リンクに挿入される、ページ番号キー

=item $info->{formparam}

ページ移動リンクに追加されるフォーム。Tripletail::Formクラス

=item $info->{pagingtype}

ページングの種類

=item $info->{maxpages}

存在している最大ページ

=item $info->{linkstart}

リンクの開始ページ数

=item $info->{linkend}

リンクの終了ページ数

=item $info->{maxrows}

全体の件数

=item $info->{beginrow}

取得を開始した箇所

=item $info->{rows}

取得した件数

=back

=item paging

  $pager->paging($t->node('pagingblock'), $sql, @param)
  $pager->paging($t->node('pagingblock'), [$sql, $maxrows], @param)

指定したノードに、指定したSQLを実行してページングする。
展開するデータが1件も無い場合は 0 を、表示できるページ数を超えたページ数を指定
された場合は、setPagingTypeで設定されている値が0（デフォルト）であれば、undefが、
1であれば最終ページのデータ件数、それ以外の場合はデータ件数を返す。

$maxrows で件数のカウントを別途指定できる。
指定を省略した場合、SQL 文の先頭部分を SELECT SQL_CALC_FOUND_ROWS ～ に書き換えたもの
を使用して、自動的に SELECT FOUND_ROWS() を実行し件数をカウントする。
UNION を使用した場合は正常に動作しない。

=item pagingArray

  $result = $pager->pagingArray($t->node('pagingblock'), $sql, @param)
  $result = $pager->pagingArray($t->node('pagingblock'), [$sql, $maxrows], @param)

指定したノードに、指定したSQLを実行してページングする。
Row ノードは展開せずに、ページング対象のデータを配列の配列へのリファレンスで返す。
展開するデータが1件も無い場合は 0 を、表示できるページ数を超えたページ数を指定
された場合は、setPagingTypeで設定されている値が0（デフォルト）であれば、undefが、
1であれば最終ページのデータを返す。

その他は L</paging> と同じ。

=item pagingHash

  $result = $pager->pagingHash($t->node('pagingblock'), $sql, @param)
  $result = $pager->pagingHash($t->node('pagingblock'), [$sql, $maxrows], @param)

指定したノードに、指定したSQLを実行してページングする。
Row ノードは展開せずに、ページング対象のデータをハッシュの配列へのリファレンスで返す。
展開するデータが1件も無い場合は 0 を、表示できるページ数を超えたページ数を指定
された場合は、setPagingTypeで設定されている値が0（デフォルト）であれば、undefが、
1であれば最終ページのデータを返す。

その他は L</paging> と同じ。

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::DB>

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
