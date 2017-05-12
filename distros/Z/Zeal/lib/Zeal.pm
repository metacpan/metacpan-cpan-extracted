package Zeal;

use 5.014000;
use strict;
use warnings;
use re '/s';

our $VERSION = '0.001001';

use File::Spec::Functions qw/catfile/;

use Zeal::Docset;
use Zeal::Document;

sub new {
	my ($class, $path) = @_;
	$path //= $ENV{ZEAL_PATH};
	my $self = bless {sets => {}}, $class;
	if ($path) {
		$self->add($_) for split /:/, $path;
	}
	$self
}

sub add {
	my ($self, $path) = @_;
	return unless -d $path;
	if ($path =~ /[.]docset$/) {
		my $ds = Zeal::Docset->new($path);
		$self->{sets}{$ds->family} //= [];
		push @{$self->{sets}{$ds->family}}, $ds;
	} else {
		my $dir;
		opendir $dir, $path;
		my @entries = grep { !/^[.]{1,2}$/ } readdir $dir;
		closedir $dir;
		$self->add(catfile $path, $_) for @entries
	}
}

sub sets {
	my ($self, $family) = @_;
	return map { @$_ } values %{$self->{sets}} unless $family;
	die "No docsets in family '$family'\n" unless $self->{sets}{$family};
	@{$self->{sets}{$family}}
}

sub query {
	my ($self, $query, $family) = @_;
	($family, $query) = split /:/, $query, 2 if !$family && $query =~ /^\w+:[^:]/;
	my @res = map { $_->query($query) } $self->sets($family);
	wantarray ? @res : $res[0]
}

1;
__END__

=encoding utf-8

=head1 NAME

Zeal - Read and query Dash/Zeal docsets

=head1 SYNOPSIS

  use Zeal;
  my $zeal = Zeal->new("/home/mgv/docsets/:/home/mgv/something.docset");
  $zeal->add('/home/mgv/somethingelse.docset'); # Add another docset
  $zeal->add('/home/mgv/moredocsets/');         # Add a directory containing docsets

  my $doc = $zeal->query('length');             # Documentation for 'length' in all docsets
  my @docs = $zeal->query('Test::%', 'perl');   # Documentation for all Test:: perl modules
  @docs = $zeal->query('perl:Test::%);          # Alternative syntax

=head1 DESCRIPTION

Dash is an offline API documentation browser. Zeal.pm is a module for
reading and querying Dash documentation sets.

This module queries multiple docsets. If you only have one docset, you
should use the L<Zeal::Docset> module directly.

Available methods:

=over

=item Zeal->B<new>([I<$path>])

Create a new Zeal object. I<$path> is an optional colon delimited
string for initializing the object. Each of its components is
recursively scanned for docsets (and can also be a docset itself). If
I<$path> is not provided, the value of I<$ENV{ZEAL_PATH}> (if defined)
is used instead.

=item $zeal->B<add>(I<$path>)

Recursively scan a path for docsets, adding them to this object.

=item $zeal->B<sets>([I<$family>])

Return a list of docsets (L<Zeal::Docset> objects) in the given
family, or in all families if I<$family> is not provided.

=item $zeal->B<query>(I<"$family:$query">)

=item $zeal->B<query>(I<$query>, [I<$family>])

Return a list of documents (L<Zeal::Document> objects) matching a
query, optionally restricted to a family. In scalar context only one
such document is returned. I<$query> is a SQL LIKE condition.

=back

=head1 SEE ALSO

L<http://kapeli.com/dash>, L<http://zealdocs.org>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
