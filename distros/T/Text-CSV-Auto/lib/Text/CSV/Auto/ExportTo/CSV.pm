package Text::CSV::Auto::ExportTo::CSV;
BEGIN {
  $Text::CSV::Auto::ExportTo::CSV::VERSION = '0.06';
}
use Moose;

=head1 NAME

Text::CSV::Auto::ExportTo::CSV - Export a CSV to a CSV.

=head1 SYNOPSIS

    use Text::CSV::Auto;
    use Text::CSV::Auto::ExportTo::CSV;
    
    my $auto = Text::CSV::Auto->new('path/to/file.csv');
    my $exporter = Text::CSV::Auto::ExportTo::CSV->new(
        auto => $auto,
        file => 'path/to/new_file.csv',
    );
    $exporter->export();

=head1 DESCRIPTION

This module allows the exporting of a CSV to a new CSV.

=cut

use Text::CSV;
use autodie;
use Clone qw( clone );

=head1 ATTRIBUTES

=head2 auto

The L<Text::CSV::Auto> instance to copy headers and rows from.  Required.

=cut

with 'Text::CSV::Auto::ExportTo';

=head2 file

The file name to write the new CSV to.  Required.

=cut

has 'file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
sub _fh {
    my ($self) = @_;
    return IO::File->new( $self->file(), 'w' );
}

=head2 csv_options

Set this to a hashref of extra options that you'd like to have
passed down to the underlying L<Text::CSV> writer.

Read the L<Text::CSV> docs to see the many options that it supports.

=cut

has 'csv_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);

=head2 csv

This contains an instance of the L<Text::CSV> object that is used
to write the CSV file.  You may pass in your own writer object.
If you don't then one will be instantiated for you with the
csv_options().

If not set already in csv_options, the following defaults
will be used:

    auto_diag => 1 # die() if there are any errors.
    sep_char  => $auto->separator()

=cut

has 'csv' => (
    is         => 'ro',
    isa        => 'Text::CSV',
    lazy_build => 1,
);
sub _build_csv {
    my ($self) = @_;

    my $options = clone( $self->csv_options() );

    $options->{auto_diag} //= 1;
    $options->{sep_char}  //= $self->auto->separator();

    return Text::CSV->new($options);
}

=head2 newline

The character used for newlines.  Defaults to "\n" which will produce a newline
that is the default for your OS.

=cut

has 'newline' => (
    is      => 'ro',
    isa     => 'Str',
    default => "\n",
);

=head1 METHODS

=head2 export

    $exporter->export();

Exports the source CSV file to the destination CSV file.

=cut

sub export {
    my ($self) = @_;

    my $csv = $self->csv();
    my $fh = $self->_fh();
    my $newline = $self->newline();

    my $headers = $self->auto->headers();
    $csv->print( $fh, $headers );
    print $fh $newline;

    $self->auto->_raw_process(sub{
        my ($row) = @_;

        $csv->print( $fh, $row );
        print $fh $newline;

        return 1;
    }, 1);

    return;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

