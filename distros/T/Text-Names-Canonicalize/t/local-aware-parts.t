use strict;
use warnings;
use utf8;
use Test::Most;

use_ok 'Text::Names::Canonicalize';

sub canon {
    Text::Names::Canonicalize::canonicalize_name_struct(
        @_,
        strip_diacritics => 1,
    );
}

# 1. en_GB: no particles → simple surname
{
    my $r = canon("Mary Anne Smith", locale => 'en_GB');
    is_deeply $r->{parts}{surname}, ["smith"], "simple surname";
}

# 2. en_GB: hyphen preserved
{
    my $r = canon("Mary-Anne Smith-Jones", locale => 'en_GB');
    is_deeply $r->{parts}{surname}, ["smith-jones"], "hyphen surname";
}

# 3. en_GB: suffix still works
{
    my $r = canon("John R Smith Jr", locale => 'en_GB');
    is_deeply $r->{parts}{suffix}, ["jr"], "suffix extracted";
}

done_testing;
