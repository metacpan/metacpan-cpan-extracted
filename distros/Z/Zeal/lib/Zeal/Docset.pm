package Zeal::Docset;

use 5.014000;
use strict;
use warnings;

our $VERSION = '0.001001';

use parent qw/Class::Accessor::Fast/;
__PACKAGE__->mk_ro_accessors(qw/path plist dbh name id family/);

use Carp qw/carp/;
use Cwd qw/realpath/;
use File::Spec::Functions qw/catfile catdir rel2abs/;
use HTTP::Tiny;

use DBI;
use File::Slurp qw/read_file/;
use Mac::PropertyList::SAX qw/parse_plist_file/;

use Zeal::Document;

sub new {
	my ($class, $path) = @_;
	$path = realpath $path;
	my $plpath  = catfile $path, 'Contents', 'Info.plist';
	my $dbpath = catfile $path, 'Contents', 'Resources', 'docSet.dsidx';
	my $plist = parse_plist_file($plpath)->as_perl;
	carp 'This is not a Dash docset' unless $plist->{isDashDocset};

	bless {
		path   => $path,
		plist  => $plist,
		dbh    => DBI->connect("dbi:SQLite:dbname=$dbpath", '', ''),
		name   => $plist->{CFBundleName},
		id     => $plist->{CFBundleIdentifier},
		family => $plist->{DocSetPlatformFamily},
	}, $class
}

sub _blessdocs {
	my ($self, $docsref) = @_;
	map {
		my %hash = (%$_, docset => $self);
		($hash{path}, $hash{anchor}) = split /#/s, $hash{path};
		Zeal::Document->new(\%hash);
	} @$docsref;
}

sub fetch {
	my ($self, $path) = @_;
	return HTTP::Tiny->new->get($path)->{content} if $path =~ /^http:/s;
	my $docroot = catdir $self->path, 'Contents', 'Resources', 'Documents';
	$path = rel2abs $path, $docroot;
	scalar read_file $path
}

sub query {
	my ($self, $cond) = @_;
	my $query = 'SELECT * FROM searchIndex WHERE name LIKE ?';
	my $res = $self->dbh->selectall_arrayref($query, {Slice => {}}, $cond);
	my @results = $self->_blessdocs($res);
	wantarray ? @results : $results[0]
}

sub get {
	my ($self, $cond) = @_;
	$self->query($cond)->fetch
}

sub list {
	my ($self) = @_;
	my $query = 'SELECT * FROM searchIndex';
	my $res = $self->dbh->selectall_arrayref($query, {Slice => {}});
	$self->_blessdocs($res)
}

1;
__END__

=encoding utf-8

=head1 NAME

Zeal::Docset - Class representing a Dash/Zeal docset

=head1 SYNOPSIS

  use Zeal::Docset;
  my $ds = Zeal::Docset->new('/home/mgv/docsets/Perl.docset');
  say $ds->$path;  # /home/mgv/docsets/Perl.docset
  say $ds->name;   # Perl
  say $ds->id;     # perl
  say $ds->family; # perl

  # In SQL LIKE, % is .* and _ is .
  my @matches = $ds->query('perlopen%'); # finds perlopenbsd and perlopentut
  my $doc = $ds->query('perlsec'); # A Zeal::Document object for perlsec
  my $html = $ds->get('perls_c'); # HTML documentation of perlsec
  my @docs = $ds->list; # all documents

=head1 DESCRIPTION

Dash is an offline API documentation browser. Zeal::Docset is a class
representing a Dash/Zeal docset.

Available methods:

=over

=item Zeal::Docset->B<new>(I<$path>)

Create a Zeal::Docset object from a given docset. I<$path> should be
the path to a F<something.docset> directory.

=item $ds->B<path>

The path to the docset folder.

=item $ds->B<plist>

A hashref with the contents of Info.plist.

=item $ds->B<dbh>

A DBI database handle to the docSet.dsidx index.

=item $ds->B<name>

The name of this docset. Equivalent to
C<< $ds->plist->{CFBundleName} >>

=item $ds->B<id>

The identifier of this docset. Equivalent to
C<< $ds->plist->{CFBundleIdentifier} >>

=item $ds->B<family>

The family this docset belongs to. Dash uses this as the keyword for
restricting searches to a particular family of docsets. Equivalent to
C<< $ds->plist->{DocSetPlatformFamily} >>

=item $ds->B<fetch>(I<$path>)

Internal method for fetching the HTML content of a document. I<$path>
is either the path to the document relative to C<< $ds->B<path> >> or
a HTTP URL.

=item $ds->B<query>(I<$cond>)

In list context, return all documents (L<Zeal::Document> instances)
matching I<$cond>. In scalar context, return one such document.
I<$cond> is a SQL LIKE condition.

=item $ds->B<get>(I<$cond>)

The HTML content of one document that matches I<$cond>.
I<$cond> is a SQL LIKE condition.

This method is shorthand for C<< $ds->query(I<$cond>)->fetch >>.

=item $ds->B<list>

The list of all documents (L<Zeal::Document> instances) in this
docset.

=back

=head1 SEE ALSO

L<Zeal>, L<http://kapeli.com/dash>, L<http://zealdocs.org>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
