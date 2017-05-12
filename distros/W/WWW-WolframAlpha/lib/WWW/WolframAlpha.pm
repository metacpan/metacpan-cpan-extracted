package WWW::WolframAlpha;
BEGIN {
  $WWW::WolframAlpha::VERSION = '1.10';
}

use 5.008008;
use strict;
use warnings;

require Exporter;

use WWW::WolframAlpha::ValidateQuery;
use WWW::WolframAlpha::Query;
use WWW::WolframAlpha::Pod;

use URI::Escape qw(uri_escape_utf8);
use XML::Simple qw(:strict);

use LWP::UserAgent;
use HTTP::Request::Common;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use WWW::WolframAlpha ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION ||= '0.0development';

my $xs = XML::Simple->new(
    'KeyAttr' => [],
    'ForceArray' => ['assumption','pod','subpod','source','value','state','info','link','statelist','unit','spellcheck','sound','didyoumean','error'],
    'ValueAttr' => [],
    'VarAttr' => [''],
    'SuppressEmpty' => undef,
    );

sub new {
    my $class = shift;
    my %options = @_;

    my $self = {};
    while(my($key, $val) = each %options) {
	my $lkey = lc($key);
	$self->{$lkey} = $val;
    }

    die qq(no appid) if !$self->{'appid'};

    $self->{'ua'} = get_useragent();    

    return(bless($self, $class));
}

my $ua_agent = 'WWW::WolframAlpha/' . $VERSION;
sub get_useragent {
  my $ua = new LWP::UserAgent(
      agent => $ua_agent,
      );
  return $ua;
}

sub get_response {
    my $self = shift;
    my $url = shift;

    my $timeout = 0;
    {
	my ($scantimeout) = $url =~ /\&scantimeout\=(\d+)/o;
	my ($formattimeout) = $url =~ /\&formattimeout\=(\d+)/o;
	$timeout += $scantimeout || 3;
	$timeout += $formattimeout || 8;
    }

    my $response = '';
    eval {
	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm($timeout);
	$response = $self->{'ua'}->request(GET $url);
	alarm(0);
    };

    my $xml = '';
    my $ref = '';
    $self->{'errmsg'} = '';
    $self->{'error'} = 0;

    if ($@) {
	$self->{'errmsg'} = $@;
	$self->{'error'} = 1;

    } elsif (!$response) {
	$self->{'errmsg'} = 'unknown request error';
	$self->{'error'} = 1;

    } elsif ($response->code != '200') {
	$self->{'errmsg'} = $response->code . ' ' . $response->message;
	$self->{'error'} = 1;

    } else {
	$xml = $response->content;

	eval {
	    $ref = $xs->XMLin($xml);
	};

	if (!$ref) {
	    $self->{'errmsg'} = 'bad xml response';
	    $self->{'error'} = 1;
	}
    }   

    return ($xml,$ref);
}

sub construct_url {
    my ($method,$appid,%param) = @_;
#    my $url = 'http://preview.wolframalpha.com/api/v1/' . $method . '.jsp?';
    my $url = 'http://api.wolframalpha.com/v1/' . $method . '.jsp?';
    $url .= 'appid=' . $appid;

    if (exists $param{'url'}) {
	$url = $param{'url'};
    }

    foreach my $param (keys %param) {
	next if $param eq 'url';

	if ($param eq 'podtitle' && $param{$param} =~ /,/) {
	    my @param = split(/\,/,$param{$param});
	    SUB_PARAM: foreach my $sub_param (@param) {
		next SUB_PARAM if !$sub_param;
		$url .= '&' . $param . '=' . uri_escape_utf8($sub_param);
	    }

	} else {
	    $url .= '&' . $param . '=' . uri_escape_utf8($param{$param});
	}
    }

    # For debugging.
#    warn $url;

    return $url;
}

sub validatequery {
    my $self = shift;
    my ($url) = construct_url('validatequery',$self->{'appid'},@_);
    my ($xml,$ref) = get_response($self,$url);

    my $object =  WWW::WolframAlpha::ValidateQuery->new(
	xml => $xml,
	xmlo => $ref,
	);

    return $object;
}

sub query {
    my $self = shift;
    my ($url) = construct_url('query',$self->{'appid'},@_);
    my ($xml,$ref) = get_response($self,$url);

    my $object =  WWW::WolframAlpha::Query->new(
	xml => $xml,
	xmlo => $ref,
	);

    return $object;
}

sub asyncPod {
    my $self = shift;
    my ($url) = construct_url('query',$self->{'appid'},@_);
    my ($xml,$ref) = get_response($self,$url);

    my $object =  WWW::WolframAlpha::Pod->new($ref);

    $object->{'xml'} = $xml;
    $object->{'xmlo'} = $ref;

    return $object;
}

sub error {shift->{'error'};}
sub errmsg {shift->{'errmsg'};}

# Preloaded methods go here.

1;


=pod

=head1 NAME

WWW::WolframAlpha

=head1 VERSION

version 1.10

=head1 SYNOPSIS

  use WWW::WolframAlpha;

  my $wa = WWW::WolframAlpha->new (
    appid => 'XXX',
  );

  my $query = $wa->query(
    input => 'Pi',
  );

  if ($query->success) {
    foreach my $pod (@{$query->pods}) {	    
      ...
    }
  }

=head1 DESCRIPTION

See the included example.*.pl files for full working examples.

Access to this module is strictly OO. Pass your appid to the constructor, which is the only parameter needed.

There are three functions available, query, validatequery and asyncPod, which match the API calls. 

Pass any desired input paramters to the function calls. The 'input' parameter is required.

Each function call returns objects, of the forms L<WWW::WolframAlpha::Query>, L<WWW::WolframAlpha::ValidateQuery> and L<WWW::WolframAlpha::Pod>, respectively.

See the WolframAlpha API docs for details on the overall API, what parameters you can input and what you can expect in response. 

All the attributes and elements detailed in the API docs are available via the returned objects. See the documentation in L<WWW::WolframAlpha::Query>, L<WWW::WolframAlpha::ValidateQuery>, L<WWW::WolframAlpha::Pod> and other sub-packages for details on what methods are available for particular objects.

=head2 ERROR HANDLING

If there are errors contacting WA, $wa->error will be set to 1 and $wa->errmsg should give you some indication of what is going on.

Errors returned by WA are handled within the objects themselves via success and error methods (see example.*.pl files).

=head2 DEBUGGING

For debugging, the raw XML output and the internal Perl object used (via L<XML::Simple>) are available via the xml and xmlo methods. However, please don't rely on these, i.e. only use them for debugging.

=head2 EXPORT

None by default.

=head1 NAME

WWW::WolframAlpha - Perl extension for the WolframAlpha API

=head1 SEE ALSO

B<WWW::WolframAlpha> requires L<XML::Simple>, L<LWP::UserAgent>, L<URI::Escape> and L<HTTP::Request::Common>.

http://www.wolframalpha.com/

=head1 AUTHOR

Gabriel Weinberg, E<lt>yegg@alum.mit.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Gabriel Weinberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 AUTHOR

Gabriel Weinberg <yegg@alum.mit.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Gabriel Weinberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
# Below is stub documentation for your module. You'd better edit it!

