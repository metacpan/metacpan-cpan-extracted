package Pake::Task;

our $VERSION = '0.2';

use Scalar::Util qw(blessed);
###################################################
# Task Object source
#--------------------------------------------------
sub new(&$@){
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $code = shift if ref($_[0]) eq "CODE";
   my $name = shift;
   my $self  = {};

   $self->{"name"} = $name;
   $self->{"code"} = $code;
   $self->{"pre"} = shift;

   if(exists Pake::Application::Env()->{"desc"}){
       $self->{"description"} = Pake::Application::Env()->{"desc"};
       delete Pake::Application::Env()->{"desc"};
   } else {
       $self->{"description"} = "-";
   }
   bless ($self, $class);
   Pake::Application::add_task($self);
   return $self;
   
}
#--------------------------------------------------
sub invoke{
    my $self = shift;
    return 0 if $self->{"invoked"};
    $self->{"invoked"} = 1;

    $self->invoke_prerequisites();

    if($self->needed()){
	local $_ = $self;
	$self->{"code"}->();
    }
}
#--------------------------------------------------
sub invoke_prerequisites {
    my $self = shift;

    for $pre (@{$self->{"pre"}}){
	if(blessed (Pake::Application::get_task($pre))){
	    Pake::Application::get_task($pre)->invoke();
	} else{
	   warn "cannot apply rules" unless Pake::Application::check_rules($pre);
	}
    }
}
#--------------------------------------------------
sub execute{
    my $self = shift;
    $self->{"code"}->();
}
#--------------------------------------------------
sub needed{
    1;
}
#--------------------------------------------------
sub timestamp{

}
#--------------------------------------------------
sub desc{
    my $self = shift;
    if(@_){
	$self->{"description"}= shift;
    }
    $self->{"description"};
}
#--------------------------------------------------
sub name{
    my $self = shift;
    if(@_){
	$self->{"name"}= shift;
    }
    $self->{"name"};
}
#--------------------------------------------------
sub code{
    my $self = shift;
    if(@_){
	$self->{"code"}= shift;
    }
    $self->{"code"};
}
#--------------------------------------------------
sub dependencies{
    my $self = shift;
    if(@_){
	$self->{"pre"} = @_;
    }
    $self->{"pre"}
}
#--------------------------------------------------


1;

__END__

=head1 NAME

    Pake::Task 

=head1 SYNOPSIS

    use Pake::Task;
    $task = Pake::Task->new($code,$name,$dependency_array_ref);
    $task->invoke();


=head1 Description

Task is highly coupled with Pake::Application. The constructor registers new blessed Task variable in the Pake::Application. Task is a starting point to add new functionality to pake. You should extend it, and call the super constructor or manually add task in Pake::Application. Refer to source.

=head1 Methods

B<new>

Task constructor.

First parameter is a block of code, executed when the task is invoked.
Second parameter is name of the task (you specify it during pake usage, pake task1) pointing to the table with dependendant tasks 

	task {
	} "name" => ["deps"];

B<execute>

	$task->execute();

It runs the code block passed in the constructor

B<invoke>

	$task->invoke();

The method invokes all dependant tasks, checks if the file changed and eventually executes the task

B<invoke_prerequisites>

	$task->invoke_prerequisites();

invoke all task dependencies.

B<needed>

check if exection of task is needed: default 1.

Override it for special behaviour.

B<timestamp>

This method should return the file stamp if the task is a file abstraction. Right now it checks if file is newer then dependencies. If yes then it executes.
Can be chaned to some hash checking or some other fancy idea.

B<desc>

    Set/Get method for task description

B<name>

    Set/Get method for task name

B<code>

    Set/Get method for task code

=cut
