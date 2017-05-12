package WWW::Asana::Story;
BEGIN {
  $WWW::Asana::Story::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Story::VERSION = '0.003';
}
# ABSTRACT: Asana Story Class

use MooX;

with 'WWW::Asana::Role::HasClient';
with 'WWW::Asana::Role::HasResponse';
with 'WWW::Asana::Role::NewFromResponse';

with 'WWW::Asana::Role::CanReload';

sub own_base_args { 'tags', shift->id }

sub reload_base_args { 'Tag', 'GET' }

has id => (
	is => 'ro',
	predicate => 1,
);

has text => (
	is => 'ro',
	predicate => 1,
);

has type => (
	is => 'ro',
	isa => sub {
		die "type must be 'comment' or 'system'" unless grep { $_[0] eq $_ } qw( comment system );
	},
	predicate => 1,
);

has source => (
	is => 'ro',
	isa => sub {
		die "source must be web, email, mobile, api or unknown"
			unless grep { $_[0] eq $_ } qw( web email mobile api unknown );
	},
	predicate => 1,
);

has target => (
	is => 'ro',
	isa => sub {
		die "target must be a WWW::Asana::Task or WWW::Asana::Project"
			unless ref $_[0] eq 'WWW::Asana::Task' or ref $_[0] eq 'WWW::Asana::Project';
	},
	required => 1,
);

has created_by => (
	is => 'ro',
	isa => sub {
		die "created_by must be a WWW::Asana::User" unless ref $_[0] eq 'WWW::Asana::User';
	},
	predicate => 1,
);

has created_at => (
	is => 'ro',
	isa => sub {
		die "created_at must be a DateTime" unless ref $_[0] eq 'DateTime';
	},
	predicate => 1,
);

1;

__END__
=pod

=head1 NAME

WWW::Asana::Story - Asana Story Class

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

