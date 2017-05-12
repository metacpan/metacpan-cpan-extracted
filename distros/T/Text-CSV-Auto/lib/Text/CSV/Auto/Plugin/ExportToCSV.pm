package Text::CSV::Auto::Plugin::ExportToCSV;
BEGIN {
  $Text::CSV::Auto::Plugin::ExportToCSV::VERSION = '0.06';
}
use Moose::Role;

=head1 NAME

Text::CSV::Auto::Plugin::ExportToCSV - Provides a direct interface from
Text::CSV::Auto to export to a CSV.

=head1 SYNOPSIS

    use Text::CSV::Auto;
    my $auto = Text::CSV::Auto->new('path/to/file.csv');
    $auto->export_to_csv(
        file => 'path/to/new_file.csv',
    );

=head1 DESCRIPTION

This L<Text::CSV::Auto> plugin provides a simple interface to
L<Text::CSV::Auto::ExportToCSV>.

=head1 METHODS

=head2 export_to_csv

All arguments are passed directly on to L<Text::CSV::Auto::ExportToCSV>.

=cut

use Text::CSV::Auto::ExportTo::CSV;

sub export_to_csv {
    my $self = shift;

    my $options;
    if (@_ == 1) {
        $options = shift;
    }
    else {
        $options = { @_ };
    }

    return Text::CSV::Auto::ExportTo::CSV->new(
        auto => $self,
        %$options,
    )->export();
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

