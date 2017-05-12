# Test-PAUSE-ConsistentPermisssions

Checking your PAUSE permissions are consistent for a module.

This is distinct from checking if you have the permission
required to release the module successfully.  This is primarirly
useful for projects with multiple co-maintainers.

This module provides methods for testing permissions manually
with a script, and a testing method.

    pause-check-distro-perms Test::DBIx::Class

For tests,

```
use Test::Most;
use Test::PAUSE::ConsistentPermissions;

all_permissions_consistent 'Test::PAUSE::ConsistentPermissions';
done_testing;

```


## Installation

Note, not currently on CPAN.  This will be how you install it once
it is.

    cpanm Test::PAUSE::ConsistentPermissions

## Development

See CONTRIBUTING.md for details on contributing to the project.

