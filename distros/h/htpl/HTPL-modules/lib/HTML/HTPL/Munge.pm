package HTML::HTPL::Munge;

use Filter::Util::Call;
use Tie::Parent;
require Exporter;
use strict;
use vars qw(%variables);
use Carp;

sub import {
    my $pkg = (caller)[0];
    my $class = shift;
    $variables{$pkg} = [ @_ ];   

    filter_add(bless {'pkg' => $pkg});
    Exporter::export('HTML::HTPL::Munge::Stub', $pkg, 'AUTOLOAD');
    Exporter::export('HTML::HTPL::Munge::Stub2', "${pkg}::__shadow__", 'AUTOLOAD');
    undef;
}

sub filter {
    my $self = shift;
    my $status = filter_read();
    if ($_ eq "SYNC\n") {
        my @vars = &getvars($self->{'pkg'});
        my @lines = map { s/^://; "my \$$_; tie \$$_, 'Tie::Parent', \$self, '$_';" }
              @vars;
        unshift(@lines, 'my $self = shift;', 'local ($__htpl_lastself) = $self;');
        $_ = join("\n", @lines, "");
    }
    $status;
}

sub getvars {
    my ($pkg, %way) = shift;
    my @vars = @{$variables{$pkg}};
    my @isa;
    eval '@{"$pkg\::ISA"};';

    return @vars unless (@vars && @isa);
    foreach (@isa) {
        push(@vars, &getvars($_, %way, $_, 1)) unless ($way{$_});
    }
    @vars;
}

package HTML::HTPL::Munge::Stub;
use strict;
use vars qw(%lastself $AUTOLOAD @EXPORT_OK);
@EXPORT_OK = qw(AUTOLOAD);

sub AUTOLOAD {
    &loader;
    goto &$AUTOLOAD;
}

sub loader {
    my $save = $@;
    $@ = undef;
    my $index = rindex($AUTOLOAD, "::");
    Carp::croak("Can't parse $AUTOLOAD") unless ($index > -1);
    my $class = substr($AUTOLOAD, 0, $index);
    my $method = substr($AUTOLOAD, $index + 2);
    if ($method eq 'DESTROY') {
        *$AUTOLOAD = {};
        return;
    }
    my $shadow_class = '__shadow__';
    my $shadow_method = '__shadow__';
    my $impclass = "${class}::$shadow_class";
    my $impmethod = "${shadow_method}$method";
    my $impfunc =  "${impclass}::$impmethod";

    if ($method eq 'new') {
        eval <<EOM;
package $class;
sub new {
    my \$self = bless {}, shift;
    ${impclass}::__init__(\@_);
    \$self;
}
EOM
        return;
    }

    if (grep /$method/, @{$HTML::HTPL::Munge::variables{$class}}) {
        eval <<EOM;

package $impclass;
sub $impmethod {
    my \$self = shift;
    if (\@_) {
        \$self->{'$method'} = shift;
    } else {
        return \$self->{'$method'};
    }
}
EOM
        die $@ if ($@);    
    }

    my $ref = eval("*$impfunc\{CODE}");
    Carp::croak("No method $method in $class") unless (UNIVERSAL::isa($ref, 'CODE'));
    eval <<EOM;
package $class;
sub $method {
    \$HTML::HTPL::Munge::Stub::lastself{'$class'} ||= [];
    push(\@{\$HTML::HTPL::Munge::Stub::lastself{'$class'}}, \$_[0]);
    my \@result = $impfunc(\@_);
    pop(\@{\$HTML::HTPL::Munge::Stub::lastself{'$class'}});
    wantarray ? \@result : \$result[0];
}

package $impclass;
sub $method {
    my \$self = \$HTML::HTPL::Munge::Stub::lastself{'$class'}->[-1]
         || Carp::croak("Can't encapsulate $method in $class");
    $impmethod(\$self, \@_);
}

EOM
    $@ = $save;
    return;
}


package HTML::HTPL::Munge::Stub2;
use strict;
use vars qw($AUTOLOAD @EXPORT_OK);
@EXPORT_OK = qw(AUTOLOAD);

sub AUTOLOAD {
    my $save = $@;
    $@ = undef;
    my $index = rindex($AUTOLOAD, "::");
    Carp::croak("Can't parse $AUTOLOAD") unless ($index > -1);
    my $class = substr($AUTOLOAD, 0, $index);
    my $method = substr($AUTOLOAD, $index + 2);
    if ($method eq 'DESTROY') {
        *$AUTOLOAD = {};
        goto &$AUTOLOAD;
    }
    $class =~ s/::[^:]+$//;
    my $shadow_class = '__shadow__';
    my $shadow_method = '__shadow__';
    return if ($method =~ /^$shadow_method/);
    $HTML::HTPL::Munge::Stub::AUTOLOAD = "${class}::$method";
    &HTML::HTPL::Munge::Stub::loader;
    goto &$AUTOLOAD;
}

