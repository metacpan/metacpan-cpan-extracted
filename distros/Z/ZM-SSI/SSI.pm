package ZM::SSI;
$ZM::SSI::VERSION = '0.0.5';
use strict;

sub parse
{
	my $data = shift;
	$data=~s/<!--#include file\s*=\s*"(\S+)"\s*-->/${\(include($1))}/gi;
	$data=~s/<!--#exec cgi\s*=\s*"(\S+)"\s*-->/${\(execcgi($1))}/gi;
	return($data);
}

sub include
{
	my $file=shift;
	$file=$ENV{DOCUMENT_ROOT}.$file if($file=~/^\//);
	my $old;
	$old=$/;
	undef($/);
	open(DATAFOR,$file);
	my $data=<DATAFOR>;
	close(DATAFOR);
	$/=$old;
	$data=parse($data);
	return($data);
}

sub execcgi
{
	my $file=shift;
	if($file=~/^([^?]*)\?(.*)/) # Cut Query string
	{
		$file=$1;
		if($ENV{QUERY_STRING} eq '')
		{
			$ENV{QUERY_STRING}=$2;
		}
		else
		{
			$ENV{QUERY_STRING}.='&'.$2;
		}
	}
	if($file=~/^\//)
    {
        $file=$ENV{DOCUMENT_ROOT}.$file;
    }
    else
    {
		$file="./$file";
    }
	my $data=`$file`;
	$data=~s/^.*\n\n//;
	$data=parse($data);
	return($data);
}
#############################

1;

__END__

=head1 NAME

ZM::SSI - SSI parser for CGI

=head1 VERSION

SSI.pm v 0.0.5

=head1 DESCRIPTION

Parsing SSI from Perl script.
Understand:
  <!--#include file="..." -->
  <!--#exec cgi="..." -->


=head1 METHODS

The following public methods are availible:

=over 4

=item B<ZM::SSI::parse($string);>

Parsing string with HTML code.

=back

=head1 COPYRIGHT

Copyright 2002 Zet Maximum

=head1 AUTHOR

Zet Maximum ltd.
http://www.zmaximum.ru/

=cut
