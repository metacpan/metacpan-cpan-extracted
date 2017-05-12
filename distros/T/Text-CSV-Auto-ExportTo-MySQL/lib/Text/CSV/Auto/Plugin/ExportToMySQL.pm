package Text::CSV::Auto::Plugin::ExportToMySQL;
BEGIN {
  $Text::CSV::Auto::Plugin::ExportToMySQL::VERSION = '0.02';
}
use Moose::Role;

=head1 NAME

Text::CSV::Auto::Plugin::ExportToMySQL - Provides a direct interface from
Text::CSV::Auto to export to MySQL.

=head1 SYNOPSIS

    use Text::CSV::Auto;
    my $auto = Text::CSV::Auto->new('path/to/file.csv');
    $auto->export_to_mysql(
        connection => $dbh,
    );

=head1 DESCRIPTION

This L<Text::CSV::Auto> plugin provides a simple interface to
L<Text::CSV::Auto::ExportTo::MySQL>.

=head1 METHODS

=head2 export_to_mysql

All arguments are passed directly on to L<Text::CSV::Auto::ExportTo::MySQL>.

=cut

use Text::CSV::Auto::ExportTo::MySQL;

sub export_to_mysql {
    my $self = shift;

    my $options;
    if (@_ == 1) {
        $options = shift;
    }
    else {
        $options = { @_ };
    }

    return Text::CSV::Auto::ExportTo::MySQL->new(
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

