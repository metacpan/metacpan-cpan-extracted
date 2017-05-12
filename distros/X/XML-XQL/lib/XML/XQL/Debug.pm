package XML::XQL::Debug;

# Replaces the filepath separator if necessary (i.e for Macs and Windows/DOS)
sub filename
{
    my $name = shift;

    if ((defined $^O and
	 $^O =~ /MSWin32/i ||
	 $^O =~ /Windows_95/i ||
	 $^O =~ /Windows_NT/i) ||
	(defined $ENV{OS} and
	 $ENV{OS} =~ /MSWin32/i ||
	 $ENV{OS} =~ /Windows_95/i ||
	 $ENV{OS} =~ /Windows_NT/i))
    {
	$name =~ s!/!\\!g;
    }
    elsif  ((defined $^O and $^O =~ /MacOS/i) ||
	    (defined $ENV{OS} and $ENV{OS} =~ /MacOS/i))
    {
	$name =~ s!/!:!g;
	$name = ":$name";
    }
    $name;
}

sub dump
{
    new XML::XQL::Debug::Dump->pr (@_);
}

sub str
{
    my $dump = new XML::XQL::Debug::Dump;
    $dump->pr (@_);
    $dump->{Str} =~ tr/\012/\n/;	# for MacOS where '\012' != '\n'
    $dump->{Str};
}

package XML::XQL::Debug::Dump;

sub new
{
    my ($class, %args) = @_;
    $args{Indent} = 0;
    $args{Str} = "";
    bless \%args, $class;
}

sub indent
{
    $_[0]->p ("  " x $_[0]->{Indent});
}

sub ip
{
    my $self = shift;
    $self->indent;
    $self->p (@_);
}

sub pr
{
    my ($self, $x) = @_;
    if (ref($x))
    {
	if (ref($x) eq "ARRAY")
	{
	    if (@$x == 0)
	    {
		$self->ip ("<array/>\n");
		return;
	    }

	    $self->ip ("<array>\n");
	    $self->{Indent}++;

	    for (my $i = 0; $i < @$x; $i++)
	    {
		$self->ip ("<item index='$i'>\n");
		$self->{Indent}++;

		$self->pr ($x->[$i]);

		$self->{Indent}--;
		$self->ip ("</item>\n");
	    }
	    $self->{Indent}--;
	    $self->ip ("</array>\n");
	}
	else
	{
	    $self->ip ("<obj type='" . ref($x) . "'>");
	    
	    if ($x->isa ('XML::XQL::PrimitiveType'))
	    {
		$self->p ($x->xql_toString);
	    }
	    else
	    {
		$self->p ("\n");
		$self->{Indent}++;
		
		if ($x->isa ("XML::DOM::Node"))
		{
		    # print node plus subnodes as XML
		    $self->p ($x->toString);
		}
		$self->p ("\n");

		$self->{Indent}--;
		$self->indent;
	    }
	    $self->p ("</obj>\n");
	}
    }
    elsif (defined $x)
    {
	$self->indent;
	$self->p ("<str>$x<str/>\n");	
    }
    else
    {
	$self->indent;
	$self->p ("<undef/>\n");
    }
}

sub p
{
    my $self = shift;

    if ($self->{Dump})
    {
	print @;
    }
    else
    {
	$self->{Str} .= join ("", @_);
    }
}

1;
