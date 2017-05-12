# -----------------------------------------------------------------------------
# Tripletail::RawCookie - 汎用的なクッキー管理を行う
# -----------------------------------------------------------------------------
package Tripletail::RawCookie;
use constant _POST_REQUEST_HOOK_PRIORITY => -4_000_000; # 順序は問わない
use strict;
use warnings;
use Tripletail;

my %_INSTANCES; # group => Tripletail::RawCookie

# ABNF from RFC 6265:
#
# cookie-header = "Cookie:" OWS cookie-string OWS
# cookie-string = cookie-pair *( ";" SP cookie-pair )
#
# set-cookie-header = "Set-Cookie:" SP set-cookie-string
# set-cookie-string = cookie-pair *( ";" SP cookie-av )
#
# cookie-pair       = cookie-name "=" cookie-value
# cookie-name       = token
# cookie-value      = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE )
# cookie-octet      = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E
#                       ; US-ASCII characters excluding CTLs,
#                       ; whitespace DQUOTE, comma, semicolon,
#                       ; and backslash
# token             = <token, defined in [RFC2616], Section 2.2>
#
# cookie-av         = expires-av / max-age-av / domain-av /
#                     path-av / secure-av / httponly-av /
#                     extension-av
# expires-av        = "Expires=" sane-cookie-date
# sane-cookie-date  = <rfc1123-date, defined in [RFC2616], Section 3.3.1>
# max-age-av        = "Max-Age=" non-zero-digit *DIGIT
#                       ; In practice, both expires-av and max-age-av
#                       ; are limited to dates representable by the
#                       ; user agent.
# non-zero-digit    = %x31-39
#                       ; digits 1 through 9
# domain-av         = "Domain=" domain-value
# domain-value      = <subdomain>
#                       ; defined in [RFC1034], Section 3.5, as
#                       ; enhanced by [RFC1123], Section 2.1
# path-av           = "Path=" path-value
# path-value        = <any CHAR except CTLs or ";">
# secure-av         = "Secure"
# httponly-av       = "HttpOnly"
# extension-av      = <any CHAR except CTLs or ";">
my $re_token        = qr/[^\x00-\x20()<>@,;:\\"\/[\]?={}]+/;
my $re_cookie_octet = qr/[^\x00-\x20\",;\\]/;
my $re_path_value   = qr/[^\x00-\x1F;]*/;
my $re_domain_value = qr{ [A-Za-z0-9]+ (?:-[A-Za-z0-9]+)*
                          (?:
                              \.[A-Za-z0-9]+ (?:-[A-Za-z0-9]+)*
                          )*
                        }x;

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
        });

    return $obj;
}

use fields qw(group hasLoaded gotCookies setCookies
              expires path domain secure httpOnly);
sub __new {
    my Tripletail::RawCookie $this  = shift;
    my                       $group = shift;

    if (!ref $this) {
        $this = fields::new($this);
    }

    $this->{group     } = $group;
    $this->{hasLoaded } = undef;  # 環境変数からロードした後は真。
    $this->{gotCookies} = {};     # キー => 値 (飽くまでキャッシュ。{setCookies}が優先される。)
    $this->{setCookies} = {};     # キー => 値 (undefの値はクッキーの削除)
    $this->{expires   } = $TL->INI->get($group => expires  => undef);
    $this->{path      } = $TL->INI->get($group => path     => undef);
    $this->{domain    } = $TL->INI->get($group => domain   => undef);
    $this->{secure    } = $TL->INI->get($group => secure   => undef);
    $this->{httpOnly  } = $TL->INI->get($group => httpOnly => undef);

    if (defined($this->{path})
          && $this->{path} !~ m/\A$re_path_value\z/) {
        die "Malformed cookie path: $this->{path}";
    }
    elsif (defined($this->{domain})
             && $this->{domain} !~ m/\A$re_domain_value\z/) {
        die "Malformed cookie domain: $this->{domain}";
    }

    return $this;
}

sub get {
    my Tripletail::RawCookie $this = shift;
    my                       $name = shift;

    if (!defined $name) {
        die __PACKAGE__."#get: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#get: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($name !~ m/\A$re_token\z/o) {
        die __PACKAGE__."#get: arg[1] contains some forbidden symbols.\n";
    }

    if (exists $this->{setCookies}{$name}) {
        # setまたはdeleteされている。
        if (defined(my $value = $this->{setCookies}{$name})) {
            return $value;
        }
        else {
            return;
        }
    }
    else {
        $this->__readEnvIfNeeded;

        if (defined(my $value = $this->{gotCookies}{$name})) {
            return $value;
        }
        else {
            return;
        }
    }
}

sub set {
    my Tripletail::RawCookie $this  = shift;
    my                       $name  = shift;
    my                       $value = shift;

    if (!defined $name) {
        die __PACKAGE__."#set: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#set: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($name !~ m/\A$re_token\z/o) {
        die __PACKAGE__."#set: arg[1] contains some forbidden symbols.\n";
    }

    if (!defined $value) {
        die __PACKAGE__."#set: arg[2] is not defined. (第2引数が指定されていません)\n";
    }
    elsif (ref $value) {
        die __PACKAGE__."#set: arg[2] is a reference. (第2引数がリファレンスです)\n";
    }
    elsif ($name !~ m/\A$re_cookie_octet*\z/) {
        die __PACKAGE__."#set: arg[2] contains some forbidden symbols.\n";
    }

    $this->{setCookies}{$name} = $value;
    return $this;
}

sub delete {
    my Tripletail::RawCookie $this = shift;
    my                       $name = shift;

    if (!defined $name) {
        die __PACKAGE__."#delete: arg[1] is not defined. (第1引数が指定されていません)\n";
    }
    elsif (ref $name) {
        die __PACKAGE__."#delete: arg[1] is a reference. (第1引数がリファレンスです)\n";
    }
    elsif ($name !~ m/\A$re_token\z/o) {
        die __PACKAGE__."#set: arg[1] contains some forbidden symbols.\n";
    }

    if (exists $this->{gotCookies}{$name}) {
        # We deliberately replace it with undef to emit Set-Cookie
        # header that promptly expires it.
        $this->{setCookies}{$name} = undef;
    }
    else {
        delete $this->{setCookies}{$name};
    }

    return $this;
}

sub clear {
    my Tripletail::RawCookie $this = shift;

    $this->__readEnvIfNeeded;

    # We deliberately replace every value with undef to emit
    # Set-Cookie headers that promptly expires them.
    my @keys = (keys %{$this->{gotCookies}}, keys %{$this->{setCookies}});
    foreach my $key (@keys) {
        $this->{setCookies}{$key} = undef;
    }

    return $this;
}

sub isSecure {
    my Tripletail::RawCookie $this = shift;

    if ($this->{secure}) {
        return 1;
    }
    else {
        return;
    }
}

sub _makeSetCookies {
    # Set-Cookie:の値として使えるようにクッキーを文字列化するクラスメソッド。
    # 結果は配列で返される。
    return map { $_->__makeSetCookie } values %_INSTANCES;
}

sub __readEnvIfNeeded {
    my Tripletail::RawCookie $this = shift;

    if ($this->{hasLoaded}) {
        return $this;
    }

    if (my $cookie = $ENV{HTTP_COOKIE}) {
        foreach my $pair (split /; /, $cookie) {
            if ($pair =~ m/\A(.+?)=($re_cookie_octet*)\z/so) {
                $this->{gotCookies}{$1} = $2;
            }
            elsif ($pair =~ m/\A(.+?)="($re_cookie_octet*)"\z/so) {
                $this->{gotCookies}{$1} = $2;
            }
        }
    }

    $this->{hasLoaded} = 1;
    return $this;
}

sub __cookieTime {
    my Tripletail::RawCookie $this  = shift;
    my                       $epoch = shift;

    my @DoW = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    my @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime $epoch;
    $year += 1900;

    # '$[': The index of the first element in an array, and of the
    #       first character in a substring.
    return sprintf(
        '%s, %02d-%s-%04d %02d:%02d:%02d GMT',
        $DoW[$[+$wday], $mday, $MoY[$[+$mon], $year, $hour, $min, $sec);
}

sub __makeSetCookie {
    my Tripletail::RawCookie $this = shift;
    my @result;

    while (my ($key, $value) = each %{$this->{setCookies}}) {
        my @parts;
        push @parts, sprintf('%s=%s', $key, defined $value ? $value : '');

        if (defined $value) {
            if (defined $this->{expires}) {
                push @parts,
                  'expires='.$this->__cookieTime(
                                 time + $TL->parsePeriod($this->{expires}));
            }
        }
        else {
            # Expire it immediately.
            push @parts, "expires=".$this->__cookieTime(0);
        }

        if (defined $this->{path}) {
            push @parts, "path=$this->{path}";
        }
        if (defined $this->{domain}) {
            push @parts, "domain=$this->{domain}";
        }
        if ($this->{secure}) {
            push @parts, 'secure';
        }
        if ($this->{httpOnly}) {
            push @parts, 'httponly';
        }

        my $line = join '; ', @parts;
        if (length($line) > 1024 * 4) {
            die __PACKAGE__."#_makeSetCookies: the cookie became too large. ".
              "Decrease its content. [$line] (クッキーが大きくなりすぎました。".
                "保存するデータを減らしてください)";
        }

        push @result, $line;
    }

    @result;
}


__END__

=encoding utf-8

=head1 NAME

Tripletail::RawCookie - 汎用的なクッキー管理を行う

=head1 SYNOPSIS

  my $rawcookie = $TL->getRawCookie;

  my $val = $rawcookie->get('Cookie1');
  $rawcookie->set('Cookie2' => 'val2');

=head1 DESCRIPTION

生の文字列の状態でクッキーを取り出し、また格納する。
改行などのコントロールコードが含まれないように注意する必要性がある。

クッキー有効期限、ドメイン、パス等は、 L<ini|Tripletail::Ini> ファイルで指定する。

=head2 METHODS

=over 4

=item C<< $TL->getRawCookie >>

  $TL->getRawCookie($inigroup)
  $TL->getRawCookie('Cookie')

Tripletail::RawCookie オブジェクトを取得。
引数には L<ini|Tripletail::Ini> で設定したグループ名を渡す。
引数省略時は 'Cookie' グループが使用される。

=item C<< get >>

  $str = $cookie->get($cookiename)

指定された名前のクッキーの内容を返す。

=item C<< set >>

  $cookie->set($cookiename => $str)

文字列を、指定された名前のクッキーとしてセットする。

=item C<< delete >>

  $cookie->delete($cookiename)

指定された名前のクッキーを削除する。

=item C<< clear >>

  $cookie->clear

全てのクッキーを削除する。

=item C<< isSecure >>

  my $bool = $cookie->isSecure();

当該グループのクッキーに L</"secure"> 属性を与えるよう設定されているならば真を返す。

=back


=head2 Ini パラメータ

=over 4

=item path

  path = /cgi-bin

クッキーのパス。省略可能。
デフォルトは省略した場合と同様。

=item domain

  domain = example.org

クッキーのドメイン。省略可能。
デフォルトは省略した場合と同様。

=item expires

  expires = 30 days

クッキー有効期限。 L<度量衡|Tripletail/"度量衡"> 参照。省略可能。
省略時はブラウザが閉じられるまでとなる。

=item secure

  secure = 1

RFC 6265 (L<http://tools.ietf.org/html/rfc6265#section-4.1.2>)
に定義される C<Secure> 属性を与えるかどうか。C<1> または C<0>
を指定する。デフォルトは C<0> である。

=item httponly

  httponly = 1

RFC 6265 (L<http://tools.ietf.org/html/rfc6265#section-4.1.2>)
に定義される C<HttpOnly> 属性を与えるかどうか。C<1> または C<0>
を指定する。デフォルトは C<0> である。

=back


=head1 SEE ALSO

=over 4

=item L<Tripletail>

=item L<Tripletail::Cookie>

生の文字列でなく L<Tripletail::Form> を扱うクッキークラス。

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
