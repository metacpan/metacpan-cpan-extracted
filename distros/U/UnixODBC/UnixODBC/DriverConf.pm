package UnixODBC::DriverConf;

# $Id: DriverConf.pm,v 1.18 2008-01-21 09:16:56 kiesling Exp $

our $VERSION=0.02;

@ISA = qw(Exporter);

@EXPORT_OK = qw(&new &ConstructProperties &SQLGetInstalledDrivers
	       &SQLGetAvailableDrivers &odbcinst_system_file_path
               &SQLValidDSN &Values &Help &PromptType &PromptData
	       &SQLSetConfigMode &SQLGetConfigMode &GetProfileString
	       &WriteProfileString &GetDSN
	   $ODBCINST_PROMPTTYPE_LABEL $ODBCINST_PROMPTTYPE_TEXTEDIT
	   $ODBCINST_PROMPTTYPE_LISTBOX $ODBCINST_PROMPTTYPE_COMBOBOX
	   $ODBCINST_PROMPTTYPE_FILENAME $ODBCINST_PROMPTTYPE_HIDDEN
	   $ODBC_BOTH_DSN $ODBC_USER_DSN $ODBC_SYSTEM_DSN 
	   );

%EXPORT_TAGS = ( 'all' => [@EXPORT_OK] );

# Constants from odbcinstext.h
our $ODBCINST_PROMPTTYPE_LABEL = 0; # RO
our $ODBCINST_PROMPTTYPE_TEXTEDIT = 1;
our $ODBCINST_PROMPTTYPE_LISTBOX = 2;
our $ODBCINST_PROMPTTYPE_COMBOBOX = 3;
our $ODBCINST_PROMPTTYPE_FILENAME = 4;
our $ODBCINST_PROMPTTYPE_HIDDEN = 5;

# From odbcinst.h 
# SQLGetConfigMode and SQLSetConfigMode
our $ODBC_BOTH_DSN = 0;
our $ODBC_USER_DSN = 1;
our $ODBC_SYSTEM_DSN = 2;

=head1 NAME

UnixODBC::DriverConf - Properties for UnixODBC drivers.

=head1 SYNOPSIS

    use UnixODBC qw(:all);
    use UnixODBC::DriverConf qw(:all);


    # Object-oriented Interface

    my $self = new UnixODBC::DriverConf;

    $self -> ConstructProperties ($driver);

    # Methods for accessing properties
    $self -> Values;
    $self -> Help;
    $self -> PromptType;
    $self -> PromptData;

    # Configuration Modes
    $self -> SQLSetConfigMode ($mode);
    $mode = $self -> SQLGetConfigMode ();

    my @drivers = $self -> SQLGetInstalledDrivers ();
    my @drivers = $self -> SQLGetAvailableDrivers ();

    $r = $self -> SQLValidDSN ($dsn);

    $confpath = $self -> odbcinst_system_file_path ();

    $s = $self -> GetProfileString ($section, $keyword, $filename);
    $self -> WriteProfileString ($section, $newprofilestring, $filename);

    @dsn = $self -> GetDSN ($name, $filename);
    $self -> WriteDSN (\@template, $filename);
    

    # Procedural Interface

    my @drivers = SQLGetInstalledDrivers ();
    # Synonym for SQLGetInstalledDrivers ();
    my @drivers = SQLGetAvailableDrivers ();

    $r = SQLValidDSN ($dsn);

    $confpath = odbcinst_system_file_path ();
    @dsn = GetDSN ($name, $filename);
    WriteDSN (\@template, $filename);




=head1 DESCRIPTION


UnixODBC::DriverConf extracts and accesses properties of
driver-specific libraries, and provides procedural interfaces for
libodbcinst's configuration functions.


=head2 UnixODBC Configuration


Each ODBC-accessible DBMS has an ODBC driver defined for it.  The file
odbcinst.ini contains site-specific values for each property.
Properties and their values depend on the DBMS server's Application
Programming Interface.

Each ODBC accessible database must have a Data Source Name defined for
it.  DSNs are contained in the file, odbc.ini.  Each DSN specifies
driver and configuration libraries, a database name, and the host
name.  Additional values depend on the properties defined by the
driver library.

The function, odbcinst_system_file_path (), returns the directory of
odbcinst.ini and odbc.ini.

ConstructProperties () retrieves driver properties.  The methods,
Values (), Help (), PromptType (), and PromptData (), return the each
property's value, documentation string, prompt type, and prompt data.

This program lists the properties of a PostgreSQL driver and their
values.

  use UnixODBC qw(:all);
  use UnixODBC::DriverConf qw(:all);

  my $self = new UnixODBC::DriverConf;
  $self -> ConstructProperties ('PostgreSQL 7.x');

  foreach (keys %{$self -> Values}) { print "$_ = ". 
		 $self -> Values -> {$_} . "\n"; }


This is the program's output.

   Description = PostgreSQL 7.x
   TraceFile = 
   Password = 
   Protocol = 6.4
   Name = 
   Servername = localhost
   Driver = PostgreSQL 7.x
   Trace = No
   ShowOidColumn = No
   ShowSystemTables = No
   Database = 
   Port = 5432
   FakeOidIndex = No
   Username = 
   RowVersioning = No
   ReadOnly = No
   ConnSettings = 

DSN and driver section headings in odbc.ini and odbcinst.ini are
delimited by brackets.  An example odbcinst.ini section for a
MySQL-MyODBC Driver is given below.

  [MySQL 3.23.49]
  Description   = MySQL-MyODBC Sample - Edit for your system.
  Driver        = /usr/local/lib/libmyodbc3-3.51.02.so
  Setup         = /usr/local/lib/libodbcmyS.so.1.0.0
  FileUsage     = 1
  CPTimeout     = 
  CPReuse       = 

A DSN named definition that uses the driver is shown here.

  [Contacts]
  Description   = Names and Addresses Sample - Edit for your system.
  Driver        = MySQL 3.23.49
  Server        = localhost
  Port          = 3396
  Socket        = /tmp/mysql.sock
  Database      = Contacts

An odbc.ini entry for a DSN that defines values the PostgreSQL driver
library properties is shown here.

  [Postgresql]
  Description           = Sample DSN - Edit for your system.
  Driver                = PostgreSQL 7.x
  Trace                 = No
  TraceFile             = 
  Database              = gutenberg
  Servername            = localhost
  Username              = postgres
  Password              = postgres
  Port                  = 5432
  Protocol              = 6.4
  ReadOnly              = No
  RowVersioning         = No
  ShowSystemTables      = No
  ShowOidColumn         = No
  FakeOidIndex          = No
  ConnSettings          = 
  Server                = localhost

=head1 FUNCTIONS

=head2 ConstructProperties (I<driver>)


Retrieve the driver properties.  This method is not automatically
called by new ().

  $self -> ConstructProperties ($driver);

=head2 GetDSN (I<dsn>, I<filename>)


Returns a list of the template of I<dsn> from I<filename>.

    my @dsn = $self -> GetDSN ('mydsn', '/usr/local/etc/odbc.ini');

=head2 GetProfileString (I<section>, I<keyword>, I<conffile>)


Return a profile string. 

  $s = $self -> GetProfileString ($driver, $keyword, $conffile);

=head2 Help ()


Return a hash of properties' documentation strings, if any.

    %docs = $self -> Help;

=head2 new ()


UnixODBC::DriverConf constructor.

  my $self = new UnixODBC::DriverConf;


=head2 PromptData ()


Return default values for each property, if any.  Each value is
separated by a newline ("\n");

  # Default values for "Protocol" property.
  my %promptdefaults = $self -> PromptData;
  foreach (split "\n", $prompromptdefaults{Protocol}) { print "$_\n"; }

=head2 PromptType ()


Return type of each prompt.  The type can be 	   

  $ODBCINST_PROMPTTYPE_LABEL 
  $ODBCINST_PROMPTTYPE_TEXTEDIT
  $ODBCINST_PROMPTTYPE_LISTBOX 
  $ODBCINST_PROMPTTYPE_COMBOBOX
  $ODBCINST_PROMPTTYPE_FILENAME 
  $ODBCINST_PROMPTTYPE_HIDDEN

  $self -> PromptType;

=head2 SQLGetAvailableDrivers ()


A synonym for L<"SQLGetInstalledDrivers ()">.

=head2 SQLGetConfigMode ()


  Return the libodbcinst configuration mode.  Mode may be one of:

  $ODBC_BOTH_DSN
  $ODBC_USER_DSN
  $ODBC_SYSTEM_DSN

  $mode = $self -> SQLGetConfigMode; 

=head2 SQLGetInstalledDrivers ()


Returns a list of installed drivers.

  # List the installed ODBC drivers
  my @drivers = SQLGetInstalledDrivers ();
  foreach (@drivers) {print "$_\n";}

=head2 SQLSetConfigMode (I<mode>)


Set the UnixODBC configuration mode.  The parameter may be one of:

  $ODBC_BOTH_DSN
  $ODBC_USER_DSN
  $ODBC_SYSTEM_DSN


=head2 SQLValidDSN (I<dsnname>)


Returns true if I<dsnname> has a length > 0 and does not contain the
following characters: '[', ']', '{', '}', '(', ')', ',', ';', '?',
'*', '=', '!', '@', or '\'.  Returns false otherwise.

=head2   odbcinst_system_file_path ();


Return the directory name of the unixODBC configuration files.

=head2 WriteProfileString (I<section>, I<newprofilestring>, I<conffile>)


Write a profile string to I<conffile>.

  $self -> WriteProfileString ($section, $newprofilestring, $conffile);

=head2 Values ()


Return a hash of values for each property.

  %values = $self -> Values;


=head2 WriteDSN (I<templateref>, I<filename>)


Writes the template array reference I<templateref> to I<filename>.

  my $template = ['[MyDSN]', 
                  'prop1 = val1',
                  'prop2 = val2',
                  'prop3 = val3'];

  $self -> WriteDSN ($template, '/usr/local/etc/odbc.ini');

=head1 EXPORTS


See @EXPORT_OK in UnixODBC::DriverConf.pm.

=head1 VERSION

Version 0.02

=head1 COPYRIGHT

Copyright © 2004-2005, 2008 Robert Kiesling, rkies@cpan.org.

Licensed under the same terms as Perl.  Refer to the file, "Artistic,"
for details.

=head1 SEE ALSO


UnixODBC(3)

=cut


sub ConstructProperties {
    my $self = shift;
    my $driver = $_[0];
    my %h = ();
    $h = UnixODBC::__ODBCINSTConstructPropertyValues ($driver);
    $self -> {Values} = $h;
    $h = UnixODBC::__ODBCINSTConstructPropertyHelp ($driver);
    $self -> {Help} = $h;
    $h = UnixODBC::__ODBCINSTConstructPropertyPrompt ($driver);
    $self -> {PromptType} = $h;
    $h = UnixODBC::__ODBCINSTConstructPropertyPromptData ($driver);
    $self -> {PromptData} = $h;
}

sub Values {my $self = shift; return $self -> {Values};}

sub Help {my $self = shift; return $self -> {Help};}

sub PromptType {my $self = shift; return $self -> {PromptType};}

sub PromptData {my $self = shift; return $self -> {PromptData};}

sub new {
    my $proto = shift;
    my $self = { @_ };
    bless($self, (ref($proto) || $proto));
    return $self;
}

sub SQLGetInstalledDrivers {
    my $self = shift;
    my $names = UnixODBC::__SQLGetInstalledDrivers();
    return @$names;
}

sub SQLGetAvailableDrivers {
    my $self = shift;
    my $names = UnixODBC::__SQLGetInstalledDrivers();
    return @$names;
}

sub odbcinst_system_file_path {
    my $self = shift;
    my $r;
    &UnixODBC::__odbcinst_system_file_path ($r);
    return $r;
}

sub SQLValidDSN {
    my $self = shift;
    my $dsn = $_[0];
    return &UnixODBC::__SQLValidDSN ($dsn);
}

sub SQLSetConfigMode {
    my $self = shift;
    my $mode = $_[0];
    return &UnixODBC::__SQLSetConfigMode ($mode);
}

sub SQLGetConfigMode {
    my $self = shift;
    return &UnixODBC::__SQLGetConfigMode ();
}

sub GetProfileString {
    my $self = shift;
    my ($section, $keyword, $f) = @_;
    my $l;
    my $insec = 0;

    open FILE, "$f" or die "GetProfileString: $!\n"; 
    while (defined ($l = <FILE>)) {
	chomp $l;
	$insec = 1 if (($l =~ /^\[/) && ($l =~ m"$section"));
	$insec = 0 if (($l =~ /^\[/) && ($l !~ m"$section"));
	if ($insec && ($l =~ m"^$keyword")) {
	    close FILE;
	    return $l;
	}
    }
    close FILE;
    return undef;
}

sub WriteProfileString {
    my $self = shift;
    my ($section, $ns, $f) = @_;
    my @profile, @newprofile;
    my $l;
    
    open IN, "$f" or die "WriteProfileString: $!\n";
    while (defined ($l = <IN>)) {
	chomp $l;
	push @profile, ($l);
    }
    close IN;

    foreach my $s (@profile) {
	push @newprofile, ($s);
	if ($s =~ m"^\[$section]") {
	    push @newprofile, ($ns);
	}
    }

    open OUT, ">$f" or die "WriteProfileString: $!\n";
    print OUT "$_\n" foreach (@newprofile);
    close OUT;

    return 0;
}

sub GetDSN {
    my $self = shift;
    my ($dsn, $file) = @_;
    my $l;
    my $sec = 0; 
    my @a;
    open FILE, "$file" or die "GetDSN: $!\n";

    while (defined ($l = <FILE>)) {
	$sec = 1 if ($l =~ m"^\[$dsn\]");
	last if ($sec == 1 && ($l =~ /^\[/) && ($l !~ m"\[$dsn\]"));
	push @a, ($l) if $sec;
    }
    close FILE;
    return @a;
}

sub WriteDSN {
    my $self = shift;
    my ($template, $file) = @_;

    open FILE, ">> $file" or die "WriteDSN: $!\n";
    foreach (@$template) { chomp; print FILE "$_\n"; }
    close FILE;
}

1;
