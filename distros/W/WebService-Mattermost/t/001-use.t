#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::Most tests => 2;

use_ok 'WebService::Mattermost';
use_ok 'WebService::Mattermost::V4::Client';
__END__

=head1 NAME

t/001-use.t

=head1 DESCRIPTION

Check some important files import properly.

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

