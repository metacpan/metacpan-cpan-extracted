package Tripletail::HtmlFilter;
use strict;
use warnings;
#use Smart::Comments;

our $PURE_PERL = 0;

use Tripletail;
use DynaLoader;
use base 'DynaLoader';
our @XSUBS = qw(next _next_elem Element::parse Element::attr);
our $XS_LOADERROR;
Tripletail::HtmlFilter->my_bootstrap($Tripletail::XS_VERSION);

use constant {
	# 注意: ここを変更した時は XS 側も修正する事。
	INTEREST       => 0,
	TRACK          => 1,
	FILTER_TEXT    => 2,
	FILTER_COMMENT => 3,
	CONTEXT        => 4,
	HTML           => 5,
	OUTPUT         => 6,
};
my %_MATCHER_CACHE;

sub my_bootstrap
{
  my $pkg = shift;
  
  if( !$PURE_PERL )
  {
    local ($@);
    eval
    {
      local($SIG{__DIE__}) = 'DEFAULT';
      $pkg->SUPER::bootstrap(@_);
    };
    $XS_LOADERROR = $@;
  }else
  {
    $XS_LOADERROR = 'disabled';
  }
  
  do
  {
    no strict 'refs';
    #$err and chomp $err;
    #warn "warning: $err";
    foreach my $name (@XSUBS)
    {
      my $xsub = __PACKAGE__.'::'.$name;
      if( !defined(&$xsub) )
      {
        (my $ppsub = $xsub) =~ s/(\w+)$/_$1_pp/;
        *$xsub = \&$ppsub;
      }
    }
  }
}

1;

sub _new {
    my $class = shift;
    my $opts = { @_ };

	my $this = bless [] => $class;

	$this->[INTEREST]       = $opts->{interest};
	$this->[TRACK]          = $opts->{track};
	$this->[FILTER_TEXT]    = $opts->{filter_text};
	$this->[FILTER_COMMENT] = $opts->{filter_comment};
	
    $this->[CONTEXT]        = Tripletail::HtmlFilter::Context->_new;
    $this->[HTML]           = undef; # 文字列
    $this->[OUTPUT]         = []; # Tripletail::HtmlFilter::{Element,Text,Comment}

    # interest, trackに渡された正規表現はこの時点で CODE にコンパイルしておく。
    if ($this->[INTEREST]) {
		$this->[INTEREST] = $this->_compile_matcher($this->[INTEREST]);
    }

    if ($this->[TRACK]) {
		$this->[TRACK] = $this->_compile_matcher($this->[TRACK]);
    }

    $this;
}

sub set {
    my $this = shift;
    my $html = shift;

    if (not defined $html) {
		die __PACKAGE__."#set: ARG[1] is not defined.\n";
    }
    elsif (ref $html) {
		die __PACKAGE__."#set: ARG[1] is a Ref.\n";
    }

    #@{$this->[HTML]} = split m/(<.+?>)/s, $html;
    # ↑では、<!-- <hoge> -->を正しく解析できない。真面目にパーズする必要がある
    # しかし、perlで真面目にパーザを書くのは非常に面倒なので正規表現で誤魔化す
    # NB: 他にも、正しく解析できないパターンが存在するかも
    @{$this->[HTML]} = split m/((?:<!--.*?-->)|(?:<.+?>))/s, $html;
    @{$this->[OUTPUT]} = ();
    $this;
}

sub toStr {
    my $this = shift;

    $this->[CONTEXT]->_flush($this); # 未確定の部分を確定する

    join('', map {ref($_)?$_->toStr:$_} @{$this->[OUTPUT]});
}

sub _compile_matcher {
	my $this = shift;
	my $regexes = shift;

	my $joined = join('', @$regexes);
	if (my $cached = $_MATCHER_CACHE{$joined}) {
		return $cached;
	}

	my $ret = [];
	foreach my $reg (@$regexes) {
		if (ref($reg) eq 'Regexp') {
			# コンパイル済み正規表現だった。
			push @$ret, sub {
				return 1 if $_[0] =~ $reg;
			};
		}
		else {
			# 単純な文字列だった。
			push @$ret, lc $reg;
		}
	}

	$_MATCHER_CACHE{$joined} = $ret;
	$ret;
}

sub _next_pp {
    my $this = shift;
    $this->[CONTEXT]->_flush($this); # 未確定の部分を確定する
    
    while (@{$this->[HTML]}) {
		my $str = shift @{$this->[HTML]};
		my $parsed;
		my $interested;
	
		if ($str =~ m/^<!--\s*(.+?)\s*-->$/) {
			# コメント
			if ($this->[FILTER_COMMENT]) {
				$interested = $this->[CONTEXT]->newComment($1);
			}
		} elsif ($str =~ m/^</) {
			# 要素
			if ($this->[TRACK] or $this->[INTEREST]) {
				($interested,$parsed) = $this->_next_elem($str);
			}
		} else {
			# テキスト
			if ($this->[FILTER_TEXT]) {
				# 興味を持ってるときはオブジェクトにして返す. 
				$interested = $this->[CONTEXT]->newText($str);
			}
		}

		if ($interested) {
			# この要素は興味を持たれている。
			$this->[CONTEXT]->_current($interested);
			return ($this->[CONTEXT], $interested);
		} else {
			# そうでないなら出力に書いて次へ
			push(@{$this->[OUTPUT]},$parsed||$str);
		}
    }
	
    ();
}

sub __next_elem_pp {
	my $this = shift;
	my $str = shift;
	my $elem = $this->[CONTEXT]->newElement;
	$elem->parse($str);
	my $elem_name = $elem->name;

	my $is_matched = sub {
		my $matcher = shift;
		my $str = lc shift;

		foreach my $m (@$matcher) {
			if (ref $m) {
				if ($m->($str)) {
					return 1;
				}
			}
			else {
				if ($m eq $str) {
					return 1;
				}
			}
		}

		undef;
	};

	my ($interested,$parsed);
	if (defined $elem_name) {
		my ($close,$nameonly) = $elem_name =~ /^(\/?)(.*)/;
		
		if ($this->[TRACK] and $is_matched->($this->[TRACK], $nameonly)) {
			$parsed = $elem;
			if ($close) {
				$this->[CONTEXT]->removein($nameonly);
			}
			else {
				$this->[CONTEXT]->addin($nameonly => $parsed);
			}
		}
    
		if ($this->[INTEREST] and $is_matched->($this->[INTEREST], $elem_name)) {
			$interested = $elem;
		}
	}
	($interested,$parsed);
}

sub _output {
    my $this = shift;
    my $elem = shift;
    # 渡されたオブジェクト(若しくはテキスト)を
    # $this->[OUTPUT] に追加しているだけ. 
    # 直接pushしているコードもあるので修正する際には注意. 
    push @{$this->[OUTPUT]}, $elem;
    $this;
}


# =============================================================================
# Tripletail::HtmlFilter::Context.
#
package Tripletail::HtmlFilter::Context;
use constant {
	IN      => 0,
	ADDED   => 1,
	DELETED => 2,
	CURRENT => 3,
};

sub _new {
    my $class = shift;

    my $this = bless [] => $class;
    $this->[IN] = [];
    $this->[ADDED] = [];
    $this->[DELETED] = undef;
    $this->[CURRENT] = undef; # Tripletail::HtmlFilter::{Element,Comment,Text}

    $this;
}

sub newElement {
    my $this = shift;
    my $name = shift;

    Tripletail::HtmlFilter::Element->_new($name);
}

sub newText {
    my $this = shift;
    my $str = shift;

    Tripletail::HtmlFilter::Text->_new($str);
}

sub newComment {
    my $this = shift;
    my $str = shift;

    Tripletail::HtmlFilter::Comment->_new($str);
}

sub addin {
    my $this = shift;
    my $name = lc shift;
    my $elem = shift;

    unshift(@{$this->[IN]}, [$name, $elem]);
    
    $this;
}

sub removein {
    my $this = shift;
    my $name = lc shift;

    while(my $elem = shift(@{$this->[IN]})) {
		last if($elem->[0] eq $name);
    }
    
    $this;
}

sub in {
    my $this = shift;
    my $name = lc shift;

    foreach my $elem (@{$this->[IN]}) {
		if($elem->[0] eq $name) {
			return $elem->[1];
		}
    }

    return undef;
}

sub add {
    my $this = shift;
    my $elem = shift;

    if (not defined $elem) {
		die __PACKAGE__."#add: ARG[1] is not defined.\n";
    }
    elsif (my $pkg = ref $elem) {
		if ($pkg !~ m/^Tripletail::HtmlFilter::(?:Element|Text|Comment)$/) {
			die __PACKAGE__."#add, ARG[1] is an unacceptable Ref. [$elem]\n";
		}
    }
    else {
		# refでなければテキストとして扱う。
		$elem = $this->newText($elem);
    }

    push @{$this->[ADDED]}, $elem;
    $this;
}

sub delete {
    my $this = shift;
    $this->[DELETED] = 1;
}

sub _current {
    my $this = shift;
    my $elem = shift;
    
    $this->[CURRENT] = $elem;
}

sub _flush {
    my $this = shift;
    my $filter = shift;
    
    if (not $this->[CURRENT]) {
		return $this; # 何もする必要が無い
    }

    if ($this->[DELETED]) {
		# 削除するように指示された。
		$this->[DELETED] = undef;
    }
    else {
		$filter->_output($this->[CURRENT]);
    }

    foreach (@{$this->[ADDED]}) {
		$filter->_output($_);
    }
    @{$this->[ADDED]} = ();

    $this->[CURRENT] = undef;
    $this;
}

# =============================================================================
# Tripletail::HtmlFilter::ElementBase.
#
package Tripletail::HtmlFilter::ElementBase;
sub isElement {
    my $this = shift;
    (ref $this) eq 'Tripletail::HtmlFilter::Element';
}

sub isText {
    my $this = shift;
    (ref $this) eq 'Tripletail::HtmlFilter::Text';
}

sub isComment {
    my $this = shift;
    (ref $this) eq 'Tripletail::HtmlFilter::Comment';
}

# =============================================================================
# Tripletail::HtmlFilter::Element.
#
package Tripletail::HtmlFilter::Element;
use constant {
	# 注意: ここを変更した時は XS 側も修正する事。
	NAME   => 0,
	ATTRS  => 1,
	ATTR_H => 2,
	TAIL   => 3,
};
our @ISA = qw(Tripletail::HtmlFilter::ElementBase);

sub _new {
    my $class = shift;
    my $name = shift; # undef可

    if (ref $name) {
		die __PACKAGE__."#_new, ARG[1] was bad Ref. [$name]\n";
    }

    my $this = bless [] => $class;
    $this->[NAME] = $name;
    $this->[ATTRS] = []; # [[key, val], [key, val], ...]
    $this->[ATTR_H] = {}; # key => [key, val] ($this->[ATTRS]の要素と共有)
    $this->[TAIL] = undef;

    $this;
}

sub name {
	# 注意: このメソッドは XS 側では使用されない。
    my $this = shift;
    if (@_) {
		$this->[NAME] = shift;

		if (ref $this->[NAME]) {
			die __PACKAGE__."#name: ARG[1] is a Ref. [".$this->[NAME]."]\n";
		}
    }
    $this->[NAME];
}

sub _parse_pp {
    my $this = shift;
    local($_) = shift;

    if (ref) {
		die __PACKAGE__."#parse: ARG[1] is a Ref. [$_]\n";
    }

    s/^<//;

    (s/^\s*(\/?\w+)//) and ($this->[NAME] = $1);

    while(1) {
        (s/([\w:\-]+)\s*=\s*"([^"]*)"//)     ? ($this->attr($1 => $2)) :
          (s/([\w:\-]+)\s*=\s*'([^']*)'//)   ? ($this->attr($1 => $2)) :
            (s/([\w:\-]+)\s*=\s*([^\s>]+)//) ? ($this->attr($1 => $2)) :
              (s~(\w+|/)~~)                  ? ($this->end($1)) :
                last;
    }

    $this;
}

sub _attr_pp {
    my $this = shift;
    my $key = shift;

    if (not defined $key) {
		die __PACKAGE__."#attr: ARG[1] is not defined.\n";
    }
    elsif (ref $key) {
		die __PACKAGE__."#attr: ARG[1] is a Ref. [$key]\n";
    }
    
    if (@_) {
		my $val = shift;

		if (ref $val) {
			die __PACKAGE__."#attr: ARG[2] is a Ref. [$val]\n";
		}
	
		if (defined $val) {
			# この属性が既にあるなら上書き。無ければ末尾に追加。
			my $lc_key = lc $key;
			
			if (my $old = $this->[ATTR_H]{$lc_key}) {
				$old->[1] = $val;
			}
			else {
				my $pair = [$key, $val];
				push @{$this->[ATTRS]}, $pair;
				$this->[ATTR_H]{$lc_key} = $pair;
			}
		}
		else {
			# この属性を消去
			if (my $old = $this->[ATTR_H]{lc $key}) {
				delete $this->[ATTR_H]{$key};
				
				@{$this->[ATTRS]} = grep {
					lc($_->[0]) ne lc($key);
				} @{$this->[ATTRS]};
			}
		}

		$val;
    }
    else {
		if (my $pair = $this->[ATTR_H]{lc $key}) {
			$pair->[1];
		}
		else {
			undef; # 存在しない
		}
    }
}

sub attrList {
    my $this = shift;

    map { $_->[0] } @{$this->[ATTRS]}
}

sub tail {
	goto &end;
}

sub end {
	# 注意: このメソッドは XS 側では使用されない。
    my $this = shift;
    if (@_) {
		$this->[TAIL] = shift;

		if (ref $this->[TAIL]) {
			die __PACKAGE__."#end: ARG[1] is a Ref. [$this->[TAIL]]\n";
		}
    }
    $this->[TAIL];
}

sub toStr {
    my $this = shift;
    my $str = '<' . $this->[NAME];

    foreach my $attr (@{$this->[ATTRS]}) {
        my $key   = $attr->[0];
        my $value = $attr->[1];
        $value =~ s/"/&quot;/g;
        $str .= sprintf(qq{ %s="%s"}, $key, $value);
    }

    if( defined $this->[TAIL] and length $this->[TAIL] )
	{
		$str .= ' ' . $this->[TAIL];
    }

    $str .= '>';
}

# =============================================================================
# Tripletail::HtmlFilter::Text.
#
package Tripletail::HtmlFilter::Text;
use constant {
	STR => 0,
};
our @ISA = qw(Tripletail::HtmlFilter::ElementBase);

sub _new {
    my $class = shift;
    my $str = shift;

    my $this = bless [] => $class;
    $this->[STR] = $str;

    $this;
}

sub str {
    my $this = shift;
    if (@_) {
		$this->[STR] = shift;

		if (ref $this->[STR]) {
			die ref($this)."#str: ARG[1] is a Ref. [".$this->[STR]."]\n";
		}
    }
    $this->[STR];
}

sub toStr {
    my $this = shift;
    $this->[STR];
}

# =============================================================================
# Tripletail::HtmlFilter::Comment.
#
package Tripletail::HtmlFilter::Comment;
our @ISA = qw(Tripletail::HtmlFilter::Text);
use constant {
	STR => Tripletail::HtmlFilter::Text::STR(),
};


sub toStr {
    my $this = shift;
    sprintf '<!-- %s -->', $this->[STR];
}


__END__

=encoding utf-8

=head1 NAME

Tripletail::HtmlFilter - HTMLのパースと書き換え

=head1 SYNOPSIS

  my $filter = $TL->newHtmlFilter(
      interest => ['form', 'textarea'],
  );
  $filter->set($html);
  
  while (my ($context, $elem) = $filter->next) {
      ...
  }

  print $filter->toStr;

=head1 DESCRIPTION

=head2 METHODS

=head3 Tripletail::HtmlFilter

=over 4

=item new

  $TL->newHtmlFilter(%options)

フィルタオブジェクトを作る。オプションは以下の通り:

=over 8

=item interest

要素名、もしくは要素名にマッチする正規表現を要素とする配列。
正規表現の場合は C<qr//> でコンパイルしなければならない。
マッチしなかった要素はスキップされる。省略可能。

注意: 要素が文字列の場合は大文字小文字を無視した比較がされるが、
正規表現で同じ動作をさせるには qr/h\d/i のように i フラグを
付けなければならない。

=item track

要素名、もしくは要素名にマッチする正規表現を要素とする配列。
正規表現の場合は C<qr//> でコンパイルしなければならない。
マッチした要素は、その子要素内で取り出す事が出来る。省略可能。

注意: 要素が文字列の場合は大文字小文字を無視した比較がされるが、
正規表現で同じ動作をさせるには qr/h\d/i のように i フラグを
付けなければならない。

=item filter_text

真なら要素内のテキスト部分も検出する。

=item filter_comment

真ならコメントも検出する。

=item my_bootstrap

内部メソッド

=back

=item set

  $filter->set($html)

パース対象のHTMLを設定する。

=item toStr

  my $html = $filter->toStr()

フィルタリング結果のHTMLを文字列で返す。

=item next

  my ($context, $elem) = $filter->next;

次の要素/テキスト/コメントを取り出す。
戻り値は二つで、最初の項目は L</"Tripletail::HtmlFilter::Context"> 、
次の項目は L</"Tripletail::HtmlFilter::ElementBase"> のオブジェクトである。

=back


=head3 Tripletail::HtmlFilter::Context

=over 4

=item newElement

  $context->newElement($name)

指定された要素名を持つ L</"Tripletail::HtmlFilter::Element"> を作成して返す。

=item newText

  $context->newText($str)

指定された内容を持つ L</"Tripletail::HtmlFilter::Text"> を作成して返す。

=item newComment

  $context->newComment($str)

指定された内容を持つ L</"Tripletail::HtmlFilter::Comment"> を作成して返す。

=item in

  my $element = $context->in($name)

現在の文脈が、指定された名前を持つ要素の中であれば、その要素を返す。
要素の中であるとは、現在の要素がその要素の子孫であるか、その要素内に
含まれるテキストやコメントである場合を云う。

=item add

  $context->add($elem)
  $context->add('text')

新たな要素を、現在の要素の直後に挿入する。
引数は文字列または L</"Tripletail::HtmlFilter::ElementBase"> でなければならない。
C<< $context->add('text') >> は
C<< $context->add($context->newText('text')) >> と同値である。

=item delete

現在の要素を削除する。 

=back


=head3 Tripletail::HtmlFilter::ElementBase

このクラスは以下のクラスの親クラスである。

=over 4

=item L</"Tripletail::HtmlFilter::Element">

=item L</"Tripletail::HtmlFilter::Text">

=item L</"Tripletail::HtmlFilter::Comment">

=back

=over 4

=item isElement

  $elem->isElement()

L</"Tripletail::HtmlFilter::Element"> のインスタンスであれば1を返す。

=item isText

L</"Tripletail::HtmlFilter::Text"> のインスタンスであれば1を返す。

=item isComment

L</"Tripletail::HtmlFilter::Comment"> のインスタンスであれば1を返す。

=back


=head3 Tripletail::HtmlFilter::Element

=over 4

=item name

  $elem->name()
  $elem->name($new_name)

要素名を返す。引数が与えられた場合は要素名を変更する。
元の要素名が大文字であった場合には、この関数も大文字で返す事に注意。

=item parse

  $elem->parse('<foo bar="111" baz="222">')

文字列で渡されたHTML要素をパースして、要素名と属性を置き換える。

=item attr

  $elem->attr($key)
  $elem->attr($key => $value)

指定された属性名を持つ属性があれば、その値を返す。
引数が二つ指定された場合は、指定された属性値を書換える。
属性名の大文字小文字は保存されるが、検索時には区別されない。

=item attrList

  my @attrs = $elem->attrList()

存在する全ての属性名を配列で返す。

=item end

  $elem->end()
  $elem->end('checked')

属性値の存在しない属性名があれば返す。値が指定された場合は、その値を設定する。
input要素の"checked"等、またXHTMLの空要素 "/" が該当する。

=item tail

end の別名。

=item toStr

  $str = $elem->toStr

要素を文字列化する。この要素が文字列をパースして作られたものである時は、
パースした文字列の属性の順序が保存される。

=back


=head3 Tripletail::HtmlFilter::Text

=over 4

=item str

  $elem->str()
  $elem->str($string)

テキストの内容を返す。値が指定された場合は、内容を置き換える。

=item toStr

テキストの内容を返す。 

=back


=head3 Tripletail::HtmlFilter::Comment

=over 4

=item str

  $elem->str()
  $elem->str($string)

コメントの内容を返す。"E<lt>!-- --E<gt>"は付かない。
値が指定された場合は内容を置き換える。文字列が"--"を含んでいてはならない。

=item toStr

"E<lt>!-- --E<gt>"を付けた内容を返す。 

=back


=head2 サンプル

=head3 コード

 # フィルタの準備
 my $filt = $TL->newHtmlFilter(
     # a, form, b要素のみ検出する。bは閉じタグも見る。それ以外は見ない。
     interest => [qw(^a$ form /?b)], # 正規表現の配列
     
     # select, option要素の場合は、その要素内で$context->in('select')を呼ぶ事で
     # Tripletail::HtmlFilter::Elementのオブジェクトを得る事が出来る。
     track => [qw(select option)], # 正規表現の配列
     
     # 真ならタグ以外の部分も見る。コメントは別扱い。
     filter_text => 1,
 
     # 真ならコメントの部分も見る。
     filter_comment => 1,
    );
 
 # フィルタに通すHTMLを設定
 $filt->set(q{
 <form>
   <select>
     <a href="http://example.com/" target="_new">foo</a>
     <b>bold</b>
     <option></option>
   </select>
   <!-- this is a comment -->
 </form>});
 
 while (my ($context, $elem) = $filt->next) {
     if ($elem->isElement) {
         if ($elem->name eq 'a') {
             # <select>要素の中なら、href属性を書換える
             if ($context->in('select')) {
                 $elem->attr(href => 'http://ymir.jp/');
             }
         }
         elsif ($elem->name eq 'form') {
             # form要素の開始直後に別の要素を挿入
             my $hidden = $context->newElement('input');
             $hidden->attr(name => 'foo');
             $hidden->attr(type => 'hidden');
             $hidden->end('/'); # <input name="foo" type="hidden" />を作る
             
             $context->add($hidden);
         }
         elsif ($elem->name eq 'b' or $elem->name eq '/b') {
             # b要素は消す。
             $context->delete;
         }
     }
     elsif ($elem->isText) {
         if ($context->in('option')) {
             # <option>の中なら書換える
             $context->delete;
             $context->add('AAAAA'); # テキストを追加。
             # $context->add($context->newText('AAAAA')); と等価。
 
             # 同時にこのテキストの親であるoption要素に属性を追加する。
             $context->in('option')->attr(foo => 'bar');
         }
     }
     elsif ($elem->isComment) {
         # コメントは全て消す。
         $context->delete;
     }
 }
 
 # フィルタリング結果を出力する
 print $filt->toStr, "\n";


=head3 実行結果

 <form><input name="foo" type="hidden" />
   <select>
     <a href="http://ymir.jp/" target="_new">foo</a>
     bold
     <option foo="bar">AAAAA</option>
   </select>
 
 </form>


=head1 SEE ALSO

L<Tripletail>

=cut
