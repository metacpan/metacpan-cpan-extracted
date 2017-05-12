#!perl

#
# tests for field and record compute
#

use strict;
use File::Spec::Functions;
use FindBin qw( $Bin );
use Readonly;
use Test::Exception;
use Test::More tests => 9;
use Text::RecordParser;

Readonly my $TEST_DATA_DIR => catdir( $Bin, 'data' );

{
    my $p = Text::RecordParser->new;
    throws_ok { $p->field_compute( '', 'foo' ) } qr/no usable field/i, 
        'field_compute dies on no field name';
}

{
    my $file          =  catfile( $TEST_DATA_DIR, 'simpsons.csv' );
    my $p             =  Text::RecordParser->new( 
        filename      => $file,
        header_filter => sub { lc shift }, 
        field_filter  => sub { $_ = shift; s/^\s+|\s+$//g; s/"//g; $_ },
    );
    $p->bind_header;

    throws_ok { $p->field_compute( 'dependents', 'foo' ) } qr/not code/i, 
        'field_compute rejects not code';

    $p->field_compute( 'dependents', sub { [ split /,/, shift() ] } );
    $p->field_compute( 'wife', 
        sub { 
            my ( $field, $others ) = @_;
            my $husband =  $others->{'name'} || '';
            $husband    =~ s/^.*?,\s*//;
            return $field.', wife of '.$husband;
        } 
    );

    my $row        = $p->fetchrow_hashref;
    my $dependents = $row->{'dependents'};
    is( scalar @{ $dependents || [] }, 4, 'Four dependents' );
    is( $dependents->[0], 'Bart', 'Firstborn is Bart' );
    is( $dependents->[-1], q[Santa's Little Helper], 
        q[Last is Santa's Little Helper] );
    is( $row->{'wife'}, 'Marge, wife of Homer', 
        q[Marge is still Homer's wife] );
}

{
    my $file = catfile( $TEST_DATA_DIR, 'numbers.csv' );
    my $p    =  Text::RecordParser->new( $file );
    $p->field_compute( 3, 
        sub { 
            my ( $cur, $others ) = @_;
            my $sum; 
            $sum += $_ for @$others;
            return $sum;
        } 
    );
    my $data = $p->fetchall_arrayref;
    my $rec  = $data->[0];
    is( $rec->[-1], 9, 'Sum is 9' );
    $rec     = $data->[1];
    is( $rec->[-1], 37, 'Sum is 37' );
    $rec     = $data->[2];
    is( $rec->[-1], 18, 'Sum is 18' );
}
