package Tie::FieldVals::Row::Join;
use strict;
use warnings;

=head1 NAME

Tie::FieldVals::Row::Join - a hash tie for merging rows of Tie::FieldVals data

=head1 VERSION

This describes version B<0.6203> of Tie::FieldVals::Row::Join.

=cut

our $VERSION = '0.6203';

=head1 SYNOPSIS

    use Tie::FieldVals::Row;
    use Tie::FieldVals::Row::Join;

    # just the keys
    my %person_thing;
    my $jr = tie %person_thing, 'Tie::FieldVals::Row::Join,
	fields=>@keys;

    # keys and values
    my %person;
    my $rr = tie %person_thing, 'Tie::FieldVals::Row,
	fields=>@keys;

    my %person_thing;
    my $jr = tie %person_thing, 'Tie::FieldVals::Row::Join,
	row=>$rr;


=head1 DESCRIPTION

This is a Tie object to enable the merging of more than one
Tie::FieldVals::Row hashes into one hash.

=cut

use 5.006;
use strict;
use Carp;

our @ISA = qw(Tie::FieldVals::Row);

# to make taint happy
$ENV{PATH} = "/bin:/usr/bin:/usr/local/bin";
$ENV{CDPATH} = '';
$ENV{BASH_ENV} = '';

# for debugging
my $DEBUG = 0;

=head1 OBJECT METHODS

=head2 append_keys

    $row_obj->append_keys(@fields);

Extend the legal fields definition by adding the given fields to it.
Sets the given fields to be undefined.

=cut
sub append_keys ($@) {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my @keys = @_;

    foreach my $key (@keys)
    {
	if (!exists $self->{FIELDS}->{$key})
	{
	    $self->{FIELDS}->{$key} = undef;
	    push @{$self->{OPTIONS}->{fields}}, $key;
	}
    }

} # append_keys

=head2 merge_rows

    $row_obj->merge_rows($row_obj2);

Merge a Tie::FieldVals::Row object with this one. The second
row object has different Fields than this one, and this will
extend the legal fields definition by adding the given fields to it,
as well as adding the values of the second row to this row.

=cut
sub merge_rows ($$) {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $row_obj = shift;

    my @keys = @{$row_obj->field_names()};
    foreach my $key (@keys)
    {
	if (!exists $self->{FIELDS}->{$key}) # only add new keys
	{
	    $self->{FIELDS}->{$key} = [];
	    push @{$self->{FIELDS}->{$key}}, @{$row_obj->{FIELDS}->{$key}};
	    push @{$self->{OPTIONS}->{fields}}, $key;
	}
    }

} # merge_rows

=head1 TIE-HASH METHODS

=head2 TIEHASH

Create a new instance of the object as tied to a hash.

    my %person_thing;
    my $jr = tie %person_thing, 'Tie::FieldVals::Row::Join,
	fields=>@keys;

    my %person;
    my $rr = tie %person_thing, 'Tie::FieldVals::Row,
	fields=>@keys;

    my %person_thing;
    my $jr = tie %person_thing, 'Tie::FieldVals::Row::Join,
	row=>$rr;

=cut
sub TIEHASH {
    carp &whowasi if $DEBUG;
    my $class = shift;
    my %args = (
	fields=>undef,
	row=>undef,
	@_
    );

    my $self;
    if (defined $args{row})
    {
	my $row_obj = $args{row};
	delete $args{row};
	$self = Tie::FieldVals::Row::TIEHASH($class,
	    fields=>[qw(dummy)]);
	# merge the rows
	%{$self->{FIELDS}} = ();
	$self->{OPTIONS}->{fields} = [];
	$self->merge_rows($row_obj);
    }
    else # just fields
    {
	$self = Tie::FieldVals::Row::TIEHASH($class, %args)
    }

    return $self;
} # TIEHASH

sub UNTIE {
    carp &whowasi if $DEBUG;
    my $self = shift;
    my $count = shift;

    carp "untie attempted while $count inner references still exist" if $count;

    $self->SUPER::UNTIE($count);
}

=head1 PRIVATE METHODS

For developer reference only.

=head2 debug

Set debugging on.

=cut
sub debug { $DEBUG = @_ ? shift : 1 }

=head2 whowasi

For debugging: say who called this 

=cut
sub whowasi { (caller(1))[3] . '()' }

=head1 REQUIRES

    Test::More
    Carp

=head1 SEE ALSO

perl(1).
L<Tie::FieldVals>
L<Tie::FieldVals::Join>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Tie::FieldVals::Row::Join
__END__
