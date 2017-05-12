package WWW::Webrobot::Print::TestSimple;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004-2006 ABAS Software AG


use WWW::Webrobot::Util qw/textify/;
use WWW::Webrobot::XML2Tree;
use Test::More qw/no_plan/;


sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);
    return $self;
}

sub global_start {
    #my $self = shift;
}

sub item_pre {
    #my $self = shift;
    #my ($arg) = @_;
}

sub responses {
    my ($r) = @_;
    my @list = ();
    while (defined $r) {
        push @list, " "x8 . "$r->{_rc} $r->{_request}->{_uri}";
        $r = $r -> {_previous};
    }
    return @list;
}

sub delete_parameters {
    my ($uri) = @_;
    $uri =~ s/\?.*$//;
    return $uri;
}

sub bool_assert { $_[0] ? "FALSE" : "TRUE " }
sub bool { $_[0] ? "TRUE " : "FALSE" }

sub item_post {
    my ($self, $r, $arg) = @_;
    my $data = $arg->{data};
    my $out_ok = "$arg->{method} $arg->{url}";
    if (! ok(! $arg->{fail}, textify $out_ok)) {

        diag " "x4 . textify "Request:     $arg->{method} $arg->{url}";

        diag " "x4 . textify "Description: $arg->{description}";

        diag textify " "x4 . "Predicates:  " . bool_assert($arg->{fail});
        foreach my $s (@{$arg->{fail_str}}) {
            $s =~ s/^(.)/ bool($1) /ge;
            $s =~ s/^/        /gm;
            diag textify $s;
        }

        if ($arg->{assert_xml}) {
            foreach my $assert (@{$arg->{assert_xml}}) {
                my $xml = WWW::Webrobot::XML2Tree::print_xml($assert);
                diag " "x4 . textify "Expression of the assertion in this request:";
                diag " "x8 . textify $_ foreach (split /\n/, $xml);
            }
        }

        diag " "x4 . textify "Responses:";
        diag textify(delete_parameters($_)) foreach (responses($r));
        if ($arg->{new_properties}) {
            diag " "x4 . textify "New properties:";
            diag " "x8 . textify "property '$_->[0]' => '$_->[1]'" foreach (@{$arg->{new_properties}});
        }
        if ($r && (my $c = $r->content)) {
            my $line = substr($c, 0, 132);
            diag " "x4 . textify "Content: [$line]" ;
        }
    }
    else {
        diag " "x10 . textify $arg->{description};
    }

}

sub global_end {
    #my $self = shift;
}

1;

=head1 NAME

WWW::Webrobot::Print::TestSimple - write response content according to L<Test::More>

=head1 DESCRIPTION

The same as WWW::Webrobot::Print::Test, but it doesn't output form data

=head1 METHODS

See L<WWW::Webrobot::pod::OutputListeners>.

=over

=item WWW::Webrobot::Print::TestSimple -> new ();

=back
