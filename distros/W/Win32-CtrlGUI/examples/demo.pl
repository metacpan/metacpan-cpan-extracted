=head1 What to do this this demo:

=head2 Prep work

Close all Notepad and WordPad windows on your desktop

=head2 First Demo

=over 4

=list *

Run demo.pl

=list *

Open Notepad

=back

Watch.  It will open the demo.pl file in Notepad and then close the window.  This demonstrates the
simplest path through the demo.

=head2 Second Demo

=over 4

=list *

Open Notepad.  Type some random text in the window.

=list *

Run demo.pl

=back

It will attempt to open the demo.pl file, but first Notepad will ask if the existing file should
be saved.  The script will save it to C:\TEMP\Saved.txt.

=head2 Third Demo

=over 4

=list *

Repeat the above steps

=back

This demonstrates that the cnfm options to the dialog on saving the stuff to Saved.txt works.

=head2 Fourth Demo

=over 4

=list *

Run demo.pl

=list *

Open WordPad

=back

This demonstrates the fork - operates on either Notepad or WordPad.

=head2 What doesn't work

=over 4

=list *

The demo doesn't deal with an open Notepad that has an existing _file_ open, rather than Untitled.

=list *

The demo doesn't display as much flexibility with respect to WordPad

=back

=cut


use Win32::CtrlGUI;

#This puts it in debug mode so that debug information is outputted to STDOUT
$Win32::CtrlGUI::State::debug = 1;

Win32::CtrlGUI::State->newdo(
  #We fork depending upon whether Notepad is opened or WordPad is opened.  We preferentially
  #pick WordPad over Notepad
  fork => [
    #This is the Notepad sequence
    seq => [
      #First we check for a window with Notepad in the title and set it an Alt-F o.
      atom => [criteria => [pos => qr/Notepad/],
               action => "!fo"],

      #Then we have an sequence with optional elements in case the Notepad already has text in it
      seq_opt => [
        seq => [
          #This is the sequence for the situation where the Notepad has text in it.
          #The criteria is a window titled Notepad with text in the body saying the following
          #We send that window an Alt-Y
          atom => [criteria => [pos => 'Notepad', qr/^The text in the .* file has changed/i],
                   action => "!y"],

          #We know that there will be a "Save As" dialog that pops up (this is presuming the
          #Notepad has text in it but it was not an opened file).
          #This dialog is sent the file name to save as along with some pauses and whatnot.
          #If that file already exists, we will get a confirmation dialog, to which we send Alt-Y
          #Note that if the existing Notepad window had a modified file in it, answering Alt-Y will
          #just save to the existing file, so we add a 10 second timeout on waiting for the
          #"Save As" dialog box.
          dialog => [criteria => [pos => 'Save As'],
                     action => "!n{1}C:\\TEMP\\Saved.txt{2}{ENTER}",
                     timeout => 10,
                     cnfm_criteria => [pos => 'Save As', qr/already exists/i],
                     cnfm_action => "!y"],
        ],

        #The exit criteria for this optional sequence is the Open dialog box.  We send it the
        #filename we want to open(this file).
        dialog => [criteria => [pos => 'Open', 'Cancel'],
                  action => "!n{1}".Win32::GetCwd()."\\demo.pl{1}{HOME}{2}{ENTER}"],
      ],

      #When the Notepad window has the file in it, send it an Alt-F x to close it.
      dialog => [criteria => [pos => qr/Notepad/],
                action => "!fx"],
    ],
    seq => [
      #This is the WordPad sequence.  I didn't do as much work on this one.
      atom => [criteria => [pos => qr/WordPad/],
               action => "!fo"],

      dialog => [criteria => [pos => 'Open', 'Cancel'],
                 action => "!n{1}".Win32::GetCwd()."\\demo.pl{2}{ENTER}"],

      atom => [criteria => [pos => qr/WordPad/],
               action => "!fx"],
    ],
  ],
);

