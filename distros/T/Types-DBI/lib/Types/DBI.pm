use 5.008001;
use strict;
use warnings;

package Types::DBI;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use DBI ();
use Type::Library -base;
use Types::Standard qw( InstanceOf ArrayRef Str );

our @EXPORT = 'Dbh';

my $meta = __PACKAGE__->meta;

my $dbh = $meta->add_type(
	name                 => 'Dbh',
	parent               => InstanceOf['DBI::db'],
	constraint_generator => sub {
		my @allowed = @_;
		return sub {
			my $type = $_->get_info(17);
			!!grep($_ eq $type, @allowed);
		};
	},
	coercion_generator   => sub {
		my $parent  = shift;
		my $child   = shift;
		my @allowed = @_;
		'Type::Coercion'->new(
			type_constraint   => $child,
			type_coercion_map => [@{ $parent->coercion->type_coercion_map }],
		)->freeze;
	},
	inline_generator     => sub {
		my @allowed = @_;
		return sub {
			return (
				undef,
				sprintf(
					'%s->get_info(17) eq %s',
					$_[1],
					B::perlstring($allowed[0]),
				),
			);
		} if @allowed == 1;
		return sub {
			return (
				undef,
				sprintf(
					'do { my $t = %s->get_info(17); %s }',
					$_[1],
					join(' or ', map { my $x = B::perlstring($_); "\$t eq $x" } @allowed),
				),
			);
		};
	},
);

my $sth = $meta->add_type(
	name   => 'Sth',
	parent => InstanceOf['DBI::st'],
);

$dbh->coercion->add_type_coercions(
	Str       ,=> q{ 'DBI'->connect($_, '', '', { RaiseError => 1 }) },
	ArrayRef  ,=> q{ 'DBI'->connect(@$_) },
);

$_->coercion->freeze for $dbh, $sth;

1;

__END__

=pod

=encoding utf-8

=for stopwords dereferenced

=head1 NAME

Types::DBI - type constraints for dealing with relational databases

=head1 SYNOPSIS

   package FroobleBase;
   
   use Moose;
   use Types::DBI;
   
   has dbh => (
      is       => 'ro',
      isa      => Dbh['PostgreSQL'],
      coerce   => 1,
      required => 1,
   );

=head1 DESCRIPTION

L<Types::DBI> is a type constraint library suitable for use with
L<Moo>/L<Moose> attributes, L<Kavorka> sub signatures, and so forth.

=head2 Types

This module provides two type constraints, but only C<Dbh> is exported
by default.

=over

=item C<Dbh>

A class type for DBI database handles (DBI::db objects). Coercions from:

=over

=item from C<Str>

The string will be passed to C<< DBI->connect >> as the DSN. Empty
strings will be supplied as the username and password parameters. (Many
databases allow the username and password to be specified as part of
the DSN. Some databases like SQLite can be usefully used without any
authentication details.) The C<< RaiseError >> attribute will be set to
true.

=item from C<ArrayRef>

The arrayref will be dereferenced and passed to C<< DBI->connect >>.

=back

=item C<Dbh[`a]>

C<Dbh> can be parameterized with one or more database names:

   isa  => Dbh["SQLite"]

   isa  => Dbh[qw/ SQLite PostgreSQL /]

The database names must be a case-sensitive match for the strings
returned by C<< $dbh->get_info(SQL_DBMS_NAME) >>.

Coercions are inherited from non-parameterized C<Dbh>.

=item C<Sth>

A class type for DBI statement handles (DBI::st objects). No coercions.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-DBI>.

=head1 SEE ALSO

L<Types::Standard>, L<DBI>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

