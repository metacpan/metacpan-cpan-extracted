package Yote::YapiServer::File;

use strict;
use warnings;
use base 'Yote::YapiServer::BaseObj';

# Database column definitions
our %cols = (
    url           => 'VARCHAR(512)',
    type          => 'VARCHAR(128)',     # MIME type
    size          => 'INT',
    original_name => 'VARCHAR(255)',
    file_path     => 'VARCHAR(512)',     # server filesystem path
    owner         => '*Yote::YapiServer::User',
    created       => 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
);

# Field visibility rules
our %FIELD_ACCESS = (
    url           => { public => 1 },
    type          => { public => 1 },
    size          => { public => 1 },
    original_name => { owner_only => 1 },
    file_path     => { never => 1 },
    owner         => { owner_only => 1 },
    created       => { public => 1 },
);

# No client-callable methods
our %METHODS = ();

1;

__END__

=head1 NAME

Yote::YapiServer::File - Persisted file upload metadata

=head1 DESCRIPTION

Represents an uploaded file stored on the server. Created automatically
when a method with C<files> access receives an f-prefixed argument.

Files are content-addressed (SHA-256 hash of content as filename) and
stored under C<www/webroot/img/E<lt>2-char-prefixE<gt>/>.

=head1 FIELDS

  url           - web-accessible path (public)
  type          - MIME type (public)
  size          - file size in bytes (public)
  original_name - original upload filename (owner_only)
  file_path     - server filesystem path (never sent to client)
  owner         - uploading user (owner_only)

=cut
