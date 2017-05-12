package xDT::RecordType;

use v5.10;
use Moose;
use namespace::autoclean;
use Carp;
use XML::Simple;
use File::Basename;

=head1 NAME

xDT::RecordType - The record type of a xDT record.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use xDT::RecordType;

    my $recordType = xDT::RecordType->new($id);
	# or
	my $recordType = xDT::RecordType->new($id, $configFile);

	say $recordType->getLabels()->{en};
	say $recordType->getAccessor();

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 CONSTANTS

=head2 LENGTH

The maximum length of a record type identifier.

=cut

use constant {
	LENGTH => 4,
};

=head1 ATTRIBUTES

=head2 id

Unique identifier of this record type.

=cut

has id => (
	is            => 'ro',
	isa           => 'Str',
	required      => 1,
	reader        => 'getId',
	trigger       => \&_checkId,
	documentation => q{Unique identifier of this record type.},
);

=head2 labels

The human readable labels of this record type. Language is used as key value.

=cut

has labels => (
	is            => 'ro',
	isa           => 'Maybe[HashRef[Str]]',
	reader        => 'getLabels',
	documentation => q{The human readable labels of this record type. Language is used as key value.},
);

=head2 accessor

Short string for easy access to this record via xDT::Object.

=cut

has accessor => (
	is            => 'ro',
	isa           => 'Str',
	required      => 1,
	reader        => 'getAccessor',
	documentation => q{Short string for easy access to this record via xDT::Object.},
);

=head2 length

Max length of this record type.

=cut

has length => (
	is            => 'ro',
	isa           => 'Maybe[Str]',
	reader        => 'getLength',
	documentation => q{Max length of this record type.},
);

=head2 type

Corresponds to xDT record type string.

=cut

has type => (
	is            => 'ro',
	isa           => 'Maybe[Str]',
	reader        => 'getType',
	documentation => q{Corresponds to xDT record type string.},
);

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;

	if (@_ == 1 && !ref $_[0]) {
		return $class->$orig(_extractParametersFromConfigFile($_[0], $_[1]));
	} else {
		my %params = @_;
		return $class->$orig(_extractParametersFromConfigFile($params{'id'}, $params{'configFile'}));
	}
};

=head1 SUBROUTINES/METHODS

=head2 isObjectEnd

Checks if this record type is an ending record

=cut

sub isObjectEnd {
	my $self = shift;

	return $self->getId == 8201;
}

=head2 getId

Returns the id of this record type.

=cut

=head2 getLabels

Returns the labels of this record type.

=cut

=head2 getAccessor

Returns the accessor of this record type.

=cut

=head2 getLength

Returns the maximum length of this recourd type.

=cut

=head2 getType

Extracts metadata for a given record type id from the config file, if a file was given.
Otherwise id and accessor are set to the given id and all other attributes are undef.

Format of the XML config file:

	<RecordTypes>
		<RecordType id="theId" length="theLength" type="theType" accessor="theAccessor">
			<label lang="en">TheEnglishLabel</label>
			<label lang="de">TheGermanLabel</label>
			...
		</RecordType>
		...
	</RecordTypes>

=cut

sub _extractParametersFromConfigFile {
	my $id         = shift // croak('Error: parameter $id missing.');
	my $configFile = shift;

	my $xml = new XML::Simple(
		KeyAttr    => { RecordType => 'id', label => 'lang' },
		ForceArray => 1,
		ContentKey => '-content',
	);

	my $config = ();
	$config = $xml->XMLin($configFile)->{RecordType}->{$id}
		if (defined $configFile);
	
	return (
		id       => $id,
		labels   => $config->{label},
		type     => $config->{type},
		accessor => $config->{accessor} // $id,
		length   => $config->{length},
	);
}


sub _checkId {
	my ($self, $id) = @_;

	croak(sprintf("Error: attribute 'id' has length %d (should be %d).", length $id, LENGTH))
		unless (length $id == LENGTH);
}

=head1 AUTHOR

Christoph Beger, C<< <christoph.beger at imise.uni-leipzig.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xdt-parser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=xDT-Parser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc xDT::RecordType


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=xDT-Parser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/xDT-Parser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/xDT-Parser>

=item * Search CPAN

L<http://search.cpan.org/dist/xDT-Parser/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Christoph Beger.

This program is released under the following license: MIT


=cut

__PACKAGE__->meta->make_immutable;

1; # End of xDT::RecordType