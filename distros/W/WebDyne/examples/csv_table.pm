use strict;
use warnings;
use Text::CSV;
use HTML::Table;


sub csv_table  {
    
    # Self ref
    #
    my $self=shift();


    # Input CSV file
    #my $csv_file = File::Spec->rel2abs('./csv_table.csv', $self->cwd());
    my $csv_file = $self->rel2abs('./csv_table.csv');

    # Create a Text::CSV object
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });

    # Open the CSV file
    open my $fh, '<', $csv_file or die "Could not open '$csv_file': $!";

    # Create an HTML::Table object
    my $table = HTML::Table->new();

    # Parse the CSV and populate the table
    while (my $row = $csv->getline($fh)) {
        $table->addRow(@$row);
    }

    close $fh;

    # Set table headers (optional, if your CSV has headers)
    #$table->setHead('Column 1', 'Column 2', 'Column 3');

    # Set table attributes (optional)
    $table->setAttr('border="1" cellpadding="5"');

    # Generate and print the HTML
    return $table->getTable;

}

1;