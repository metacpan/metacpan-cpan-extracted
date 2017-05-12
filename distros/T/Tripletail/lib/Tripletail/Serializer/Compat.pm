package Tripletail::Serializer::Compat;
use base 'Tripletail::Serializer';
use strict;
use warnings;
use MIME::Base64 qw(encode_base64 decode_base64);
use Tripletail;

=encoding utf-8

=head1 NAME

Tripletail::Serializer::Compat - 内部用


=head1 DESCRIPTION

L<Tripletail> によって内部的に使用される。


=head2 METHODS

=over 4

=item C<< $TL->newSerializer({-type => 'compat'}) >>

=cut

use fields qw(legacy);
sub _new {
    my $class = shift;

    my Tripletail::Serializer::Compat $this = fields::new($class);
    $this->SUPER::_new(@_);
    $this->{legacy} = $TL->newSerializer({-type => 'legacy'});

    return $this;
}


=item C<< serialize >>

=cut

sub serialize {
    my Tripletail::Serializer::Compat $this = shift;

    return encode_base64($this->SUPER::serialize(@_), '');
}


=item C<< deserialize >>

=cut

sub deserialize {
    my Tripletail::Serializer::Compat $this = shift;
    my                                $src  = shift;

    # In the modern format they always start with one of the following
    # bit patterns:
    #   - bin 0000 0001 (plain w/ sum ) = b64 /A[Q-Za-f]/
    #   - bin 0000 0010 (plain w/ zlib) = b64 /A[g-v]/
    #   - bin 0000 0101 (AES   w/ sum ) = b64 /B[Q-Za-f]/
    #   - bin 0000 0110 (AES   w/ zlib) = b64 /B[g-v]/
    #
    # And in the legacy format:
    #   - /0-9a-f/ (scalar)
    #   - /h/      (hash  )
    #   - /y/      (array )
    #
    # Conclusion: They do not overlap at all. Phew.

    if ($src =~ m/\A[AB]/) {
        return $this->SUPER::deserialize(decode_base64($src));
    }
    elsif ($src =~ m/\A[0-9a-fhy]/) {
        return $this->{legacy}->deserialize($src);
    }
    else {
        die "Failed to detect the format of serialization: $src";
    }
}


=back

=head1 AUTHOR INFORMATION

Copyright 2006-2012 YMIRLINK Inc.

This framework is free software; you can redistribute it and/or modify it under the same terms as Perl itself

このフレームワークはフリーソフトウェアです。あなたは Perl と同じライセンスの 元で再配布及び変更を行うことが出来ます。

Address bug reports and comments to: tl@tripletail.jp

Web site: http://tripletail.jp/

=cut

1;
