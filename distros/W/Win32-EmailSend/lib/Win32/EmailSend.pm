package Win32::EmailSend;

use warnings;
use strict;
use Win32::OLE;

our $VERSION = '0.04';

BEGIN {
	use Exporter;
	our @ISA         = qw( Exporter );
	our @EXPORT      = qw( );
	our %EXPORT_TAGS = ( );
	our @EXPORT_OK   = qw( &SendIt );
}

sub SendIt($;$$;$$$;$$$$) {

	my $to      = shift;
	my $cc      = shift;
	my $subject = shift;
	my $body    = shift;

	defined $to or $to = "";

	($to) or die "USAGE: $0\n       <\"To\">\n       [<\"Cc\">]\n       [<\"Subject\">]\n       [<\"Body\">]\n       [<\"Attachment 1\">]\n       [<\"Attachment 2\">]\n       [<\"Attachment ...\">]\n";

	my $email = Win32::OLE->new('Outlook.Application') or die $!;
	my $items = $email->CreateItem(0) or die $!;

	$items->{'To'}      = $to;
	$items->{'CC'}      = $cc;
	$items->{'Subject'} = $subject;
	$items->{'Body'}    = $body;

	foreach my $attach (@ARGV) {
		die $! if not -e $attach;

		my $attachments = $items->Attachments();
		$attachments->Add($attach);

	} # foreach

	$items->Send();

	my $error = Win32::OLE->LastError();
	print "Email ok.\n" if not $error;
	print "Email ko.\n" if $error;

} # SendIt

1;
__END__

=pod

=head1 NAME

EmailSend - a module for send emails [with Attachments] via Microsoft Outlook

=head1 SYNOPSIS

  use warnings;
  use strict;
  use EmailSend qw( SendIt );

  SendIt('name@domain.com');

=head1 ABSTRACT

Test

=head1 DESCRIPTION

...

=head1 AUTHOR AND LICENSE

copyright 2009 (c)
Gernot Havranek

=cut
