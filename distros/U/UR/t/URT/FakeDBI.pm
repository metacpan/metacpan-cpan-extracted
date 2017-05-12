package URT::FakeDBI;
use strict;
use warnings;

# A DBI-like test class we can force failures on

my %configuration;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub connect {
    my $class = shift;
    if ($configuration{connect_fail}) {
        $class->set_errstr('connect_fail');
        return undef;
    } else {
        return $class->new();
    }
}

sub configure {
    my $self = shift;
    my($key, $val) = @_;
    $configuration{$key} = $val;
}

sub prepare {
    my $self = shift;
    if ($configuration{prepare_fail}) {
        $self->set_errstr('prepare_fail');
        return undef;
    } else {
        return URT::FakeDBI::sth->new($self);
    }
}

sub do {
    my $self = shift;
    if ($configuration{do_fail}) {
        $self->set_errstr('do_fail');
        return undef;
    } else {
        return 1;
    }
}

sub set_errstr {
    my $self = shift;
    my $key = shift;
    our $errstr = $configuration{$key};
}

sub errstr {
    our $errstr;
    return $errstr;
}

package URT::FakeDBI::sth;

sub new {
    my $class = shift;
    my $dbh = shift;
    return bless \$dbh, $class;
}

sub execute {
    my $self = shift;
    my $dbh = $$self;
    if ($configuration{execute_fail}) {
        $dbh->set_errstr('execute_fail');
        return undef;
    } else {
        return 1;
    }
}

1;


