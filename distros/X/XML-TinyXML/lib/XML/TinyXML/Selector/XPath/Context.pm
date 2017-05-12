# Internal use only
package XML::TinyXML::Selector::XPath::Context;

use strict;
use warnings;

our $VERSION = '0.34';

our %Operators = (
 '+'   => sub {  $_[0] +  $_[1]  },
 '-'   => sub {  $_[0] -  $_[1]  },
 '='   => sub { ($_[0] == $_[1]) }, 
 '!='  => sub { ($_[0] != $_[1]) },
 '<'   => sub { ($_[0] <  $_[1]) },
 '<='  => sub { ($_[0] <= $_[1]) },
 '>'   => sub { ($_[0] >  $_[1]) },
 '>='  => sub { ($_[0] >= $_[1]) },
 '*'   => sub {  $_[0] *  $_[1]  },
 'and' => sub { 
                if (ref($_[0]) and ref($_[0]) eq "ARRAY") {
                    return scalar(@{$_[0]})?[@{$_[0]}, @{$_[1]}]:[];
                } else {
                    return($_[0] && $_[1]) 
                } 
              },
 'or'  => sub { 
                if (ref($_[0]) and ref($_[0]) eq "ARRAY") {
                    return scalar(@{$_[0]})?$_[0]:$_[1];
                } else {
                    return($_[0] || $_[1]) 
                } 
              },
 'mod' => sub { ($_[0] %  $_[1]) },
 'div' => sub { $_[0] 
                ? $_[1] 
                  ? $_[0] / $_[1] 
                  : undef
                : $_[1]
                  ? 0
                  : undef
               }
);

sub new {
    my ($class, $xml) = @_;
    my $self = { xml => $xml, 
                 operators => \%Operators,
                 items => [$xml->rootNodes]
               };
    return bless $self, $class;
}

sub AUTOLOAD
{
    my $self = shift;
    our $AUTOLOAD;
    my $method = (split('::', $AUTOLOAD))[-1];
    return $self->{$method};
}

1;
