package Text::TEI::Collate::Lang::Latin;

use strict;
use warnings;
use Text::TEI::Collate::Lang;

=head1 NAME

Text::TEI::Collate::Lang::Armenian - (Classical) Armenian language module for
Text::TEI::Collate

=head1 DESCRIPTION

This module is an extension of Text::TEI::Collate::Lang for the Latin
language.  It is really just here to normalize 'v' to 'u', and 'j' to 'i'.

Also see documentation for Text::TEI::Collate::Lang.

=head1 METHODS

=head2 comparator

This is a function to normalize some Latin spelling.

=cut

sub comparator {
   	my $word = shift;
    $word =~ s/v/u/g;
    $word =~ s/j/i/g;
    $word =~ s/cha/ca/g;
    return $word;
}

sub distance { return Text::TEI::Collate::Lang::distance( @_ ) }
sub canonizer { return Text::TEI::Collate::Lang::canonizer( @_ ) }

1;

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
