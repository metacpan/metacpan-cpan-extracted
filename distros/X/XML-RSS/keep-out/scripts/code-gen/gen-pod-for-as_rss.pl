#!/usr/bin/perl

use strict;
use warnings;

my @versions =
(
    { 'f' => "0_9", 'rss' => "0.9", },
    { 'f' => "0_9_1", 'rss' => "0.91", },
    { 'f' => "1_0", 'rss' => "1.0", },
    { 'f' => "2_0", 'rss' => "2.0", },
);

my $pod;
foreach my $v_struct (@versions)
{
    my $f = $v_struct->{f} or die "f not specified";
    my $rss = $v_struct->{rss} or die "rss not specified";

    $pod .= <<"EOF";
=head2 \$rss->as_rss_$f()

B<WARNING>: this function is not an API function and should not be called
directly. It is kept as is for backwards compatibility with legacy code. Use
the following code instead:

    \$rss->{output} = "$rss";
    my \$text = \$rss->as_string();

This function renders the data in the object as an RSS version $rss feed,
and returns the resultant XML as text.

EOF
}

print $pod;
