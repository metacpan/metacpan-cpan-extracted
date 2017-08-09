package testcases::Base::Projects;
use strict;
use XAO::SimpleHash;
use XAO::Utils;
use Error qw(:try);
use XAO::Errors qw(XAO::Projects);

use base qw(testcases::Base::base);

sub test_everything {
    my $self=shift;

    use XAO::Projects qw(:all);

    my $project=new XAO::SimpleHash foo => 'bar';
    $self->assert(ref($project),
                  "Can't create project");

    create_project(name => 'test',
                   object => $project);

    my $rc="Second call to create_project was successfull and should not be";
    try {
        create_project(name => 'test',
                       object => $project);
    } catch XAO::E::Projects with {
        $rc='';
    } otherwise {
        my $e=shift;
        $rc="Wrong exception ($e)";
    };
    $self->assert($rc eq '',$rc);

    my $got=get_project('test');
    $self->assert(ref($got) && ref($got) eq ref($project),
                  "Got something bad from get_project ($got)");
    $self->assert($got->get('foo') eq 'bar',
                  "Project data corrupted");

    $rc="There should be no current project at that point";
    try {
        get_current_project();
    } catch XAO::E::Projects with {
        $rc='';
    } otherwise {
        my $e=shift;
        $rc="Wrong exception ($e)";
    };
    $self->assert($rc eq '', $rc);
    $self->assert(! get_current_project_name(),
                  "There should be no current project name at that point");
    set_current_project('test');
    $self->assert(ref(get_current_project()),
                  "No current project after set_current_project()");
    $self->assert(get_current_project_name() eq 'test',
                  "No current project name after set_current_project()");

    ##
    # Multiple projects at the same time
    #
    get_current_project()->{newvalue}=123;

    my $bar=new XAO::SimpleHash bar => 'foo', test => 234;
    $self->assert(ref($bar),
                  "Can't create project (bar)");

    create_project(name => 'bar',
                   object => $bar,
                   set_current => 1);
    $self->assert(get_current_project()->get('bar') eq 'foo',
                  "Wrong current project (bar)");
    $self->assert(get_current_project_name() eq 'bar',
                  "Wrong current project name (bar)");
    $self->assert(get_project('bar')->get('test') == 234,
                  "Wrong current project value for 'test' (bar)");
    $self->assert(get_project('test')->get('newvalue') == 123,
                  "Wrong current project value for 'newvalue' (test)");

    ##
    # Switching back
    #
    $self->assert(set_current_project('test') eq 'bar',
                  "set_current_project() did not return old name");
    $self->assert(get_current_project()->get('foo') eq 'bar',
                  "Wrong current project (test)");

    ##
    # Checking that get_project does not throw an error on non-existing
    # project
    #
    $self->assert(!defined(get_project('abrakadabra')),
                  "get_project on unknown project should return undef");
}

1;
