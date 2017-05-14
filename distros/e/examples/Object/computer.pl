package StoreItem;

my $_sales_tax = 8.5;  # 8.5% added to all components's post rebate price

sub new {
    my ($pkg, $name, $price, $rebate) = @_;
    bless {
        _name => $name, _price => $price, _rebate => $rebate
    }, $pkg;
}

# Accessor functions
sub sales_tax {shift; @_ ? $_sales_tax = shift : $_sales_tax};

sub name {my $obj = shift; @_ ? $obj->{_name} = shift : $obj->{_name}};

sub rebate {my $obj = shift; @_ ? $obj->{_rebate} = shift : $obj->{_rebate}};

sub price {my $obj = shift;
              @_ ? $obj->{_price} = shift
                 : $obj->{_price} - $obj->rebate
}

sub net_price {
    my $obj = shift;
    return $obj->price * (1 + $obj->sales_tax / 100);
}

1;

#--------------------------------------------------------------------------
package Component;
@ISA = qw(StoreItem);
1;

#--------------------------------------------------------------------------
package Monitor;
@ISA = qw (StoreItem);
# Hard-code prices and rebates for now
sub new { $pkg = shift; $pkg->SUPER::new("Monitor", 400, 15)}
1;

#--------------------------------------------------------------------------
package CDROM;
@ISA = qw (StoreItem);
sub new { $pkg = shift; $pkg->SUPER::new("CDROM", 200, 5)}
1;

#--------------------------------------------------------------------------
package Computer;
@ISA = qw (StoreItem);

sub new {
    my $pkg = shift; 
    my $obj = $pkg->SUPER::new("Computer", 0, 0); # Dummy value for price
    $obj->{components} = [];        # list of components
    $obj->components(@_);
    $obj;
}

sub components {
    my $obj = shift;
    @_ ? push (@{$obj->{components}}, @_)
       : @{$obj->{components}};
}

sub price {
    my $obj = shift;
    my $price = 0;
    foreach my $component ($obj->components()) {
        $price += $component->price();
    }
    $price;
}

package main;
$mon   = new Monitor ("Sony Trinitron");
$cdrom = new CDROM ("Seagate SD2200"); 
$comp  = new Computer ($mon, $cdrom);
print $comp->net_price();

