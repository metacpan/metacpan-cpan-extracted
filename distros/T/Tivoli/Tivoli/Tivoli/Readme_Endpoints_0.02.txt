NAME
            Tivoli::Endpoints - Perl Extension for Tivoli

SYNOPSIS
            use Tivoli::Endpoints;

VERSION
            v0.02

License
            Copyright (c) 2001 Robert Hase.
            All rights reserved.
            This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

DESCRIPTION
                This Package will handle about everything you may need for Endpoints.
                If anything has been left out, please contact me at
                tivoli.rhase@muc-net.de
                so it can be added.

  DETAILS

            still in work

  ROUTINES

            Description of Routines

   ExecuteSys

    * DESCRIPTION
                Execute Unix Command with system

    * CALL
                $Var = &ExecuteSys(<Command>);

    * SAMPLE
                $Var = &ExecuteSys('ls');
                $Var = returncode from the Command

   SubscrEP

    * DESCRIPTION
                Subscribe Endpoint to ProfileManager

    * CALL
                $Var = &SubscrEP(<ProfileManager, Endpoint>);

    * SAMPLE
                $Var = &SubscrEP("all-inv-HW_DIFF-ca-pm", "WBK0815");
                $Var = 1 = ok, 0 = Failure

   UnsubscrEP

    * DESCRIPTION
                Unsubscribe Endpoint from ProfileManager

    * CALL
                $Var = &UnsubscrEP(<ProfileManager, Endpoint>);

    * SAMPLE
                $Var = &UnsubscrEP("all-inv-HW_DIFF-ca-pm", "WBK0815");
                $Var = 1 = ok, 0 = Failure

   CheckEPinTMR

    * DESCRIPTION
                Check, if Endpoint in TMR

    * CALL
                $Var = &CheckEPinTMR(<Endpoint>);

    * SAMPLE
                $Var = &CheckEPinTMR(""WBK0815");
                $Var = 1 = ok, 0 = Failure

  Plattforms and Requirements

                Supported Plattforms and Requirements

    * Plattforms
                tested on:

                - aix4-r1 (AIX 4.3)

    * Requirements
            requires Perl v5 or higher

  HISTORY

            VERSION         DATE            AUTHOR          WORK
            ----------------------------------------------------
            0.01            2001-07-06      RHase           created
            0.01            2001-07-09      RMahner         ExecuteSys
            0.01            2001-07-09      RMahner         SubscrEP
            0.01            2001-07-09      RMahner         UnsubscrEP
            0.01            2001-07-09      RMahner         CheckEPinTMR
            0.02            2001-08-04      RHase           POD-Doku added

AUTHOR
            Robert Hase
            ID      : RHASE
            eMail   : Tivoli.RHase@Muc-Net.de
            Web     : http://www.Muc-Net.de

SEE ALSO
            CPAN
            http://www.perl.com

