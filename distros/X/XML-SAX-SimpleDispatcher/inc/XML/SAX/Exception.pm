#line 1
package XML::SAX::Exception;

use strict;

use overload '""' => "stringify",
    'fallback' => 1;

use vars qw/$StackTrace $VERSION/;
$VERSION = '1.01';
use Carp;

$StackTrace = $ENV{XML_DEBUG} || 0;

# Other exception classes:

@XML::SAX::Exception::NotRecognized::ISA = ('XML::SAX::Exception');
@XML::SAX::Exception::NotSupported::ISA = ('XML::SAX::Exception');
@XML::SAX::Exception::Parse::ISA = ('XML::SAX::Exception');


sub throw {
    my $class = shift;
    if (ref($class)) {
        die $class;
    }
    die $class->new(@_);
}

sub new {
    my $class = shift;
    my %opts = @_;
    confess "Invalid options: " . join(', ', keys %opts) unless exists $opts{Message};
    
    bless { ($StackTrace ? (StackTrace => stacktrace()) : ()), %opts },
        $class;
}

sub stringify {
    my $self = shift;
    local $^W;
    my $error;
    if (exists $self->{LineNumber}) {
        $error = $self->{Message} . " [Ln: " . $self->{LineNumber} . 
                ", Col: " . $self->{ColumnNumber} . "]";
    }
    else {
        $error = $self->{Message};
    }
    if ($StackTrace) {
        $error .= stackstring($self->{StackTrace});
    }
    $error .= "\n";
    return $error;
}

sub stacktrace {
    my $i = 2;
    my @fulltrace;
    while (my @trace = caller($i++)) {
        my %hash;
        @hash{qw(Package Filename Line)} = @trace[0..2];
        push @fulltrace, \%hash;
    }
    return \@fulltrace;
}

sub stackstring {
    my $stacktrace = shift;
    my $string = "\nFrom:\n";
    foreach my $current (@$stacktrace) {
        $string .= $current->{Filename} . " Line: " . $current->{Line} . "\n";
    }
    return $string;
}

1;

__END__

#line 125

