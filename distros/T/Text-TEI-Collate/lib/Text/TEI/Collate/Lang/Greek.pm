package Text::TEI::Collate::Lang::Greek;

use strict;
use warnings;
use Text::TEI::Collate::Lang;
use Text::WagnerFischer;
use Unicode::Normalize;

=head1 NAME

Text::TEI::Collate::Lang::Armenian - (Classical) Armenian language module for
Text::TEI::Collate

=head1 DESCRIPTION

This module is an extension of Text::TEI::Collate::Lang for the Greek
language.  At this point it is really just a placeholder for later use.

Also see documentation for Text::TEI::Collate::Lang. 

=head1 METHODS

=head2 distance

Use Text::WagnerFischer::distance.

=cut

sub distance {
    return Text::WagnerFischer::distance( @_ );
}

sub canonizer { return Text::TEI::Collate::Lang::canonizer( @_ ) }

=begin testing

use Test::More::UTF8;
use Text::TEI::Collate::Lang::Greek;

my $comp = \&Text::TEI::Collate::Lang::Greek::comparator;
is( $comp->( "αι̣τια̣ν̣" ), "αιτιαν", "Got correct comparison string for Greek underdots" );

=end testing

=cut

sub comparator { return Text::TEI::Collate::Lang::comparator( @_ ) }

1;

=head1 AUTHOR

Tara L Andrews E<lt>aurum@cpan.orgE<gt>
