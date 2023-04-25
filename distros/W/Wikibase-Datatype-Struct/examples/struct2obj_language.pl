#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Language qw(struct2obj);

# Monolingualtext structure.
my $struct_hr = {
        'language' => 'en',
        'value' => 'English text',
};

# Get object.
my $obj = struct2obj($struct_hr);

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