use strict; use warnings;
package assign::Types;


#------------------------------------------------------------------------------
package var;

sub new {
    my ($class, $var, $def) = @_;
    bless {
        var => $var,
        def => $def,
    }, $class;
}

sub val { $_[0]->{var} }



#------------------------------------------------------------------------------
package skip;

sub new {
    my ($class) = @_;
    my $skip = '_';
    bless \$skip, $class;
}

sub val { ${$_[0]} }



#------------------------------------------------------------------------------
package skip_num;
use overload '""', \&stringify;

sub new {
    my ($class, $num) = @_;
    bless \$num, $class;
}

sub val { ${$_[0]} }

1;
