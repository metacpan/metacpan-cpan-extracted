### Configuring Disbatch 4.2

Copyright (c) 2016, 2019 by Ashley Willis.

#### Configure `/etc/disbatch/config.json`
1. Copy `/etc/disbatch/config.json-example` to `/etc/disbatch/config.json`
2. Make sure that only the process running Disbatch can read and edit
   `/etc/disbatch/config.json`
3. Edit `/etc/disbatch/config.json`
   1. Change `mongohost` to the URI of your MongoDB servers
   2. Change `database` to the MongoDB database name you are using for Disbatch
   3. Ensure proper SSL settings in `attributes`, or remove it if not using SSL
   4. Change passwords in `auth` for the respective MongoDB users, or delete
      the field or set its value to `null` if not using MongoDB authentication
   5. Set `plugins` to the name(s) of the plugins you want accessible for queue
      creation
   6. Set `monitoring` to `false` if you want `GET /monitoring` to ignore checks
   7. Set `balance.enabled` to `true` if using QueueBalance
   8. Uncomment values in `web_extensions` if needing to use deprecated routes
   9. Set `activequeues` or `ignorequeues` per DEN if used
   10. Remove the rest, which is optional and configured for development

See also [Configuring and Using SSL with MongoDB](SSL_MongoDB.md) and
[Configuring and Using SSL with the Disbatch Command Interface](SSL_DCI.md).

#### Create MongoDB users for Disbatch if using authentication
- Configure the permissions your plugin needs in
  `/etc/disbatch/plugin-permissions.json`.
- If your MongoDB `root` user has a different name, passs that to `--root_user`.
  If no users exist yet, also pass `--create_root`. See the perldoc for more
  info.

        disbatch-create-users --config /etc/disbatch/config.json --root_user root

See also [Configuring and Using Authentication with MongoDB](Authentication_MongoDB.md).
