use Win32::CtrlGUI;
use Win32::CtrlGUI::State::DebugTk;

$Win32::CtrlGUI::State::action_delay = 3;

$Win32::CtrlGUI::State::DebugTk::debugmode = 1;

my $search = "{ENTER}";
(my $escaped = $search) =~ s/([{}])/{$1}/g;

Win32::CtrlGUI::State::DebugTk->newdo(
  seq => [
    atom => [criteria => [pos => qr/Notepad/],
             action => "!fo",
             name => 'MyNotepad'],


    seq_opt => [
      seq => [
        atom => [criteria => [pos => 'Notepad', qr/^The text in the .* file has changed/i],
                 action => "!y"],

        dialog => [criteria => [pos => 'Save As'],
                   action => "!nC:\\TEMP\\Saved.txt{1}{ENTER}",
                   timeout => 5,
                   cnfm_criteria => [pos => 'Save As', qr/already exists/i],
                   cnfm_action => "!y"],
      ],

      dialog => [criteria => [pos => 'Open', 'Cancel'],
                 action => "!n{1}".Win32::GetCwd()."\\demotk.pl{1}{HOME}{2}{ENTER}"],
    ],


    atom => [criteria => [pos => \'MyNotepad'],
             action => "!sf"],

    atom => [criteria => [pos => "Find", "Fi&nd what:"],
             action => "!n$escaped",
             name => 'MyFind'],

    loop => [
      atom => [criteria => [and => timeout => 3, [pos => \'MyFind'], [neg => "Notepad", "Cannot find \"$search\""]],
               action => "!f"],

      seq => [
        atom => [criteria => [and => timeout => 9, [pos => "Notepad", "Cannot find \"$search\""]],
                 action => "{ENTER}"],

        atom => [criteria => [pos => \'MyFind'],
                 action => "{ESC}"],
      ],
    ],


    dialog => [criteria => [pos => \'MyNotepad'],
               action => "!fx"],
  ]
);
