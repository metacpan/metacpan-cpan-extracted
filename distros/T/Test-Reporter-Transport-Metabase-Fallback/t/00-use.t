#!/usr/bin/env perl -w

# $Id: 00-use.t 54 2018-01-25 02:06:01Z stro $

use strict;
use Test::More;
BEGIN { plan tests => 7 }

use Cwd;
use File::Spec;
use Test::Reporter;
use Test::Reporter::Transport::Metabase::Fallback;

my $file = File::Spec->catfile(getcwd(), 't/dot-cpanreporter/pass.CPAN-SQLite-0.211.rpt');
my $reports_dir = File::Spec->catfile(getcwd(), 't/dot-cpanreporter/reports');
ok $Test::Reporter::Transport::Metabase::Fallback::VERSION;

ok my $transport = Test::Reporter::Transport::Metabase::Fallback->new(
    'File'      => $reports_dir,
    'uri'       => 'http://example.com/api/v1/',
    'id_file'   => File::Spec->catfile(getcwd(), 't/dot-cpanreporter/id_file.json'),
);

ok my $tr = Test::Reporter->new(
    'transport' => 'Metabase::Fallback',
    'transport_args' => [
        'uri'     => $transport->{'uri'},
        'id_file' => $transport->{'id_file'},
        'File'    => $transport->{'File'},
    ],
)->read($file);

ok $tr->send();

opendir(my $DIR => $reports_dir);
my @files = sort grep { /\.rpt/ } readdir $DIR;
closedir $DIR;

is scalar @files => 2;
like $files[0] => qr/^pass\.CPAN\-SQLite/;
like $files[1] => qr/^pass\.Dist\-Zilla/;

exit;
