package Tivoli::Endpoints;

our(@ISA, @EXPORT, $VERSION, $Fileparse_fstype, $Fileparse_igncase);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(ExecuteSys SubscrEP UnsubscrEP CheckEPinTMR);

# Robert.Hase@sysmtec.de
# 07-2001
# thanks to Rosie

$VERSION = '0.02';

################################################################################################

=pod

=head1 NAME

	Tivoli::Endpoints - Perl Extension for Tivoli

=head1 SYNOPSIS

	use Tivoli::Endpoints;


=head1 VERSION

	v0.02

=head1 License

	Copyright (c) 2001 Robert Hase.
	All rights reserved.
	This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 DESCRIPTION

=over

	This Package will handle about everything you may need for Endpoints.
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

=head3 SubscrEP

=over

=item * DESCRIPTION

	Subscribe Endpoint to ProfileManager

=item * CALL

	$Var = &SubscrEP(<ProfileManager, Endpoint>);

=item * SAMPLE

	$Var = &SubscrEP("all-inv-HW_DIFF-ca-pm", "WBK0815");
	$Var = 1 = ok, 0 = Failure

=back

=cut

sub SubscrEP
{
        ($p_pm, $p_ep)=@_;
        $l_cmd="wsub \@ProfileManager:$p_pm \@Endpoint:$p_ep";
        $l_rc=&ExecuteSys ($l_cmd);
        if ($l_rc) { return(0); }
        return(1);
}

=pod

=head3 UnsubscrEP

=over

=item * DESCRIPTION

	Unsubscribe Endpoint from ProfileManager

=item * CALL

	$Var = &UnsubscrEP(<ProfileManager, Endpoint>);

=item * SAMPLE

	$Var = &UnsubscrEP("all-inv-HW_DIFF-ca-pm", "WBK0815");
	$Var = 1 = ok, 0 = Failure

=back

=cut

sub UnsubscrEP
{
        ($p_pm, $p_ep)=@_;
        $l_cmd="wunsub \@ProfileManager:$p_pm \@Endpoint:$p_ep";
        $l_rc=&ExecuteSys ($l_cmd);
        if ($l_rc) { return(0); }
        return(1);
}

=pod

=head3 CheckEPinTMR

=over

=item * DESCRIPTION

	Check, if Endpoint in TMR

=item * CALL

	$Var = &CheckEPinTMR(<Endpoint>);

=item * SAMPLE

	$Var = &CheckEPinTMR(""WBK0815");
	$Var = 1 = ok, 0 = Failure

=back

=cut

sub CheckEPinTMR
{
        ($p_ep)=@_;
        $l_erg=0;
        $l_cmd="wep $p_ep > /dev/null 2>&1";
        $rc=0xffff & system $l_cmd;
        if ( $rc == 0 ) { $l_erg=1; }
        return $l_erg;
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
	0.01		2001-07-09	RMahner		ExecuteSys
	0.01		2001-07-09	RMahner		SubscrEP
	0.01		2001-07-09	RMahner		UnsubscrEP
	0.01		2001-07-09	RMahner		CheckEPinTMR
	0.02		2001-08-04	RHase		POD-Doku added

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
