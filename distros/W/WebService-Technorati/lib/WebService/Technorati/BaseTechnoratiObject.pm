package WebService::Technorati::BaseTechnoratiObject;
use strict;
use utf8;

use vars qw($AUTOLOAD);
use AutoLoader;

use WebService::Technorati::Exception;

sub AUTOLOAD {
    my $self=shift;
    my $change=shift;
    my $class = ref($self) || $self;
    my($type,$field) = $AUTOLOAD =~ /.*::((?:s|g)et)([A-Z]\w+)/;
    if (! defined($field)) {
        WebService::Technorati::MethodNotImplementedException->throw(
            "method not implemented: $AUTOLOAD");
    }
    $field = lc($field);
    $self->_accessible($field)
        || WebService::Technorati::AccessViolationException->throw(
        "attribute not accessible in $class: $field $AUTOLOAD");
    if ($change && $type eq 'set') {
        $self->{$field}=$change;
    }
    return $self->{$field};
} # AUTOLOAD

sub _accessible {
    my $self = shift;
    my $class = ref($self) || $self;
    WebService::Technorati::MethodNotImplementedException->throw(
        "abstract method '_accessible' not implemented by $class");
}

1;

__END__
