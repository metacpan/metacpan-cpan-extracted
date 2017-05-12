#!perl -w
use strict;
use Text::ClearSilver;

my $tcs = Text::ClearSilver->new;

my %vars = (
    uri => q{<a href="http://example.com">example.com</a>},
);

$tcs->process(\<<'TCS', \%vars);
escape: "none":
<?cs escape: "none" ?><?cs var:uri ?><?cs /escape ?>

escape: "html":
<?cs escape: "html" ?><?cs var:uri ?><?cs /escape ?>

escape: "js":
<?cs escape: "js" ?><?cs var:uri ?><?cs /escape ?>

escape: "url":
<?cs escape: "url" ?><?cs var:uri ?><?cs /escape ?>
TCS
