
use strict;
use warnings;

use Test::More tests => 11;                      # last test to print

use Test::Pod::Snippets;

my $tps = Test::Pod::Snippets->new( );

ok  $tps->is_extracting_verbatim,   'default: getting verbatim bits';
ok !$tps->is_extracting_methods,    'default: not getting methods';
ok !$tps->is_extracting_functions,  'default: not getting functions';

my $pod = <<'END_POD';
=head1 NAME

Foo - Make your programs footastic

=head1 SYNOPSIS

    ONE

=head1 METHODS

=head2 TWO

=head2 THREE

Do stuff, for example:

    FOUR

=head1 FUNCTIONS

=head2 FIVE

yada yada

END_POD

my $snippets = $tps->extract_snippets( $pod );

like    $snippets => qr/ONE/, 'catching verbatim stuff';
like    $snippets => qr/FOUR/; 
unlike  $snippets => qr/TWO|THREE|FIVE/, '..and nothing else';

$tps->extracts_verbatim( 0 );
$tps->extracts_methods( 1 );

$snippets = $tps->extract_snippets( $pod );

like    $snippets => qr/TWO/, 'catching method bits';
like    $snippets => qr/THREE/;
unlike  $snippets => qr/ONE|FOUR|FIVE/, '... and nothing else';

$tps->extracts_methods( 0 );
$tps->extracts_functions( 1 );

$snippets = $tps->extract_snippets( $pod );

like    $snippets => qr/FIVE/, 'catching function bits';
unlike  $snippets => qr/ONE|TWO|THREE|FOUR/, '... and nothing else';
