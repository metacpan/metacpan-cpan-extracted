package Text::Undiacritic;

use strict;
use warnings;
our $VERSION = '0.07';

require Exporter;
our @ISA = qw(Exporter); ## no critic
our @EXPORT_OK = qw(undiacritic);

use charnames ':full';
use Unicode::Normalize qw(decompose);

sub undiacritic {
  my $characters = shift;

  if ( !$characters ) { return $characters; }

  $characters = decompose($characters);
  $characters =~ s/\p{NonspacingMark}//gxms;

  return join('',
    map {
      (ord($_) > 127)
        ? do {
          my $charname = charnames::viacode(ord $_);
          $charname =~ s/\s WITH \s .+ \z//x;
          #charnames::string_vianame($charname);
          chr charnames::vianame($charname);
        }
        : $_;
    }
    split //, $characters
  );
}

1;

__END__

=pod

=head1 NAME

Text::Undiacritic - remove diacritics from a string

=for html
<a href="https://travis-ci.org/wollmers/Text-Undiacritic"><img src="https://travis-ci.org/wollmers/Text-Undiacritic.png" alt="Text-Undiacritic"></a>
<a href='https://coveralls.io/r/wollmers/Text-Undiacritic?branch=master'><img src='https://coveralls.io/repos/wollmers/Text-Undiacritic/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 VERSION

This document describes Text::Undiacritic 0.01

=head1 SYNOPSIS

    use Text::Undiacritic qw(undiacritic);
    $ascii_string = undiacritic( $czech_string );

=head1 DESCRIPTION

Changes characters with diacritics into their base characters.

Also changes into base character in cases where UNICODE does not provide a decomposition.

E.g. all characters '... WITH STROKE' like 'LATIN SMALL LETTER L WITH STROKE' do not have a decomposition. In the latter case the result will be 'LATIN SMALL LETTER L'.

Removing diacritics is useful for matching text independent of spelling variants.

=head1 SUBROUTINES/METHODS

=head2 undiacritic

    $ascii_string = undiacritic( $characters );

Removes diacritics from $characters and returns a simplified character string.

The input string must be in character modus, i.e. UNICODE code points.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item *

L<version>

=item *

L<charnames>

=item *

L<Unicode::Normalize>

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There is no experience if this module gives useful results for scripts other than Latin.

=head1 AUTHOR

Helmut Wollmersdorfer C<< <WOLLMERS@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Helmut Wollmersdorfer C<< <WOLLMERS@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
