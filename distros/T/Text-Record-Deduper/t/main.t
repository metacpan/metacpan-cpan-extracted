# main.t for Text::Record::Deduper

use Test::Simple tests => 6;
use strict;
use Text::Record::Deduper;

my %given_name_aliases =
(
   'Bob'     => 'Robert',
   'Rob'     => 'Robert',
   'Bill'    => 'William'
);

my @pipe_delim_data =
(
    "1|bob|Smith  |Waverley",
    "2|Robert|Smith   |Waverley",
    "3|robert|Smith   |Waverley",
    "4|Rob|Smith|Waverley",
    "5|Bob|O'Brien   |Bronte",
    "6|Bob|O'Brien   |Bronte"
);


my $pipe_delim_deduper = new Text::Record::Deduper;
$pipe_delim_deduper->field_separator("|");
$pipe_delim_deduper->add_key(field_number => 2, ignore_case => 1,ignore_whitespace => 1, alias => \%given_name_aliases) or die;
$pipe_delim_deduper->add_key(field_number => 3, ignore_case => 1,ignore_whitespace => 1) or die;

my ($uniq,$dupe) = $pipe_delim_deduper->dedupe_array(\@pipe_delim_data);

ok
( 
    ( 
        $uniq->[0] eq "2|Robert|Smith   |Waverley" and 
        $uniq->[1] eq "5|Bob|O'Brien   |Bronte"
    ),
    'Multi column delimited data: unique records' 
);

ok
( 
    ( 
        $dupe->[0] eq "1|bob|Smith  |Waverley" and 
        $dupe->[1] eq "3|robert|Smith   |Waverley" and
        $dupe->[2] eq "4|Rob|Smith|Waverley" and
        $dupe->[3] eq "6|Bob|O'Brien   |Bronte"
    ),
    'Multi column delimited data" duplicate records' 
);

my @fixed_width_data =
(
    "1 bob    Smith   Waverley",
    "2 Robert Smith   Waverley",
    "3 robert Smith   Waverley",
    "4 Rob    Smith   Waverley",
    "5 Bob    O'Brien Bronte  ",
    "6 Bob    O'Brien Bronte  "
);

my $fixed_width_deduper = new Text::Record::Deduper;
$fixed_width_deduper->add_key(start_pos => 3, key_length => 6, ignore_case => 1,
    ignore_whitespace => 1, alias => \%given_name_aliases) or die;
$fixed_width_deduper->add_key(start_pos => 10, key_length => 8, ignore_case => 1) or die;
($uniq,$dupe) = $fixed_width_deduper->dedupe_array(\@fixed_width_data);

ok
( 
    ( 
        $uniq->[0] eq "2 Robert Smith   Waverley" and 
        $uniq->[1] eq "5 Bob    O'Brien Bronte  "
    ),
    'Multi column fixed width data: unique records' 
);

ok
( 
    ( 
        $dupe->[0] eq "1 bob    Smith   Waverley" and
        $dupe->[1] eq "3 robert Smith   Waverley" and 
        $dupe->[2] eq "4 Rob    Smith   Waverley" and
        $dupe->[3] eq "6 Bob    O'Brien Bronte  "
    ),
    'Multi column fixed width data: duplicate records'
);


my @fixed_width_single_column_data =
(
    "Rob    Smith   Waverley",
    "Bob    O'Brien Bronte  ",
    "Robert Smith   Waverley",
    "Bob    O'Brien Bronte  "
);

my $fixed_width_deduper_no_keys = new Text::Record::Deduper;
($uniq,$dupe) = $fixed_width_deduper->dedupe_array(\@fixed_width_single_column_data);

ok
( 
    ( 
        $uniq->[0] eq "Rob    Smith   Waverley" and
        $uniq->[1] eq "Bob    O'Brien Bronte  " and
        $uniq->[2] eq "Robert Smith   Waverley"
    ),
    'Single column fixed width data: unique records'
);

ok
( 
    ( 
        $dupe->[0] eq "Bob    O'Brien Bronte  "
    ),
    'Single column fixed width data: duplicate records'
);





