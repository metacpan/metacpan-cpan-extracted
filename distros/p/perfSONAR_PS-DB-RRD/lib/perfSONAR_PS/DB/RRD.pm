package perfSONAR_PS::DB::RRD;

use fields 'LOGGER', 'PATH', 'NAME', 'DATASOURCES', 'COMMIT';

use strict;
use warnings;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::DB::RRD - A module that provides a simple API for dealing with
data stored in rrd files through the RRDTool's RRDp perl module.

=head1 DESCRIPTION

This module builds on the simple offerings of RRDp (simple a series of pipes to
communicate with rrd files) to offer some common functionality that is present
in the other DB modules of perfSONAR_PS.

=cut    

use RRDp;
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use perfSONAR_PS::Common;
use perfSONAR_PS::ParameterValidation;

=head2 new($package, { path, name, dss, error })

Create a new RRD object.  All arguments are optional:

 * path - path to RRD executable on the host system
 * name - name of the RRD file this object will be reading
 * dss - hash reference of datasource values
 * error - Flag to allow RRD to pass back error values

The arguments can be set (and re-set) via the appropriate function calls. 

=cut

sub new {
    my ( $package, @args ) = @_;
    my $parameters = validateParams( @args, { path => 0, name => 0, dss => 0, error => 0 } );

    my $self = fields::new($package);
    $self->{LOGGER} = get_logger("perfSONAR_PS::DB::RRD");
    if ( exists $parameters->{path} and $parameters->{path} ) {
        $self->{PATH} = $parameters->{path};
    }
    if ( exists $parameters->{name} and $parameters->{name} ) {
        $self->{NAME} = $parameters->{name};
    }
    if ( exists $parameters->{dss} and $parameters->{dss} ) {
        $self->{DATASOURCES} = \%{ $parameters->{dss} };
    }
    if ( exists $parameters->{error} and $parameters->{error} ) {
        if ( $parameters->{error} == 1 ) {
            $RRDp::error_mode = 'catch';
            $self->{LOGGER}->debug("Setting error mode.");
        }
        else {
            undef $RRDp::error_mode;
            $self->{LOGGER}->debug("Unsetting error mode.");
        }
    }
    return $self;
}

=head2 setFile($self, { file })

Sets the RRD filename for the RRD object.

=cut

sub setFile {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { file => 1 } );

    if ( $parameters->{file} =~ m/\.rrd$/mx ) {
        $self->{NAME} = $parameters->{file};
        return 0;
    }
    else {
        $self->{LOGGER}->error("Cannot set filename.");
        return -1;
    }
}

=head2 setPath($self, { path })

Sets the 'path' to the RRD binary for the RRD object.

=cut

sub setPath {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { path => 1 } );

    if ( $parameters->{path} =~ m/rrdtool$/mx ) {
        $self->{PATH} = $parameters->{path};
        return 0;
    }
    else {
        $self->{LOGGER}->error("Cannot set path.");
        return -1;
    }
}

=head2 setVariables($self, { dss })

Sets several variables (as a hash reference) in the RRD object.

=cut

sub setVariables {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { dss => 1 } );

    $self->{DATASOURCES} = \%{ $parameters->{dss} };
    return 0;
}

=head2 setVariable($self, { dss })

Sets a variable value in the RRD object.

=cut

sub setVariable {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { ds => 1 } );

    $self->{DATASOURCES}->{ $parameters->{ds} } = q{};
    return 0;
}

=head2 setError($self, { error })

Sets the error variable for the RRD object.

=cut

sub setError {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { error => 1 } );

    if ( $parameters->{error} == 1 ) {
        $RRDp::error_mode = 'catch';
        $self->{LOGGER}->debug("Setting error mode.");
    }
    else {
        undef $RRDp::error_mode;
        $self->{LOGGER}->debug("Unsetting error mode.");
    }
    return 0;
}

=head2 getErrorMessage($self, { })

Gets any error returned from the underlying RRDp module for this RRD object.

=cut

sub getErrorMessage {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    if ($RRDp::error) {
        return $RRDp::error;
    }
    return;
}

=head2 openDB($self, { })

'Opens' (creates a pipe) to the defined RRD file.

=cut

sub openDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    if ( exists $self->{PATH} and exists $self->{NAME} ) {
        RRDp::start $self->{PATH};
        return 0;
    }
    else {
        $self->{LOGGER}->error("Missing path or name in object.");
        return -1;
    }
}

=head2 closeDB($self, { })

'Closes' (terminates the pipe) of an open RRD.

=cut

sub closeDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    if ( exists $self->{PATH} and exists $self->{NAME} ) {
        my $status = RRDp::end;
        if ($status) {
            $self->{LOGGER}->error( $self->{PATH} . " has returned status \"" . $status . "\" on closing." );
            return -1;
        }
        return 0;
    }
    else {
        $self->{LOGGER}->error("RRD file not open.");
        return -1;
    }
}

=head2 query($self, { cf, resolution, start, end })

Query a RRD with specific times/resolutions.

=cut

sub query {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { cf => 1, resolution => 0, start => 0, end => 0 } );

    my %rrd_result   = ();
    my @rrd_headings = ();
    unless ( $parameters->{cf} ) {
        $self->{LOGGER}->error("Consolidation function invalid.");
    }

    my $cmd = "fetch " . $self->{NAME} . " " . $parameters->{cf};
    if ( $parameters->{resolution} ) {
        $cmd = $cmd . " -r " . $parameters->{resolution};
    }
    if ( $parameters->{start} ) {
        $cmd = $cmd . " -s " . $parameters->{start};
    }
    if ( $parameters->{end} ) {
        $cmd = $cmd . " -e " . $parameters->{end};
    }

    $self->{LOGGER}->debug( "Calling rrdtool with command: " . $cmd );
    RRDp::cmd $cmd;
    my $answer = RRDp::read;
    if ($RRDp::error) {
        $self->{LOGGER}->error( "Database error \"" . $RRDp::error . "\"." );
        %rrd_result = ();
        $rrd_result{ANSWER} = $RRDp::error;
        return %rrd_result;
    }

    if ( $$answer ) {
        my @array = split( /\n/mx, $$answer );
        my $len = $#{@array};
        for my $x ( 0 .. $len ) {
            if ( $x == 0 ) {
                @rrd_headings = split( /\s+/mx, $array[$x] );
            }
            elsif ( $x > 1 ) {
                unless ( defined $array[$x] and $array[$x] ) {
                    next;
                }
                my @line = split( /\s+/mx, $array[$x] );
                $line[0] =~ s/://mx;
                my $len2 = $#{@rrd_headings};
                for my $z ( 1 .. $len2 ) {
                    $rrd_result{ $line[0] }{ $rrd_headings[$z] } = $line[$z] if $line[$z];
                }
            }
        }
    }
    return %rrd_result;
}

=head2 insert($self, { time, ds, value })

'Inserts' a time/value pair for a given variable.  These are not inserted
into the RRD, but will wait until we enter into the commit phase (i.e. by
calling the commit function).  This allows us to stack up a bunch of values
first, and reuse time figures. 

=cut

sub insert {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { time => 1, ds => 1, value => 1 } );

    $self->{COMMIT}->{ $parameters->{time} }->{ $parameters->{ds} } = $parameters->{value};
    return 0;
}

=head2 insertCommit($self, { })

'Commits' all outstanding variables time/data pairs for a given RRD.

=cut

sub insertCommit {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    my $answer = q{};
    my @result = ();
    foreach my $time ( keys %{ $self->{COMMIT} } ) {
        my $cmd      = "updatev " . $self->{NAME} . " -t ";
        my $template = q{};
        my $values   = q{};
        my $counter  = 0;
        foreach my $ds ( keys %{ $self->{COMMIT}->{$time} } ) {
            if ( $counter == 0 ) {
                $template = $template . $ds;
                $values   = $values . $time . ":" . $self->{COMMIT}->{$time}->{$ds};
            }
            else {
                $template = $template . ":" . $ds;
                $values   = $values . ":" . $self->{COMMIT}->{$time}->{$ds};
            }
            $counter++;
        }

        unless ( $template and $values ) {
            $self->{LOGGER}->error("RRDTool cannot update when datasource values are not specified.");
            next;
        }

        delete $self->{COMMIT}->{$time};
        $cmd = $cmd . $template . " " . $values;
        RRDp::cmd $cmd;
        $answer = RRDp::read;
        unless ($RRDp::error) {
            push @result, $$answer;
        }
    }
    return @result;
}

=head2 firstValue($self, { }) 

Returns the first value of an RRD.

=cut

sub firstValue {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    RRDp::cmd "first " . $self->{NAME};
    my $answer = RRDp::read;
    unless ($RRDp::error) {
        chomp($$answer);
        return $$answer;
    }
    return;
}

=head2 lastValue($self, { })

Returns the last value of an RRD. 

=cut

sub lastValue {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    RRDp::cmd "last " . $self->{NAME};
    my $answer = RRDp::read;
    unless ($RRDp::error) {
        chomp($$answer);
        return $$answer;
    }
    return;
}

=head2 lastTime($self, { })

Returns the last time the RRD was updated. 

=cut

sub lastTime {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    RRDp::cmd "lastupdate " . $self->{NAME};
    my $answer = RRDp::read;
    my @result = split( /\n/mx, $$answer );
    my @time   = split( /:/mx, $result[-1] );
    unless ($RRDp::error) {
        return $time[0];
    }
    return;
}

1;

__END__

=head1 SYNOPSIS

    use perfSONAR_PS::DB::RRD;

    my $rrd = new perfSONAR_PS::DB::RRD( {
      path => "/usr/local/rrdtool/bin/rrdtool" , 
      name => "/home/jason/rrd/stout/stout.rrd",
      dss => {'eth0-in'=>"" , 'eth0-out'=>"", 'eth1-in'=>"" , 'eth1-out'=>""},
      error => 1 }
    );

    # or also:
    # 
    # my $rrd = new perfSONAR_PS::DB::RRD;
    # $rrd->setFile({ path => "/home/jason/rrd/stout/stout.rrd" });
    # $rrd->setPath({ file => "/usr/local/rrdtool/bin/rrdtool" });  
    # $rrd->setVariables({ dss => {'eth0-in'=>"" , 'eth0-out'=>"", 'eth1-in'=>"" , 'eth1-out'=>""} });  
    # $rrd->setVariable({ dss => "eth0-in" });
    # ...
    # $rrd->setError({ error => 1});     

    # For reference, here is the create string for the rrd file:
    #
    # rrdtool create stout.rrd \
    # --start N --step 1 \
    # DS:eth0-in:COUNTER:1:U:U \ 
    # DS:eth0-out:COUNTER:1:U:U \
    # DS:eth1-in:COUNTER:1:U:U \
    # DS:eth1-out:COUNTER:1:U:U \
    # RRA:AVERAGE:0.5:10:60480

    # will also 'open' a connection to a file:
    if($rrd->openDB == -1) {
      print "Error opening database\n";
    }

    my %rrd_result = $rrd->query({
      cf => "AVERAGE", 
      resolution => "", 
      end => "1163525343", 
      start => "1163525373" });

    if($rrd->getErrorMessage) {
      print "Query Error: " , $rrd->getErrorMessage , "; query returned: " , $rrd_result{ANSWER} , "\n";
    }
    else {
      my @keys = keys(%rrd_result);
      foreach $a (sort(keys(%rrd_result))) {
        foreach $b (sort(keys(%{$rrd_result{$a}}))) {
          print $a , " - " , $b , "\t-->" , $rrd_result{$a}{$b} , "<--\n"; 
        }
        print "\n";
      }
    }

    $rrd->insert({ time => "N", ds => "eth0-in", value => "1" });
    $rrd->insert({ time => "N", ds => "eth0-out", value => "2" });
    $rrd->insert({ time => "N", ds => "eth1-in", value => "3" });
    $rrd->insert({ time => "N", ds => "eth1-out", value => "4" });
                  
    my $insert = $rrd->insertCommit;

    if($rrd->getErrorMessage) {
      print "Insert Error: " , $rrd->getErrorMessage , "; insert returned: " , $insert , "\n";
    }

    print "last: " , $rrd->lastValue , "\n";
    if($rrd->getErrorMessage) {
      print "last Error: " , $rrd->getErrorMessage , "\n";
    }

    print "first: " , $rrd->firstValue , "\n";
    if($rrd->getErrorMessage) {
      print "first Error: " , $rrd->getErrorMessage , "\n";
    }
    
    if($rrd->closeDB == -1) {
      print "Error closing database\n";
    }
    
=head1 SEE ALSO

L<RRDp>, L<Log::Log4perl>, L<Params::Validate>, L<perfSONAR_PS::Common>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along 
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
