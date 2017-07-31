#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 7;
use Text::Amuse::Compile::TemplateOptions;
use Data::Dumper;

is_deeply([ Text::Amuse::Compile::TemplateOptions->serif_fonts ],
          [
                 {
                  name => 'CMU Serif',
                  desc => 'Computer Modern',
                 },
                 {
                  name => 'Linux Libertine O',
                  desc => 'Linux Libertine'
                 },
                 {
                  name => 'TeX Gyre Termes',
                  desc => 'TeX Gyre Termes (Times)',
                 },
                 {
                  name => 'TeX Gyre Pagella',
                  desc => 'TeX Gyre Pagella (Palatino)',
                 },
                 {
                  name => 'TeX Gyre Schola',
                  desc => 'TeX Gyre Schola (Century)',
                 },
                 {
                  name => 'TeX Gyre Bonum',
                  desc => 'TeX Gyre Bonum (Bookman)',
                 },
                 {
                  name => 'Antykwa Poltawskiego',
                  desc => 'Antykwa Półtawskiego',
                 },
                 {
                  name => 'Antykwa Torunska',
                  desc => 'Antykwa Toruńska',
                 },
                 {
                  name => 'Charis SIL',
                  desc => 'Charis SIL (Bitstream Charter)',
                 },
                 {
                  name => 'PT Serif',
                  desc => 'Paratype (cyrillic)',
                 },
                 {
                  name => 'Noto Serif',
                  desc => 'Noto Serif',
                 },
                 {
                  name => 'Gentium Book Basic',
                  desc => 'Gentium',
                 },
                 {
                  name => 'Cormorant Garamond',
                  desc => 'Garamond',
                 },
           ]);
is_deeply([ Text::Amuse::Compile::TemplateOptions->mono_fonts ],
          [
                 {
                  name => 'CMU Typewriter Text',
                  desc => 'Computer Modern Typewriter Text',
                 },
                 {
                  name => 'DejaVu Sans Mono',
                  desc => 'DejaVu Sans Mono',
                 },
                 {
                  name => 'TeX Gyre Cursor',
                  desc => 'TeX Gyre Cursor (Courier)',
                 }
          ]);

is_deeply([ Text::Amuse::Compile::TemplateOptions->sans_fonts ],
          [
                 {
                  name => 'CMU Sans Serif',
                  desc => 'Computer Modern Sans Serif',
                 },
                 {
                  name => 'TeX Gyre Heros',
                  desc => 'TeX Gyre Heros (Helvetica)',
                 },
                 {
                  name => 'TeX Gyre Adventor',
                  desc => 'TeX Gyre Adventor (Avant Garde Gothic)',
                 },
                 {
                  name => 'Iwona',
                  desc => 'Iwona',
                 },
                 {
                  name => 'DejaVu Sans',
                  desc => 'DejaVu Sans',
                 },
                 {
                  name => 'PT Sans',
                  desc => 'PT Sans (cyrillic)',
                 },
                 {
                  name => 'Noto Sans',
                  desc => 'Noto Sans',
                 },
           ]);

is_deeply([ Text::Amuse::Compile::TemplateOptions->all_fonts ],
          [
                 {
                  name => 'CMU Serif',
                  desc => 'Computer Modern',
                 },
                 {
                  name => 'Linux Libertine O',
                  desc => 'Linux Libertine'
                 },
                 {
                  name => 'TeX Gyre Termes',
                  desc => 'TeX Gyre Termes (Times)',
                 },
                 {
                  name => 'TeX Gyre Pagella',
                  desc => 'TeX Gyre Pagella (Palatino)',
                 },
                 {
                  name => 'TeX Gyre Schola',
                  desc => 'TeX Gyre Schola (Century)',
                 },
                 {
                  name => 'TeX Gyre Bonum',
                  desc => 'TeX Gyre Bonum (Bookman)',
                 },
                 {
                  name => 'Antykwa Poltawskiego',
                  desc => 'Antykwa Półtawskiego',
                 },
                 {
                  name => 'Antykwa Torunska',
                  desc => 'Antykwa Toruńska',
                 },
                 {
                  name => 'Charis SIL',
                  desc => 'Charis SIL (Bitstream Charter)',
                 },
                 {
                  name => 'PT Serif',
                  desc => 'Paratype (cyrillic)',
                 },
                 {
                  name => 'Noto Serif',
                  desc => 'Noto Serif',
                 },
                 {
                  name => 'Gentium Book Basic',
                  desc => 'Gentium',
                 },
                 {
                  name => 'Cormorant Garamond',
                  desc => 'Garamond',
                 },
                 {
                  name => 'CMU Sans Serif',
                  desc => 'Computer Modern Sans Serif',
                 },
                 {
                  name => 'TeX Gyre Heros',
                  desc => 'TeX Gyre Heros (Helvetica)',
                 },
                 {
                  name => 'TeX Gyre Adventor',
                  desc => 'TeX Gyre Adventor (Avant Garde Gothic)',
                 },
                 {
                  name => 'Iwona',
                  desc => 'Iwona',
                 },
                 {
                  name => 'DejaVu Sans',
                  desc => 'DejaVu Sans',
                 },
                 {
                  name => 'PT Sans',
                  desc => 'PT Sans (cyrillic)',
                 },
                 {
                  name => 'Noto Sans',
                  desc => 'Noto Sans',
                 },
                 {
                  name => 'CMU Typewriter Text',
                  desc => 'Computer Modern Typewriter Text',
                 },
                 {
                  name => 'DejaVu Sans Mono',
                  desc => 'DejaVu Sans Mono',
                 },
                 {
                  name => 'TeX Gyre Cursor',
                  desc => 'TeX Gyre Cursor (Courier)',
                 }
          ]);

is (Text::Amuse::Compile::TemplateOptions->default_mainfont, 'CMU Serif');
is (Text::Amuse::Compile::TemplateOptions->default_monofont, 'CMU Typewriter Text');
is (Text::Amuse::Compile::TemplateOptions->default_sansfont, 'CMU Sans Serif');

