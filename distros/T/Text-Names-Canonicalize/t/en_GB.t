use strict;
use warnings;
use utf8;
use Test::Most;

use_ok 'Text::Names::Canonicalize';

sub canon_struct {
    Text::Names::Canonicalize::canonicalize_name_struct(
        @_,
        strip_diacritics => 1,
    );
}

# 1. Title stripping
{
    my $r = canon_struct("Sir Arthur Conan Doyle", locale => 'en_GB');
    is $r->{canonical}, "arthur conan doyle", "title stripped";
    is_deeply $r->{parts}{surname}, ["doyle"], "surname correct";
}

# 2. Suffix handling
{
    my $r = canon_struct("John R Smith Jr", locale => 'en_GB');
    is $r->{canonical}, "john r smith jr", "suffix preserved in canonical";
    is_deeply $r->{parts}{suffix}, ["jr"], "suffix extracted";
}

# 3. Hyphen policy (preserve)
{
    my $r = canon_struct("Mary-Anne Smith-Jones", locale => 'en_GB');
    is $r->{canonical}, "mary-anne smith-jones", "hyphens preserved";
    is_deeply $r->{parts}{surname}, ["smith-jones"], "surname correct";
}

done_testing;
