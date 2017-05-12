
# $Id: init_args.t 113 2006-08-13 05:42:19Z rmuhle $

use Test::More tests=>4;

package TestInitArgs;
use classes new=>'new',  attrs=>[qw( some )];

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->classes::init_args(@_) if scalar @_;
  return $self;
}
package main;

ok my $init1 = TestInitArgs->new( some=>'thing' ), 'TestInitArgs';
ok my $init2 = TestInitArgs->new({some=>'thing'}), 'TestInitArgs';

is $init1->get_some, 'thing';
is $init2->get_some, 'thing';

#TODO

