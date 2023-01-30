package Variable::Declaration::Info;
use v5.12.0;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args = @_;
    bless \%args => $class;
}

sub declaration { $_[0]->{declaration} }
sub type        { $_[0]->{type} }
sub attributes  { $_[0]->{attributes} }

1;
__END__

=encoding utf-8

=head1 NAME

    Variable::Declaration::Info - Information about variables

=head1 SYNOPSIS

    use Variable::Declaration;
    use Types::Standard -types;

    let Str $str = "message";

    my $info = Variable::Declaration::info \$str;
    $info->type; # Str

=head1 DESCRIPTION

Variable::Declaration::info returns objects of this class to describe variables.  The following methods are available:

=head2 $info->type

type of variable

=head2 $info->attributes

attributes of variable

=head2 $info->declaration

variable is defined by this declaration

=head1 SEE ALSO

L<Variable::Declaration>

