BEGIN
{
    use Data::Dumper;

    sub UNIVERSAL::dump : method
    {
        return Data::Dumper->Dump( [ shift ] );
    }
}

use Class::Maker qw(:all);

use File::Find::Rule;

use HTML::Mason;

use Path::Class;

use Carp qw(croak);

{
    package Workflow::Aline::Fundamental;
    
    Class::Maker::class
    {
	isa => [qw( Class::Listener )],

	public => 
	{
	    int => [qw( stages current_stage )],
	    
	    bool => [qw( is_testrun is_staging )],

	    array => [qw( stage_history robots )],

	    hash => [qw( stage_callbacks action_callbacks )],
	},
	
	private => 
	{
	    ref => [qw( cursor )],
	},
    };
}

{
    package Workflow::Aline::OnMemory;

use IO::Extended ':all';
    
    Class::Maker::class
    {
	isa => [qw( Workflow::Aline::Fundamental )],

	public => 
	{
	    ref => [qw( input )],
	},
	
	private => 
	{
	},
    };

    sub run : method
    {
	my $this = shift;

	my @robots = @_;


	map { $_->aline( $this ) } @robots;
 
	$this->is_staging = 1;

	println "Entering multistage publishing";

	@{ $this->stage_history } = ();

	for( 0 .. $this->stages )
	{        
	    println "\n";

	    printfln "stage...%d", $_;
	   
	    $this->current_stage( $_ );

	    my $master = $this;

	    my $factory_switches = Workflow::Aline::ConveyorBelt::Factory->new( 
									       shall_create => 'Workflow::Aline::ConveyorBelt::Switch',
									       mixin_classes => [qw(Workflow::Aline::Pluggable::OneProximalOneDistal)] 
									      );

	    my $conveyor_belt = $factory_switches->create_new( 						  
							      #proximal => $line->{$_-1}, distal => $line->{$_+1}
							      
							      robots => \@robots,
							      
							      master => $master, 
							      
							      #source_dir => ( $this->stage_history->[-1] || $this->source_dir ), 
							      
							      #target_dir => $this->sprintf_current_target_dir( $this->current_stage ),
						 
							     );
	   
	    #$conveyor_belt->plug;

	    foreach ( $this->robots )
	    {
		last if $_->Class::Listener::signal( 'pre_session', $this, $conveyor_belt );
	    }

	    $conveyor_belt->run;

	    foreach ( $this->robots )
	    {
		last if $_->Class::Listener::signal( 'post_session', $this );
	    }

	    push @{ $this->stage_history }, $this->sprintf_current_target_dir( $this->current_stage );
	}
	
	println "\nDumping stage history:";

	println for @{ $this->stage_history };

	println "\nStaging to final target";

	$this->is_staging = 0;

	my $factory_ends = Workflow::Aline::ConveyorBelt::Factory->new( 
								       shall_create => 'Workflow::Aline::ConveyorBelt::End',

								       mixin_classes => [qw(Workflow::Aline::Pluggable::OneProximalOneDistal)] 
								      );
	
	# MUENALAN: Missing, comment why this is not plug'ed ?

	$factory_ends->create_new( 
				  robots => \@robots,
				  
				  master => $this, 
				  
				  source_dir => $this->stage_history->[-1], 
				  
				  target_dir => $this->sprintf_current_target_dir 
				  
				 )->run;

	foreach ( $this->robots )
        {
	    last if $_->Class::Listener::signal( 'final', $this );
	}
    }

}

{
package Workflow::Aline;

our $VERSION = '0.04';

our $DEBUG = { basic => 0, robots => 0 };

use strict; 

use warnings;

use IO::Extended ':all';

use Class::Maker qw(:all);

use File::Find::Rule;

use HTML::Mason;

use Path::Class;

use Carp qw(croak);

}

use Workflow::Aline::Manager;
use Workflow::Aline::Robot;
use Workflow::Aline::Pluggable;
use Workflow::Aline::ConveyorBelt;

{
    package Workflow::Aline;
    
    use IO::Extended qw(:all);

    use Data::Iter qw(:all);
    
    use modules qw( File::Spec File::Path File::Basename Carp );
    
    # We load a patched File::Find

    Class::Maker::class
    {
	isa => [qw( Workflow::Aline::Fundamental )],

	public => 
	{
	    ref => [qw( home_dir source_dir target_dir comp_dir temp_dir )],

	    string => [qw( stage_dir_format )],
	},
	
	default =>
	{
	    temp_dir => Path::Class::Dir->new( '_publish' ),

	    stage_dir_format => '_stage%d',

	    current_stage => 0,

	    stages => 1,

	    is_testrun => 0,
	},
    };
    
    our $mason_interp;

    { 
	package HTML::Mason::Commands;
	
	use Data::Iter qw(:all);
	
	use Class::Maker qw(:all);
	
	use IO::Extended qw(:all);
	
	use Data::Dumper;
	
	our $dtq;
    }
    
    sub _postinit : method
    {
	my $this = shift;

	foreach( qw(source_dir target_dir home_dir comp_dir temp_dir) )
	{
	    confess "$this->$_ is not defined" unless defined( $this->$_ );

	    $this->$_( Path::Class::Dir->new( $this->$_ ) ) unless ref( $this->$_ ); #->isa( 'Path::Class::Dir' );
	}  

	foreach ( qw( source_dir target_dir temp_dir ) )
	{
	    $this->$_->cleanup;

	    unless( -e $this->$_ )
	    {
		warnfln "$this->_postinit: Did not find %s ..making dir.", $this->$_;

		$this->$_->mkpath;
	    }  
	}

	warn "Mason (init):";

	indn;

	for( iter { module => $this->comp_dir->stringify, basic => $this->home_dir->stringify } )
	{
	    warnfln "Mason (comp dirs): %s => %s", KEY, VALUE;
	}

	indb;

	$Workflow::Aline::mason_interp = HTML::Mason::Interp->new( 

						       comp_root =>  # like @INC - first gets searched first
						       [ 
							 [ module => $this->comp_dir->stringify ], # ongoing stage?
							 [ basic => $this->home_dir->stringify ], # /basic/*.mas
						       ], 

						       allow_globals => [ '$dtq' ],
									      
                                                       #resolver_class => 'HTML::Mason::Resolver::FileDebug',
						       );

	$this->is_staging( 0 );
    }

  sub new_with_setup : method
  {
    my $this = shift;
    
    our %options = 
      (
       home_dir => Path::Class::Dir->new( '.aline' )->absolute,
       
       project => 'test1',
      );
    
    my %args = @_;

    %options = ( %options, %args );
    
    $options{home_dir} = Path::Class::Dir->new( $options{home_dir} ) unless ref( $options{home_dir} );

    $options{home_dir} = $options{home_dir}->absolute;

    my $aline = Workflow::Aline->new( 
				     
				     source_dir => Path::Class::Dir->new( $options{home_dir}, 'projects', $options{project}, 'files' ), 
				     
				     target_dir => Path::Class::Dir->new( $options{home_dir}, 'projects', $options{project}, 'published' ), 
				     
				     home_dir => $options{home_dir},
				     
				     comp_dir   => Path::Class::Dir->new( $options{home_dir}, 'projects', $options{project} ),
				     
				     temp_dir   => Path::Class::Dir->new( $options{home_dir}, 'projects', $options{project}, '_temp' ),
				     
				     is_testrun => 0,
				     
				     stages => 2,
				     
				     stage_dir_format => Path::Class::Dir->new( 'stage%d' )->stringify,
				     
				     robots => 
				     [ 
				      Workflow::Aline::Robot::Finalize->new( aline => $this ),		    
				     ],
				    );
    
    return $aline;
  }

    sub _on_copy : method
    {
	my $this = shift;


	my $logfile = $this->home_dir->file( 'aline.log' );

	open( LOG, sprintf ">>%s", $logfile ) or die "cant open $logfile";

	printf LOG "$_\n" for @_;

	close( LOG );
    }
 
    sub sprintf_stage_dir : method
    {
	my $this = shift;
	
	my $stage = shift || 0;
	
	return $this->temp_dir->subdir( Path::Class::Dir->new( sprintf( $this->stage_dir_format, $stage ) )  );
    }

    sub sprintf_current_target_dir : method
    {
	my $this = shift;
	
	my $stage = shift;

	if( $this->is_staging )
	{
	    defined $stage or Workflow::Aline::croak "expected argument to sprintf_current_target_dir";

	    my $d = $this->sprintf_stage_dir( $stage );

	    unless( -e $d )
	    {
		warnfln "$this->sprintf_current_target_dir: Did not find %s ..making dir.", $d;
		
		$d->mkpath;
	    }

	    return $d;
        }
	
	return $this->target_dir;
    } 

    sub run : method
    {
	my $this = shift;

	my @robots = @_;


	map { $_->aline( $this ) } @robots;
 
	$this->is_staging = 1;

	println "Entering multistage publishing";

	@{ $this->stage_history } = ();

	for( 0 .. $this->stages )
	{        
	    println "\n";

	    printfln "stage...%d", $_;
	   
	    $this->current_stage( $_ );

#	    print Data::Dumper->Dump( [ $this ] );

	    #println ref($_) for $this->robots;

	    my $master = $this;

	    my $factory_switches = Workflow::Aline::ConveyorBelt::Factory->new( 
									       shall_create => 'Workflow::Aline::ConveyorBelt::Switch',
									       mixin_classes => [qw(Workflow::Aline::Pluggable::OneProximalOneDistal)] 
									      );

	    my $conveyor_belt = $factory_switches->create_new( 						  
							      #proximal => $line->{$_-1}, distal => $line->{$_+1}
							      
							      robots => \@robots,
							      
							      master => $master, 
							      
							      source_dir => ( $this->stage_history->[-1] || $this->source_dir ), 
							      
							      target_dir => $this->sprintf_current_target_dir( $this->current_stage ),
						 
							     );
	   
	    #$conveyor_belt->plug;

	    foreach ( $this->robots )
	    {
		last if $_->Class::Listener::signal( 'pre_session', $this, $conveyor_belt );
	    }

	    $conveyor_belt->run;

	    foreach ( $this->robots )
	    {
		last if $_->Class::Listener::signal( 'post_session', $this );
	    }

	    push @{ $this->stage_history }, $this->sprintf_current_target_dir( $this->current_stage );
	}
	
	println "\nDumping stage history:";

	println for @{ $this->stage_history };

	println "\nStaging to final target";

	$this->is_staging = 0;

	my $factory_ends = Workflow::Aline::ConveyorBelt::Factory->new( 
								       shall_create => 'Workflow::Aline::ConveyorBelt::End',

								       mixin_classes => [qw(Workflow::Aline::Pluggable::OneProximalOneDistal)] 
								      );
	
	# MUENALAN: Missing, comment why this is not plug'ed ?

	$factory_ends->create_new( 
				  robots => \@robots,
				  
				  master => $this, 
				  
				  source_dir => $this->stage_history->[-1], 
				  
				  target_dir => $this->sprintf_current_target_dir 
				  
				 )->run;

	foreach ( $this->robots )
        {
	    last if $_->Class::Listener::signal( 'final', $this );
	}
    }

    sub close : method 
    { 
	my $this = shift;
	
	foreach ( $this->robots )
	{
	    last if $_->Class::Listener::signal( 'close', $this );
	}

	if( -e $this->temp_dir )
	{
	    warnfln "$this->close: Cleaning %s ..deleting files.", $this->temp_dir;
	    
	    $this->temp_dir->rmtree( 1, 1 );
	}

	printfln "\n\nYou can now find your published files in %S\n\n", $this->target_dir;
    }
}

1;
__END__

=head1 NAME

Workflow::Aline - a modular staging framework

=head1 CONCEPT

 File3
      robot1 robot2 robot3

 Dir/File1
      robot1 robot2 robot3

 Dir/File2
      robot1 robot2 robot3

 Stage0:
             R1       R2       R3

   ********
   * File *  =>       =>       =>
   ********
   .=============================.  .===================.
  ( O     ::ConveyorBelt        O )( O  ::ConveyorBelt O )
   `-----------------------------´  `-------------------´

  |--------------------- ::Aline ------------------------|

 Stage1:

  As above, but Stage0 output-files are fed back as input.

=head2 Switches (Vertices)

Multiple conveyor-belts can be arranged as an DAG via the ::ConveyorBelt::Switch
class.                                                                   
                                                                ____
                                                               /
     (CB)----Switch::OneProximalOneDistal----(CB)-Switch::OneProximalTwoDistal
                                                               \____
=head1 SYNOPSIS

 use Workflow::Aline;

 my $manager = Workflow::Aline::Manager->new( home_dir => '.aline' );

   # create a new Workflow::Aline dir (".aline") in the current directory

 $manager->dir_workflow_aline_setup;

   # create a new Workflow from the 'project_skeleton' dir available in the Aline
   # dir (.aline). 

 $manager->dir_project_setup( 'newprj1' );
 $manager->dir_project_setup( 'newprj2' );

   # use newprj2 as a skeleton

 $manager->dir_project_setup( 'newprj3', 'newprj2' );

 for( qw( newprj1 newprj2 newprj3 ) )
 {
    my $aline = Workflow::Aline->new_with_setup( home_dir => '.aline', project => $_ );

       # run implicates already a basic conveyorbuilt setup

    $aline->run( 
		  Workflow::Aline::Robot::Skip->new( when => sub { my ($this, $event, $session, $src) = @_; $src->stringify =~ /~$/i } ),
		  
		  Workflow::Aline::Robot::Skip->new( when => sub { my ($this, $event, $session, $src) = @_; $src->stringify =~ /maslib|cvs/i } ),
		  
		  Workflow::Aline::Robot::Skip->new( when => sub { my ($this, $event, $session, $src) = @_; $src->stringify =~ /tmpl$/ && not $session->master->is_staging } ),
		  
		  Workflow::Aline::Robot::Mkdir->new(),
		  
		  Workflow::Aline::Robot::Copy->new(),
		  
		  Workflow::Aline::Robot::Template->new( detector => sub { $_[1] =~ /\.tmpl$/ } ),
		  
		  Workflow::Aline::Robot::Decorator->new( stage => 0 ),
		 );
    
    $aline->close;
  }

=head1 DESCRIPTION

Workflow::Aline iterates through a set of files and requests robots to act on these. Differentiated
robots subject the files to certain actions, dependant on the robot type. A "copy-robot" would ie. copy
the file from one to another location, for example.

The design is similar to an event-driven parsing of an DAG. The DAG in that instance is the file-tree
and the events are the robots. 

=head2 EXPORT

None by default.

=head1 SEE ALSO

Class::Listener, Class::Maker, HTML::Mason, CPAN.

=head2 INCLUDED IN THIS PACKAGE

Workflow::Aline::Robot, Workflow::Aline::Pluggable, Workflow::Aline::ConveyorBelt.

=head1 AUTHOR

Murat Uenalan, E<lt>muenalan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by M. Uenalan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
