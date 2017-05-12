package Text::CSV::LibCSV;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);

use Carp;
use Scalar::Util qw(blessed);

BEGIN {
    $VERSION = '0.10';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @ISA = qw(DynaLoader);
        __PACKAGE__->bootstrap;
    }
    require Exporter;
    push @ISA, 'Exporter';
    @EXPORT = qw(csv_parse CSV_STRICT CSV_REPALL_NL);
}

sub csv_parse {
    my ($data, $callback, $opt) = @_;
    __PACKAGE__->new($opt || 0)->parse($data, $callback);
}

sub parse {
    my ($self, $data, $callback) = @_;
    if (blessed($data) && $data->isa('IO::Handle')) {
        $self->parse_fh($data, $callback);
    } else {
        $self->xs_parse($data, $callback);
    }
}

sub parse_fh {
    my ($self, $fh, $callback) = @_;
    my $data = do { local $/; <$fh> };
    $self->xs_parse($data, $callback);
}

sub parse_file {
    my ($self, $file, $callback) = @_;
    open my $fh, '<', $file or croak "$file: $!";
    $self->parse_fh($fh, $callback);
    close $fh;
}

1;
__END__

=head1 NAME

Text::CSV::LibCSV - comma-separated values manipulation routines (using libcsv)

=head1 SYNOPSIS

  use Text::CSV::LibCSV;

  my $callback = sub {
       my @fields = @_;
       print(join(',', @fields), "\n");
  };
  csv_parse($data, $callback) or die;
  # or using OO interface
  my $parser = Text::CSV::LibCSV->new;
  $parser->parse($data, $callback) or die $parser->strerror;

=head1 DESCRIPTION

This module is an interface for libcsv.
It is available at: http://sourceforge.net/projects/libcsv/

WARNING: Please note that this module is primarily targetted for libcsv >= 1.0.0, so if things seem to be broken and your libcsv version is below 1.0.0, then you might want to consider upgrading libcsv first.

=head1 METHODS

=over 4

=item new([$opts])

Initialize parser object.

Option can be set CSV_STRICT or CSV_REPALL_NL.
Read libcsv's documentation for details.

Returns an instance of this module.

=item opts($opts)

Set options.

=item parse($data, $callback)

Parse a CSV string.

Callback function is called at the end of every row.

Returns true on success or undef on failure.

You can get error message by strerror.

=item parse_file($file, $callback)

Parse a CSV string from file.

=item parse_fh($fh, $callback)

Parse a CSV string from file handle.

You can use C<parse()> in the same way.

NOTE: C<parse_file()> and C<parse_fh()> read all data to memory once.
It is not necessarily the case that they work faster than parse.

=item strerror

Returns error message.

=back

=head1 FUNCTIONS

=over 4

=item csv_parse($data, $callback [, $option])

Parse a CSV string.

Callback function is called at the end of every row.

=back

=head1 EXPORT

csv_parse, CSV_STRICT, CSV_REPALL_NL

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://sourceforge.net/projects/libcsv/>

=cut

