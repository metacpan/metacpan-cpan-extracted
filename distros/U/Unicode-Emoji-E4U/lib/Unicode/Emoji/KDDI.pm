=head1 NAME

Unicode::Emoji::KDDI - Emoji for au by KDDI

=head1 SYNOPSIS

    use Unicode::Emoji::E4U;
    my $e4u = Unicode::Emoji::E4U->new;
    my $kddi = $e4u->kddi;

    my $e;
    $e = $kddi->list->[0];
    $e = $kddi->find(unicode => 'E488');
    print "name_ja: ", $e->name_ja, "\n";
    print "number: ",  $e->number, "\n";
    print "unicode: ", $e->unicode, "\n";

    my $ke = $e->kddi_emoji;
    print "is_alt: ",         $ke->is_alt, "\n";
    print "unicode_string: ", $ke->unicode_string, "\n";
    print "unicode_octets: ", $ke->unicode_octets, "\n";
    print "cp932_string: ",   $ke->cp932_string, "\n";
    print "cp932_octets: ",   $ke->cp932_octets, "\n";

    my $kwe = $e->kddiweb_emoji;
    print "is_alt: ",         $kwe->is_alt, "\n";
    print "unicode_string: ", $kwe->unicode_string, "\n";
    print "unicode_octets: ", $kwe->unicode_octets, "\n";
    print "cp932_string: ",   $kwe->cp932_string, "\n";
    print "cp932_octets: ",   $kwe->cp932_octets, "\n";

=head1 DEFINITION

L<http://emoji4unicode.googlecode.com/svn/trunk/data/kddi/carrier_data.xml>

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Unicode::Emoji::E4U>

=head1 COPYRIGHT

Copyright 2009 Yusuke Kawasaki, all rights reserved.

=cut

package Unicode::Emoji::KDDI;
use Unicode::Emoji::Base;
use Any::Moose;
extends 'Unicode::Emoji::Base::File::Carrier';

our $VERSION = '0.03';

sub _dataxml { 'kddi/carrier_data.xml'; }

package Unicode::Emoji::KDDI::XML::carrier_data;
use Any::Moose;
has e => (is => 'ro', isa => 'Unicode::Emoji::KDDI::XML::e');

package Unicode::Emoji::KDDI::XML::e;
use Any::Moose;
has name_ja => (is => 'ro', isa => 'Str');
has number  => (is => 'ro', isa => 'Str');
has unicode => (is => 'ro', isa => 'Str');
has kddi_emoji    => (is => 'ro', isa => 'Unicode::Emoji::KDDI::Emoji', lazy_build => 1);
has kddiweb_emoji => (is => 'ro', isa => 'Unicode::Emoji::KDDIweb::Emoji', lazy_build => 1);

sub _build_kddi_emoji { Unicode::Emoji::KDDI::Emoji->new(unicode_hex => $_[0]->unicode) };
sub _build_kddiweb_emoji { Unicode::Emoji::KDDIweb::Emoji->fromKDDI($_[0]->kddi_emoji) };

package Unicode::Emoji::KDDI::Emoji;
use Any::Moose;
extends 'Unicode::Emoji::Base::Emoji::CP932';

sub _unicode_to_cp932 {
    my $self = shift;
    my $code = shift;
    my $sjis;
    if ( $code >= 0xE468 && $code <= 0xE5DF ) {         # 1-420
        if ( $code <= 0xE4A6 ) {
            $sjis = $code+4568;
        } elsif ( $code <= 0xE523 ) {
            $sjis = $code+4569;
        } elsif ( $code <= 0xE562 ) {
            $sjis = $code+4636;
        } elsif ( $code <= 0xE5B4 ) {
            $sjis = $code+4637;
        } elsif ( $code <= 0xE5CC ) {
            $sjis = $code+4656;
        } else {
            $sjis = $code+3443;
        }
    } elsif ( $code >= 0xEA80 && $code <= 0xEB8E ) {    # 421-
        if ( $code <= 0xEAAB ) {
            $sjis = $code+2259;
        } elsif ( $code <= 0xEAFA ) {
            $sjis = $code+2260;
        } elsif ( $code <= 0xEB0D ) {
            $sjis = $code+3287;
        } elsif ( $code <= 0xEB3B ) {
            $sjis = $code+2241;
        } elsif ( $code <= 0xEB7A ) {
            $sjis = $code+2308;
        } else {
            $sjis = $code+2309;
        }
    } else {
        return;
    }
    $sjis
}

package Unicode::Emoji::KDDIweb::Emoji;
use Carp;
use Any::Moose;
extends 'Unicode::Emoji::Base::Emoji::CP932';

sub fromKDDI {
    my $class = shift;
    my $kddi  = shift;
#   my $hex = sprintf('%04X' => unpack(n => $kddi->cp932_octets) - 1792);
    my $hex = join '+' => map {sprintf '%04X' => $_-1792} unpack 'n*' => $kddi->cp932_octets;
    $hex = '>'.$hex if $kddi->is_alt;
    $class->new(unicode_hex => $hex);
};

sub _unicode_to_cp932 {
    my $self = shift;
    my $code = shift;
    my $sjis = $code + 1792;
    $sjis;
}

__PACKAGE__->meta->make_immutable;
