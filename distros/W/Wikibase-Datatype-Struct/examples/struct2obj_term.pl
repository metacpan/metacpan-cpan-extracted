#!/usr/bin/env perl

use strict;
use warnings;

use Wikibase::Datatype::Struct::Term qw(struct2obj);

# Monolingualtext structure.
my $struct_hr = {
        'language' => 'en',
        'value' => 'English text',
};

# Get object.
my $obj = struct2obj($struct_hr);

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