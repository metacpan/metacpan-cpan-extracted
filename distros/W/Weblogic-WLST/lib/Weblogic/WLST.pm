package Weblogic::WLST;
use Data::Dumper;
use Expect;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}



=head1 NAME

Weblogic::WLST - Communicate with weblogic server via WLST.

=head1 SYNOPSIS

  use Weblogic::UserAdmin;
  my $wlst->{$server} = new Weblogic::WLST(
		{
			wlsthome => "/home/http/Oracle/Middleware/wlserver_10.3/server/",
			user     => 'system',
			password => 'narcolepsy',
			server   => "t3://$server"
		}
	) or die "Died";
  	
  
=cut

=head1 DESCRIPTION

Communicate with weblogic server via WLST.

=cut


=head1 USAGE

=cut

sub new
{
    my ($class, $parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);
	
	
	_connect_server($self,$parameters->{server},$parameters->{wlsthome},$parameters->{user},$parameters->{password});
	

    return $self;
}


sub _connect_server {
	
	my ($self,$server, $wlsthome, $user, $password ) = @_;
	
	$self->{exp} = Expect->spawn("$wlsthome/bin/setWLSEnv.sh;java -cp $wlsthome/lib/weblogic.jar weblogic.WLST")
	 	or die "Cannot spawn WLST: $!\n";;

	#$Expect::Exp_Internal = 1;
	#$self->{exp}->debug(1);
	
	
	$self->{exp}->log_stdout(0);

	

	$self->{exp}->send("connect('$user','$password','$server')\n");
	

	$self->{exp}->send("AS=get('AdminServerName')\n");
	

	$self->{exp}->send("\nprint 'AS#' + AS\n");
	
	

	my ($idx, $err, $string, $before, $after) = $self->{exp}->expect(30, '#');
	$self->{exp}->clear_accum();
	($idx, $err, $string, $before, $after) = $self->{exp}->expect(30, '#');
	
	
	$after =~ s/\r\n//;
	$self->{adminServer} = $after;
	$self->{exp}->send("serverRuntime()\n");
	
}

=head2 getRunTimeValue($param)

  gets the value from the JVMRuntime stack -  
  my $heapFree=getRuntimeValue("HeapFreeCurrent")
=cut

sub getRuntimeValue {
	
	my ($self, $param) = @_;
	
	
	
	
	my $cmd = "RESULT=get('/JVMRuntime/$self->{adminServer}/$param')\n";
	
	$cmd .= "print
			 print 'RESULT#' + `RESULT`
			 ";
	
	$self->{exp}->send($cmd . "\n");

	my ($idx, $err, $string, $before, $after) = $self->{exp}->expect(10, '#');
	$self->{exp}->clear_accum();
	($idx, $err, $string, $before, $after) = $self->{exp}->expect(10, '#');
	
	if(!defined $after) {
		return undef;
	} else {
		$after =~ s/\r\n//;		
		return substr($after,0,length($after)-1);
	}
			 
}







=head1 AUTHOR

    D Peters
    CPAN ID: DAVIDP
    davidp@electronf.com

=cut

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

