#!/usr/bin/env perl
use Text::Summarizer;

my $summarizer = Text::Summarizer->new;

$summarizer->scan_all;
$summarizer->summarize_all;