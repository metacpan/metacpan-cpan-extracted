package Wikibase::Datatype::Value::Monolingual;

use strict;
use warnings;

use Mo qw(default is);

our $VERSION = 0.05;

extends 'Wikibase::Datatype::Value';

has language => (
	is => 'ro',
	default => 'en',
);

sub type {
	return 'monolingualtext';
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Value::Monolingual - Wikibase monolingual value datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Value::Monolingual;

 my $obj = Wikibase::Datatype::Value::Monolingual->new(%params);
 my $language = $obj->language;
 my $type = $obj->type;
 my $value = $obj->value;

=head1 DESCRIPTION

This datatype is string class for representation of translatable string.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Value::Monolingual->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<language>

Language shortcut.
Parameter is optional.
Default value is 'en'.

=item * C<value>

Value of instance.
Parameter is required.

=back

=head2 C<language>

 my $language = $obj->language;

Get language shortcut.

Returns string.

=head2 C<type>

 my $type = $obj->type;

Get type. This is constant 'monolingualtext'.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get value.

Returns string.

=head1 ERRORS

 new():
         From Wikibase::Datatype::Value::new():
                 Parameter 'value' is required.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Wikibase::Datatype::Value::Monolingual;

 # Object.
 my $obj = Wikibase::Datatype::Value::Monolingual->new(
         'language' => 'en',
         'value' => 'English text',
 );

 # Get language.
 my $language = $obj->language;

 # Get type.
 my $type = $obj->type;

 # Get value.
 my $value = $obj->value;

 # Print out.
 print "Language: $language\n";
 print "Type: $type\n";
 print "Value: $value\n";

 # Output:
 # Language: en
 # Type: monolingualtext
 # Value: English text

=head1 DEPENDENCIES

L<Mo>,
L<Wikibase::Datatype::Value>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.05

=cut
