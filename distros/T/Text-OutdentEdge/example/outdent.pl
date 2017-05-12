#! /usr/bin/perl -w
use strict;
use warnings;
use Text::OutdentEdge qw(outdent);

local($/) = undef;
while(<>)
{
	print outdent $_;
}

