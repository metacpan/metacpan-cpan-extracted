# -----------------------------------------------------------------------------
# Tripletail::Validator - 値の検証の一括処理
# -----------------------------------------------------------------------------
package Tripletail::Validator;
use strict;
use warnings;
use Tripletail;

use Tripletail::Validator::FilterFactory;

1;

#---------------------------------- 一般
sub _new {
	my $class = shift;
	return bless { _filters => {} }, $class;
}

sub addFilter {
	my $this    = shift;
	my $filters = shift;

	while ( my ( $key, $value ) = each %$filters ) {
		$this->{_filters}->{$key} = [];
		while ( $value =~ s/(\w+)(?:\((.*?)\))?(?:\[(.*?)\])?(?:;|$)// ) {
			my ( $filter, $args, $message ) = ( $1, $2, $3 );
			push(
				@{ $this->{_filters}->{$key} },
				{
					filter  => $filter,
					args    => $args,
					message => $message,
				}
			);
		}
#		$TL->log(
#			'Tripletail::Validator' => qq/addFilter { $key } : / . join(
#				', ',
#				map {
#					    $_->{filter}
#					  . ( defined( $_->{args} )    ? qq{($_->{args})}    : '' )
#					  . ( defined( $_->{message} ) ? qq{[$_->{message}]} : '' )
#				  } @{ $this->{_filters}->{$key} }
#			)
#		);
	}

	return $this;
}

sub check {
	my $this = shift;
	my $form = shift;
	# correctフィルタがある場合はエラーとする
	foreach my $key ( keys %{ $this->{_filters} } ) {
		foreach my $filter ( @{ $this->{_filters}->{$key} } ) {
			if(Tripletail::Validator::FilterFactory::getFilter($filter->{filter})->isCorrectFilter) {
				die __PACKAGE__."#check: with the check() method, you can't use any filters which may modify values. Use the correct() method instead.".
					" (checkメソッドではcorrentフィルタを使用することは出来ません。correctメソッドを利用してください)\n";
			}
		}
	}
	$this->_execFilter($form, 0);
}

sub correct {
	my $this = shift;
	my $form = shift;
	if($form->isConst) {
		die __PACKAGE__."#correct: the instance of Tripletail::Form is a const object.".
			" (Formオブジェクトの変更が禁止されています)\n";
	}
	$this->_execFilter($form, 1);
}
sub _execFilter {
	my $this = shift;
	my $form = shift;
	my $allowmodify = shift;
	my $onfail;
	my $error;

	foreach my $key ( keys %{ $this->{_filters} } ) {
		my @values = $form->getValues($key);
		my $empty_exists = !@values && $form->exists($key);
		foreach my $filter ( @{ $this->{_filters}->{$key} } ) {
#			my $diag = do
#			{
#				my $vals = join(', ', @values);
#				my $diag = "{ $key => [$vals] } : $filter->{filter}";
#				defined($filter->{args}) and $diag .= "($filter->{args})";
#				defined($filter->{message}) and $diag .= "[$filter->{message}]";
#				$diag;
#			};
			
			my @oldvalues = @values;
			my $res = Tripletail::Validator::FilterFactory::getFilter( $filter->{filter} )->doFilter( \@values, $filter->{args} );
			if( !$allowmodify )
			{
				@values = @oldvalues;
			}
			if( !$res )
			{
#				$TL->log( 'Tripletail::Validator' => "ok $diag");
				next;
			}
			
			if( ref($res) )
			{
#				$TL->log( 'Tripletail::Validator' => "ok and skip $diag");
			}else
			{
#				$TL->log( 'Tripletail::Validator' => "error $diag");
				
				$error->{$key} =
				  defined( $filter->{message} )
				  ? $filter->{message}
				  : $filter->{filter};
			}
			last;
		}
		if( $allowmodify )
		{
			# @values が空の時は削除される.
			$form->set($key => \@values);
		}
	}
	if( $error && $onfail )
	{
		my $message = $this->_checkerror_to_message($error);
		$onfail->($error, $message);
	}

	return $error;
}

sub _checkerror_to_message
{
	my $this = shift;
	my $error = shift;
	my $message = join(', ', map{ "$_($error->{$_})" } sort keys %$error );
	$message;
}


sub getKeys {
	my $this = shift;
	return keys %{ $this->{_filters} };
}

__END__

=encoding utf-8

=head1 NAME

Tripletail::Validator - 値の検証の一括処理

=head1 SYNOPSIS

  my $validator = $TL->newValidator;
  $validator->addFilter(
    {
      name  => 'NotBlank',
      email => 'Email',
      optionemail => 'Blank;Email',  # 入力しなくてもOKとする
      password => 'CharLen(4,8);Password',
    }
  );
  my $error = $validator->check($form);

=head1 DESCRIPTION

Formオブジェクト値の検証の一括処理を行う。

=head1 METHODS

=over 4

=item $TL->newValidator

  $validator = $TL->newValidator

Tripletail::Validator オブジェクトを作成。

=item addFilter

  $validator->addFilter(
    {
      name  => 'NotBlank',
      email => 'Email',
      optionemail => 'Empty;Email',  # 入力しなくてもOKとする
      password => 'CharLen(4,8);Password',
    }
  )

バリデータにフィルタを設定する。
検証対象となるフォームのキーに対し、フィルタリストを指定する。

フィルタ指定形式としては、

  FilterName(args)[message]

を、「;」区切りとする。
「(args)」や、「[message]」は省略可能。
「(args)」を省略した場合は、それぞれのフィルタによりデフォルトのチェックを行う。
「[message]」を省略した場合は、checkの戻り時にフィルタ名を返す。

=item check

  $error = $validator->check($form)
  $error = $validator->check($form, sub{...} )

設定したフィルタを利用して、フォームの値を検証する。

それぞれのフォームのキーに対してエラーがあれば、「[message]」、
もしくは指定がない場合はフィルタ名を値としたハッシュリファレンスを返す。
エラーがなければ、そのキーは含まれない。

２番目の引数に関数リファレンスを渡すと, エラー時にそれが呼ばれる。
エラーがなかった場合には呼ばれない。
引数として、１つめに check メソッドが返すのと同じハッシュを、
２つめに文字列でのエラーメッセージを渡す。

変更用フィルタを使用しようとした場合はエラーを返す。

=item correct

  $error = $validator->correct($form)
  $error = $validator->correct($form, sub{...} )

設定したフィルタを利用して、フォームの値を検証する。
また、変更用フィルタを使った場合はフォームの値を修正する。

それぞれのフォームのキーに対してエラーがあれば、「[message]」、
もしくは指定がない場合はフィルタ名を値としたハッシュリファレンスを返す。
エラーがなければ、そのキーは含まれない。

２番目の引数に関数リファレンスを渡すと, エラー時にそれが呼ばれる。
エラーがなかった場合には呼ばれない。
引数として、１つめに check メソッドが返すのと同じハッシュを、
２つめに文字列でのエラーメッセージを渡す。

$form に const メソッドが呼ばれた Form オブジェクトが渡された場合、
エラーを返す。

=item getKeys

  @keys = $validator->getKeys

現在設定されているフィルタのキー一覧を返す。

=back

=head2 フィルタ一覧

=head3 組み込みcheckフィルタ

=over 4

=item Empty

値が空（存在しないか0文字）であることをチェックし、そうであれば以降の判定を中止し、検証OKとする。

Email等の形式である必要があるが、入力が任意であるような項目のチェックに使用する。

=item NotEmpty

値が空（存在しないか0文字）でないことをチェックする。

値の形式を問わないが、入力必須としたい場合に使用する。

=item NotWhitespace

半角/全角スペース、タブのみでないことをチェックする。
値が空（存在しないか0文字）の場合は検証NGとなる。

=item Blank

値が空（存在しないか0文字）、半角/全角スペース、タブのみであることをチェックし、そうであれば以降の判定を中止し、検証OKとする。

Email等の形式である必要があるが、入力が任意であるような項目のチェックに使用する。空白のみなら入力無しとみなす。

=item NotBlank

値が空（存在しないか0文字）、半角/全角スペース、タブのみでないことをチェックする。

値の形式を問わないが、入力必須としたい場合に使用する。空白のみなら入力無しとみなす。

=item PrintableAscii

文字列が制御コードを除くASCII文字のみで構成されているかチェックする。
値が空（存在しないか0文字）なら検証NGとなる。

=item Wide

文字列が全角文字のみで構成されているかチェックする。
値が空（存在しないか0文字）なら検証NGとなる。

=item Password($spec)

文字列が$specに指定した要素をすべて最低1つずつ含んでいるかチェックする。

$specに指定できるのはC<alpha>, C<ALPHA>, C<digit>, C<symbol>をカンマ区切りで指定した文字列で、
指定がない場合はすべて指定した場合と同様となる。
また、指定された文字以外が入っていることに関しては考慮しない。

値が空（存在しないか0文字）なら検証NGとなる。

L<Tripletail::Value/isPassword>

=item ZipCode

7桁の郵便番号（XXX-XXXX形式）かチェックする。

実在する郵便番号かどうかは確認しない。

=item TelNumber

電話番号（/^\d[\d-]+\d$/）かチェックする。

数字で始まり、数字で終わり、その間が数字とハイフン(-)のみで構成されていれば電話番号とみなす。

=item Email

メールアドレスとして正しい形式かチェックする。

=item MobileEmail

メールアドレスとして正しい形式かチェックする。

但し携帯電話のメールアドレスでは、アカウント名の末尾にピリオドを含んでいる場合がある為、これも正しい形式であるとみなす。 

携帯電話キャリアのドメイン名を判別するわけではないため、通常のメールアドレスも正しい形式であるとみなす。

=item Integer($min,$max)

整数で、かつ$min以上$max以下かチェックする。指定値は省略可能。

デフォルトでは、最大最小のチェックは行わなず整数であれば正しい形式であるとみなす。

値が空（存在しないか0文字）なら検証NGとなる。

=item Real($min,$max)

整数もしくは小数で、かつ$min以上$max以下かチェックする。指定値は省略可能。 

デフォルトでは、最大最小のチェックは行わなず、整数もしくは小数であれば正しい形式であるとみなす。

値が空（存在しないか0文字）なら検証NGとなる。

=item Hira

平仮名だけが含まれているかチェックする。

値が空（存在しないか0文字）なら検証NGとなる。

=item Kata

片仮名だけが含まれているかチェックする。

値が空（存在しないか0文字）なら検証NGとなる。

=item ExistentDay

YYYY-MM-DDで設定された日付が実在するかチェックする。

=item Gif

=item Jpeg

=item Png

それぞれの形式の画像かチェックする。

画像として厳密に正しい形式であるかどうかは確認しない。

=item HttpUrl($mode)

"http://" で始まる文字列かチェックする。

$modeにs を指定した場合、"https://" で始まる文字列も正しい形式とみなす。

=item HttpsUrl

"https://" で始まる文字列かチェックする。

=item Len($min,$max)

バイト数の範囲が指定値以内かチェックする。 指定がない場合はチェックを行わない。

=item SjisLen($min,$max)

Shift-Jisでのバイト数の範囲が指定値以内かチェックする。指定がない場合はチェックを行わない。

=item CharLen($min,$max)

文字数の範囲が指定値以内かチェックする。 指定値がない場合はチェックを行わない。

=item Portable

機種依存文字を含んでいないかチェックする。

値が空（存在しないか0文字）なら検証OKとなる。

=item PcPortable

携帯絵文字を含んでいないかチェックする。

値が空（存在しないか0文字）なら検証OKとなる。

=item DomainName

ドメイン名として正当である事を確認する。

=item IpAddress

  IpAddress($checkmask)

$checkmaskに対して、設定されたIPアドレスが一致すれば1。そうでなければundef。
	
$checkmaskは空白で区切って複数個指定する事が可能。

例：'10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 127.0.0.1 fe80::/10 ::1'。

=item Enum($a,$b,$c)

値が指定値のいずれかであることをチェックする。指定値がない場合にはいずれにも該当しないとみなす。

=item Or($filter1|$filter2|$filter3)

指定のフィルタのいずれかに該当するかをチェックする。指定値がない場合にはいずれにも該当しないとみなす。

=item RegExp($regexp)

指定の正規表現に該当するかをチェックする。指定値がない場合には、エラー。

=item SingleValue

値がただ1つ存在することをチェックする拒否フィルタ。
(0.44 以降)

1つのみ存在すれば、次のフィルタに処理を渡す。

2つ以上存在する、若しくは1つも存在しない場合には、
その時点で処理を中断し、エラーを返す。

=item MultiValues

  MultiValues($min)
  MultiValues($min,$max)

値が指定した C<$min> 個以上, C<$max> 個以下の範囲で
存在することをチェックする拒否フィルタ。
(0.44 以降)

個数が範囲内であれば、
次のフィルタに処理を渡す。

個数が範囲外だった場合には、
その時点で処理を中断し、エラーを返す。

C<$max> を省略した場合、上限個数の確認は行わない。

値が0個で、それが範囲内のときのみ(C<$min> が 0 の場合)、その場で受理される.
(0.45以降)

=item NoValues

値が存在しないことを受け付ける受理フィルタ。
(0.44 以降)

値を全く持っていなければ、
その時点で処理を中断し、成功を返す。

何らかの値が(空欄であったとしても)存在した場合には、
次のフィルタに処理を渡す。

=back

=head3 組み込みcorrectフィルタ

L</correct> で使用できる変更用フィルタ。
L</correct> では check フィルタと correct フィルタの
両方を利用できるが、L</check> で correct フィルタを使用した場合には
エラーとなる。

=over 4

=item ConvHira

ひらがなに変換する。
L<Tripletail::Value/convHira>。

=item ConvKata

カタカナに変換する。
L<Tripletail::Value/convKata>。

=item ConvNumber

半角数字に変換する。
L<Tripletail::Value/convNumber>。

=item ConvNarrow

全角文字を半角に変換する。
L<Tripletail::Value/convNarrow>。

=item ConvWide

半角文字を全角に変換する。
L<Tripletail::Value/convWide>。

=item ConvKanaNarrow

全角カタカナを半角に変換する。
L<Tripletail::Value/convKanaNarrow>。

=item ConvKanaWide

半角カタカナを全角に変換する。
L<Tripletail::Value/convKanaWide>。

=item ConvComma

半角数字を3桁区切りのカンマ表記に変換する。
L<Tripletail::Value/convComma>。

=item ConvLF

改行コードを LF (\n) に変換する。
L<Tripletail::Value/convLF>。


=item ConvBR

改行コードを <BR>\n に変換する。
L<Tripletail::Value/convBR>。

=item ForceHira

ひらがな以外の文字は削除。
L<Tripletail::Value/forceHira>。

=item ForceKata

カタカナ以外の文字は削除。
L<Tripletail::Value/forceKata>。

=item ForceNumber

半角数字以外の文字は削除。
L<Tripletail::Value/forceNumber>。

=item ForceMin($max,$val)

半角数字以外の文字を削除し、min未満なら$valをセットする。$val省略時はundefをセットする。
L<Tripletail::Value/forceMin($max,$val)>。

=item ForceMax($max,$val)

半角数字以外の文字を削除し、maxより大きければ$valをセットする。$val省略時はundefをセットする。
L<Tripletail::Value/forceMax($max,$val)>。

=item ForceMaxLen($max)

最大バイト数を指定。超える場合はそのバイト数までカットする。
L<Tripletail::Value/forceMaxLen($max)>。

=item ForceMaxUtf8Len($max)

UTF-8での最大バイト数を指定。
超える場合はそのバイト数以下まで
UTF-8の文字単位でカットする。
L<Tripletail::Value/forceMaxUtf8Len($max)>。

=item ForceMaxSjisLen($max)

SJISでの最大バイト数を指定。超える場合はそのバイト数以下まで
SJISの文字単位でカットする。
L<Tripletail::Value/forceMaxSjisLen($max)>。

=item ForceMaxCharLen($max)

最大文字数を指定。超える場合はその文字数以下までカットする。
L<Tripletail::Value/forceMaxCharLen($max)>。

=item ForcePortable

機種依存文字以外を削除。

=item ForcePcPortable

携帯絵文字以外を削除。

=item TrimWhitespace

値の前後に付いている半角/全角スペース、タブを削除する。
L<Tripletail::Value/trimWhitespace>。

=back

=head3 ユーザー定義フィルタについて

組み込みフィルタに含まれないフィルタを、ユーザーで実装し、組み込むことができる。

=head4 フィルタの構築

Tripletail::Validator::Filterクラスを継承し、doFilterメソッドをオーバーライドする。

doFilterメソッドに渡される引数は、以下の通り。

=over 4

=item $this

フィルタオブジェクト自身

=item $values

チェック対象となる値の配列の参照。

=item $args

フィルタに与えられる引数。

=back

doFilterメソッドの戻り値をスカラで評価し、その復帰値が真で且つ
リファレンスでなければ検証NGと判断する。
偽であれば、そのフィルタは通過して次のフィルタに。
リファレンスであればそのキーは検証OKとして、そのキーの検証を終了する。

=head4 フィルタの組み込み

IniパラメータのValidatorグループに、

  フィルタ名 = フィルタクラス名

として指定する。

=head4 例

チェック対象となる値の配列に、'Test'以外の文字列が含まれていればエラー。

=over 4

=item TestFilter.pm

  package TestFilter;
  use Tripletail;
  
  use base qw{Tripletail::Validator::Filter};
  
  sub doFilter {
    my $this   = shift;
    my $values = shift;
    my $args   = shift;
    
    return grep { $_ ne 'Test' } @$values > 0;
  }

=item Iniファイル

  [Validator]
  Test = TestFilter

=item 使い方

  $validator->addFilter(
    {
      test => 'Test',
    }
  )

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::Value>

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
