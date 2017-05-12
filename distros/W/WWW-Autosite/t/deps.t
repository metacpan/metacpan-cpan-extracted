use Test::Simple 'no_plan';
use strict;

my @need = qw(
HTML::FromText
File::PathInfo
HTML::Template
YAML
Carp
File::Copy
File::Path
Text::VimColor
Pod::Html
);

for (@need){

	ok( (eval "require $_;" ? 1 : 0 ), "have $_" );

}
