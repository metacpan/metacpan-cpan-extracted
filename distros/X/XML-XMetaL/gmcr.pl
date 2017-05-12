# /usr/bin/perl

use strict;
use warnings;

use Getopt::Std;

my @events = qw(
On_Document_Save On_Document_SaveAs On_Before_Document_Save
On_Before_Document_SaveAs

On_Document_Open_Complete On_Document_Open_View On_Document_Close
On_Document_First_Draw

On_Update_UI

On_Update_ElementList On_ElementList_Insert On_ElementList_Change
On_ElementList_Surround On_ElementList_Insert_NoRequired

On_Application_Before_Document_Validate On_Before_Document_Validate
On_Application_Before_Selection_Validate On_Before_Selection_Validate
On_Application_After_Document_Validate On_After_Document_Validate
On_Application_After_Selection_Validate On_After_Selection_Validate
On_Check_Element_SimpleContent On_Check_Attribute_Value

On_Document_Activate On_Document_Deactivate

On_Before_Document_Preview

On_Click On_Double_Click

On_View_Change 

On_Context_Menu 

On_Document_Before_DropText On_Application_Document_Before_DropText
On_Document_After_DropText On_Application_Document_After_DropText 

On_Drop_Files

On_Drop_URL On_Drag_Over_URL 



On_Style_Element

);

my @file_events = qw(
File_Open File_Open_Template File_New File_Save File_SaveAs File_SaveAll
File_Close File_CloseAll File_Exit
);

my @mouse_events = qw(
On_Mouse_Over On_Mouse_Out
);

my @global_events = qw(
On_Application_Open On_Application_Close
On_Default_CommandBars_Complete
On_Application_Open_Complete
On_Application_Activate On_Application_Deactivate

On_DTD_Open_Complete

On_Application_Resolve_Entity_URL On_Application_Resolve_Image_URL 

);

our %opts;

getopts('mgh',\%opts);

#print map {"$_ => $opts{$_}\n"} keys %opts;

my $system_identifier;
my $perl_module;

{
    &help if exists $opts{h};
    push @events, @file_events if $opts{f};
    push @events, @global_events if $opts{g};
    push @events, @mouse_events if $opts{m};
    $system_identifier = $ARGV[-2] || do {
        warn "System identifier argument is missing\n";
        &help;
    };
    $system_identifier =~ /\.dtd$/i || do {
        warn "System identifier must end with .dtd or .DTD";
        &help;
    };
    $perl_module = $ARGV[-1] || do {
        warn "Module argument is missing\n";
        &help;
    };
}

print <<EOT
<?xml version="1.0"?>
<!DOCTYPE MACROS SYSTEM "macros.dtd">
<MACROS>
    <MACRO name="On_Macro_File_Load" key="" lang="PerlScript">
        <![CDATA[
            use XML::XMetaL;
            use $perl_module;
            
            \$handler = $perl_module->new(-application => \$Application);
            
            \$dispatcher = XML::XMetaL->new(-application => \$Application);
            \$dispatcher->add_handler(
                                      -system_identifier  => "$system_identifier",
                                      -handler            => \$handler
            );
            \$dispatcher->On_Macro_File_Load();
        ]]>
    </MACRO>
EOT
;

foreach my $event (@events) {
    
    print qq{    <MACRO name="$event" key="" lang="PerlScript">
        <![CDATA[
            \$dispatcher->$event(\$ActiveDocument);
        ]]>
    </MACRO>
}
}

print <<EOT
</MACROS>
EOT
;


sub help {
    print <<EOT
gmcr.pl generates XMetaL .mcr (macro) files.

Synopsis:

gmcr.pl [-m] [-g] [-h] sysid module >outfile.mcr

sysid       = The system identifier of the documents to be customized
              using the module
module      - The Perl module used to customize XMetaL
-f          - Add file events (Replaces XMetaL's default file open
              and save operations)
-m          - Add mouse events (may slow XMetaL down)
-g          - Add global macro events
-h          - Print this help message
outfile.mcr - An XMetaL macro file

The following event types can not be generated using gmcr.pl:
* On_Drop_format
* On_Drag_Over_format
EOT
;
exit 1;
}