#!/usr/bin/perl

use strict;
use warnings;

use autodie;

use Test::More tests => 2;

use File::Temp qw( tempdir );

use XML::RSS;
use File::Spec;

use List::Util qw(first);

use lib './t/lib';

use SyndTempWrap (qw(cur_fn dir $temp_dir common_fns atom_fn rss_fn yaml_fn));

$temp_dir = tempdir( CLEANUP => 1 );

sub _my_copy
{
    my ( $src, $dest ) = @_;

    open my $out_fh, '>', $dest;
    print {$out_fh} _slurp($src);
    close($out_fh);

    return;
}

# We cannot use File::Copy::copy() here because it preserves the file's
# read-only status on some versions of Windows, which makes the file
# unwritable later on, which prevents it from being updated and causes
# the tests to fail.
_my_copy( cur_fn("t/data/fortune-synd-eliminate-old-ids-1/fort.yaml"),
    yaml_fn() );

my @cmd_line = (
    $^X,
    "-MXML::Grammar::Fortune::Synd::App",
    "-e",
    "run()",
    "--",
    "--dir" => dir("t/data/fortune-synd-eliminate-old-ids-1"),
    qw(
        --xml-file irc-conversation-4-several-convos.xml
        --xml-file screenplay-fort-sample-1.xml
        ),
    @{ common_fns() },
    "--master-url" => "http://www.fortunes.tld/My-Fortunes/",
    "--title"      => "My Fortune Feeds",
    "--tagline"    => "My Fortune Feeds",
    "--author"     => "shlomif\@iglu.org.il (Shlomi Fish)",
);

sub print_cmd_line
{
    open my $out_fh, ">", "file.bash";
    print {$out_fh} join( " ", map { qq{"$_"} } @cmd_line );
    close($out_fh);
}

# print_cmd_line();

# TEST
ok( !system(@cmd_line) );

sub _slurp
{
    my $filename = shift;

    open my $in, "<", $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

# TODO : use a YAML parser etc., but I'm lazy.
{
    my $content = _slurp( yaml_fn() );

    my @matches = ( $content =~ m{let-me-wikipedia-it}g );

    # TEST
    is( scalar(@matches), 1, "ID exists only in one place." );
}
