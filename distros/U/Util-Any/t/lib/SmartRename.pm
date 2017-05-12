package SmartRename;

use Util::Any -Base;

our $Utils = {
  -utf8 => [['utf8', '',
             {
              is_utf8   => 'is_utf8',
              upgrade   => 'utf8_upgrade',
              downgrade => 'downgrade',
             }
            ]],
};

1;
