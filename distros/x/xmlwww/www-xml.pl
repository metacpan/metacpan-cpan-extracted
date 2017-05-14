#!/usr/bin/perl -w

use strict;

use FindBin qw/$Bin/;
use File::Basename qw/ basename /;
use File::Spec::Functions qw/ catfile /;

use POSIX qw/setsid setuid/;

use lib catfile($Bin, 'lib');
use WWWXML::Config;
use WWWXML::Logger;
use WWWXML::Output;

use XML::Twig;
use Time::HiRes qw/gettimeofday/;

our ($user, $session, $query, $logger, $CONFIG);
our ($tamino, $t);

BEGIN {
    $CONFIG = WWWXML::Config->new(catfile($Bin,"www-xml.conf"), undef, [
        "help|h|?",
        "debug!",
        "logtime!",
        "screen!",
        "pidfile=s",
        "fcgi-socket-path=s",
        "setuid-user=s",
        "detach!",
    ]);
    
    $logger = WWWXML::Logger->logger(
        filename => catfile($Bin, 'www-xml.log'),
        screen   => $::CONFIG->{screen},
    );
    
    if ($^O ne 'MSWin32' and not $ENV{APACHE_TEST_ENV}) {
        $ENV{FCGI_SOCKET_PATH}  = $CONFIG->{fcgi_socket_path};
        $ENV{FCGI_LISTEN_QUEUE} = $CONFIG->{fcgi_listen_queue};
    }
}

use CGI;
use CGI::Fast;

use FCGI;
use FCGI::ProcManager;

use CGI::Session;

use Tamino;

$|++;

for my $h (values %$WWWXML::Config::action_handlers) {
    local $_ = $h;
    s/^\+//;
    $_ = catfile('WWWXML','Modules',"$_.pm");
    require $_;
}

if($::CONFIG->{detach}) {
#    close STDIN;
#    close STDOUT;
#    close STDERR;
    exit(0) if (fork);
	setsid();
    setuid(scalar getpwnam($CONFIG->{setuid_user})) if $CONFIG->{setuid_user};

    undef $CGITempFile::TMPDIRECTORY;
    CGITempFile::find_tempdir();
}

exit(&::main(@ARGV));

sub main {
    $CGI::POST_MAX = 1024 * $CONFIG->{max_upload_size};
    
    CGI::Session->name('www-xml-sid');
    
    my $proc_manager;
    if ($^O ne 'MSWin32' and not $ENV{APACHE_TEST_ENV}) {
        # write PID to file
        open my $fh_pid, '>', catfile($Bin,$CONFIG->{pidfile})
            or warn "$CONFIG->{pidfile}: $!\n" and return 10;
        print $fh_pid $$;
        close $fh_pid;
    
        if($::CONFIG->{detach} && $CONFIG->{fcgi_processes} > 1) {
            $proc_manager = FCGI::ProcManager->new({ n_processes => $CONFIG->{fcgi_processes} });
            $proc_manager->pm_manage;
        }
    }
    
    $tamino = Tamino->new(
        map { $_ => $::CONFIG->{"tamino_$_"} }
            grep { defined $::CONFIG->{"tamino_$_"} }
                qw/server db collection user password encoding timeout keep_alive/
    );
    
    $::tamino->_debug($::CONFIG->{debug});
    unless($CONFIG->{debug}) {
        $::t = $tamino->begin or warn $tamino->error and return 20;
    }

    my $tmpl;
    my $action;
    my ($t0,$t1);    
    my $sessdir = catfile($Bin,'sessions');
    while ($query = CGI::Fast->new) {
        $proc_manager->pm_pre_dispatch if $proc_manager;
        
        if($CONFIG->{debug}) {
            $::t = $::tamino->begin_tran or die $::tamino->error;
        }
        
        if($::CONFIG->{logtime}) {
            $tamino->queries(0);
            $tamino->queries_time(0);
            $t0 = sprintf "%d.%06d", gettimeofday;
        }
        
        unlink grep { time-(stat$_)[9] > $::CONFIG->{session_expire} } glob "$sessdir/*";
        
        $session = CGI::Session->new(
           'driver:file',
           $query,
           { Directory => catfile($Bin,'sessions') }
        ) or warn CGI::Session->errstr and return 30;
        
        $action = $::query->get_param('action');
        
        $::logger->debug("action=$action=");
        
        my $class = $WWWXML::Config::action_handlers->{$action} or warn "Illegal action: '$action'" and WWWXML::Output->redirect_status(403) and next;
        my $anon = $class =~ s/^\+//;
        
        undef $user;
        if ($session->param('uid')) {
            $t->simplify([keyattr => [], forcearray => [qw/number card/]]);
            $user = $t->xquery(q{for $x in input()/clientz/client[@id='%s'] return $x}, $session->param('uid'))
                or warn $t->error and return 40;
            $user = $user->{client};
        }
        
        if($anon || $user) {
            eval {
                $tmpl = "WWWXML::Modules::$class"->$action;
            };
            if($@) {
                $::logger->error($@);
                $tmpl = WWWXML::Output->new_template(name => 'null');
                local $_ = $@;
                while(s/\s+at\s+[\w.\\\/\$\-:()]+\.p[ml]\s+line\s+\d+\.\s*$//gs) { 1 };
                $tmpl->tmpl_param(submit_error => [{ text => $_ }] );
            }
        } else {
            WWWXML::Output->redirect_status(403);
        }
        
        $session->flush;
        
        if($tmpl) {
            $tmpl->tmpl_param(static_dir => $::CONFIG->{static_dir});
            $tmpl->tmpl_param(action => $action);
            $tmpl->tmpl_param("action_$action" => 1);
            if($user) {
                $tmpl->tmpl_param("u_$_" => $user->{$_}) for qw/id fname sname inn birth/;
                $tmpl->tmpl_param("u_$_" => [ map +{ %$_ }, @{$user->{"${_}s"}->{$_}} ]) for qw/number card/;
            }
            
            if($::CONFIG->{logtime}) {
                $t1 = sprintf "%d.%06d", gettimeofday;
                $t1 -= $t0;
                $tmpl->tmpl_param(_exec_time    => sprintf("%.6f",$t1));
                $tmpl->tmpl_param(_queries_time => sprintf("%.6f",$tamino->queries_time));
                $tmpl->tmpl_param(_clean_time   => sprintf("%.6f",$t1 - $tamino->queries_time));
                $tmpl->tmpl_param(_queries      => $tamino->queries);
            }

            if(index(lc ref $tmpl, 'form') >= 0) { WWWXML::Output->print_form($tmpl); }
            else { WWWXML::Output->print_template($tmpl); }

        }
    
        if($::CONFIG->{logtime}) {
            $t1 = sprintf "%d.%06d", gettimeofday;
            $t1 -= $t0;
            $::logger->debug(sprintf("ET:%.6f; QT:%.6f; CT:%.6f; Qs:%d;",$t1,$tamino->queries_time,$t1 - $tamino->queries_time,$tamino->queries));
        }
        
        if($CONFIG->{debug}) {
            undef $::t;
        }
        
        $proc_manager->pm_post_dispatch if $proc_manager;
    }
    
    return 0;
}

sub CGI::Fast::get_param {
    my $self = shift;
    local $_ = $self->url_param(@_) || $self->param(@_);
    return unless defined;
    my %t = ('"' => '&quot;', '<' => '&lt;', '&' => '&amp;', "'" => '&apos;');
    s/['"<&]/$t{$1}/e;
    return $_;
}

