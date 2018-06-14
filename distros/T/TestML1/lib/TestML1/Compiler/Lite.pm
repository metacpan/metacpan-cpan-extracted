package TestML1::Compiler::Lite;

use TestML1::Base;
extends 'TestML1::Compiler';

use TestML1::Runtime;

has input => ();
has points => ();
has tokens => ();
has function => ();

my $WS = qr!\s+!;
my $ANY = qr!.!;
my $STAR = qr!\*!;
my $NUM = qr!-?[0-9]+!;
my $WORD = qr![-\w]+!;
my $HASH = qr!#!;
my $EQ = qr!=!;
my $TILDE = qr!~!;
my $LP = qr!\(!;
my $RP = qr!\)!;
my $DOT = qr!\.!;
my $COMMA = qr!,!;
my $SEMI = qr!;!;
my $SSTR = qr!'(?:[^']*)'!;
my $DSTR = qr!"(?:[^"]*)"!;
my $ENDING = qr!(?:$RP|$COMMA|$SEMI)!;

my $POINT = qr!$STAR$WORD!;
my $QSTR = qr!(?:$SSTR|$DSTR)!;
my $COMP = qr!(?:$EQ$EQ|$TILDE$TILDE)!;
my $OPER = qr!(?:$COMP|$EQ)!;
my $PUNCT = qr!(?:$LP|$RP|$DOT|$COMMA|$SEMI)!;

my $TOKENS = qr!(?:$POINT|$NUM|$WORD|$QSTR|$PUNCT|$OPER)!;

our $block_marker = '===';
our $point_marker = '---';

sub compile_code {
    my ($self) = @_;
    $self->{function} = TestML1::Function->new;
    while (length $self->{code}) {
        $self->{code} =~ s{^(.*)(\r\n|\n|)}{};
        $self->{line} = $1;
        $self->tokenize;
        next if $self->done;
        $self->parse_assignment ||
        $self->parse_assertion ||
        $self->fail;
    }
}

sub tokenize {
    my ($self) = @_;
    $self->{tokens} = [];
    while (length $self->{line}) {
        next if $self->{line} =~ s/^$WS//;
        next if $self->{line} =~ s/^$HASH$ANY*//;
        if ($self->{line} =~ s/^($TOKENS)//) {
            push @{$self->{tokens}}, $1;
        }
        else {
            $self->fail("Failed to get token here: '$self->{line}'");
        }
    }
}

sub parse_assignment {
    my ($self) = @_;
    return unless $self->peek(2) eq '=';
    my ($var, $op) = $self->pop(2);
    my $expr = $self->parse_expression;
    $self->pop if not $self->done and $self->peek eq ';';
    $self->fail unless $self->done;
    push @{$self->function->statements},
        TestML1::Assignment->new(name => $var, expr => $expr);
    return 1;
}

sub parse_assertion {
    my ($self) = @_;
    return unless grep /^$COMP$/, @{$self->tokens};
    $self->{points} = [];
    my $left = $self->parse_expression;
    my $token = $self->pop;
    my $op =
        $token eq '==' ? 'EQ' :
        $token eq '~~' ? 'HAS' :
        $self->fail;
    my $right = $self->parse_expression;
    $self->pop if not $self->done and $self->peek eq ';';
    $self->fail unless $self->done;

    push @{$self->function->statements}, TestML1::Statement->new(
        expr => $left,
        assert => TestML1::Assertion->new(
            name => $op,
            expr => $right,
        ),
        @{$self->points} ? (points => $self->points) : (),
    );
    return 1;
}

sub parse_expression {
    my ($self) = @_;

    my $calls = [];
    while (not $self->done and $self->peek !~ /^($ENDING|$COMP)$/) {
        my $token = $self->pop;
        if ($token =~ /^$NUM$/) {
            push @$calls, TestML1::Num->new(value => $token + 0);
        }
        elsif ($token =~/^$QSTR$/) {
            my $str = substr($token, 1, length($token) - 2);
            push @$calls, TestML1::Str->new(value => $str);
        }
        elsif ($token =~ /^$WORD$/) {
            my $call = TestML1::Call->new(name => $token);
            if (not $self->done and $self->peek eq '(') {
                $call->{args} = $self->parse_args;
            }
            push @$calls, $call;
        }
        elsif ($token =~ /^$POINT$/) {
            $token =~ /($WORD)/ or die;
            $token = $1;
            $token =~ s/-/_/g;
            push @{$self->{points}}, $token;
            push @$calls, TestML1::Point->new(name => $token);
        }
        else {
            $self->fail("Unknown token '$token'");
        }
        if (not $self->done and $self->peek eq '.') {
            $self->pop;
        }
    }
    return @$calls == 1
        ? $calls->[0]
        : TestML1::Expression->new(calls => $calls);
}

sub parse_args {
    my ($self) = @_;
    $self->pop eq '(' or die;
    my $args = [];
    while ($self->peek ne ')') {
        push @$args, $self->parse_expression;
        $self->pop if $self->peek eq ',';
    }
    $self->pop;
    return $args;
}

sub compile_data {
    my ($self) = @_;
    my $input = $self->data;
    $input =~ s/^#.*\n/\n/mg;
    my @blocks = grep $_, split /(^$block_marker.*?(?=^$block_marker|\z))/ms, $input;
    for my $block (@blocks) {
        $block =~ s/\n+\z/\n/;
    }

    my $data = [];
    for my $string_block (@blocks) {
        my $block = TestML1::Block->new;
        $string_block =~ s/^$block_marker\ +(.*?)\ *\n//g
            or die "No block label! $string_block";
        $block->{label} = $1;
        $string_block =~ s/\A(.*?)(^$point_marker\ )/$2/sm;
        while (length $string_block) {
            next if $string_block =~ s/^\n+//;
            my ($key, $value);
            if ($string_block =~ s/\A$point_marker\ +($WORD):\ +(.*)\n//g or
                $string_block =~
                    s/\A$point_marker\ +($WORD)\n(.*?)(?=^$point_marker|\z)//msg
            ) {
                ($key, $value) = ($1, $2);
                $key =~ s/-/_/g;
            }
            else {
                die "Failed to parse TestML1 string:\n$string_block";
            }
            $block->{points} ||= {};
            my $eol = ($value =~ s/(\r?\n)\s*\z//) ? $1 : '';
            if (length $value) {
                $value .= $eol;
            }
            $block->{points}{$key} = $value;

            if ($key =~ /^(ONLY|SKIP|LAST)$/) {
                $block->{$key} = 1;
            }
        }
        push @$data, $block;
    }
    $self->function->{data} = $data if @$data;
}

sub done {
    my ($self) = @_;
    @{$self->{tokens}} ? 0 : 1
}

sub peek {
    my ($self, $index) = @_;
    $index ||= 1;
    die if $index > @{$self->{tokens}};
    $self->{tokens}->[$index - 1];
}

sub pop {
    my ($self, $count) = @_;
    $count ||= 1;
    die if $count > @{$self->{tokens}};
    splice @{$self->{tokens}}, 0, $count;
}

sub fail {
    my ($self, $message) = @_;
    my $text = "Failed to compile TestML1 document.\n";
    $text .= "Reason: $message\n" if $message;
    $text .= "\nCode section of failure:\n$self->{line}\n$self->{code}\n";
    die $text;
}

1;
