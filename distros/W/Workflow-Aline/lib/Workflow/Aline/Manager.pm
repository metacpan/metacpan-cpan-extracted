package Workflow::Aline::Manager;

use Class::Maker qw(:all);
use Class::Maker::Exception;
use IO::Extended qw(:all);
use File::Box;
use Regexp::Box;


our $VERSION = '0.02';

our $DEBUG = { basic => 0, robots => 0 };

use strict; 

use warnings;

use File::Box;

Class::Maker::class
{
    public =>
    {
	string => [qw( name dir_home )],

	obj => [qw( file_box )],
    },
};

sub _preinit : method
{
    my $this = shift;

    $this->file_box( File::Box->new( mother_file => __FILE__ ) );
}

sub _postinit : method
{
    my $this = shift;

    $this->dir_home( Path::Class::Dir->new( '.aline' ) ) unless ref( $this->dir_home );
}

sub _path_class_always 
{
    my $where = shift;

    $where = Path::Class::Dir->new( $where ) unless ref( $where );

return $where;
}

sub dir_project_setup : method
{
    my $this = shift;

    my $dir_new_project = _path_class_always( shift );

    my $skeleton_project = shift || 'project_skeleton';

    if( my $dir_skeleton = $this->dir_home->subdir( $skeleton_project ) )
    {
	my $dir_new = $this->dir_home->subdir( 'projects')->subdir( $dir_new_project );

	unless( -e $dir_skeleton )
	{
	    warnfln "$this->dir_project_setup: Did not find project skeleton %S ..will do nothing.", $dir_skeleton;
	}  
	else
	{
	    if( -e $dir_new )
	    {
		warnfln "$this->dir_project_setup: Existing project with name %S found ..will do nothing.", $dir_new;
	    }
	    else
	    {
		print qx{cp -r $dir_skeleton $dir_new};

		warnfln "$this->dir_project_setup: Project new %S created ..ok.", $dir_new_project;
	    }
	}

	print qx{find $dir_new};
    }
    else
    {
	diefln "Cannot find work_aline_projects via File::Box";
    }
}

sub dir_workflow_aline_setup : method
{
    my $this = shift;

    my $where = $this->dir_home;

    if( my $d = $this->file_box->request( $this->dir_home ) )
    {
	unless( -e $where )
	{
#	    warnfln "$this->dir_project_create: Did not find %S ..making dir.", $where;
#	    $where->mkpath;

	    print qx{cp -r $d $where};
	}  
	else
	{
	    warnfln "$this->dir_project_create: Project dir %S exists ..skipping setup.", $where;
	}

	print qx{find $where};
    }
    else
    {
	diefln "Cannot find work_aline_projects via File::Box";
    }
}

sub close : method
{
}

1;
