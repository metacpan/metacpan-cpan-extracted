package YAML::Perl::Stream;
use strict;
use warnings;

package YAML::Perl::Stream::Input;
use YAML::Perl::Base -base;

package YAML::Perl::Stream::Input;
use YAML::Perl::Base -base;

package YAML::Perl::Stream::Output;
use YAML::Perl::Base -base;

field 'buffer';

sub open {
    my $self = shift;
    if (not @_) {
        my $output = '';
        $self->buffer(\$output); 
    }
    else {
        XXX @_;
    }
    return 1;
}

sub write {
    ${$_[0]->buffer} .= $_[1];
}

sub string {
    my $self = shift;
    return ${$self->buffer};
}

1;
