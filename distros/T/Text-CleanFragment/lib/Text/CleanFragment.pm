package Text::CleanFragment;
use strict;
use Exporter qw'import';
use Text::Unidecode;

our $VERSION = '0.05';
our @EXPORT = (qw(clean_fragment));

=head1 NAME

=encoding utf8

Text::CleanFragment - clean up text to use as URL fragment or filename

=head1 SYNOPSIS

  my $title = "Do p\x{00FC}t <this> into/URL's?";
  my $id = 42;
  my $url = join "/",
              $id,
              clean_fragment( $title );
  # 42/Do_put_this_into_URLs

=head1 DESCRIPTION

This module downgrades strings of text to match

  /^[-._A-Za-z0-9]*$/

or, to be more exact

  /^([-.A-Za-z0-9]([-._A-Za-z0-9]*[-.A-Za-z0-9])?)?$/

This makes the return values safe to be used as URL fragments
or as file names on many file systems where whitespace
and characters outside of the Latin alphabet are undesired
or problematic.

=head1 FUNCTIONS

=head2 C<< clean_fragment( @fragments ) >>

    my $url_title = join("_", clean_fragment("Ümloud vs. ß",'by',"Grégory"));
    # Umloud_vs._ss_by_Gregory

Returns a cleaned up list of elements. The input elements
are expected to be encoded as Unicode strings. Decode them using
L<Encode> if you read the fragments as file names from the filesystem.

The operations performed are:

=over 4

=item *

Use L<Text::Unidecode> to downgrade the text from Unicode to 7-bit ASCII.

=item *

Eliminate single and double quotes, apostrophes.

=item *

Replace all non-letters, non-digits by underscores, including whitespace
and control characters.

=item *

Squash dashes to a single dash

=item *

Squash C<_-_> and C<_-_(-_)+> to -

=item *

Eliminate leading underscores

=item *

Eliminate trailing underscores

=item *

Eliminate underscores before - or .

=back

In scalar context, returns the first element of the cleaned up list.

=cut

sub clean_fragment {
    # make uri-sane filenames
    # We assume Unicode on input.

    # First, downgrade to ASCII chars (or transliterate if possible)
    @_ = unidecode(@_);

    for( @_ ) {
        tr/['"\x{2019}]//d;     # Eliminate apostrophes
        s/[^a-zA-Z0-9.-]+/_/g;  # Replace all non-ascii by underscores, including whitespace
        s/-+/-/g;               # Squash dashes
        s/_(?:-_)+/-/g;         # Squash _-_ and _-_-_ to -
        s/^[-_]+//;             # Eliminate leading underscores
        s/[-_]+$//;             # Eliminate trailing underscores
        s/_(\W)/$1/;            # No underscore before - or .
     };
    wantarray ? @_ : $_[0];
};

1;

__END__

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/text-cleanfragment>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-CleanFragment>
or via mail to L<text-cleanfragment-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2012-2022 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
