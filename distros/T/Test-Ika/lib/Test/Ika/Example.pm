package Test::Ika::Example;
use strict;
use warnings;
use utf8;

use Carp ();
use Try::Tiny;
use Test::Builder;

{ # accessor
    sub name   { $_[0]->{name} }
    sub skip   { $_[0]->{skip} > 0 }
    sub result { $_[0]->{result} }
    sub output { $_[0]->{output} }
    sub error  { $_[0]->{error} }
}

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $name = delete $args{name} || Carp::croak "Missing name";
    my $code = delete $args{code}; # allow specification only

    my $cond = exists $args{cond} ? delete $args{cond} : sub { 1 };
    my $skip = exists $args{skip} ? delete $args{skip} : (!$code ? 1 : 0); # xit

    bless {
        name => $name,
        code => $code,
        cond => $cond,
        skip => $skip,
    }, $class;
}

sub run {
    my $self = shift;

    my $error;
    my $ok;
    my $output = "";

    if (defined $self->{cond} && defined $self->{code}) {
        my $cond = ref $self->{cond} eq 'CODE' ? $self->{cond}->() : $self->{cond};
        $cond = !!$cond;
        $self->{skip}++ unless $cond;
    }

    try {
        open my $fh, '>', \$output;
        $ok = do {
            no warnings 'redefine';
            my $builder = Test::Builder->create();
            local $Test::Builder::Test = $builder;
            $builder->no_header(1);
            $builder->no_ending(1);
            $builder->output($fh);
            $builder->failure_output($fh);
            $builder->todo_output($fh);

            if ($self->{skip}) {
                $builder->skip;
            }
            else {
                $self->{code}->();
            }

            $builder->finalize();
            $builder->is_passing();
        };
    } catch {
        $error = "$_";
    } finally {
        my $name = $self->{name};
        if ($self->{skip}) {
            $name .= $self->{code} ? ' [DISABLED]' : ' [NOT IMPLEMENTED]';
        }

        my $test = $self->{skip} ? -1 : !!$ok;

        $self->{result} = $test;
        $self->{output} = $output;
        $self->{error}  = $error;

        $Test::Ika::REPORTER->it($name, $test, $output, $error);
    };
}

1;
