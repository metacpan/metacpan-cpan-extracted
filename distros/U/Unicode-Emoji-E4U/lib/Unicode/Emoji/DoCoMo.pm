=head1 NAME

Unicode::Emoji::DoCoMo - Emoji for NTT DoCoMo

=head1 SYNOPSIS

    use Unicode::Emoji::E4U;
    my $e4u = Unicode::Emoji::E4U->new;
    my $docomo = $e4u->docomo;

    my $e;
    $e = $docomo->list->[0];
    $e = $docomo->find(unicode => 'E63E');
    print "jis: ",     $e->jis, "\n";
    print "name_en: ", $e->name_en, "\n";
    print "name_ja: ", $e->name_ja, "\n";
    print "unicode: ", $e->unicode, "\n";

    my $de = $e->docomo_emoji;
    print "is_alt: ",         $de->is_alt, "\n";
    print "unicode_string: ", $de->unicode_string, "\n";
    print "unicode_octets: ", $de->unicode_octets, "\n";
    print "cp932_string: ",   $de->cp932_string, "\n";
    print "cp932_octets: ",   $de->cp932_octets, "\n";

=head1 DEFINITION

L<http://emoji4unicode.googlecode.com/svn/trunk/data/docomo/carrier_data.xml>

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Unicode::Emoji::E4U>

=head1 COPYRIGHT

Copyright 2009 Yusuke Kawasaki, all rights reserved.

=cut

package Unicode::Emoji::DoCoMo;
use Unicode::Emoji::Base;
use Any::Moose;
extends 'Unicode::Emoji::Base::File::Carrier';

our $VERSION = '0.03';

sub _dataxml { 'docomo/carrier_data.xml'; }

package Unicode::Emoji::DoCoMo::XML::carrier_data;
use Any::Moose;
has e => (is => 'ro', isa => 'Unicode::Emoji::DoCoMo::XML::e');

package Unicode::Emoji::DoCoMo::XML::e;
use Any::Moose;
has jis     => (is => 'ro', isa => 'Str');
has name_en => (is => 'ro', isa => 'Str');
has name_ja => (is => 'ro', isa => 'Str');
has unicode => (is => 'ro', isa => 'Str');
has docomo_emoji  => (is => 'ro', isa => 'Unicode::Emoji::Base::Emoji', lazy_build => 1);

sub _build_docomo_emoji { Unicode::Emoji::DoCoMo::Emoji->new(unicode_hex => $_[0]->unicode) };

package Unicode::Emoji::DoCoMo::Emoji;
use Any::Moose;
extends 'Unicode::Emoji::Base::Emoji::CP932';

sub _unicode_to_cp932 {
    my $self = shift;
    my $code = shift;
    my $sjis;
    return if ($code < 0xE63E);
    return if ($code > 0xE757);
    if ( $code <= 0xE69B ) {
        $sjis = $code+4705;
    } elsif ( $code <= 0xE6DA ) {
        $sjis = $code+4772;
    } else {
        $sjis = $code+4773;
    }
    $sjis;
}

__PACKAGE__->meta->make_immutable;
