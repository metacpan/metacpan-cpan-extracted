package Xymon::Client;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.08';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}




sub new
{
    my ($class,$parm) = @_;

 	
    my $self = bless ({}, ref ($class) || $class);
	$self->{home} = $parm->{home};
	$self->{DEBUG} = $parm->{DEBUG};

	my $fh;
	open($fh, "<",$self->{home}."/etc/hobbitclient.cfg");
	while(<$fh>) {
		chomp;
		if(!m/^#/ && m/\w+/) {
			s/\"//g;
			s/\#.*$//g;
			my @fields = (split(/=|\s+/));
			my $field = shift @fields;
			
			if( @fields > 1 ) {
				$self->{$field} = \@fields;
			} else {
				$self->{$field} = $fields[0];
			}
			
			
		}
	}
	
    return $self;
	

}

sub get_status
{
	my $self = shift;
	my $service = shift;
	my $cmd;
	
	my $host = $self->{BBDISPLAYS}[0];
		
	open($cmd,"$self->{home}/bin/bb $host 'hobbitdboard host=$host fields=hostname,testname,color'");
	
	while(<$cmd>) {
		print $_ . "\n";
	}

	
}


sub send_status
{
	my $self = shift;
	my $args = shift;
	

	foreach my $host (@{$self->{BBDISPLAYS}}) {
		system("$self->{home}/bin/bb $host 'status $args->{server}.$args->{testname} $args->{color} $args->{msg}'") ;
		if( $self->{DEBUG} == 1 ) {
			print "$self->{home}/bin/bb $host 'status $args->{server}.$args->{testname} $args->{color} $args->{msg}'";
		}
	}
	
}

=head1 NAME

Xymon::Client - Interface to xymon/hobbit client.

=head1 SYNOPSIS

  use Xymon::Client;
  my $xymon = Xymon::Client->new("/home/hobbit/client/");
  
  $xymon->send_status({
  	server => 'servername',
  	testname => 'test',
  	color => 'red',
  	msg => 'test failed',
  	
  })


=head1 DESCRIPTION

Provides an object interface to the xymon/hobbit client.

=head1 METHODS

=head2 Xymon::Client->new($home)

Create a new Xymon Client object, passing it the xymon/hobbit home dir. 
This is usually /home/hobbit/client. 


=head2 send({...})

Sends a status message to the hobbit server. The following parameters should be passed:

server: the server name that was tested
testname: the name of the test (ie the column on the xymon page)
color: the status color
msg: the message to send which may be multiline and include any name-colon-value parameters.

ie 

$xymon->send({
  	server => 'servername',
  	testname => 'test',
  	color => 'red',
  	msg => 'test failed',
  	
  })


	
	
=cut




=head1 AUTHOR

    David Peters
    CPAN ID: DAVIDP
    davidp@electronf.com
    http://www.electronf.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), bb(1)

=cut




1;


