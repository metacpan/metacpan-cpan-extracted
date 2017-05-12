package WWW::Chain;
BEGIN {
  $WWW::Chain::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Chain::VERSION = '0.003';
}
# ABSTRACT: A web request chain

our $VERSION ||= '0.000';


use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Safe::Isa;

has stash => (
	isa => HashRef,
	is => 'lazy',
);

sub _build_stash {{}}

has next_requests => (
	isa => ArrayRef,
	is => 'rwp',
	clearer => 1,
	required => 1,
);

has next_coderef => (
	#isa => CodeRef,
	is => 'rwp',
	clearer => 1,
);

has done => (
	isa => Bool,
	is => 'rwp',
	default => sub { 0 },
);

has request_count => (
	isa => Num,
	is => 'rwp',
	default => sub { 0 },
);

has result_count => (
	isa => Num,
	is => 'rwp',
	default => sub { 0 },
);

sub BUILDARGS {
	my $self = shift;
	return $_[0] if (scalar @_ == 1 && ref $_[0] eq 'HASH');
	my ( $next_requests, $next_coderef, @args ) = $self->parse_chain(@_);
	return {
		next_requests => $next_requests,
		next_coderef => $next_coderef,
		request_count => scalar @{$next_requests},
		@args,
	};
}

sub parse_chain {
	my ( $self, @args ) = @_;
	my $coderef;
	my @requests;
	while (@args) {
		my $arg = shift @args;
		if ( $arg->$_isa('HTTP::Request') ) {
			push @requests, $arg;
		} elsif (ref $arg eq 'CODE') {
			$coderef = $arg;
			last;
		} elsif (ref $arg eq '') {
			die "".(ref $self)."->parse_chain '".$arg."' is not a known function" unless $self->can($arg);
			$coderef = $arg;
			last;
		} else {
			die "".(ref $self)."->parse_chain got unparseable element".(defined $arg ? " ".$arg : "" );
		}
	}
	die "".(ref $self)."->parse_chain found no HTTP::Request objects" unless @requests;
	return [@requests], $coderef, @args;
}

sub next_responses {
	my ( $self, @responses ) = @_;
	die "".(ref $self)."->next_responses can't be called on chain which is done." if $self->done;
	my $amount = scalar @{$self->next_requests};
	die "".(ref $self)."->next_responses would need ".$amount." HTTP::Response objects to proceed"
		unless scalar @responses == $amount;
	die "".(ref $self)."->next_responses only takes HTTP::Response objects"
		if grep { !$_->isa('HTTP::Response') } @responses;
	$self->clear_next_requests;
	my @result = $self->${\$self->next_coderef}(@responses);
	$self->clear_next_coderef;
	$self->_set_result_count($self->result_count + 1);
	if ( $result[0]->$_isa('HTTP::Request') ) {
		my ( $next_requests, $next_coderef, @args ) = $self->parse_chain(@result);
		die "".(ref $self)."->next_responses can't parse the result, more arguments after CodeRef" if @args;
		$self->_set_next_requests($next_requests);
		$self->_set_next_coderef($next_coderef);
		$self->_set_request_count($self->request_count + scalar @{$next_requests});
		return 0;
	}
	$self->_set_done(1);
	return $self->stash;
}

1;

__END__
=pod

=head1 NAME

WWW::Chain - A web request chain

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # Coderef usage

  my $chain = WWW::Chain->new(HTTP::Request->new( GET => 'http://localhost/' ), sub {
    my ( $chain, $response ) = @_;
    $chain->stash->{first_request} = 'done';
    return
      HTTP::Request->new( GET => 'http://localhost/' ),
      HTTP::Request->new( GET => 'http://other.localhost/' ),
      sub {
        my ( $chain, $first_response, $second_response ) = @_;
        $chain->stash->{two_calls_finished} = 'done';
        return;
      };
  });

  # Method usage (can be mixed with Coderef)

  {
    package TestWWWChainMethods;
    use Moo;
    extends 'WWW::Chain';

    sub first_request {
      $_[0]->stash->{a} = 1;
      return HTTP::Request->new( GET => 'http://duckduckgo.com/' ), "second_request";
    }

    sub second_request {
      $_[0]->stash->{b} = 2;
      return;
    }
  }

  my $chain = TestWWWChainMethods->new(HTTP::Request->new( GET => 'http://duckduckgo.com/' ), 'first_request');

  # Blocking usage:

  my $ua = WWW::Chain::UA::LWP->new;
  $ua->request_chain($chain);

  # ... or non blocking usage example:

  my @http_requests = @{$chain->next_requests};
  # ... do something with the HTTP::Request objects to get HTTP::Response objects
  $chain->next_responses(@http_responses);
  # repeat those till $chain->done

  # Working with the result

  print $chain->stash->{two_calls_finished};

=head1 DESCRIPTION

The implementation is not finished (but fully working), API changes may occur...

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

