package WWW::Connpass::Event::Question;
use strict;
use warnings;

use JSON 2;
use Module::Load ();

my @QUESTION_TYPES = qw/FreeText CheckBox Radio PullDown/;

sub _answer_type { die "this is abstract method" }

sub new {
    my ($class, %args) = @_;
    die "$class is abstract class" if $class eq __PACKAGE__;

    # assertion
    if (exists $args{answer_type}) {
        $args{answer_type} == $class->_answer_type
            or die "Invalid answer type: $args{answer_type}";
    }
    else {
        $args{answer_type} = $class->_answer_type;
    }

    # normalize required option
    $args{required} = $args{required} ? JSON::true : JSON::false;

    # normalize answer_frame to options
    if (exists $args{answer_frame}) {
        $args{options} = [
            map { +{ title => $_ } } @{
                delete $args{answer_frame}
            }
        ];
    }

    return bless \%args => $class;
}

sub inflate {
    my ($class, %args) = @_;
    $class .= '::'.$QUESTION_TYPES[$args{answer_type} - 1];
    Module::Load::load($class);
    return $class->new(%args);
}

sub raw_data { +{%{$_[0]}} }

sub title { shift->{title} }
sub options { shift->{options} }
sub answer_type { shift->{answer_type} }
sub required { shift->{required} }

sub answer_frame { map { $_->{title} } @{ shift->{options} }  }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::Event::Question - TODO

=head1 SYNOPSIS

    use WWW::Connpass::Event::Question;

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
