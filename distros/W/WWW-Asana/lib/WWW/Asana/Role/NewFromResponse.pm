package WWW::Asana::Role::NewFromResponse;
BEGIN {
  $WWW::Asana::Role::NewFromResponse::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Role::NewFromResponse::VERSION = '0.003';
}
# ABSTRACT: Role which implements new_from_response for Asana classes

use MooX::Role;
use DateTime::Format::ISO8601;
use Class::Load ':all';


sub new_from_response {
	my ( $class, $data ) = @_;
	die "First parameter to new_From_response need to be a HashRef" unless ref $data eq 'HASH';
	my %data = %{$data};
	my %multi_mapping = (
		followers => 'WWW::Asana::User',
		workspaces => 'WWW::Asana::Workspace',
		projects => 'WWW::Asana::Project',
		tags => 'WWW::Asana::Tag',
	);
	my @needs_workspace = qw( projects tags );
	my %single_mapping = (
		assignee => 'WWW::Asana::User',
		workspace => 'WWW::Asana::Workspace',
		created_by => 'WWW::Asana::User',
	);
	my %new = %data;
	# single mapping before multi mapping so that workspace is already there
	for my $key (keys %single_mapping) {
		if (exists $data{$key}) {
			if ($data{$key}) {
				my $target_class = $single_mapping{$key};
				load_class($target_class) unless is_class_loaded($target_class);
				$new{$key} = $target_class->new_from_response({
					%{$data{$key}},
					defined $data{client} ? ( client => $data{client} ) : (),
					response => $data{response},
				});
			} else {
				delete $new{$key};
			}
		}
	}
	for my $key (keys %multi_mapping) {
		if (exists $data{$key}) {
			$new{$key} = [];
			my $target_class = $multi_mapping{$key};
			for (@{$data{$key}}) {
				load_class($target_class) unless is_class_loaded($target_class);
				push @{$new{$key}}, $target_class->new_from_response({
					%{$_},
					defined $data{client} ? ( client => $data{client} ) : (),
					(grep { $_ eq $key } @needs_workspace) ? ( workspace => $new{workspace} ) : (),
					response => $data{response},
				});
			}
		}
	}
	for my $key (qw( completed_at modified_at created_at due_on )) {
		if (exists $data{$key}) {
			if ($data{$key}) {
				$new{$key} = DateTime::Format::ISO8601->parse_datetime($data{$key});
			} else {
				delete $new{$key};
			}
		}
	}
	return $class->new(%new);
}

1;
__END__
=pod

=head1 NAME

WWW::Asana::Role::NewFromResponse - Role which implements new_from_response for Asana classes

=head1 VERSION

version 0.003

=head1 METHODS

=head2 new_from_response

This function converts the data which is get from Asana into the required
attributes for generation of the given class. The first parameter must be
a HashRef. This HashRef can be spiced with B<client> and B<response> to give
a client which is able to handle the B<do> function, or to reflect the
response which leaded to this object.

The B<client> attribute is required if you want todo any calls to the Asana
API.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

