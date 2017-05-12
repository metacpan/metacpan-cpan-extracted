package VCI::VCS::Test;
use Moose;
extends 'VCI';

use VCI::Abstract::Repository;

sub repository_class { 'VCI::Abstract::Repository'; }
