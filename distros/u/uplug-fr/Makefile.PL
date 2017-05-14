use inc::Module::Install;

name          'Uplug';
version       '0.2';
license       'gpl';

abstract    'French language pack for Uplug';
author      'Joerg Tiedemann';
# include     'Module::AutoInstall';

requires              'Uplug'     => 0;
requires_external_bin 'MElt';

# auto_install;
install_share;

WriteAll;
