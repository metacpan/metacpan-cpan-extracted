#!/usr/bin/env perl

=head1 NAME

regenerate_apis.pl - Download API specifications and regenerate packages

=head1 SYNOPSIS

    maint/regenerate_apis.pl [VERSION]

=cut

use warnings;
use strict;

use lib 'lib';
use WebService::BitbucketServer;

use Config::INI::Reader;

BEGIN {
    my $dist = Config::INI::Reader->read_file('dist.ini');
    require Test::File::ShareDir;
    Test::File::ShareDir->import(-share => {
        -dist   => $dist->{ShareDir} ? {$dist->{'_'}{name} => $dist->{ShareDir}{dir} || 'share'} : {},
        -module => $dist->{ModuleShareDirs} || {},
    });
}

my $version = shift || 'latest';

WebService::BitbucketServer->write_api_packages(dir => 'lib', version => $version);

