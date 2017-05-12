# -----------------------------------------------------------------------------
# Tripletail::Cookie - 独自のクッキー管理を行う
# -----------------------------------------------------------------------------
package Tripletail::Cookie;
use strict;
use warnings;
use Digest::SHA qw(sha256);
use Tripletail;
use base 'Tripletail::RawCookie';

sub _POST_REQUEST_HOOK_PRIORITY() { -3_000_000 } # 順序は問わない

my %_INSTANCES; # group => Tripletail::Cookie

1;

sub _getInstance {
    my $class = shift;
    my $group = shift;

    if (!defined $group) {
        $group = 'Cookie';
    }

    if (my $obj = $_INSTANCES{$group}) {
        return $obj;
    }

    my $obj = $_INSTANCES{$group} = $class->__new($group);

    # postRequestフックに、保存されているインスタンスを削除する関数を
    # インストールする。そうしなければFCGIモードで過去のリクエストのクッキーが
    # いつまでも残る。
    $TL->setHook(
        'postRequest',
        _POST_REQUEST_HOOK_PRIORITY,
        sub {
            %_INSTANCES = ();
        },
       );

    return $obj;
}

use fields qw(serializer);
sub __new {
    my $class = shift;

    my Tripletail::Cookie $this = fields::new($class);
    $this->SUPER::__new(@_);

    my $format    = $TL->INI->get($this->{group} => format    => undef);
    my $cryptokey = $TL->INI->get($this->{group} => cryptokey => undef);

    $this->{serializer} = do {
        if (defined $cryptokey) {
            if (!defined $format || $format eq 'modern') {
                $TL->newSerializer({-type => 'compat'})
                   ->setCryptoKey(sha256($cryptokey));
            }
            else {
                die sprintf(
                      qq{%s: %s/format is set to `%s' which do not support }.
                      qq{encryption. Use `modern' instead, or just omit it.\n},
                      $TL->INI->_filename, $this->{group}, $format);
            }
        }
        else {
            if (!defined $format || $format eq 'legacy') {
                $TL->newSerializer({-type => 'legacy'});
            }
            elsif ($format eq 'modern') {
                $TL->newSerializer({-type => 'compat'});
            }
            else {
                die sprintf(
                      qq{%s: %s/format is set to `%s' which is unknown to the }.
                      qq{current version of Tripletail.\n},
                      $TL->INI->_filename, $this->{group}, $format);
            }
        }
    };

    return $this;
}

sub get {
    my Tripletail::Cookie $this = shift;
    my                    $name = shift;

    if (defined(my $raw = $this->SUPER::get($name))) {
        my $form = $TL->eval(sub {
                                 $TL->newForm(
                                     $this->{serializer}->deserialize($raw));
                             });
        if ($@) {
            $TL->log(__PACKAGE__,
                     sprintf(
                         q{Warning: Ignoring unparsable cookie: %s=%s: %s},
                         $name, $raw, $@));
            return $TL->newForm();
        }
        else {
            return $form;
        }
    }
    else {
        return $TL->newForm();
    }
}

sub set {
    my Tripletail::Cookie $this = shift;
    my                    $name = shift;
    my Tripletail::Form   $form = shift;

    if (!defined($form)) {
        die __PACKAGE__."#set: arg[2] is not defined. (第2引数が指定されていません)\n";
    }
    elsif (!Tripletail::_isa($form, 'Tripletail::Form')) {
        die __PACKAGE__."#set: arg[2] is not an instance of Tripletail::Form.".
          " (第2引数がFormオブジェクトではありません)\n";
    }

    my $raw = $this->{serializer}->serialize($form->toHash());
    return $this->SUPER::set($name => $raw);
}

sub _makeSetCookies {
    # Set-Cookie:の値として使えるようにクッキーを文字列化するクラスメソッド。
    # 結果は配列で返される。
    return map { $_->__makeSetCookie } values %_INSTANCES;
}

__END__

=encoding utf-8

=for stopwords
	Ini
	YMIRLINK
	httponly
	ini

=head1 NAME

Tripletail::Cookie - 独自のクッキー管理を行う

=head1 SYNOPSIS

  my $cookie = $TL->getCookie;

  my $form = $cookie->get('Cookie1');
  my $val = $form->get('key1');

  $form->set(key2 => 100);
  $cookie->set('Cookie1' => $form);


=head1 DESCRIPTION

L<Tripletail::Form> クラスのインスタンスをクッキーに保存し、
また、クッキーから L<Tripletail::Form> を取り出す。

クッキー有効期限、ドメイン、パス等は、 L<ini|Tripletail::Ini> ファイルで指定する。


=head2 METHODS

=over 4

=item C<< $TL->getCookie >>

  $cookie = $TL->getCookie($inigroup)
  $cookie = $TL->getCookie('Cookie')

Tripletail::Cookie オブジェクトを取得。
引数には Ini で設定したグループ名を渡す。
引数省略時は 'Cookie' グループが使用される。

=item C<< get >>

  $Form_obj = $cookie->get($cookiename)

指定された名前のクッキーの内容を L<Tripletail::Form> のインスタンスに変換し、返す。
返された L<Tripletail::Form> インスタンスへの変更はクッキーへ反映されない。

=item C<< set >>

  $cookie->set($cookiename => $Form_obj)

L<Tripletail::Form> クラスのインスタンスの内容を、指定された名前のクッキーとしてセットする。

=item C<< delete >>

  $cookie->delete($cookiename)

クッキーを消去する。

=item C<< clear >>

  $cookie->clear

全てのクッキーを削除する。

=back


=head2 Ini パラメータ

=over 4

=item format

  format = modern

生成されるクッキーの形式を指定する。C<legacy> と C<modern> から選択可能であり、後述の
C<cryptokey> が存在すればデフォルトが C<modern> に、存在すれば C<legacy> になる。

C<modern> は AES によるクッキーの暗号化や ZLIB
による圧縮、Adler-32 チェックサムによる誤り検出にも対応した非常にコンパクトな形式であるが、この形式で生成されたクッキーは
L<Tripletail> のバージョン 0.50 以降でなければ読み取る事ができない。

なお C<modern> に設定されている場合であっても、C<legacy> 形式（すなわちバージョン 0.49 以前の形式）のクッキーは読み取り可能である。

=item cryptokey

  cryptokey = Lorem ipsum dolor sit amet, consectetur adipisicing elit

クッキーの暗号化に使用する鍵であり、省略可能。これを指定した場合には
L</"format"> を C<modern> とするか、もしくは省略しなければならない。

=item path

  path = /cgi-bin

クッキーのパス。省略可能。デフォルトは省略した場合と同様。

=item domain

  domain = example.org

クッキーのドメイン。省略可能。デフォルトは省略した場合と同様。

=item expires

  expires = 30 days

クッキー有効期限。 L<度量衡|Tripletail/"度量衡"> 参照。省略可能。
省略時はブラウザが閉じられるまでとなる。

=item secure

  secure = 1

C<secure>フラグの有無。省略可能。
1の場合、C<secure>フラグを付ける。
0の場合、C<secure>フラグを付けない。
デフォルトは0。

=item httponly

  httponly = 1

C<httponly>フラグの有無。省略可能。
1の場合、C<httponly>フラグを付ける。
0の場合、C<httponly>フラグを付けない。
デフォルトは0。
現状では IE でしか意味が無い。

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::RawCookie>

L<Tripletail::Form> でなく生の文字列を扱うクッキークラス。

=item L<Tripletail::Form>

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
