NAME
            Tivoli::Logging - Perl Extension for Tivoli

SYNOPSIS
            use Tivoli::Logging;

VERSION
            v0.02

License
            Copyright (c) 2001 Robert Hase.
            All rights reserved.
            This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

DESCRIPTION
                This Package will handle about everything you may need for Logging.
                If anything has been left out, please contact me at
                tivoli.rhase@muc-net.de
                so it can be added.
        
                Prints formated Logging-Informations to STDOUT and if wanted to one or more Files.
                Supports an unlimited Numbers of open Files (dynamical Filehandlers) and
                prints the Type of the STDOUT-Information in Color (requires ANSI).

                Should be the first loaded Tivoli-Package.

  DETAILS

                If Parameter L<File-Handler> = STDOUT the Logging-Message will only be sended to Standard-Out

    * Types of Logging and Colors
                ROUTINE         TYPE            FOREGROUND/BACKGROUND
                -----------------------------------------------------
                LogInfo         (Info)          black/green
                LogWarn         (Warning)       black/yellow
                LogFail         (Failed)        black/red
                LogFat          (Fatal)         white/black

    * Loggings to STDOUT
                Prints Logging-Informations in the following Format:
                TYPE dd.mm.yyyy hh:mm:ss MSG

    * SAMPLE
                &LogInfo(STDOUT, "This is an Information-Message only to Standard-Out");

    * OUTPUT
                INFO 23.07.2001 This is an Information-Message only to Standard-Out

    * Logging to Files
                Prints Logging-Informations in the following Format:
                yyyy-mm-dd hh:mm:ss TYPE MSG

    * SAMPLE
                &LogInfo($G_LOGFILE1, "This is an Information-Message to Standard-Out AND Logfile $G_LOGFILE1");

    * OUTPUT
                STDOUT: INFO 23.07.2001 13:27:42 This is an Information-Message to Standard-Out AND Logfile $G_LOGFILE1
                FILE  : 2001-07-23 13:27:42 INFO This is an Information-Message to Standard-Out AND Logfile $G_LOGFILE1

  Routines

                Details to the Logging-Functionality

   LogOpenNew

    * CALL
                $FileHandle = &LogOpenNew(<PATH/FILENAME>);

    * DESCRIPTION
                - opens a new Log-File
                - prints L<INFO-Message> to Display and L<$FileHandle>
                - returns the File-Handler

   LogOpenAppend

    * CALL
                $FileHandle = &LogOpenAppend(<PATH/FILENAME>);

    * DESCRIPTION
                - opens PATH/FILENAME for Append
                - prints L<INFO-Message> to Display and $FileHandle
                - returns the File-Handler

   LogInfo

    * CALL
                &LogInfo($FileHandle, <MSG>);

    * DESCRIPTION
                - prints INFO-Message to Display
                - prints INFO-Message to $FileHandle if $FileHandle not 0 

   LogWarn

    * CALL
                &LogWarn($FileHandle, <MSG>);

    * DESCRIPTION
                - prints WARN-Message to Display
                - prints WARN-Message to $FileHandle if $FileHandle not 0

   LogFail

    * CALL
                &LogFail($FileHandle, <MSG>);

    * DESCRIPTION
                - prints FAILED-Message to Display
                - prints FAILED-Message to $FileHandle if $FileHandle not 0

   LogFat

    * CALL
                &LogFat($FileHandle, <MSG>);

    * DESCRIPTION
                - prints FATAL-Message to Display
                - prints FATAL-Message to $FileHandle if $FileHandle not 0

   LogClose

    * CALL
                &LogsClose;

    * DESCRIPTION
                - prints INFO-Message to Display
                - prints INFO-Message to EVERY $FileHandle if exist
                - close EVERY open (Logging-) File-Handler

  Plattforms and Requirements

                Supported Plattforms and Requirements

    * Plattforms
                tested on:

                - w32-ix86 (W9x, NT4, Windows 2000)
                - aix4-r1 (AIX 4.3)
                - Linux (Kernel 2.2.x)

    * Requirements
            requires Perl v5 or higher

  HISTORY

            VERSION         DATE            AUTHOR          WORK
            ----------------------------------------------------
            0.01            2001-07-18      RHase           created
            0.02            2001-07-23      RHase           POD-Doku added

AUTHOR
            Robert Hase
            ID      : RHASE
            eMail   : Tivoli.RHase@Muc-Net.de
            Web     : http://www.Muc-Net.de

SEE ALSO
            CPAN
            http://www.perl.com

