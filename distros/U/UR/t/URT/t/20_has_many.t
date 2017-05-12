#!/usr/bin/env perl 

use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;
use Test::More tests => 22;

UR::Object::Type->define(
    class_name => 'Acme',
    is => 'UR::Namespace'
);

UR::Object::Type->define(
    class_name => 'Acme::Order',
    table_name => 'order_',
    id_by => [
        order_id    => { is => 'integer', is_optional => 1, column_name => 'order_id' },
    ],
    has_many => [
        lines           => { is => 'Acme::OrderLine' },
        line_quantities => { via => 'lines', to => 'quantity' },
    ],
);

UR::Object::Type->define(
    class_name => 'Acme::OrderBuddy',
    id_by => [
        order    => { is => 'Acme::Order', id_by => 'order_id', constraint_name => 'order_line' },
        line_num => { is => 'Integer', is_optional => 1, column_name => 'line_num' },
    ],
);

UR::Object::Type->define(
    class_name => 'Acme::OrderLine',
    table_name => 'order_line',
    id_by => [
        order    => { is => 'Acme::Order', id_by => 'order_id', constraint_name => 'order_line' },
        line_num => { is => 'Integer', is_optional => 1, column_name => 'line_num' },
    ],
    has => [
        quantity   => { is => 'Integer', is_optional => 1, column_name => 'quantity' },
        product    => { is => 'String', constraint_name => 'order_line_product' },
    ],
);

my $o = Acme::Order->create(id => 1);
ok($o, "order object created");

my $line1 = Acme::OrderLine->create(order => $o, line_num => 1, quantity => 100, product => "fish");
my $line2 = Acme::OrderLine->create(order => $o, line_num => 2, quantity => 200, product => "fish");
my $line3 = Acme::OrderLine->create(order => $o, line_num => 3, quantity => 300, product => "fish");
my @lines = sort Acme::OrderLine->get(order => $o);
is(scalar(@lines), 3, "created expected list of 3 line items");

ok($o->can("line"), "can do line");
ok($o->can("lines"), "can do lines");
ok($o->can("line_list"), "can do line_list");
ok($o->can("line_arrayref"), "can do line_arrayref");
ok($o->can("add_line"), "can do add_line");
ok($o->can("remove_line"), "can do remove_line");

my @r1 = sort $o->lines();
is_deeply(\@r1,\@lines,"lines() works");

my @q1 = sort $o->line_quantities;
my @q1_expected = sort map { $_->quantity } @lines;
is_deeply(\@q1,\@q1_expected,"indirect method (line_quantities()) returns lists through the lines() acccessor");

my @r2 = sort $o->line_list();
is_deeply(\@r2,\@lines,"line_list() works");

my @r3 = sort @{ $o->line_arrayref() };
is_deeply(\@r3,\@lines,"line_arrayref() works");

my @r4;
eval { @r4 = $o->line(line_num => 1) };
is($r4[0], $line1, "line() works with a simple rule");

my $r5;
eval { $r5 = $o->line(2) };
is($r5, $line2, "line() returns a single selected item");

my $line4 = $o->add_line(line_num => 4, quantity => 400, product => "fish");
ok($line4, "added a line with full additional parameters");
my @r6 = sort { $a->line_num <=> $b->line_num } $o->lines();
is(scalar(@r6),4,"line count is correct");

my $line5 = $o->add_line(5);
ok($line5, "added a line with a partial identity");
my @r7 = sort { $a->line_num <=> $b->line_num } $o->lines();
is(scalar(@r7),5,"line count is correct");
$line5->product('fish');  # Sets the property's value, since it's not is_optional

my $removed = $o->remove_line(3);
ok($removed, "removed a line with a partial identity");
my @r8 = sort map { $_->line_num } $o->lines();
is("@r8","1 2 4 5","line numbers left are correct");

my $removed2 = $o->remove_line(quantity => 400);
ok($removed2, "removed a line with full parameters");
my @r9 = sort map { $_->line_num } $o->lines();
is("@r9","1 2 5","line numbers left are correct");

=cut

# This only works if there is a data source currently,
# since the whole closure logic is inside of UR::DataSource::RDBMS.

ok($o->can("line_iterator"), "can do line_iterator");
my $i = $o->line_iterator;
ok($i, "got an iterator");
my @o4;
if ($i) {
    while (my $next = $i->next) {
        push @o4, $next;
    }
}
is_deeply(\@o4,\@lines,"line_iterator works");

=cut


1;
