# -----------------------------------------------------------------------------
# Tripletail::Filter::Cookie - クッキーを出力するフィルタ（内部用）
# -----------------------------------------------------------------------------
package Tripletail::Filter::Cookie;
use strict;
use warnings;
use base 'Tripletail::Filter';
use Tripletail::RawCookie;
use Tripletail::Cookie;

sub _make_header {
    my $this = shift;

    if (defined(&Tripletail::Session::_getInstance)) {
        # Tripletail::Sessionが有効になっているので、データが有れば、それをクッキーに加える。
        foreach my $group (Tripletail::Session->_getInstanceGroups) {
            Tripletail::Session->_getInstance($group)->_setSessionDataToCookies;
        }
    }

    return {
        'Set-Cookie' => [
            Tripletail::Cookie->_makeSetCookies,
            Tripletail::RawCookie->_makeSetCookies
             ]
       };
}

=encoding utf-8

=head1 NAME

Tripletail::Filter::Cookie - クッキーを出力するフィルタ（内部用）

=head1 DESCRIPTION

L<Tripletail::Filter> によって内部的に使用される。

=head1 SEE ALSO

L<Tripletail::Filter>

=head1 AUTHOR INFORMATION

=over 4

Copyright 2006-2012 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Web site : http://tripletail.jp/

=back

=cut

1;
