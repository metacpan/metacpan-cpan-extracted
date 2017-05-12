package Xmms::Streamcast;

use Term::ReadKey;
use Socket;
use POSIX;
use strict;
use File::Basename;
use MP3::Info;
use Symbol ();
use IO::Handle;
use Xmms::Config ();

{
	no strict;
	$VERSION = "0.09";
}

if (caller eq 'Xmms') { 
	#Xmms::shell has pulled us in, so alias the commands
	*Xmms::Cmd::skip = \&skip; 
	*Xmms::Cmd::request = \&request; 
	*Xmms::Cmd::requests = \&requests; 
	*Xmms::Cmd::requested = \&requests; 
	*Xmms::Cmd::stream = \&streaming; 
	*Xmms::Cmd::songs = \&songs; 
	*Xmms::Cmd::dug = \&dug; 
	*Xmms::Cmd::search = \&search; 
	*Xmms::Cmd::shost = \&shost; 
	*Xmms::Cmd::sport = \&sport; 
	*Xmms::Cmd::sserver = \&sserver; 
	
} 

my $pconfig = Xmms::Config->new(Xmms::Config->perlfile);
my $server = $pconfig->read(streamcast => 'streamhost');
my $port = $pconfig->read(streamcast => 'streamport');

my $VERSION = "0.09";
print "Streamcast support $VERSION...available\n";
print "Stream server.............$server:$port\n";

my $DEBUG = 0;
sub shost ($;$$) {

        my ($self, $args) = @_;
        my $host = $args;
	$pconfig->write(streamcast => 'streamhost', "$host");
	$pconfig->write_file(Xmms::Config->perlfile);
	$server = $host;	
}

sub sport{

        my ($self, $args) = @_;
        my $stream_port = $args;
        $pconfig->write(streamcast => 'streamport', "$stream_port");
        $pconfig->write_file(Xmms::Config->perlfile);
	$port = $stream_port;

}

sub sserver{

print "$server:$port\n";

}
sub skip { 

	my $fh = open_connection();
	my $string = send_commands($fh, 'skip current');
	close_connection($fh);
}

sub streaming {
	my $title;
	my $mins;
	my $secs;
	my $song_id;
	my $file;
	my $base;
	my $artist;
	my $fh = open_connection();
	my $string = send_commands($fh, 'show current');
	close_connection($fh);

	my @line = split(/\n/, $string);
	foreach my $s (@line) {
		if ($s =~ m/ID\: (\d+)/g){
		    	$song_id = $1;
		   	# print "$song_id ";
		}

		if ($s =~ m/FILENAME\: (.*)$/g){
				$file = $1;
				$file = basename($file);
				chop($file);
			#	print "$file";
		}
                if ($s =~ m/MM\: (\d+)/g){
                         $mins = $1;
                }

                if ($s =~ m/SS\: (\d+)/g){
                	$secs= $1;
			if ($secs < 10) {
				$secs = "0$secs";
			}
                }
		if ($s =~ m/TITLE\: (.*)/g){
                       	$title = $1;
			chop($title);
		#	print "TITLE: $title\n"
		}
		if ($s =~ m/ARTIST\: (.*)/g){
                	$artist = $1;
			chop($artist);
		#	print "ARTIST: $artist<\n";
                }
	}
	if ($title) {
		print "$song_id - $artist - $title ($mins:$secs)\n";
	}
	else {
        	print "$song_id $file ($mins:$secs)\n";
	}
}
sub dug ($;$$) {

        my ($self, $args) = @_;
        my $grep = $args;
	my $all = 0;
	my $fh = open_connection();
	my $string = send_commands($fh, 'show songs');
	close_connection($fh);

	my @songs = split(/\n/, $string);

	foreach my $s (@songs) {
		my $in = '';
		if ($s =~ m/$grep/){
	                if ($s =~ m/(\d+)/g) {
       		        	my $song_id = $1;
				my $output = $s;
				chop($output);
				if($all == 0){
                			print "$output (y/n/a/b)? ";
					$in = ReadLine();
					chomp($in);
				}
				if ($in eq "y") {
			    		\&request(" ",$song_id);
				}
				elsif ($in eq "b"){
					last;	
				}
                                elsif ($in eq "a" || $all != 0){
					$all = 1;
					\&request(" ",$song_id);
                                }

				else {
					print "*not requested*\n";
				}
    		        }
		}
	}
}

sub songs {

	my $fh = open_connection();
	my $string = send_commands($fh, 'show songs');
	close_connection($fh);

	print {pager()} "$string";
}

sub request {

        my ($self, $args) = @_;
	my @nums = split(/\s/, $args);
	foreach my $num	 (@nums) {
		if($num == ' ') {
			next;
		}
        	my $fh = open_connection();
        	my $string = send_commands($fh, "add request $num");
		print "song $num requested\n";
        close_connection($fh);
	}	
}

sub requests {

	my $nothing = 0;
	my $fh = open_connection();
	my $string = send_commands($fh, 'show requests');
	close_connection($fh);

	my @songs = split(/\n/, $string);

	foreach my $s (@songs) {
                if ($s =~ /.*\r$/) {
                        chop($s);
                }
		my ($id, $file);

                if ($s =~ /^(\d+) (.*)$/) {
		 	$id = $1;
                 	$file = $2;
                 	$file = basename($file);
		 	print "$id $file\n";
		 	$nothing++;
		}
	}

	if (!$nothing){
		print "Zero requested songs. \n";
	}
}
sub search ($;$$) {

        my ($self, $args) = @_;
        my $grep = $args;
        my $all = 0;
        my $fh = open_connection();
        my $string = send_commands($fh, 'show songs');
        close_connection($fh);

        my @songs = split(/\n/, $string);

        foreach my $s (@songs) {
                my $in = '';
                if ($s =~ m/$grep/){
                        if ($s =~ m/(\d+) (.*)$/g) {
                                my $song_id = $1;
				my $string = $2;
                                my $output = $s;
                                chop($output);
				print "$song_id $string\n";
			}
		}
	}
}
sub open_connection {

        my $localport = $port;

        local *SOCK;
        socket(SOCK, PF_INET, SOCK_STREAM, 0) || die server_down();
        my $ipaddr = inet_aton($server);
        connect(SOCK, sockaddr_in($localport, $ipaddr)) || die server_down();
        print "Connection open\n" if $DEBUG;
        select(SOCK);
        $| = 1;
        select(STDOUT);

        return *SOCK;
}



sub close_connection {

        my $fh = shift;

        my $string = '';
        print "quit sent\n" if $DEBUG;
        print $fh "quit\r\n";
        while(defined (my $line = <$fh>)) {
                $string .= $line;
        }

        print "Closing connection\n" if $DEBUG;
        close($fh);

        return $string;
}
sub send_commands {

        my $fh = shift;
        my $string = '';

        $string = read_to_prompt($fh);
        if (@_) {
                foreach my $cmd (@_) {
                        print $fh "$cmd\r\n";
                        $string .= read_to_prompt($fh);
                }
        }

        return $string;
}
sub read_to_prompt {

        my $fh = shift;

        my $buff = '';
        my $line = '';
        my $string = '';
        my $read = 1;
        while ($read) {
                $buff = '';
                sysread($fh, $buff, 1);
                print "Buff: ->$buff<-\n" if $DEBUG > 1;
                if ($buff ne "\n") {
                        $line .= $buff;
                        if ($line =~ /^\>\s.*/) {
                                print "Prompt Found\n" if $DEBUG;
                                $read = 0;
                        }
                } else {
                        $string .= $line;
                        $string .= "\n";
                        print "Line: ->$line<-\n" if $DEBUG;
                        $line = '';
                }
        }

        print "read_to_prompt: Returning string ->$string<-\n" if $DEBUG;
        return $string;
}

sub server_down {

        print " radio network is down for the moment\n";
	return 1;
}

sub pager {
    my $fh = Symbol::gensym();

    if ($ENV{PAGER}) {
        open $fh, "|$ENV{PAGER}";
    }
    else {
        $fh = \*STDOUT;
    }

    return $fh;
}

1;
