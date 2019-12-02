package XML::NewsML_G2::Role::HasTranslations;

use Moose::Role;
use namespace::autoclean;

has 'translations',
    isa     => 'HashRef',
    is      => 'rw',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
    add_translation  => 'set',
    has_translations => 'count',
    get_translation  => 'get',
    languages        => 'keys'
    };

1;
__END__

=head1 NAME

XML::NewsML_G2::Role::HasTranslations - Role for item types that have translations

=head1 SYNOPSIS

    my $media_topic = XML::NewsML_G2::Media_Topic->new
        (name  => 'alpine skiing',
         qcode => 20001057);
    $media_topic->add_translation('de', 'alpiner Skilauf')

=head1 DESCRIPTION

This module serves as a role for all NewsML-G2 item type classes which have
translations

=head1 ATTRIBUTES

=over 4

=item translations

Hash mapping from language to according translation

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
