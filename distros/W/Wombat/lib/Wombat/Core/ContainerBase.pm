# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::ContainerBase;

use fields qw(children logger mapper mappers mapperClass name parent);
use fields qw(pipeline realm sessionManager started);
use strict;
use warnings;

use Servlet::Util::Exception ();
use Wombat::Exception ();
use Wombat::Core::Pipeline ();
use Wombat::Globals ();

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->{children} = {};
    $self->{logger} = undef;
    $self->{sessionManager} = undef;
    $self->{mapper} = undef;
    $self->{mappers} = {};
    $self->{mapperClass} = undef;
    $self->{name} = undef;
    $self->{parent} = undef;
    $self->{pipeline} = Wombat::Core::Pipeline->new($self);
    $self->{realm} = undef;
    $self->{started} = undef;

    return $self;
}

# accessors

sub getLogger {
    my $self = shift;

    return $self->{logger} if $self->{logger};
    return $self->{parent}->getLogger() if $self->{parent};
    return undef;
}

sub setLogger {
    my $self = shift;
    my $logger = shift;

    my $oldLogger = $self->{logger};
    return 1 if ref $oldLogger eq ref $logger;
    $self->{logger} = $logger;

    if ($self->{started} && $oldLogger) {
        $oldLogger->stop();
    }

    $self->{logger}->setContainer($self) if $self->{logger};

    if ($self->{started} && $logger) {
        $logger->start();
    }

    return 1;
}

sub getMapperClass {
    my $self = shift;

    return $self->{mapperClass};
}

sub setMapperClass {
    my $self = shift;
    my $mapperClass = shift;

    $self->{mapperClass} = $mapperClass;

    return 1;
}

sub getName {
    my $self = shift;

    return $self->{name};
}

sub setName {
    my $self = shift;
    my $name = shift;

    $self->{name} = $name;

    return 1;
}

sub getParent {
    my $self = shift;

    return $self->{parent};
}

sub setParent {
    my $self = shift;
    my $parent = shift;

    $self->{parent} = $parent;

    return 1;
}

sub getPipeline {
    my $self = shift;

    return $self->{pipeline};
}

sub getRealm {
    my $self = shift;

    return $self->{realm} if $self->{realm};
    return $self->{parent}->getRealm() if $self->{parent};
    return undef;
}

sub setRealm {
    my $self = shift;
    my $realm = shift;

    my $oldRealm = $self->{realm};
    return 1 if ref $oldRealm eq ref $realm;
    $self->{realm} = $realm;

    if ($self->{started} && $oldRealm) {
        $oldRealm->stop();
    }

    $self->{realm}->setContainer($self) if $self->{realm};

    if ($self->{started} && $realm) {
        $realm->start();
    }

    return 1;
}

sub getSessionManager {
    my $self = shift;

    return $self->{sessionManager} if $self->{sessionManager};
    return $self->{parent}->getSessionManager() if $self->{parent};
    return undef;
}

sub setSessionManager {
    my $self = shift;
    my $manager = shift;

    my $oldManager = $self->{sessionManager};
    return 1 if ref $oldManager eq ref $manager;
    $self->{sessionManager} = $manager;

    if ($self->{started} && $oldManager) {
        $oldManager->stop();
    }

    $self->{sessionManager}->setContainer($self) if $self->{sessionManager};

    if ($self->{started} && $manager) {
        $manager->start();
    }

    return 1;
}

# container methods

sub addChild {
    my $self = shift;
    my $child = shift;

    my $name = $child->getName();
    if (exists $self->{children}->{$name}) {
        my $msg = "addChild: Child name '$name' is not unique";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $child->setParent($self);

    $self->{children}->{$name} = $child;

    if ($self->{started}) {
        $child->start();
    }

    return 1;
}

sub getChild {
    my $self = shift;
    my $name = shift;

    return $self->{children}->{$name};
}

sub getChildren {
    my $self = shift;

    my @children = values %{ $self->{children} };

    return wantarray ? @children: \@children;
}

sub removeChild {
    my $self = shift;
    my $child = shift;

    delete $self->{children}->{$child->getName()};

    if ($self->{started}) {
        $child->stop();
    }

    return 1;
}

sub addMapper {
    my $self = shift;
    my $mapper = shift;

    return 1 unless $mapper;

    my $protocol = $mapper->getProtocol();
    if ($self->{mappers}->{$protocol}) {
        my $msg = "addMapper: protocol [$protocol] is not unique";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $mapper->setContainer($self);

    $self->{mappers}->{$protocol} = $mapper;
    if (keys %{ $self->{mappers} } == 1) {
        $self->{mapper} = $mapper;
    } else {
        undef $self->{mapper};
    }

    return 1;
}

sub getMapper {
    my $self = shift;
    my $protocol = shift;

    return $self->{mapper} if $self->{mapper};
    return $self->{mappers}->{$protocol};
}

sub getMappers {
    my $self = shift;

    my @mappers = values %{ $self->{mappers} };

    return wantarray ? @mappers : \@mappers;
}

sub removeMapper {
    my $self = shift;
    my $mapper = shift;

    return undef unless $mapper;

    delete $self->{mappers}->{$mapper->getProtcol()};

    return 1;
}

sub invoke {
    my $self = shift;

    $self->{pipeline}->invoke(@_);

    return 1;
}

sub map {
    my $self = shift;
    my $request = shift;

    my $mapper = $self->getMapper($request->getRequest()->getProtocol());
    return undef unless $mapper;

    return $mapper->map($request);
}

sub addValve {
    my $self = shift;

    $self->{pipeline}->addValve(@_);

    return 1;
}

sub getValves {
    my $self = shift;

    return $self->{pipeline}->getValves();
}

sub removeValve {
    my $self = shift;

    $self->{pipeline}->removeValve(@_);

    return 1;
}

# protected methods

sub addDefaultMapper {
    my $self = shift;

    return 1 unless $self->{mapperClass};
    return 1 if keys %{ $self->{mappers} };

    my $class = $self->{mapperClass};
    eval "require $class";
    unless ($@) {
        eval {
            my $mapper = $class->new();
            $mapper->setProtocol('http');
            $self->addMapper($mapper);
        };
    }
    if ($@) {
        $self->log("addDefaultMapper", $@, 'ERROR');
    }

    return 1;
}

sub handleError {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $e = shift || '';

    $self->log(undef, $e, 'ERROR') if $e;

    # XXX: if error page configured, forward to it

    # whack any previously written headers and buffer unless
    # $response->sendError() has already been called
    unless ($response->isError()) {
        eval {
            $response->reset();
        };
        if ($@) {
            # response is already committed
        }
    }

    # send default error response. for HTTP servlets, this means
    # sending an error code and a HTML page.

    if ($response->isa('Wombat::HttpResponse')) {
        eval {
            unless ($response->isError()) {
                my $status =
                    Servlet::Http::HttpServletResponse::SC_INTERNAL_SERVER_ERROR;
                $response->sendError($status);
            }

            $response->setContentType('text/html');

            my $writer = $response->getWriter();

            my $status = $response->getStatus();
            my $message = $response->getMessage();
            my $uri = $request->getRequestURI();

            $writer->print(<<EOT);
<html>
<head>
<title>$status $message</title>
</head>
<body>
<h1>$status $message</h1>
<p>
<strong>URI:</strong> $uri
</p>
<pre>
$e
</pre>
EOT

            my $root = $e->getRootCause() if
                $e && $e->isa('Servlet::ServletException');
            if ($root) {
                $writer->print(<<EOT);
<h2>Original Exception</h2>
<pre>
$root
</pre>
EOT
            }

            $writer->print(<<EOT);
</body>
</html>
EOT

            $writer->flush();
        };
        if ($@) {
            $self->log("problem writing default error page", $@);
            # response is already committed, or output exception
        };
    }

    return 1;
}

sub handleSuccess {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    # XXX: if error page configured, forward to it

    if ($response->isa('Wombat::HttpResponse')) {
        my $status = $response->getStatus();
        return 1 if $status < 200;
        return 1 if $status ==
            Servlet::Http::HttpServletResponse::SC_OK;
        return 1 if $status ==
            Servlet::Http::HttpServletResponse::SC_NOT_MODIFIED;
        return 1 if $status ==
            Servlet::Http::HttpServletResponse::SC_NO_CONTENT;

        eval {
            $response->setContentType('text/html');

            my $writer = $response->getWriter();

            my $status = $response->getStatus();
            my $message = $response->getMessage();
            my $uri = $request->getRequestURI();

            $writer->print(<<EOT);
<html>
<head>
<title>$status $message</title>
</head>
<body>
<h1>$status $message</h1>
<p>
<strong>URI:</strong> $uri
</p>
</body>
</html>
EOT

            $writer->flush();
        };
        if ($@) {
            $self->log("problem writing default success page", $@);
            # response is already committed, or output exception
        };
    }

    return 1;
}

# lifecycle methods

sub start {
    my $self = shift;

    if ($self->{started}) {
        my $msg = "start: container already started";
        Wombat::LifecycleException->throw($msg);
    }

    $self->{logger}->start() if $self->{logger};
    $self->{sessionManager}->start() if $self->{sessionManager};
    $self->{realm}->start() if $self->{realm};

    for my $child ($self->getChildren()) {
        $child->start();
    }

    $self->{pipeline}->start();

    $self->addDefaultMapper($self->{mapperClass});

    $self->{started} = 1;

    return 1;
}

sub stop {
    my $self = shift;

    unless ($self->{started}) {
        my $msg = "stop: container not started";
        Wombat::LifecycleException->throw($msg);
    }

    undef $self->{started};

    $self->{pipeline}->stop();

    for my $child ($self->getChildren()) {
        $child->stop();
    }

    $self->{realm}->stop() if $self->{realm};
    $self->{sessionManager}->stop() if $self->{sessionManager};
    $self->{logger}->stop() if $self->{logger};

    return 1;
}

# private methods

sub debug {
    my $self = shift;
    my $msg = shift;

    if (Wombat::Globals::DEBUG) {
        $self->log($msg, undef, 'DEBUG');
    }

    return 1;
  }

sub log {
    my $self = shift;
    my $error = shift || '';

    my $logger = $self->getLogger();
    $logger->log(sprintf("%s: %s", $self->logName(), $error), @_) if $logger;

    return 1;
  }

sub logName
  {
    my $self = shift;

    my $className = ref $self;
    $className =~ s/.*:://;

    return sprintf "%s[%s]", $className, ($self->getName() || '');
  }

1;
__END__
