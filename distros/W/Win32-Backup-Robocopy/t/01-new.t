#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Capture::Tiny qw(capture);

# use ok
use_ok( 'Win32::Backup::Robocopy' ) || print "Bail out!\n";  

note( "Testing Win32::Backup::Robocopy with Perl $]" ); 
# show version of used modules
map{ note( join ' ',$_,($_->VERSION // '?' ) ) }
	'Win32::Backup::Robocopy',
	'Carp',
	'File::Spec',
	'File::Path',
	'JSON::PP',
	'Capture::Tiny',
	'Time::Piece',
	'Algorithm::Cron',
;

# object of proper class
isa_ok( Win32::Backup::Robocopy->new( name => 'zero', source =>'X:/'), 'Win32::Backup::Robocopy' );

###################
# testing RUN mode
###################

note('testing RUN mode instantiation');

# module has sane defaults while in RUN mode
my $bkp = Win32::Backup::Robocopy->new( name => 'test', src	=> 'x:/', );
ok ($bkp->{dst} eq File::Spec->rel2abs( '.' ),'default destination');

# in the RUN mode no job entry is present
ok (! exists $bkp->{jobs}, 'no jobs entry exists in main object while in RUN mode');
 
# RUN mode does not permit to add job
dies_ok { $bkp->job } 'job method is expected to die while in RUN mode';

# warning if source does not exists
my ($out, $err, @res) = capture { 
						my $nobkp = Win32::Backup::Robocopy->new( 
						name => 'warning',
						src => File::Spec->catdir ( Win32::GetNextAvailDrive(),'' ),
						dst	 => '.') 
};
ok( $err =~ /backup source .* does not exists!/, 'new emits a warning about not existent source');


###################
# testing JOB mode
###################

note('testing JOB mode instantiation');

# the JOB type of instantiation
$bkp = Win32::Backup::Robocopy->new( conf => './empty_conf.txt' );

# JOB mode does not permit to run
dies_ok { $bkp->run } 'run method is expected to die while in JOB mode';

# JOB mode instantiate an empty queue
ok (ref $bkp->{jobs} eq 'ARRAY','JOB mode instantiate an empty jobs queue');

# in job mode no name is present
ok (! exists $bkp->{name}, 'no name entry exists in main object while in JOB mode');

# in job mode no src is present
ok (! exists $bkp->{src}, 'no source entry exists in main object while in JOB mode');

# in job mode no dst is present
ok (! exists $bkp->{dst}, 'no destination entry exists in main object while in JOB mode');

# in job mode no history is present
ok (! exists $bkp->{history}, 'no history entry exists in main object while in JOB mode');


###################
# testing deep recurse
###################

note('testing arguments against deep recursion');

# warn if dst and src are equal
($out, $err, @res) = capture { Win32::Backup::Robocopy->new( name => 'equal', src => '.', dst => '.' ) };
like ($err, qr/^SRC and DST are equal! This might be not what you intended./,
	"warning expected when source and destination are equal");

	
# warn if dst and src are equal (case insensitive and different path separator)
($out, $err, @res) = capture { Win32::Backup::Robocopy->new( name => 'equal', src => 'c:\\', dst => 'C:/' ) };
like ($err, qr/^SRC and DST are equal! This might be not what you intended./,
	"warning expected when source and destination are equal (case insensitive)");

# die if dst is under src
dies_ok { Win32::Backup::Robocopy->new( name => 'deep', src => '.', dst => './a' ) } 
		'expecting to die if destination is under source';
# die if dst is under src
dies_ok { Win32::Backup::Robocopy->new( name => 'deep', src => '.', dst => './a/b' ) } 
		'expecting to die if destination is deeply under source';

done_testing();
