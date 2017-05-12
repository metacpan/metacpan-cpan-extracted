package Pake::TestLib::TestTask;

use strict;
use warnings;

our @ISA = qw(Pake::Task);

sub run_from_dir($){

	my $test_dir = shift;
	return sub {
		opendir(DIR, $test_dir);
       		my @test_files= readdir(DIR); 
		
	       @test_files = splice(@test_files,2);
	       @test_files = map { $test_dir . "/" . $_} @test_files;

	       print "Running test_files: @test_files\n";

	       use Test::Harness;
	       runtests(@test_files);
	};
};

sub new(&){
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $test_dir = shift;

   my $self  = {};

   $self->{"name"} = "Test";
   $self->{"code"} = run_from_dir($test_dir);
   $self->{"pre"} = [];

   bless ($self, $class);

   $self->register_description($test_dir);
   Pake::Application::add_task($self);

   return $self;   
}

sub register_description($){
   my $self = shift;
   my $dir = shift;

   if(exists Pake::Application::Env()->{"desc"}){
       $self->{"description"} = Pake::Application::Env()->{"desc"};
       delete Pake::Application::Env()->{"desc"};
   } else {
       $self->{"description"} = "Execute tests from $dir dir";
   }
}

1;

__END__

=head1 NAME

    Pake::TestLib::TestTask 

=head1 SYNOPSIS
String tests is a directory where TestTask will search for test script.
It will execute any files in that dir

    Pake::TestLib::TestTask->new("tests");

If you want to execute test run:

    pake Test

Other way is to make default task Test:

    default "Test";

=head1 Description

TestTask executes tests in a specified directory.
