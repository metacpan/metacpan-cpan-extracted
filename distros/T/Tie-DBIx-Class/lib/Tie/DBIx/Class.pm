package Tie::DBIx::Class;

=pod

=head1 NAME

Tie::DBIx::Class - Tie a DBIx::Class ResultSet into a hash

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  my $object = Tie::DBIx::Class->new(
      foo  => 'bar',
      flag => 1,
  );
  
=head1 DESCRIPTION

This module ties a DBIx::Class::ResultSet into a simple hash but loads
the referenced DBIx::Class::ResultSet only on request reducing database
access.

DBIx::Class puts a SQL row into a simple object and masks all SQL from
you scripts, but it's strictly database based.

Imagine you got a house:

my $house = House->new(1);
$house->open_door();

$house could be a SQL row, but what if you'ld like
to add methods or sub-objects which aren't SQL rows?

Here is what Tie-DBIx-Class is for:

package House;

sub new {
    my $class = shift;
    my $house_id = shift;
    tie(my %row,'Tie::DBIx::Class',$main::schema,'houses',$house_id);
    return bless \%row,$class;
}

sub open_door {
    # Access the door controller
}

Every column is accessible as a hash key of the blessed object
while you're still free to define additional methods.

In addition, Tie::DBIx::Class waits for the first access to
the hash's data before actually fetching the data from the
database - saving resources in case you just want to open the
door and don't need the SQL row's data at all.

Tie::DBIx::Class has been developed for use with
Template::Toolkit. Templates may get access to database rows
without the need to preload everything which might be used by
a template. Just create the objects and push them to
Template::Toolkit and the required rows will be loaded
automatically.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use Tie::Hash;

our $VERSION = '0.01'; # UPDATE POD VERSION ABOVE!
our @ISA = ('Tie::StdHash');

=pod

=head2 TIEHASH

  tie %hashname,'Tie::DBIx::Class',$dbh,$table_name,$primary_key);

The C<new> constructor lets you create a new B<Tie::DBIx::Class> object.

So no big surprises there...

=cut

# TODO: Allow { seckey => value } as alternate to $primary_key

sub TIEHASH {
	my $class = shift;
	my $dbh = shift;
	my $table = shift;
	my $find = shift;
	
	my $self = bless {
		dbh => $dbh,
		table => $table,
		find => $find
		}, $class;
	
	return $self;
}

=pod

=head2 DELETE

Remove the value for a key.

=cut

sub DELETE {
	my $self = shift;
	my $key = shift;

	$self->_CHECK_DBIx;

	return $self->{DBIx}->$key(undef);
}

=pod

=head2 EXISTS

Check if a keys exists.

=cut

sub EXISTS {
	my $self = shift;
	my $key = shift;

	$self->_CHECK_DBIx;

	return $self->{dbh}->class($self->{table})->has_column($key);
}

=pod

=head2 FETCH

Called for every read access to the tied hash.

=cut

sub FETCH {
	my $self = shift;
	my $key = shift;

	$self->_CHECK_DBIx;

	return $self->{DBIx}->get_column($key);
}

=pod

=head2 FIRSTKEY

Start a new keys() loop.

=cut

sub FIRSTKEY {
	my $self = shift;

	$self->{keys} = [$self->{dbh}->class($self->{table})->columns];

	return $self->NEXTKEY;
}

=pod

=head2 NEXTKEY

Return a key for the keys() listing.

=cut

sub NEXTKEY {
	my $self = shift;

	return shift(@{$self->{keys}});
}

=pod

=head2 STORE

Called for every write access to the tied hash.

=cut

sub STORE {
	my $self = shift;
	my $key = shift;
	my $value = shift;

	$self->_CHECK_DBIx;

	return $self->{DBIx}->set_column($key,$value);
}

=pod

=head2 UNTIE

Commit changes to database.

=cut

sub UNTIE {
	my $self = shift;

	return unless defined($self->{DBIx});

	if ($self->{new}) {
		return $self->{DBIx}->insert;
	} else {
		return $self->{DBIx}->update;
	}
}

=pod

=head1 INTERNAL METHODS

=head2 _CHECK_DBIx

Check if the DBIx::Class::ResultSet was fetched before.

=cut

sub _CHECK_DBIx {
	my $self = shift;
	
	return if defined($self->{DBIx});

	$self->{DBIx} = $self->{dbh}->resultset($self->{table})->find($self->{find})
	if defined($self->{find}); 

	return if defined($self->{DBIx});

	$self->{DBIx} = $self->{dbh}->resultset($self->{table})->new({});
	$self->{new} = 1;

}

1;

=pod

=head1 AUTHOR

Copyright 2010 Sebastian Willing

=head1 BUGS

Please report any bugs or feature requests to C<bug-tie-dbix-class at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-DBIx-Class>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

Most important things to do:
 - Improve error handling

Nice to have:
 - Allow ->search instead of ->find

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::DBIx::Class

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-DBIx-Class>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-DBIx-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-DBIx-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-DBIx-Class/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Sebastian Willing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
