#!/usr/bin/perl -w
use strict;

# pre-compile the parser from the grammar
use Parse::RecDescent;

(my $directory = shift) =~ s/Parser\.pm//;

chdir $directory;
open my $fh, '<', 'grammar';
Parse::RecDescent->Precompile(join('', <$fh>), 'Text::FormBuilder::Parser');
