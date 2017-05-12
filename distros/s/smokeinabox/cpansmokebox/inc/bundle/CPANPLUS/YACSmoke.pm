package CPANPLUS::YACSmoke;

use strict;
use warnings;

use Carp;
use CPANPLUS::Backend;
use CPANPLUS::Configure;
use CPANPLUS::Error;
use CPANPLUS::Internals::Constants;
use POSIX qw( O_CREAT O_RDWR O_RDONLY );         # for SDBM_File
use SDBM_File;
use File::Fetch;
use IO::File;
use File::Spec::Functions;
use File::Path;
use Regexp::Assemble;
use Sort::Versions;
use Config::IniFiles;

use vars qw($VERSION);

use constant DATABASE_FILE => 'cpansmoke.dat';
use constant CONFIG_FILE   => 'cpansmoke.ini';
use constant RECENT_FILE   => 'RECENT';

require Exporter;

our @ISA = qw( Exporter );
our %EXPORT_TAGS = (
  'all'      => [ qw( mark test excluded purge flush reindex) ],
  'default'  => [ qw( mark test excluded ) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = ( @{ $EXPORT_TAGS{'default'} } );

$VERSION = '0.58';

{
  my %Checked;
  my $TiedObj;


sub _connect_db {
  my $self = shift;
  return if $TiedObj;
  my $filename = catfile( $self->{conf}->get_conf('base'), DATABASE_FILE );
  $TiedObj = tie %Checked, 'SDBM_File', $filename, O_CREAT|O_RDWR, 0644;
  $self->{checked} = \%Checked;
}

sub _disconnect_db {
  my $self = shift;
  return unless $TiedObj;
  $TiedObj         = undef;
  $self->{checked} = undef;
  untie %Checked;
}

sub new {
  my $package = shift;
  my $nconf = shift if ref $_[0] and $_[0]->isa('CPANPLUS::Configure');

  $ENV{AUTOMATED_TESTING} = 1;
  $ENV{PERL_MM_USE_DEFAULT} = 1; # despite verbose setting
  $ENV{PERL_EXTUTILS_AUTOINSTALL} = '--defaultdeps';

  my $conf = $nconf || CPANPLUS::Configure->new();

  # Override configure settings
  $conf->set_conf( prereqs => 2 ); # force to ask callback
  $conf->set_conf( skiptest => 0 ); 
  $conf->set_conf( no_update => 1 )
    if glob( catfile( $conf->get_conf('base'), $conf->_get_source('stored') .'*'. STORABLE_EXT, ) );
  $conf->set_conf( dist_type => 'CPANPLUS::Dist::YACSmoke' ); # this is where the magic happens.
  $conf->set_conf( cpantest => 'dont_cc' ); # Yes, we want to report test results. But not CC
  $conf->set_conf( verbose => 1 ); # set verbosity to true.

  unless ( defined $ENV{MAILDOMAIN} ) {
     my $hostpart = ( split /\@/, ( $conf->get_conf( 'email' ) || 'smoker@cpantesters.org' ) )[1];
     $ENV{MAILDOMAIN} = $hostpart =~ /^(cpan\.org|gmail\.com)$/i ? 'cpantesters.org' : $hostpart;
  }

  if ( $^V gt v5.9.5 ) {
     $conf->set_conf( prefer_makefile => 0 ); # Prefer Build.PL if we have M::B
  }
  else {
     eval "require Module::Build"; 
     $conf->set_conf( prefer_makefile => 0 ) unless $@; # 
  }

  my $cb   = CPANPLUS::Backend->new($conf);

  my $exclude_dists;
  my $config_file = catfile( $conf->get_conf('base'), CONFIG_FILE );
  if ( -r $config_file ) {
     my $cfg = Config::IniFiles->new(-file => $config_file);
     my @list = $cfg->val( 'CONFIG', 'exclude_dists' );
     if ( @list ) {
        $exclude_dists = Regexp::Assemble->new();
        $exclude_dists->add( @list );
     }
  }

  my $self = bless { @_ }, $package;
  $self->{conf} = $conf;
  $self->{cpanplus} = $cb;
  $self->{exclude_dists} = $exclude_dists;
  $self->{allow_retries} = 'aborted|ungraded';
  return $self;
}

sub test {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  $self ||= __PACKAGE__->new();
  $self->_connect_db();
  
  my @dists = @_;

  unless ( @dists ) {
     @dists = $self->_download_list();
  }

  my @mods;

  foreach my $dist ( @dists ) {
     my $mod = $self->{cpanplus}->parse_module( module => $dist );
     next unless $mod;
     my $package = $mod->package_name .'-'. $mod->package_version;
     my $grade = $self->{checked}->{$package} || 'ungraded';
     next if $self->_is_excluded_dist($package);
     next if $mod->is_bundle;
     next unless $grade =~ /$self->{allow_retries}/;
     push @mods, $mod;
  }

  $self->_disconnect_db();

  foreach my $mod ( @mods ) {
     eval {
		CPANPLUS::Error->flush();
		my $stat = $self->{cpanplus}->install( 
				modules  => [ $mod ],
				target   => 'create',
				allow_build_interactively => 0,
				# other settings now set via set_config() method
		);
     };
  }

  $self->{cpanplus}->save_state();
  return 1;
}

sub mark {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  $self ||= __PACKAGE__->new();
  $self->_connect_db();

  my $distver = shift || '';
  my $grade   = lc shift || '';

  if ($grade) {
    my $mod = $self->{cpanplus}->parse_module( module => $distver );
    return error(qq{Invalid distribution "$distver"}) unless $mod;
    
    unless ($grade =~ /(pass|fail|unknown|na|none|ungraded|aborted|ignored)/) {
      return error("Invalid grade: '$grade'");
    }
    if ($grade eq "none") {
      $grade = undef;
    }

    $distver = $mod->package_name .'-'. $mod->package_version;
    $self->{checked}->{$distver} = $grade;
  }
  else {
    my @distros = ($distver ? ($distver) : $self->_download_list());
    foreach my $dist ( @distros ) {
       my $mod = $self->{cpanplus}->parse_module( module => $dist );
       next unless $mod;
       my $dist_ver = $mod->package_name .'-'. $mod->package_version;
       next if $self->_is_excluded_dist( $dist_ver );
       $grade = $self->{checked}->{$dist_ver};
       if ( $grade ) {
	 msg(qq{result for "$dist_ver" is "$grade"});
       }
       else {
	 msg(qq{no result for "$dist_ver"});
       }
    }
  }
  $self->_disconnect_db();
  return $grade if $distver;
}

sub excluded {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  $self ||= __PACKAGE__->new();

  my @dists = @_;

  unless ( @dists ) {
     @dists = $self->_download_list();
  }

  my @mods;

  foreach my $dist ( @dists ) {
     my $mod = $self->{cpanplus}->parse_module( module => $dist );
     next unless $mod;
     my $package = $mod->package_name .'-'. $mod->package_version;
     next unless $self->_is_excluded_dist($package);
     msg(qq{EXCLUDED: "$package"});
     push @mods, $package;
  }

  return @mods;
}

sub purge {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  $self ||= __PACKAGE__->new();
  my %config = ref($_[0]) eq 'HASH' ? %{ shift() } : ();
  $self->_connect_db();

  my $flush = $config{flush_flag} || 0;
  my %distvars;
  my $override = 0;

  if(@_) {
     $override = 1;
     for(@_) {
	next	unless(/^(.*)\-(.+)$/);
	push @{$distvars{$1}}, $2;
     }
  } 
  else {
     for(keys %{$self->{checked}}) {
	next	unless(/^(.*)\-(.+)$/);
	push @{$distvars{$1}}, $2;
     }
  }

  foreach my $dist (sort keys %distvars) {
     my $passed = $override;
     my @vers = sort { versioncmp($a, $b) } @{$distvars{$dist}};
     while(@vers) {
	my $vers = pop @vers;		# the latest
	if($passed) {
		msg("'$dist-$vers' ['".
					uc($self->{checked}->{"$dist-$vers"}).
					"'] has been purged");
		delete $self->{checked}->{"$dist-$vers"};
		if($flush) {
	          my $builddir =
                      catfile($self->_get_build_dir(), "$dist-$vers");
		      rmtree($builddir)	if(-d $builddir);
		}
	}
	elsif($self->{checked}->{"$dist-$vers"} eq 'pass') {
		$passed = 1;
	}
     }
  }

  $self->_disconnect_db();
  return 1;
}

sub flush {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  $self ||= __PACKAGE__->new();
  my %config = ref($_[0]) eq 'HASH' ? %{ shift() } : ();
  $self->_connect_db();

  my $param = shift || 'all';

  my $build_dir = $self->_get_build_dir();

  if ( $param eq 'old' ) {
    my %dists;
    opendir(my $DIR, $build_dir);
    while(my $dir = readdir($DIR)) {
	    next if $dir =~ /^\.+$/;
		  $dir =~ /(.*)-(.+)/;
		  $dists{$1}->{$2} = "$dir";
	  } 
    closedir($DIR);
	  for my $dist (keys %dists) {
	    for(sort { versioncmp($a, $b) } keys %{$dists{$dist}}) {
	      rmtree(catfile($build_dir,$dists{$dist}->{$_}));
		    msg("'$dists{$dist}->{$_}' flushed");
	    }
	  }
  }
	else {
		msg("Flushing '$build_dir'");
		rmtree($build_dir);
		msg("Flushed '$build_dir'");
	}

  $self->_disconnect_db();
  return 1;
}

sub reindex {
  my $self;
  eval {
    if ( (ref $_[0]) && $_[0]->isa(__PACKAGE__) ) {
	$self = shift;
    }
  };
  $self ||= __PACKAGE__->new();
  $self->{conf}->set_conf( no_update => 0 );
  $self->{cpanplus}->reload_indices( update_source => 1 );
  $self->{conf}->set_conf( no_update => 1 )
    if glob( catfile( $self->{conf}->get_conf('base'), $self->{conf}->_get_source('stored') .'*'. STORABLE_EXT, ) );
  return 1;
}

sub _is_excluded_dist {
  my $self = shift;
  my $dist = shift || return;
  return unless $self->{exclude_dists};
  return 1 if $dist =~ $self->{exclude_dists}->re();
}

sub _download_list {
  my $self  = shift;

  my $path  = $self->{conf}->get_conf('base');
  my $local = catfile( $path, RECENT_FILE );

  my $hosts = $self->{conf}->get_conf('hosts');
  my $h_ind = 0;

  while ($h_ind < @$hosts) {
      my $remote = $hosts->[$h_ind]->{scheme} . '://'
                . catdir(
                        $hosts->[$h_ind]->{host},
                        $hosts->[$h_ind]->{path} . RECENT_FILE );

      my $ff = File::Fetch->new( uri => $remote );
      my $status = $ff->fetch( to => $path );
      last if $status;
      $h_ind++;
  }

  return ()   if(@$hosts == $h_ind); # no host accessible

  my @testlist;
  my $fh = IO::File->new($local)
    or croak("Cannot access local RECENT file [$local]: $!\n");
  while (<$fh>) {
    next    unless(/^authors/);
    next    unless(/\.(?:tar\.(?:bz2|gz|Z)|t(?:gz|bz)|(?<!ppm\.)zip|pm.gz)\n$/i);
    s!authors/id/!!;
    chomp;
    push @testlist, $_;
  }

  return @testlist;
}

sub _get_build_dir {
  my $self = shift;
  File::Spec->catdir(
        $self->{conf}->get_conf('base'),
        $self->{cpanplus}->_perl_version( perl => $^X ),
        $self->{conf}->_get_build('moddir')
  );
}

}

1;
__END__

=head1 NAME

CPANPLUS::YACSmoke - Yet Another CPANPLUS Smoke Tester

=head1 SYNOPSIS

  perl -MCPANPLUS::YACSmoke -e test

=head1 DESCRIPTION

CPANPLUS::YACSmoke is an enhancement of the venerable L<CPAN::YACSmoke> that uses the API backend of L<CPANPLUS>
to run tests on CPAN modules and post results to the CPAN Testers list.

L<CPANPLUS::Dist::YACSmoke> is loaded into the L<CPANPLUS> configuration before any modules are tested.

It will create a database file in the F<.cpanplus> directory, which it
uses to track tested distributions.  This information will be used to
keep from posting multiple reports for the same module, and to keep
from testing modules that use non-passing modules as prerequisites.

If C<prereqs> have been tested previously and have resulted in a C<pass> grade then the tests for those 
C<prereqs> will be skipped, speeding up smoke testing.

By default it uses L<CPANPLUS> configuration settings.

=head1 CONFIGURATION FILE

CPANPLUS::YACSmoke only honours the C<exclude_dists> in L<CPAN::YACSmoke> style C<ini> files.

The C<exclude_dists> setting, which is laid out as:

  [CONFIG]
  exclude_dists=<<HERE
  mod_perl
  HERE

The above would then ignore any distribution that includes the string
'mod_perl' in its name. This is useful for distributions which use
external C libraries, which are not installed, or for which testing
is problematic.

See L<Config::IniFiles> for more information on the INI file format.

=head1 PROCEDURAL INTERFACE

=head2 EXPORTS

The following routines are exported by default.  They are intended to
be called from the command-line, though they could be used from a
script.

=over

=item test( [ $dist [, $dist .... ] ] )

  perl -MCPANPLUS::YACSmoke -e test

  perl -MCPANPLUS::YACSmoke -e test('R/RR/RRWO/Some-Dist-0.01.tar.gz')

Runs tests on CPAN distributions. Arguments should be paths of
individual distributions in the author directories.  If no arguments
are given, it will download the F<RECENT> file from CPAN and use that.

By default it uses CPANPLUS configuration settings. If CPANPLUS is set
not to send test reports, then it will not send test reports.

=item mark( $dist [, $grade ] ] )

  perl -MCPANPLUS::YACSmoke -e mark('Some-Dist-0.01')

  perl -MCPANPLUS::YACSmoke -e mark('Some-Dist-0.01', 'fail')

Retrieves the test result in the database, or changes the test result.

It can be useful to update the status of a distribution that once
failed or was untestable but now works, so as to test modules which
make use of it.

Grades can be one of (case insensitive):

  aborted  = tests aborted (uninstallable prereqs or other failure in test)
  pass     = passed tests
  fail     = failed tests
  unknown  = no tests available
  na       = not applicable to platform or installed libraries
  ungraded = no grade (test possibly aborted by user)
  none     = undefines a grade
  ignored  = package was ignored (a newer version was tested)

=item excluded( [ $dist [, $dist ... ] ] )

  perl -MCPANPLUS::YACSmoke -e excluded('Some-Dist-0.01')

  perl -MCPANPLUS::YACSmoke -e excluded()

Given a list of distributions, indicates which ones would be excluded from
testing, based on the exclude_dist list that is created.

=item purge( [ \%config, ] [ $dist [, $dist ... ] ] )

  perl -MCPANPLUS::YACSmoke -e purge()

  perl -MCPANPLUS::YACSmoke -e purge('Some-Dist-0.01')

Purges the entries from the local cpansmoke database. The criteria for purging
is that a distribution must have a more recent version, which has previously
been marked as a PASS. However, if one or more distributions are passed as a
parameter list, those specific distributions will be purged.

If the flush_flag is set, via the config hashref, to a true value, the directory 
path created for each older copy of a distribution is deleted.

=item flush( [ 'all' | 'old' ]  )

  perl -MCPAN::YACSmoke -e flush()
  
  perl -MCPAN::YACSmoke -e flush('all')

  perl -MCPAN::YACSmoke -e flush('old')

Removes unrequired build directories from the designated CPANPLUS build
directory. Note that this deletes directories regardless of whether the 
associated distribution was tested.

Default flush is 'all'. The 'old' option will only delete the older 
distributions, of multiple instances of a distribution.

Note that this cannot be done reliably using last access or modify time, as
the intention is for this distribution to be used on any OS that CPANPLUS
is installed on. In this case not all OSs support the full range of return
values from the stat function.

=item reindex

Make L<CPANPLUS> reload its indices.

=back

=head1 OBJECT INTERFACE

Each of the procedural interface functions are available as methods of a CPANPLUS::YACSmoke object.

=over

=item C<new>

The object interface is created normally through the test() or mark() functions of the procedural interface. 

=back 

=head1 ENVIRONMENT VARIABLES

The following environment variables affect the operation of this module:

=over

=item C<PERL5_YACSMOKE_BASE>

Loaded into L<CPANPLUS> by L<CPANPLUS::Config::YACSmoke>, sets the basedir where L<CPANPLUS> and
CPANPLUS::YACSmoke related modules find the C<.cpanplus> directory for their settings

  export PERL5_YACSMOKE_BASE=/home/moo/perls/conf/perl-5.8.9/

Would set the base dir to C</home/moo/perls/conf/perl-5.8.9/.cpanplus/>

=back

Several environment variables get set by the module:

=over

=item C<AUTOMATED_TESTING>

Set to 1 to indicate that we are currently running in an automated testing environment

=item C<PERL_MM_USE_DEFAULT>

Set to 1 MakeMaker and Module::Build's prompt functions will always return the default 
without waiting for user input.

=item C<MAILDOMAIN>

L<Test::Reporter> uses this. YACSmoke will set this if it isn't already set. It will try to determine
the domain from the C<email> setting in L<CPANPLUS>. If this is C<cpan.org> it will default to 
C<cpantesters.org> ( the perl.org MX doesn't like people trying to impersonate it, for obvious reasons ).

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

Based on L<CPAN::YACSmoke> by Robert Rothenberg and Barbie.

Contributions and patience from Jos Boumans the L<CPANPLUS> guy!

=head1 LICENSE

Copyright E<copy> Chris Williams, Jos Boumans, Robert Rothenberg and Barbie.

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<CPANPLUS>

L<CPANPLUS::Dist::YACSmoke>

L<CPANPLUS::Config::YACSmoke>

L<CPAN::YACSmoke>

L<Test::Reporter>

=cut
