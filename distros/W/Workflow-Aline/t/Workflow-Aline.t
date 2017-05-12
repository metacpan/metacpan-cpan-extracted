# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Workflow-Aline.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Workflow::Aline') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Workflow::Aline;

use IO::Extended qw(:all);

  my $manager = Workflow::Aline::Manager->new( dir_home => '.aline' );
  
  $manager->dir_workflow_aline_setup;
  $manager->dir_project_setup( 'newprj1' );
  $manager->dir_project_setup( 'newprj2' );
  $manager->dir_project_setup( 'newprj3' );
  $manager->close();

for( qw( newprj1 newprj2 newprj3 ) )
  {
    my $project = Workflow::Aline->new_with_setup( home_dir => '.aline', project => $_ );

	#$podchecker_robot is too verbose and out
#our $podchecker_robot = Workflow::Aline::Robot::Podchecker->new();
		
    $project->run( 
		  Workflow::Aline::Robot::Skip->new( when => sub { my ($this, $event, $session, $src) = @_; $src->stringify =~ /~$/i } ),
		  
		  Workflow::Aline::Robot::Skip->new( when => sub { my ($this, $event, $session, $src) = @_; $src->stringify =~ /maslib|cvs/i } ),
		  
		  Workflow::Aline::Robot::Skip->new( when => sub { my ($this, $event, $session, $src) = @_; $src->stringify =~ /tmpl$/ && not $session->master->is_staging } ),
		  
		  Workflow::Aline::Robot::Mkdir->new(),
		  
		  Workflow::Aline::Robot::Copy->new(),
		  
		  Workflow::Aline::Robot::Template->new( detector => sub { $_[1] =~ /\.tmpl$/ } ),
		  
		  Workflow::Aline::Robot::Decorator->new( stage => 0 ),
		 );
    
    $project->close;
  }

println "Exiting $0";
