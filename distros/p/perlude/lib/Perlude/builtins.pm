package Perlude::builtins;
use Perlude;
use strict;
use warnings;
our $VERSION = '0.0';

my %builtins = (
    abs => [
        qw(
            abs
            chr
            cos
            defined
            exp
            glob
            hex
            int
            lc
            lcfirst
            length
            log
            oct
            ord
            quotemeta
            rand
            ref
            sin
            sqrt
            uc
            ucfirst
            unlink
            )
    ],
    chomp   => [qw( chomp chop )],
    pack    => [qw( pack )],
    pop     => [qw( pop shift )],
    reverse => [qw( readline reverse )],
    splice  => [qw( splice )],
    split   => [qw( split )],
    stat    => [qw( lstat stat )],
    substr  => [qw( substr )],
    unpack  => [qw( unpack )],
);

# the snippets of code for each builtin type
my %code = (
    abs     => [ '$'   => 'return apply { %s } $a[0]' ],
    chomp   => [ '$'   => 'return apply { %s; $_ } $a[0]' ],
    pack    => [ '$$'  => 'return apply { %s $a[0], @$_ } $a[1]' ],
    pop     => [ '$'   => 'return apply { %s @$_ } $a[0]' ],
    reverse => [ '$'   => 'return apply { scalar %s $_ } $a[0]' ],
    splice  => [ '$$$' => << 'CODE' ],
return $a[1]
    ? apply { [ %s @$_, $a[0], $a[1] ] } $a[2]
    : apply { [ %s @$_, $a[0] ] } $a[2];
CODE
    split  => [ '$$'  => 'return apply { [ %s $a[0] ] } $a[1]' ],
    stat   => [ '$'   => 'return apply { [ %s $_ ] } $a[0]' ],
    substr => [ '$$$' => << 'CODE' ],
return $a[1]
    ? apply { %s $_, $a[0], $a[1] } $a[2]
    : apply { %s $_, $a[0] } $a[2];
CODE
    unpack => [ '$$' => 'return apply { [ %s $a[0], $_ ] } $a[1]' ],
);

# generate the functions
for my $type ( keys %code ) {
    my ( $proto, $code ) = @{ $code{$type} };
    my $count = $code =~ s/%s/%s/g;
    for my $builtin ( @{ $builtins{$type} } ) {
        no strict 'refs';
        *{"f::$builtin"}
            = eval sprintf "sub ($proto) { my \@a = \@_; $code }",
            ($builtin) x $count;
        die $@ if $@;
    }
}

# and a nice alias
*f::sub = \&Perlude::enlist;

1;

__END__

