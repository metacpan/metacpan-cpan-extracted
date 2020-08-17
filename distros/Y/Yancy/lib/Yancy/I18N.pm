package Yancy::I18N;
our $VERSION = '1.066';
# ABSTRACT: Internationalization (i18n) for Yancy

#pod =head1 SYNOPSIS
#pod
#pod     # XXX: Show how to set the language of Yancy
#pod     # XXX: Show how to create a custom lexicon
#pod     # XXX: Show examples of bracket notation (quant, numf, numerate,
#pod     # sprintf, and positional parameters)
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the internationalization module for Yancy. It uses L<Locale::Maketext> to do
#pod the real work.
#pod
#pod B<NOTE:> This is a work-in-progress and not all of Yancy's text has been made available
#pod for translation. Patches welcome!
#pod
#pod =head2 Languages
#pod
#pod Yancy comes with the following lexicons:
#pod
#pod =over
#pod
#pod =item L<English (US)|Yancy::I18N::en>
#pod
#pod =back
#pod
#pod =head2 Custom Lexicons
#pod
#pod To create your own lexicon, start from an existing Yancy lexicon and add your own
#pod entries, like so:
#pod
#pod     package MyApp::I18N;
#pod     use Mojo::Base 'Yancy::I18N';
#pod
#pod     package MyApp::I18N::en;
#pod     use Mojo::Base 'Yancy::I18N::en';
#pod     our %Lexicon = (
#pod         'Additional entry' => 'Additional entry',
#pod     );
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious::Plugin::I18N>, L<Locale::Maketext>
#pod
#pod =cut

use Mojo::Base '-strict';
use base 'Locale::Maketext';

1;

__END__

=pod

=head1 NAME

Yancy::I18N - Internationalization (i18n) for Yancy

=head1 VERSION

version 1.066

=head1 SYNOPSIS

    # XXX: Show how to set the language of Yancy
    # XXX: Show how to create a custom lexicon
    # XXX: Show examples of bracket notation (quant, numf, numerate,
    # sprintf, and positional parameters)

=head1 DESCRIPTION

This is the internationalization module for Yancy. It uses L<Locale::Maketext> to do
the real work.

B<NOTE:> This is a work-in-progress and not all of Yancy's text has been made available
for translation. Patches welcome!

=head2 Languages

Yancy comes with the following lexicons:

=over

=item L<English (US)|Yancy::I18N::en>

=back

=head2 Custom Lexicons

To create your own lexicon, start from an existing Yancy lexicon and add your own
entries, like so:

    package MyApp::I18N;
    use Mojo::Base 'Yancy::I18N';

    package MyApp::I18N::en;
    use Mojo::Base 'Yancy::I18N::en';
    our %Lexicon = (
        'Additional entry' => 'Additional entry',
    );

=head1 SEE ALSO

L<Mojolicious::Plugin::I18N>, L<Locale::Maketext>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
