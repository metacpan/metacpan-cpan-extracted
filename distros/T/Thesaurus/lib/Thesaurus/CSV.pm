package Thesaurus::CSV;

use strict;

use Thesaurus;

use base 'Thesaurus';

use IO::File;
use Params::Validate qw( validate SCALAR BOOLEAN );
use Text::CSV_XS;

sub new
{
    return shift->SUPER::new(@_);
}

sub _init
{
    my $self = shift;
    my %p = validate( @_,
                      { filename => { type => SCALAR } }
                    );

    $self->{csv} = Text::CSV_XS->new( { binary => 1 } );
    $self->{params}{filename} = $p{filename};

    if ( -e $self->{params}{filename} )
    {
        my $fh = IO::File->new("<$self->{params}{filename}")
            or die "Cannot read $self->{params}{filename}: $!";

        while ( ! $fh->eof )
        {
            my $cols = $self->{csv}->getline($fh);

            die "Text::CSV_XS can't parse " . $self->{csv}->error_input
                unless defined $cols;

            $self->add($cols);
        }
    }

    return $self;
}

sub save
{
    my $self = shift;

    my $fh = IO::File->new(">$self->{params}{filename}")
	or die "Cannot write to $self->{params}{filename}: $!";

    foreach my $list ( $self->all )
    {
	$self->{csv}->print( $fh, $list );
	print $fh "\n";
    }

    close $fh;
}

1;

__END__

=head1 NAME

Thesaurus::CSV - Read/write thesarus data from/to a file

=head1 SYNOPSIS

  use Thesaurus::CSV;

  my $book = Thesaurus::CSV->new( filename => '/some/file/name.csv' );

=head1 DESCRIPTION

This subclass of C<Thesaurus> implements persistence by reading and
storing data in a CSV format text file.

This CSV file can easily be edited from a text editor

For very large objects, consider using the C<Thesaurus::BerkeleyDB>
subclass instead, as it is much more memory-efficient.

This module requires the C<Text::CSV_XS> module from CPAN.

=head1 METHODS

=over 4

=item * new

Besides those parameters taken by its parent class, C<Thesaurus>, this
class requires an additional parameter, C<filename>.  If this file
exists when the object is created, data from the file be used to
populate the object in memory.

=item * save

Writes the contents of the object to its associated file.

=back

=cut
