# -----------------------------------------------------------------------------
# Tripletail::InputFilter::SEO - SEO入力フィルタ
# -----------------------------------------------------------------------------
package Tripletail::InputFilter::SEO;
use base 'Tripletail::InputFilter';
use strict;
use warnings;
use Tripletail;

# このフィルタは次のようなPATH_INFOからフォーム情報を得る。
# foo.cgi/aaa/100/bbb/200
# => aaa=100&bbb=200

# このフィルタをSession及びTripletail::Filter::MobileHTMLと併用する場合は
# Tripletail::Filter::MobileHTMLよりも先に呼ばれるように設定しなければならない。

1;

sub _new {
	my $class = shift;
	my $this = $class->SUPER::_new(@_);

	$this;
}

sub decodeCgi {
	my $this = shift;
	my $form = shift;

	my $newform = $this->_formFromPairs(
	$this->__pairsFromPathInfo);

	$form->addForm($newform);

	$this;
}

sub decodeURL {
	my $this = shift;
	my $form = shift;
	my $url = shift; # フラグメントは除去済
	my $fragment = shift;

	# URLの何処からPATH_INFOが始まっているのか
	# 判断する方法は無い。

	$this;
}

sub __pairsFromPathInfo {
	# 戻り値: ([[key => value], ...], {key => filename, ...})
	#         但しkey, value共にURLデコードされている事。文字コードは生のまま。
	my $this = shift;

	if(!defined($ENV{PATH_INFO})) {
		return ([], undef);
	}

	my @split = map { $this->_urlDecodeString($_) } split m!/!, $ENV{PATH_INFO};
	shift @split; # 最初の項目は常に空。PATH_INFOがスラッシュで始まる為。

	my @pairs;
	while(@split) {
		if(defined($split[0]) && $split[0] eq 'SEO') {
			shift(@split);
			shift(@split);
			next;
		}
		my $key = shift(@split);
		my $value = shift(@split);
		if(!defined($value)) {
			$value = '';
		}
		push @pairs, [$key => $value];
	}
	return (\@pairs, {});
}


__END__

=encoding utf-8

=for stopwords
	SEO
	YMIRLINK
	decodeCgi
	decodeURL

=head1 NAME

Tripletail::InputFilter::SEO - SEO 入力フィルタ

=head1 SYNOPSIS

  $TL->setInputFilter(['Tripletail::InputFilter::SEO', 999]);
  $TL->setInputFilter('Tripletail::InputFilter::HTML');
  
  $TL->startCgi(
      -main => \&main,
  );
  
  sub main {
      if ($CGI->get('mode') eq 'Foo') {
          ...
      }
  }

=head1 DESCRIPTION

このフィルタは次のような C<PATH_INFO> からフォーム情報を得る。

  foo.cgi/aaa/100/bbb/200
  => aaa=100&bbb=200


注意:
  
このフィルタを L<Tripletail::Session> 及び L<Tripletail::InputFilter::MobileHTML>
と併用する場合は、 それらよりも先に呼ばれるように設定しなければならない。

=head2 METHODS

=over 4

=item decodeCgi

内部メソッド

=item decodeURL

内部メソッド

=back

=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::InputFilter>

=item L<Tripletail::InputFilter::MobileHTML>

=item L<Tripletail::Session>

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
