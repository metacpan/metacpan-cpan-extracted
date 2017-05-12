# XML::Filter::Hekeln
#      (c) 1999 GNU General Public License
#      Michael Koehne Kraehe@Copyleft.de
# ---------------------------------------------------------------------------- #

package XML::Filter::Hekeln;
use UNIVERSAL;

use strict;
use vars qw($VERSION $METHODS);

$VERSION = '0.06';
$METHODS = {
	start_document => 1,
	end_document => 1,
	doctype_decl => 1,
	processing_instruction => 1,
	start_element => 1,
	end_element => 1,
	start_cdata => 1,
	end_cdata => 1,
	characters => 1
	};

# ---------------------------------------------------------------------------- #

sub new {
	my $proto = shift;
	my $self  = {};
	my $class = ref($proto) || $proto;
	bless($self, $class);

	my $args = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	foreach (keys %$args) { $self->{$_}=$args->{$_}; }

	$self->{'Action'} = $self->script($self->{'Script'})
		if $self->{'Script'} && !$self->{'Action'};

	$self->{'Action'} = {} unless ref($self->{'Action'}) eq 'HASH';
	$self->{'Methods'} = {};
	$self->{'Stack'} = [];

	if ($self->{'Handler'}) {
		foreach (keys %$METHODS) {
			$self->{'Methods'}{$_} =
				$self->{'Handler'}->can($_) ? 2 : 1;
		}
	}

	return $self;
}

sub script {
	my ($self,$script) = @_;
	my $hash = {};
	my ($key,$val,$str);
	my (@v, $o, $p);
	my $action;

	local $SIG{__WARN__} = sub { die $_[0] };

	foreach (split /\n\n/, $script) {
		if ($_ !~ /^#/) {
			($key,$val) = split /\n/, $_, 2;
			if ($key =~ /^[^:]+:[^:]+$/) {

				$str = 'sub {'."\n\t";
				$str .= 'my ($self,$param) = @_;'."\n\t";
				$str .= 'my ($hash) = {};'."\n\t";

				$val =~ s/\~(\w+)\~/\$param->{$1}/g;

				SCRIPT_TO_SUB_SW: foreach (split /\n/, $val) {
					@v = split /\t/, $_;
					$o = shift @v;
					$p = shift @v;

					if ($o eq '<') {
						$str .= '$hash->{Name}="'.$p.'"; ';
						$str .= '$self->handle("start_element", $hash);';
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}
					
					if ($o eq '</') {
						$str .= '$hash->{Name}="'.$p.'"; ';
						$str .= '$self->handle("end_element", $hash);';
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}
					
					if ($o eq '') {
						$str .= '$hash->{Data}="'.$p.'"; ';
						$str .= '$self->handle("characters", $hash);';
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}
					
					if ($o eq '!') {
						$str .= $p;
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}

					if ($o eq '+') {
						$str .= '$self->{Flag}{'.$p.'}=1;';
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}
					if ($o eq '++') {
						$str .= '$self->{Flag}{'.$p.'}=1;';
						$str .= 'unshift @{$self->{Stack}}, "'.$p.'";';
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}
					if ($o eq '-') {
						$str .= '$self->{Flag}{'.$p.'}=0;';
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}
					if ($o eq '--') {
						$str .= '$self->{Flag}{'.$p.'}=0;';
						$str .= 'shift @{$self->{Stack}} if $self->{Stack}[0] eq "'.$p.'";';
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}
					if ($o eq '?{') {
						$str .= 'if ($self->{Flag}{'.$p.'}) {';
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}
					if ($o eq '?}') {
						$str .= '}';
						$str .= "\n\t";
						next SCRIPT_TO_SUB_SW;
					}
				}
				$str.= '}';
				print STDERR '$hash->{'.$key.'}=eval "'.$str.'";'."\n\n"
					if $self->{'Debug'};
				$action = eval $str;
				if ($@) {
					print STDERR "Error: $key: "; die $@
				}
				$hash->{$key}=$action;
			}
		}
	}
	return $hash;
}

sub start_document		{ my ($self, $param) = @_; $self->style('start_document',$param); }
sub end_document		{ my ($self, $param) = @_; $self->style('end_document',$param); }
sub doctype_decl		{ my ($self, $param) = @_; $self->style('doctype_decl',$param); }
sub processing_instruction	{ my ($self, $param) = @_; $self->style('processing_instruction',$param); }
sub start_element		{ my ($self, $param) = @_; $self->style('start_element',$param); }
sub end_element			{ my ($self, $param) = @_; $self->style('end_element',$param); }
sub start_cdata			{ my ($self, $param) = @_; $self->style('start_cdata',$param); }
sub end_cdata			{ my ($self, $param) = @_; $self->style('end_cdata',$param); }
sub characters			{ my ($self, $param) = @_; $self->style('characters',$param); }

sub style {
	my ($self,$event,$param) = @_;

	return unless $param;
	return unless $event;
	return unless $METHODS->{$event};

	my $target = "*";
	   $target = $param->{'Name'}   if $param->{'Name'};
	   $target = $param->{'Target'} if $param->{'Target'};
	   $target = $self->{Stack}[0]  if ( $event eq 'characters' or
					     $event eq 'start_cdata' or
					     $event eq 'end_cdata' ) and
					     $self->{Flag}{$self->{Stack}[0]};

	my $action = $self->{'Action'}{$event.':'.$target};
	return undef unless $action;

	my $hash = $param;
	   $hash = $param->{'Attributes'} if $event eq 'start_element';

	return &$action($self,$hash);
}

sub handle {
	my ($self,$event,$param) = @_;

	return $self->{'Handler'}->$event($param)
		if ($self->{'Methods'}{$event}>1);
	return undef;
}

# ---------------------------------------------------------------------------- #

1;
__END__

=head1 NAME

XML::Filter::Hekeln - a SAX stream editor

=head1 SYNOPSIS

  use XML::Filter::Hekeln;

  my $hander = new SAXHandler( ... );
  my $hekeln = new XML::Filter::Hekeln(
  	'Handler' => $handler,
	'Script'  => $script
	);
  my $driver = new SAXDriver( ..., 'Handler' => $hekeln );

=head1 DESCRIPTION

XML::Filter::Hekeln is a sophisticated SAX stream editor.

Hekeln is a SAX filter. This means that you can use a Hekeln
object as a Handler to act on events, and to produce SAX events
as a driver for the next handler in the chain. The name Hekeln
sounds like the german word for crocheting, whats the best to
describe, what Hekeln can do on markup language translation.

The main design goal was to make it as easy for Perl as possible,
while preserving a human readable form for the translation script.

Hekeln scripts are event based. Hekeln objects stream events to
the next in chain. They are therefore useable to handle XML
documents larger than physical memory, as they do not need to
store the entire document in a DOM or Grove structure. They will
also be faster than any XSL in most circumstances.

To tell you straight, how Hekeln works, I'll start with an example.

I want to translate XML::Edifact repositories into html. Those
repositories start with something like this:

	<repository
		agency="UN/ECE/TRADE/WP.4"
		code="sdsd"
		desc="based on UN/EDIFACT D422.TXT"
		name="Service Segment Directory"
		version="99A"
		>

Here is a sniplet from test.pl :

	start_element:repository
	!	$self->handle('start_document',{});
	<	html	>
	<	body	>
	<	h1	>
		XML-Edifact Repository
	</	h1	>
	<	h2	>
		~name~
	</	h2	>
	<	p	>
		Agency: ~agency~
	<	br	>
		Code: ~code~
	<	br	>
		Version: ~version~
	<	br	>
		Description: ~desc~
	</	p	>
	<	hr	>

	end_element:repository
	</	body	>
	</	html	>
	!	$self->handle('end_document',{});

This part is handling start_element and end_element events, that have
a target called repository. The translation done by Hekeln is done into
subroutines that are stored in a hash. 

So anything is possible, if you understand the trick. To understand
the trick, uncomment the "'Debug' => 1" parameter of Hekeln invocation
in the test.pl script and redirect STDERR to some file.

This will produce a file starting like :

    $hash->{start_element:repository}=eval "sub {
	my ($self,$param) = @_;
	my ($hash) = {};
	$self->handle('start_document',{});
	$hash->{Name}="html"; $self->handle("start_element", $hash);
	$hash->{Name}="body"; $self->handle("start_element", $hash);
	$hash->{Name}="h1"; $self->handle("start_element", $hash);
	$hash->{Data}="XML-Edifact Repository"; $self->handle("characters", $hash);
	$hash->{Name}="h1"; $self->handle("end_element", $hash);
	$hash->{Name}="h2"; $self->handle("start_element", $hash);
	$hash->{Data}="$param->{name}"; $self->handle("characters", $hash);
	$hash->{Name}="h2"; $self->handle("end_element", $hash);
	$hash->{Name}="p"; $self->handle("start_element", $hash);
	$hash->{Data}="Agency: $param->{agency}"; $self->handle("characters", $hash);
	$hash->{Name}="br"; $self->handle("start_element", $hash);
	$hash->{Data}="Code: $param->{code}"; $self->handle("characters", $hash);
	$hash->{Name}="br"; $self->handle("start_element", $hash);
	$hash->{Data}="Version: $param->{version}"; $self->handle("characters", $hash);
	$hash->{Name}="br"; $self->handle("start_element", $hash);
	$hash->{Data}="Description: $param->{desc}"; $self->handle("characters", $hash);
	$hash->{Name}="p"; $self->handle("end_element", $hash);
	$hash->{Name}="hr"; $self->handle("start_element", $hash);
	}";

    $hash->{end_element:repository}=eval "sub {
	my ($self,$param) = @_;
	my ($hash) = {};
	$hash->{Name}="body"; $self->handle("end_element", $hash);
	$hash->{Name}="html"; $self->handle("end_element", $hash);
	$self->handle('end_document',{});
	}";

As you can imagine ~foobaa~ parts within a script will become expanded
with the the attributes given in the XML start_element event. Syntax
itself is a bit tricky as translation of the script into a sub is
stupid and fast.

Any event that has to be handled by Hekeln starts with an event_name
event_target pair and ends with a blank line.

	event_name<DOUBLE_COLON>event_target<NL>
	left_indicator<TAB>text<TAB>right_indicator<NL>
	left_indicator<TAB>text<TAB>right_indicator<NL>
	left_indicator<TAB>text<TAB>right_indicator<NL>
	<NL>

Valid as left_indicator are "<", "</", "", "!", "+", "-", "++, "--",
"?{" and "?}", while the right indicator may be optional execpt for "<".

The first produce start_element, end_element and character events,
to make Hekeln scripts look similar to the markup you want to produce.

The "!" indicator is something special as it will be copied into the
sub as it is, to be evaluted in the complete context of a script. So its
possible to code conditionals or even loops with a constructions like
those :

	!	$self->{Flag}{FooBaa}=1;
	!	unshift @{$self->{Stack}}, "FooBaa";

and

	!	$self->{Flag}{FooBaa}=undef;
	!	shift @{$self->{Stack}} if $self->{Stack}[0] eq "FooBaa";

and

	!	if ($self->{Flag}{FooBaa}) {
	<	h1	>
		flag FooBaa raised
	</	h1	>
	!	}

It wont be necessary to code exactly this, as this is done by "++", "--",
"?{" and "?}". "+" and "-" will raise or lower some flag, while "++" and
"--" not only manage the flags, but also a stack that is needed to process
character events. 

The default behavior is to throw away any event that does not have a
subroutine matching the event, target pair. Events that do not have a
target, will use the top flag on the stack as a target. So if you want
to process character events, use "++" and "--" when handling the
surounding start_element and end_element events. 

As a last word: Hekeln is not yet well tested, and badly needs some
better documentation. I would aplaude anybody for naming bug, or improving
the POD.

=head1 AUTHOR

Michael Koehne, Kraehe@Copyleft.de

=head1 SEE ALSO

perl(1), XML::Parser, XML::Parser::PerlSAX

=cut
