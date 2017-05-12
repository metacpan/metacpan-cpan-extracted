use strict;
use warnings;

use Test::More 'no_plan';

# use the recorded package via the controller.
BEGIN {
    use Test::Mimic {
        'key' => sub {'order'},
        'packages' => {
            'RecordMe' => {},
        },
    };
}

my $dummy;
my @dummy;
my %dummy;

my @calls;

# Access some constants.

$dummy = RecordMe::PI;
is( $dummy, 3, 'scalar constant works' );

# Access and manipulate package variables.

$dummy = $RecordMe::scalar_state;# = 47; # Tests FETCH
is( $dummy, 47 );
$dummy = $RecordMe::scalar_state;# = "A string";
is( $dummy, 'A string' );

#@RecordMe::array_state = (1, 2, 3);
ok( exists( $RecordMe::array_state[0] ) );    # Tests EXISTS
ok( ! exists( $RecordMe::array_state[17] ) );
$dummy = @RecordMe::array_state;        # Tests FETCHSIZE
is( $dummy, 3 );

my @check_against = (1, 2, 3);
for my $val (@RecordMe::array_state) {
    $dummy = $val;                      # Tests FETCH
    is( $dummy, shift(@check_against) );
};

#@RecordMe::array_state = ('a', 'b', 'c');
@dummy = @RecordMe::array_state; # Tests FETCH and FETCHSIZE (?)

@check_against = ('a', 'b', 'c');
for my $val ( @dummy ) {
    is( $val, shift(@check_against) );
}


#%RecordMe::hash_state = (
#    'circle'    => 'sphere',
#    'square'    => 'cube',
#    'cube'      => 'hypercube',
#);

my %check_against = (
    'circle'    => 'sphere',
    'square'    => 'cube',
    'cube'      => 'hypercube',
);
for my $key ( keys %RecordMe::hash_state ) {    # Tests FIRSTKEY and NEXTKEY
    $dummy = $RecordMe::hash_state{$key};       # Tests FETCH
    is( $dummy, $check_against{$key} );
}

ok( exists( $RecordMe::hash_state{'circle'} ) );      # Tests EXISTS
ok( ! exists( $RecordMe::hash_state{'line'} ) );
is( scalar( %RecordMe::hash_state ), '3/8' );           # Tests SCALAR

#%RecordMe::hash_state = (
#    'sky'   => 'grey',
#    'water' => 'green',
#    'grass' => 'yellow',
#);       
%dummy = %RecordMe::hash_state; # Tests FIRSTKEY, NEXTKEY and FETCH (?)

%check_against = (
    'sky'   => 'grey',
    'water' => 'green',
    'grass' => 'yellow',
);
for my $key ( keys %dummy ) {
    is( $dummy{$key}, $check_against{$key} );
}

# Call a few subroutines.

# Void context
RecordMe::pos_or_neg(0);
RecordMe::pos_or_neg(-17);
RecordMe::pos_or_neg(17);

# Scalar context
$dummy = RecordMe::pos_or_neg(5);
is( $dummy, 'positive' );
$dummy = RecordMe::pos_or_neg(0);
is( $dummy, 'zero' );
$dummy = RecordMe::pos_or_neg(-4);
is( $dummy, 'negative' );

# List context
@dummy = RecordMe::pos_or_neg(12);
is( $dummy[0], 'positive' );

# Tests exception handling
$dummy = RecordMe::throw(0);            # Doesn't die.
is( $dummy, 'alive and well' );
ok( ! eval { $dummy = RecordMe::throw(1); 1; } );  # Does.

# Objects and Methods

my $obj = RecordMe->new();

$obj->put( 'hello', 'bill' );
$obj->put( 'bye', 'jane' );
$dummy = $obj->get('hello'); # Access data via method calls.
is( $dummy, 'bill' );
$dummy = $obj->get('bye');
is( $dummy, 'jane' );

my $obj2 = RecordMe->new();

$obj2->put( 'apple', 'red' );
$obj2->put( 'banana', 'yellow' );
$obj2->put( 'orange', 'orange' );
$obj2->put( undef, 'ugly' );

%check_against = (
    'apple'     => 'red',
    'banana'    => 'yellow',
    'orange'    => 'orange',
    ''          => 'ugly',
);
for my $key ( keys %{$obj2} ) { # Access data directly.
    $dummy =  $obj2->{$key};
    is( $dummy, $check_against{$key} );
}

# Inherited method
$dummy = RecordMe->mom('Does this return mom?');
is( $dummy, 'mom' );
$dummy = RecordMe->grandma('Does this return grandma?'); 
is( $dummy, 'grandma' );

# Watching a nested structure.

my $obj3 = RecordMe->new();
my $ref = {};

$obj3->put( 'nothing particularly exciting', 0 );
$obj3->put( 'a hash!', $ref );

#$ref->{'Beer'} = 'Reel Big Fish'; #Song name => band name, just for fun :)
#$ref->{'Spiderwebs'} = 'No Doubt';
#$ref->{'Ojos Sexys'} = 'Laurel Aitken';
#$ref->{'Gangsters'} = 'The Specials';

%check_against = (
    'Beer'          => 'Reel Big Fish',
    'Spiderwebs'    => 'No Doubt',
    'Ojos Sexys'    => 'Laurel Aitken',
    'Gangsters'     => 'The Specials',
);
for my $key ( keys %{$ref} ) {
    $dummy = $ref->{$key};
    is( $dummy, $check_against{$key} );
}

#$ref->{'Beer'} = 'Mustard Plug';
$dummy = $ref->{'Beer'};
is( $dummy, 'Mustard Plug' );

# Watching a circular structure.

my $cur = my $front = [ 2, [] ];    # The default hash key generator is just smart enough
                                    # to recognize that merely [] was not passed to put.
#for my $i ( 1 .. 20 ) {
#    $dummy = $cur->[0] = 2 * $i;
#    $cur = $cur->[1] = [];
#}

#$cur->[0] = 'again!';
#$cur->[1] = $front;

$obj3->put( 'a circular linked list', $front ); # We don't watch random lexical variables, so pass it.

# Access the elements.
@check_against = map {2 * $_} 1 .. 20;
$cur = $front;
while ( $cur->[1] != $front ) {
    $dummy = $cur->[0];
    is( $dummy, shift(@check_against) );
    $cur = $cur->[1];
}
