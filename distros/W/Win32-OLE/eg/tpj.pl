# Sample code from the Win32::OLE article in "The Perl Journal" #10

use strict;
$| = 1;

my $Contract = 'us8m';
my $text;
if (1) {
    # Offline debugging
    $text = `cat tsf$Contract.htm`;
}
else {
    use LWP::Simple;
    my $URL = 'http://www.cbot.com/mplex/quotes/tsfut';
    $text = get("$URL/tsf$Contract.htm");
}

my ($Day,$Time,$hhmm,$Open,$High,$Low,$Close,@Bars);
foreach (split "\n", $text) {
    my ($Date,$Price,$Hour,$Min,$Sec,$Ind) =
      # 03/12/1998  US   98Mar   12116  15:28:34  Open
      m|^\s*(\d+/\d+/\d+)        # "  03/12/1998"
	\s+US\s+\S+\s+(\d+)      # "  US  98Mar  12116"
	\s+(\d+):(\d+):(\d+)     # "  12:42:40"
	\s*(.*)$|x;              # "  Ask"
    next unless defined $Date;
    $Day = $Date;

    # Convert from implied fractional to decimal format
    $Price = int($Price/100) + ($Price%100)/32;
    # Round up time to next multiple of 15 minutes
    my $NewTime = int(($Sec+$Min*60+$Hour*3600)/900+1)*900;
    if (!defined $Time || $NewTime != $Time) {
	push @Bars, [$hhmm, $Open, $High, $Low, $Close]
	  if defined $Time;
	$Open = $High = $Low = $Close = undef;
	$Time = $NewTime;
	my $Hour = int($Time/3600);
	$hhmm = sprintf "%02d:%02d", $Hour, $Time/60-$Hour*60;
    }
    # Update 15 minute bar values
    $Close = $Price;
    $Open  = $Price unless defined $Open;
    $High  = $Price unless defined $High && $High > $Price;
    $Low   = $Price unless defined $Low && $Low < $Price;
}

die "No Times & Sales data found" unless defined $Time;
push @Bars, [$hhmm, $Open, $High, $Low, $Close];

# Start Excel and create new workbook with a single sheet
use Win32::OLE qw(in valof with);
use Win32::OLE::Const 'Microsoft Excel';
use Win32::OLE::NLS qw(:DEFAULT :LANG :SUBLANG);

my $lgid = MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT);
$Win32::OLE::LCID = MAKELCID($lgid);

$Win32::OLE::Warn = 3;

print "Start Excel\n";
my $Excel = Win32::OLE->new('Excel.Application', 'Quit');
$Excel->{SheetsInNewWorkbook} = 1;
my $Book  = $Excel->Workbooks->Add;
my $Sheet = $Book->Worksheets(1);
$Sheet->{Name} = 'Candle';

# Insert column titles
my $Range = $Sheet->Range("A1:E1");
$Range->{Value} = [qw(Time Open High Low Close)];
$Range->Font->{Bold} = 1;

$Sheet->Columns("A:A")->{NumberFormat} = "h:mm";
# Open/High/Low/Close to be displayed in 32nds
$Sheet->Columns("B:E")->{NumberFormat} = "# ?/32";

# Add 15 minute data to spreadsheet
print "Add data\n";
$Range = $Sheet->Range(sprintf "A2:E%d", 2+$#Bars);
$Range->{Value} = \@Bars;

# Create candle stick chart as new object on worksheet
print "Create chart\n";
$Sheet->Range("A:E")->Select;
my $Chart = $Book->Charts->Add;
$Chart->{ChartType} = xlStockOHLC;
$Chart->Location(xlLocationAsObject, $Sheet->{Name});
# Excel bug: old $Chart has become invalid now!
$Chart = $Excel->ActiveChart;

# Add title, remove legend
with($Chart, HasLegend => 0, HasTitle => 1);
$Chart->ChartTitle->Characters->{Text} = "US T-Bond";

# Setup daily statistics
$Open  = $Bars[0][1];
$High  = $Sheet->Evaluate("MAX(C:C)");
$Low   = $Sheet->Evaluate("MIN(D:D)");
$Close = $Bars[$#Bars][4];

# Change tickmark spacing from decimal to fractional
with($Chart->Axes(xlValue),
     HasMajorGridlines => 1,
     HasMinorGridlines => 1,
     MajorUnit         => 1/8,
     MinorUnit         => 1/16,
     MinimumScale      => int($Low*16)/16,
     MaximumScale      => int($High*16+1)/16,
);

# Fat candles with only 5% gaps
$Chart->ChartGroups(1)->{GapWidth} = 5;

sub RGB {
    my ($red,$green,$blue) = @_;
    return $red | ($green<<8) | ($blue<<16);
}

# White background with a solid border
$Chart->PlotArea->Border->{LineStyle} = xlContinuous;
$Chart->PlotArea->Border->{Color} = RGB(0,0,0);
$Chart->PlotArea->Interior->{Color} = RGB(255,255,255);

# Add 1 hour moving average of the Close series
my $MovAvg = $Chart->SeriesCollection(4)->Trendlines
             ->Add({Type => xlMovingAvg, Period => 4});
$MovAvg->Border->{Color} = RGB(255,0,0);

# Save worbook to file
print "Save workbook\n";
my $Filename = 'i:\tmp\tpj\data.xls';
unlink $Filename if -f $Filename;
$Book->SaveAs($Filename);
$Book->Close;

############################################################
print "Start ADO and update database\n";
use Win32::OLE::Const 'Microsoft ActiveX Data Objects';

my $Connection = Win32::OLE->new('ADODB.Connection');
my $Recordset = Win32::OLE->new('ADODB.Recordset');
$Connection->Open('T-Bonds');

# Open a recordset for table of this contract
{
    local $Win32::OLE::Warn = 0;
    $Recordset->Open($Contract, $Connection, adOpenKeyset, 
		     adLockOptimistic, adCmdTable);
}
# Create table and index if it doesn't exist yet
if (Win32::OLE->LastError) {
    $Connection->Execute(<<"SQL");
        CREATE TABLE $Contract
	( 
          Day DATETIME,
	  Open DOUBLE, High DOUBLE, Low DOUBLE, Close DOUBLE
	)
SQL
    $Connection->Execute(<<"SQL");
        CREATE INDEX $Contract 
        ON $Contract (Day) WITH PRIMARY
SQL
    $Recordset->Open($Contract, $Connection, adOpenKeyset, 
		     adLockOptimistic, adCmdTable);
}

# Add new record to table
use Win32::OLE::Variant;
$Win32::OLE::Variant::LCID = $Win32::OLE::LCID;

my $Fields = [qw(Day Open High Low Close)];
my $Values = [Variant(VT_DATE, $Day),
	      $Open, $High, $Low, $Close];
{
    local $Win32::OLE::Warn = 0;
    $Recordset->AddNew($Fields, $Values);
}

# Replace existing record
if (Win32::OLE->LastError) {
    $Recordset->CancelUpdate;
    $Recordset->Close;
    $Recordset->Open(<<"SQL", $Connection, adOpenDynamic);
        SELECT * FROM $Contract
	WHERE Day = #$Day#
SQL
    $Recordset->Update($Fields, $Values);
}

$Recordset->Close;
$Connection->Close;

############################################################
print "Start Notes and send email\n";

sub EMBED_ATTACHMENT {1454;}

my $Notes = Win32::OLE->new('Notes.NotesSession');
my $Database = $Notes->GetDatabase('', '');
$Database->OpenMail;
my $Document = $Database->CreateDocument;

$Document->{Form} = 'Memo';
$Document->{SendTo} = ['Jon Orwant <orwant@media.mit.edu>',
		       'Jan Dubois <jan.dubois@ibm.net>'];
$Document->{Subject} = "US T-Bonds Chart for $Day";

my $Body = $Document->CreateRichtextItem('Body');
$Body->AppendText(<<"EOT");
I\'ve attached the latest US T-Bond data and chart for $Day.
The daily statistics were:

\tOpen\t$Open
\tHigh\t$High
\tLow\t$Low
\tClose\t$Close

Kind regards,
Mary

EOT

$Body->EmbedObject(EMBED_ATTACHMENT, '', $Filename);

#$Document->Send(0);
$Document->Save(0,0);

print "Done\n";

