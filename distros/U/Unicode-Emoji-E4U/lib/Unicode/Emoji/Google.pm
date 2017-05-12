=head1 NAME

Unicode::Emoji::Google - Emoji for Google and cross-mapping table

=head1 SYNOPSIS

    use Unicode::Emoji::E4U;
    my $e4u = Unicode::Emoji::E4U->new;
    my $google = $e4u->google;

    my $e;
    $e = $google->list->[0];
    $e = $google->find(unicode => 'E04A');
    print "id: ",            $e->id, "\n";
    print "name: ",          $e->name, "\n";
    print "desc: ",          $e->desc, "\n";
    print "text_fallback: ", $e->text_fallback, "\n";
    print "in_proposal: ",   $e->in_proposal, "\n";

    my $de = $e->docomo_emoji;      # Unicode::Emoji::DoCoMo::Emoji
    my $ke = $e->kddi_emoji;        # Unicode::Emoji::KDDI::Emoji
    my $se = $e->softbank_emoji;    # Unicode::Emoji::SoftBank::Emoji
    my $ge = $e->google_emoji;      # Unicode::Emoji::Google::Emoji
    my $ue = $e->unicode_emoji;     # Unicode::Emoji::Unicode::Emoji

    print "is_alt: ",         $ge->is_alt, "\n";
    print "unicode_string: ", $ge->unicode_string, "\n";
    print "unicode_octets: ", $ge->unicode_octets, "\n";

=head1 DEFINITION

L<http://emoji4unicode.googlecode.com/svn/trunk/data/emoji4unicode.xml>

=head1 AUTHOR

Yusuke Kawasaki, L<http://www.kawa.net/>

=head1 SEE ALSO

L<Unicode::Emoji::E4U>

L<Unicode::Emoji::DoCoMo>

L<Unicode::Emoji::KDDI>

L<Unicode::Emoji::SoftBank>

=head1 COPYRIGHT

Copyright 2009 Yusuke Kawasaki, all rights reserved.

=cut

package Unicode::Emoji::Google;
use Unicode::Emoji::Base;
use Unicode::Emoji::DoCoMo;
use Unicode::Emoji::KDDI;
use Unicode::Emoji::SoftBank;
use Unicode::Emoji::Google;
use Any::Moose;
extends 'Unicode::Emoji::Base::File';
has list => (is => 'ro', isa => 'ArrayRef', lazy_build => 1);

our $VERSION = '0.03';

sub _dataxml { 'emoji4unicode.xml'; }

sub _build_list {
    my $self = shift;
    my $list = [];
    foreach my $category (@{$self->root->category}) {
        foreach my $subcategory (@{$category->subcategory}) {
            push( @$list, @{$subcategory->e} );
        }
    }
    $list;
}

package Unicode::Emoji::Google::XML::emoji4unicode;
use Any::Moose;
has category    => (is => 'ro', isa => 'Unicode::Emoji::Google::XML::category');

package Unicode::Emoji::Google::XML::category;
use Any::Moose;
has subcategory => (is => 'ro', isa => 'Unicode::Emoji::Google::XML::subcategory');

package Unicode::Emoji::Google::XML::subcategory;
use Any::Moose;
has e => (is => 'ro', isa => 'Unicode::Emoji::Google::XML::e');

package Unicode::Emoji::Google::XML::e;
use Any::Moose;
has docomo          => (is => 'ro', isa => 'Str');
has google          => (is => 'ro', isa => 'Str');
has id              => (is => 'ro', isa => 'Str');
has kddi            => (is => 'ro', isa => 'Str');
has name            => (is => 'ro', isa => 'Str');
has softbank        => (is => 'ro', isa => 'Str');
has unicode         => (is => 'ro', isa => 'Str');
has desc            => (is => 'ro', isa => 'Str');
has glyphRefID      => (is => 'ro', isa => 'Str');
has ann             => (is => 'ro', isa => 'Str');
has img_from        => (is => 'ro', isa => 'Str');
has text_fallback   => (is => 'ro', isa => 'Str');
has in_proposal     => (is => 'ro', isa => 'Str');
has text_repr       => (is => 'ro', isa => 'Str');
has prop            => (is => 'ro', isa => 'Str');

has docomo_emoji   => (is => 'ro', isa => 'Unicode::Emoji::Base::Emoji', lazy_build => 1);
has kddi_emoji     => (is => 'ro', isa => 'Unicode::Emoji::Base::Emoji', lazy_build => 1);
has softbank_emoji => (is => 'ro', isa => 'Unicode::Emoji::Base::Emoji', lazy_build => 1);
has google_emoji   => (is => 'ro', isa => 'Unicode::Emoji::Base::Emoji', lazy_build => 1);
has unicode_emoji  => (is => 'ro', isa => 'Unicode::Emoji::Base::Emoji', lazy_build => 1);
has kddiweb_emoji  => (is => 'ro', isa => 'Unicode::Emoji::Base::Emoji', lazy_build => 1);

sub _build_docomo_emoji   { $_[0]->docomo   && Unicode::Emoji::DoCoMo::Emoji->new(unicode_hex => $_[0]->docomo) };
sub _build_kddi_emoji     { $_[0]->kddi     && Unicode::Emoji::KDDI::Emoji->new(unicode_hex => $_[0]->kddi) };
sub _build_softbank_emoji { $_[0]->softbank && Unicode::Emoji::SoftBank::Emoji->new(unicode_hex => $_[0]->softbank) };
sub _build_google_emoji   { $_[0]->google   && Unicode::Emoji::Google::Emoji->new(unicode_hex => $_[0]->google) };
sub _build_unicode_emoji  { $_[0]->unicode  && Unicode::Emoji::Unicode::Emoji->new(unicode_hex => $_[0]->unicode) };
sub _build_kddiweb_emoji  { $_[0]->kddi     && Unicode::Emoji::KDDIweb::Emoji->fromKDDI($_[0]->kddi_emoji) };

package Unicode::Emoji::Google::Emoji;
use Any::Moose;
extends 'Unicode::Emoji::Base::Emoji';

package Unicode::Emoji::Unicode::Emoji;
use Any::Moose;
extends 'Unicode::Emoji::Base::Emoji';

__PACKAGE__->meta->make_immutable;
