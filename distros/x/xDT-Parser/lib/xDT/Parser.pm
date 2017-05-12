package xDT::Parser;

use v5.10;
use Moose;
use namespace::autoclean;
use FileHandle;
use Carp;

use xDT::Record;
use xDT::Object;

=head1 NAME

xDT::Parser - A Parser for xDT files.

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

Can be used to open xdt files and to iterate over contained objects.

    use xDT::Parser;

    my $parser = xDT::Parser->new();
    # or
    my $parser = xDT::Parser->new($configFile);

    # A config file must be in XML format and can be used to add
    # metadata (like accessor string or labels) to each record type.

    $parser->open($xdtFile);

    my $object = $parser->nextObject();
    # ...

    $parser->close();

=head1 ATTRUBITES

=head2 fh

FileHandle to the currently open file.

=cut

has 'fh' => (
    is            => 'rw',
    isa           => 'FileHandle',
    documentation => q{The filehandle the parser will use to read xDT data.},
);

=head2 config

The file where configurations of this parser are stored.

=cut

has 'configFile' => (
    is            => 'rw',
    isa           => 'Maybe[Str]',
    documentation => q{The file where configurations of this parser are stored.},
);


around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;

	if (@_ == 1 && !ref $_[0]) {
		return $class->$orig(configFile => $_[0]);
	} else {
		my %params = @_;
		return $class->$orig(\%params);
	}
};

=head1 SUBROUTINES/METHODS

=head1 open($xdtFile)

Sets the parsers filehandle on this file.
More information about the file format can be found at L<http://search.cpan.org/dist/xDT-RecordType/>.

=cut

sub open {
    my ($self, $file) = @_;

    croak("Error: provided file '$file' does not exist or is not readable.")
        unless (-f $file);

    my $fh = FileHandle->new($file, 'r')
        or croak("Error: could not open filehandle $file.");
    
    $self->fh($fh);
}

=head1 close

Closes the parsers filehandle

=cut

sub close {
    my $self = shift;

    close $self->fh;
}

=head1 nextObject

Returns the next object of the xDT file.

=cut

sub nextObject {
    my $self = shift;
    my $object = xDT::Object->new();

    while (my $record = $self->_next()) {
        last if ($record->isObjectEnd);
        $object->addRecord($record);
    }

    return $object;
}

sub _next {
    my $self = shift;
    my $line;
    
    do {
        $line = $self->fh->getline() or return undef;
    } while ($line =~ /^\s*$/);

    my $record = xDT::Record->new($line);
    $record->setRecordType(xDT::RecordType->new(
        configFile => $self->configFile,
        id         => substr($line, 3, 4)
    ));

    return $record;
}

=head1 AUTHOR

Christoph Beger, C<< <christoph.beger at imise.uni-leipzig.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xdt-parser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=xDT-Parser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc xDT::Parser


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

1; # End of xDT::Parser