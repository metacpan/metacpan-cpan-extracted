  # Base class, shouldnt be directly instantiated

{
package Workflow::Aline::Pluggable;

    Class::Maker::class
    {
	public => 
	{
	    string => [qw( id )],
	},
    };    

    sub plug : method
    {
	my $this = shift;
	
	$this->_plug_proximal;
	
	$this->_plug_distal;
    }

    sub _plug_distal : method
    {
	my $this = shift;
	
	if( defined $this->distal )
	{
	    $this->distal->proximal( $this ) if $this->distal->isa( 'Workflow::Aline::Pluggable::OneProximal' );
	    
	    push @{ $this->distal->proximal }, $this if $this->distal->isa( 'Workflow::Aline::Pluggable::ManyProximal' );
	}
    }

    sub _plug_proximal : method
    {
	my $this = shift;
	
	if( defined $this->proximal )
	{
	    $this->proximal->distal( $this ) if $this->proximal->isa( 'Workflow::Aline::Pluggable::OneDistal' );
	    
	    push @{ $this->proximal->distal }, $this if $this->proximal->isa( 'Workflow::Aline::Pluggable::ManyDistal' );
	}
    }
}

{
package Workflow::Aline::Pluggable::OneProximal;

    Class::Maker::class
    {
	isa => [qw(Workflow::Aline::Pluggable)],
	
	public =>
	{
	    ref => [qw( proximal )],
	},
    };
}

{
package Workflow::Aline::Pluggable::ManyProximal;

    Class::Maker::class
    {
	isa => [qw(Workflow::Aline::Pluggable)],
	
	public =>
	{
	    array => [qw( proximal )],
	},
    };
}

{
package Workflow::Aline::Pluggable::OneDistal;

    Class::Maker::class
    {
	isa => [qw(Workflow::Aline::Pluggable)],
	
	public =>
	{
	    ref => [qw( distal )],
	},
    };
}

{
package Workflow::Aline::Pluggable::ManyDistal;

    Class::Maker::class
    {
	isa => [qw(Workflow::Aline::Pluggable)],
	
	public =>
	{
	    array => [qw( distal )],
	},
    };
}

  # Here the composites begin

{
package Workflow::Aline::Pluggable::OneProximalOneDistal;

    Class::Maker::class
    {
	isa => [qw(Workflow::Aline::Pluggable::OneProximal Workflow::Aline::Pluggable::OneDistal)],
    };  
}

{
package Workflow::Aline::Pluggable::OneProximalManyDistal;

    Class::Maker::class
    {
	isa => [qw(Workflow::Aline::Pluggable::OneProximal Workflow::Aline::Pluggable::ManyDistal)],
    };    
}

{
package Workflow::Aline::Pluggable::ManyProximalManyDistal;

    Class::Maker::class
    {
	isa => [qw(Workflow::Aline::Pluggable::ManyProximal Workflow::Aline::Pluggable::ManyDistal)],
    };    
}

{
package Workflow::Aline::Pluggable::ManyProximalOneDistal;

    Class::Maker::class
    {
	isa => [qw(Workflow::Aline::Pluggable::ManyProximal Workflow::Aline::Pluggable::OneDistal)],
    };    
}

1;
