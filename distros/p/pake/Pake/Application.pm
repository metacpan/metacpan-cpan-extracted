package Pake::Application;

our $VERSION = '0.2';

use strict;
use warnings;

use Pake::Task;
use Pake::FileTask;
use Pake::Directory;
use Pake::Rule;

#Structure maintianing declared task with dependecies,
#options passed to the program and pake enviroment variables
our $appConfig = {
    "tasks" => {},
    "file" => "Pakefile",
    "rules" => {},
    "env" => {},
    "options" => {}
};
#--------------------------------------------------
sub Pakefile{
    if(@_){
	$appConfig->{"file"} = shift;
    }
    $appConfig->{"file"};
}
#--------------------------------------------------
sub Env{
    $appConfig->{"env"};
}
#--------------------------------------------------
sub printTasks{
    my $description = "Description";
    my $taskName = "Task";
    format TASK_PRINT =
@<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$taskName,                        $description
.

    local $~ = 'TASK_PRINT';
write();
print "\n";

    foreach $taskName (keys %{$appConfig->{"tasks"}}){
	$description = $appConfig->{"tasks"}{$taskName}->desc();
        write();
    }
}
#--------------------------------------------------
sub printDeps{
    my $deps = "Depends on";
    my $taskName = "Task";
    format TASK_DEPS =
@<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$taskName,                  $deps
.

    local $~ = 'TASK_DEPS';
write();
print "\n";

    foreach $taskName (keys %{$appConfig->{"tasks"}}){
	 
       if($appConfig->{"tasks"}{$taskName}->{"pre"}){
          $deps = "@{$appConfig->{'tasks'}{$taskName}->{'pre'}}"
       }

       $deps = "NO DEPENDENCIES" unless $deps;
       write();
    }
}
#--------------------------------------------------
sub options{
    if($_[0]){
	my %optHash = %{$_[0]};
	$appConfig->{"options"} = \%optHash;
    }
    $appConfig->{"options"};
}
#--------------------------------------------------
sub add_task {
    my $task = shift;
    $appConfig->{"tasks"}{$task->{"name"}} = $task;
}
#--------------------------------------------------
sub remove_task{
    my $task = shift;
    delete $appConfig->{"tasks"}{$task->{"name"}};
}
#--------------------------------------------------
sub get_task{
    my $task = shift;
    $appConfig->{"tasks"}{$task}
}
#--------------------------------------------------
sub add_rule{
    my $rule = shift;
    $appConfig->{"rules"}{$rule->{"pattern"}} = $rule;
}
#--------------------------------------------------
#use pake_dependency in the pake file to load Pakefiles
#by using this you're ending up in the Pake::Application context
sub run{
    my $file =  $appConfig->{"file"};

    unless (my $return = do $file) {
        die "couldn't parse $file: $@\n" if $@;
        die "couldn't do $file: $!\n"    unless defined $return;
        die "couldn't run $file\n"       unless $return;
    }
}
#--------------------------------------------------
sub usage {
    my @options = (
	"pake", "[options] [tasks]",
	"", "",
	"options:", "",
	"-h, -H", "Print help instructions",
	"-t, -T", "Prints all task with descriptions from Pakefile",
	"-D", "Prints all task with dependencies from Pakefile",
	"-d DIR", "Change the working directory to DIR",
	"-f FILE", "Loads dependencies from FILE instead of Pakefile",
	"-r", "dry run of Pakefile",
	"-V", "Print version"
	);
    my $index = 0;

    format USAGE_PRINT =
@<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<
   $options[$index],        $options[$index+1] 
.

    local $~ = 'USAGE_PRINT';
    for($index = 0; $index < $#options; $index+=2){
        write();
    }
}
#--------------------------------------------------
sub runTask {
    my $task = shift;
    my @files = ();

    if($appConfig->{"tasks"}{$task}){
	$appConfig->{"tasks"}{$task}->invoke();
    }
    else {
	unless (check_rules($task)){
	    print "Task: $task is not defined, cannot apply rules\n";
	    exit;
	}
    }
}
#--------------------------------------------------
sub check_rules{
    my $task = shift;

    while (my ($key, $rule) = each(%{$appConfig->{"rules"}})){
	#do poprawki, jak sprawdzic regexpa ;O??
	print $task, " ", $key, "\n";
	if($task =~ m/\Q$key/){
	    my $source_file = "";


	    #transforming task name into dpendant source file
 	    if(ref $rule->{"source"}){
		local $_ = $task;
		$source_file = $rule->{"source"}->();
	    }else{
		$source_file = $task;
		$source_file =~ s/\Q$key/$rule->{"source"}/;
	    }

	    if(-e $source_file){
		if(-e $task){
		    if((stat($task))[9]>(stat($source_file))[9]){
			#execute if task file is older then source file 
			return 1;
		    }
		    else{
			return 0;
		    }
		}
		
		$rule->{"code"}->();
		return 1;
	    } else{
		if(check_rules($source_file)){
		    $rule->{"code"}->();
		} else {
		    warn "No source file for task: ".($task).
			"\n\tCannot apply recursive rules";
		    return 0;
		}
	    }
	}
    }
}

1;

__END__

=head1 NAME

Pake::Application 

=head1 SYNOPSIS

You probably won't mess with the code in here.
If you are accessing Pake::Application enviroment from Pakefile you can get any information possesed by it.

=head1 Usage

	#In Pakefile script
	task {
		$task = Pake::Application::get_task("Any_task_created_earlier");
		$task->execute();
	} "test"

=head1 DESCRIPTION

Pake::Application is an enviroment of pake. It contains all information about current execution.

=head1 Methods

Overview of all methods avalailable in the Syntax.pm

B<Pakefile>

    You can get executed file name. During execution only get have any sense.

B<Env>

    Returns pake env variables

B<printTasks>

    Print all tasks with descriptions

B<printDeps>

    Print all tasks with dependencies

B<options>

    options passed to pake

B<get_task>

    returns Task object which name was specified as parameter

B<runTask>

    runs Task object which name was specified as parameter

=cut

#--------------------------------------------------

############## depreciated #################
#
#sub prepare {
#    my $self = shift;
#    my $task = shift;
#    my @taskChain = ();
#
#    return $self->prepare_task($task,@taskChain);
#}
#
#sub prepare_task{
#    my $self = shift;
#    my $task = shift;
#    my @taskChain = @_;
#    
#    my $pre = $self->{"tasks"}{$task}{"pre"};
#
#    foreach my $p (@{$pre}){
#	@taskChain = $self->prepare_task($p,@taskChain);
#    }
#    push @taskChain, $task unless $self->contains($task,@taskChain);
#    return @taskChain;
#}
#
#sub contains{
#   shift;
#   my ( $task, @taskChain) = @_;
#   foreach my $t (@taskChain){
#      return 1 if $t eq $task;
#   }
#}
#
############################################

1;
