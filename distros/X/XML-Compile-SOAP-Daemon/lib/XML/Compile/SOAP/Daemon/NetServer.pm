# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP::Daemon::NetServer;
use vars '$VERSION';
$VERSION = '3.12';


# The selected type of netserver gets added to the @ISA during new(),
# so there are two base-classes!
use parent 'XML::Compile::SOAP::Daemon';
our @ISA;

use Log::Report 'xml-compile-soap-daemon';

use Time::HiRes               qw/time alarm/;
use XML::Compile::SOAP::Util  qw/:daemon/;
use XML::Compile::SOAP::Daemon::LWPutil;

# Net::Server error levels to Log::Report levels
my @levelToReason = qw/ERROR WARNING NOTICE INFO TRACE/;


sub new($%)
{   my ($class, %args) = @_;
    my $daemon = $args{based_on} || 'Net::Server::PreFork';

    my $self;
    if(ref $daemon)
    {   $self = $daemon;
    }
    else
    {   eval "require $daemon";
        $@ and error __x"failed to compile Net::Server class {class}, {error}"
           , class => $daemon, error => $@;
        $self = $daemon->new(%args);
    }

    $self->{based_on} = ref $daemon || $daemon;
    $daemon->isa('Net::Server')
        or error __x"The daemon is not a Net::Server, but {class}"
             , class => $self->{based_on};

    # Beautiful Perl
    push @ISA, $self->{based_on};
    (bless $self, $class)->init(\%args);  # $ISA[0] branch only
}

sub options()
{   my ($self, $ref) = @_;
    my $prop = $self->{server};
    $self->SUPER::options($ref);
    foreach ( qw/client_timeout client_maxreq client_reqbonus name/ )
    {   $prop->{$_} = undef unless exists $prop->{$_};
        $ref->{$_} = \$prop->{$_};
    }
}

sub default_values()
{   my $self  = shift;
    my $def   = $self->SUPER::default_values;
    my %mydef =
     ( # changed defaults
       setsid => 1, background => 1, log_file => 'Log::Report'

       # make in-code defaults explicit, Net::Server 0.97
       # see http://rt.cpan.org//Ticket/Display.html?id=32226
     , log_level => 2, syslog_ident => 'net_server', syslog_logsock => 'unix'
     , syslog_facility => 'daemon', syslog_logopt => 'pid'

     , client_timeout => 30, client_maxreq => 100
     , client_reqbonus => 0, name => 'soap daemon'
     );
    @$def{keys %mydef} = values %mydef;
    $def;
}

sub post_configure()
{   my $self = shift;
    my $prop = $self->{server};

    # Change the way messages are logged

    my $loglevel = $prop->{log_level};
    my $reasons  = ($levelToReason[$loglevel] || 'NOTICE') . '-';

    my $logger   = delete $prop->{log_file};
    if($logger eq 'Log::Report')
    {   # dispatching already initialized
    }
    elsif($logger eq 'Sys::Syslog')
    {   dispatcher SYSLOG => 'default'
          , accept    => $reasons
          , identity  => $prop->{syslog_ident}
          , logsocket => $prop->{syslog_logsock}
          , facility  => $prop->{syslog_facility}
          , flags     => $prop->{syslog_logopt}
    }
    else
    {   dispatcher FILE => 'default', to => $logger;
    }

    $self->SUPER::post_configure;
}

sub post_bind_hook()
{   my $self = shift;
    my $prop = $self->{server};
    lwp_socket_init $_ for @{$prop->{sock}};
}

sub setWsdlResponse($;$)
{   my ($self, $fn, $ft) = @_;
    trace "setting wsdl response to $fn";
    lwp_wsdl_response $fn, $ft;
}

# Overrule Net::Server's log() to translate it into Log::Report calls
sub log($$@)
{   my ($self, $level, $msg) = (shift, shift, shift);
    $msg = sprintf $msg, @_ if @_;
    chomp $msg;  # some log lines have a trailing newline

    my $reason = $levelToReason[$level] or return;
    report $reason => $msg;
}

# use Log::Report for hooks
sub write_to_log_hook { panic "write_to_log_hook cannot be used" }


sub _run($)
{   my ($self, $args) = @_;
    delete $args->{log_file};      # Net::Server should not mess with my preps
    $args->{no_client_stdout} = 1; # it's a daemon, you know
    lwp_add_header Server => $self->{prop}{name};
    $self->{XCSDN_pp} = delete $args->{postprocess};

    $ISA[1]->can('run')->($self, $args);    # never returns
}

sub process_request()
{   my $self = shift;
    my $prop = $self->{server};

    # Now, our connection will become a HTTP::Daemon connection
    my $old_class  = ref $prop->{client};
    my $connection = lwp_http11_connection $self, $prop->{client};

    eval {
        lwp_handle_connection $connection
          , expires  => time() + $prop->{client_timeout}
          , maxmsgs  => $prop->{client_maxreq}
          , reqbonus => $prop->{client_reqbonus}
          , handler  => sub {$self->process(@_)}
          , postprocess => $self->{XCSDN_pp};
    };

    info __x"connection ended with force; {error}", error => $@
        if $@;

    # Our connection becomes as Net::Server::Proto::TCP again
    bless $prop->{client}, $old_class;
    1;
}

sub url() { "url replacement not yet implemented" }
sub product_tokens() { shift->{prop}{name} }

#-----------------------------


1;
