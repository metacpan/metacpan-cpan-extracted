package Wikibase::Datatype::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_entity check_property);

our $VERSION = 0.03;

sub check_entity {
	my ($self, $key) = @_;

	if (! defined $self->{$key}) {
		return;
	}

	if ($self->{$key} !~ m/^Q\d+$/ms) {
		err "Parameter '$key' must begin with 'Q' and number after it.";
	}

	return;
}

sub check_property {
	my ($self, $key) = @_;

	if (! defined $self->{$key}) {
		return;
	}

	if ($self->{$key} !~ m/^P\d+$/ms) {
		err "Parameter '$key' must begin with 'P' and number after it.";
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

 use Wikibase::Datatype::Utils qw(check_entity);

 check_entity($self, $key);
 check_property($self, $key);

=head1 DESCRIPTION

Datatype utilities for checking of data objects.

=head1 SUBROUTINES

=head2 C<check_entity>

 check_entity($self, $key);

Check parameter defined by C<$key> whith is entity (/^Q\d+/).

Returns undef.

=head2 C<check_property>

 check_property($self, $key);

Check parameter defined by C<$key> whith is property (/^P\d+/).

Returns undef.

=head1 ERRORS

 check_entity():
         Parameter '%s' must begin with 'Q' and number after it.";

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

 use Wikibase::Datatype::Utils qw(check_property);

 my $self = {
         'key' => 'P123',
 };
 check_property($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

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

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.03

=cut
