package Test::VCR::LWP;
$Test::VCR::LWP::VERSION = '0.5';
use strict;
use warnings;

use LWP::UserAgent;
use Data::Dumper;
use FindBin;
use File::Spec;
use Carp;

use base 'Exporter';
our @EXPORT_OK = qw(withVCR withoutVCR);
our $__current_vcr;

=head1 NAME

Test::VCR::LWP - Record and playback LWP interactions.

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	withVCR {
		my $res = $useragent->get('http://metacpan.org/');
	};

=head1 DESCRIPTION

Records HTTP transactions done thru LWP to a file and then replays them.  Allows
your tests suite to be fast, dterministic and accurate.

Inspired by (stolen from) L<http://relishapp.com/vcr/vcr/docs>

=head1 OO Interface
	
You can use the object oriented interface, but the basic decorator style
function interface is recommended.

Using the OO interface:

	my $vcr = Test::VCR::LWP->new(tape => 'mytape.tape');
	
	$vcr->run(sub {
		my $ua  = LWP::UserAgent->new;
		my $res = $ua->get('http://www.perl.org/');
		
		if ($_->is_recording) {
			do_something();
		}
	});
	

=cut

sub new {
	my $class = shift;
	return bless {@_}, $class;
}

sub run {
	my ($self, $code) = @_;
	
	
	if ($self->tape_is_blank) {
		$self->record($code);
	}
	else {
		$self->play($code);
	}
}

sub tape_is_blank {
	my ($self) = @_;
	
	return not -s $self->{tape};
}


sub record {
	my ($self, $code) = @_;
	
	local $self->{is_recording} = 1;
	my $original_lwp_request = \&LWP::UserAgent::request;
	
	my $tape = $self->_load_tape;
	
	no warnings 'redefine';
	
	local *LWP::UserAgent::request = sub {
		my ($ua, $req) = @_;
		local *LWP::UserAgent::request = $original_lwp_request;
		
		my $res = $original_lwp_request->($ua, $req);
		
		# skip recording is often set by the withoutVCR function
		unless ($self->{skip_recording}) {
			diag("recording http response for %s %s", $req->method, $req->uri);
			push(@$tape, {request => $req, response => $res});
		}
		else {
			diag("Not recording (within a withoutVCR block).");
		}
		
		return $res;
	};
	
	local $_ = $self;
	eval {
		$code->();
	};
	my $e = $@;
	
	open(my $fh, '>', $self->{tape}) || die "Couldn't open $self->{tape}: $!\n";
	
	local $Data::Dumper::Purity = 1;
	print $fh "use HTTP::Response;\n";
	print $fh "use HTTP::Request;\n";
	print $fh Data::Dumper::Dumper($tape), "\n";
	close($fh) || die "Couldn't close $self->{tape}: $!\n";

	die $e if $e;
}

sub play {
	my ($self, $code) = @_;
	
	$self->_load_tape;
	
	no warnings 'redefine';
	my @match_fields = ('scheme', 'host', 'port', 'path', 'query');
	my $original_lwp_request = \&LWP::UserAgent::request;
	
	local *LWP::UserAgent::request = sub {
		my ($ua, $incoming) = @_;
		
		no warnings 'uninitialized';
		
		REQ: foreach my $episode (@{$self->{requests}}) {
			my $recorded = $episode->{request};
			
			next REQ if $recorded->method ne $incoming->method;
			
			foreach my $field (@match_fields) {
				next REQ if $recorded->uri->$field ne $incoming->uri->$field;
			}
			
			diag("returning recorded http response for %s %s", $incoming->method, $incoming->uri);
			return $episode->{response};
		}
		
		local *LWP::UserAgent::request = $original_lwp_request;
		
		my $res;
		$self->record(sub {
			$res = $ua->request($incoming);
		});
		return $res;
	};
	
	local $_ = $self;
	$code->();
}


sub is_recording {
	return shift->{is_recording};
}

sub _load_tape {
	my ($self) = @_;
	
	return [] unless -e $self->{tape};
	
	return $self->{requests} ||= do {
		local $/;
		open(my $fh, "<", $self->{tape}) || die "Couldn't open $self->{tape}: $!\n";
		my $perl = <$fh>;
		close($fh) || die "Couldn't close $self->{tape}: $!\n";
		
		our $VAR1;
		eval "$perl";
		
		die $@ if $@;
		
		$VAR1;
	};
}

sub diag {
	my ($format, @args) = @_;
	
	if ($ENV{VCR_DEBUG}) {	
		my $msg = sprintf($format, @args);
		warn "# $msg\n";
	}
}

=head2 withVCR

Mocks out any calls to LWP::UserAgent with Test::VCR::LWP.  Takes a
number of flags which are passed to the VCR constructor, and finally
a code ref.  For example:

	withVCR {
		my $req = $ua->post('http://oo.com/object');
		isa_ok($req, 'HTTP::Response');
		
		if ($_->is_recording) {
			sleep(5);
		}
		
		my $second = $ua->get('http://oo.com/object/' . $res->id);
		
	} tape => 'my_test.tape';

Or to have the name of the calling sub define the tape name:

	withVCR {
		my $req = $ua->post('http://oo.com/object');
		isa_ok($req, 'HTTP::Response');
	};
	
The tape file we be placed in the same directory as the script if no tape
argument is given.  If this function is called outside of a subroutine, the
filename of the current perl script will be used to derive a tape filename.

Within the code block, C<$_> is the current vcr object.  The C<is_recording>
method might be useful.

=cut

sub withVCR (&;@) {
	my $code = shift;
	my %args = @_;
	
	$args{tape} ||= do {
		my $caller = (caller(1))[3];
		$caller =~ s/^.*:://;
		
		if ($caller eq '__ANON__') {
			croak "tape name must be supplied if called from anonymous subroutine"
		}
		
		File::Spec->catfile($FindBin::Bin, "$caller.tape");
	};
	
	my $vcr = Test::VCR::LWP->new(%args);
	diag("Created $vcr");
	# this is so withoutVCR can get to the current vcr object.
	local $__current_vcr = $vcr;
	$vcr->run($code);
}

=head2 withoutVCR

Allows a section of a withVCR code block to skip recording.

	withVCR {
		my $req = $ua->post('http://oo.com/object');
		isa_ok($req, 'HTTP::Response');
		
		withoutVCR {
			# this will not end up in the tape
			$ua->post('http://always.com/dothis');
		};
	};

=cut

sub withoutVCR (&) {
	my $code = shift;
	
	if (!$__current_vcr) {
		croak "Using withoutVCR outside of a withVCR. You probably don't want to do this.";
	}
	
	local $__current_vcr->{skip_recording} = 1;
	diag("Setting skip in $__current_vcr");
 	$code->();
}

=head1 TODO

=over 2

=item *

The docs are pretty middling at the moment.

=back

=head1 AUTHORS

    Chris Reinhardt
    crein@cpan.org

    Mark Ng
    cpan@markng.co.uk   
    
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<LWP::UserAgent>, perl(1)

=cut


1;
__END__
