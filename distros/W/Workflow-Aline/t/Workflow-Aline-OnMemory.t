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

use Tree::Registry;

my $r = Tree::Registry->new( name => 'Fauna', desc => 'Procaryontic life' );

$r->know( 'Li' );
$r->know( 'Li/Proc' );
$r->know( 'Li/Proc/Bact' );
$r->know( 'Li/Proc/Algae' );
$r->know( 'Li/Proc/Archaeb/Void' );
$r->know( 'Li/Proc/Archaeb' );

$r->at( 'Li/Proc/Archaeb' )->attributes->{featureA} = '';

$r->at( 'Li/Proc/Bact' )->attributes->{featureA} = 1;

$r->at( 'Li/Proc/Bact' )->attributes->{featureB} = 2;










=head1 idea

	model Bio::Genome::SNP::Workflow from 
	

	snp_array = Bio::Genome::SNP::Array->new( file => 'file.snp' );

	filter = Bio::Genome::SNP::Filter->new( args => .. ); # isa Workflow::Aline::Robot

	reporter = Bio::Genome::SNP::Reporter->new( args => .. ); # isa Workflow::Aline::Robot



	my flow = Bio::Genome::SNP::Workflow->new( input =>  snp_array ); # isa Workflow::Aline

	flow->run( 		  
		   filter, 
		   reporter 
		  );

=cut



my $project = Workflow::Aline::OnMemory->new( input => $r, stages => 3 );
  
$project->run( 
	      # Workflow::Aline::Robot::Skip->new( when => sub { my ($this, $event, $session, $src) = @_; $src->stringify =~ /~$/i } ),
	     );

$project->close;

println "Exiting $0";

