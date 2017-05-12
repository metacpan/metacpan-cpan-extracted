#!/usr/bin/perl

=head1 NAME

 dumpvar - Dumps all context information seen from template namespace

=cut

use YAML qw(Dump);
use Text::ScriptTemplate;

$YAML::UseVersion = 0;

$tmpl = new Text::ScriptTemplate;
$tmpl->pack(q{<%= Dump(%{__PACKAGE__ . "::"}) %>});

*NoWhere::Dump = *Dump;

print "=== default context ===\n", $tmpl->fill;
print "=== nowhere context ===\n", $tmpl->fill(PACKAGE => "NoWhere");

exit(0);
