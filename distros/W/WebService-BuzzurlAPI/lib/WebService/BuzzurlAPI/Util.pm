package WebService::BuzzurlAPI::Util;

=pod

=head1 NAME

WebService::BuzzurlAPI::Util - Buzzurl WebService API utility module

=head1 VERSION

0.02

=head1 DESCRIPTION

Buzzurl WebService API utility module

=head1 METHOD

=cut

use strict;
use base qw(Exporter);
use Encode;

our(@EXPORT_OK, $PKG_REGEXP, $VERSION);

@EXPORT_OK = qw(drop_utf8flag urlencode);
$PKG_REGEXP = qr/^WebService::BuzzurlAPI/;
$VERSION = 0.02;

=pod

=head2 drop_utf8flag

Drop utf8flag

Example: 

  my $str = WebService::BuzzurlAPI::Util::drop_utf8flag($utf8flagstr);

=cut

sub drop_utf8flag {

    my $str = (scalar @_ == 2 && (ref($_[0]) =~ $PKG_REGEXP || $_[0] =~ $PKG_REGEXP)) ? $_[1] : $_[0];
    if($str ne "" && Encode::is_utf8($str)){
        $str = Encode::encode_utf8($str);
    }
    return $str;
}

=pod

=head2 urlencode

URLEncoding

Example: 

  my $str = WebService::BuzzurlAPI::Util::urlencode($str);

=cut

sub urlencode {

    my $str = (scalar @_ == 2 && (ref($_[0]) =~ $PKG_REGEXP || $_[0] =~ $PKG_REGEXP)) ? $_[1] : $_[0];
    if($str ne ""){
        $str =~ s/([^\w ])/"%" . unpack("H2", $1)/eg;
        $str =~ tr/ /+/;
    }
    return $str;
}

1;

__END__

=head1 SEE ALSO

L<Encode>

=head1 AUTHOR

Akira Horimoto

=head1 COPYRIGHT

Copyright (C) 2007 Akira Horimoto

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


