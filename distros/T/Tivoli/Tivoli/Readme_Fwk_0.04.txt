NAME
            Tivoli::Fwk - Perl Extension for Tivoli

SYNOPSIS
            use Tivoli::Fwk;

VERSION
            v0.04

LICENSE
            Copyright (c) 2001 Robert Hase.
            All rights reserved.
            This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

DESCRIPTION
                This Package will handle about everything you may need for Framework.
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

   CrtPR

    * DESCRIPTION
                Create PolicyRegion

    * CALL
                $Var = &CrtPR(<TopPolicyRegion, PolicyRegion>);

    * SAMPLE
                $Var = &CrtPR("top-Company_Europe_pr", "all-Clients_Europe-pr");
                $Var = 1 = ok, 0 = Failure

   CrtDatalessPM

    * DESCRIPTION
                Create Dataless ProfileManager

    * CALL
                $Var = &CrtDatalessPM(<PolicyRegion, ProfileManager>);

    * SAMPLE
                $Var = &CrtDatalessPM("all-Sample-pr", "all-inv-SW-tmr-pm");
                $Var = 1 = ok, 0 = Failure

   NoResource

    * DESCRIPTION
                Check Tivoli Resource with wlookup

    * CALL
                $Var = &NoResource(<Typ, Resource>);

    * SAMPLE
                $Var = &NoResource("RIM", "inv40");
                $Var = 1 = ok, 0 = Failure

   Wlookup_pm

    * DESCRIPTION
                looks for ProfileManagers which includes the given String

    * CALL
                $Var = &Wlookup_pm(<String>);

    * SAMPLE
                @Arr = &Wlookup_pm("-New_EP-");
                @Arr = Array with ProfileManagers

   Wlsendpts_SearchPms

    * DESCRIPTION
                Lists all the endpoints directly or indirectly subscribed to the given ProfileManager

    * CALL
                $Var = &Wlsendpts_SearchPms(<Name of the ProfileManager>);

    * SAMPLE
                @Arr = &Wlsendpts_SearchPms("all-Server-pm");
                @Arr = Array with Endpoints

   Wgetsub_pm

    * DESCRIPTION
                gets the Subscribers of a given ProfileManager

    * CALL
                $Var = &Wgetsub_pm(<ProfileManager>);

    * SAMPLE
                @Arr = &Wgetsub_pm("all-Clients-pm");
                @Arr = Array with Subscribers

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
            0.01            2001-07-06      RHase           Wlsendpts_SearchPms
            0.01            2001-07-06      RHase           Wlookup_pm
            0.02            2001-07-09      RMahner         NoResource
            0.02            2001-07-09      RMahner         CrtDatalessPM
            0.02            2001-07-09      RMahner         CrtPR
            0.02            2001-07-09      RMahner         ExecuteSys
            0.03            2001-07-13      RHase           Wgetsub_pm
            0.04            2001-08-04      RHase           POD-Doku added

AUTHOR
            Robert Hase
            ID      : RHASE
            eMail   : Tivoli.RHase@Muc-Net.de
            Web     : http://www.Muc-Net.de

SEE ALSO
            CPAN
            http://www.perl.com

