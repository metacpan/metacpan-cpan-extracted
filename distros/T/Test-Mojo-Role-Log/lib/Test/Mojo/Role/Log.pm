package Test::Mojo::Role::Log;
use Mojo::Base -role, -signatures;
our $VERSION = '0.2.1';

around 'new' => sub {
    my $orig = shift;
    my $self = $orig->(@_);
    my $log = $self->app->log;
    if ( $log->level eq 'fatal' ){
        $log->unsubscribe(
            message => $log->subscribers('message')->[0] 
        );
        if ($log->can('trace')){
            $log->level('trace');
        }
        else {
            $log->level('debug');
        }
    }
    $log->on(message => sub {
        my $log = shift;
        push @{$self->logCache}, \@_;
    });
    return $self;
};


around '_build_ok' => sub {
    my $orig = shift;
    my $self = $_[0];
    $self->logCache([]);
    return $orig->(@_);
};

has logCache => sub {
    [];
};

sub _log_test ($self,$rx,$level,$like,$desc=undef) {
    $desc //= "log ".
        (defined $level ? "level=$level ":"").
        ($like eq 'like' ? "" : "un")."like $rx";
    my $ok = $like ? 0 : 1;
    my $logs = '';
    for my $entry (@{$self->logCache}){
        my ($l,@msg) =  @$entry;
        if (not defined $level or $l eq $level){
            $logs .= join("\n",@msg)."\n";
        }
    }
    return $self->test($like,$logs,$rx,Test::Mojo::_desc($desc));
}

sub log_like ($self,$rx,$desc=undef) {
    return $self->_log_test($rx,undef,'like',$desc);
}

sub log_unlike ($self,$rx,$desc=undef) {
    return $self->_log_test($rx,undef,'unlike',$desc);
}

sub log_trace_like ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'trace','like',$desc);
}

sub log_debug_like ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'debug','like',$desc);
}

sub log_info_like ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'info','like',$desc);
}

sub log_warn_like ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'warn','like',$desc);
}

sub log_error_like ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'error','like',$desc);
}

sub log_fatal_like ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'fatal','like',$desc);
}

sub log_trace_unlike ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'trace','unlike',$desc);
}

sub log_debug_unlike ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'debug','unlike',$desc);
}

sub log_info_unlike ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'info','unlike',$desc);
}

sub log_warn_unlike ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'warn','unlike',$desc);
}

sub log_error_unlike ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'error','unlike',$desc);
}

sub log_fatal_unlike ($self,$rx,$desc=undef) {
    return shift->_log_test($rx,'fatal','unlike',$desc);
}


1;

=encoding utf8

=head1 NAME

Test::Mojo::Role::Log - test mojo log messages

=head1 SYNOPSIS

 use Test::Mojo;

 my $t = Test::Mojo->with_roles('+Log')->new('MyApp');
 
 $t->get_ok('/gugus')
    ->log_like(qr{GET "/gugus"})
    ->log_debug_like(qr{GET "/gugus"})
    ->log_info_unlike(qr{GET "/gugus"})
    ->log_debug_like(qr{200 OK.+s.+/s})

 done_testing();
 
=head1 DESCRIPTION

The L<Test::Mojo::Role::Log> role enhances L<Test::Mojo> with additional methods to check log output.

=head1 ATTRIBUTES

=head2 logCache

Points to an array with all the log messages issued since the last request.

=head1 METHODS
 
The role L<Test::Mojo::Role::Log> adds the following new methods to L<Test::Mojo> ones.
 
=head2 log_like($rx,$desc)

  $t->get_ok('/hello')
    ->log_like(undef,qr{/hello not found},"Request got logged")
 
Check if the given log message has been issued. All the log messages issued since the start of the current request will get checked.
If $logLevel is set to undef the logLevel does not get checked.

=head2 log_trace_like($rx,$desc)  (if mojo supports it)
 
Find a trace level log message matching the given $rx.

=head2 log_debug_like($rx,$desc)
 
Find a debug level log message matching the given $rx.

=head2 log_info_like($rx,$desc)
 
Find a info level log message matching the given $rx.

=head2 log_warn_like($rx,$desc)
 
Find a warn level log message matching the given $rx.

=head2 log_error_like($rx,$desc)
 
Find a error level log message matching the given $rx.

=head2 log_fatal_like($rx,$desc)
 
Find a fatal level log message matching the given $rx.

=head2 *_unlike

For each of the methods above there is ac coresponding

=head1 AUTHOR

Tobias Oetiker E<lt>tobi@oetiker.chE<gt>

=head1 COPYRIGHT

Copyright 2020, OETIKER+PARTNER AG

=head1 LICENSE

Perl Artistic License
