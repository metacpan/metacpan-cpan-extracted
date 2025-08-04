#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Print::Term;
use Wikibase::Datatype::Term;

# Object.
my $obj = Wikibase::Datatype::Term->new(
        'language' => 'en',
        'value' => 'English text',
);

# Print.
print Wikibase::Datatype::Print::Term::print($obj)."\n";

# Output:
# English text (en)