# Copyright (c) 2002-2005 the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics
#       Massachusetts Institute of Technology.
# written by Olivier Thereaux <ot@w3.org> for W3C
#
# $Id: Mail.pm,v 1.13 2005/09/09 06:33:11 ot Exp $

package W3C::LogValidator::Output::Mail;
use strict;


require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/;


###########################
# usual package interface #
###########################
our %config;
our $verbose = 1;

sub new
{
        my $self  = {};
        my $proto = shift;
        my $class = ref($proto) || $proto;
	# configuration for this module
	if (@_) {%config =  %{(shift)};}
	if (exists $config{verbose}) {$verbose = $config{verbose}}
        bless($self, $class);
        return $self;
}

sub output
{
	my $self = shift;
	my %results;
	my $outputstr ="";
	if (@_) {%results = %{(shift)}}
	use W3C::LogValidator::Output::Raw;
	$outputstr = W3C::LogValidator::Output::Raw->output(\%results);
	print $outputstr if ($verbose >2 ); # debug

	return $outputstr;	
}


sub finish
{
# for this module, that means send e-mail to the specified maintainer
 my $self = shift;
        if (@_)
        {
                my $result_string = shift;
		my ($sec,$min,$hour,$day,$mon,$year,$wday,$yday) = gmtime(time);
	        $hour = sprintf ( "%02d", $hour);
		$min = sprintf ( "%02d", $min);
		$mon ++; # weird 'feature': months run 0-11; days run 1-31 :-(
		my $date = ($year+1900) .'-'. ($mon>9 ? $mon:"0$mon") .'-'. ($day>9 ? $day:"0$day");

		if (defined $config{"ServerAdmin"} and $result_string ne "")
		# we have someone to send the mail to
		{
			my $mail_subject = "Logvalidator results";
			if (defined $config{"Title"})
			{
				$mail_subject = $config{"Title"};
			}
			$mail_subject = $mail_subject." ($date at $hour:$min GMT)";
			my $add = $config{"ServerAdmin"};
			my $mail_from = $add;
			if (defined $config{"MailFrom"})
			{
				$mail_from = $config{"MailFrom"};
			}
			use Mail::Sendmail;
			my %mail = (To      => $add,
			From    =>  "LogValidator <$mail_from>",
			Subject => "$mail_subject",
			'X-Mailer' => "Mail::Sendmail version $Mail::Sendmail::VERSION",
			Message => $result_string );
			print "Sending Mail to $add...\n" if ($verbose >1 );
			Mail::Sendmail::sendmail(%mail) or print STDERR $Mail::Sendmail::error;
			if ($verbose >1 ) { print "OK Mail::Sendmail log:\n", $Mail::Sendmail::log, "\n";}
		}
		else { print $result_string; }
	}
	

}

package W3C::LogValidator::Output::Mail;

1;

__END__

=head1 NAME

W3C::LogValidator::Output::Mail - [W3C Log Validator] e-mail output module

=head1 DESCRIPTION

This module is part of the W3C::LogValidator suite, and sends the results
of the log processing and validation as an e-mail message to the webmaster

=head1 AUTHOR

Olivier Thereaux <ot@w3.org>

=head1 SEE ALSO

W3C::LogValidator, perl(1).
Up-to-date complete info at http://www.w3.org/QA/Tools/LogValidator/

=cut
