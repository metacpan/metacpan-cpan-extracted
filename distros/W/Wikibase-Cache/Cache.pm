package Wikibase::Cache;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);

our $VERSION = 0.03;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Wikibase::Cache::Backend backend.
	$self->{'backend'} = 'Basic';

	# Process parameters.
	set_params($self, @params);

	# Load backend module.
	my $backend_module = 'Wikibase::Cache::Backend::'.$self->{'backend'};
	eval "require $backend_module;";
	if ($EVAL_ERROR) {
		err "Cannot load module '$backend_module'.",
			'Error', $EVAL_ERROR;
	}
	$self->{'_backend'} = $backend_module->new;

	# Check for inheritance.
	if (! $self->{'_backend'}->isa('Wikibase::Cache::Backend')) {
		err "Backend must inherit 'Wikibase::Cache::Backend' abstract class.";
	}

	return $self;
}

sub get {
	my ($self, $type, $key) = @_;

	return $self->{'_backend'}->get($type, $key);
}

sub save {
	my ($self, $type, $key, $value) = @_;

	return $self->{'_backend'}->save($type, $key, $value);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Wikibase::Cache - Wikibase cache class.

=head1 SYNOPSIS

 use Wikibase::Cache;

 my $obj = Wikibase::Cache->new(%params);
 my $backend_ret = $obj->get($type, $key);
 my $backend_ret = $obj->save($type, $key, $value);

=head1 METHODS

=head2 C<new>

 my $obj = Wikibase::Cache->new(%params);

Constructor.

=over 8

=item * C<backend>

Wikibase::Cache::Backend backend class.

Default value is 'Basic' = L<Wikibase::Cache::Backend::Basic>.

=back

Returns instance of object.

=head2 C<get>

 my $backend_ret = $obj->get($type, $key);

Get cached value for C<$type> and C<$key>.
Example C<$type> is 'label' and C<$key> is Wikidata QID like 'Q42'. Returns
something like 'Douglas Adams'.

Returns backend return value(s).

=head2 C<save>

 my $backend_ret = $obj->save($type, $key, $value);

Save cached value for C<$type> and C<$key>.
Example C<$type> is 'label' and C<$key> is Wikidata QID like 'Q42' (Douglas
Adams).
Another example C<$type> is 'description' and C<$key> is Wikidata QID like 'Q42'
(English science fiction writer and humourist).

Returns backend return value(s).

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Backend must inherit 'Wikibase::Cache::Backend' abstract class.
         Cannot load module '%s'.
                 Error: %s

=head1 EXAMPLE1

=for comment filename=get_cached_value.pl

 use strict;
 use warnings;

 use Wikibase::Cache;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 qid_or_pid\n";
         exit 1;
 }
 my $qid_or_pid = $ARGV[0];

 # Object.
 my $obj = Wikibase::Cache->new;

 # Get translated QID.
 my $translated_qid_or_pid = $obj->get('label', $qid_or_pid) || $qid_or_pid;

 # Print out.
 print $translated_qid_or_pid."\n";

 # Output for nothing:
 # Usage: ./get_cached_value.pl qid_or_pid

 # Output for 'P31':
 # instance of

 # Output for 'Q42':
 # Q42

=head1 EXAMPLE2

=for comment filename=save_cached_value.pl

 use strict;
 use warnings;

 use Error::Pure qw(err);
 use Wikibase::Cache;

 $Error::Pure::TYPE = 'Error';

 # Object.
 my $obj = Wikibase::Cache->new;

 # Save label for 'Q42'.
 $obj->save('label', 'Q42', 'Douglas Adams');

 # Get translated QID.
 my $translated_qid = $obj->get('label', 'Q42');

 # Print out.
 print $translated_qid."\n";

 # Output:
 # #Error [../Wikibase/Cache/Backend/Basic.pm:60] Wikibase::Cache::Backend::Basic doesn't implement save() method.

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Wikibase::Cache::Backend>

TODO

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Wikibase-Cache>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
