package XML::NewsML_G2::Translatable_Text;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::HasTranslations';

has 'text', is => 'ro', isa => 'Str', required => 1;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Translatable_Text - a text with optional translations

=head1 SYNOPSIS

    my $text = XML::NewsML_G2::Translatable_Text->new(text => 'Freizeit');
    $text->add_translation('en', 'leisure');

=head1 ATTRIBUTES

=over 4

=item text

Default (untranslated) text content

=back

=head1 METHODS

=over 4

=item add_translation

Define a translation for the text

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
