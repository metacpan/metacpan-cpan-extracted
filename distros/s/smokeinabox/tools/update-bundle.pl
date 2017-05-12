use strict;
use Cwd;
use File::Path qw[mkpath];
use CPANPLUS::Backend;

$|++;

my $Prefix      = '../';           # updir from cpanplus/devel 
my $Libdir      = 'lib/';
my $Cwd         = cwd();
my $Target      = $Cwd . '/cpansmokebox/inc/bundle';    # Target dir to copy to
my $MineOnly    = @ARGV ? 1 : 0;
my $Conf        = CPANPLUS::Configure->new();
$Conf->set_conf( enable_custom_sources => 0 );
$Conf->set_conf( verbose => 1 );
$Conf->set_conf( hosts => [ { scheme => 'ftp', host => 'localhost', path => '/CPAN/' } ] );
$Conf->set_conf( no_update => 1 );
$Conf->set_conf( source_engine => 'CPANPLUS::Internals::Source::CPANIDX' );
my $CB          = CPANPLUS::Backend->new( $Conf );

### from p4 
{   my @Copy    = qw[
    ];

    for my $entry (@Copy) {
        my $dir = $Prefix . $entry . $Libdir;
        
        print "Copying files from $entry...";
        system("cp -R $dir $Target");
        print "done\n";
    }
}



### from installations 
unless( $MineOnly ) {  
    my @Modules = qw[
        Archive::Extract
        Archive::Tar
        File::Fetch
        IPC::Cmd
        Log::Message
        Log::Message::Simple
        Module::Load
        Module::Loaded
        Module::Load::Conditional
        Object::Accessor
        Package::Constants
        Params::Check
        Term::UI
        File::Spec
        IO::String
        IO::Zlib
        Locale::Maketext::Simple
        Module::CoreList
        Module::Pluggable
        version
        Parse::CPAN::Meta
        Config::IniFiles
        Sort::Versions
        Regexp::Assemble
        Test::Reporter
        CPANPLUS::YACSmoke
    ];
    
    # IPC::Run no more!
    
    UPDATE: for my $module ( @Modules ) {

        my $obj = $CB->module_tree( $module );

        ### do an uptodate check
        {   local @INC = ( $Target );

            print   "Updating $module..." .
                    "[HAVE: " . $obj->installed_version   .'] ' .
                    "[CPAN: " . $obj->version             .'] ';

            if( $obj->is_uptodate ) {
                print "already uptodate\n";
                      
                next UPDATE;
            }
        }

        $obj->fetch( fetchdir => '/tmp' )   or die "Could not fetch";
        my $dir = $obj->extract( extractdir => '/tmp' )  
                                            or die "Could not extract";
       
        ### either they have the lib structure
        if( -d $dir . "/lib" ) {
            chdir $dir . "/lib" or die "Could not chdir: $!";
            system("cp -R . $Target") and die "Could not copy files";


            ### XXX special case -- version.pm has Special Dirs :(
            ### need the 'vperl/vpp.pm' file too
            if( $module eq 'version' ) {
                system("cp ../vperl/vpp.pm $Target/version/")
                    and die "Could not copy special files for $module";
            }
            
            print "done\n";
            next UPDATE;
        } 

        ### ok, so no libdir... let's see if they have just the pm in
        ### the topdir
        chdir $dir or die "Could not chdir to $dir: $!";
        
        my @parts = split '::', $module;
        my $file = pop(@parts) . '.pm';
        if ( -e $file ) {
            my $tdir = $Target . '/' . join '/', @parts;
            mkpath($tdir) unless -d $tdir;
        
            my $to =  join '/', $tdir, $file;
            system("cp $file $to") and die "Could not copy $file to $to: $!\n";
            
            print "done\n";
            next UPDATE;
        }
        
        die "Dont know how to copy $module from $dir\n";
        
    }        
}        
        

# 
# ### set all the versions to -1
# if(0) {
#     for my $file ( map { chomp; $_ } `find $Target -type f` ) {
#         system( "p4 edit $file" );
#     
#         my $code = q[s/(\$|:)VERSION\s*=.+$/${1}VERSION = "-1";/];
# 
#         my $cmd  = qq[$^X -pi -e'$code'];
#         print "Running [$cmd $file]\n";
# 
#         system( "$cmd $file" );
#     }        
# }

### revert all that wasn't touched
chdir $Cwd or die "Could not chdir back!";
exit 0;
#system("find $Target -type f | xargs svk add");
#system("svk diff | less");
#system("svk commit");

