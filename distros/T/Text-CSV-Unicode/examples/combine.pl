use strict;
use Text::CSV::Base;

my $csv = Text::CSV::Base->new;

my @data = (
	[qw( Author	Organisation	Count	Comment)],
	[ 'Robin Barker', 'NPL', 1, 'This is a short comment' ],
        [ 'Chris Williams', 'NPL', 0, 'This is a comment with ooo!' ],
        [ 'Mr Sand', 'Justervesenet', -1 ],
        [ 'Walter Raleigh', 'PTB', 100, '"no comment"' ] 
);

local $\ = "\n";
for my $data (@data) {
    $csv->combine(@$data) or die $csv->error_input;
    print $csv->string;
}
