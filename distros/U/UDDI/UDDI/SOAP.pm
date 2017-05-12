package UDDI::SOAP;

# Copyright 2000 ActiveState Tool Corp.

use strict;

sub SOAP_ENV () { "http://schemas.xmlsoap.org/soap/envelope/" }
sub UDDI_API () { "urn:uddi-org:api" }

for (qw(Envelope Header Body Fault detail)) {
    $UDDI::elementContent{"UDDI::SOAP::$_"} = UDDI::ELEM_CONTENT();
}

for (qw(faultcode faultstring faultactor)) {
    $UDDI::elementContent{"UDDI::SOAP::$_"} = UDDI::TEXT_CONTENT();
}

sub parse {
    my $doc = shift;

    require XML::Parser::Expat;

    my $p = XML::Parser::Expat->new(ErrorContext => 0);

    $p->setHandlers(Start => \&start_h,
		    End   => \&end_h,
		    Char  => \&char_h,
		   );

    $p->{stack} = [[]];
    $p->parse($doc);
    my $tree = (delete $p->{stack})->[0][0];
    $p->release;
    undef($p);

    $tree;
}

sub ns_set
{
    my($p, $ns, $v) = @_;
    # push handlers to clean up when namespace scope has been left.
    if (exists $p->{ns}{$ns}) {
	my $old = $p->{ns}{$ns};
	push(@{$p->{ns_stack}[-1]}, sub { $p->{ns}{$ns} = $old  });
    }
    else {
	push(@{$p->{ns_stack}[-1]}, sub { delete $p->{ns}{$ns} });
    }
    # update namespace
    $p->{ns}{$ns} = $v;
}

sub ns_qualify
{
    my($p, $name, $attr) = @_;
    return "$p\0$name" unless ref($p);

    if ($name =~ s/^([^:]+)://) {
	my $prefix = $1;
	unless (exists $p->{ns}{$prefix}) {
	    if ($prefix eq "xml") {
		return "xml\0$name";
	    }
	    else {
		$p->xpcroak("Unknown namespace prefix '$prefix'")
	    }
	}
	return "$p->{ns}{$prefix}\0$name";
    }
    elsif (!$attr && exists $p->{ns}{""}) {
	return "$p->{ns}{''}\0$name";
    }
    elsif ($attr) {
	return "$attr\0$name";
    }
    else {
	return "\0$name";
    }
}

sub ns_split
{
    my $qname = shift;
    my @s = split(/\0/, $qname, 2);
    @s;
}

sub ns_enter
{
    my $p = shift;
    push(@{$p->{ns_stack}}, []);
}

sub ns_leave
{
    my $p = shift;
    my $frame = pop(@{$p->{ns_stack}});
    for (@$frame) {
	&$_(); # invoke cleanup functions
    }
}

sub start_h
{
    my $p = shift;
    my $e = shift;

    ns_enter($p);

    my @attr;
    while (@_) {
	my($k, $v) = splice(@_, 0, 2);
	if ($k eq "xmlns") {
	    ns_set($p, "", $v);
	}
	elsif ($k =~ s/^xmlns://) {
	    ns_set($p, $k, $v);
	}
	else {
	    push(@attr, $k => $v);
	}
    }

    $e = ns_qualify($p, $e);
    my($e_ns, undef) = ns_split($e);
    for (my $i = 0; $i < @attr; $i += 2) {
	$attr[$i] = ns_qualify($p, $attr[$i], $e_ns);
    }

    my $node = [$e, { @attr }];

    my($ns, $name) = ns_split($e);
    my $class;
    if ($ns eq UDDI_API) {
	$class = "UDDI::$name";

	# trick, generate classes on the fly
	no strict 'refs';
	@{"$class\::ISA"} = ('UDDI::Object') unless @{"$class\::ISA"};
    }
    elsif ($ns eq SOAP_ENV) {
	$class = "UDDI::SOAP::$name";
    }
    else {
	$p->xpcroak("Unrecognized element $name ($ns)");
    }

    if ($class) {
	shift @$node;
	bless $node, $class;
    }

    push(@{$p->{stack}}, $node);
}

sub end_h
{
    my($p, $e) = @_;
    ns_leave($p);
    my $node = pop(@{$p->{stack}});

    # XXX might process $node here...

    push(@{$p->{stack}[-1]}, $node);
    return;
}

sub char_h
{
    my($p, $str) = @_;

    my $elem_type = ref($p->{stack}[-1]);

    if (exists $UDDI::elementContent{$elem_type}) {
	my $content = $UDDI::elementContent{$elem_type};
	unless ($content & UDDI::TEXT_CONTENT) {
	    $p->xpcroak("Text not allowed for $elem_type elements")
		if $str =~ /\S/;
	    return;
	}
    }

    if (!ref($p->{stack}[-1][-1])) {
	# Avoid subsequenct text segments
	$p->{stack}[-1][-1] .= $str;
    }
    else {
	push(@{$p->{stack}[-1]}, $str);
    }
}


package UDDI::SOAP::Envelope;

sub must_understand_headers
{
    my $self = shift;
    my @elem = @$self;
    shift(@elem); # attributes
    pop(@elem);   # body
    my @h;
    for (@elem) {
	die "Assert $_" unless ref($_) eq "UDDI::SOAP::Header";
	push(@h, $_->[1])
	    if $_->[1][0]{UDDI::SOAP::SOAP_ENV . "\0mustUnderstand"};
    }
    return @h;
}

sub body_content
{
    my $self = shift;
    my $body = $self->[-1];
    if (wantarray) {
	my @tmp = @$body;
	shift(@tmp);  # attributes
	return @tmp;
    }
    else {
	return $body->[1];
    }
}


package UDDI::SOAP::Fault;

sub code
{
    my $self = shift;
    my $code;
    for (@$self) {
	if (ref($_) eq "UDDI::SOAP::detail") {
	    my $d = $_->[-1];
	    if (ref($d) eq "UDDI::dispositionReport") {
		eval {
		    # hope for the best
		    $code = $d->result->errInfo->errCode;
		};
	    }
	    last;
	}
    }

    if (!$code) {
	for (@$self) {
	    if (ref($_) eq "UDDI::SOAP::faultcode") {
		$code = $_->[-1];
		last;
	    }
	}
    }

    $code ||= "SOAP_Fault";

    $code;
}

sub message
{
    my $self = shift;
    my $mess;
    for (@$self) {
	if (ref($_) eq "UDDI::SOAP::faultstring") {
	    $mess = $_->[-1];
	    last;
	}
    }

    $mess ||= $self->code . " fault";
    $mess;
}

1;
