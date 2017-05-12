#!/usr/bin/perl -w
use strict;
# NO BUFFERING
$| = 1;
my $input = 'ECHO:';
print qq(WXTEST INPUT\n);

while(<STDIN>) {
    $input .= $_;
}

print $input;
exit(0);
1;

