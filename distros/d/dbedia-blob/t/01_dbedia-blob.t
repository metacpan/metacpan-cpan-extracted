#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use FindBin qw($Bin);
use Path::Class qw(file);
use YAML::Syck qw(Load);

BEGIN {use_ok('dbedia::blob') or die;}

subtest 'basics' => sub {
    my $blob = dbedia::blob->new(
        file     => file($Bin, 't-files', 'site.css'),
        base_uri => 'https://meon.eu/blob/',
    );
    is($blob->file_chksum, '420bab008035354b69e243bea67238e40d04dfb0529a1263162fa954bdb7467a',
        'file_chksum()');
    is($blob->file_path, '42/0b/ab/008035354b69e243bea67238e40d04dfb0529a1263162fa954bdb7467a',
        'file_path()');
    is($blob->file_meta_path,
        '42/0b/ab/008035354b69e243bea67238e40d04dfb0529a1263162fa954bdb7467a.yml',
        'file_meta_path()');
    is( $blob->file_url,
        'https://meon.eu/blob/420bab008035354b69e243bea67238e40d04dfb0529a1263162fa954bdb7467a/site.css',
        'file_url()'
    );
    my %file_meta = (
        filename  => 'site.css',
        mime_type => 'text/css',
        size      => 27,
    );

    eq_or_diff_data($blob->file_meta, \%file_meta, 'file_meta()')
        and eq_or_diff_data(Load($blob->file_meta_yaml), \%file_meta, 'file_meta_yaml()');
};

subtest 'favicon' => sub {
    my $blob = dbedia::blob->new(file => file($Bin, 't-files', 'fi'));
    is($blob->file_chksum, '06a84e0530102d0eed18fb7e68d09e02ab2c50266c6b59c956504a6175987166',
        'file_chksum()');
    is($blob->file_path, '06/a8/4e/0530102d0eed18fb7e68d09e02ab2c50266c6b59c956504a6175987166',
        'file_path()');
    is($blob->file_meta_path,
        '06/a8/4e/0530102d0eed18fb7e68d09e02ab2c50266c6b59c956504a6175987166.yml',
        'file_meta_path()');
    is( $blob->file_url,
        'https://b.dbedia.com/06a84e0530102d0eed18fb7e68d09e02ab2c50266c6b59c956504a6175987166/fi',
        'file_url()'
    );
    my %file_meta = (
        filename  => 'fi',
        mime_type => 'image/png',
        size      => 475,
    );

    eq_or_diff_data($blob->file_meta, \%file_meta, 'file_meta()')
        and eq_or_diff_data(Load($blob->file_meta_yaml), \%file_meta, 'file_meta_yaml()');
};

done_testing;
