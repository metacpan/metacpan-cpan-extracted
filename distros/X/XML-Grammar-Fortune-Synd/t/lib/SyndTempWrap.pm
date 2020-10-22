package SyndTempWrap;

use strict;
use warnings;

use base 'Exporter';

use vars qw($temp_dir);

our @EXPORT_OK = qw($temp_dir cur_fn fn yaml_fn atom_fn rss_fn common_fns dir);

sub dir
{
    my $fn = shift;
    return File::Spec->catdir( File::Spec->curdir(), ( split m!/!, $fn ), );
}

sub cur_fn
{
    my $fn = shift;
    return File::Spec->catfile( File::Spec->curdir(), ( split m!/!, $fn ), );
}

sub fn
{
    return File::Spec->catfile( $temp_dir, shift );
}

sub yaml_fn
{
    return fn('fort.yaml');
}

sub atom_fn
{
    return fn('fort.atom');
}

sub rss_fn
{
    return fn('fort.rss');
}

sub common_fns
{
    return [
        "--yaml-data"   => yaml_fn(),
        "--atom-output" => atom_fn(),
        "--rss-output"  => rss_fn(),
    ];
}

1;
