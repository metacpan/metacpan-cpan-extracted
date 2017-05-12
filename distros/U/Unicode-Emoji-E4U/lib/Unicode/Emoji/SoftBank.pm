=head1 NAME

Unicode::Emoji::SoftBank - Emoji for SoftBank Mobile

=head1 SYNOPSIS

    use Unicode::Emoji::E4U;
    my $e4u = Unicode::Emoji::E4U->new;
    my $softbank = $e4u->softbank;

    my $e;
    $e = $softbank->list->[0];
    $e = $softbank->find(unicode => 'E04A');
    print "name_ja: ", $e->name_ja, "\n";
    print "number: ",  $e->number, "\n";
    print "unicode: ", $e->unicode, "\n";

    my $se = $e->softbank_emoji;
    print "is_alt: ",         $se->is_alt, "\n";
    print "unicode_string: ", $se->unicode_string, "\n";
    print "unicode_octets: ", $se->unicode_octets, "\n";
    print "cp932_string: ",   $se->cp932_string, "\n";
    print "cp932_octets: ",   $se->cp932_octets, "\n";

=head1 DEFINITION

L<http://emoji4unicode.googlecode.com/svn/trunk/data/softbank/carrier_data.xml>

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Unicode::Emoji::E4U>

=head1 COPYRIGHT

Copyright 2009 Yusuke Kawasaki, all rights reserved.

=cut

package Unicode::Emoji::SoftBank;
use Unicode::Emoji::Base;
use Any::Moose;
extends 'Unicode::Emoji::Base::File::Carrier';

our $VERSION = '0.03';

sub _dataxml { 'softbank/carrier_data.xml'; }

package Unicode::Emoji::SoftBank::XML::carrier_data;
use Any::Moose;
has e => (is => 'ro', isa => 'Unicode::Emoji::SoftBank::XML::e');

package Unicode::Emoji::SoftBank::XML::e;
use Any::Moose;
has name_ja   => (is => 'ro', isa => 'Str');
has number    => (is => 'ro', isa => 'Str');
has unicode   => (is => 'ro', isa => 'Str');
has softbank_emoji => (is => 'ro', isa => 'Unicode::Emoji::Base::Emoji', lazy_build => 1);

sub _build_softbank_emoji  { Unicode::Emoji::SoftBank::Emoji->new(unicode_hex => $_[0]->unicode) };

package Unicode::Emoji::SoftBank::Emoji;
use Any::Moose;
extends 'Unicode::Emoji::Base::Emoji::CP932';

sub _unicode_to_cp932 {
    my $self = shift;
    my $code = shift;
    return if ($code < 0xE001);
    return if ($code > 0xE55A);
    my $page = ($code >> 8) & 7;
    my $sjisH = (0xF9, 0xF7, 0xF7, 0xF9, 0xFB, 0xFB)[$page];
    my $sjisL = (0x40, 0x40, 0xA0, 0xA0, 0x40, 0xA0)[$page] + ($code&0x7F);
    $sjisL ++ if ($sjisL > 0x7E && $sjisL < 0xA1);
    ( $sjisH << 8 | $sjisL );
}

__PACKAGE__->meta->make_immutable;
