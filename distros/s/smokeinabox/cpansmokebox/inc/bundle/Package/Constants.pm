package Package::Constants;

use strict;
use vars qw[$VERSION $DEBUG];

$VERSION    = '0.02';
$DEBUG      = 0;

sub list {
    my $class = shift;
    my $pkg   = shift;
    return unless defined $pkg; # some joker might use '0' as a pkg...
    
    _debug("Inspecting package '$pkg'");
    
    my @rv;
    {   no strict 'refs';
        my $stash = $pkg . '::';

        for my $name (sort keys %$stash ) {
        
            _debug( "   Checking stash entry '$name'" );
            
            ### is it a subentry?
            my $sub = $pkg->can( $name );
            next unless defined $sub;
                
            _debug( "       '$name' is a coderef" );
            
            next unless defined prototype($sub) and 
                     not length prototype($sub);

            _debug( "       '$name' is a constant" );
            push @rv, $name;
        }
    }
    
    return sort @rv;
}

sub _debug { warn "@_\n" if $DEBUG; }

1;

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
