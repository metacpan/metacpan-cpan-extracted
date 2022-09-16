use strict;
use warnings;
use v5.18;      # minimum needed for Object::Pad

use FindBin;
use lib $FindBin::Bin . '/../lib';

use Test::More tests => 7;
use Capture::Tiny       qw( capture );
use Module::Load::Conditional qw(check_install);

use Weather::GHCN::App::Fetch;

my $config_file = $FindBin::Bin . '/ghcn_fetch.yaml';

die if not -r $config_file;

my @args = (
        '-country',     'US',
        '-state',       'NY',
        '-location',    'New York',
        '-active',      '1900-1910',
        '-report',      '',
        '-nonetwork',   1,
        '-config',      $config_file,
);

my ($stdout, $stderr) = capture {   
    Weather::GHCN::App::Fetch->run( \@args );
};

my @result = split "\n", $stdout;

my $hdr;
my $matches;
foreach my $r (@result) {
    next unless $r;
    $hdr++      if $r =~ m{ \A StationId \t Country }xms;
    $matches++  if $r =~ m{ NEW \s YORK }xms;
    last if $r =~ m{ \A Options: }xms;
}

is $hdr, 1, 'Weather::GHCN::App::Fetch returned a header';
is $matches, 11, 'Weather::GHCN::App::Fetch returned 9 entries for NEW YORK';

# for test coverage

is Weather::GHCN::App::Fetch::deabbrev_report_type('da'), 'daily', 'deabbrev_report_type';

local @ARGV = qw(-report id);

my $opt_href = Weather::GHCN::App::Fetch::get_user_options_no_tk;
is $opt_href->{'report'}, 'id', 'get_user_options_no_tk';

@ARGV = qw(-report id);

if ( check_install(module=>'Tk') and check_install(module=>'Tk::Getopt')) {
    $opt_href = Weather::GHCN::App::Fetch::get_user_options_tk;
    is $opt_href->{'report'}, 'id', 'get_user_options_tk';   
} else {
    ok 1, 'Tk or Tk::Getopt not installed';
}

my @opttable = ( Weather::GHCN::Options->get_tk_options_table() );

@opttable = ( Weather::GHCN::Options->get_tk_options_table() );
ok Weather::GHCN::App::Fetch::valid_report_type('id', \@opttable),   'valid_report_type - id valid';
ok !Weather::GHCN::App::Fetch::valid_report_type('xxx', \@opttable), 'valid_report_type - xxx invalid';