
package Apache::Request::Controller::[% TABLE.moduleName %];

use strict;
#use Exception qw(:all);
use Apache::Const qw(:common :methods :http);
use Carp qw(cluck confess);

use Apache::Request::Controller;
our @ISA = (qw(Apache::Request::Controller));

sub __index
{
    return 'list';
}

sub __openTable
{
    my $self = shift;
    return DB::Table::[% TABLE.moduleName %]->open($self->{'dbh'});
}

1;

