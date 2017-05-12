#!/usr/bin/perl
# issues2excel.pl     yamamoto@nulab.co.jp     2007/11/16 03:59:04

use strict;
use warnings;

use Carp;
use Getopt::Long qw(:config no_ignore_case bundling);
use WebService::Backlog;

our $VERSION = $WebService::Backlog::VERSION;

my $projectId = undef;
my $out       = "";

sub export {
    my $projectId = shift or croak('Please specify projectId!');
    print "Exporting your issues on project[" . $projectId . "]...\n";
    my $backlog = WebService::Backlog->new();
}

=head1 NAME

issues2excel.pl

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 AUTHOR

Ryuzo Yamamoto, E <lt> yamamoto @ptahE < gt >

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by YAMAMOTO Ryuzo

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
