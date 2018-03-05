# Copyrights 2007-2018 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution XML-Compile-SOAP.  Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package XML::Compile::SOAP::Trace;
use vars '$VERSION';
$VERSION = '3.23';


use warnings;
use strict;

use Log::Report   'xml-compile-soap', syntax => 'REPORT';
  # no syntax SHORT, because we have own error()

use IO::Handle;

my @xml_parse_opts = (load_ext_dtd => 0, recover => 1, no_network => 1);


sub new($)
{   my ($class, $data) = @_;
    bless $data, $class;
}


sub start() {shift->{start}}


sub date() {scalar localtime shift->start}


sub error(;$)
{   my $self   = shift;
    my $errors = $self->{errors} ||= [];

    foreach my $err (@_)
    {   $err = __$err unless ref $err;
        $err = Log::Report::Exception->new(reason => 'ERROR', message => $err)
            unless $err->isa('Log::Report::Exception');
        push @$errors, $err;
    }

    wantarray ? @$errors : $errors->[0];
}


sub errors() { @{shift->{errors} || []} }


sub elapse($)
{   my ($self, $kind) = @_;
    defined $kind ? $self->{$kind.'_elapse'} : $self->{elapse};
}


sub request() {shift->{http_request}}


sub response() {shift->{http_response}}


sub responseDOM() {shift->{response_dom}}


sub printTimings(;$)
{   my ($self, $fh) = @_;
    my $oldfh = $fh ? (select $fh) : undef;
    print  "Call initiated at: ",$self->date, "\n";
    print  "SOAP call timing:\n";
    printf "      encoding: %7.2f ms\n", $self->elapse('encode')    *1000;
    printf "     stringify: %7.2f ms\n", $self->elapse('stringify') *1000;
    printf "    connection: %7.2f ms\n", $self->elapse('connect')   *1000;

    my $dp = $self->elapse('parse');
    if(defined $dp) {printf "       parsing: %7.2f ms\n", $dp *1000 }
    else            {printf "       parsing:       -    (no xml to parse)\n" }

    my $dt = $self->elapse('decode');
    if(defined $dt) {printf "      decoding: %7.2f ms\n", $dt *1000 }
    else            {print  "      decoding:       -    (no xml to convert)\n"} 

    my $el = $self->elapse;
    printf "    total time: %7.2f ms = %.3f seconds\n\n", $el*1000, $el
        if defined $el;

    select $oldfh if $oldfh;
}


sub printRequest(;$%)
{   my $self    = shift;
    my $request = $self->request or return;

    my $fh      = @_%2 ? shift : *STDOUT;
    my %args    = @_;

    my $format = $args{pretty_print} || 0;
    if($format && $request->content_type =~ m/xml/i)
    {   $fh->print("\n", $request->headers->as_string, "\n");
        XML::LibXML
          ->load_xml(string => $request->content, @xml_parse_opts)
          ->toFH($fh, $format);
    }
    else
    {   my $req = $request->as_string;
        $req =~ s/^/  /gm;
        $fh->print("Request:\n$req\n");
    }
}


sub printResponse(;$%)
{   my $self = shift;
    my $resp = $self->response or return;

    my $fh   = @_%2 ? shift : *STDOUT;
    my %args = @_;

    my $format = $args{pretty_print} || 0;
    if($format && $resp->content_type =~ m/xml/i)
    {   $fh->print("\n", $resp->headers->as_string, "\n");
        XML::LibXML->load_xml
          ( string => ($resp->decoded_content || $resp->content)
          , @xml_parse_opts
          )->toFH($fh, $format);
    }
    else
    {   my $resp = $resp->as_string;
        $resp    =~ s/^/  /gm;
        $fh->print("Response:\n$resp\n");
    }
}


sub printErrors(;$)
{   my ($self, $fh) = @_;
    $fh ||= *STDERR;

    print $fh $_->toString for $self->errors;

    if(my $d = $self->{decode_errors})  # Log::Report::Dispatcher::Try object
    {   print $fh "Errors while decoding:\n";
        foreach my $e ($d->exceptions)
        {   print $fh "  ", $e->toString;
        }
    }
}

1;
