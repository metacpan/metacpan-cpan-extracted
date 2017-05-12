# $Id$
# Copyright 2010 Pedro Paixao (paixaop at gmail dot com)
#
package WWW::Salesforce::Report;

use warnings;
use strict;

# CPAN and external modules
use HTTP::Cookies;
use HTTP::Headers;
use HTTP::Request::Common;
use LWP::UserAgent;
use Digest::MD5;
use IO::Compress::Zip qw(zip $ZipError :constants);
use DBI;
use Carp;

=pod

=head1 NAME

WWW::Salesforce::Report - The poor man's Salesforce report API in Perl!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Create a rough API for Salesforce.com reports. Reports are downloaded in CSV
format from Salesforce and can then be cached locally in a SQLite database.
Regular SQL queries can then be ran on the data.

The reports can also be downloaded in Excel format, which will not be
cache in a local database but can be sent as an attachment to users for example.

Perhaps a little code snippet.

    use WWW::Salesforce::Report;

    my $sfr = WWW::Salesforce::Report->new(
                    id=> "000000068AxXd",
                    user=> "myuser",
                    password => "mypassword" );
        
    $sfr->login();
    $sfr->get_report();
    
    my @data = $sfr->query( query => "select * from report" );

Save a report to an Excel file

    use WWW::Salesforce::Report;

    $sfr = WWW::Salesforce::Report->new(
        id=> "000000068AxXd",
        user=> "myuser",
        password => "mypassword" );
        
    $sfr->login();
    my $xls_data = $sfr->get_report(format => "xls");
    my $name = $sfr->write(file=> "report.xls", compress => 0);

Attach a compressed version of the Excel report to an email and send it to a
user or group of users:

    use WWW::Salesforce::Report;
    use Net::SMTP::TLS;
    use Mime::Lite;
    
    $sfr = WWW::Salesforce::Report->new(
        id=> "000000068AxXd",
        user=> "myuser",
        password => "mypassword" );
        
    $sfr->login();
    my $xls_data = $sfr->get_report(format => "xls");
    my $name = $sfr->write(file=> "report.xls");
    
    # using TLS to send the e-mail
    my $mailer = new Net::SMTP::TLS(
        "mail.domain.com",
        Hello   => "mail.domain.com",
        Port    =>  25,
        User    => "my_user_name",
        Password=> "my_password");
    
    # email of the sender
    $mailer->mail("reports@domain.com");
    
    # email of the recipient
    $mailer->to("user@domain.com");
    
    $mailer->data;
    
    my $message = MIME::Lite->new(
            From    => "reports@domain.com",
            To      => "user@domain.com",
            Subject => "REPORT: Quarter Forecast by Region",
            Type    =>'multipart/mixed'
    );
    
    # Message body
    $message->attach(
            Type => "TEXT",
            Data => "Here are the latest forecast numbers.",
    );
    
    # Attach the zip file
    $message->attach(
            Type => "application/zip",
            Filename => $name,
            Path => $name,
            Encoding => "base64",
            Disposition => 'attachment',
    );  
    
    $mailer->datasend($message->as_string);
    
    $mailer->dataend;
    $mailer->quit;

=head1 DEPENDS

The WWW::Salesforce::Report depends on the following CPAN modules

=begin HTML

<ul>
    <li>HTTP::Cookies</li>
    <li>HTTP::Headers</li>
    <li>HTTP::Request::Common</li>
    <li>LWP::UserAgent</li>
    <li>Digest::MD5</li>
    <li>DBI</li>
    <li>Carp</li>
</ul>

=end HTML

=head1 METHODS

=head2 PUBLIC METHODS

This module uses a named paramter convetion. That means that all methods expect
to be called like

    $obj->method( param_name => value, param2_name => value_2 );
  
and not like

    $obj->method( value_1, value_2 );

=over

=item new( OPTIONS )

Class constructor. You must call new() before using the object, and manipulating
report data.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<Mandatory parameters:>

B<user> => user_name

B<password> => password

User name and password to login to Salesforce.com.

B<Optional parameters:>

B<id> => salesforce_id

Salesforce.com Id of the report you want to download. Please make sure this is a
valid report Id from Salesforce.com otherwise this module will fail.
You can get the Id from the Salesfoce.com URL that points to the report you want
to use with the script.
Although you can set the report ID using report_id() it is a best practice to set it
in the object constructor, and if you need to work with multiple reports create
different objects for each one.

B<format> => "csv"| "xls"

See L<format()>

B<verbose> => 0 | 1

If true a "lot" of debug or tracing messages will be printed.
Enabled by default.

B<convert_dates> => 0 | 1

If true convert dates from Salesforce.com format to SQLite format. Enabled by
default.

B<login_url> => URL

This must be a Salesforce.com direct login URL. See L<login>.
Defaults to:

    login_url => https://login.salesforce.com/?un=USER&pw=PASS

B<csv_report_url> => URL

Url to export the desired report as a CSV file.
Defaults to:

    csv_report_url => https://SERVER.salesforce.com/REPORTID?export=1&enc=UTF-8&xf=csv

B<xls_report_url> => URL

Url to export the desired report as a CSV file.
Defaults to:

    csv_report_url => https://SERVER.salesforce.com/REPORTID?export=1&enc=UTF-8&xf=xls

In the above URLs the words SERVER, USER and PASS represent the Salesforce.com
login server, user name and password.

Generally you do not need to supply your own URLs, these parameters are here
just to ensure future compatibility if Salesfroce.com changes them.

B<erase_db> => 0 | 1

If true the database file will be deleted and recreated anew. Defaults to 1.

B<allow_duplicates> => 0 | 1

If true the database will allow duplicate records. For every report line a
new field is added which equals the MD5 hash of said report line.
This is done because not all Salesforce reports may contain Salesforce.com IDs.
If you do not want duplicates in your database a UNIQUE index will be created on
the __hash field.
Defaults to 1, to allow duplicates.

B<primary_key_type> => sqlite_type

The type of the primary key. This must be a valid SQLite type. Defaults to TEXT.

B<primary_key> => name_of_primary_key

The name of the primary key. Defaults to __id

B<erase_reports_table> => 0 | 1

If true erase the reports table. Defaults to 1.
If the database already exists, it will not be created but you have the
opportunity of erasing all data in the reports table.

B<erase_notifications_table> => 0 | 1

If true erase the notifications table. Defaults to 0.
If the database already exists, it will not be created but you have the
opportunity of erasing all data in the notifications table.

B<clean_on_destroy> => 0 | 1

If true clean up local files when destroying object. Defauts to true (1)

=cut

sub new {
    my ($class, %options) = @_;
  
    my $self = {} ;
    $class = ref($class) || $class;
    bless ($self, $class);
    
    $self->{ ua }         = LWP::UserAgent->new;    # HTTP User Agent
    $self->{ cookie_jar } = HTTP::Cookies->new;     # Prepare the cookies
    
    # Let's fake a Internet Explorer Browser on Windows XP ;)
    $self->{ ua }->agent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)');

    # Should module pring verbose messages?
    $self->{ verbose } = 0;
    $self->{ verbose } = $options{ verbose }
        if( defined($options{ verbose })  );
        
    # Should Salesforce.com dates be converted to SQLite format?
    $self->{ convert_dates } = 1;
    $self->{ convert_dates } = $options{ convert_dates }
        if( defined($options{ convert_dates })  );
        
    # User provided a different login URL?
    if( defined($options{ login_url })  ) {
        $self->{ login_url } = $options{ login_url };
    } else {
        $self->{ login_url } = "https://login.salesforce.com/?un=USER&pw=PASS";
    }
    
    # User provided a different URL for the CSV format reports?
    if( defined($options{ csv_report_url })  ) {
        $self->{ csv_report_url } = $options{ csv_report_url };
    } else {
        $self->{ csv_report_url } =
            "https://SERVER.salesforce.com/REPORTID?export=1&enc=UTF-8&xf=csv";
    }
    
    # User provided a different URL for the XLS format reports?
    if( defined($options{ xls_report_url })  ) {
        $self->{ xls_report_url } = $options{ xls_report_url };
    } else {
        $self->{ xls_report_url } =
            "https://SERVER.salesforce.com/REPORTID?export=1&enc=UTF-8&xf=xls";
    }
    
    $self->{ id } = "";
    $self->{ file } = "";
    
    # File directive to read from a local file overrides the salesforce Id
    if( defined($options{ file }) ) {

        croak "Local file $options{ file } does not exist"
            if( !-e $options{ file } );

        $self->{ file } = $options{ file };

    }
    else {
        
        if( defined($options{ id })  ) {
            $self->{ id } = $options{ id };
        }
        else {
            croak 'You need to pass a "file" or "id" parameter to WWW::Salesforce::Report->new()';
        }

        if( defined($options{ user })  ) {
            $self->{ user } = $options{ user };
        } else {
            croak 'You need to pass a "user" parameter to WWW::Salesforce::Report->new()';
        }
        
        if( defined($options{ password })  ) {
            $self->{ password } = $options{ password };
        } else {
            croak 'You need to pass a "password" parameter to WWW::Salesforce::Report->new()';
        }
        
    }
    
    # Set default format to CSV, and do not update name
    $self->format( format => "csv" );
    if( defined($options{ format })  ) {
        $self->format( format => $options{ format } );
    }
    
    $self->{ cache } = 1;
    if( defined($options{ cache })  ) {
        $self->{ cache } = $options{ cache };
    }
    
    $self->{ pre_import_query } = "";
    if( defined($options{ pre_import_query })  ) {
        $self->{ pre_import_query } = $options{ pre_import_query };
    }
    
    $self->{ post_import_query } = "";
    if( defined($options{ post_import_query })  ) {
        $self->{ post_import_query } = $options{ post_import_query };
    }
    
    $self->{ erase_db } = 1
        if( !defined($self->{ erase_db }) );
    
    $self->{ allow_duplicates } = 1
        if( !defined($self->{ allow_duplicates }) );
        
    $self->{ primary_key_type } = "TEXT"
        if( !defined($self->{primary_key_type}) );
        
    $self->{ primary_key } = "__id"
        if( !defined($self->{primary_key}) );
        
    $self->{ erase_reports_table } = 1
        if( !defined($self->{ erase_reports_table }) );
        
    $self->{ erase_notifications_table } = 0
        if( !defined($self->{ erase_reports_table }) );
    
    $self->{ clean_on_destroy } = 1
        if( !defined($self->{ clean_on_destroy }) );
    
    croak "new() failed, neither file, id, or name were initialized"
        if( !$self->{ file } && !$self->{ id } && !$self->name );

    return $self;
}

=item login ( )

Login to Salesforce.com via the URL method, which includes the user's
credentials in a URL instead of the login form the user usually sees.

If successful returns 1, otherwise triggers an error.

The URL method of login is sort of a hack since it does not use an approved API
call. Unfortunately the fact that Salesforce.com does not have a report API
available we must use this method to get the report data.

As of this witting you can login to Salesforce.com directly, i.e.,
not using the Login page, by using the following URL:

   https://login.salesforce.com/?un=USER&pw=PASS

where C<USER> is the user name, and C<PASS> the user's password.

=cut

sub login {
    my ($self) = @_;
    
    croak "Please call new() before using the object\n" if( !$self );
    
    if( $self->{ file } ) {
        
        print "Reading report from local file. Salesforce.com login not needed\n"
            if( $self->{ verbose } );

        return 0;
        
    }
    
    my $usr_login = $self->{ login_url };
    $usr_login =~ s/USER/$self->{ user }/g;
    $usr_login =~ s/PASS/$self->{ password }/g;
    
    print "Attempt Salesforce.com login with: $self->{ user }\n"
        if( $self->{ verbose } );
    
    # Get the login page with user and password information
    my $res = $self->{ ua }->request(GET $usr_login);
    
    # Exit if we can't connect
    croak "Cannot get login page" if(!$res->is_success);
    
    # Check if we got the Activation page and inform the user
    # This is not a permanent error. All that needs to be done is access
    # Salesforce.com from a browser in the computer where the script is installed
    # and follow the Salesforce.com activation procedure
    if( $res->content =~/Challenge User/ ) {
        
        # we got the Challenge User page asking the user to verify the computer
        croak "This computer is not activated to access Salesforce.com.\n" .
              "Login to Salesforce.com from a browser on this computer " .
              "before using this script\n";

    }
    
    # Check if we got the login page again...
    croak "Cannot Login with user $self->{ user }\n"
        if( $res->content =~ /Login Page/ );
    
    # Extract the cookie information from the server response, and
    # save it in our "cookie jar"
    $self->{ cookie_jar }->extract_cookies($res);
    
    # Determine which server did we login to by checking the cookies
    # Replace the server name in the report urls so we can download them later
    foreach my $server (keys %{ $self->{ cookie_jar }->{ COOKIES } }) {
        
        if( $server =~ /(.+?)\.salesforce\.com/ ) {
            
            $server = $1;
            $self->{ csv_report_url } =~ s/SERVER/$server/g;
            $self->{ xls_report_url } =~ s/SERVER/$server/g;
            $self->{ url } =~ s/SERVER/$server/g;
            
            print "Login Successful on " . $server . ".salesforce.com\n"
                if( $self->{ verbose } );
            
            last;
        }
        
    }
    
    return 1;
}

=item login_server ( )

If the login was successful return the server to which the user logged on,
otherwise return 0.

    my $server;
    if( $sforce->login() ) {
        $server = $sforce->login_server();
    }
    
    print "Logged to : $server \n";

=cut

sub login_server {
    my ($self) = @_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );
    
    if( !$self->{ file } ) {
        
        foreach my $server (keys %{ $self->{ cookie_jar }->{ COOKIES } }) {
            if( $server =~ /(.+?)\.salesforce\.com/ ) {
                return $1;
            }
        }
    
    }
    
    print "Reading report from local file. Salesforce.com login_server not set.\n"
        if( $self->{ verbose } );
        
    return 0;
}

=item report_id( [id => salesforce_id] )

Set  or get the Salesforce.com Id of report you want to download.

    $sforce->report_id()                      # return the current Salesforce.com Id.
    $sforce->report_id( id=> salesforce_id )  # set the current Salesforce.com Id.

=cut

sub report_id {
    my ($self, %options) = @_;
    
    $options{ delete } = 1 if( !defined($options{ delete }) );
    
    if( $options{ id } ) {
        
        # If the id does not change just return and do nothing
        return $self->{ id }
            if( $self->{ id } eq $options{ id } );
        
        $self->{ id } = $options{ id };
        
        $self->_set_name( delete => $options{ delete } );
        
    }
    
    return $self->{ id };
}


=item name ( )

Get the name of the local cache file or database.

=cut

sub name {
    my ($self) = @_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );
    
    croak "Please pass a Salesforce.com Report Id, or local file,"
        . "to WWW::Salesforce::Report->new() or by calling the report_id() method.\n"
                if( !$self->{ id } && !$self->{ file } );
    
    return $self->{ name };
}

=item format( format => "csv" | "xls" )

Get or set the report format

B<format> => "csv"| "xls"

The report format. Possible values are C<"csv">, or C<"xls">.
As of this writing Salesforce.com only supports CSV and XLS formats
for exported reports.
Comma Separated Value (CSV) is the only format that can be cached to a local
SQLite database. If you set the local file, via the C<file> parameter to new(),
a local CSV file will be read from disk instead of downloading the report data
from Salesforce.com. The local file must be in CSV format.

To return the current format:

    my $format = $sforce->format();

To set the current format:

    $sforce->format( format=> "csv" );

=cut

sub format {
    my ($self, %options) = @_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );
    
    croak "Please pass a Salesforce.com Report Id, or local file,"
        . "to WWW::Salesforce::Report->new() or by calling the report_id() method.\n"
            if( !$self->{ id } && !$self->{ file } );
    
    return $self->{ format } if( !defined($options{ format }) );
    
    $self->{ format } = $options{ format };
    
    if( $self->{ format }=~ /csv/i ) {
        
        $self->{ url } = $self->{ csv_report_url };
        
        print "Report format set to CSV.\n"
            if( $self->{ verbose } );
        
    }
    elsif( $self->{ format } =~ /xls/i ) {
        
        croak 'Format cannot be set to "xls" when reading from local file'
            if( $self->{ file } );
        
        $self->{ url } = $self->{ xls_report_url };
        
        # XLS reports cannot be cached localy
        $self->cache( cache => 0 );
        
        print "Report format set to XLS. Caching disabled\n"
            if( $self->{ verbose } );
            
    }
    else {
        
        croak "Unknonw report type ($self->{ format }). Supported formats are"
            . ' "csv", or "xls"';
    }
    
    $self->_set_name();
    return $self->{ format };

}

=item cache( cache => 0 | 1 )

Get or set the local cache flag

To return the current format:

    my $cache = $sforce->cache();

To set the current format:

    $sforce->cache( cache => 0 );

=cut

sub cache {
    my ($self, %options) = @_;
    
    $self->{ cache } = $options{ cache }
        if( defined($options{ cache }) );
    
    return $self->{ cache };

}

=item primary_key( key => field )

Get the primary key field of the database. Defaults to '__id'

=cut

sub primary_key {
    my ($self) = @_;
    
    return $self->{ primary_key };
}


=item clean ( )

Clean the local cache and report data. This method will delete the local
cache file (SQLite database) if it exists.
Downloaded report data will also be erased from memory.

=cut

sub clean {
    my ($self, %options ) = @_;
    
    # Check if the local cache database exists and remove it
    # So we do not leave garbage behind.
    if( $self->{ name }          &&
        $self->{ format } =~ /csv|xls/i &&
        -e $self->{ name }          ) {

        unlink $self->{ name } or
            croak "Could not erase local cache $self->{ name }\n";

    }
    
    $self->{ data } = "";
}

=item get_report ( format => string, cache => 0 | 1, force => 0 | 1 )

Download a report from Salesforce.com or read it from a local file
Returns a string with the report data.

C<OPTIONS> are passed in a hash like fashion, using key and value pairs.
Possible options are:

B<format> => "csv"| "xls"

The report format. Possible values are csv, or xls
As of this writing Salesforce.com only supports CSV and XLS formats
for exported reports.
Comma Separated Value (CSV) is the only format that can be cached to a local
SQLite database. If you set the local file, via the C<file> parameter to new(),
a local CSV file will be read from disk instead of downloading the report data
from Salesforce.com. The local file must be in CSV format.

B<cache> => 0 | 1

If true create a local cache for the report data, using a SQLite
database. B<cache> is on by default but only used if report B<format> is C<CSV> or
C<local>. The database name is the report Id, with a 'db3' extension. Or local
C<filename.db3> in case of C<local> format.

B<force> => 0 | 1

If called multiple times C<get_report()> will return the cached data without
downloading it again, and again. If you want to re-download the data from
Salesforce.com, or re-read the local file, set C<force> to 1.
By default C<force> is 0.

Example:

    my $report = $sf->get_report( id => "000006889AAD", format => "xls");

=cut

sub get_report {
    my ($self, %options ) =@_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );
    
    croak "Please pass a Salesforce.com Report Id, or local file,"
    . "to WWW::Salesforce::Report->new() or by calling the report_id() method.\n"
        if( !$self->{ id } && !$self->{ file } );
    
    $options{ force } = 0 if( !defined($options{ force }) );
    
    if( $self->{ data }   &&
        !$options{ force } ) {
        
        print "Report content already in memory. Return without downloading\n"
            if( $self->{ verbose } );
        
        return $self->{ data };
    }
    
    if( $options{ format } ) {
        
        $self->format( format => $options{ format } );
        $self->_set_name( delete => $options{ force } );

    }
    
    # Replace the report Id in the report URL
    $self->{ url } =~ s/REPORTID/$self->{ id }/g;
    
    my $res;
    if( !$self->{ file } ) {
        
        # Not a local report so get it from Salesfoce.com
        print "Getting report $self->{ id } data.\n"
            if( $self->{ verbose } );
    
        $res = $self->_request($self->{ url });
        
    }
    else {
        
        print "Get Report from local file: $self->{ file }\n"
                  if( $self->{ verbose } );
                  
        open my $fh,"<", $self->{ file } or
            croak "Could not open $self->{ file } : $!";
        
        $res = "";
        while( <$fh> ) {
            $res .= $_;
        }
        
        close $fh;
    }

    if( $self->{ format } =~ /csv/i ) {
        # Remove the text in the end of the report results. Something like:
        #
        #   "This is the report name"
        #   "Copyright (c) 2000-2007 salesforce.com, inc. All rights reserved."
        #   "Confidential Information - Do Not Distribute"
        #   "Generated By:  username  2/4/2008 3:54 AM"
        #   "Company"
        #
        $res =~ s/"(?:\n){2}.*$/"/s;
        
        $res =~ s/"\n/"___/g;   # safeguard the "true" new lines
        $res =~ s/\n/ /g;       # replace all "in-field" new lines with \s
        $res =~ s/___/\n/g;     # restore "true" end of lines
    }
    
    $self->{ data } = $res;
    
    # Cache report to local database, if caching is enabled
    $self->_cache_report_to_sqlite()
        if( $self->cache() );
    
    print "Caching disabled. Report data not imported into local database\n"
        if( !$self->cache() && $self->{ verbose } );
        
    return $res;
}

=item write( file => file_name, compress => 0 | 1 )

Write report data to local file. If C<compress> is 1 create a Zip file, with the
compressed contents of the downloaded report. This is the default.

If  a specific file name is not passed via C<file> the report data will be saved
to the default name returned by name().

Example:

Write report data to a Zipped Excel file

    use PMP::Salesforce;

    $sf = PMP::Salesforce->new(
        id=> "000000068AxXd",
        format => "xls",
        user=> "myuser",
        password => "mypassword" );
        
    $sf->login();
    $sf->get_report();
    my $name = $sf->write();

=cut

sub write {
    my ($self, %options) = @_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );

    croak "Please pass a Salesforce.com Report Id, or local file,"
        . "to WWW::Salesforce::Report->new() or by calling the report_id() method.\n"
                if( !$self->{ id } && !$self->{ file } );
    
    croak "Call get_report() before calling write()"
        if( !$self->{ data } );
    
    my $name;
    if( $options{ file } ) {
        $name = $options{ file };
    }
    elsif( $self->{ file } ) {
        $name = $self->{ file };
    }
    elsif( $self->{ id } ) {
            
        $name = $self->{ id } . ".csv";
    }
    else {
        croak "File name not set";
    }
    
    $options{ compress } = 1 if( !defined($options{ compress }) );
    
    if( !$options{ compress } ) {
        open my $fh, ">", $name or
            croak "Could not create file $name for writing\n";
    
        print $fh $self->{ data };
        close $fh;
        
        print "Report data written to file $name\n"
            if( $self->{ verbose } );
        
        return $name;
    }
    else {
        # Compress the file?
        
        # remove the .db3 that may exist in the file's name
        $name =~ s/\.db3$//;
        my $zip_name = $name;
        
        if( $name =~ /\..+/ ) {
            
            # Replace the file extention with .zip
            $zip_name =~ s/\..*$/\.zip/;
            
        }
        else {
            
            # File had no extention just add a .zip
            $zip_name .= ".zip";
            
        }
        
        my $z = IO::Compress::Zip->new(
            $zip_name,
            name        => $name,
            ExtAttr     => 0666 << 16,
            AutoClose   => 1 )
            or die "IO::Compress::Zip(1) failed: $ZipError\n";
            
        print $z $self->{ data };
        
        print "Report data written to zip file $zip_name\n"
            if( $self->{ verbose } );
        
        return $zip_name;
    }

}

=item query( query => sqlite_query, hash => 0 | 1 )

Run query on the cached report database. This method can only be called on
CSV and local report formats that have been cached locally. If the database
does not exist the mothod will fail and croak.

B<query> => sqlite_query

Mandatory SQLite query string to execute.

B<hash> => 0 | 1

Optional parameter that defaulst to 1, and controls how data is returned.
If hash => 1 query result is returned as an array
of hash references. If hash => 0 query result is returned as an array
of array references. See DBI module documentation for fetchrow_hashref(), and
fetchrow_arrayref().

Example:

    $sf = PMP::Salesforce->new( user=> "myuser", password => "mypassword" );
    $sf->login();
    $sf->report_id(id=> "000000068AxXd");
    $sf->get_report();
    my @data = $sf->query(query => "select * from reports");

=cut

sub query {
    my ($self, %options ) = @_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );
    
    croak "Please pass a Salesforce.com Report Id, or local file,"
        . "to WWW::Salesforce::Report->new() or by calling the report_id() method.\n"
                if( !$self->{ id } && !$self->{ file } );
    
    croak "You need to cache a report locally before you can call query()\n"
        if( !-e $self->{ name } );
        
    croak "Please pass a SQLite query string to query()\n"
        if( !defined($options{ query }) );
        
    croak "Please enable the local cache in new() before you can run queries"
        if( !$self->cache() );
    
    $options{ hash } = 1 if( !defined( $options{ hash }) );
    
    $self->{ dbh } =
        DBI->connect("dbi:SQLite:dbname=". $self->{ name },"","") or
            croak "Database connection not made: $DBI::errstr";

    my $sth;
    $sth = $self->{ dbh }->prepare( $options{ query } ) or
        croak "Couldn't prepare statement: " . $sth->errstr;
        
    print "Running query: $options{ query }\n"
        if( $self->{ verbose } );
        
    $sth->execute() or
        croak "Couldn't execute statement: " . $sth->errstr;
        
    #TODO: This is not optimal from a memory consumption perspective and should
    #      be changed into calling a sub ref.
    my %ret_hash;

    $ret_hash{ num_fields } = $sth->{NUM_OF_FIELDS};

    # TODO: this is a bug for sure
    push @{ $ret_hash{ fields } }, @{ $sth->{ NAME } };
    
    if( $options{ hash } ) {
        $ret_hash{ format } = "array_of_hashes";
        
        while( my $data = $sth->fetchrow_hashref() ) {
           push @{ $ret_hash{ data } },  $data ;
        }

    }
    else {
        $ret_hash{ format } = "array_of_array";
        while( my $data = $sth->fetchrow_arrayref() ) {
           push @{ $ret_hash{ data } }, ( $data );
        }
        
    }
    
    return %ret_hash;
}

=item dbh ( )

Returns the DBI handle of the cached report database. Use this method if you
need direct access to the local database DBI handle.

    my $dbh = $sforce->dbh();
    my $sth = $dbh->prepare( "select * from reports ) or
        croak "Couldn't prepare statement: " . $sth->errstr;

Just like you're accessing SQLite through DBI, a bit low level but allows you
to manipulate the report data in a very flexible way.

=cut

sub dbh {
    my ($self, %options ) = @_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );
    
    croak "Please pass a Salesforce.com Report Id, or local file,"
        . "to WWW::Salesforce::Report->new() or by calling the report_id() method.\n"
                if( !$self->{ id } && !$self->{ file } );
        
    croak "You need to download the report and cache it locally before you can call get_dbh()\n"
        if( !defined($self->{ dbh } ) );
    
    return $self->{ dbh };
}

=back

=head2 PRIVATE METHODS

Internal methods are not to be used directly in your code. Documented in
case you need to hack this module...

=over

=item _request( URL )

Request Salesforce.com URL after the user has already been authenticated
Returns the page content as a string.
Can be used to get any URL

=cut

sub _request {
    my ($self, $url) = @_;
    
    # Sanity checks
    die "Please pass a url to _request" if(!defined($url) );
    croak "Please call new() before using the object\n" if( !$self );
    
    croak "Please login() before doing any other operations"
        if( !$self->login_server() );
    
    my $request = HTTP::Request->new(GET => $url);

    # Place the saved cookie on the request HTTP Header
    $self->{ cookie_jar }->add_cookie_header($request);

    # Actually send the request to the server
    my $res = $self->{ ua }->request($request);
    
    croak "Cannot get $url"
        if(!$res->is_success);
    
    return($res->content);
}

=item _db_check_create( fields => fields_str )

Check if the database exists and if it needs to be deleted/created before the
report is imported to the database.

If the database file does not exist a new one is created and the two tables are
created within it.

B<fields> => list_of_field_names

String with the list of all the report fields (comma separated).

B<Database Schema>

This is the table where all the report data will be stored. The fields of the
table are the same as the ones used in the Salesforce.com report, but with all
the characters that do not match 0-9, a-z or A-Z removed.
The database will have two tables (report and notifications) and optionally
an index (__report_index).

B<Reports Table>

Table to store all report data. Fields are determined by the C<fields> parameter
all the types are C<TEXT>.
A C<__hash> fields is always added to the C<report> table. This field will store
a MD5 hash of each report line, and can be used to create a C<UNIQUE> index if
you do not want repeated report lines in your local database.

B<Notifications Table>

Table to store notification data, for instance emails sent to users notifying
them about report data.

B<Unique index on __hash on reports>

If C<allow_duplicates> is false then an index will be created on the __hash
field of the reports table in order to guarantee no duplicate report line data
is stored in the database.

Example:

    $self->_db_check_create( fields => "OpportunityOwner, Amount, Probability" );

=cut

sub _db_check_create {
    my ($self, %options) = @_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );
    
    croak "Please pass a Salesforce.com Report Id, or local file,"
        . "to WWW::Salesforce::Report->new() or by calling the report_id() method.\n"
                if( !$self->{ id } && !$self->{ file } );
    
    croak "Please pass a list of fields to _db_check_create()\n"
        if( !$options{ fields } );
    
    die 'Local cache only supports "csv" format, in _db_check_create()'
        if( $self->format() !~ /csv/i);
    
    # Store the first line for data insertion
    my $sql_fields = "__hash," . $options{ fields };
    
    my $db_name = $self->name();
    
    # Check if the user wants to erase the database each time we run
    if( $self->{ erase_db } &&
        -e $db_name) {
        
        unlink($db_name) or
            die "Could not delete database: $db_name\n";
            
        print "Database $db_name deleted\n"
            if( $self->{ verbose } );
        
    } 
       
    if( !( -e  $db_name) ) {
        # Create the database if it does not exist
        
        # Create DB Table
        # All data types are TEXT
        $options{ fields } =~ s/"//g;
        my @fields = split(/,/, $options{ fields });
        
        my $report_table = "CREATE TABLE report (__hash TEXT,";
        my $notify_table = "CREATE TABLE notifications (";
        
        if( $self->{ primary_key } eq "__id" ) {
            $report_table .= "__id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, ";
            $notify_table .= "__id INTEGER,timestamp TEXT, action TEXT,subject TEXT,note TEXT,sender TEXT,rcpt TEXT)";
        }
        else {
            
            # Check if the user primary key exists in the fields
            croak "Bad primary key:$self->{ primary_key }, " .
                  "possilbe values are: $options{ fields }"
                    if( $options{ fields } !~ /$self->{ primary_key }/ );
                
            $notify_table .=
                $self->{ primary_key }      . " " .
                $self->{ primary_key_type } . "," .
                "timestamp TEXT, action TEXT,subject TEXT,note TEXT," .
                "sender TEXT,rcpt TEXT)";

        }
        
        # append the report fields
        foreach my $field ( @fields ) {
            if( $field eq $self->{ primary_key } ) {
                $report_table .=
                    "$field $self->{ primary_key_type } NOT NULL PRIMARY KEY,";
            } else {
                $report_table .= " $field TEXT,"
            }
        }
        
        chop($report_table);
        $report_table .= ")";
        
        # Connect/Create the DB and create the table to store the report
        my $dbh = DBI->connect("dbi:SQLite:dbname=$db_name","","") or
            die "Database connection not made: $DBI::errstr";
            
        $dbh->do( $report_table ) or
            die "Could not create database table reports: $DBI::errstr";
            
        $dbh->do( $notify_table ) or
            die "Could not create database table notifications: $DBI::errstr"; 
        
        # Check if the user wants to allow duplicates in the db.
        # If not create a unique index for the hash value
        if( !$self->{ allow_duplicates } ) {
            
            print "Duplicates not allowed. Creating Unique index\n"
                if( $self->{ verbose } );
                
            my $index;
            if( $self->{ primary_key } eq "__id" ) {
                $index = "CREATE UNIQUE INDEX __hash_index ON reports (__hash)";
            }
            else {
                $index = "CREATE UNIQUE INDEX __report_index ON reports ($self->{ primary_key })";
            }
            $dbh->do( $index ) or
                die "Could not create database index :$DBI::errstr";

        }
        
        $dbh->disconnect() or
            die "Could not disconnect from database: $DBI::errstr";
        
    }
    
    if( $self->{ erase_reports_table } ||
        $self->{ erase_notifications_table } ) {
        
        my $dbh = DBI->connect("dbi:SQLite:dbname=$db_name","","") or
            die "Database connection not made: $DBI::errstr";
            
        if( $self->{ erase_reports_table } ) {
            
            print "All data in reports table deleted\n"
                if( $self->{ verbose } );
        
            $dbh->do("DELETE FROM report") or
                die "Could not delete data in the report table: $DBI::errstr";
        }
        
        if( $self->{ erase_notifications_table } ) {
            
            print "All data in notifications table deleted\n"
                if( $self->{ verbose } );
        
            $dbh->do("DELETE FROM notifications") or
                die "Could not delete data in the notifications table: $DBI::errstr";
        }
        
        $dbh->disconnect() or
            die "Could not disconnect from database: $DBI::errstr";
    }
}

=item _dd($self, $mon, $day, $year)

Convert the dates from mm/dd/yyyy to yyyy-mm-dd

=cut

sub _dd {
    my ($s1, $s2, $s3) = @_;
    return sprintf("%04d-%02d-%02d",$s3,$s1,$s2);
}

=item _cache_report_to_sqlite( $data )

Take the CSV formated $data and import it into the SQLite database.
The CSV must have all the fields in the first line of the file, be comma separated
data and all fields should be quoted with "

Report data is imported into the C<reports> table in the database.

=cut

sub _cache_report_to_sqlite {
    my ($self) =@_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );
    
    croak "Please pass a Salesforce.com Report Id, or local file,"
        . "to WWW::Salesforce::Report->new() or by calling the report_id() method.\n"
                if( !$self->{ id } && !$self->{ file } );
    
    die 'Local cache only supports "csv" format, in _db_check_create()'
        if( $self->format() !~ /csv/i);
    
    croak "Call get_report() before calling _cache_report_to_sqlite"
        if( !$self->{ data } );
    
    print "Writing report data to database\n"
        if( $self->{ verbose } );
    
    print "Importing data.\n"
        if( $self->{ verbose } );
    
    my $res = $self->{ data };
    
    #The first line has the field names lets fix them
    $res =~ s/^[\s\t]+\n/_/sg;      # replace spaces and tabs with '_'
    
    # get first line
    $res =~ /(.*)/m;
    my $first_line = $1;
    $res =~ s/.*\n//m;

    # if the report is empty then there is only the first line, which has
    # all the field names and no data.
    if( $res eq $first_line ) {
        
        print "No new data to add to database\n"
            if( $self->{ verbose } );
        return 0;
        
    }

    # Convert the Field names so they only have letters and Numbers and no spaces
    $first_line =~ s/[^,a-zA-Z0-9]*//g;
    
    my @fields = split(/,/,$first_line);
    my $num_fields = $#fields;

    # Store the first line for data insertion
    my $sql_fields = "__hash," . $first_line;
    
    # Create the DB and create the table to store the report
    $self->_db_check_create( fields => $first_line );
    
    # Connect to the database
    
    $self->{ dbh } =
        DBI->connect("dbi:SQLite:dbname=" . $self->{ name }, "", "")
        or die "Database connection not made: $DBI::errstr";
    
    $self->query(query => $self->{ pre_import_query })
        if( $self->{ pre_import_query } );
    
    my $sql = "INSERT INTO report (" . $sql_fields . ") VALUES (__MYVALUES__)";

    # Loop all the data lines
    while( $res =~ /(.*)/gm) {
        # in SFDC CSV exports all fields are quoted with " and separated with ,
        # but the fields can have LF chars in them
        my $line = $1;
        
        next if( $line eq "" );
        
        if( $self->{ convert_dates } ) {
            $line =~ s/(\d{1,2})\/(\d{1,2})\/(\d{4})/$self->_dd($1,$2,$3)/ge;
        }
        
        # hash the data so we don't do repeats
        my $md5 = Digest::MD5->new;
        $md5->add($line);
        $line = "\"". $md5->hexdigest . "\"," . $line;
        
        my $tsql = $sql;
        $tsql =~ s/__MYVALUES__/$line/;
        
        $self->{ dbh }->do($tsql) or
            croak "Could not insert data into reports table>: $DBI::errstr\n";

    }

    $self->{ dbh }->disconnect() or
        croak "Could not disconnect from Database: $DBI::errstr";
        
    print "Data imported into the reports table of " . $self->{ name } . "\n"
        if( $self->{ verbose });
    
    $self->query(query => $self->{ post_import_query })
        if( $self->{ post_import_query } );
    
    return 1;
}

=item _set_name ( name => file_name, delete => 0 | 1)

Set the name of the local cache database or file to which the report
data is saved.

Optional Parameters:

B<name> => file_name

Name of file to use. If C<name> is not given the file's name is determined by
using the current report C<format>, and local C<file>, or C<id> that were passed
to C<new()>.

As in other methods the C<file> option takes precedence over Salesforce.com
report C<id>. Teh name is constructed by appending and extension to either the
C<file> or C<id> as follows

Extensions and formats:
   CSV  -> name.db3
   XLS  -> name.xls

B<delete> => 0 | 1

If C<delete> is true the report data, and local cache file will be deleted
before the name change. Otherwise the file is left on disk. Default is true (1).

=cut

sub _set_name {
    my($self, %options) = @_;
    
    # Sanity checks
    croak "Please call new() before using the object\n" if( !$self );
    
    croak "Please pass a Salesforce.com Report Id, or local file,"
        . "to WWW::Salesforce::Report->new() or by calling the report_id() method.\n"
        if( !$self->{ id } && !$self->{ file } );
    
    # Delete the local fiel and report data?
    $options{ delete } =1
        if( !defined( $options{ delete }) );
    if( $options{ delete } ) {
    
        $self->clean();
    
    }
        
    $options{ name } = ""
        if( !defined( $options{ name }) );
    
    if( !$options{ name } ) {
        # Calculate name from current report format and local file or
        # Salesforce.com report id
        
        # Update local chache name
        if( $self->{ file } ) {
            
            # local file must be in CSV
            $self->{ name } = $self->{ file } . ".db3";
            
        }
        elsif( $self->{ id } ) {
            
            if( $self->format() =~ /csv/i ) {
                $self->{ name } = $self->{ id } . ".db3";
            }
            elsif( $self->format() =~ /xls/i ) {
                $self->{ name } = $self->{ id } . ".xls";
            }
            else {
                croak 'Bad file format. Format can only be "csv" or "xls".';
            }

        }
        else {
            
            croak 'Unkown report format: ' . $self->{ format } .
                  'Must be "csv" or "xls".\n';

        }
    
    }
    else {
        $self->{name} = $options{ name };
    }
    
    die "Name was not set new()"
        if( !$self->{ name } );
        
    return $self->{ name };
}


=item Destructor

Object destructor will clean the local cache files format is CSV or XLS.

=back

=cut

sub DESTROY {
    my $self = shift;
    
    return if( !$self );
    
    $self->clean() if( $self->{ clean_on_destroy } );
}

=head1 AUTHOR

Pedro Paixao, C<< <paixaop at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-salesforce-report at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Salesforce-Report>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<WWW::Salesforce>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Salesforce::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Salesforce-Report>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Salesforce-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Salesforce-Report>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Salesforce-Report/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Pedro Paixao.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Salesforce::Report
