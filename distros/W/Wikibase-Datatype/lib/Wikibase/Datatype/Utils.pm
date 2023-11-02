package Wikibase::Datatype::Utils;

use base qw(Exporter);
use strict;
use warnings;

use DateTime;
use Error::Pure qw(err);
use List::Util qw(none);
use Wikibase::Datatype::Languages qw(all_language_codes);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_datetime check_entity check_language
	check_lexeme check_property check_sense);

our $VERSION = 0.33;

sub check_datetime {
	my ($self, $key) = @_;

	if ($self->{$key} !~ m/^([\+\-]\d+)\-(\d{2})\-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/ms) {
		err "Parameter '$key' has bad date time.",
			'Value', $self->{$key},
		;
	}
	my ($year, $month, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
	if ($month > 12) {
		err "Parameter '$key' has bad date time month value.",
			'value' => $self->{$key},
		;
	}
	if ($month > 0) {
		my $dt = DateTime->new(
			'day' => 1,
			'month' => $month,
			'year' => int($year),
		)->add(months => 1)->subtract(days => 1);;
		if ($day > $dt->day) {
			err "Parameter '$key' has bad date time day value.",
				'value' => $self->{$key},
			;
		}
	} else {
		if ($day != 0) {
			err "Parameter '$key' has bad date time day value.",
				'value' => $self->{$key},
			;
		}
	}
	if ($hour != 0) {
		err "Parameter '$key' has bad date time hour value.",
			'value' => $self->{$key},
		;
	}
	if ($min != 0) {
		err "Parameter '$key' has bad date time minute value.",
			'value' => $self->{$key},
		;
	}
	if ($sec != 0) {
		err "Parameter '$key' has bad date time second value.",
			'value' => $self->{$key},
		;
	}

	return;
}

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

sub check_sense {
	my ($self, $key) = @_;

	if (! defined $self->{$key}) {
		return;
	}

	if ($self->{$key} !~ m/^L\d+\-S\d+$/ms) {
		err "Parameter '$key' must begin with 'L' and number, dash, S and number after it.";
	}

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

 use Wikibase::Datatype::Utils qw(check_datetime check_entity check_language check_lexeme check_property check_sense);

 check_datetime($self, $key);
 check_entity($self, $key);
 check_language($self, $key);
 check_lexeme($self, $key);
 check_property($self, $key);
 check_sense($self, $key);

=head1 DESCRIPTION

Datatype utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_datetime>

 check_datetime($self, $key);

Check parameter defined by C<$key> if it's datetime for Wikibase.
Format of value is variation of ISO 8601 with some changes (like 00 as valid month).

Returns undef.

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

=head2 C<check_sense>

 check_sense($self, $key);

Check parameter defined by C<$key> if it's property (/^L\d+\-S\d+$/).

Returns undef.

=head1 ERRORS

 check_datetime():
         Parameter '%s' has bad date time.
                 Value: %s
         Parameter '%s' has bad date time day value.
                 Value: %s
         Parameter '%s' has bad date time hour value.
                 Value: %s
         Parameter '%s' has bad date time minute value.
                 Value: %s
         Parameter '%s' has bad date time month value.
                 Value: %s
         Parameter '%s' has bad date time second value.
                 Value: %s

 check_entity():
         Parameter '%s' must begin with 'Q' and number after it.";

 check_language():
         Language code '%s' isn't ISO 639-1 code.
         Language with ISO 639-1 code '%s' doesn't exist.

 check_lexeme():
         Parameter '%s' must begin with 'L' and number after it.";

 check_property():
         Parameter '%s' must begin with 'P' and number after it.";

 check_sense():
         Parameter '%s' must begin with 'L' and number, dash, S and number after it.

=head1 EXAMPLE1

=for comment filename=check_datetime_success.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Utils qw(check_datetime);

 my $self = {
         'key' => '+0134-11-00T00:00:00Z',
         'precision' => 10
 };
 check_datetime($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_datetime_fail.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Utils qw(check_datetime);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => '+0134-34-00T00:01:00Z',
 };
 check_datetime($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # #Error [/../Wikibase/Datatype/Utils.pm:?] Parameter 'key' has bad date time month value.

=head1 EXAMPLE3

=for comment filename=check_entity_success.pl

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

=head1 EXAMPLE4

=for comment filename=check_entity_fail.pl

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

=head1 EXAMPLE5

=for comment filename=check_lexeme_success.pl

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

=head1 EXAMPLE6

=for comment filename=check_lexeme_fail.pl

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

=head1 EXAMPLE7

=for comment filename=check_property_success.pl

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

=head1 EXAMPLE8

=for comment filename=check_property_fail.pl

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

=head1 EXAMPLE9

=for comment filename=check_sense_success.pl

 use strict;
 use warnings;

 use Wikibase::Datatype::Utils qw(check_sense);

 my $self = {
         'key' => 'L34727-S1',
 };
 check_sense($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE10

=for comment filename=check_sense_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Wikibase::Datatype::Utils qw(check_sense);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad_sense',
 };
 check_sense($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [/../Wikibase/Datatype/Utils.pm:?] Parameter 'key' must begin with 'L' and number, dash, S and number after it.

=head1 DEPENDENCIES

L<DateTime>,
L<Exporter>,
L<Error::Pure>,
L<List::Util>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Datatype>

Wikibase datatypes.

=item L<Mo::utils>

Mo utilities.

=item L<Mo::utils::Language>

Mo language utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Datatype>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.33

=cut
