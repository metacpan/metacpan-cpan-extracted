#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Term;

# Object.
my $obj = Wikibase::Datatype::Term->new(
        'language' => 'en',
        'value' => 'English text',
);

# Get language.
my $language = $obj->language;

# Get value.
my $value = $obj->value;

# Print out.
print "Language: $language\n";
print "Value: $value\n";

# Output:
# Language: en
# Value: English text