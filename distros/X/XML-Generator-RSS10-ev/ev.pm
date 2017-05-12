## XML::Generator::RSS10::ev
## An extension to Dave Rolsky's XML::Generator::RSS10 to handle event metadata
## Written by Andrew Green, Article Seven, http://www.article7.co.uk/
## Sponsored by Woking Borough Council, http://www.woking.gov.uk/
## Last updated: Friday, 10 March 2006

package XML::Generator::RSS10::ev;

$VERSION = '0.01';

use strict;
use Carp;

use base 'XML::Generator::RSS10::Module';

use Params::Validate qw( validate SCALAR HASHREF OBJECT );

use constant CONTENTS_SPEC => { startdate  => { type => SCALAR | HASHREF | OBJECT },
                                enddate    => { type => SCALAR | HASHREF | OBJECT },
                                location   => { type => SCALAR, optional => 1 },
                                organizer  => { type => SCALAR, optional => 1 },
                                type       => { type => SCALAR, optional => 1 }
                              };

use DateTime;
use DateTime::Format::W3CDTF;

1;

####

sub NamespaceURI {

   'http://purl.org/rss/1.0/modules/event/'

}

####

sub contents {

   my $self = shift;
   my $rss = shift;
   my %p = validate( @_, CONTENTS_SPEC );
   
   foreach my $elt ( sort keys %p ) {
      if (($elt eq 'startdate') || ($elt eq 'enddate')) {
			$self->_evdate($rss,$elt,$p{$elt});
      } else {
         $rss->_element_with_data('ev',$elt,$p{$elt});
      }
      $rss->_newline_if_pretty;
   }
}

####

sub _evdate {
	
	# if we're handed a hashref, convert it to a DateTime object and output it as W3CDTF
	# if we're handed a DateTime object, output it as W3CDTF;
	# if we're handed an integer, treat it as an epoch, make it a DateTime object, and output it as W3CDTF;
	# if we're handed any other scalar, assume it's already W3CDTF and output it verbatim

   my ($self,$rss,$elt,$date) = @_;
	
	my $w3cdtf;
	
	if (ref $date eq 'HASH') { # it's a date definition...
		my $dt = DateTime->new($date);
		my $f = DateTime::Format::W3CDTF->new;
		$w3cdtf = (exists $date->{'hour'} || exists $date->{'minute'} || exists $date->{'second'}) ? $f->format_datetime($dt) : $f->format_date($dt); # use the date alone if the hashref has no time values
	} elsif (ref $date eq 'DateTime') { # it's an object...
		my $f = DateTime::Format::W3CDTF->new;
		$w3cdtf = $f->format_datetime($date);		
	} elsif ($date =~ /^[0-9]+$/) { # it's an epoch...
		my $dt = DateTime->from_epoch( epoch => $date );
		my $f = DateTime::Format::W3CDTF->new;
		$w3cdtf = $f->format_datetime($dt);
	} else {
		$w3cdtf = $date;
	}
	
	$rss->_element_with_data('ev',$elt,$w3cdtf);
	
}

__END__

=head1 NAME

XML::Generator::RSS10::ev - Support for the Event (ev) RSS 1.0 module

=head1 SYNOPSIS

    use XML::Generator::RSS10;
	 use DateTime;
    
    my $rss = XML::Generator::RSS10->new( Handler => $sax_handler, modules => [ qw(ev) ] );
    
    $rss->item(
                title => 'Perl Poetry Recitals',
                link  => 'http://www.example.org/diary/perlpoetry.html',
                description => 'Some lovely Perl poetry, read loudly by Brian Blessed',
                ev => {
                   startdate => { year   => 2006,
                                  month  => 05,
                                  day    => 01,
                                  hour   => 19,
                                  minute => 00,
                                  second => 00,
                                  time_zone  => 'local'
                                },
                   enddate   => { year   => 2006,
                                  month  => 05,
                                  day    => 01,
                                  hour   => 20,
                                  minute => 00,
                                  second => 00,
                                  time_zone  => 'local',
                                },
                   location  => 'Town Hall, Exampleham, UK',
                   organizer => 'Example Organisation, info@example.org',
                   type      => 'Recital'
                }
              );
    
    $rss->channel(
                   title => 'Diary of Events',
                   link  => 'http://www.example.org/diary/',
                   description => 'Forthcoming example events'
                 );

=head1 DESCRIPTION

This module extends Dave Rolsky's L<XML::Generator::RSS10> to provide support for the Event (ev) RSS 1.0 module.

For full details of the Event module specification, see L<http://web.resource.org/rss/1.0/modules/event/>.

Where event data is supplied, the C<startdate> and C<enddate> elements are required.  These should be output in W3CDTF date/time format, as defined at L<http://www.w3.org/TR/NOTE-datetime>.  To help facilitate this, the module accepts four types of value for either element, which will be formatted to W3CDTF.

=head2 Define the date using a hashref

If the module is passed a hashref with date and time values as above, it will create a L<DateTime> object from these and use L<DateTime::Format::W3CDTF> to output in W3CDTF.

If the hashref doesn't contain any time values (C<hour>, C<minute> or C<second>), the output won't either.

=head2 Pass a L<DateTime> object directly

The module will use L<DateTime::Format::W3CDTF> to output the date and time in the correct format.

B<Note:> Since L<DateTime> doesn't distinguish between a date with no time component and midnight, the output of this module when passed a L<DateTime> object directly will I<always> include a time.

=head2 Pass a scalar value in epoch seconds

Alternatively, a time value may be supplied in epoch seconds.  This will be converted internally to a DateTime object, and thence formatted to W3CDTF.

=head2 Pass a string already in in W3CDTF

Any other scalar value passed as a C<startdate> or C<enddate> will be assumed to be already in W3CDTF, and will be output verbatim.


=head1 CHANGES

B<Version 0.01>: Initial release.

=head1 SEE ALSO

L<XML::Generator::RSS10>, L<DateTime>, L<DateTime::Format::W3CDTF>.

=head1 AUTHOR

Andrew Green, C<< <andrew@article7.co.uk> >>.

Sponsored by Woking Borough Council, L<http://www.woking.gov.uk/>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
