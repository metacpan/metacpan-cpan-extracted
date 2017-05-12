package DataControl;

use Tk;
use Tk::Balloon;
use strict;

use base qw(Tk::Derived Tk::Frame);
use vars qw($VERSION);
use Carp;

$VERSION = '0.01';

Tk::Widget->Construct('DataControl');

#----------------------------------------------------Constructors-----------------------------------------------------------------#

sub new()
{
	my ($Class) = (shift);

	my $Object = $Class->SUPER::new(@_);
	if(scalar(@{$Object->Get_Fields}) ne scalar(@{$Object->Get_Text_List}))
	{
		$Object->Croak_Error("Tk::Error: Insufficient Number of Fields or Entries\n");
	}
	$Object->{_Class} = $Class;
	$Object->Handle_Db;
	$Object->Store_Rec_Num(0);
	my $Record = $Object->Fetch_Record;
	$Object->Display_Record($Record);
	$Object->Current_Status;

	return $Object;
}

sub Populate()
{
	my ($this)  = (shift);

    eval
       {
        my $Bitmask = pack
           (
		"b25"x20,
            "........................",
            "........................",
            "........................",
            ".....111................",
            ".....111111.............",
            ".....111111111..........",
            ".....111111111111.......",
            ".....111111111111111....",
            ".....111111111111111....",
            ".....111111111111111....",
            ".....111111111111.......",
            ".....111111111..........",
            ".....111111.............",
            ".....111................",
            "........................",
            "........................",
		   );

        $this->Window()->DefineBitmap
           (
            'next' => 25, 20, $Bitmask
           );
       };

    eval
       {
        my $Bitmask = pack
           (
		"b25"x20,
            "........................",
            "........................",
            "........................",
            ".....111..........111...",
            ".....111111.......111...",
            ".....111111111....111...",
            ".....11111111111..111...",
            ".....1111111111111111...",
            ".....1111111111111111...",
            ".....1111111111111111...",
            ".....11111111111..111...",
            ".....111111111....111...",
            ".....111111.......111...",
            ".....111..........111...",
            "........................",
            "........................",
		   );

        $this->Window()->DefineBitmap
           (
            'last' => 25, 20, $Bitmask
           );
		};
	
	eval
       {
		my $Bitmask = pack
		   (
		"b25"x20,
            "........................",
            "........................",
            "........................",
            ".................111....",
            "..............111111....",
            "...........111111111....",
            "........111111111111....",
            ".....111111111111111....",
            ".....111111111111111....",
            ".....111111111111111....",
            "........111111111111....",
            "...........111111111....",
            "..............111111....",
            ".................111....",
            "........................",
            "........................",
		   );

        $this->Window()->DefineBitmap
           (
            'previous' => 25, 20, $Bitmask
           );
	   };

	eval
       {
		my $Bitmask = pack
		   (
		"b25"x20,
            "........................",
            "........................",
            "........................",
            "....111..........111....",
            "....111.......111111....",
            "....111....111111111....",
            "....111..11111111111....",
            "....1111111111111111....",
            "....1111111111111111....",
            "....1111111111111111....",
            "....111..11111111111....",
            "....111....111111111....",
            "....111.......111111....",
            "....111..........111....",
            "........................",
            "........................",
		   );

        $this->Window()->DefineBitmap
           (
            'first' => 25, 20, $Bitmask
           );
	   };

    my $First_Button = $this->Component
       (
        'Button' => 'FirstButton',
        '-bitmap' => 'first',
        '-highlightthickness' => 1,
        '-relief' => 'raised',
        '-borderwidth' => 1,
        '-takefocus' => 1,
        '-width' => 0,
       );

    my $Previous_Button = $this->Component
       (
        'Button' => 'PreviousButton',
        '-bitmap' => 'previous',
        '-highlightthickness' => 1,
        '-relief' => 'raised',
        '-borderwidth' => 1,
        '-takefocus' => 1,
        '-width' => 0,
       );

	my $Status_Entry = $this->Component
       (
        'Entry' => 'Entry',
		'-justify' => 'left',
        '-highlightthickness' => 1,
        '-borderwidth' => 0,
        '-relief' => 'flat',
        '-takefocus' => 1,
        '-width' => 10,
		'-textvariable' => \$this->{_Status},
		'-state' => 'disable',
       );


    my $Next_Button = $this->Component
       (
        'Button' => 'NextButton',
        '-bitmap' => 'next',
        '-highlightthickness' => 1,
        '-relief' => 'raised',
        '-borderwidth' => 1,
        '-takefocus' => 1,
        '-width' => 0,
       );

    my $Last_Button = $this->Component
       (
        'Button' => 'LastButton',
        '-bitmap' => 'last',
        '-highlightthickness' => 1,
        '-relief' => 'raised',
        '-borderwidth' => 1,
        '-takefocus' => 1,
        '-width' => 0,
       );
	
	my $Balloon = $this->Component
	   (
		'Balloon' => 'Balloon',
	   );
	
	$Balloon->attach
	   (
		$First_Button, -balloonmsg => "First Record",
	   );

	$Balloon->attach
	   (
		$Previous_Button, -balloonmsg => "Previous Record",
	   );

	$Balloon->attach
	   (
		$Next_Button, -balloonmsg => "Next Record",
	   );

	$Balloon->attach
	   (
		$Last_Button, -balloonmsg => "Last Record",
	   );
	
	$First_Button->bind
	   (
		'<Button-1>' => sub {$this->Handle_Record('First')},
	   );

	$Previous_Button->bind
	   (
		'<Button-1>' => sub {$this->Handle_Record('Previous')},
	   );

	$Next_Button->bind
	   (
		'<Button-1>' => sub {$this->Handle_Record('Next')},
	   );

	$Last_Button->bind
	   (
		'<Button-1>' => sub {$this->Handle_Record('Last')},
	   );

	$Status_Entry->bind
	   (
		'<Button-1>' => 
		sub 
		   {
			$this->Subwidget('Entry')->focus;
			$this->Configure_Widget($this->Subwidget('Entry'), '-state', 'normal');
			$this->Clear_Data($this->Subwidget('Entry'))
		   },
	   );

	$Status_Entry->bind
	   (
		'<Return>' => sub {$this->Handle_Record('Text')},
	   );
	
    $First_Button->pack
       (
        '-side' => 'left',
		'-fill' => 'y',
        '-expand' => 'true',
       );

    $Previous_Button->pack
       (
        '-side' => 'left',
		'-fill' => 'y',
        '-expand' => 'true',
       );

    $Status_Entry->pack
       (
        '-fill' => 'both',
        '-expand' => 'true',
        '-side' => 'left',
       );

    $Next_Button->pack
       (
        '-side' => 'left',
		'-fill' => 'y',
        '-expand' => 'true',
       );

    $Last_Button->pack
       (
        '-side' => 'left',
		'-fill' => 'y',
        '-expand' => 'true',
       );

    $this->ConfigSpecs
       (
        '-background' => [['SELF', 'METHOD', $Status_Entry], 'background', 'Background', 'white'],
        '-foreground' => [['SELF', 'METHOD', $Status_Entry], 'foreground', 'Foreground', 'black'],
        '-relief' => [['SELF', 'METHOD', $First_Button, $Previous_Button, $Next_Button, $Last_Button], 'relief', 'Relief', 'raised'],
        '-cursor' => [['SELF', 'METHOD', $Status_Entry], 'cursor', 'Cursor', ""],
		'-height' => [['SELF', 'METHOD', $Status_Entry, $First_Button, $Previous_Button, $Next_Button, $Last_Button], 'height', 'Height', 10],
        '-width' => [['SELF', 'METHOD', $Status_Entry], 'width', 'Width', 20],
        '-borderwidth' => [['SELF', $First_Button, $Previous_Button, $Next_Button, $Last_Button], 'borderwidth', 'BorderWidth', 1],
        '-state' => [['SELF', 'METHOD', $Status_Entry], 'state', 'State', 'disable'],
		'-beep' => ['METHOD', 'beep', 'Beep', 1],
		'-dbh' => ['METHOD', 'dbh', 'Dbh', 0],
		'-table' => ['METHOD', 'table', 'Table', 0],
		'-fieldlist' => ['METHOD', 'fieldlist', 'FieldList', 0],
		'-textlist' => ['METHOD', 'textlist', 'TextList', 0],
        '-bg' => '-background',
        '-fg' => '-foreground',
       );

	$this->SUPER::Populate (@_);

	return $this;
}

#----------------------------------------------------Class Methods--------------------------------------------------------------#

sub Class()
{
	return $_[0]->{_Class};	
}

sub Window()
{
	my ($this) = (shift);
	
	return $this->parent;
}

sub Store_Dbh()
{
	my ($this, $Dbh) = (shift, @_);

	$this->{_DBH} = $Dbh;
}

sub Get_DBH()
{
	my ($this) = (shift);

	return $this->{_DBH};
}

sub Store_Table()
{
	my ($this, $Table) = (shift, @_);

	$this->{_Table} = $Table;
}

sub Get_Table()
{
	my ($this) = (shift);
	
	return $this->{_Table};
}

sub Store_Fields()
{
	my ($this, $Value) = (shift, @_);

	$this->{_Field_List} = $Value;
}

sub Get_Fields()
{
	my ($this) = (shift);

	return $this->{_Field_List};
}

sub Store_Text_List()
{
	my ($this, $Value) = (shift, @_);

	$this->{_Text_List} = $Value;
}

sub Get_Text_List()
{
	my ($this) = (shift);

	return $this->{_Text_List};
}

sub Get_Row_List()
{
	my ($this) = (shift);

	return $this->{_Rows_List};
}

sub Store_Row_List()
{
	my ($this, $List) = (shift, @_);

	$this->{_Rows_List} = $List;
}

sub Store_Rec_Num()
{
	my ($this, $Value) = (shift, @_);

	$this->{_Rec_Num} = $Value;
}

sub Get_Rec_Num()
{
	my ($this) = (shift);

	return $this->{_Rec_Num};
}

sub Store_Rows_Count()
{
	my ($this, $Count) = (shift, @_);

	$this->{_Rows_Count} = $Count;
}

sub Get_Rows_Count()
{
	my ($this) = (shift);

	return $this->{_Rows_Count};
}

sub Store_Fields_Count()
{
	my ($this) = (shift);
	my ($Fields) = ($this->Get_Fields());
	
	if(ref($Fields) eq 'ARRAY')
	{
		$this->{_Fields_Count} = scalar(@{$Fields});
	}
}

sub Get_Fields_Count()
{
	my ($this) = (shift);

	return $this->{_Fields_Count};
}

sub Get_Field_Name()
{
	my ($this, $Fields, $Field_Index) = (shift, @_);

	return (exists ($Fields->[$Field_Index])) ? $Fields->[$Field_Index] : undef;
}

sub Store_Status()
{
	my ($this, $Value) = (shift, @_);	

	$this->{_Status} = $Value;
}

sub Store_Beep()
{
	my ($this, $Value) = (shift, @_);

	$this->{_Beep} = $Value;
}

sub Get_Beep()
{
	my ($this) = (shift);

	return $this->{_Beep};
}

#-------------------------------------------------Functions Call up when Configue or Set Options------------------------------------------#

sub dbh()
{
	my ($this, $Dbh) = (shift, @_);	
	if(ref($Dbh) !~ /DBI::/ )
	{
		if($Dbh eq 0)
		{
			$_[0] = undef;
		}
		$this->Die_Error("Illegal Database Handle or not defined -dbh option\n");
	}

	$this->Store_Dbh($Dbh);
}

sub table()
{
	my ($this, $Table) = (shift, @_);

	$this->Store_Table($Table);
}

sub fieldlist()
{
	my ($this, $Field_List) = (shift, @_);
	
	if(ref($Field_List) !~ 'ARRAY')
	{
		if($Field_List eq 0)
		{
			$_[0] = undef;
		}
		$this->Die_Error("Illegal Field List\n");
	}
	
	$this->Store_Fields($Field_List);
}

sub textlist()
{
	my ($this, $Text_List) = (shift, @_);
	
	if(ref($Text_List) !~ 'ARRAY')
	{
		if($Text_List eq 0)
		{
			$_[0] = undef;
		}
		$this->Die_Error("Illegal Text List\n");
	}
	
	foreach my $Entry (@{$Text_List})
	{
		unless($this->Check_Widget($Entry))
		{
			$this->Die_Error("Not a Entry Widget $Entry\n");
		}
	}
	$this->Store_Text_List($Text_List);
}

sub beep()
{
	my ($this) = (shift);
	
	if($_[0] < 0)
	{
		$this->Die_Error("Illegal Value for -beep\n");
	}

	$this->Store_Beep($_[0]);
}

#-----------------------------------------------------Validation Functions----------------------------------------------#

sub Check_Beep()
{
	my ($this) = (shift);

	return $this->Get_Beep();
}

sub Check_Int()
{
	my ($this, $Variable) = (shift, @_);
	
	return 0 if($Variable eq 0);
	return ($Variable =~ /^\d+/) ? 1 : 0;
}


sub Check_Widget()
{
	my ($this, $Widget) = (shift, @_);
	
	return Exists($Widget);
}

sub Check_Boundary()
{
	my ($this, $Corner) = (shift, @_);
	my $Cur_Rec_Num =  $this->Get_Rec_Num;
	
	if($Corner eq 'Left')
	{
		return ($Cur_Rec_Num <= 0) ? 1 : 0;
	}
	else
	{
		my $Rows_Count = $this->Get_Rows_Count;
		return ($Cur_Rec_Num >= ($Rows_Count - 1)) ? 1 : 0;
	}
}

#-----------------------------------------------------Widget Handling Functions-------------------------------------------------#

sub Enable_Widget()
{
	my ($this, $Widget) = (shift, @_);

	if($this->Check_Widget($Widget))
	{
		$this->Configure_Widget($Widget, '-state', -'normal');
	}
	
}

sub Disable_Widget()
{
	my ($this, $Widget) = (shift, @_);

	if($this->Check_Widget($Widget))
	{
		$this->Configure_Widget($Widget, '-state', 'disable');
	}
}

sub Configure_Widget()
{
	my ($this, $Widget, $Option, $Value) = (shift, @_);

	$Widget->configure
	  (
		$Option => $Value,
	  );
}

#------------------------------------------------Status Handling Functions-----------------------------------------------------#

sub Insert_Field()
{
	my ($this, $Widget, $Data) = (shift, @_);
	
	$this->Clear_Data($Widget);
	$Widget->insert("end", $Data);
}

sub Clear_Data()
{
	my ($this, $Widget) = (shift, @_);	

	$Widget->delete(0, "end");
}

sub Alarm()
{
	my ($this) = (shift);

	$this->Window->bell;
}

sub Current_Status()
{
	my ($this) = (shift);
	my ($Rec_Num, $Rows_Count) = ($this->Get_Rec_Num, $this->Get_Rows_Count);

	$this->Store_Status(($Rec_Num + 1) . "/$Rows_Count");
}

#-----------------------------------------------------Database Handling Functions----------------------------------------------#

sub Handle_Db()
{
	my ($this) = (shift);
	my ($Dbh) = $this->Get_DBH;
	my ($Table) = $this->Get_Table;
	my ($Fields) = $this->Get_Fields;
	
	my $Sel_Query = $this->Form_Select_Query($Fields, $Table);
	$this->Store_Row_List($this->Return_Query_Result($Dbh, $Sel_Query));
	my $Row_List = $this->Get_Row_List;
	my $Rows_Count = scalar(@{$Row_List});
	if($Rows_Count eq 0)
	{
		$this->Croak_Error("Tk::Error: Zero Number of Records\n");
	}
	$this->Store_Rows_Count($Rows_Count);
}

sub Form_Select_Query()
{
	my ($this, $Field_List, $Table) = (shift, @_);
	my ($Col_List) = join(',', @{$Field_List});
	my ($Sel_Query) = "SELECT $Col_List FROM $Table";

	return $Sel_Query;
}

sub Return_Query_Result()
{
	my ($this, $Dbh, $Sel_Query) = (shift, @_);

	return $Dbh->selectall_arrayref($Sel_Query);
}

#-----------------------------------------------------Records Handling Functions----------------------------------------------#

sub Handle_Record()
{
	my ($this, $Op) = (shift, @_);
	my ($Row_List) = $this->Get_Row_List;
	my ($Text_List) = $this->Get_Text_List;
	my ($Row_Count) = $this->Get_Rows_Count;
	
	if($Op eq 'Text')
	{
		my $Entry = $this->Subwidget('Entry');
		my $Value = $Entry->get;
		if($this->Check_Int($Value))
		{
			if($Value <= $Row_Count)
			{
				$this->Store_Rec_Num(($Value - 1));
			}
			else
			{
				$this->Alarm if($this->Check_Beep);
			}
		}
		else
		{
			$this->Alarm if($this->Check_Beep);
		}
		$this->Configure_Widget($Entry, '-state', 'disable');
	}
	else
	{
		eval "\$this->Move_To_" . $Op . "_Record;";
	}

	my ($Rec_Num) = $this->Get_Rec_Num;
	my $Record = $this->Fetch_Record;
	$this->Display_Record($Record);
	$this->Current_Status;
}

sub Move_To_First_Record()
{
	my ($this) = (shift);

	if($this->Check_Boundary('Left'))
	{
		$this->Alarm if($this->Check_Beep);
	}
	$this->Store_Rec_Num(0);
}

sub Move_To_Previous_Record()
{
	my ($this) = (shift);
	
	if($this->Check_Boundary('Left'))
	{
		$this->Alarm if($this->Check_Beep);
	}
	else
	{
		$this->Dec_Rec_Num;
}
}

sub Move_To_Next_Record()
{
	my ($this) = (shift);
	
	if($this->Check_Boundary('Right'))
	{
		$this->Alarm if($this->Check_Beep);
	}
	else
	{
		$this->Inc_Rec_Num;
	}
}

sub Move_To_Last_Record()
{
	my ($this) = (shift);

	if($this->Check_Boundary('Right'))
	{
		$this->Alarm if($this->Check_Beep);
	}

	$this->Store_Rec_Num(($this->Get_Rows_Count - 1));
}

sub Inc_Rec_Num()
{
	my ($this) = (shift);

	my ($Rec_Num) = $this->Get_Rec_Num;
	$this->Store_Rec_Num(($Rec_Num + 1));
	
}

sub Dec_Rec_Num()
{
	my ($this) = (shift);

	my ($Rec_Num) = $this->Get_Rec_Num;
	$this->Store_Rec_Num(($Rec_Num - 1));
}

sub Fetch_Record()
{
	my ($this) = (shift);

	my ($Rows_List, $Rec_Num) = ($this->Get_Row_List, $this->Get_Rec_Num);
	
	return $Rows_List->[$Rec_Num];
}

sub Display_Record()
{
	my ($this, $Record ) = (shift, @_);
	my ($Text_List) = $this->Get_Text_List;
	my ($Field_Num) = 0;

	foreach my $Widget (@{$Text_List})
	{
		$this->Insert_Field($Widget, $Record->[$Field_Num++]);	
	}
}

#-----------------------------------------------------Execption Functions-----------------------------------------------#

sub Die_Error()
{
	my ($this, $Message) = (shift, @_);

	die $Message;
}

sub Warn_Error()
{
	my ($this, $Message) = (shift, @_);

	warn $Message;
}

sub Croak_Error()
{
	require Croak;
	my ($this, $Message) = (shift, @_);

	croak $Message;
}
1;

__END__

=cut

=head1 NAME

   Tk::DataControl - Record Navigation Widget

=head1 SYNOPSIS

   $datacontrol = $parent->DataControl(?options?);


=head1 STRANDARD OPTIONS

   -background | -bg, -foreground | -fg, -state, -width, -height, -relief, -cursor, -borderwidth,
   

=head1 WIDGET SPECIFIC OPTIONS

    Name   :  dbh 

    Class  :  Dbh 

    Switch :  -dbh

         Specify the valid DataBase Handle

    Name   :  table 

    Class  :  Table 

    Switch :  -table

         Specify the Table to Navigate the Records

    Name   :  fieldlist 

    Class  :  FieldList 

    Switch :  -fieldlist

         The Array reference of list of fields from table to display

    Name   :  textlist 

    Class  :  TextList 

    Switch :  -textlist

         The Array reference of list of Textbox(Entry) Widget
	
    Name   :  beep

    Class  :  Beep

    Switch :  -beep

         Specifies whether to enable bell when reaches the Boundary while Navigation.
	
=head1 DESCRIPTION

    A DataControl Navigation Control for Records From the Table

=head1 Example
	
	#! /usr/bin/perl -w
	use Tk;
	use DataControl;
	use DBI;

	my $mw = MainWindow->new();
	my $text1 = $mw->Entry()->pack;
	my $text2 = $mw->Entry()->pack;
	my $dbh = DBI->connect("dbi:?driver?:dbname=?dbaname?", "?username?", "?password?");
	my $dc = $mw->DataControl
	  (
	   -dbh => $dbh, 
	   -table => '?table_name?', 
	   -textlist => [$text1, $text2], 
	   -fieldlist => ['?field1?', '?field2?'], 
	   -foreground => 'blue'
	  );

	$dc->pack();

	MainLoop;

=head1 AUTHORS

SanjaySen , palash_bksys@yahoo.com

=cut
