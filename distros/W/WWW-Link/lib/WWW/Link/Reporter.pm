=head1 NAME

WWW::Link::Reporter - report information about a link back to a user

=head1 SYNOPSIS

    package WWW::Link::Reporter::somethingorother
    use WWW::Link::Reporter;
    sub broken {print "something..."; ... }
    sub not_found {print "or...; ... }
    sub redirected {print "other...; ... }
    sub okay ...
    sub not_perfect ....

=head1 DESCRIPTION

This class is really a base class upon which other classes can be
built.  These classes will allow feedback to users about what the
status of various links is.

The class provides one facility in that it will gather some statistics
on the links that are fed to it.

=head1 SUBCLASSES

Here is a list of the subclasses which come in the default
distribution.  Each one should have a more detailed description (but
probably doesn't ;-)

=over

=item Text

A simple text output listing which links are broken.

=item HTML

An HTML page with a list of the broken links.

=item RepairForm

Generates an HTML page which will drive C<fix-link.cgi> (provided with
this package) to fix links.

=item LongList

Runs C<ls -l> on files which contain broken links giving a format
which emacs can interpret for editing (see special emacs mode
B<link-report-dired> provided).

=item Compile

For use whilst checking links in a file online.  Generates an emacs
compile mode style listing which can be used to go directly to the
line needing corrected in the editor.

=back

Other subclasses can be created by overriding the built in methods
(see below).

The default class supports storing an index object which could be used
for getting information about the link.  However it doesn't do
anything with it.

=cut

package WWW::Link::Reporter;
$REVISION=q$Revision: 1.10 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

#default value for verbosity..
#$WWW::Link::Reporter::verbose=0xFF;
$WWW::Link::Reporter::verbose=0x00;

use WWW::Link;
use Carp; #or CGI::carp??

=head1 METHODS

=head2 new WWW::Link::Reporter [$index]

New sets up a new reporter.  If it is given a suitable index, then it
will store this for later use during reporting.

=cut

sub new ($;$) {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{"index"}=shift;
  ref $index or croak "index must be a reference" if defined $index;
  bless ($self, $class);
  #next come settings
  $self->{"verbose"}=$WWW::Link::Reporter::verbose;
  $self->init() ;
  $self->default_reports();
  return $self;
}

=head2 $reporter->set_index ( $index )

We can set the index that we are using.

=cut

sub set_index {
  my $self=shift;
  $self->{"index"}=shift;
}

=head2 $reporter->examine ( $link )

The examine class calls appropriate methods of the reporter to give to
give information about the link, depending on its status.  By
overriding the methods in the default class (see below) you can make
any kind of report you wish.  Individual method calls can be turned on
or off using boolean variables in the object (again see below).

Normally there's no need to override this.

=cut

sub examine {
  my $self=shift;
  my $link=shift;

  croak 'usage $reporter->examine($link)' unless ref $link;

  my $url=$link->url();

  print STDERR "WWW::Link::Reporter::examine looking at $url\n"
    if $self->{"verbose"} & 8;

  $self->{"total"}++ ;

 CASE: {

#    no strict refs;
    my $redir=0;
    $link->is_redirected and $redir=1;

    foreach my $status ( "broken", "okay", "not_checked",
			 "damaged", "disallowed", "unsupported" ) {
      my $testfn = "is_" . $status;
      my $reportvar = "report_" . $status;
      my $showfn = $status;

      $link->$testfn() && do {
	($self->{$reportvar} or $redir && $self->{report_redirected})
	  and $self->$showfn($link, $redir) ;
	last CASE;
      };
    }

    $self->{"report_unknown"} && $self->unknown($link);
  }

  print STDERR "WWW::Link::Reporter::examine finished $url\n"
    if $self->{"verbose"} & 8;
  return 0;			#we reported nothing..
}

=head2 init

In this class init just re-initialises the statistics the class
gathers.  It is called automatically by the constructor.  Generally it
will be over-ridden by a sub class if needed.

=cut

sub init {
  my $self=shift;
  my $setting=0;

  $self->{"broken_count"} = $setting;
  $self->{"okay_count"} = $setting;
  $self->{"redirected_count"} = $setting;
  $self->{"not_checked_count"} = $setting;
  $self->{"disallowed_count"} = $setting;
  $self->{"unsupported_count"} = $setting;
  $self->{"unknown_count"} = $setting;
}

=head2 dummy methods

  $s->okay $s->not_perfect $s->redirected $s->broken
  $s->unsupported $s->disallowed

These methods are designed to be overriden in derived classes.  The
appropriate function is called by $s->examine depending on the state
of the link.  These dummy simply increment a count of each kind of
link.  The one exception is unknown which also issues a warning.

=over

=item broken

Is called when a link was found broken enough times that we consider
it permenantly broken.  Controlled $self->{"report_broken"}.

=item okay

Is called when there link has been checked and found to be okay. This
is controlled by $self->{"report_okay"}.  N.B. this will exclude links
which have never been checked.  Use not_checked for those.

=item damaged

Is called when a link was found broken, but not enough times for us to
consider it permanently broken.  Controlled by
$self->{"report_not_perfect"}.

This link is exactly the kind of thing which the linkcontroller system
was designed to avoid (links which have not been broken for long and
will probably soon be repaired), so probably you don't want to use
not_perfect unless for some reason you are reporting links which are
okay or the user explicitly asks you to.

=item redirected

Is called when a redirect was returned by the server serving the
resource.  Controlled $self->{"report_redirected"}.

=item unsupported

Is called when for some reason a link couldn't be checked at all.
This would typically be some unsupported scheme.  Controlled
$self->{"report_unsupported"}.

=item disallowed

Is called when checking of the link is disallowed.  The status of the
link its self cannot be known.  $self->{"report_unsupported"}.

=item not_checked

Is called when for some reason a link hasn't yet been checked.

=item unknown

Is called when the status of a link is not understood by this module.
This should normally be considered an error condition and this module
produces a warning.

=back

=cut

sub heading {
  1;
}

sub footer {
  1;
}

sub broken {
  my $self=shift;
  $self->{"broken_count"} ++;
}

sub okay {
  my $self=shift;
  $self->{"okay_count"} ++;
}

sub damaged {
  my $self=shift;
  $self->{"damaged_count"} ++;
}

sub redirected {
  my $self=shift;
  $self->{"redirected_count"} ++;
}

sub not_checked {
  my $self=shift;
  $self->{"not_checked_count"} ++;
}

sub disallowed {
  my $self=shift;
  $self->{"disallowed_count"} ++;
}

sub unsupported {
  my $self=shift;
  $self->{"unsupported_count"} ++;
}

sub unknown {
  my ($self,$link)=@_;
  warn "link found with an unknown status " . $link->url();
  $self->{"unknown_count"} ++;
}

=head2 not_found

This method should be called from outside the module when a link which
should be in the links database isn't there.

=cut

sub not_found {
  carp "link not found in database";
}

=head2 all_reports

This sets the flag about what we will report for every single kind of
report and can be used to make a very noisy or a very quiet reporter.

=cut

sub all_reports {
  my $self=shift;
  my $setting=shift;

  $self->{"report_broken"} = $setting;
  $self->{"report_okay"} = $setting;
  $self->{"report_damaged"} = $setting;
  $self->{"report_redirected"} = $setting;
  $self->{"report_not_checked"} = $setting;
  $self->{"report_disallowed"} = $setting;
  $self->{"report_unsupported"} = $setting;
  $self->{"report_unknown"} = $setting;

}

=head2 default_reports

This sets a sensible set of default reporting as follows.

  $self->{"report_broken"} = 1;
  $self->{"report_okay"} = 0;
  $self->{"report_damaged"} = 0;
  $self->{"report_redirected"} = 1;
  $self->{"report_not_checked"} = 0;
  $self->{"report_disallowed"} = 1;
  $self->{"report_unsupported"} = 0;
  $self->{"report_unknown"} = 1;

You can override it no problem.

=cut

sub default_reports {
  my $self=shift;

  $self->{"report_broken"} = 1;
  $self->{"report_okay"} = 0;
  $self->{"report_damaged"} = 0;
  $self->{"report_redirected"} = 1;
  $self->{"report_not_checked"} = 0;
  $self->{"report_disallowed"} = 1;
  $self->{"report_unsupported"} = 0;
  $self->{"report_unknown"} = 1;
}

=head1 report_not_perfect()

this is a convenience function which turns on reports for all link
apart from those which are okay.

=cut

sub report_not_perfect () {
  my ($self,$value)=@_;
  $self->all_reports(1);
  $self->report_okay(0);
}

=head1 report_good()

This sets reporting which should show all links which are probably not
broken.  Currently that defininition includes all redirected links and
those that are unsupported etc. Excludes are broken links and ones
where checking is disallowed.

Since this function is designed for automatic link page
maintainainance, however, as any other ways of detecting broken links
are discovered, those links will be excluded.

=cut

sub report_good () {
  my ($self,$value)=@_;
  $self->all_reports(1);
  $self->report_broken(0);
  $self->report_disallowed(0);
}

=head1 INDIVIDUAL REPORTS

The following functions allow individual reporting functions to be
turned on or off if called with a value (1 turns the report on, 0
turns it off).

If called with no value they simply return the current status of that
report.

=over 4

=item *

report_broken

=item *

report_okay

=item *

report_damaged

=item *

report_redirected

=item *

report_not_checked

=item *

report_disallowed

=item *

report_unsupported

=back

=cut

sub report_broken (;$) {
  my ($self,$value)=@_;
  $self->{"report_broken"} = $value if defined $value;
  $self->{"report_broken"};
}

sub report_okay (;$) {
  my ($self,$value)=@_;
  $self->{"report_okay"} = $value if defined $value;
  $self->{"report_okay"};
}

sub report_damaged (;$) {
  my ($self,$value)=@_;
  $self->{"report_damaged"} = $value if defined $value;
  $self->{"report_damaged"};
}

sub report_redirected (;$) {
  my ($self,$value)=@_;
  $self->{"report_redirected"} = $value if defined $value;
  $self->{"report_redirected"};
}

sub report_not_checked (;$) {
  my ($self,$value)=@_;
  $self->{"report_not_checked"} = $value if defined $value;
  $self->{"report_not_checked"};
}

sub report_disallowed (;$) {
  my ($self,$value)=@_;
  $self->{"report_disallowed"} = $value if defined $value;
  $self->{"report_disallowed"};
}

sub report_unsupported (;$) {
  my ($self,$value)=@_;
  $self->{"report_unsupported"} = $value if defined $value;
  $self->{"report_unsupported"};
}

1;

