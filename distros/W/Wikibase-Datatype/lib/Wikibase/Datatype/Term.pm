package Wikibase::Datatype::Term;

use strict;
use warnings;

use Mo qw(build is);
use Mo::utils 0.01 qw(check_required);
use Wikibase::Datatype::Utils qw(check_language_term);

our $VERSION = 0.38;

has language => (
	is => 'ro',
);

has value => (
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check language.
	if (! defined $self->{'language'}) {
		$self->{'language'} = 'en',
	}
	check_language_term($self, 'language');

	# Check value.
	check_required($self, 'value');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Term - Wikibase term datatype.

=head1 SYNOPSIS

 use Wikibase::Datatype::Term;

 my $obj = Wikibase::Datatype::Term->new(%params);
 my $language = $obj->language;
 my $value = $obj->value;

=head1 DESCRIPTION

This datatype is string class for representation of translatable string. This
datatype is used for label, description and alias.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Datatype::Term->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<language>

Language shortcut.
Parameter is optional.
Value is checked to Wikibase language code used for terms.
Default value is 'en'.

=item * C<value>

Value of instance.
Parameter is required.

=back

=head2 C<language>

 my $language = $obj->language;

Get language shortcut.

Returns string.

=head2 C<value>

 my $value = $obj->value;

Get value.

Returns string.

=head1 ERRORS

 new():
         From Wikibase::Datatype::Value::new():
                 Parameter 'value' is required.

         From Wikibase::Datatype::Utils::check_language_term():
                 Language code '%s' isn't code supported for terms by Wikibase.

=head1 EXAMPLE

=for comment filename=create_and_print_term.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Term;

 # Object.
 my $obj = Wikibase::Datatype::Term->new(
         'language' => 'en',
         'value' => 'English text',
 );

 # Get language.
 my $language = $obj->language;

 # Get value.
 my $value = $obj->value;

 # Print out.
 print "Language: $language\n";
 print "Value: $value\n";

 # Output:
 # Language: en
 # Value: English text

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Wikibase::Datatype::Utils>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype::Value::Monolingual>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.38

=cut
