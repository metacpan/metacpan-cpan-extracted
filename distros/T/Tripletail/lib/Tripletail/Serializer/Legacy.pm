package Tripletail::Serializer::Legacy;
use strict;
use warnings;

sub _encodeArray {
    my $src = shift;

    return join('', map {
                        (y => unpack('H*', _encodeValue($_)))
                      }
                      @$src);
}

sub _decodeArray {
    my $src = shift;

    return [ map {
                 _decodeValue(pack('H*', $_))
               }
               split /y/, substr($src, 1)
           ];
}

sub _encodeHash {
    my $src = shift;

    return join('', map {
                        ( h => unpack('H*', $_                        ),
                          r => unpack('H*', _encodeValue($src->{$_})) )
                      }
                      keys %$src);
}

sub _decodeHash {
    my $src = shift;

    return { map {
                 my ($key, $val) = split /r/, $_;
                 (pack('H*', $key) => _decodeValue(pack('H*', $val)))
               }
               split /h/, substr($src, 1)
           };
}

sub _encodeValue {
    my $src  = shift;

    if (!defined $src) {
        return '';
    }
    elsif (length(my $type = ref $src)) {
        if ($type eq 'ARRAY') {
            return _encodeArray($src);
        }
        elsif ($type eq 'HASH') {
            return _encodeHash($src);
        }
        else {
            die "unsupported ref type: $type";
        }
    }
    else {
        return unpack('H*', $src);
    }
}

sub _decodeValue {
    my $src = shift;

    if ($src =~ m/^y/) {
        return _decodeArray($src);
    }
    elsif ($src =~ m/^h/) {
        return _decodeHash($src);
    }
    else {
        return pack('H*', $src);
    }
}

=encoding utf-8

=head1 NAME

Tripletail::Serializer::Legacy - 内部用


=head1 DESCRIPTION

L<Tripletail> によって内部的に使用される。


=head2 METHODS

=over 4

=item C<< $TL->newSerializer({-type => 'legacy'}) >>

=cut

use fields qw();
sub _new {
    my Tripletail::Serializer::Legacy $this = shift;

    if (!ref $this) {
        $this = fields::new($this);
    }

    return $this;
}


=item C<< serialize >>

=cut

sub serialize {
    my $this = shift;
    my $src  = shift;

    return _encodeValue($src);
}


=item C<< deserialize >>

=cut

sub deserialize {
    my $this = shift;
    my $src  = shift;

    return _decodeValue($src);
}


=back


=head1 SEE ALSO

L<Tripletail>


=head1 AUTHOR INFORMATION

Copyright 2006-2012 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Web site : http://tripletail.jp/

=cut

1;
