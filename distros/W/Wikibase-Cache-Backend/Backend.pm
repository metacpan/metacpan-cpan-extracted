package Wikibase::Cache::Backend;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use List::Util qw(none);
use Readonly;

Readonly::Array our @TYPES => qw(description label);

our $VERSION = 0.04;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

sub get {
	my ($self, $type, $key) = @_;

	# Check type.
	$self->_check_type($type);

	return $self->_get($type, $key);
}

sub save {
	my ($self, $type, $key, $value) = @_;

	# Check type.
	$self->_check_type($type);

	return $self->_save($type, $key, $value);
}

sub _check_type {
	my ($self, $type) = @_;

	if (! defined $type) {
		err 'Type must be defined.';
	}
	if (none { $type eq $_ } @TYPES) {
		err "Type '$type' isn't supported.";
	}

	return;
}

sub _get {
	my $self = shift;

	err "This is abstract class. You need to implement '_get' method.";
}

sub _save {
	my $self = shift;

	err "This is abstract class. You need to implement '_save' method.";
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Cache::Backend - Abstract class for Wikibase::Cache backend.

=head1 SYNOPSIS

 use Wikibase::Cache::Backend;

 my $obj = Wikibase::Cache::Backend->new;
 my $value = $obj->get($type, $key);
 my $saved_value = $obj->save($type, $key, $value);

=head1 DESCRIPTION

Abstract class for Wikibase::Cache backend.
Methods, which needs to implement are: C<_get()> and C<_save()>.

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Cache::Backend->new;

Constructor.

Returns instance of object.

=head2 C<get>

 my $value = $obj->get($type, $key);

Get cache value for C<$type> and C<$key>.
Possible types are 'description' and 'label'.

Returns string.

=head2 C<save>

 my $saved_value = $obj->save($type, $key, $value);

Save cache value for C<$type> and C<$key>. Value will be set to C<$value>.
Possible types are 'description' and 'label'.

Returns string.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 get():
         This is abstract class. You need to implement '_get' method.
         Type '%s' isn't supported.
         Type must be defined.';

 save():
	 This is abstract class. You need to implement '_save' method.
         Type '%s' isn't supported.
         Type must be defined.';

=head1 EXAMPLE

=for comment filename=simple_cache_backend.pl

 use strict;
 use warnings;

 package Foo;

 use base qw(Wikibase::Cache::Backend);

 sub _get {
         my ($self, $type, $key) = @_;

         my $value = $self->{'_data'}->{$type}->{$key} || undef;

         return $value;
 }

 sub _save {
         my ($self, $type, $key, $value) = @_;

         $self->{'_data'}->{$type}->{$key} = $value;

         return $value;
 }

 package main;

 # Object.
 my $obj = Foo->new;

 # Save cached value.
 $obj->save('label', 'foo', 'FOO');

 # Get cached value.
 my $value = $obj->get('label', 'foo');

 # Print out.
 print $value."\n";

 # Output like:
 # FOO

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::Util>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Wikibase::Cache>

Wikibase cache class.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Cache-Backend>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
