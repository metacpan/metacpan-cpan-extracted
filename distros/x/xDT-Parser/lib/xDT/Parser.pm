package xDT::Parser;

use v5.10;
use Moose;
use FileHandle;

use xDT::Record;
use xDT::RecordType;
use xDT::Object;

=head1 NAME

xDT::Parser - A Parser for xDT files.

=head1 VERSION

Version 1.04

=cut

our $VERSION = '1.04';


=head1 SYNOPSIS

Can be used to open xdt files and strings, and to iterate over contained objects.

    use xDT::Parser;

    my $parser = xDT::Parser->new();
    # or
    my $parser = xDT::Parser->new(record_type_config => $config);
    # or
    my $parser = xDT::Parser->new(
        record_type_config => xDT::Parser::build_config_from_xml($xml_file)
    );
    # or
    my $parser = xDT::Parser->new(
        record_type_config => JSON::Parser::read_json($json_file)
    );

    # A record type configuration can be provided via xml file or arrayref and can be used to add
    # metadata (like accessor string or labels) to each record type.

    $parser->open(file => $xdt_file);     # read from file
    # or
    $parser->open(string => $xdt_string); # read from string

    while (my $object = $parser->next_object) {  # iterate xdt objects
        # ...
    }

    $parser->close(); # close the file handle

=head1 ATTRIBUTES

=head2 fh

FileHandle to the currently open file.

=cut

has 'fh' => (
    is            => 'rw',
    isa           => 'FileHandle',
    documentation => q{The filehandle the parser will use to read xDT data.},
);

=head2 record_type_config

The C<RecordType> configurations.

e.g.:

    [{
        "id": "0201",
        "length": "9",
        "type": "num",
        "accessor": "bsnr",
        "labels": {
            "en": "BSNR",
            "de": "BSNR"
        }
    }]

=cut

has 'record_type_config' => (
    is            => 'rw',
    isa           => 'ArrayRef',
    documentation => q{Contains configurations for record types.},
);


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if (@_ == 1) {
        return $class->$orig(record_type_config => $_[0]);
    } else {
        my %params = @_;
        return $class->$orig(\%params);
    }
};

=head1 SUBROUTINES/METHODS

=head2 open

$parser->open(file => 'example.gdt');
$parser->open(string => $xdt_string);

Open a file or string with the parser.
If both file and string are given, the string will be ignored.
More information about the file format can be found at L<http://search.cpan.org/dist/xDT-RecordType/>.

=cut

sub open {
    my ($self, %args) = @_;

    my $file   = $args{file};
    my $string = $args{string};
    my $fh;

    die 'Error: No file or string argument given to parse xDT.'
        unless (defined $file or defined $string);

    if (defined $file) {
        die "Error: Provided file '$file' does not exist or is not readable."
            unless (-f $file);

        $fh = FileHandle->new($file, 'r')
            or die "Error: Could not open file handle for '$file'.";
    } else {
        $fh = FileHandle->new(\$string, 'r')
            or die 'Error: Could not open file handle for provided string.';
    }

    $self->fh($fh);
}

=head2 close

Closes the parsers filehandle

=cut

sub close {
    my $self = shift;

    close $self->fh;
}

=head2 next_object

Returns the next object from xDT.

=cut

sub next_object {
    my $self = shift;
    my @records;

    while (my $record = $self->_next()) {
        last if ($record->is_object_end);
        push @records, $record;
    }

    return undef unless (scalar @records);

    my $object = xDT::Object->new();
    foreach my $record (@records) {
        $object->add_record($record);
    }

    return $object;
}

=head2 build_config_from_xml

Extracts metadata for a given record type id from a XML config file, if a file was given.
Otherwise id and accessor are set to the given id and all other attributes are undef.

XML::Simple must be installed in order to use this method.

Format of the XML config file:

	<RecordTypes>
		<RecordType id="theId" length="theLength" type="theType" accessor="theAccessor">
			<label lang="en">TheEnglishLabel</label>
			<label lang="de">TheGermanLabel</label>
			<!-- more labels -->
		</RecordType>
		<!-- more record types -->
	</RecordTypes>

=cut

sub build_config_from_xml {
	my $file = shift;

    return [] unless (length $file);

    use XML::Simple;
	return XML::Simple->new(
        KeyAttr    => { label => 'lang' },
        GroupTags  => { labels => 'label' },
		ContentKey => '-content',
	)->XMLin($file)->{RecordType};
}

sub _next {
    my $self = shift;
    my $line;
    
    do {
        $line = $self->fh->getline() or return undef;
    } while ($line =~ /^\s*$/);

    my $record = xDT::Record->new($line);
    $record->set_record_type(xDT::RecordType::build_from_arrayref(
        substr($line, 3, 4),
        $self->record_type_config,
    ));

    return $record;
}

=head1 AUTHOR

Christoph Beger, C<< <christoph.beger at medizin.uni-leipzig.de> >>

=cut

__PACKAGE__->meta->make_immutable;

1; # End of xDT::Parser
