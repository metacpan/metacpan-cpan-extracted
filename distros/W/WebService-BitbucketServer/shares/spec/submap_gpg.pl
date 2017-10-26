# Map endpoints to subroutine names in GPG::V1.
use strict;
{
    'gpg/1.0/keys DELETE' => 'delete_keys',
    'gpg/1.0/keys GET' => 'get_keys',
    'gpg/1.0/keys POST' => 'add_key',
    'gpg/1.0/keys/{fingerprintOrId} DELETE' => 'delete_key',
};
