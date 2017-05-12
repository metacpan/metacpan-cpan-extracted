# -----------------------------------------------------------------------------
# Tripletail::InputFilter::Plain - 何もしない
# -----------------------------------------------------------------------------
package Tripletail::InputFilter::Plain;
use base 'Tripletail::InputFilter';
use strict;
use warnings;
use Tripletail;

my $TEMPFILE_COUNTER = 0;

1;

sub _new {
	my $class = shift;
	my $this = $class->SUPER::_new(@_);

	$this;
}

sub decodeCgi {
	my $this = shift;
	my $form = shift;

	$this;
}

sub decodeURL {
	my $this = shift;
	my $form = shift;
	my $url = shift; # フラグメントは除去済
	my $fragment = shift;

	$this;
}


__END__

=encoding utf-8

=for stopwords
	YMIRLINK
	decodeCgi
	decodeURL

=head1 NAME

Tripletail::InputFilter::Plain - 何も処理を行わない

=head1 SYNOPSIS

  $TL->setInputFilter('Tripletail::InputFilter::Plain');
  
  $TL->startCgi(
      -main => \&main,
  );
  
  sub main {
  }

=head1 DESCRIPTION

何も処理を行わない。
セッションについても処理を行わないので注意が必要。

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

=item L<Tripletail::InputFilter::Plain>

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
