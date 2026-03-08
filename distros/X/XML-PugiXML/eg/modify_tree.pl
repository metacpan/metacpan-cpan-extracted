#!/usr/bin/env perl
# Navigate, modify, and clone nodes
use strict;
use warnings;
use XML::PugiXML;

my $doc = XML::PugiXML->new;
$doc->load_string(<<'XML') or die $@;
<config>
  <server host="localhost" port="8080"/>
  <server host="backup" port="9090"/>
  <logging level="info"/>
</config>
XML

my $root = $doc->root;

# Navigate children
for my $child ($root->children) {
    printf "%s", $child->name;
    for my $attr ($child->attrs) {
        printf " %s=%s", $attr->name, $attr->value;
    }
    print "\n";
}

# Find by attribute
my $backup = $root->find_child_by_attribute('server', 'host', 'backup');
printf "\nBackup port: %s\n", $backup->attr('port')->value;

# Modify attributes
$backup->set_attr('port', '9091');
$backup->set_attr('ssl', 'true');  # adds new attribute

# Clone a node
my $third = $root->append_copy($backup);
$third->set_attr('host', 'standby');
$third->set_attr('port', '7070');

# Remove a node
my $logging = $root->child('logging');
$root->remove_child($logging);

# Remove an attribute
$third->remove_attr('ssl');

# Insert before
my $first = $root->first_child;
my $lb = $root->insert_child_before('loadbalancer', $first);
$lb->set_attr('algorithm', 'round-robin');

print "\n", $doc->to_string("  ", XML::PugiXML::FORMAT_INDENT()
                                | XML::PugiXML::FORMAT_NO_DECLARATION());
