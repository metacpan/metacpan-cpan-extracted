package Wikibase::Datatype::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util qw(none);
use Locale::Language;
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_entity check_language check_lexeme check_property);

our $VERSION = 0.11;

sub check_entity {
	my ($self, $key) = @_;

	_check_item_with_char($self, $key, 'Q');

	return;
}

sub check_language {
	my ($self, $key) = @_;

	if (none { $_ eq $self->{$key} } all_language_codes()) {
		err "Language code '".$self->{$key}."' isn't ISO 639-1 code.";
	}

	return;
}

sub check_lexeme {
	my ($self, $key) = @_;

	_check_item_with_char($self, $key, 'L');

	return;
}

sub check_property {
	my ($self, $key) = @_;

	_check_item_with_char($self, $key, 'P');

	return;
}

sub _check_item_with_char {
	my ($self, $key, $char) = @_;

	if (! defined $self->{$key}) {
		return;
	}

	if ($self->{$key} !~ m/^$char\d+$/ms) {
		err "Parameter '$key' must begin with '$char' and number after it.";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Datatype::Utils - Wikibase datatype utilities.

=head1 SYNOPSIS

 use Wikibase::Datatype::Utils qw(check_entity check_language check_lexeme check_property);

 check_entity($self, $key);
 check_language($self, $key);
 check_lexeme($self, $key);
 check_property($self, $key);

=head1 DESCRIPTION

Datatype utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_entity>

 check_entity($self, $key);

Check parameter defined by C<$key> if it's entity (/^Q\d+/).

Returns undef.

=head2 C<check_language>

 check_language($self, $key);

Check parameter defined by C<$key> if it's ISO 639-1 language code and if language exists.

Returns undef.

=head2 C<check_lexeme>

 check_lexeme($self, $key);

Check parameter defined by C<$key> if it's entity (/^L\d+/).

Returns undef.

=head2 C<check_property>

 check_property($self, $key);

Check parameter defined by C<$key> if it's property (/^P\d+/).

Returns undef.

=head1 ERRORS

 check_entity():
         Parameter '%s' must begin with 'Q' and number after it.";

 check_language():
         Language code '%s' isn't ISO 639-1 code.
         Language with ISO 639-1 code '%s' doesn't exist.

 check_lexeme():
         Parameter '%s' must begin with 'L' and number after it.";

 check_property():
         Parameter '%s' must begin with 'P' and number after it.";

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Wikibase::Datatype::Utils qw(check_entity);

 my $self = {
         'key' => 'Q123',
 };
 check_entity($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Error::Pure;
 use Wikibase::Datatype::Utils qw(check_entity);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad_entity',
 };
 check_entity($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [/../Wikibase/Datatype/Utils.pm:?] Parameter 'key' must begin with 'Q' and number after it.

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Wikibase::Datatype::Utils qw(check_lexeme);

 my $self = {
         'key' => 'L123',
 };
 check_lexeme($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

 use strict;
 use warnings;

 use Error::Pure;
 use Wikibase::Datatype::Utils qw(check_lexeme);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad_entity',
 };
 check_lexeme($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [/../Wikibase/Datatype/Utils.pm:?] Parameter 'key' must begin with 'L' and number after it.

=head1 EXAMPLE5

 use strict;
 use warnings;

 use Wikibase::Datatype::Utils qw(check_property);

 my $self = {
         'key' => 'P123',
 };
 check_property($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE6

 use strict;
 use warnings;

 use Error::Pure;
 use Wikibase::Datatype::Utils qw(check_property);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad_property',
 };
 check_property($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [/../Wikibase/Datatype/Utils.pm:?] Parameter 'key' must begin with 'P' and number after it.

=head1 DEPENDENCIES

L<Exporter>,
L<Error::Pure>,
L<List::Util>,
L<Locale::Language>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2020-2022

BSD 2-Clause License

=head1 VERSION

0.11

=cut
