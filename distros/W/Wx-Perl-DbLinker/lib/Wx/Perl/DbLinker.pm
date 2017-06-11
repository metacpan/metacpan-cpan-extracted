
=head1 NAME

Wx::Perl::DbLinker - Wx gui building part of DbLinker.

=cut

package Wx::Perl::DbLinker;
use strict;
use warnings;

=head1 VERSION

version  0.013 but see version at the end of MYMETA.yml to check that I'm correct here...

=cut

our $VERSION     = '0.013';
$VERSION = eval $VERSION;

1;

__END__

=head1 INSTALLATION

To install this module type the following:
	perl Makefile.PL
	make
	make test
	make install

On windows use nmake or dmake instead of make.

=head1 DEPENDENCIES

The following modules are required in order to use Wx::Perl::Linker

	Gtk2::Ex::DbLinker::DbTools => latest version (see README),
	Data::Dumper => 2.154,
	DateTime::Format::Strptime => 1.5,
	Test::More => 1,
	Wx => 0.99,
	Log::Log4perl => 1.41
	DBD::SQLite'	=> 1.46
    Scalar::Util => 1.45
    Class::InsideOut => 1.13

Install one of Rose::DB::Object or DBIx::Class if you want to use these orm to access your data.

DBIx::Class is required to get example_dbc working.

=head1 DESCRIPTION

This module automates the process of tying data from a database to widgets on a xrc-generated form.

Steps for use:

=over

=item * 

Create a Gtk2::Ex::DbLinker::xxxDataManager object that contains the rows to display. Use DbiDataManager, RdbDataManager or DbcDataManager depending on how you access the database: sql commands and DBI, DBIx::Class or Rose::DB::Object

=item * 

Create xrc resource files to construct the gui: Wx windows and controls.
It is required that you name your widgets the same as the fields in your data source.


=item * 

Create a Wx::Perl:DbLinker::Wxform object that links the data and the gui 

=item *

Connect the buttons to methods that handle common actions such as inserting, moving, deleting, etc.

=back

=head1 EXAMPLES

The eg folder (located in the Wx-Perl-DbLinker-xxx folder under cpan/build in your perl folders tree) contains three examples.
All displays a main form with a bottom navigation bar that displays each record (a country and its main language) one by one. 
A subform displays other(s) language(s) spoken in that country. Each language is displayed one by one and a second navigation bar is used to show these in turn.
For each language, a list gives the others countries where this idiom is spoken. Items from this lists are also add/delete/changed with a third navigation bar.

The data is stored in two sqllite files that differs only on the layout of the speaks table. In both files, there are three tables: 

=over

=item *

countries (countryid, country, mainlangid), 

=item *

langues (langid, langue), 

=item *

speaks (in file ./data/ex1_1) (langid, countryid) is access with runexample_dbc.pl, runexample_sqla.pl  

speaks (in file ./data/ex1) (speaksid, langid, countryid) is access with runexample_rdb.pl

=back

=over

=item *

C<runexample_dbc.pl> uses DBIx::Class and Gtk2::Ex::DbLinker::DbcDataManager. The speaks table primary key is the complete row itself, with the two fields, countryid and langid.

=item *

C<runexample_sqla.pl> uses SQL::Abstract::More and Gtk2::Ex::DbLinker::SqlADataManager. The database is the same as above.

=item *

C<runexample_rdb.pl> uses Rose::Data::Object and Gtk2::Ex::DbLinker::RdbDataManager. The speaks table primary key is a counter speaksid and the two fields, countryid and langid compose an index which does not allow duplicate rows.

=back

=head1 SUPPORT

Any Wx::Perl::DbLinker questions or problems can be posted to me (rappazf) on my gmail account. 

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/wx-perl-dblinker/>.

=head1 AUTHOR

FranE<231>ois Rappaz <rappazf@gmail.com>    CPAN ID: RAPPAZF

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Gtk2::Ex::DbLinker::DbTools>

=cut



