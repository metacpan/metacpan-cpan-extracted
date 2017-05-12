use Test::More tests => 16;

BEGIN {
use_ok( 'Text::Twiddler' );
}

diag( "Testing Text::Twiddler $Text::Twiddler::VERSION methods" );

my $twid = Text::Twiddler->new();

my $cust = Text::Twiddler->new({
   'start'     => 'begin madness',
   'text'      => 'too many secrets',
   'end'       => 'stop the insanity',
   'sway'      => 1,
   'output_ns' => 'Text::Twiddler::HTML', 
});
ok($twid->get_uniq_str() =~ m{^Text::Twiddler-\d+$}, 'get_uniq_str');
ok($twid->get_longest() == 11, 'default length calc');
ok($twid->get_output_ns() eq 'Text::Twiddler::CLI', 'default output_ns');
ok($twid->get_start() eq 'Starting...', 'default start');
ok($twid->get_text()  eq 'Working...', 'default text');
ok($twid->get_end()   eq 'Done!', 'default end');
ok($twid->get_start_twiddler() =~ m{Starting\.\.\.}, 'output_ns CLI (fallback)');
is_deeply(
    $twid->get_frames(), 
    [
          'W',
          'Wo',
          'Wor',
          'Work',
          'Worki',
          'Workin',
          'Working',
          'Working.',
          'Working..',
          'Working...',
    ],
    'get_frames() and sway = 0',
);

ok($cust->get_longest() == 17, 'spec args length calc');
ok($cust->get_output_ns() eq 'Text::Twiddler::HTML', 'specified output_ns');
ok($cust->get_start() eq 'begin madness', 'specified start');
ok($cust->get_text()  eq 'too many secrets', 'specified text');
ok($cust->get_end()   eq 'stop the insanity', 'specified end');
ok($cust->get_start_twiddler() =~ m{<div id=".*"></div>}, 'output_ns HTML');
is_deeply(
    $cust->get_frames(), 
    [
        't',
        'to',
        'too',
        'too ',
        'too m',
        'too ma',
        'too man',
        'too many',
        'too many ',
        'too many s',
        'too many se',
        'too many sec',
        'too many secr',
        'too many secre',
        'too many secret',
        'too many secrets',
        'too many secrets',
        'too many secret',
        'too many secre',
        'too many secr',
        'too many sec',
        'too many se',
        'too many s',
        'too many ',
        'too many',
        'too man',
        'too ma',
        'too m',
        'too ',
        'too',
        'to',
        't',
    ],
    'get_frames() and sway = 1',
);