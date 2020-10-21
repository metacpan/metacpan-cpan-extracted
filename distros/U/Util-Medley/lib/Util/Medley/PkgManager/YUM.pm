package Util::Medley::PkgManager::YUM;
$Util::Medley::PkgManager::YUM::VERSION = '0.051';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Kavorka 'method', 'multi';
use English;

with
  'Util::Medley::Roles::Attributes::Spawn',
  'Util::Medley::Roles::Attributes::String';

=head1 NAME

Util::Medley::PkgManager::YUM - Class for interacting with YUM

=head1 VERSION

version 0.051

=cut

=head1 SYNOPSIS

  my $yum = Util::Medley::Yum->new;
  
  #
  # positional  
  #
  $aref = $yum->repoList([$enabled], [$disabled]);
                        
  #
  # named pair
  #
  $aref = $yum->repoList([enabled  => 0|1],
                         [disabled => 0|1]); 
  
  $aref = $yum->repoQuery ([all       => 0|1],
                           [installed => 0|1],
                           [repoId    => $repoId]);
=cut

########################################################

=head1 DESCRIPTION

A simple wrapper library for YUM on Linux.  

=cut

########################################################

=head1 ATTRIBUTES

none

=head1 METHODS

=head2 repoList

Generates a list of configured YUM repositories.

Returns: ArrayRef[HashRef]

Example HashRef:

  {
    repoBaseurl   "http://centos3.zswap.net/7.8.2003/updates/x86_64/ (9 more)",
    repoExpire    "21,600 second(s) (last: Tue Oct 13 12:14:28 2020)",
    repoId        "updates/7/x86_64",
    repoMirrors   "http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=updates&infra=vag",
    repoName      "CentOS-7 - Updates",
    repoPkgs      "1,104",
    repoSize      "5.4 G",
    repoStatus    "enabled",
    repoUpdated   "Mon Sep 14 08:18:15 2020"
  }

=over

=item usage:

 $aref = $yum->repoList([$enabled], [$disabled]);

 $aref = $yum->repoList([enabled => 1],
                        [disabled => 0]);
 
=item args:

=over

=item enabled [Bool] (optional)

Flag indicating the returned list should include enabled repos.

Default: 1

=item disabled [Bool] (optional)

Flag indicating the returned list should include disabled repos.

Default: 0

=back

=back

=cut

multi method repoList( Bool :$enabled = 1, Bool :$disabled = 0 ) {

	my @cmd = ( 'yum', 'repolist', '-v', 'all' );

	my ( $stdout, $stderr, $exit ) =
	  $self->Spawn->capture( cmd => \@cmd, wantArrayRef => 1 );
	if ($exit) {
		confess $stderr;
	}

	my @repos;
	my $repoHref;
    my $cnt = 0;
    
	foreach my $line (@$stdout) {

		next if $self->String->isBlank($line);

		if ( $line =~ /^Repo-\w+\s/ ) {
			
			my ( $key, $value ) = $self->_repoListParseLine($line);
			
			if ( $key eq 'repoId' ) {
				if ($cnt > 0) {
				    push @repos, $repoHref;
				}
			     		
				$value = $self->_parseRepoId($value);
				$repoHref = {};
				$cnt++;
			}

			$repoHref->{$key} = $value;
		}
	}

	if ( $cnt > 0 ) {#$repoHref->{repoId} ) {
		push @repos, $repoHref;
	}

	###

	my $reposAref = [];

	foreach my $repo (@repos) {
		my $status = $repo->{repoStatus};
		if ( $status eq 'enabled' ) {
			push @$reposAref, $repo if $enabled;
		}
		elsif ( $status eq 'disabled' ) {
			push @$reposAref, $repo if $disabled;
		}
		else {
			confess "unhandled repoStatus: $status";
		}
	}

	return $reposAref;
}

multi method repoList( Bool $enabled, Bool $disabled) {

	my %a;
	$a{enabled}  = $enabled  if defined $enabled;
	$a{disabled} = $disabled if defined $disabled;

	return $self->repoList(%a);
}

=head2 repoQuery

Captures the output from the 'repoquery' command.

Returns: ArrayRef[Str]

=over

=item usage:

  $aref = $yum->repoQuery ([all       => 0|1],
                           [installed => 0|1],
                           [repoId    => $repoId]);

 Positional params not supported for this method due to
 the volume of options.
  
=item args:

=over

=item all [Bool] (optional)

Equivalent to the --all flag on the cli.

Default: 0

=item installed [Bool] (optional)

Equivalent to the --installed flag on the cli.

Default: 0

=item repoId [Str] (optional) 

Equivalent to the --repoid option on the cli.

=back

=back

=cut

method repoQuery (Bool :$all,
                  Bool :$installed,
                  Str  :$repoId) {

	my @cmd = ('repoquery');
	push @cmd, '--all'       if $all;
	push @cmd, '--installed' if $installed;
	push @cmd, '--repoid', $repoId if $repoId;

	my ( $stdout, $stderr, $exit ) =
	  $self->Spawn->capture( cmd => \@cmd, wantArrayRef => 1 );
	if ($exit) {
		confess $stderr;
	}

	return $stdout;
}

=head2 list

Captures the output from the 'yum list' command.

Returns: ArrayRef[Str] or ArrayRef[HashRef]

=over

=item usage:

  $aref = $yum->list ([installed => 0|1],
                      [repoId    => $repoId]);

 Positional params not supported for this method due to
 the volume of options.
  
=item args:

=over

=item installed [Bool] (optional)

List only installed packages.

Default: 0

=item repoId [Str] (optional) 

Limit the listing to this repo.  This leverages 'repository-packages' under the
hood.

=item useSudo [Bool] (optional)

If a repoId is provided and your running under a user other than root, 
you must use sudo privileges in order to run "yum repo-pkgs".  Must be due to
some "feature" I am not privy to.

=item parseOutput [Bool] (optional) 

Indicates the caller wants the output parsed and put into a hashref.

=back

=back

=cut

method list (Bool :$installed,
             Str  :$repoId,
             Bool :$useSudo,
             Bool :$parseOutput) {

	my @cmd;
	push @cmd, 'sudo' if $useSudo;
	push @cmd, 'yum';
	push @cmd, '--quiet';
	push @cmd, '--color', 'never';
	push @cmd, 'repo-pkgs', $repoId
	  if $repoId;    # this requires root/sudo for some reason
	push @cmd, 'list';
	push @cmd, 'installed' if $installed;

	my ( $stdout, $stderr, $exit ) =
	  $self->Spawn->capture( cmd => \@cmd, wantArrayRef => 1 );
	if ($exit) {
		confess $stderr;
	}
   
    my $cleansed  = $self->_cleanseListOutput($stdout);
   
    if ($parseOutput) { 
    	
        my @parsed;
        foreach my $line (@$cleansed) {
        
            my ($rpmName, $version, $repo) = split /\s+/, $line;	
            my $href = {
        	   rpmName => $rpmName,
        	   version => $version,
        	   repo    => $repo
            };
            
            push @parsed, $line;
        }
    
	    return \@parsed;
    }
    
    return $cleansed;
}

#################################################################3

method _parseRepoId (Str $value) {

	#
	# from 'man yum'
	#
	#    In  non-verbose mode the first column will start with a ´*´ if the
	#    repo. has metalink data and the latest metadata is not local and
	#    will start with a ´!´ if the repo. has metadata that is expired. For
	#    non-verbose mode the last column will also display the number of
	#    packages in the repo. and (if there are any user specified excludes)
	#    the number of packages excluded.
	#
	$value =~ s/^[!\*]//;

	#
	# from 'man yum.conf'
	#
	#    ui_repoid_vars:  When a repository id is displayed, append these yum
	#                     variables to the string if they are used in the
	#                     baseurl/etc. Variables are appended in the order
	#                     listed (and found).  Default is 'releasever basearch'.
	#
	my ($repoId) = split( /\//, $value );

	return $repoId;
}

method _repoListParseLine (Str $line) {

	my ( $key, @value ) = split( /:/, $line );

	$key = $self->String->trim($key);
	$key = $self->String->camelize($key);

	my $value = join ':', @value;
	$value = $self->String->trim($value);

	return ( $key, $value );
}

#
# this method removes the header line ("...... packages") and joins 
# broken lines.
#
method _cleanseListOutput (ArrayRef $list) {

    my @clean;
    my $prev;
     
    foreach my $line (@$list) {
    	
        next if $line =~ /^\w+ packages$/i;
        
        my ($rpmName, $version, $repo) = split /\s+/, $line;    
        if ($rpmName) {
            if (defined $version) {
            	if ($repo) {
            		# happy path
                    push @clean, $line;	
                    next;
            	}
            }
        }         	
        else {
        	# join with prev line
        	my $joined = join '  ', $prev, $self->String->trim($line);
            $joined =~ s/\s\s+/  /g;	
            
   	        my ($rpmName, $version, $repo) = split /\s+/, $joined;
            if ($rpmName and defined $version and $repo) {
            	# happy path
                push @clean, $joined;
            }    	
            else {
                confess "unable to join output lines: $joined";	
            }
        }
        
        $prev = $line;
    }	
    
    return \@clean;
}

1;
