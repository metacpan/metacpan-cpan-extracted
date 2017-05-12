#!/usr/bin/perl
#
# Trivial example to demonstrate use of the Text::LineEditor module.
# 
# ObLegalStuff:
#    Copyright (c) 1998 Bek Oberin. All rights reserved. This program is
#    free software; you can redistribute it and/or modify it under the
#    same terms as Perl itself.
# 
# Last updated by gossamer on Tue Aug 25 18:53:28 EST 1998
#


use Text::LineEditor;

my $text = line_editor();

print "You entered:\n---\n";
print $text;
print "---\n";


