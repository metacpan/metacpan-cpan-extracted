# 
# $Id: Tape.pm,v 1.7 2005/09/01 08:19:27 patrick Exp $
#

=head1 NAME

XML::Tape - module for the manipulation of XMLtape archives

=head1 SYNOPSIS

 use XML::Tape qw(:all);

 $tape = tapeopen('tape.xml','w');
 $tape->add_record("info:archive_id/1", "2005-05-31", $xml_record);
 $tape->tapeclose();

 $tape = tapeopen('tape.xml','r');
 while ($record = $tape->get_record()) {
     printf "id: %s\n"  , $record->getIdentifier;
     printf "date: %s\n" , $record->getDate;
     printf "xml: %s\n", $record->getRecord;
 }
 $tape->tapeclose();

=head1 DESCRIPTION

The XMLtape provides a write-once/read-many XML wrapper for a 
collection of XML documents. The wrapper provides an easy 
storage format for big collections of XML files which can be 
processed with off the shelf tools and validated against a 
schema. The XMLtape is typically used in digital preservation 
projects.

=cut
package XML::Tape;
use strict;
require Exporter;
use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.7 $ ' =~ /\$Revision:\s+([^\s]+)/;;

@XML::Tape::ISA = qw(Exporter);
@XML::Tape::EXPORT_OK = qw(tapeopen);
%XML::Tape::EXPORT_TAGS = (all => [qw(tapeopen)]);
$XML::Tape::SCHEMA_LOCATION = 'http://purl.lanl.gov/aDORe/schemas/2005-08/XMLtape.xsd';

=head1 FUNCTIONS

=over 4

=item tapeopen($filename, $mode, [, @admin])

Filename is the location of an XMLtape file or an opened
IO::Handle.
When mode is 'r' this function opens a XMLtape for reading.
When mode is 'w' this function creates a new XMLtape on disk.
Optionally an array of strings can be provided which contain in
XML format metadata about the XMLtape. E.g.

tapeopen(
  "tape.xml",
  "w"
  "<dc:date xmlns=\"http://purl.org/dc/elements/1.1/\">2005-05-31</dc:date>"
);

Returns a XMLtape instance on success or undef on error.

=cut
sub tapeopen {
    my ($filename, $mode, @admin) = @_;

    die "usage: tapeopen(\$filename, \$mode, [\@admin])" unless ($filename && $mode =~ /^r|w$/);

    if ($mode eq 'w') {
        return new XML::Tape::Writer($filename,@admin);
    }
    else {
        my $identifier = new XML::Tape::Identifier;
        my $namespace = $identifier->identify($filename);
        if ($namespace eq 'http://library.lanl.gov/2005-01/STB-RL/tape/') {
            return new XML::Tape::Reader::v2005_01($filename);
        }
        elsif ($namespace eq 'http://library.lanl.gov/2005-08/aDORe/XMLtape/') {
            return new XML::Tape::Reader($filename);
        }
        else {
            die "unknown tape version $namespace";
        }
    }

    return undef;
}

package XML::Tape::Writer;
use IO::File;

sub new {
    my ($pkg, $filename,@admin) = @_;
    my $fh;

    if (ref $filename && $filename->isa('Tie::Handle')) {
        $fh = $filename;
    }
    else {
        $fh = new IO::File;
        $fh->open("> $filename") || return undef;
    }

    my $obj = bless { 
            fh => $fh  ,
            init => 0,
            recnum => 0 ,
            } , $pkg;
    $obj->add_admin(@admin) if (@admin > 0);
    return $obj;
}

sub init {
    my ($this) = shift;
    my $fh = $this->{fh};
    die "init: not allowed at this stage" unless $this->{init} == 0;
    print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print $fh "<tape xmlns=\"http://library.lanl.gov/2005-08/aDORe/XMLtape/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://library.lanl.gov/2005-08/aDORe/XMLtape/ $XML::Tape::SCHEMA_LOCATION\">";
    $this->{init}++;
}

sub add_admin {
    my ($this,@admin) = @_;
    my $fh = $this->{fh};
    $this->init() unless ($this->{init});
    die "add_admin: not allowed at this stage" unless $this->{recnum} == 0;
    foreach (@admin) {
        printf $fh "<tapeAdmin>%s</tapeAdmin>", $_;
    }
}

=item $tape->add_record($identifier, $date, $record [, @admin])

Add a XML document to the XMLtape with identifier $identifier, date stamp
$date and XML string representation $record. Optionally
an array of strings can be provided which contain in
XML format metadata about the record. 

Returns true on success undef on error.

=cut
sub add_record {
    my ($this, $identifier, $date, $record, @admin) = @_;
    my $fh = $this->{fh};
    $this->init() unless ($this->{init});

    print $fh "<tapeRecord>";
    print $fh "<tapeRecordAdmin>";
    print $fh "<identifier>" , &escape($identifier) , "</identifier>";
    print $fh "<date>" ,  &escape($date) , "</date>";
    foreach my $admin (@admin) {
        print $fh "<recordAdmin>" , $admin , "</recordAdmin>";
    }
    print $fh "</tapeRecordAdmin>";
    print $fh "<record>" , $record , "</record>";
    print $fh "</tapeRecord>";

    $this->{recnum}++;

    return 1;
}

=item $tape->tapeclose

Closes the XMLtape. 

Returns true on success undef on error.

=cut
sub tapeclose {
    my ($this) = shift;
    my $fh = $this->{fh};
    $this->init() unless ($this->{init});
    print $fh "</tape>";
    $fh->close;
}

sub escape {
    my $str = shift;
    $str =~ s/&/&amp/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/'/&apos;/g;
    $str =~ s/"/&quot;/g;
    return $str;
}

package XML::Tape::Identifier;
use XML::Parser;

sub new {
    my $pkg = shift;
    return bless {} , $pkg;
}

sub identify {
    my ($this,$filename) = @_;
    my $parser = new XML::Parser(Namespaces => 1,
                                 Handlers => {
                                    Start      => sub { $this->handle_start(@_); },
                                 });
    eval {
        $parser->parsefile($filename);
    };
    return $this->{namespace};
}

sub handle_start {
    my ($this, $xp, $elem, %attr) = @_;
    $this->{namespace} = $xp->namespace($elem);
    die "ok";
}

package XML::Tape::Reader;
# NS version http://library.lanl.gov/2005-08/aDORe/XMLtape/
use XML::Parser;
use IO::File;

$XML::Tape::Reader::BUFF_SIZE = 1024;

sub new {
    my ($pkg, $filename,%options) = @_;
    my $obj = bless {} , $pkg;
    my $fh;

    if (ref $filename && $filename->isa('Tie::Handle')) {
        $fh = $filename;
    }
    else {
        $fh = new IO::File;
        $fh->open("< $filename") || return undef;
    }

    $obj->{fh}             = $fh;   # XML file handle
    $obj->{records}        = [];    # Temporary storage for XML::Tape::Record
    $obj->{admins}         = [];    # Temporary storage for XML::Tape::Admin
    $obj->{curr}           = undef; # Current record to be read
    $obj->{parse_init}     = 0;     # Flag to indicate if we started reading XML
    $obj->{parse_done}     = 0;     # Flag to indicate if we still reading XML
    $obj->{parser}         = undef; # XML::Parser
    $obj->{parsernb}       = undef; # XML::Parser::ExpatNB
    $obj->{nav}            = {};    # Hash to navigate in the XML record

    return $obj;
}

=item $tape->get_admin()

Reads one XMLtape admin section. Returns an instance of XML::Tape::Admin on success
or undef when no more XMLtape admin sections are available.

=cut
sub get_admin {
    my ($this) = shift;

    $this->parse() until ( ( scalar @{$this->{records}} ) || ( $this->{parse_done} ) );

    return shift( @{$this->{admins}} );
}

=item $tape->get_record()

Reads one XMLtape record section. Returns an instance of XML::Tape::Record on success
or undef when no more records are available.

=cut
sub get_record {
    my ($this) = shift;

    # Parse the XML until we read a new record or the parse is done...
    $this->parse() until ( ( scalar @{$this->{records}} ) || ( $this->{parse_done} ) );

    return shift( @{$this->{records}} );
}

sub tapeclose {
    my ($this) = shift;
    $this->{fh}->close;
}

sub parse_init {
    my ($this) = shift;

    $this->{parser} = new XML::Parser( Handlers => {
                    Start      => sub { $this->handle_start(@_); },
                    Char       => sub { $this->handle_char(@_); },
                    Comment    => sub { $this->handle_comment(@_); },
                    Proc       => sub { $this->handle_proc(@_); },
                    CdataStart => sub { $this->handle_cdata_start(@_); },
                    CdataEnd   => sub { $this->handle_cdata_end(@_); },
                    End        => sub { $this->handle_end(@_); },
                    Final      => sub { $this->handle_final(@_); },
                      });

    $this->{parsernb} = $this->{parser}->parse_start();

    return undef unless $this->{parsernb};

    $this->{parse_init} = 1;

    return 1;
}

sub parse {
    my ($this) = shift;

    unless ($this->{parse_init}) {
        $this->parse_init() || return undef;
    }

    if (defined $this->{fh}) {
        my $buffer;

        # Read a chunk of XML...
        read($this->{fh}, $buffer, $XML::Tape::Reader::BUFF_SIZE);
     
        # If the buffer isn't empty then, parse it
        # otherwise we reached the end of the file...
        if (length $buffer) {
            $this->{parsernb}->parse_more($buffer);
        }
        else {
            $this->{parsernb}->parse_done();
            $this->{parse_done} = 1;
        }
    }
}

sub handle_start {
    my ($this, $xp, $elem, %attr) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }

    if (0) {}
    elsif ($xp->depth == 1 && $elem =~ /^(\w+:)?tapeAdmin$/) {
        $this->{nav}->{in_tape_admin} = 1;
        $this->{curr} = XML::Tape::Admin->new();
    }
    elsif ($xp->depth == 1 && $elem =~ /^(\w+:)?tapeRecord$/) {
        $this->{curr} = XML::Tape::Record->new();
    }
    elsif ($xp->depth == 2 && $elem =~ /^(\w+:)?tapeRecordAdmin$/) {
        $this->{nav}->{in_tape_record_admin} = 1;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?identifier$/) {
        $this->{nav}->{in_record_identifier} = 1;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?date$/) {
        $this->{nav}->{in_record_date} = 1;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?recordAdmin$/) {
        $this->{nav}->{in_record_admin} = 1;
        $this->{curr}->pushAdmin();
    }
    elsif ($xp->depth == 2 && $elem =~ /^(\w+:)?record$/) {
        $this->{nav}->{in_record} = 1;
        $this->{curr}->setStartByte($xp->current_byte + length $xp->original_string);
    }
}

sub handle_end {
    my ($this, $xp, $elem, %attr) = @_;

    if (0) {}
    elsif ($xp->depth == 1 && $elem =~ /^(\w+:)?tapeAdmin$/) {
        $this->{nav}->{in_tape_admin} = 0;
        push(@{$this->{admins}}, $this->{curr});
    }
    elsif ($xp->depth == 1 && $elem =~ /^(\w+:)?tapeRecord$/) {
        push(@{$this->{records}}, $this->{curr});
    }
    elsif ($xp->depth == 2 && $elem =~ /^(\w+:)?tapeRecordAdmin$/) {
        $this->{nav}->{in_tape_record_admin} = 0;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?identifier$/) {
        $this->{nav}->{in_record_identifier} = 0;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?date$/) {
        $this->{nav}->{in_record_date} = 0;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?recordAdmin$/) {
        $this->{nav}->{in_record_admin} = 0;
    }
    elsif ($xp->depth == 2 && $elem =~ /^(\w+:)?record$/) {
        $this->{nav}->{in_record} = 0;
        $this->{curr}->setEndByte($xp->current_byte);
    }

    if (0) {}
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
}

sub handle_char {
    my ($this, $xp, $data) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record_identifier}) {
        $this->{curr}->addIdentifier($data);
    }
    elsif ($this->{nav}->{in_record_date}) {
        $this->{curr}->addDate($data);
    }
}

sub handle_comment {
    my ($this, $xp, $data) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
}

sub handle_proc {
    my ($this, $xp) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
}

sub handle_cdata_start {
    my ($this, $xp) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
}

sub handle_cdata_end {
    my ($this, $xp) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
}

sub handle_final {
    return 1;
}

package XML::Tape::Reader::v2005_01;
# Old tape reader keeping for backwards compatibility reasons;
# NS version http://library.lanl.gov/2005-01/STB-RL/tape/
use XML::Parser;
use IO::File;

$XML::Tape::Reader::BUFF_SIZE = 1024;

sub new {
    my ($pkg, $filename,%options) = @_;
    my $obj = bless {} , $pkg;
    my $fh;

    if (ref $filename && $filename->isa('Tie::Handle')) {
        $fh = $filename;
    }
    else {
        $fh = new IO::File;
        $fh->open("< $filename") || return undef;
    }

    $obj->{fh}             = $fh;   # XML file handle
    $obj->{records}        = [];    # Temporary storage for XML::Tape::Record
    $obj->{admins}         = [];    # Temporary storage for XML::Tape::Admin
    $obj->{curr}           = undef; # Current record to be read
    $obj->{parse_init}     = 0;     # Flag to indicate if we started reading XML
    $obj->{parse_done}     = 0;     # Flag to indicate if we still reading XML
    $obj->{parser}         = undef; # XML::Parser
    $obj->{parsernb}       = undef; # XML::Parser::ExpatNB
    $obj->{nav}            = {};    # Hash to navigate in the XML record

    return $obj;
}

sub get_admin {
    my ($this) = shift;

    $this->parse() until ( ( scalar @{$this->{records}} ) || ( $this->{parse_done} ) );

    return shift( @{$this->{admins}} );
}

sub get_record {
    my ($this) = shift;

    # Parse the XML until we read a new record or the parse is done...
    $this->parse() until ( ( scalar @{$this->{records}} ) || ( $this->{parse_done} ) );

    return shift( @{$this->{records}} );
}

sub tapeclose {
    my ($this) = shift;
    $this->{fh}->close;
}

sub parse_init {
    my ($this) = shift;

    $this->{parser} = new XML::Parser( Handlers => {
                    Start      => sub { $this->handle_start(@_); },
                    Char       => sub { $this->handle_char(@_); },
                    Comment    => sub { $this->handle_comment(@_); },
                    Proc       => sub { $this->handle_proc(@_); },
                    CdataStart => sub { $this->handle_cdata_start(@_); },
                    CdataEnd   => sub { $this->handle_cdata_end(@_); },
                    End        => sub { $this->handle_end(@_); },
                    Final      => sub { $this->handle_final(@_); },
                      });

    $this->{parsernb} = $this->{parser}->parse_start();

    return undef unless $this->{parsernb};

    $this->{parse_init} = 1;

    return 1;
}

sub parse {
    my ($this) = shift;

    unless ($this->{parse_init}) {
        $this->parse_init() || return undef;
    }

    if (defined $this->{fh}) {
        my $buffer;

        # Read a chunk of XML...
        read($this->{fh}, $buffer, $XML::Tape::Reader::BUFF_SIZE);

        # If the buffer isn't empty then, parse it
        # otherwise we reached the end of the file...
        if (length $buffer) {
            $this->{parsernb}->parse_more($buffer);
        }
        else {
            $this->{parsernb}->parse_done();
            $this->{parse_done} = 1;
        }
    }
}

sub handle_start {
    my ($this, $xp, $elem, %attr) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }

    if (0) {}
    elsif ($xp->depth == 1 && $elem =~ /^(\w+:)?tape-admin$/) {
        $this->{nav}->{in_tape_admin} = 1;
        $this->{curr} = XML::Tape::Admin->new();
    }
    elsif ($xp->depth == 1 && $elem =~ /^(\w+:)?tape-record$/) {
        $this->{curr} = XML::Tape::Record->new();
    }
    elsif ($xp->depth == 2 && $elem =~ /^(\w+:)?tape-record-admin$/) {
        $this->{nav}->{in_tape_record_admin} = 1;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?identifier$/) {
        $this->{nav}->{in_record_identifier} = 1;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?date$/) {
        $this->{nav}->{in_record_date} = 1;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?record-admin$/) {
        $this->{nav}->{in_record_admin} = 1;
        $this->{curr}->pushAdmin();
    }
    elsif ($xp->depth == 2 && $elem =~ /^(\w+:)?record$/) {
        $this->{nav}->{in_record} = 1;
        $this->{curr}->setStartByte($xp->current_byte + length $xp->original_string);
    }
}

sub handle_end {
    my ($this, $xp, $elem, %attr) = @_;

    if (0) {}
    elsif ($xp->depth == 1 && $elem =~ /^(\w+:)?tape-admin$/) {
        $this->{nav}->{in_tape_admin} = 0;
        push(@{$this->{admins}}, $this->{curr});
    }
    elsif ($xp->depth == 1 && $elem =~ /^(\w+:)?tape-record$/) {
        push(@{$this->{records}}, $this->{curr});
    }
    elsif ($xp->depth == 2 && $elem =~ /^(\w+:)?tape-record-admin$/) {
        $this->{nav}->{in_tape_record_admin} = 0;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?identifier$/) {
        $this->{nav}->{in_record_identifier} = 0;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?date$/) {
        $this->{nav}->{in_record_date} = 0;
    }
    elsif ($this->{nav}->{in_tape_record_admin} == 1 && $elem =~ /^(\w+:)?record-admin$/) {
        $this->{nav}->{in_record_admin} = 0;
    }
    elsif ($xp->depth == 2 && $elem =~ /^(\w+:)?record$/) {
        $this->{nav}->{in_record} = 0;
        $this->{curr}->setEndByte($xp->current_byte);
    }

    if (0) {}
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
}

sub handle_char {
    my ($this, $xp, $data) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record_identifier}) {
        $this->{curr}->addIdentifier($data);
    }
    elsif ($this->{nav}->{in_record_date}) {
        $this->{curr}->addDate($data);
    }
}

sub handle_comment {
    my ($this, $xp, $data) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
}

sub handle_proc {
    my ($this, $xp) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
}

sub handle_cdata_start {
    my ($this, $xp) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
}

sub handle_cdata_end {
    my ($this, $xp) = @_;

    if (0) {}
    elsif ($this->{nav}->{in_tape_admin}) {
        $this->{curr}->addAdminXML($xp->original_string);
    }
    elsif ($this->{nav}->{in_record}) {
        $this->{curr}->addRecordXML($xp->original_string);
    }
}

sub handle_final {
    return 1;
}


=back

=head1 XML::Tape::Admin METHODS

=over 4

=item $admin->getRecord()

Returns a XML string representation of a XMLtape administrative record.

=back

=cut
package XML::Tape::Admin;

sub new {
    my ($pkg) = shift;
    return bless {
        adminXML => undef ,
    } , $pkg;
}

sub addAdminXML {
    my ($this, $str) = @_;
    $this->{adminXML} .= $str;
}

sub getRecord {
    my ($this) = @_;
    return $this->{adminXML};
}

=head1 XML::Tape::Record METHODS

=over 4

=item $record->getIdentifier()

Returns the record identifier as string.

=item $record->getDate()

Returns the record datestamp as string.

=item $record->getAdmin()

Returns an ARRAY of administrative records

=item $record->getRecord()

Returns a XML string representation of a XMLtape record.

=item $record->getStartByte()

Returns the start byte position of the record in the XMLtape

=item $record->getEndByte()

Returns the end byte positorion of the record in the XMLtape

=back

=cut
package XML::Tape::Record;

sub new {
    my ($pkg) = shift;
    return bless {
         startByte  => 0 ,
         endByte    => 0 ,
         recordXML  => undef,
         identifier => undef,
         date       => undef,
         admin      => [],
    } , $pkg;
}

sub setStartByte {
    my ($this,$num) = @_;
    $this->{startByte} = $num;
}

sub getStartByte {
    my ($this) = @_;
    return $this->{startByte};
}

sub setEndByte {
    my ($this,$num) = @_;
    $this->{endByte} = $num;
}

sub getEndByte {
    my ($this) = @_;
    return $this->{endByte};
}

sub addRecordXML {
    my ($this, $str) = @_;
    $this->{recordXML} .= $str;
}

sub getRecord {
    my ($this) = @_;
    return $this->{recordXML};
}

sub addIdentifier {
    my ($this, $str) = @_;
    $this->{identifier} .= $str;
}

sub getIdentifier {
    my ($this) = @_;
    return $this->{identifier};
}

sub addDate {
    my ($this, $str) = @_;
    $this->{date} .= $str;
}

sub getDate {
    my ($this) = @_;
    return $this->{date};
}

sub pushAdmin {
    my ($this) = @_;
    push(@{$this->{admin}},'');
}

sub addAdminXML {
    my ($this, $xml) = @_;
    my $num = @{$this->{admin}};
    $this->{admin}->[$num-1] .= $xml;
}

sub getAdmin {
    my ($this) = @_;
    return $this->{admin};
}

1;

=head1 FURTHER INFORMATION
 
'File-based storage of Digital Objects and constituent datastreams: XMLtapes and Internet Archive ARC files'
 http://arxiv.org/abs/cs.DL/0503016
 
'The multi-faceted use of the OAI-PMH in the LANL Repository'
 http://yar.sourceforge.net/jcdl2004-submitted-draft.pdf

=head1 BUGS

UTF-8 encoding is mandatory.
Doesn't check for UTF-8 encoding.

=head1 CREDITS

XMLtape archives were developed by the Digital Library Research & Prototyping
team at Los Alamos National Laboratory.

XML parsing in the module was inspired by Robert Hanson's XML::RAX module.

=head1 SEE ALSO

L<XML::Tape::Index>

In bin/oaitape you'll find an example of a OAI-PMH interface on XML::Tape

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=cut

1;
