# $Id: HTML.pm 517 2008-06-30 23:48:04Z rick $
package iCal::Parser::HTML;

use strict;
use warnings;

# Get version from subversion url of tag or branch.
our $VERSION= do {(q$URL: svn+ssh://xpc/var/lib/svn/rick/perl/ical/iCal-Parser-HTML/tags/1.07/lib/iCal/Parser/HTML.pm $=~ m$.*/(?:tags|branches)/([^/ \t]+)$)[0]||'0.1'};

our @ISA = qw(Exporter);
our @EXPORT_OK=qw($xml $xsl);

use iCal::Parser::SAX;
use XML::LibXML;
use XML::LibXML::SAX::Builder;
use XML::LibXSLT;

our $xsl=XML::LibXSLT->new;
our $xml=XML::LibXML->new;

our %sheet_cache=();

sub new {
    my $class=shift;
    return bless {@_},$class;
}
sub parse {
    my($self,%args)=@_;
    my $type=delete $args{type};
    my $files=delete $args{files};
    my $url=delete $args{url}||'';
    #adjust dates to appropriate period
    my $start=$args{start};
    unless(ref $start) {
	$start=$args{start}=$self->parse_partial_datetime($start);
    }
    $start->subtract(days=>$start->dow-1) if $type eq 'week';
    $start->set(day=>1) if $type eq 'month';
    $start->set(day=>1,month=>1) if $type eq 'year';
    $args{end}=$start->clone->add("${type}s"=>1);

    my $sink=XML::LibXML::SAX::Builder->new;
    my $parser=iCal::Parser::SAX->new(Handler=>$sink,%args);
    my $result=$parser->parse_uris(@$files);

    my $sheet=$sheet_cache{$type}||=$xsl
    ->parse_stylesheet($xml->parse_file(get_sheet_dir() . $type . '.xsl'));

    return $sheet->output_string
    ($sheet->transform($result,$self->sheet_args($args{start},$url)));
}
sub parse_partial_datetime {
    my($self,$string)=@_;
    my($y,$m,$d)=($string=~ m/(\d{4})-?(\d{2})?-?(\d{2})?/);

    my $date=$y ? DateTime->new(year=>$y,
				($m ? (month=>$m) :()),
				($d ? (day=>$d):())
			       ) : DateTime->now;
}
sub sheet_args {
    my($self,$date,$url)=@_;
    my %args;
    foreach my $t qw(week month year) {
		$args{$t}=$date->$t();
    }
    $args{date}='"'.$date->ymd .'"';
    $args{'base-url'}='"'.$url.'"';
    return %args;
}
sub get_sheet_dir {
    my $key=__PACKAGE__ . '.pm';
    $key=~s|::|/|go;
    my $path=$INC{$key};
    $path=~s|\.pm$|/stylesheet/|go;
    return $path;
}
1;
__END__

=head1 NAME

iCal::Parser::HTML - Generate HTML calendars from iCalendars

=head1 SYNOPSIS

  use iCal::Parser::HTML;
  my $parser=iCal::Parser::HTML->new;
  print $parser->parse(type=>$type,start=>$date,files=>[@icals]);

=head1 DESCRIPTION

This module uses L<iCal::Parser::SAX> and L<XML::LibXSLT> with
included stylesheets to generates html calendars from icalendars.

The html document generated includes (when appropriate) a sidebar
containing a legend, a list of todos and a three month calendar for
the previous, current and next months.

The stylesheets are stored in the HTML/stylesheet directory under the
installed package directory.

Also included in this package are an optionally installed command line
program L<scripts/ical2html> and, in the example directory, a cgi handler
(L<examples/ical.cgi>) and a stylesheet (L<examples/calendar.css>)
for formatting the html output. Note that the html output will
look quite broken without the stylesheet.

=head1 ARGUMENTS

The following arguments are processed by this module. Any addtional
arguments are passed to L<iCal::Parser::SAX>.

=over 4

=item type

The type of calendar to generate. One of: C<day>, C<week>, C<month> or
C<year>.  The daily, weekly and monthly calendars include the
sidebar. The calendar generated will be for the specified period (day,
week, etc.) which includes the specified date.

=item start

The date to generated the calendar for. The date only needs to be
specified to the precision necessary for the type of calendar. That
is, C<YYYY> for a yearly calendar, C<YYYYMM> for a monthly, and
C<YYYYMMDD> for daily and weekly. In addition, the date can be in one
of the following forms:

=over 4

=item YYYY[MM[DD]]

=item YYYY[-MM[-DD]]

=item A L<DateTime> object initialized to the necessary precision

=back

=item files

An array reference to the list of icalendars to include in the results.

=item url

If this params is specified, then the html output will contain
links back to this url for getting other calendar periods.
The params C<type> and C<date> will be appended to this url 
when generating the links.

=back

=head1 AUTHOR

Rick Frankel, cpan@rickster.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<iCal::Parser::SAX>, L<XML::LibXML::SAX::Builder>, L<XML::LibXSLT>, L<DateTime>
