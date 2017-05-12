package VCI::Abstract::ProjectItem;
use Moose::Role;
use VCI::Util qw(CLASS_METHODS);

has 'project'  => (is => 'ro', isa => 'VCI::Abstract::Project', required => 1,
                   handles => ['vci', 'repository', CLASS_METHODS]);

1;