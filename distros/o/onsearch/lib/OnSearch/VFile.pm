package OnSearch::VFile; 

=head1 NAME

OnSearch::VFile - OnSearch virtual file library.

=head1 SYNOPSIS

    my $vfile = OnSearch::VFile -> new;
    $return_value = $vfile -> vfopen (<pathname>);
    $mimetype = $vfile -> vf_ftype;
    $return_value = $vfile -> vfseek ($offset, $whence);
    $buf = $vfile -> vfread ($size);
    $vfile -> vfclose;

=head1 DESCRIPTION

OnSearch::VFile provides read-only virtual file routines that allow
documents of different formats to be indexed and searched.  VFile
provides an interface to plugin modules which filter the file's 
contents into plain text, to facilitate indexing and searching.

=head1 METHODS

=cut

#$Id: VFile.pm,v 1.13 2005/08/16 05:34:03 kiesling Exp $

use strict;
use warnings;
use Carp;
use Fcntl;

use OnSearch;
use OnSearch::WebLog;

my $VERSION='0.01';

my $logfunc = \&OnSearch::WebLog::clf;

=head2 $vf -> new ();

This is the OnSearch::VFile constructor.

=cut

sub new {
    my $proto = shift;
    my $class = ref ( $proto ) || $proto;
    no warnings;  # CWD used only once warning.
    my $obj = {
	cwd => $OnSearch::CWD,
    };
    use warnings;
    bless ($obj, $class);
    return $obj;
}

=head2 $vf -> vfopen (I<path>);

Create a virtual file handle for file I<path.>

=cut

sub vfopen {
    my $self = shift;
    my $subj_path = shift;
    
    my ($tmpfh, $afh);
    my ($basename) = ($subj_path =~ /.*\/(.*)/);
    my $tmpname = '/tmp/' . "$basename.$$";
    my ($c_type, $c_plugin);

    local $!;

    $self -> {subj_path} = $subj_path;
    $self -> {tmpname} = $tmpname;
    $self -> {tmpoff} = 0;
    $self -> {filetype} = vf_ftype ($subj_path) || do {
	browser_warn ("VFile.pm::vfopen::vf_ftype $subj_path: $!");
	$self -> vfclose;
	return undef;
    };

    undef $self -> {plugin};
    foreach my $p (OnSearch::AppConfig -> lst ('PlugIn')) {
	($c_type, $c_plugin) = ($p =~ /(\S+)\s+(\S+)/);
	if ($self -> {filetype} =~ m"$c_type") {
	    $self -> {plugin} = $c_plugin;
	}
    }
    if (! $self -> {plugin}) {
	browser_warn ("A plugin filter for $subj_path (MIME type " .
      $self -> {filetype} . ') is not installed.  Using text/plain plugin.');
	$self -> {plugin} = 'plugins/text';
    }

    ###
    ### It should be okay to spool anything with the text/plain 
    ### plugin provided it doesn't die while spooling some binary
    ### data, and the display routines are robust enough to pick
    ### out the search terms from the data.  
    ###
    if ($self -> _vf_spool) {

	###
	### Suppres warnings about STDOUT from
	### the abstraction layer... it isn't in
	### use since we're running as a daemon
	### process.
	###
	no warnings;
	sysopen ($tmpfh, $tmpname, O_RDONLY);
	use warnings;
	###
	### We must use defined () when testing for 
	### file handles. The next available file 
	### handle number could be 0, because
	### this subroutine runs as a daemon process 
	### and STDOUT isn't open.
	###
	if ((! defined (fileno ($tmpfh))) || $!) {
            ###
            ### Don't vfclose () here in case we can re-spool later.
            ###
	    return undef;
	} else {
	    $self -> {tmpfh} = *$tmpfh;
	}
    }

    ###
    ### The Perl I/O abstraction layer issues a warning
    ### if the file handle number is 0, which is STDOUT,
    ### and is opened only for input.  We issue our own
    ### warning if necessary when handling an exception.
    ###
    no warnings;
    sysopen ($afh, $subj_path, O_RDONLY);
    use warnings;
	
    if (! defined (fileno ($afh)) || $!) {
	&$logfunc ('error',
	   "VFile.pm::vfopen::sysopen failed $subj_path: $!.");
	$self -> vfclose;
	return undef
    }
    $self -> {fh} = *$afh;

    return $self;
}

sub _vf_spool {
    my $self = $_[0];

    unless ($self -> {cwd} && -d $self -> {cwd}) {
	browser_warn ("OnSearch::VFile::_vf_spool: bad cwd" .
			  $self -> {cwd} . "$!.");
	return undef;
    }
    my $plugin_path = $self -> {cwd} . '/' . $self -> {plugin};
    unless ($plugin_path && -f $plugin_path) {
	browser_warn ("OnSearch::VFile::_vf_spool: bad plugin ".$plugin_path);
	return undef;
    }
    unless ($self -> {tmpname}) {
	browser_warn ("OnSearch::VFile::_vf_spool: bad tmp name" .
			  $self -> {tmpname});
	return undef;
    }

    my @vf_args = ($plugin_path, $self->{subj_path}, $self->{tmpname});
    my $retval = 
	_vf_exec (\@vf_args);

    if (! defined ($retval) || $!) {
	browser_warn ("OnSearch::VFile::_vf_spool \"$plugin_path " .
		      $self -> {subj_path}. ' ' . $self -> {tmpname} . 
		      "\": return value $retval, $!.");
	return undef;
    }
    return 1;
}

sub _vf_exec {
    my $args = shift;
    my $chldpid;

    #
    # Explicitly ignore SIGCHLD from exec call terminating,
    # SIGPIPE which can terminate a script, and SIGTERM 
    # if a (potentially different) parent process terminates.  
    #
    local $SIG{CHLD} = \&ignore_signal;
    local $SIG{PIPE} = \&ignore_signal;
    local $SIG{TERM} = \&ignore_signal;

  FORK: if ($chldpid = fork ()) {
      ###
      ### Wait for the child process to terminate.
      ###
      wait;
      #
      # Quick way to ignore errors caused by other signals
      # from the Web server or a plugin.  The browser_warn 
      # call below notes actual exec () errors.
      #
      undef $! if $!;
      return $chldpid;
  } elsif (defined $chldpid) {
      exec @$args or browser_warn ("OnSearch::_vf_exec @{$args}: $!");
  } elsif ($! =~ /No more processes|Resource temporarily unavailable/) {
      OnSearch::WebLog::clf ("OnSearch::_vf_exec @{$args} $!.");
      sleep 2;
      redo FORK;
  } else {
      return undef;
  }
}

=head2 $vf -> vf_ftype (I<path>)

Return the MIME type of file I<path.>

=cut

###
###  If adding magic types, also add to OnSearch::Utils::filetype.
###
sub vf_ftype {
    my $fname = $_[0];
    my $type = 'text/plain'; 
    my ($buf, $fh);
    my $size = 1024;

    ###
    ### The text/plain filter should be able to cope with
    ### any file type, so we can simply default to 
    ### that value and not worry about recovering from
    ### an error at this point.
    ###
    ###
    ### Supress I/O abstraction layer warnings here also.
    ###
    no warnings;
    sysopen ($fh, $fname, 0) || do {  # O_RDONLY
	&$logfunc ('error', 
	   "vf_ftype open $fname: $!.  Using MIME type $type.");
	return $type;
    };
    use warnings;
    sysread ($fh, $buf, $size) || do {
	&$logfunc ('error', 
	   "vf_ftype read $fname: $!.  Using MIME type $type.");
	return $type;
    };

    if ($buf =~ /\<\!DOCTYPE HTML/ism) { $type = 'text/html'; }
    if ($buf =~ /\<html/ism) { $type = 'text/html'; }
    if ($buf =~ /\<\?xml/ism) { $type = 'text/html'; }
    if ($buf =~ /^%!PS-Adobe/) { $type = 'application/postscript'; }
    if ($buf =~ /^%PDF-/) { $type = 'application/pdf'; }
    if ($buf =~ /^PK\003\004/) { $type = 'application/zip'; }
    if ($buf =~ /^\037\213/) { $type = 'application/x-gzip'; }
    if ($buf =~ /^GIF8/) { $type = 'image/gif'; }
    if ($buf =~ /^\211PNG/) { $type = 'image/png'; }
    if ($buf =~ /^\037\235/) { $type = 'application/compress'; }
    if ($buf =~ /^\312\376\272\276/) { $type = 'application/java-class'; }
    no warnings;
    if (substr ($buf, 6, 4) eq 'JFIF') { $type = 'image/jpeg'; }
    if (substr ($buf, 24, 22) eq 'outname=install.sfx.$$') 
    { $type = 'application/vnd.sun.pkg'; }
    use warnings;
    close $fh;
    return $type;
}

=head2 $vf -> vfseek (I<offset>, I<whence>);

Seek to file position I<offset>.  The I<whence> parameter 
can be 0 to seek from the beginning of the file, 1, to seek
from the current position, and 2 to set the offset from the
end of the file.

=cut

sub vfseek {
    my $self = $_[0];
    my $offset = $_[1];
    my $from = $_[2];

    if (! $self -> {tmpfh} || ! defined (fileno $self->{tmpfh})) {
	# If tmp file was unlinked, re-spool.
	my $vf_spool_result = 
	    $self -> _vf_spool unless (-f $self -> {tmpname});
	return undef unless $vf_spool_result;
	sysopen ($self -> {tmpfh}, $self->{tmpname}, O_RDONLY);
	if (! defined (fileno ($self->{tmpfh})) || $!) {
	    browser_warn ("OnSearch::VFile::vfseek::sysopen reopening" .
			  $self -> {tmpname} . " PID $$: $!");
	    $self -> vfclose;
	    return undef
	}
    }

    my $r = sysseek ($self -> {tmpfh}, $offset, $from);
    if (! $r) {
	browser_warn ("OnSearch::VFile::vfseek::sysseek" .
		      $self -> {tmpname} . " offset $offset : PID $$ $!");
	$self -> vfclose;
	return undef;
    }
    $self -> {tmpoff} = $r;
    return $r;
}

=head2 $vf -> vfread (I<bytes>)

Read I<bytes> from the virtual file.

=cut

sub vfread {
    my $self = $_[0];
    my $size = $_[1];
    if (!$self -> {tmpfh} || ! defined (fileno ($self -> {tmpfh}))) {
	warn "vfread: reopening " . $self -> {tmpname};
	sysopen (TMP, $self -> {tmpname}, 0) or   # O_RDONLY
	    warn "vfread sysopen " . $self -> {tmpname} . ": $!\n";
	sysseek (TMP, $self -> {tmpoff}, 0) or warn "vfread sysseek: $! " .
	    $self -> {tmpoff} . "\n";
	$self -> {tmpfh} = \*TMP;
    }
    my ($nbytes, $buf);
    eval { $nbytes = sysread ($self->{tmpfh}, $buf, $size); };

    if (@!||$!) { warn "vfread: $! @!"; return undef; }

    $self -> {tmpoff} += length ($buf);

    warn ("vfread error ".$self->{tmpname}.": $!") 
	if ($nbytes != length($buf));
    return $buf;
}

=head2 $vf -> vfclose ();

Close a virtual file handle.

=cut

sub vfclose {
    my $vf_obj = shift;
    
    if ($vf_obj -> {tmpfh} && defined (fileno ($vf_obj->{tmpfh}))) { 
	close $vf_obj -> {tmpfh}; 
    }
    undef $vf_obj -> {tmpfh};
    if ($vf_obj -> {fh} && defined (fileno ($vf_obj->{fh}))) {
        close $vf_obj -> {fh};
    }
    undef $vf_obj -> {fh};
    if ($vf_obj -> {tmpname}) {
	unlink ($vf_obj -> {tmpname}) if (-f $vf_obj->{tmpname});
	undef $vf_obj -> {tmpname};
    }
    undef $vf_obj -> {subj_path};
    undef $vf_obj -> {filetype};
    undef $vf_obj -> {plugin};
}

1;

__END__

=head1 BUGS

The plugin filters don't report errors to WebLog.pm.

=head1 SEE ALSO

L<OnSearch(3)>

=cut

