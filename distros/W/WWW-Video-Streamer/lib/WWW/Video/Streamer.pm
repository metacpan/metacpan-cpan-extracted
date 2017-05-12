package WWW::Video::Streamer;

use warnings;
use strict;
use Config::IniHash;
use Text::NeatTemplate;
use String::ShellQuote;
use CGI qw/:standard/;
use File::MimeInfo;
use Cwd 'abs_path';

$CGI::POST_MAX=1024;
$CGI::DISABLE_UPLOADS=1;

=head1 NAME

WWW::Video::Streamer - A HTTP video streamer and browser.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use WWW::Video::Streamer;

    my $wvs = WWW::Video::Streamer->new();

    #read the config if it exists
    if (-e './config.ini') {
	    $wvs->config('./config.ini');
    }

    #invoke the CGI stiff
    $wvs->cgi;

=head1 METHODS

=head2 new

Initiates the object.

    my $wvs=WWW::Video::Streamer->new;

=cut

sub new {

	my $self={error=>undef, errorString=>'', hi=>5, minL=>5,
			  maxL=>20, replaceP=>50, maxR=>20};
	bless $self;

	$self->{mt}='/usr/local/bin/mencoder {$file} -oac mp3lame -ovc lavc -of avi -lavcopts vbitrate={$vb} '.
	            '-lameopts cbr={$ab} {$size} -vf scale={$x}:{$y} -really-quiet -o -';
	$self->{x}='140';
	$self->{y}='100';
	$self->{vb}='120';
	$self->{ab}='40';
	$self->{dir}='/arc/video/';

	#this will be used regardless in CGI more
	#also if being used as a deamon, this saves from doing it more than once
	$self->{cgi}=CGI->new;

	return $self;
}

=head2 cgi

This handles a handles the CGI interface.

    $wvs->cgi;

=cut

sub cgi{
	my $self=$_[0];

	#get the file in question and convert it to absolute path
	my $file=$self->{cgi}->param('file');
	if (!defined($file)) {
		$file='';
	}
	my $path=$self->{dir}.'/'.$file;
	$path=abs_path($path);
	if ($path eq '') {
		$path=$self->{dir}.'/';
	}

	#make sure the file in question is below the directory in question
	my $dirtest=$self->{dir}; #this is done just incase the directory that the user specified does not end in a /
	$dirtest=abs_path($dirtest);
	#if this is blank, it means it does not exist
	if ($dirtest eq '') {
		$self->{error}=11;
		$self->{errorString}='"'.$self->{dir}.'" does not exist';
		warn('WWW-Video-Streamer cgi:11: '.$self->{errorString});
		print $self->{cgi}->header(-status=>'404 file not found');
		return undef;
	}
	$dirtest=$dirtest.'/';
	my $regex='^'.quotemeta($dirtest);
	if ($path !~ /$regex/) {
		warn('WWW-Video-Streamer cgi: The path in question is out of the base directory. Using the default.');
		$path=$self->{dir};
		$path=abs_path($path).'/';
	}

	if (!-e $path) {
		$self->{error}=10;
		$self->{errorString}='The requested path, "'.$path.'", does not exist. file="'.$file.'"';
		warn('WWW-Video-Streamer cgi:10: '.$self->{errorString});
		print $self->{cgi}->header(-status=>'404 file not found');
		return undef;
	}

	#handles it if it is a file
	if (-d $path) {
		$self->dir($path);
		return 1;
		if ($self->{error}) {
			warn('WWW-Video-Streamer cgi: $self->dir("'.$path.'") failed');
		}
	}

	#handles it if it is a file
	if (-f $path) {
		my $px=$self->{cgi}->param('x');
		my $py=$self->{cgi}->param('y');
		my $pab=$self->{cgi}->param('ab');
		my $pvb=$self->{cgi}->param('vb');

		#make sure px is numeric
		my $test=$px;
		if (defined($px)) {
			$test=~s/[0123456789]//g;
			if ($test eq '') {
				$self->{x}=$px;
			}
		}

		#make sure py is numeric
		$test=$py;
		if (defined($py)) {
			$test=~s/[0123456789]//g;
			if ($test eq '') {
				$self->{y}=$py;
			}
		}

		#make sure pab is numeric
		$test=$pab;
		if (defined($pab)) {
			$test=~s/[0123456789]//g;
			if ($test eq '') {
				$self->{ab}=$pab;
			}
		}

		#make sure pvb is numeric
		$test=$pvb;
		if (defined($px)) {
			$test=~s/[0123456789]//g;
			if ($test eq '') {
				$self->{vb}=$pvb;
			}
		}

		$self->stream($path);
		if ($self->{error}) {
			warn('WWW-Video-Streamer cgi: $self->stream("'.$path.'") failed');
		}
		return 1;
	}

	#if we get here, it is not a file or directory... error
	print $self->{cgi}->header(-status=>'404 file not found');
	$self->{error}=3;
	$self->{errorString}='The file requested "'.$path.'" below "'.$self->{dir}.'" is not a file or directory';
	warn('WWW-Video-Streamer cgi:4: '.$self->{errorString});
	return undef;
}

=head2 config

This reads the config.

    if (-e './config.ini') {
	    $wvs->config('./config.ini');
        if($wvs->{error}){
            print "Error!\n";
        }
    }

=cut

sub config{
	my $self=$_[0];
	my $file=$_[1];

	if (!defined($file)) {
		$file='./config.ini';
	}

	my $ini=ReadINI($file);
	if (!defined($ini)) {
		$self->{errorString}='Failed to read "'.$file.'"';
		$self->{error}=1;
		warn('WWW-Video-Streamer config:1: '.$self->{errorString});
		return undef;
	}

	#check if the various internal definable stuff is present in the config and if it is
	#copy it into self

	if (defined($ini->{mt})) {
		$self->{mt}=$ini->{mt};
	}

	if (defined($ini->{x})) {
		$self->{x}=$ini->{x};
	}

	if (defined($ini->{y})) {
		$self->{y}=$ini->{y};
	}

	if (defined($ini->{vb})) {
		$self->{vb}=$ini->{vb};
	}

	if (defined($ini->{ab})) {
		$self->{ab}=$ini->{ab};
	}

	if (defined($ini->{dir})) {
		$self->{dir}=$ini->{dir};
	}

	return 1;
}

=head2 dir

This handles displaying directories.

    

=cut

sub dir{
	my $self=$_[0];
	my $path=$_[1];

	#make sure the path is defined
	if (!defined($path)) {
		$self->{error}=7;
		$self->{errorString}='No path defined';
		warn('WWW-Video-Streamer dir:7: '.$self->{errorString});
		return undef;
	}

	#make sure it exists
	if (!-e $path) {
		$self->{error}=6;
		$self->{errorString}='The path "'.$path.'" does not exist';
		warn('WWW-Video-Streamer dir:6: '.$self->{errorString});
		return undef;
	}

	#make sure it exists
	if (!-d $path) {
		$self->{error}=8;
		$self->{errorString}='The path "'.$path.'" does not a directory';
		warn('WWW-Video-Streamer dir:8: '.$self->{errorString});
		return undef;
	}

	#open the directory and read it
	my @entries;
	if (opendir(DIR, $path)) {
		@entries=readdir(DIR);
		closedir(DIR);
	}else {
		print $self->{cgi}->header(-status=>'404 file not found');
		print 'Error:404: File not found.';
		$self->{error}=5;
		$self->{errorString}='opendir(DIR, "'.$path.'") failed';
		warn('WWW-Video-Streamer dir:5: '.$self->{errorString});
		return undef;
	}

	@entries=sort(@entries);

	#we ignore dot files as these are most likely not useful
	@entries=grep(!/^\./, @entries);

	#holds directories in this directory
	my @dirs;

	#holds the files in this directory
	my @files;

	#break them all apart
	my $int=0;
	while (defined($entries[$int])) {
		#add it if it is a directory
		if (-d $path.'/'.$entries[$int]) {
			push(@dirs, $entries[$int]);
		}

		#add it if it is a file
		if (-f $path.'/'.$entries[$int]) {
			#check if it is playable and adds it to the list of files
			my $playable=$self->playable($entries[$int]);
			if ($playable) {
				push(@files, $entries[$int]);
			}
		}

		$int++;
	}

	#get the required parameters
	my $ab=$self->{cgi}->param('ab');
	my $vb=$self->{cgi}->param('vb');
	my $x=$self->{cgi}->param('x');
	my $y=$self->{cgi}->param('y');

	#makes sure all of the required values are defined
	if (!defined($ab)) {
		$ab=$self->{ab};
	}
	if (!defined($vb)) {
		$vb=$self->{vb};
	}
	if (!defined($x)) {
		$x=$self->{x};
	}
	if (!defined($y)) {
		$y=$self->{y};
	}	

	#make sure all the values are numeric
	

	#this is the directory that will be displayed
	my $displaydir=$path;
	my $bd=$self->{dir}.'/'; #get the base path and tack on a /
	$bd=File::Spec->rel2abs($bd);#cleanup the base path
	$displaydir=~s/^$bd//; #remove the base path from the path
	if ($displaydir eq '') {
		$displaydir='/';
	}

#	my $url='http://'.$ENV{HTTP_HOST}.$ENV{SCRIPT_NAME}.'?ab='.$ab.'+vb='.$vb.'+x='.$x.'+y='.$y;
	my $url=$ENV{SCRIPT_NAME}.'?ab='.$ab.'&vb='.$vb.'&x='.$x.'&y='.$y.'&file=';

	print $self->{cgi}->header(-type=>'text/html');

	#prints the head of the the html
	print '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">'."\n".
	      ''."\n".
	      '<html>'."\n".
	      '    <head>'."\n".
	      '        <title>WWW::Video::Streamer: '.$displaydir.' </title>'."\n".
	      '    </head>'."\n".
	      '    <body>'."\n".
	      '        <form name="change" action="'.$ENV{SCRIPT_NAME}.'" method="get">'."\n".
	      '            ab=<input type="text" name="ab" value="'.$ab.'">'."\n".
	      '            vb=<input type="text" name="vb" value="'.$vb.'">'."\n".
	      '            x=<input type="text" name="x" value="'.$x.'">'."\n".
	      '            y=<input type="text" name="y" value="'.$y.'">'."\n".
	      '            <input type="hidden" name="file" value="'.$displaydir.'">'."\n".
	      '            <input type="submit" value="Change">'."\n".
	      '        </form><br>'."\n".
	      '        directory: '.$displaydir.'<br>'."\n".
	      '        <table border="1">'."\n".
		  '            <tr>'."\n".
		  '                <td>'."\n".
		  '                    <A href="'.$url.$displaydir.'/..">..</A><br>'."\n".
		  '                </td>'."\n".
		  '            <tr>'."\n";

	#this presents the the directories to the users
	$int=0;
	while ($dirs[$int]) {
		my $directory=$displaydir.'/'.$dirs[$int];
		$directory=~s/\/\//\//g;
		print '            <tr>'."\n".
		      '                <td>'."\n".
		      '                    <A href="'.$url.$directory.'">'.$dirs[$int].'</A><br>'."\n".
		      '                </td>'."\n".
			  '            <tr>'."\n";

		$int++;
	}

	#this presents the the directories to the users
	$int=0;
	while ($files[$int]) {
		my $file=$displaydir.'/'.$files[$int];
		$file=~s/\/\//\//g;
		print '            <tr>'."\n".
		      '                <td>'."\n".
		      '                    <A href="'.$url.$file.'">'.$files[$int].'</A><br>'."\n".
		      '                </td>'."\n".
			  '            <tr>'."\n";

		$int++;
	}


	#this prints the end of it
	print '        </table>'."\n".
	      '    </body>'."\n".	
	      '</html>'."\n";

	return 1;
}

=head2 mencoder

Takes the template and generates a proper string to run mencoder.

    my $mencoderstring=$wvs->mencoder($file);
    if(!$wvc->{error}){
        print "Error!\n";
    }

=cut

sub mencoder{
	my $self=$_[0];
	my $file=$_[1];

	if (!defined($file)) {
		$self->{errorString}='No file specified.';
		$self->{error}=2;
		warn('WWW-Video-Streamer stream:2: '.$self->{errorString});
		return undef;
	}

	#escape any bad characters
	$file=shell_quote($file);

    my $tobj = Text::NeatTemplate->new();

	#initiates the object that will 
	my %data;
	$data{x}=$self->{x};
	$data{y}=$self->{y};
	$data{ab}=$self->{ab};
	$data{vb}=$self->{vb};
	$data{file}=$file;

	my $mencoder=$tobj->fill_in(data_hash=>\%data,
							 template=>$self->{mt});

	return $mencoder
}

=head2 playable

This checks if the file is playable or not.

Currently this just checks if the mimetype matches /^video\//.

This will error if no file is specified.

    $playable=$wvc->playable($file);
    if($wvc->{error}){
        print "Error!\n";
    }else{
        if($playable){
            print "Playable.\n";
        }else{
            print "Not playable.\n";
        }
    }

=cut

sub playable{
	my $self=$_[0];
	my $file=$_[1];

	#get the type
	my $type=mimetype($file);
	if (!defined($type)) {
		return undef;
	}

	#make sure it matches the video type
	if ($type=~/^video\//) {
		return 1;
	}

	return undef;
}

=head2 stream

This streams the specified file to standard out.

    $wvc->stream($file);
    if(!$wvc->{error}){
        print "Error!\n";
    }

=cut

sub stream{
	my $self=$_[0];
	my $file=$_[1];

	if (!defined($file)) {
		$self->{errorString}='No file specified.';
		$self->{error}=2;
		warn('WWW-Video-Streamer stream:2: '.$self->{errorString});
		return undef;
	}

	my $mencoder=$self->mencoder($file);
    if($self->{error}){
        warn('WWW-Video-Streamer stream: $self->mencoder("'.$file.'")');
		return undef;
    }

	warn($mencoder);

	print $self->{cgi}->header(-type => "video/avi");

	system($mencoder);

	return 1;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

sub errorblank{
	my $self=$_[0];

	$self->{error}=undef;
	$self->{errorString}="";

	return 1;
}

=head1 ERROR CODES

=head2 1

Failed to read the config.

=head2 2

No file is defined.

=head2 3

File requested is not below the specified directory.

=head2 4

The file is below the specified directory, but is not a file or directory.

=head2 5

Opendir failed for the path.

=head2 6

Path does not exist.

=head2 7

Path is not defined.

=head2 8

Path is not a directory.

=head2 9

Failed to build mencoder string.

=head2 10

The requested file does not exist.

=head2 11

The video directory does not exist.

=head1 CONFIG FILE

The below is a example config file at the defaults.

    x=100
    y=100
    vb=120
    ab=40
    dir=/arc/video/
    mt=/usr/local/bin/mencoder {$file} -oac mp3lame -ovc lavc -of avi -lavcopts vbitrate={$vb} -lameopts cbr={$ab} {$size} -vf scale={$x}:{$y} -really-quiet -o -

=head2 ab

This is the default audio bit rate to use for the encoding.

=head2 dir

This is the base directory for video.

=head2 mt

This is the mencoder template that will be used.

=head3 {$ab}

This part of the template will be replaced with the audio bit rate.

=head3 {$file}

This part of template will be replaced with the file name.

=head3 {$vb}

This part of the template will be replaced with the video bit rate.

=head3 {$x}

This part of the template will be replaced with the video width.

=head3 {$y}

This part of the template will be replaced with the video heigth.

=head2 x

This is the default video width

=head2 y

This is the default video hieght.

=head1 DOT FILES

These are currently ignored by the dir function.

=head1 SECURITY

The file names passed to it are escaped when they are passed to mplayer.

Care should be taken to make sure that the config file is not writable by any untrusted users
as changing the 'mt' variable can allow other things to be executed.

If none-numeric values for 'x', 'y', 'ab', or 'vb' are found when it goes to play it,
the defaults are used.

=head1 USING

Copy 'bin/wvs.cgi' to your directory on your web server, enable CGI on that directory,
and then if you want to override the defaults create 'config.ini' in hat directory.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-video-streamer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Video-Streamer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Video::Streamer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Video-Streamer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Video-Streamer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Video-Streamer>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Video-Streamer/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of WWW::Video::Streamer
