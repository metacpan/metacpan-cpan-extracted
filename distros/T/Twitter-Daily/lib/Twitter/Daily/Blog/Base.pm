package Twitter::Daily::Blog::Base;

use strict;
use warnings;

our $VERSION = "0.1.0";

=pod

=head1 NAME

Twitter::Daily::Blog::Base - Interface to be used for publishing an entry on any blog

=head1 SYNOPSIS

 use Error (:try);
 
 ## The next module implements the subs descibed at Twitter::Daily::Blog::Base 
 use My::Blog::Publisher; 
 
 try { 
     my $blog = My::Blog::Publisher->new( param1 => 'firstParaneterContent', ... );
    
     $blog->login();
     
     ## $filename contains the file path to the story to be published
     $blog->publish( $filename  );
     
     $blog->quit;
 } 
 catch Twitter::Daily::Blog::NoConstructorError with {
 	my $E = shift;
    print STDERR "Error in constructor : ", $E->{'\-text'}, "\n";
 } 
 catch Twitter::Daily::Blog::NoLoginError with {
 	my $E = shift;
    print STDERR "Error in login : ", $E->{'\-text'}, "\n";
 } 
 catch Twitter::Daily::Blog::NoPublishError with {
 	my $E = shift;
    print STDERR "Error in publishing : ", $E->{'\-text'}, "\n";
 } 
 catch Twitter::Daily::Blog::NoQuitError with {
 	my $E = shift;
    print STDERR "Error in quitting : ", $E->{'\-text'}, "\n";
 }
 
=head1 DESCRIPTION 

Interface to be used for publishing an entry on any blog

=head1 INTERFACE

All methods throw an error on failure, and in such case the error thrown will
be contained as text in -text and a unique numeric value in -value.

The arguments to be used for each method implementation are up to each implementation,
meaning that unless otherwise is explicited the method will accept all sort of arguments.

=head2 new

Creates a new object.

=cut

sub new {
    my $class = shift;
    my %option = @_;

    my $self;
    
    foreach my $key ( keys %option ) {
        $self->{$key} = $option{$key};
    };
 
    return bless $self, $class;
};

=pod

=head2 login

Logins to the server. No arguments are accepted.

=cut

sub login { };

=pod

=head2 publish

Publishes the given story

=head3 options

=over 1

=item * filename

mandatory option that specifies the local filename to be published
in the blog. 

=back

=cut

sub publish {
	my $filename = shift;
}

=head2 quit

Ends the publishing process. The method accepts no parameters.

=cut

sub quit { };

1;
