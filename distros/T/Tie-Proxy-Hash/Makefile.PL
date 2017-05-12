use 5.005_62;
use strict;

use File::Spec::Functions qw( catfile );

use constant MOD_REQS =>
  [
  ];

use constant EXEC_REQS =>
  [
  ];

use constant NAME         => 'Tie-Proxy-Hash';
use constant VERSION_FROM => catfile (qw( lib Tie Proxy Hash.pm ));
use constant AUTHOR       => 'Martyn J. Pearce';
use constant ABSTRACT     => 'Proxy hashes to merge/translate';

use FindBin 1.42 qw( $Bin );
use lib $Bin;
use make;

