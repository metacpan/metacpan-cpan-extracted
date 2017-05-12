package WebService::CRUST::Result;
use base qw(Class::Accessor);

use strict;

our $VERSION = '0.7';


__PACKAGE__->mk_accessors(qw(
    result
    crust
));


sub new {
    my ($class, $h, $crust) = @_;
    
    my $self = bless {}, $class;
    $self->result($h);
    $self->crust($crust);

    return $self;
}



sub string {
    my $self = shift;
    
    return scalar $self->result;
}

# Stringify
use overload
	'""'     => sub { shift->string },
	fallback => 1;



sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;

    # Don't override DESTROY
    return if $AUTOLOAD =~ /::DESTROY$/;

    ( my $method = $AUTOLOAD ) =~ s/.*:://s;
    
    return unless $self->result and defined $self->result->{$method};
        
    my $result = $self->result->{$method};
    
    $self->{_cache}->{$method} and return $self->{_cache}->{$method};

    if (ref $result eq 'HASH') {
        $self->{_cache}->{$method} = $self->follow_result($result);
    }
    elsif (ref $result eq 'ARRAY') {
        my @results = @$result;

        my @response;
        foreach my $r (@results) {
            push @response, $self->follow_result($r);
        }

        wantarray and return @response;
        $self->{_cache}->{$method} = \@response;
    }
    else {
        $self->{_cache}->{$method} = $result;
    }

    return $self->{_cache}->{$method};
}


sub follow_result {
    my ($self, $result) = @_;
    
    if (exists $result->{'xlink:href'}) {
        my $href   = new URI($result->{'xlink:href'});
        
        my $action = exists $result->{action}
            ? $result->{action}
            : 'GET';

        my $full_href = $self->crust->response
            ? $href->abs($self->crust->response->base)
            : $href;

        my %args = exists $result->{args}
            ? %{$result->{args}}
            : ();

        my $r = $self->crust->request(
            $action,
            $full_href,
            %args
        );
        
        return $r;
    }
    else {
        return new WebService::CRUST::Result($result, $self->crust);
    }
}



1;

__END__


=head1 NAME

WebService::CRUST::Result

=head1 SYNOPSIS

  my $r = new Webservice::CRUST::Result->new($val, [$crust]);

Note that this object is generally only helpful when it is created by a
L<WebService::CRUST> call.

=head1 METHODS

=item string

The method used to stringify the object

=item result

An accessor for the raw converted hash result from the request

=item crust

An accessor that points to the WebService::CRUST object that made this request

=head1 AUTOLOAD

Any other method you call tries to get that value from the result.

If the value is a hash ref, it will be returned as another Result object;

If the value is an array ref, it will be returned as an array of Result
objects, or as a ref to the array depending on the context in which it was
called.

If the value is scalar it will just be returned as is.

=head1 INFLATION

If the value passed to new is a hash reference with a key called
"xlink:href" then this module will look for keys called "args" and "href"
and use them to construct a new request when that value is queried.  For
instance, assume this piece of XML is consumed by a WebService::CRUST object:

    <book name="So Long and Thank For All The Fish">
        <author xlink:href="http://someservice/author">
            <args first="Douglas" last="Adams" />
        </author>
        <price>42.00</price>
    </book>


    $crust->name;   # Returns 'So Long and Thanks For All The Fish'
    $crust->price;  # Returns '42.00'
    $crust->author; # Returns the results of a CRUST GET request to
                    # http://someservice/author?first=Douglas&last=Adams

This is pretty useful when you are exposing a database and you want to be able
to follow relations fairly easily.

=head1 SEE ALSO

L<WebService::CRUST>

=cut