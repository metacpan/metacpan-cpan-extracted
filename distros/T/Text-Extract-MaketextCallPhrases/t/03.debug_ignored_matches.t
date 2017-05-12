use Test::More tests => 17;

BEGIN {
    use_ok('Text::Extract::MaketextCallPhrases');
}

diag("Testing Text::Extract::MaketextCallPhrases $Text::Extract::MaketextCallPhrases::VERSION");

my %conf;
my $res_a = get_phrases_in_text( _get_guts(), \%conf );

is( @{ $conf{'debug_ignored_matches'} },           2,            'debug_ignored_matches w/out ignore_perlish_* correct number of ignores' );
is( $conf{'debug_ignored_matches'}->[0]->{'type'}, 'function',   'debug_ignored_matches w/out ignore_perlish_* function' );
is( $conf{'debug_ignored_matches'}->[1]->{'type'}, 'assignment', 'debug_ignored_matches w/out ignore_perlish_* c assignment' );

is( @{$res_a},               4,                                        'debug_ignored_matches w/out ignore_perlish_* correct number of matches' );
is( $res_a->[0]->{'type'},   'no_arg',                                 'debug_ignored_matches w/out ignore_perlish_* - matches statement' );
is( $res_a->[1]->{'phrase'}, 'i am commented out',                     'debug_ignored_matches w/out ignore_perlish_* - matches comment' );
is( $res_a->[2]->{'phrase'}, 'immediately after comment line',         'debug_ignored_matches w/out ignore_perlish_* - matches right after comment' );
is( $res_a->[3]->{'phrase'}, 'after comment line w/ preceding string', 'debug_ignored_matches w/out ignore_perlish_* - matches after comment w/ string' );

$conf{'debug_ignored_matches'}    = undef;
$conf{'ignore_perlish_statement'} = 1;
$conf{'ignore_perlish_comments'}  = 1;
my $res_b = get_phrases_in_text( _get_guts(), \%conf );

is( @{ $conf{'debug_ignored_matches'} },           4,            'debug_ignored_matches w/ ignore_perlish_* correct number of ignores' );
is( $conf{'debug_ignored_matches'}->[0]->{'type'}, 'function',   'debug_ignored_matches w/ ignore_perlish_* function' );
is( $conf{'debug_ignored_matches'}->[1]->{'type'}, 'assignment', 'debug_ignored_matches w/ ignore_perlish_* c assignment' );
is( $conf{'debug_ignored_matches'}->[2]->{'type'}, 'statement',  'debug_ignored_matches w/ ignore_perlish_* statement' );
is( $conf{'debug_ignored_matches'}->[3]->{'type'}, 'comment',    'debug_ignored_matches w/ ignore_perlish_* comment' );

is( @{$res_b},               2,                                        'debug_ignored_matches w/out ignore_perlish_* correct number of matches' );
is( $res_b->[0]->{'phrase'}, 'immediately after comment line',         'debug_ignored_matches w/ ignore_perlish_* - matches right after comment' );
is( $res_b->[1]->{'phrase'}, 'after comment line w/ preceding string', 'debug_ignored_matches w/ ignore_perlish_* - matches after comment w/ string' );

sub _get_guts {
    return <<'END_GUTS';
sub ima_maketext {
    
}

*maketext = \&foo;

goto maketext;

# commented maketext('i am commented out')

# comment
maketext('immediately after comment line')

# comment
 maketext('after comment line w/ preceding string')

END_GUTS
}
