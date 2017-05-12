package WWW::Chat;
$VERSION = '0.65';
use strict;
require Exporter;
*import = \&Exporter::import;
#use vars qw(@EXPORT_OK);
#@EXPORT_OK=qw(fail OK ERROR);

use Carp ();

sub fail
{
    my ($reason, $mres, $mct) = @_;
    $mres ||= $main::res;
    $mct  ||= $main::ct;
    Carp::carp("FAILED $reason");
    
    # Print current response too...
    my $res = $mres->clone;
    my $cref = $res->content_ref;
    if ($mct =~ m,^text/,) {
	substr($$cref, 256) = "..." if length($$cref) > 512;
    } else {
	$$cref = "";
    }
    $res = $res->as_string;
    $res =~ s/^/  /gm;
    print STDERR $res;

    die "ASSERT";
}

sub check_eval
{
    return unless $_[0];
    return if $_[0] =~ /^ASSERT /;
    print STDERR $_[0];
}


sub OK
{
    my $mstatus = shift;
    $mstatus ||= $main::status;
    $mstatus == 200;
}

sub ERROR
{
    my $mstatus = shift;
    $mstatus ||= $main::status;
    $mstatus >= 400 && $mstatus < 600;
}

sub request
{
    my ($req, $mua, $MTRACE) = @_;
    $mua    ||= $main::ua;
    $MTRACE ||= $main::TRACE;
    print STDERR ">> " . $req->method . " " . $req->uri . " ==> "
	if $MTRACE;
    #print STDERR "\nCC " . $req->content . "\n" if $MTRACE;
    my $res = $mua->request($req);
    print STDERR $res->status_line . "\n"
	if $MTRACE;
    $res;
}

sub findform
{
    my($forms, $no, $uri) = @_;
    my $f = $forms->[$no-1];
    Carp::croak("No FORM number $no") unless $f;
    my $furi = $f->uri;
    Carp::croak("Wrong FROM name ($furi)") if $uri && $furi !~ /$uri$/;
    $f;
}

sub extract_links
{
    require HTML::TokeParser;
    my $p = HTML::TokeParser->new(\$_[0]);
    my @links;

    while (my $token = $p->get_tag("a")) {
	my $url = $token->[1]{href};
	next unless defined $url;   # probably just a name link
	my $text = $p->get_trimmed_text("/a");
	push(@links, [$url => $text]);
    }
    return @links;
}

sub locate_link
{
    my($where, $links, $base) = @_;
    my $no_links = @$links;
    Carp::croak("Only $no_links links on this page ($where)") if $where >= $no_links;
    require URI;
    URI->new_abs($links->[$where][0], $base);
}

1;

__END__

=pod

=head1 NAME

WWW::Chat - support module for web chat script.

=head1 SYNOPSIS

  
  # none ... 
  # this module is not intended to be used 
  # except by processed webchat scripts.
  

=head1 DESCRIPTION

The C<webchatpp> program is a preprocessor that turns chat scripts
into plain perl scripts.  When this script is fed to perl it will 
perform the chatting.  The I<webchat language> consist of perl code
with some lines interpreted and expanded by B<WWW::Chat::Processor>.  

The interpreted scripts call functions in this module.

See L<webchatpp> for more details.

=head1 ENVIRONMENT

The initial value of the $TRACE variable is initialized from the
WEBCHAT_TRACE environment variable.

Proxy settings are picked up from the environment too. See
L<LWP::UserAgent/env_proxy>.


=head1 SEE ALSO

L<webchatpp>, L<WWW::Chat::Processor>, L<LWP>, L<HTML::Form>

=head1 COPYRIGHT

Copyright 1998 Gisle Aas.

Modified 2001 Simon Wistow <simon@thegestalt.org>.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
