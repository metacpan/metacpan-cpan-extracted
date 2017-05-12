package Text::Hunspell;

require DynaLoader;

use vars qw/  @ISA $VERSION /;
@ISA = 'DynaLoader';

$VERSION = '2.14';

bootstrap Text::Hunspell $VERSION;

# Preloaded methods go here.

1;
__END__

=encoding utf8

=head1 NAME

Text::Hunspell - Perl interface to the Hunspell library

=head1 SYNOPSIS

    use Text::Hunspell;

    # You can use relative or absolute paths.
    my $speller = Text::Hunspell->new(
        "/usr/share/hunspell/en_US.aff",    # Hunspell affix file
        "/usr/share/hunspell/en_US.dic"     # Hunspell dictionary file
    );

    die unless $speller;

    # Check a word against the dictionary
    my $word = 'opera';
    print $speller->check($word)
          ? "'$word' found in the dictionary\n"
          : "'$word' not found in the dictionary!\n";

    # Spell check suggestions
    my $misspelled = 'programmng';
    my @suggestions = $speller->suggest($misspelled);
    print "\n", "You typed '$misspelled'. Did you mean?\n";
    for (@suggestions) {
        print "  - $_\n";
    }

    # Add dictionaries later
    $speller->add_dic('dictionary_file.dic');


=head1 DESCRIPTION

This module provides a Perl interface to the B<Hunspell> library.
This module is to meet the need of looking up many words,
one at a time, in a single session, such as spell-checking
a document in memory.

The example code describes the interface on http://hunspell.sf.net

=head1 DEPENDENCIES

B<You MUST have installed the Hunspell library version 1.0 or higher>
on your system before installing this C<Text::Hunspell> Perl module.

Hunspell location is:

    http://hunspell.sf.net

There have been a number of bug reports because people failed to install
hunspell before installing this module.

This is an interface to the hunspell library installed on your system,
not a replacement for hunspell.

You must also have one hunspell dictionary installed when running the module's
test suite.

Also, please see the README and Changes files.  README may have specific
information about your platform.

=head1 METHODS

The following methods are available:

=head2 Text::Hunspell->new($full_path_to_affix, $full_path_to_dic)

Creates a new speller object. Parameters are:

=over 4

=item full path of affix (.aff) file

=item full path of dictionary (.dic) file

=back

Returns C<undef> if the object could not be created, which is unlikely.

=head2 add_dic($path_to_dic)

Adds a new dictionary to the current C<Text::Hunspell> object. This dictionary
will use the same affix file as the original dictionary, so this is like using
a personal word list in a given language. To check spellings in several
different languages, use multiple C<Text::Hunspell> objects.

=head2 check($word)

Check the word. Returns 1 if the word is found, 0 otherwise.

=head2 suggest($misspelled_word)

Returns the list of suggestions for the misspelled word.

The following methods are used for morphological analysis, which is looking
at the structure of words; parts of speech, inflectional suffixes and so on.
However, most of the dictionaries that Hunspell can use are missing this
information and only contain affix flags which allow, for example, 'cat' to
turn into 'cats' but not 'catability'. (Users of the French and Hungarian
dictionaries will find that they have more information available.)

=head2 analyze($word)

Returns the analysis list for the word. This will be a list of
strings that contain a stem word and the morphological information
about the changes that have taken place from the stem. This will
most likely be 'fl:X' strings that indicate that affix flag 'X'
was applied to the stem. Words may have more than one stem, and
each one will be returned as a different item in the list.

However, with a French dictionary loaded, C<analyze('chanson')> will return

  st:chanson po:nom is:fem is:sg

to tell you that "chanson" is a feminine singular noun, and
C<analyze('chansons')> will return

  st:chanson po:nom is:fem is:pl

to tell you that you've analyzed the plural of the same noun.

=head2 stem($word)

Returns the stem list for the word. This is a simpler version of the
results from C<analyze()>.

=head2 generate2($stem, \@suggestions)

Returns a morphologically modified stem as defined in
C<@suggestions> (got by analysis).

With a French dictionary:

  $feminine_form = 'chanteuse';
  @ana = $speller->analyze($feminine_form);
  $ana[0] =~ s/is:fem/is:mas/;
  print $speller->generate2($feminine_form, \@ana)

will print 'chanteur'.

=head2 generate($stem, $word)

Returns morphologically modified stem like $word.

  $french_speller->generate('danseuse', 'chanteur');

tells us that the masculine form of 'danseuse' is 'danseur'.


=head1 BUGS

Probably. Yes, definitely.

=head1 LICENSE

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHORS

Originally written by
Eleonora, E<lt>eleonora46_at_gmx_dot_netE<gt>.

The current maintainer is
Cosimo Streppone, E<lt>cosimo@cpan.orgE<gt>

This module is based on L<Text::Aspell>
written by Bill Moseley moseley at hank dot org.

Hunspell is written as myspell by Kevin B. Hendricks.

Hunspell is maintained by Németh László.

Please see:

    http://hunspell.sf.net

For the dictionaries:

   https://wiki.openoffice.org/wiki/Dictionaries
   http://magyarispell.sf.net for Hungarian dictionary

=cut
