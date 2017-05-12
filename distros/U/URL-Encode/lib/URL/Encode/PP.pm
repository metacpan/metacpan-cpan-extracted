package URL::Encode::PP;

use strict;
use warnings;

use Carp qw[];

BEGIN {
    our $VERSION   = '0.03';
    our @EXPORT_OK = qw[ url_encode
                         url_encode_utf8
                         url_decode
                         url_decode_utf8
                         url_params_each
                         url_params_flat
                         url_params_mixed
                         url_params_multi ];
    require Exporter;
    *import = \&Exporter::import;
}

my (%DecodeMap, %EncodeMap);
BEGIN {
    for my $ord (0..255) {
        my $chr = pack 'C', $ord;
        my $hex = sprintf '%.2X', $ord;
        $DecodeMap{lc $hex} = $chr;
        $DecodeMap{uc $hex} = $chr;
        $DecodeMap{sprintf '%X%x', $ord >> 4, $ord & 15} = $chr;
        $DecodeMap{sprintf '%x%X', $ord >> 4, $ord & 15} = $chr;
        $EncodeMap{$chr} = '%' . $hex;
    }
    $EncodeMap{"\x20"} = '+';
}

sub url_decode {
    @_ == 1 || Carp::croak(q/Usage: url_decode(octets)/);
    my ($s) = @_;
    utf8::downgrade($s, 1)
      or Carp::croak(q/Wide character in octet string/);
    $s =~ y/+/\x20/;
    $s =~ s/%([0-9A-Za-z]{2})/$DecodeMap{$1}/gs;
    return $s;
}

sub url_decode_utf8 {
    @_ == 1 || Carp::croak(q/Usage: url_decode_utf8(octets)/);
    my $s = &url_decode;
    utf8::decode($s)
      or Carp::croak(q/Malformed UTF-8 in URL-decoded octets/);
    return $s;
}

sub url_encode {
    @_ == 1 || Carp::croak(q/Usage: url_encode(octets)/);
    my ($s) = @_;
    utf8::downgrade($s, 1)
      or Carp::croak(q/Wide character in octet string/);
    $s =~ s/([^0-9A-Za-z_.~-])/$EncodeMap{$1}/gs;
    return $s;
}

sub url_encode_utf8 {
    @_ == 1 || Carp::croak(q/Usage: url_encode_utf8(string)/);
    my ($s) = @_;
    utf8::encode($s);
    return url_encode($s);
}

sub url_params_each {
    @_ == 2 || @_ == 3 || Carp::croak(q/Usage: url_params_each(octets, callback [, utf8])/);
    my ($s, $callback, $utf8) = @_;

    utf8::downgrade($s, 1)
      or Carp::croak(q/Wide character in octet string/);

    foreach my $pair (split /[&;]/, $s, -1) {
        my ($k, $v) = split '=', $pair, 2;
        $k = '' unless defined $k;
        for ($k, defined $v ? $v : ()) {
            y/+/\x20/;
            s/%([0-9a-fA-F]{2})/$DecodeMap{$1}/gs;
            if ($utf8) {
                utf8::decode($_)
                  or Carp::croak("Malformed UTF-8 in URL-decoded octets");
            }
        }
        $callback->($k, $v);
    }
}

sub url_params_flat {
    @_ == 1 || @_ == 2 || Carp::croak(q/Usage: url_params_flat(octets [, utf8])/);
    my @p;
    my $callback = sub {
        my ($k, $v) = @_;
        push @p, $k, $v;
    };
    url_params_each($_[0], $callback, $_[1]);
    return \@p;
}

sub url_params_mixed {
    @_ == 1 || @_ == 2 || Carp::croak(q/Usage: url_params_mixed(octets [, utf8])/);
    my %p;
    my $callback = sub {
        my ($k, $v) = @_;
        if (exists $p{$k}) {
            for ($p{$k}) {
                $_ = [$_] unless ref $_ eq 'ARRAY';
                push @$_, $v;
            }
        }
        else {
            $p{$k} = $v;
        }
    };
    url_params_each($_[0], $callback, $_[1]);
    return \%p;
}

sub url_params_multi {
    @_ == 1 || @_ == 2 || Carp::croak(q/Usage: url_params_multi(octets [, utf8])/);
    my %p;
    my $callback = sub {
        my ($k, $v) = @_;
        push @{ $p{$k} ||= [] }, $v;
    };
    url_params_each($_[0], $callback, $_[1]);
    return \%p;
}

1;

