package WWW::Webrobot::MyEncode;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use Exporter;
use base qw/Exporter/;
our @EXPORT_OK = qw/has_Encode legacy_mode octet_to_internal_utf8 octet_to_encoding/;



my $_has_Encode;
my $_legacy_mode;
BEGIN {
    eval {require Encode};
    $_has_Encode = $@ ? 0 : 1;
    if (!$_has_Encode) {
        warn "Missing 'Encode': Data may be improperly encoded.";

        # check for Unicode::Lite
        eval {require Unicode::Lite};
        $_legacy_mode = $@ ? 0 : 1;
        warn "Missing 'Unicode::Lite': Can't encode." if !$_legacy_mode;
        #$_legacy_mode = 0;
    }
}

sub has_Encode { $_has_Encode }
sub legacy_mode { $_legacy_mode }

sub octet_to_internal_utf8 {
    my ($encoding, $value) = @_;
    $encoding ||= "ascii";
    return $value if !$value;
    if ($_has_Encode) {
        my $ret;
        eval { $ret = Encode::decode($encoding, $value) };
        return $@ ? "" : $ret;
    }
    elsif ($_legacy_mode) {
        my $ret;
        eval { $ret = Unicode::Lite::convert($encoding, "latin1", $value) };
        return $@ ? $value : $ret;
    }
    else {
        return $value;
    }
}

sub octet_to_encoding {
    my ($encoding, $value) = @_;
    $encoding ||= "ascii";
    return $value if !$value;
    if ($_has_Encode) {
        my $ret;
        eval { $ret = Encode::encode($encoding, $value) };
        return $@ ? $value : $ret;
    }
    elsif ($_legacy_mode) {
        my $ret;
        eval { $ret = Unicode::Lite::convert("utf8", $encoding, $value) };
        return $@ ? "" : $ret;
    }
    else {
        return $value;
    }
}


1;


=head1 NAME

WWW::Webrobot::MyEncode - Subroutines for 'Encode'

=head1 SYNOPSIS

 octet_to_internal_utf8("iso-8859-1", "a text");
 octet_to_encoding("iso-8859-1", "a text");

=head1 DESCRIPTION

Data conversion

=head1 METHODS

=over

=item octet_to_internal_utf8($encoding, $text)

Assume C<$text> is in octet form, but is a valid encoding C<$encoding>
and convert it to Perls internal form (utf-8).

=item octet_to_encoding($encoding, $text)

Assume C<$text> is in octet form an convert it to encoding C<$encoding>.

=back

=cut
