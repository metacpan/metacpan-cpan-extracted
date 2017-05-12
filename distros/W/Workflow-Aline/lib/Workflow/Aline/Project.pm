package Workflow::Aline::Project;

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
	string => [qw( name )],

	obj => [qw( file_box )],
    },
};

sub _preinit : method
{
    my $this = shift;

    $this->file_box( File::Box->new( mother_file => __FILE__ ) );
}

1;
