# -----------------------------------------------------------------------------
# Tripletail::CSV - ファイルハンドルからのデータの読み込み
# -----------------------------------------------------------------------------
package Tripletail::CSV;
use strict;
use warnings;
use IO::Handle ();
use IO::Scalar ();

my $_INSTANCE;

1;

sub _getInstance {
	my $class = shift;

	if (!$_INSTANCE) {
		$_INSTANCE = $class->_new(@_);
	}

	$_INSTANCE;
}

sub _new {
	my $class = shift;

	my $this = bless {} => $class;

	eval {
		require Text::CSV_XS;
	};
	if ($@) {
		die __PACKAGE__."#new: Text::CSV_XS is unavailable. (Text::CSV_XSが使用できません)\n";
	}

	$this->{csv} = Text::CSV_XS->new({
		binary => 1,
	});

	$this;
}

sub parseCsv {
	my $this = shift;
	my $src = shift;

	my $fh;
	if (ref $src) {
		$fh = $src;
	}
	else {
		$fh = IO::Scalar->new(\$src);
	}

	Tripletail::CSV::Parser->_new($this, $fh);
}

sub makeCsv {
	my $this = shift;
	my $row = shift;

	if (ref($row) ne 'ARRAY') {
		die __PACKAGE__."#makeCsv: arg[1] is not an ARRAY ref. (第1引数が配列のリファレンスではありません)\n";
	}

	$this->{csv}->combine(@$row);
	$this->{csv}->string;
}

package Tripletail::CSV::Parser;
use strict;
use warnings;

sub _new {
	my $class = shift;
	my $csv = shift;
	my $fh = shift;

	my $this = bless {} => $class;
	$this->{csv} = $csv;
	$this->{fh} = $fh;

	$this;
}

sub next {
	my $this = shift;

	if ($this->{fh}->eof) {
		return;
	}
	else {
		if (my $row = $this->{csv}{csv}->getline($this->{fh})) {
			$row;
		}
		else {
			die __PACKAGE__."#next: parse error. (不正なCSV形式です)\n";
		}
	}
}

__END__

=encoding utf-8

=for stopwords
	CSV
	YMIRLINK

=head1 NAME

Tripletail::CSV - CSV のパースと生成

=head1 SYNOPSIS

  # パース
  my $csv = $TL->getCsv;
  my $parser = $csv->parseCsv($CGI->getFile('upload'));
  
  while (my $row = $parser->next) {
      # $row: ['カラム1', 'カラム2', ...]
  }
  

  # 生成
  $TL->print($csv->makeCsv([ qw(aaa bbb ccc) ]), "\n");
  $TL->print($csv->makeCsv([ qw(aaa bbb ccc) ]), "\n");

=head1 DESCRIPTION

CSV のパースと生成を行う為のクラス。
カンマを含むカラム、改行コードを含むカラム等も
正しく処理する事が出来る。

文字列のパースの他に、ファイルハンドルからのパースも可能。

=head2 METHODS

=over 4

=item C<< $TL->getCsv >>

  my $csv = $TL->getCsv;

L<Tripletail::CSV> オブジェクトを取得する。

=item C<< parseCsv >>

  my $parser = $csv->parseCsv("a,b,c,d,e");
  my $parser = $csv->parseCsv(IO::Scalar->new(\"a,b,c,d,e"));

与えられた文字列またはファイルハンドルから
パーサオブジェクトを生成する。

返されたオブジェクトに対して C<next> メソッドを一度呼ぶ度に、
一行分のデータが配列リファレンスで返される。
最後の行を読んだ後は undef が返される。

  while (my $row = $parser->next) {
      ...
  }

CSV に問題があってパースできない場合は、C<next> メソッドを呼んだ
時に例外が発生する。

=item C<< makeCsv >>

  my $line = $csv->makeCsv([1, 2, 3]);

与えられた配列リファレンスから CSV 1行を生成して返す。
戻り値の末尾に改行文字は付加されない。

=back

=head1 BUGS

このモジュールは L<Text::CSV_XS> に依存しており、もしそれが利用可能
でない状態で C<< $TL->getCsv >> を呼ぶと例外が発生する。

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Text::CSV_XS>

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
