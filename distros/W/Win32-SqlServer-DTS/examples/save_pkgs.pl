use warnings;
use strict;
use XML::Simple;
use Win32::SqlServer::DTS::Application;
use constant XML_FILE   => 'modify.xml';
use constant BACKUP_DIR => 'c:\\DTS-backup';
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use DateTime;
use Cwd;

# :WARNING:16/10/2007:ARFJr: there is an issue saving DTS packages using the API: all the DTS layout
# is lost during the convertion to structured files! There is no documented way to fix that.

my $xml_file = 'modify.xml';
my $xml      = XML::Simple->new();
my $config   = $xml->XMLin($xml_file);

my $app       = Win32::SqlServer::DTS::Application->new( $config->{credential} );
my $pkgs_list = [ $config->{package} ];
my $counter   = 0;

foreach my $pkg_name ( @{$pkgs_list} ) {

    my $pkg;

    print 'Saving ', $pkg_name, '... ';

    eval {
        $pkg = $app->get_db_package(
            { id => '', version_id => '', name => $pkg_name } );
    };

    if ($@) {

        warn $@, "\n";

    }
    else {

        $pkgs_list->[$counter] = $pkg_name . '.dts';

        $pkg->save_to_file( BACKUP_DIR, $pkgs_list->[$counter] );
        print 'done.', "\n";
        $counter++;

    }

}

pack_files($pkgs_list);

###################################
# SUBS
###################################

sub pack_files {

    my $pkg_list = shift;
    my $zip      = Archive::Zip->new();

    my $old_path = getcwd();

# :TRICKY:10/10/2007:ARFJr: there are issues using complete pathnames with addFile method
    chdir(BACKUP_DIR);

    foreach my $file ( @{$pkg_list} ) {

        $zip->addFile($file);

    }

    die "Could not create the ZIP file: $!\n"
      unless ( $zip->writeToFileNamed( get_backup_filename() ) == AZ_OK );

    foreach my $file ( @{$pkg_list} ) {

        unlink $file
          or warn "Cannot remove file $file in " . BACKUP_DIR . ': ' . "$!\n";

    }

    chdir($old_path);

}

sub get_backup_filename {

    my $today = DateTime->now();

    return $today->year()
      . $today->month()
      . $today->day()
      . $today->hour()
      . $today->minute()
      . $today->second() . '.zip';

}
