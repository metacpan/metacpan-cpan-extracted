package Test::Kantan::Reporter::Spec;
use strict;
use warnings;
use utf8;
use 5.010_001;
use Term::ANSIColor ();
use IO::Handle;

use Moo;

extends 'Test::Kantan::Reporter::Base';

has messages => (is => 'ro', default => sub { +[] });
has message_groups => (is => 'ro', default => sub { +[] });
has message_stack => (is => 'ro', default => sub { +[] });

no Moo;

our $UTF8;

use Scope::Guard;

sub start {
    my $self = shift;

    my $encoding = do {
        require Term::Encoding;
        Term::Encoding::get_encoding();
    };

    $UTF8 = ($encoding =~ /utf-?8/i && !$ENV{KANTAN_ASCII}) ? 1 : 0;

    binmode *STDOUT, ":encoding(${encoding})";
    STDOUT->autoflush(1);

    $self->{root_suite} = $self->suite('');

    print "\n\n";
}

sub colored {
    my ($self, $color, $msg) = @_;
    $self->color ? Term::ANSIColor::colored($color, $msg) : $msg;
}

sub head_sp {
    my ($self) = @_;
    return ' ' x (2+($self->{level}-1)*2);
}

sub suite {
    my ($self, $title) = @_;

    if (length($title) > 0) {
        print "\n" if $self->{level} <= 2;
        printf "%s%s\n", $self->head_sp, $title;
    }

    push @{$self->{message_stack}}, [];
    push @{$self->{fail_stack}}, $self->state->fail_cnt;
    push @{$self->{title}}, $title;
    $self->{level}++;
    return Scope::Guard->new(
        sub {
            my $orig_fail_cnt = pop @{$self->{fail_stack}};
            my $messages = pop @{$self->{message_stack}};
            my $titles = [@{$self->{title}}];
            if ($orig_fail_cnt != $self->state->fail_cnt && @$messages) {
                push @{$self->{message_groups}}, Test::Kantan::Reporter::Spec::MessageGroup->new(
                    titles => $titles,
                    messages => $messages,
                );
            }

            pop @{$self->{title}};

            --$self->{level};
        }
    );
}

sub step {
    my ($self, $title) = @_;

    if (length($title) > 0) {
        printf "%s%s\n", $self->head_sp, $title;
    }
}

sub fail {
    my ($self, %args) = @_;
    $self->message(Test::Kantan::Reporter::Spec::Message::Fail->new(
        reporter => $self,
        %args
    ));
}

sub pass {
    my ($self, %args) = @_;
    $self->message(Test::Kantan::Reporter::Spec::Message::Pass->new(
        reporter => $self,
        %args
    ));
}

sub message {
    my ($self, $message) = @_;
    push @{$self->{message_stack}->[-1]}, $message;
}

sub exception {
    my ($self, %args) = @_;
    $self->message(Test::Kantan::Reporter::Spec::Message::Exception->new(
        reporter => $self,
        %args
    ));
}

sub diag {
    my ($self, %args) = @_;

    $self->message(Test::Kantan::Reporter::Spec::Message::Diag->new(
        reporter => $self,
        %args
    ));
}

sub finalize {
    my ($self, %args) = @_;

    delete $self->{root_suite};

    if (!$self->state->is_passing || $ENV{KANTAN_VERBOSE}) {
        if (@{$self->{message_groups}}) {
            printf "\n\n\n  %s:\n", $self->colored(['red'], '(Diagnostic message)');
            for my $message_group (@{$self->{message_groups}}) {
                # Show group title
                {
                    print "\n";
                    my $i=0;
                    my @titles = @{$message_group->titles};
                    shift @titles; # Remove root
                    for my $title (@titles) {
                        printf("    %s%s%s\n", (' ' x ($i++*2)),
                            $self->colored(['green'], $title),
                            $i==@titles ? ':' : ''
                        );
                    }
                }

                for my $message (@{$message_group->messages}) {
                    my $str = $message->render();
                    $str =~ s/^/      /mg;
                    print "\n$str";
                }
            }
        }
    }

    # If Test::Builder was loaded...
    if (Test::Builder->can('new')) {
        if (!Test::Builder->new->is_passing) {
            # Fail if Test::Builder was failed.
            $self->state->failed;
        }
    }

    printf "\n\n%sok\n", $self->state->fail_cnt ? 'not ' : '';
    print "1..1\n";
}


package Test::Kantan::Reporter::Spec::MessageGroup;

use Moo;

has messages => (is => 'ro');
has titles   => (is => 'ro');

no Moo;

package Test::Kantan::Reporter::Spec::Message::Base;
use Test::Kantan::Util ();

use Moo;

has reporter => (
    is => 'ro',
    wek_ref => 1,
    handles => [qw(colored cutoff)],
);

has caller  => ( is => 'ro' );

no Moo;

sub render_caller_pos {
    my ($self) = @_;

    return sprintf(
        "   at %s line %s\n",
        $self->colored(['yellow'], $self->caller->filename // '-'),
        $self->colored(['yellow'], $self->caller->line)
    );
}

sub truncstr {
    my ($self, $str, $cutoff) = @_;
    return Test::Kantan::Util::truncstr($str, $cutoff // $self->reporter->cutoff);
}

package Test::Kantan::Reporter::Spec::Message::Diag;

use Test::Kantan::Util qw(dump_data);

use Moo;

extends 'Test::Kantan::Reporter::Spec::Message::Base';

has message => ( is => 'ro', required => 1 );
has caller  => ( is => 'ro', required => 1 );
has cutoff  => ( is => 'ro', required => 1 );

no Moo;

sub render {
    my ($self, $message) = @_;

    my @ret;

    my $msg = dump_data($self->message);
    $msg =~ s/\n/\\n/g;
    push @ret, $self->colored(['magenta'], $Test::Kantan::Reporter::Spec::UTF8 ? "\x{2668}\n" : "#\n");
    push @ret, $self->colored(['magenta on_black'], $self->truncstr($msg, $self->cutoff)) . "\n";
    push @ret, $self->render_caller_pos();
    return join '', @ret;
}


package Test::Kantan::Reporter::Spec::Message::Fail;

use Moo;

extends 'Test::Kantan::Reporter::Spec::Message::Base';

has description => ( is => 'ro', required => 0 );
has diag => ( is => 'ro', required => 0 );
has caller  => ( is => 'ro', required => 1 );

no Moo;

sub render {
    my ($self) = @_;

    my @ret;
    push @ret, sprintf(
        "%s\n%s\n",
        $self->colored(['red'], $Test::Kantan::Reporter::Spec::UTF8 ? "\x{2716}" : "x"),
        $self->colored(['red on_black'], $self->caller->code)
    );
    if (defined $self->description) {
        push @ret, sprintf("%s\n", $self->colored(['red on_black'], $self->description));
    }
    if (defined $self->diag) {
        my $diag = $self->diag;
        $diag =~ s/^/  /mg;
        push @ret, sprintf("%s\n", $self->colored(['red on_black'], $diag));
    }
    push @ret, $self->render_caller_pos();
    return join('', @ret);
}


package Test::Kantan::Reporter::Spec::Message::Exception;

use Moo;

extends 'Test::Kantan::Reporter::Spec::Message::Base';

has message => ( is => 'ro', required => 1 );

no Moo;

sub render {
    my ($self) = @_;

    my $msg = $self->truncstr($self->message, 1024);
    return join(
        "\n",
        $self->colored(['magenta on_black'], $Test::Kantan::Reporter::Spec::UTF8 ? "\x{2620}" : "orz"),
        $msg,
    );
}


package Test::Kantan::Reporter::Spec::Message::Pass;

use Moo;

extends 'Test::Kantan::Reporter::Spec::Message::Base';

has caller => ( is => 'ro' );
has description => ( is => 'ro' );

no Moo;

sub render {
    my ($self) = @_;
    join('',
        $self->colored(['green'], $Test::Kantan::Reporter::Spec::UTF8 ? "\x{2713}\n" : "o"),
        $self->caller->code, "\n",
        $self->render_caller_pos($self)
    );
}


1;
