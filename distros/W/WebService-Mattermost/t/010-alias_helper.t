#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Test::Most tests => 3;

use lib "$FindBin::RealBin/../lib";

use WebService::Mattermost::Helper::Alias qw(v4 view util);

is util('Hello'), 'WebService::Mattermost::Util::Hello',              'Util alias helper success';
is v4('Hello'),   'WebService::Mattermost::V4::API::Resource::Hello', 'v4 alias helper success';
is view('Hello'), 'WebService::Mattermost::V4::API::Object::Hello',   'View alias helper success';

__END__

=head1 NAME

t/010-alias_helper.t

=head1 DESCRIPTION

Check aliases exported by WebService::Mattermost::Helper::Alias build correctly.

=head1 AUTHOR

Mike Jones L<email:mike@netsplit.org.uk>

