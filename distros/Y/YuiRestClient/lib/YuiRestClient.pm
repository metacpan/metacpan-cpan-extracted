# SUSE's openQA tests
#
# Copyright © 2021 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved. This file is offered as-is,
# without any warranty.

# Maintainer: QE YaST <qa-sle-yast@suse.de>

package YuiRestClient 0.1;
use strict;
use warnings;

use constant API_VERSION => 'v1';

use YuiRestClient::App;
use YuiRestClient::Wait;

=head1 NAME

YuiRestClient - Perl module to interact with YaST applications via libyui-rest-api.


=head1 DESCRIPTION

See documentation of the L<libyui-rest-api project|https://github.com/libyui/libyui/tree/master/libyui-rest-api/doc>.
for more details about server side implementation.


=head1 VERSION

This document describes L<YuiRestClient> version B<%VERSION%>.


=head1 SYNOPSIS

  use YuiRestClient;
  use constant API_VERSION => 'v1';

  my $app = YuiRestClient::App->new({
          port        => $port,
          host        => $host,
          api_version => API_VERSION
      });
  $app->check_connection();
  my $btn = $app->button({id => 'btn_ok'});
  $btn->click();


=head1 INSTALLATION

To manually install the package run following commands:

  perl Makefile.pl
  make manifest
  male install

To generate tarball, execute C<make dist> command. This command will also
generate README file and update README.pod file.


=head1 LICENSE

The perl module is available as open source under the terms of the L<MIT License|https://opensource.org/licenses/MIT>.

=cut


1;
