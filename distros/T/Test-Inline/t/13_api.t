#!/usr/bin/perl

# Formal testing for Test::Inline.
# Tests loading and API of classes.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# Load the class to test
use Test::Inline;

# Execute the API test
use File::Spec::Functions ':ALL';
use Test::More 'tests' => 103;
use Test::ClassAPI;
Test::ClassAPI->execute('complete', 'collisions');

1;

__DATA__

Algorithm::Dependency::Source=interface
Algorithm::Dependency::Item=interface

[Test::Inline]
Algorithm::Dependency::Source=isa
new=method
exception=method
InputHandler=method
ExtractHandler=method
OutputHandler=method
ContentHandler=method
add=method
add_class=method
add_all=method
classes=method
class=method
filenames=method
schedule=method
manifest=method
save=method

[Test::Inline::Section]
Algorithm::Dependency::Item=isa
parse=method
new=method
begin=method
setup=method
example=method
context=method
name=method
after=method
classes=method
tests=method
anonymous=method
content=method

[Test::Inline::Script]
Algorithm::Dependency::Source=isa
Algorithm::Dependency::Item=isa
new=method
class=method
filename=method
config=method
setup=method
sections=method
sorted=method
merged_content=method
tests=method

[Test::Inline::Extract]
new=method
elements=method

[Test::Inline::IO::File]
new=method
path=method
readonly=method
exists_file=method
exists_dir=method
read=method
write=method
class_file=method
find=method

[Test::Inline::Content]
new=method
process=method

[Test::Inline::Content::Legacy]
Test::Inline::Content=isa
coderef=method

[Test::Inline::Content::Default]
Test::Inline::Content=isa

[Test::Inline::Content::Simple]
Test::Inline::Content=isa
template=method

[Algorithm::Dependency::Source]
load=method
item=method
items=method
missing_dependencies=method

[Algorithm::Dependency::Item]
id=method
depends=method
