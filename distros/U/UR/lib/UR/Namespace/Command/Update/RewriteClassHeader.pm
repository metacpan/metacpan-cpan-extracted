
package UR::Namespace::Command::Update::RewriteClassHeader;

use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'UR::Namespace::Command::RunsOnModulesInTree',    
    has => [
        force => { is => 'Boolean', is_optional => 1 },
    ]
);

sub params_as_getopt_specification
{
    my $self = shift;
    my @spec = $self->SUPER::params_as_getopt_specification(@_);
    return (@spec, "force!");
}

sub help_brief
{
    "Update::RewriteClassHeaders class descriptions headers to normalize manual changes."
}

sub help_detail
{
    qq|

UR classes have a header at the top which defines the class in terms of its metadata.
This command replaces that text in the source module with a fresh copy.

It is most useful to fix formatting problems, since the data from which the new
version is made is the data supplied by the old version of the file.

It's somewhat of a "perltidy" for the module header.

    |
}

sub for_each_class_object
{
    #$DB::single = 1;
    my $self = shift;
    my $class = shift;
    my $old = $class->module_header_source;
    my $new = $class->resolve_module_header_source;
    if ($self->force or ($old ne $new)) {
        print "Updating:\t", $class->module_base_name, "\n";
        $class->rewrite_module_header and return 1;
        
        print STDERR "Error rewriting header!" and return 0;
        
    }
    else {
        #print $class->class_name  . " has no source changes.  "
        #    . "Ignoring " . $class->module_base_name . ".\n";
        return 1;
    }
}

1;
#$Header$
