{
package Workflow::Aline::ConveyorBelt::Factory;

  use IO::Extended qw(:all);

  use strict; use warnings;

 Class::Maker::class
 {
     public =>
     {
	 string => [qw( shall_create mixin_classes )],
     },

     private =>
     {
	 string => [qw(can_create)],
     },
 };

  sub _preinit : method 
  { 
      my $this = shift;

      $this->_can_create( 'ConveyorBelt' );
  }


   # ->create( 'Workflow::Aline::ConveyorBelt::Switch', 'Workflow::Aline::Pluggable::OneProximalOneDistal', proximal => $p, distal => $d )

  sub create_new : method
  {
      my $this = shift;
      

      unshift @{ $this->mixin_classes }, "Workflow::Aline::ConveyorBelt::Preliminary";

      diefln "%S cannot create %S, but only %S", __PACKAGE__, $this->shall_create, $this->_can_create() unless $this->shall_create =~ $this->_can_create;
        
      unless( defined Class::Maker::Reflection::reflect( $this->shall_create )->{def} )
      {
	  my $string = join ' ', @{ $this->mixin_classes };
	
	  warnfln "%S creates %S (which isa %s)", __PACKAGE__, $this->shall_create, $string;
  
	  my $shall_create = $this->shall_create;

eval <<END_HERE;

	      package $shall_create;
	      
	      Class::Maker::class( { isa => [qw($string)] } );
END_HERE

	  warn $@ if $@;	  

	  unless( defined Class::Maker::Reflection::reflect( $this->shall_create )->{def} )
	  {
	      diefln "Class::Maker failed to reflect %s", Class::Maker::Reflection::reflect( $this->shall_create );
	  }
      }
      else
      {
	  if( $Workflow::Aline::DEBUG->{basic} )
	  {
	      warnfln "%S will not create %S again, because it already exists", __PACKAGE__, $this->shall_create ;
	  }
      }

      warnfln " create %s with new and args: %s", $this->shall_create, scalar @_ ? join( ', ', @_ ) : '<no args>' ;

      return $this->shall_create->new( @_ );
  }
}

{
package Workflow::Aline::ConveyorBelt::Preliminary;

    use IO::Extended qw(:all);

    use strict;

    Class::Maker::class
    {
	isa => [qw(Workflow::Aline::Pluggable)],

	public => 
	{
	    ref => [qw( master source_dir target_dir )],
	    
	    array => [qw( robots )],
	},
	
	private => 
	{
	    ref => [qw( cursor )],
	},
    };    

    sub _postinit : method
    {
	my $this = shift;
    }

    sub run : method
    {
	my $this = shift;

	unless( -e $this->source_dir )
	{
 	    warnfln( __PACKAGE__." source_dir '%s' not found - creating", $this->source_dir );

	    my $ok = $this->source_dir->mkpath;

	    warnfln( __PACKAGE__."$ok created" );

	    unless( $ok )
	    {
		warnfln( __PACKAGE__." source_dir '%s' not creatable", $this->source_dir );

		return;
	    }
	}

        printfln "ConveyorBelt dir '%s': '%s'", $_, $this->$_ for (qw( source_dir target_dir ));

	$this->signal_robots( 'conveyor_belt_start' );

	println "Scanning dirs";

	my @subdirs = map { println; Path::Class::Dir->new( $_ ) } File::Find::Rule->directory->in( $this->source_dir->stringify );

	  # first dir '.' off 

        shift @subdirs;

	println "Scanning dirs";

	indn;

	for( @subdirs )
	{
	      # relative requires absolute path's

	    my $rel_dir = $_->absolute->relative( $this->source_dir->absolute );

	    println my $final_target = $this->target_dir->subdir( $rel_dir )->absolute;
	    indn;

	    foreach ( $this->robots )
	    {
		printfln "robot %s", ref $_ if $Workflow::Aline::DEBUG->{robots};

		last if $_->Class::Listener::signal( 'dir', $this, $final_target );
	    }

	    indb;
	}

	indb;

	printfln "Scanning files in %s", $this->master->source_dir->stringify;

	my @files = map { Path::Class::File->new( $_ ) } File::Find::Rule->file->in( $this->source_dir->stringify );

	indn;
	
	for( @files )
	{
	    my $rel_file = $_->absolute->relative( $this->source_dir->absolute );
	   
	    my $src = $_->absolute;	    
	    
	    my $dst = Path::Class::File->new( $this->target_dir, $rel_file )->absolute;

	    warnfln "File: %s", $src;

	    indn;

	    foreach ( $this->robots )
	    {
		printfln "robot %s", ref $_ if $Workflow::Aline::DEBUG->{robots};

		last if $_->Class::Listener::signal( 'file', $this, $src, $dst );
	    }

	    indb;

	}

	indb;

	$this->signal_robots( 'conveyor_belt_end' );
    }

    sub signal_robots : method
    {
	my $this = shift;

	my $what = shift || die; 

	foreach ( $this->robots )
	{
	    $_->Class::Listener::signal( $what, $this->master, $this );
	}	
    }
}

1;
