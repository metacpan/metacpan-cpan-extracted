#!perl
#===============================================================================
#
# t/pod_coverage.t
#
# DESCRIPTION
#   Test script to check POD coverage.
#
# COPYRIGHT
#   Copyright (C) 2014, 2015, 2020 Steve Hay.  All rights reserved.
#
# LICENCE
#   This script is free software; you can redistribute it and/or modify it under
#   the same terms as Perl itself, i.e. under the terms of either the GNU
#   General Public License or the Artistic License, as specified in the LICENCE
#   file.
#
#===============================================================================

use 5.008001;

use strict;
use warnings;

use Test::More;

#===============================================================================
# MAIN PROGRAM
#===============================================================================

MAIN: {
    plan skip_all => 'Author testing only' unless $ENV{AUTHOR_TESTING};

    my $ok = eval {
        require Test::Pod::Coverage;
        Test::Pod::Coverage->import();
        1;
    };

    if (not $ok) {
        plan skip_all => 'Test::Pod::Coverage required to test POD coverage';
    }
    elsif ($Test::Pod::Coverage::VERSION < 0.08) {
        plan skip_all => 'Test::Pod::Coverage 0.08 or higher required to test POD coverage';
    }
    elsif (!eval { require Socket }) {
        plan skip_all => 'no Socket';
    }
    elsif (ord('A') == 193 && !eval { require Convert::EBCDIC }) {
        plan skip_all => 'EBCDIC but no Convert::EBCDIC';
    }
    else {
        plan tests => 12;
        my $params = { coverage_class => qw(Pod::Coverage::CountParents) };
        pod_coverage_ok('Net::Cmd', {
            %$params,
            also_private => [qw(toascii toebcdic set_status)]
        });
        pod_coverage_ok('Net::Config', {
            %$params,
            also_private => [qw(is_external)]
        });
        pod_coverage_ok('Net::Domain', $params);
        pod_coverage_ok('Net::FTP',  {
            %$params,
            also_private => [qw(authorise lsl ebcdic byte cmd)]
        });
        pod_coverage_ok('Net::Netrc', $params);
        pod_coverage_ok('Net::NNTP', $params);
        pod_coverage_ok('Net::POP3', $params);
        pod_coverage_ok('Net::SMTP', {
            %$params,
            also_private => [qw(datafh supports)]
        });
        pod_coverage_ok('Net::Time', $params);
        pod_coverage_ok('Net::FTP::A', $params);
        pod_coverage_ok('Net::FTP::dataconn', {
            %$params,
            also_private => [qw(can_read can_write cmd reading)]
        });
        pod_coverage_ok('Net::FTP::I', $params);
    }
}

#===============================================================================
