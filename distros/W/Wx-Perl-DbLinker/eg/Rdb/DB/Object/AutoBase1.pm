package Rdb::DB::Object::AutoBase1;

use base 'Rose::DB::Object';

use Rdb::DB;

sub init_db { Rdb::DB->new() }

1;
