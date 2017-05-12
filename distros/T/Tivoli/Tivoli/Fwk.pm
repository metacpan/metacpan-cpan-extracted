package Tivoli::Fwk;

our(@ISA, @EXPORT, $VERSION, $Fileparse_fstype, $Fileparse_igncase);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(ExecuteSys CrtPR CrtDatalessPM NoResource Wlookup_pm Wlsendpts_SearchPms Wgetsub_pm);

$VERSION = '0.04';

################################################################################################

=pod

=head1 NAME

	Tivoli::Fwk - Perl Extension for Tivoli

=head1 SYNOPSIS

	use Tivoli::Fwk;


=head1 VERSION

	v0.04

=head1 LICENSE

	Copyright (c) 2001 Robert Hase.
	All rights reserved.
	This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 DESCRIPTION

=over

	This Package will handle about everything you may need for Framework.
	If anything has been left out, please contact me at
	tivoli.rhase@muc-net.de
	so it can be added.

=back

=head2 DETAILS

	still in work

=head2 ROUTINES

	Description of Routines

=head3 ExecuteSys

=over

=item * DESCRIPTION

	Execute Unix Command with system

=item * CALL

	$Var = &ExecuteSys(<Command>);

=item * SAMPLE

	$Var = &ExecuteSys('ls');
	$Var = returncode from the Command

=back

=cut

sub ExecuteSys
{
        ($p_cmd)=@_;
        my ($rc) ;
        $command = "$p_cmd 2>>/dev/null";
        $rc=0xffff & system $command;
	return $rc;
}

=pod

=head3 CrtPR

=over

=item * DESCRIPTION

	Create PolicyRegion

=item * CALL

	$Var = &CrtPR(<TopPolicyRegion, PolicyRegion>);

=item * SAMPLE

	$Var = &CrtPR("top-Company_Europe_pr", "all-Clients_Europe-pr");
	$Var = 1 = ok, 0 = Failure

=back

=cut

sub CrtPR
{
        ($p_tpr, $p_pr)=@_;
        $l_cmd = "wcrtpr -s \@PolicyRegion:$p_tpr -m ProfileManager $p_pr";
        $l_rc=&ExecuteSys ($l_cmd);
        if ($l_rc) { return(1); }
	return(0);
}

=pod

=head3 CrtDatalessPM

=over

=item * DESCRIPTION

	Create Dataless ProfileManager

=item * CALL

	$Var = &CrtDatalessPM(<PolicyRegion, ProfileManager>);

=item * SAMPLE

	$Var = &CrtDatalessPM("all-Sample-pr", "all-inv-SW-tmr-pm");
	$Var = 1 = ok, 0 = Failure

=back

=cut

sub CrtDatalessPM
{
        ($p_pr, $p_pm)=@_;
        $l_cmd = "wcrtprfmgr  \@PolicyRegion:$p_pr  $p_pm";
        $l_rc=&ExecuteSys ($l_cmd);
        if ($l_rc) { &Error ("Error executing $l_cmd")};
        $l_cmd = "wsetpm -d  \@ProfileManager:$p_pm";
        $l_rc=&ExecuteSys ($l_cmd);
        if ($l_rc) {return(1);}
	return(0);
}

=pod

=head3 NoResource

=over

=item * DESCRIPTION

	Check Tivoli Resource with wlookup

=item * CALL

	$Var = &NoResource(<Typ, Resource>);

=item * SAMPLE

	$Var = &NoResource("RIM", "inv40");
	$Var = 1 = ok, 0 = Failure

=back

=cut

sub NoResource
{
        ($p_typ, $p_res)=@_;
        $l_cmd="wlookup -r $p_typ $p_res >/dev/null 2>&1";
        $rc=0xffff & system $l_cmd;
        if ( $rc == 0 ) {return(1);}
	return(0);
}

=pod

=head3 Wlookup_pm

=over

=item * DESCRIPTION

	looks for ProfileManagers which includes the given String

=item * CALL

	$Var = &Wlookup_pm(<String>);

=item * SAMPLE

	@Arr = &Wlookup_pm("-New_EP-");
	@Arr = Array with ProfileManagers

=back

=cut

sub Wlookup_pm
{
        my($l_searchstring) = $_[0];
        my(@l_pm, @l_pm_erg);
        my($l_cli);
        $l_cli = "wlookup -aLr ProfileManager |grep $l_searchstring";
        @l_pm = `$l_cli`;
        if($? != 0)
        {
                return(0);
        }
        foreach $l_dummy (@l_pm)
        {
                chomp($l_dummy);
                $l_dummy =~ s/\s.*$//;
                push(@l_pm_erg, $l_dummy);
        }
        return(@l_pm_erg);
}

=pod

=head3 Wlsendpts_SearchPms

=over

=item * DESCRIPTION

	Lists all the endpoints directly or indirectly subscribed to the given ProfileManager

=item * CALL

	$Var = &Wlsendpts_SearchPms(<Name of the ProfileManager>);

=item * SAMPLE

	@Arr = &Wlsendpts_SearchPms("all-Server-pm");
	@Arr = Array with Endpoints

=back

=cut

sub Wlsendpts_SearchPms
{
        my($p_pm) = $_[0];
        my($l_dummy);
        my(@l_ep, @l_ep_result);
        $l_dummy = "wlsendpts \@${p_pm}";
        @l_ep = `$l_dummy`;

        if($? != 0)
        {
                return(0);
        }
        foreach $l_dummy (@l_ep)
        {
                chomp($l_dummy);
                $l_dummy =~ s/\s.*\)$//;
                push(@l_ep_result, $l_dummy);
        }
        return(@l_ep_result);
}

=pod

=head3 Wgetsub_pm

=over

=item * DESCRIPTION

	gets the Subscribers of a given ProfileManager

=item * CALL

	$Var = &Wgetsub_pm(<ProfileManager>);

=item * SAMPLE

	@Arr = &Wgetsub_pm("all-Clients-pm");
	@Arr = Array with Subscribers

=back

=cut

sub Wgetsub_pm
{
        my($l_pm) = $_[0];
        my($l_dummy);
        my(@l_subs, @l_subs_result);
        $l_dummy = "wgetsub \@ProfileManager:$l_pm";
        @l_subs = `$l_dummy 2>/dev/null`;
        chomp(@l_subs);
        return(@l_subs);
}

=pod

=head2 Plattforms and Requirements

=over

	Supported Plattforms and Requirements

=item * Plattforms

	tested on:

	- aix4-r1 (AIX 4.3)

=back

=item * Requirements

	requires Perl v5 or higher

=back

=head2 HISTORY

	VERSION		DATE		AUTHOR		WORK
	----------------------------------------------------
	0.01		2001-07-06	RHase		created
	0.01		2001-07-06	RHase		Wlsendpts_SearchPms
	0.01		2001-07-06	RHase		Wlookup_pm
	0.02		2001-07-09	RMahner		NoResource
	0.02		2001-07-09	RMahner		CrtDatalessPM
	0.02		2001-07-09	RMahner		CrtPR
	0.02		2001-07-09	RMahner		ExecuteSys
	0.03		2001-07-13	RHase		Wgetsub_pm
	0.04		2001-08-04	RHase		POD-Doku added

=head1 AUTHOR

	Robert Hase
	ID	: RHASE
	eMail	: Tivoli.RHase@Muc-Net.de
	Web	: http://www.Muc-Net.de

=head1 SEE ALSO

	CPAN
	http://www.perl.com

=cut

###############################################################################################

1;
