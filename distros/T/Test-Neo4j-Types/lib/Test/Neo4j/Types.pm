use v5.10;
use strict;
use warnings;

package Test::Neo4j::Types;
# ABSTRACT: Tools for testing Neo4j type modules
$Test::Neo4j::Types::VERSION = '0.02';

use Test::More 0.94;
use Test::Exception;
use Test::Warnings qw(warnings :no_end_test);

use Exporter 'import';
BEGIN { our @EXPORT = qw(
	neo4j_node_ok
	neo4j_relationship_ok
	neo4j_path_ok
	neo4j_point_ok
	neo4j_datetime_ok
)}

{
	# This happens within new versions of Neo4j/Types.pm,
	# but we can't be sure the version is new enough:
	package # local
	        Neo4j::Types;
	use warnings::register;
}


sub _element_id_test {
	my ($BOTH, $ID_ONLY, $new, $class, $prefix) = @_;
	
	subtest "${prefix}element_id", sub {
		plan tests => 6;
		
		my $both = $new->($class, {%$BOTH});
		my $id_only = $new->($class, {%$ID_ONLY});
		lives_ok { $both->element_id } 'optional op element_id' if   $both->can('element_id');
		dies_ok  { $both->element_id } 'optional op element_id' if ! $both->can('element_id');
		SKIP: {
			skip 'optional op element_id unimplemented', 2+3 unless $class->can('element_id');
			no strict 'refs';
			my ($element_id, $id) = map { "$prefix$_" } qw( element_id id );
			
			# When both IDs are present, id() MAY warn
			is $both->$element_id(), $BOTH->{$element_id}, "$element_id";
			warnings { is $both->$id(), $BOTH->{$id}, "legacy $id" };
			
			# For a missing element ID, element_id() returns the numeric ID and MUST warn
			my @w_eid = warnings { is $id_only->$element_id(), $ID_ONLY->{$id}, "no $element_id with legacy $id" };
			ok @w_eid, "no $element_id warns";
			warn @w_eid if @w_eid > 1;
			no warnings 'Neo4j::Types';
			is warnings { $id_only->$element_id() }, @w_eid - 1, "no $element_id warn cat is Neo4j::Types";
		};
	};
}


sub _node_test {
	my ($node_class, $new) = @_;
	
	plan tests => 12 + 5 + 7 + 1 + 1;
	
	my ($n, @l, $p);
	
	$n = $new->($node_class, my $id_only = {
		id => 42,
		labels => ['Foo', 'Bar'],
		properties => { foofoo => 11, barbar => 22, '123' => [1, 2, 3] },
	});
	is $n->id(), 42, 'id';
	@l = $n->labels;
	is scalar(@l), 2, 'label count';
	is $l[0], 'Foo', 'label Foo';
	is $l[1], 'Bar', 'label Bar';
	lives_and { is scalar($n->labels), 2 } 'scalar context';
	is $n->get('foofoo'), 11, 'get foofoo';
	is $n->get('barbar'), 22, 'get barbar';
	is_deeply $n->get('123'), [1, 2, 3], 'get 123';
	$p = $n->properties;
	is ref($p), 'HASH', 'props ref';
	is $p->{foofoo}, 11, 'props foofoo';
	is $p->{barbar}, 22, 'props barbar';
	is_deeply $p->{123}, [1, 2, 3], 'props 123';
	
	$n = $new->($node_class, {
		id => 0,
		properties => { '0' => [] },
	});
	is $n->id(), 0, 'id 0';
	is ref($n->get('0')), 'ARRAY', 'get 0 ref';
	is scalar(@{$n->get('0')}), 0, 'get 0 empty';
	$p = $n->properties;
	is_deeply $p, {0=>[]}, 'props deeply';
	is_deeply [$n->properties], [{0=>[]}], 'props list context';
	
	$n = $new->($node_class, { });
	ok ! defined($n->id), 'id gigo';
	@l = $n->labels;
	is scalar(@l), 0, 'no labels';
	lives_and { is scalar($n->labels), 0 } 'scalar context no labels';
	$p = $n->properties;
	is ref($p), 'HASH', 'empty props ref';
	is scalar(keys %$p), 0, 'empty props empty';
	is_deeply [$n->get('whatever')], [undef], 'prop undef';
	ok ! exists $n->properties->{whatever}, 'prop remains non-existent';
	
	# element ID
	my $both = { element_id => 'e17', id => 17 };
	_element_id_test($both, $id_only, $new, $node_class, '');
	
	ok $n->DOES('Neo4j::Types::Node'), 'does role';
}


sub neo4j_node_ok {
	my ($class, $new, $name) = @_;
	$name //= "neo4j_node_ok '$class'";
	subtest $name, sub { _node_test($class, $new) };
}


sub _relationship_test {
	my ($rel_class, $new) = @_;
	
	plan tests => 11 + 5 + 8 + 3 + 1;
	
	my ($r, $p);
	
	$r = $new->($rel_class, my $id_only = {
		id => 55,
		type => 'TEST',
		start_id => 34,
		end_id => 89,
		properties => { foo => 144, bar => 233, '358' => [3, 5, 8] },
	});
	is $r->id, 55, 'id';
	is $r->type, 'TEST', 'type';
	is $r->start_id, 34, 'start id';
	is $r->end_id, 89, 'end id';
	is $r->get('foo'), 144, 'get foo';
	is $r->get('bar'), 233, 'get bar';
	is_deeply $r->get('358'), [3, 5, 8], 'get 358';
	$p = $r->properties;
	is ref($p), 'HASH', 'props ref';
	is $p->{foo}, 144, 'props foo';
	is $p->{bar}, 233, 'props bar';
	is_deeply $p->{358}, [3, 5, 8], 'props 358';
	
	$r = $new->($rel_class, {
		id => 0,
		properties => { '0' => [] },
	});
	is $r->id(), 0, 'id 0';
	is ref($r->get('0')), 'ARRAY', 'get 0 ref';
	is scalar(@{$r->get('0')}), 0, 'get 0 empty';
	$p = $r->properties;
	is_deeply $p, {0=>[]}, 'props deeply';
	is_deeply [$r->properties], [{0=>[]}], 'props list context';
	
	$r = $new->($rel_class, { });
	ok ! defined($r->id), 'id gigo';
	ok ! defined($r->type), 'no type';
	ok ! defined($r->start_id), 'no start id';
	ok ! defined($r->end_id), 'no end id';
	$p = $r->properties;
	is ref($p), 'HASH', 'empty props ref';
	is scalar(keys %$p), 0, 'empty props empty';
	is_deeply [$r->get('whatever')], [undef], 'prop undef';
	ok ! exists $r->properties->{whatever}, 'prop remains non-existent';
	
	# element ID
	my $both = {
		element_id       => 'e60', id       => 60,
		start_element_id => 'e61', start_id => 61,
		end_element_id   => 'e62', end_id   => 62,
	};
	_element_id_test($both, $id_only, $new, $rel_class, '');
	_element_id_test($both, $id_only, $new, $rel_class, 'start_');
	_element_id_test($both, $id_only, $new, $rel_class, 'end_');
	
	ok $r->DOES('Neo4j::Types::Relationship'), 'does role';
}


sub neo4j_relationship_ok {
	my ($class, $new, $name) = @_;
	$name //= "neo4j_relationship_ok '$class'";
	subtest $name, sub { _relationship_test($class, $new) };
}


sub _path_test {
	my ($path_class, $new) = @_;
	
	plan tests => 3 + 3 + 6 + 6 + 1;
	
	my (@p, $p, @e);
	
	my $new_path = sub {
		my $i = 0;
		map { my $o = $_; bless \$o, 'Test::Neo4j::Types::Path' . ($i++ & 1 ? 'Rel' : 'Node') } @_;
	};
	
	@p = $new_path->( \6, \7, \8 );
	$p = $new->($path_class, \@p);
	@e = $p->elements;
	is_deeply [@e], [@p], 'deeply elements 3';
	@e = $p->nodes;
	is_deeply [@e], [$p[0],$p[2]], 'deeply nodes 2';
	@e = $p->relationships;
	is_deeply [@e], [$p[1]], 'deeply rel 1';
	
	@p = $new_path->( \9 );
	$p = $new->($path_class, \@p);
	@e = $p->elements;
	is_deeply [@e], [@p], 'deeply elements 1';
	@e = $p->nodes;
	is_deeply [@e], [$p[0]], 'deeply nodes 1';
	@e = $p->relationships;
	is_deeply [@e], [], 'deeply rel 0';
	
	@p = $new_path->( \1, \2, \3, \4, \5 );
	$p = $new->($path_class, \@p);
	@e = $p->elements;
	is_deeply [@e], [@p], 'deeply elements 5';
	lives_and { is scalar($p->elements), 5 } 'scalar context elements';
	@e = $p->nodes;
	is_deeply [@e], [$p[0],$p[2],$p[4]], 'deeply nodes 3';
	lives_and { is scalar($p->nodes), 3 } 'scalar context nodes';
	@e = $p->relationships;
	is_deeply [@e], [$p[1],$p[3]], 'deeply rel 2';
	lives_and { is scalar($p->relationships), 2 } 'scalar context relationships';
	
	$p = $new->($path_class, []);
	@e = $p->elements;
	is scalar(@e), 0, 'no elements gigo';
	lives_and { is scalar($p->elements), 0 } 'scalar context no elements';
	@e = $p->nodes;
	is scalar(@e), 0, 'no nodes 0 gigo';
	lives_and { is scalar($p->nodes), 0 } 'scalar context no nodes';
	@e = $p->relationships;
	is scalar(@e), 0, 'no relationships 0 gigo';
	lives_and { is scalar($p->relationships), 0 } 'scalar context no relationships';
	
	ok $p->DOES('Neo4j::Types::Path'), 'does role';
}


sub neo4j_path_ok {
	my ($class, $new, $name) = @_;
	$name //= "neo4j_path_ok '$class'";
	subtest $name, sub { _path_test($class, $new) };
}


sub _point_test {
	my ($point_class) = @_;
	
	plan tests => (9-6)+3 + (9-6)+3+3+3+2 + 6+6+6+6 + 1;
	
	my (@c, $p);
	
	
	# Simple point, location in real world
	@c = ( 2.294, 48.858, 396 );
	$p = $point_class->new( 4979, @c );
	is $p->srid(), 4979, 'eiffel srid';
# 	is $p->X(), 2.294, 'eiffel X';
# 	is $p->Y(), 48.858, 'eiffel Y';
# 	is $p->Z(), 396, 'eiffel Z';
# 	is $p->longitude(), 2.294, 'eiffel lon';
# 	is $p->latitude(), 48.858, 'eiffel lat';
# 	is $p->height(), 396, 'eiffel ellipsoidal height';
	is_deeply [$p->coordinates], [@c], 'eiffel coords';
	is scalar ($p->coordinates), 3, 'scalar context eiffel coords';
	
	@c = ( 2.294, 48.858 );
	$p = $point_class->new( 4326, @c );
	is $p->srid(), 4326, 'eiffel 2d srid';
	is_deeply [$p->coordinates], [@c], 'eiffel 2d coords';
	is scalar ($p->coordinates), 2, 'scalar context eiffel 2d coords';
	
	
	# Other SRSs, location not in real world
	@c = ( 12, 34 );
	$p = $point_class->new( 7203, @c );
	is $p->srid(), 7203, 'plane srid';
# 	is $p->X(), 12, 'plane X';
# 	is $p->Y(), 34, 'plane Y';
# 	ok ! defined $p->Z(), 'plane Z';
# 	is $p->longitude(), 12, 'plane lon';
# 	is $p->latitude(), 34, 'plane lat';
# 	ok ! defined $p->height(), 'plane height';
	is_deeply [$p->coordinates], [@c], 'plane coords';
	is scalar ($p->coordinates), 2, 'scalar context plane coords';
	
	@c = ( 56, 78, 90 );
	$p = $point_class->new( 9157, @c );
	is $p->srid(), 9157, 'space srid';
	is_deeply [$p->coordinates], [@c], 'space coords';
	is scalar ($p->coordinates), 3, 'scalar context space coords';
	
	@c = ( 361, -91 );
	$p = $point_class->new( 4326, @c );
	is $p->srid(), 4326, 'ootw srid';
	is_deeply [$p->coordinates], [@c], 'ootw coords';
	is scalar ($p->coordinates), 2, 'scalar context ootw coords';
	
	@c = ( 'what', 'ever' );
	$p = $point_class->new( '4326', @c );
	is $p->srid(), '4326', 'string srid';
	is_deeply [$p->coordinates], [@c], 'string coords';
	is scalar ($p->coordinates), 2, 'scalar context string coords';
	
	@c = ( undef, 45 );
	$p = $point_class->new( 7203, @c );
	is_deeply [$p->coordinates], [@c], 'undef coord';
	is scalar ($p->coordinates), 2, 'scalar context undef coord';
	
	
	# Failure behaviour for incorrect number of coordinates supplied to the constructor
	@c = ( 42 );
	throws_ok { $point_class->new( 4326, @c ) } qr/\bdimensions\b/i, 'new 4326 X fails';
	throws_ok { $point_class->new( 4979, @c ) } qr/\bdimensions\b/i, 'new 4979 X fails';
	throws_ok { $point_class->new( 7203, @c ) } qr/\bdimensions\b/i, 'new 7203 X fails';
	throws_ok { $point_class->new( 9157, @c ) } qr/\bdimensions\b/i, 'new 9157 X fails';
	throws_ok { $point_class->new( 12345, @c ) } qr/\bUnsupported\b/i, 'new 12345 X fails';
	throws_ok { $point_class->new( undef, @c ) } qr/\bSRID\b/i, 'new undef X fails';
	
	@c = ( 2.294, 48.858 );
	$p = $point_class->new( 4326, @c );
	is_deeply [$p->coordinates], [@c[0..1]], 'new 4326';
	throws_ok { $point_class->new( 4979, @c ) } qr/\bdimensions\b/i, 'new 4979 XY fails';
	$p = $point_class->new( 7203, @c );
	is_deeply [$p->coordinates], [@c[0..1]], 'new 7203';
	throws_ok { $point_class->new( 9157, @c ) } qr/\bdimensions\b/i, 'new 9157 XY fails';
	throws_ok { $point_class->new( 12345, @c ) } qr/\bUnsupported\b/i, 'new 12345 XY fails';
	throws_ok { $point_class->new( undef, @c ) } qr/\bSRID\b/i, 'new undef XY fails';
	
	@c = ( 2.294, 48.858, 396 );
	$p = $point_class->new( 4326, @c );
	is_deeply [$p->coordinates], [@c[0..1]], 'new 4326 Z ignored';
	$p = $point_class->new( 4979, @c );
	is_deeply [$p->coordinates], [@c[0..2]], 'new 4979';
	$p = $point_class->new( 7203, @c );
	is_deeply [$p->coordinates], [@c[0..1]], 'new 7203 Z ignored';
	$p = $point_class->new( 9157, @c );
	is_deeply [$p->coordinates], [@c[0..2]], 'new 9157';
	throws_ok { $point_class->new( 12345, @c ) } qr/\bUnsupported\b/i, 'new 12345 XYZ fails';
	throws_ok { $point_class->new( undef, @c ) } qr/\bSRID\b/i, 'new undef XYZ fails';
	
	@c = ( 2.294, 48.858, 396, 13 );
	$p = $point_class->new( 4326, @c );
	is_deeply [$p->coordinates], [@c[0..1]], 'new 4326 ZM ignored';
	$p = $point_class->new( 4979, @c );
	is_deeply [$p->coordinates], [@c[0..2]], 'new 4979 M ignored';
	$p = $point_class->new( 7203, @c );
	is_deeply [$p->coordinates], [@c[0..1]], 'new 7203 ZM ignored';
	$p = $point_class->new( 9157, @c );
	is_deeply [$p->coordinates], [@c[0..2]], 'new 9157 M ignored';
	throws_ok { $point_class->new( 12345, @c ) } qr/\bUnsupported\b/i, 'new 12345 XYZM fails';
	throws_ok { $point_class->new( undef, @c ) } qr/\bSRID\b/i, 'new undef XYZM fails';
	
	
	ok $p->DOES('Neo4j::Types::Point'), 'does role';
}


sub neo4j_point_ok {
	my ($class, $name) = @_;
	$name //= "neo4j_point_ok '$class'";
	subtest $name, sub { _point_test($class) };
}


sub _datetime_test {
	my ($datetime_class, $new) = @_;
	
	plan tests => 5 * 7 + 1;
	
	my ($dt, $p, $type);
	
	$dt = $new->($datetime_class, $p = {
		days => 18645,  # 2021-01-18
	});
	is $dt->days, $p->{days}, 'date: days';
	is $dt->epoch, 1610928000, 'date: epoch';
	is $dt->nanoseconds, $p->{nanoseconds}, 'date: no nanoseconds';
	is $dt->seconds, $p->{seconds}, 'date: no seconds';
	is $dt->type, 'DATE', 'date: type';
	is $dt->tz_name, $p->{tz_name}, 'date: no tz_name';
	is $dt->tz_offset, $p->{tz_offset}, 'date: no tz_offset';
	
	$type = lc 'LOCAL TIME';
	$dt = $new->($datetime_class, $p = {
		nanoseconds => 1,
		seconds     => 0,
	});
	is $dt->days, $p->{days}, 'local time: no days';
	is $dt->epoch, 0, 'local time: epoch';
	is $dt->nanoseconds, $p->{nanoseconds}, 'local time: nanoseconds';
	is $dt->seconds, $p->{seconds}, 'local time: seconds';
	is $dt->type, 'LOCAL TIME', 'local time: type';
	is $dt->tz_name, $p->{tz_name}, 'local time: no tz_name';
	is $dt->tz_offset, $p->{tz_offset}, 'local time: no tz_offset';
	
	$type = lc 'ZONED TIME';
	$dt = $new->($datetime_class, $p = {  
		nanoseconds => 5e8,     # 0.5 s
		seconds     => 86340,   # 23:59
		tz_offset   => -28800,  # -8 h
	});
	is $dt->days, $p->{days}, 'zoned time: no days';
	is $dt->epoch, 86340, 'zoned time: epoch';
	is $dt->nanoseconds, $p->{nanoseconds}, 'zoned time: nanoseconds';
	is $dt->seconds, $p->{seconds}, 'zoned time: seconds';
	is $dt->type, 'ZONED TIME', 'zoned time: type';
	is $dt->tz_name, $p->{tz_name}, 'zoned time: no tz_name';
	is $dt->tz_offset, $p->{tz_offset}, 'zoned time: tz_offset';
	
	$type = lc 'LOCAL DATETIME';
	$dt = $new->($datetime_class, $p = {
		days        => -1,
		nanoseconds => 999_999_999,
		seconds     => 86399,
	});
	is $dt->days, $p->{days}, 'local datetime: days';
	is $dt->epoch, -1, 'local datetime: epoch';
	is $dt->nanoseconds, $p->{nanoseconds}, 'local datetime: nanoseconds';
	is $dt->seconds, $p->{seconds}, 'local datetime: seconds';
	is $dt->type, 'LOCAL DATETIME', 'local datetime: type';
	is $dt->tz_name, $p->{tz_name}, 'local datetime: no tz_name';
	is $dt->tz_offset, $p->{tz_offset}, 'local datetime: no tz_offset';
	
	$type = lc 'ZONED DATETIME';
	$dt = $new->($datetime_class, $p = {
		days        => 6560,   # 1987-12-18
		nanoseconds => 0,
		seconds     => 72000,  # 20:00 UTC
		tz_name     => 'America/Los_Angeles',
	});
	is $dt->days, $p->{days}, 'zoned datetime: days';
	is $dt->epoch, 566856000, 'zoned datetime: epoch';
	is $dt->nanoseconds, $p->{nanoseconds}, 'zoned datetime: nanoseconds';
	is $dt->seconds, $p->{seconds}, 'zoned datetime: seconds';
	is $dt->type, 'ZONED DATETIME', 'zoned datetime: type';
	is $dt->tz_name, $p->{tz_name}, 'zoned datetime: tz_name';
	is $dt->tz_offset, $p->{tz_offset}, 'zoned datetime: no tz_offset';
	
	ok $dt->DOES('Neo4j::Types::DateTime'), 'does role';
}


sub neo4j_datetime_ok {
	my ($class, $new, $name) = @_;
	$name //= "neo4j_datetime_ok '$class'";
	subtest $name, sub { _datetime_test($class, $new) };
}


package # private
        Test::Neo4j::Types::PathNode;
sub DOES { $_[1] eq 'Neo4j::Types::Node' }


package # private
        Test::Neo4j::Types::PathRel;
sub DOES { $_[1] eq 'Neo4j::Types::Relationship' }


1;
