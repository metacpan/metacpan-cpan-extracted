#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Value::Monolingual;

# Object.
my $obj = Wikibase::Datatype::Value::Monolingual->new(
        'language' => 'en',
        'value' => 'English text',
);

# Get language.
my $language = $obj->language;

# Get type.
my $type = $obj->type;

# Get value.
my $value = $obj->value;

# Print out.
print "Language: $language\n";
print "Type: $type\n";
print "Value: $value\n";

# Output:
# Language: en
# Type: monolingualtext
# Value: English text