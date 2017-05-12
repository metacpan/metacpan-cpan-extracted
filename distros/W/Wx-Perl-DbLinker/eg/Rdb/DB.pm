package Rdb::DB;
use Rose::DB;
# use base 'Rose::DB';
use strict;
use warnings;

our @ISA = qw(Rose::DB);

__PACKAGE__->use_private_registry;
__PACKAGE__->default_domain('main');
__PACKAGE__->default_type('main');



__PACKAGE__->register_db(
	domain => 'main',
	type => Rdb::DB->default_type,
      driver   => 'sqlite',
      database => './data/ex1',
      connect_options => {  
	      RaiseError => 0,
      	      AutoCommit => 1,
		}
     );



1;
