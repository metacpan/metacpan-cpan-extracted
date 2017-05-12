#!/usr/local/bin/perl -w
#$Id: ical.cgi 5 2005-03-19 23:27:33Z rick $
use strict;

use iCal::Parser::HTML qw($xsl $xml);
use DateTime;
use CGI;

our $VERSION=sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

our $caldir=$ENV{ICALDIR}||'.';

my $q=CGI->new;
my $html=iCal::Parser::HTML->new;


print $q->header(-type=>'text/html',-charset=>'utf-8');
my @files=$q->param('file');
unless(@files) {
    print_index();
    exit 0;
}
my $date=$q->param('date')||DateTime->now();
my $type=$q->param('type')||'month';
$q->delete(qw|date type file submit|);
my $base_url=$q->url(-query=>1);

#add files to url
$base_url .= '?' . join(';',map {"file=$_"} @files);

print $html->parse(type=>$type,start=>$date,
		   url=>$base_url,
		   dir=>$caldir,
		   files=>[map {"$caldir/$_.ics"} @files]);
exit 0;

sub print_index {
    my @files=glob("$caldir/*.ics");
    my $builder=XML::LibXML::SAX::Builder->new;
    my %nh=(Name=>'file');
    my %rh=(Name=>'files');
    $builder->start_document;
    $builder->start_element(\%rh);
    foreach my $f (@files) {
	$builder->start_element(\%nh);
	$builder->characters({Data=>$f=~m|$caldir/(.+)\.ics$|});
	$builder->end_element(\%nh);
    }
    $builder->end_element(\%rh);
    my $doc=$builder->end_document;

    my $sheet=$xsl->parse_stylesheet
    ($xml->parse_file($html->get_sheet_dir() . 'index.xsl'));
    print $sheet->output_string($sheet->transform($doc));
}

=head1 NAME

ical.cgi - Convert iCalendar files to HTML

=head1 SYNOPSIS


=head1 DESCRIPTION

This program uses L<iCal::Parser::HTML> to convert iCalendar files to HTML.

Mutlple input files are merged into a single HTML calendar.

=head1 USAGE

The script should be named C<index.cgi>, and placed in the same
directory as the calendar files (named C<*.ics>) to be displayed.

If called with no arguments, the script will display a simple
form, allowining one or more of the calendars in the current
directory to be displayed.

Alternately, if the environment variable C<ICALDIR> is set to
it will be used as the input directory in which to find the calendars
to process.

=head1 AUTHOR

Rick Frankel, cpan@rickster.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<iCal::Parser::HTML>
