use 5.008;
use strict;
use warnings;

package Text::Pipe::Translate;
our $VERSION = '1.100890';
# ABSTRACT: Translate text from one language to another
use Lingua::Translate;
use parent qw(Text::Pipe::Base);
__PACKAGE__->mk_scalar_accessors(qw(from to translators));
use constant DEFAULTS => (translators => {},);

sub get_translator {
    my $self = shift;
    $self->translators->{ $self->from }{ $self->to } ||=
      Lingua::Translate->new(src => $self->from, dest => $self->to);
}

sub filter_single {
    my ($self, $input) = @_;
    $self->get_translator->translate($input);
}
1;


__END__
=pod

=head1 NAME

Text::Pipe::Translate - Translate text from one language to another

=head1 VERSION

version 1.100890

=head1 SYNOPSIS

    use Text::Pipe 'PIPE';
    my $pipe = PIPE 'Translate::Babelfish', from => 'en', to => 'de';
    my $german = $pipe->filter('My hovercraft is full of eels.'),

=head1 DESCRIPTION

This pipe segment can translate text from one language to another. To do so it
uses L<Lingua::Translate>.

Both source and destination language are to be given in RFC3066 form. See
L<I18N::LangTags>.

=head1 METHODS

=head2 get_translator

Constructs a translator object for the current settings of C<from()> and
C<to()> and caches it using the C<translators()> accessor.

=head2 filter_single

Takes a string and translates it according to the current settings of
C<from()> and C<to()>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Text-Pipe-Translate>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Text-Pipe-Translate/>.

The development version lives at
L<http://github.com/hanekomu/Text-Pipe-Translate/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

