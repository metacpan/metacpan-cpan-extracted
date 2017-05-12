# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::Application;

use base qw(Servlet::ServletContext Wombat::Core::ContainerBase);
use fields qw(available docBase basePath constraints displayName facade);
use fields qw(loginConfig servletMappings sessionTimeout);
use fields qw(attributes initParameters sessionCookie);
use strict;
use warnings;

use File::Spec ();
use Servlet::Util::Exception ();
use URI ();
use URI::Escape ();
use Wombat::Core::ApplicationFacade ();
use Wombat::Core::ApplicationValve ();
use Wombat::Core::RequestDispatcher ();
use Wombat::Core::Wrapper ();
use Wombat::Deploy::LoginConfig ();
use Wombat::Exception ();
use Wombat::Util::XmlMapper ();

use constant DESCRIPTOR => '/WEB-INF/web.xml';
use constant AUTHENTICATORS => {
                                'BASIC' =>
                                'Wombat::Authenticator::BasicAuthenticator',
                               };

sub new {
    my $class = shift;

    my $self = fields::new($class);
    $self->SUPER::new();

    # internal application fields
    $self->{available} = undef;
    $self->{constraints} = [];
    $self->{displayName} = undef;
    $self->{facade} = Wombat::Core::ApplicationFacade->new($self);
    $self->{loginConfig} = undef;
    $self->{servletMappings} = {};
    $self->{sessionTimeout} = 30; # minutes

    # Servlet::ServletContext fields
    $self->{attributes} = {};
    $self->{initParameters} = {};
    $self->{sessionCookie} = 1;

    $self->{mapperClass} = 'Wombat::Core::ApplicationMapper';
    $self->{pipeline}->setBasic(Wombat::Core::ApplicationValve->new());

    return $self;
}

# accessors

sub getAvailable {
    my $self = shift;

    return $self->{available};
}

sub setAvailable {
    my $self = shift;
    my $flag = shift;

    $self->{available} = $flag;

    return 1;
}

sub getAttribute {
    my $self = shift;
    my $name = shift;

    return $self->{attributes}->{$name};
}

sub getAttributeNames {
    my $self = shift;

    my @attributes = keys %{ $self->{attributes} };

    return wantarray ? @attributes : \@attributes;
}

sub removeAttribute {
    my $self = shift;
    my $name = shift;

    delete $self->{attributes}->{$name};

    return 1;
}

sub setAttribute {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{attributes}->{$name} = $value;

    return 1;
}

sub addConstraint {
    my $self = shift;
    my $constraint = shift;

    # validate the proposed constraint
    for my $collection ($constraint->getCollections()) {
        for my $pattern ($collection->getPatterns()) {
            unless ($self->validateURLPattern($pattern)) {
                    my $msg = "addConstraint: invalid pattern [$pattern]";
                    Servlet::Util::IllegalArgumentException->throw($msg);
            }
        }
    }

    push @{ $self->{constraints} }, $constraint;

    return 1;
}

sub getConstraints {
    my $self = shift;

    my @constraints = @{ $self->{constraints} };

    return wantarray ? @constraints : \@constraints;
}

sub removeConstraint {
    my $self = shift;
    my $constraint = shift;

    my $n;
    for (my $i=0; $i< @{ $self->{constraints} }; $i++) {
        if (ref $constraint eq ref $self->{constraints}->[$i]) {
            $n = $i;
            last;
        }
    }

    splice @{ $self->{constraints} }, $n, 1 if defined $n;

    return 1;
}

sub getDisplayName {
    my $self = shift;

    return $self->{displayName};
}

sub setDisplayName {
    my $self = shift;
    my $displayName = shift;

    $self->{displayName} = $displayName;

    return 1;
}

sub getDocBase {
    my $self = shift;

    return $self->{docBase};
}

sub setDocBase {
    my $self = shift;
    my $docBase = shift;

    $self->{docBase} = $docBase;

    return 1;
}

sub addInitParameter {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->{initParameters}->{$name} = $value;

    return 1;
}

sub getInitParameter {
    my $self = shift;
    my $name = shift;

    return $self->{initParameters}->{$name};
}

sub getInitParameterNames {
    my $self = shift;

    my @initParameters = keys %{ $self->{initParameters} };

    return wantarray ? @initParameters : \@initParameters;
}

sub removeInitParameter {
    my $self = shift;
    my $name = shift;

    delete $self->{initParameters}->{$name};

    return 1;
}

sub getLoginConfig {
    my $self = shift;

    return $self->{loginConfig};
}

sub setLoginConfig {
    my $self = shift;
    my $config = shift;

    unless ($config) {
        my $msg = "setLoginConfig: login config required";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    my $loginPage = $config->getLoginPage();
    if ($loginPage && $loginPage !~ m|^/|) {
        my $msg = "setLoginConfig: login page must be relative to context";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    my $errorPage = $config->getErrorPage();
    if ($errorPage && $errorPage !~ m|^/|) {
        my $msg = "setLoginConfig: error page must be relative to context";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $self->{loginConfig} = $config;

    return 1;
}

sub getPath {
    my $self = shift;

    return $self->getName();
}

sub setPath {
    my $self = shift;
    my $path = shift;

    $self->setName(URI::Escape::uri_unescape($path));

    return 1;
}

sub addServletMapping {
    my $self = shift;
    my $pattern = shift;
    my $name = shift;

    unless ($self->getChild($name)) {
        my $msg = "servletMapping: servlet not defined [$name]";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $pattern = URI::Escape::uri_unescape($pattern);
    unless ($self->validateURLPattern($pattern)) {
        my $msg = "servletMapping: invalid pattern [$pattern]";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $self->{servletMappings}->{$pattern} = $name;

    return 1;
}

sub getServletMapping {
    my $self = shift;
    my $pattern = shift;

    return $self->{servletMappings}->{$pattern};
}

sub getServletMappingNames {
    my $self = shift;

    my @servletMappings = keys %{ $self->{servletMappings} };

    return wantarray ? @servletMappings : \@servletMappings;
}

sub removeServletMapping {
    my $self = shift;
    my $pattern = shift;

    delete $self->{servletMappings}->{$pattern};

    return 1;
}

sub isSessionCookie {
    my $self = shift;

    return $self->{sessionCookie};
}

sub setSessionCookie {
    my $self = shift;
    my $flag = shift;

    $self->{sessionCookie} = $flag;

    return 1;
}

sub getSessionTimeout {
    my $self = shift;

    return $self->{sessionTimeout};
}

sub setSessionTimeout {
    my $self = shift;
    my $timeout = shift;

    $self->{sessionTimeout} = $timeout;

    return 1;
}

# public methods

sub addChild {
    my $self = shift;
    my $child = shift;

    unless ($child->isa('Wombat::Core::Wrapper')) {
        my $msg = "addChild: child container must be Wrapper";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    $self->SUPER::addChild($child);

    return 1;
}

sub createWrapper {
    my $self = shift;

    my $wrapper = Wombat::Core::Wrapper->new();

    return $wrapper;
}

sub getServletContext {
    my $self = shift;

    return $self->{facade};
}

sub toString {
    my $self = shift;

    my $parent = $self->getParent();
    my $str = sprintf "Application[%s]", $self->getName();
    $str = sprintf "%s.%s", $parent->toString(), $str if $parent;

    return $str;
}

# Servlet::ServletContext methods

sub getRealPath {
    my $self = shift;
    my $path = shift;

    return undef unless $path;

    return File::Spec->canonpath(File::Spec->catfile($self->getBasePath(),
                                                     $path));
}

sub getRequestDispatcher {
    my $self = shift;
    my $path = shift;

    return undef unless $path;

    unless ($path =~ m|^/|) {
        my $msg = "getRequestDispatcher: path must be context-relative";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    my $contextPath = $self->getPath() || '';
    my ($relativeURI, $queryString) = split /\?/, $path, 2;

    # make a fake request in order to map the wrapper
    my $request = Wombat::Connector::HttpRequestBase->new();
    $request->setApplication($self);
    $request->setContextPath($contextPath || undef);
    $request->setRequestURI(join '', $contextPath, $relativeURI);
    $request->setQueryString($queryString);

    my $wrapper = $self->map($request);
    return undef unless $wrapper;

    return Wombat::Core::RequestDispatcher->new($wrapper);
}

sub getResourceAsHandle {
    my $self = shift;
    my $path = shift;

    # XXX: in java, resources are bound to a JNDI naming context. we
    # don't want to be that sophisticated/complex for now. so assume
    # that all resources refer to files in the local filesystem.

    my $loc = $self->getRealPath($path);
    return undef unless $loc;

    my $fh = IO::File->new($loc);

    Wombat::Globals::DEBUG && !$fh &&
        $self->debug("can't find resource for $path [$loc]: $!");

    return $fh;
}

# lifecycle methods

sub start {
    my $self = shift;

    $self->setAvailable(undef);

    $self->SUPER::start();
    undef $self->{started};

    # configure application from deployment descriptor
    $self->applicationConfig();

    # configure an authenticator if necessary
    $self->authenticatorConfig();

    # apply session timeout override
    my $manager = $self->getSessionManager();
    $manager->setMaxInactiveInterval($self->{sessionTimeout} * 60) if $manager;

    # XXX: set up welcome files

    # add /WEB-INF/lib to @INC so application-specific classes can be found
    # XXX: application-specific classloaders sure would be nice!
    my $libdir = File::Spec->catdir($self->getBasePath(), 'WEB-INF', 'lib');
    unshift @INC, $libdir;

    # XXX: load servlets as specified by "loadOnStartup"

    $self->{started} = 1;
    $self->setAvailable(1);

    return 1;
}

sub stop {
    my $self = shift;

    $self->setAvailable(undef);
    $self->SUPER::stop();

    return 1;
}

# private methods

sub applicationConfig {
    my $self = shift;

    my $fh = $self->getResourceAsHandle(DESCRIPTOR);
    unless ($fh) {
        my $msg = sprintf("start: can't find deployment descriptor for %s",
                          $self->getName());
        Wombat::LifecycleException->throw($msg);
    }

    my $mapper = Wombat::Util::XmlMapper->new();
    $self->createRules($mapper);
    $mapper->readXml($fh, $self);
    $fh->close();

    return 1;
}

sub getBasePath {
    my $self = shift;

    return $self->{basePath} if $self->{basePath};

    if (File::Spec->file_name_is_absolute($self->{docBase})) {
        $self->{basePath} = $self->{docBase};
        return $self->{basePath};
    }

    # find host parent app base
    my $appBase;
    my $container = $self;
    while ($container = $container->getParent()) {
        if ($container->isa('Wombat::Core::Host')) {
            $appBase = $container->getAppBase();
            last;
        }
    }

    # XXX: if there's no host parent, use the server home
    $appBase ||= $ENV{WOMBAT_HOME};

    $self->{basePath} = File::Spec->rel2abs($self->{docBase}, $appBase);
    return $self->{basePath};
}

sub validateURLPattern {
    my $self = shift;
    my $pattern = shift;

    return undef unless defined $pattern;

    # if the pattern starts with "*." it may not contain "/"
    return $pattern !~ m|/| if $pattern =~ m|^\*\.|;

    # the pattern must start with "/"
    return $pattern =~ m|^/|;
}

sub createRules {
    my $self = shift;
    my $mapper = shift;

    # init parameters
    $mapper->addRule("web-app/context-param",
                     $mapper->methodSetter('addInitParameter', 2));
    $mapper->addRule("web-app/context-param/param-name",
                     $mapper->methodParam(0));
    $mapper->addRule("web-app/context-param/param-value",
                     $mapper->methodParam(1));

    # display name
    $mapper->addRule("web-app/display-name",
                     $mapper->methodSetter('setDisplayName', 0));

    # login config
    $mapper->addRule("web-app/login-config",
                     $mapper->objectCreate("Wombat::Deploy::LoginConfig"));
    $mapper->addRule("web-app/login-config",
                     $mapper->addChild("setLoginConfig"));
    $mapper->addRule("web-app/login-config/auth-method",
                     $mapper->methodSetter('setAuthMethod', 0));
    $mapper->addRule("web-app/login-config/realm-name",
                     $mapper->methodSetter('setRealmName', 0));
    $mapper->addRule("web-app/login-config/form-login-config/form-login-page",
                     $mapper->methodSetter('setLoginPage', 0));
    $mapper->addRule("web-app/login-config/form-login-config/form-error-page",
                     $mapper->methodSetter('setErrorPage', 0));

    # security constraints
    $mapper->addRule("web-app/security-constraint",
                     $mapper->objectCreate("Wombat::Deploy::SecurityConstraint"));
    $mapper->addRule("web-app/security-constraint",
                     $mapper->addChild("addConstraint"));
    $mapper->addRule("web-app/security-constraint/auth-constraint",
                     Wombat::Util::XmlMapper::SetAuthConstraintAction->new());
    $mapper->addRule("web-app/security-constraint/auth-constraint/role-name",
                     $mapper->methodSetter('addAuthRole', 0));
    $mapper->addRule("web-app/security-constraint/display-name",
                     $mapper->methodSetter('setDisplayName', 0));
    $mapper->addRule("web-app/security-constraint/user-data-constraint/transport-guarantee",
                     $mapper->methodSetter('setUserConstraint', 0));
    $mapper->addRule("web-app/security-constraint/web-resource-collection",
                     $mapper->objectCreate("Wombat::Deploy::SecurityCollection"));
    $mapper->addRule("web-app/security-constraint/web-resource-collection",
                     $mapper->addChild("addCollection"));
    $mapper->addRule("web-app/security-constraint/web-resource-collection/http-method",
                     $mapper->methodSetter('addMethod', 0));
    $mapper->addRule("web-app/security-constraint/web-resource-collection/url-pattern",
                     $mapper->methodSetter('addPattern', 0));
    $mapper->addRule("web-app/security-constraint/web-resource-collection/web-resource-name",
                     $mapper->methodSetter('setName', 0));

    # servlets
    $mapper->addRule("web-app/servlet",
                     Wombat::Util::XmlMapper::WrapperCreateAction->new("Wombat::Core::Wrapper"));
    $mapper->addRule("web-app/servlet",
                     $mapper->addChild("addChild"));
    $mapper->addRule("web-app/servlet/init-param",
                     $mapper->methodSetter('addInitParameter', 2));
    $mapper->addRule("web-app/servlet/init-param/param-name",
                     $mapper->methodParam(0));
    $mapper->addRule("web-app/servlet/init-param/param-value",
                     $mapper->methodParam(1));
    $mapper->addRule("web-app/servlet/load-on-startup",
                     $mapper->methodSetter('setLoadOnStartup', 0));
    $mapper->addRule("web-app/servlet/run-as/role-name",
                     $mapper->methodSetter('setRunAs', 0));
    $mapper->addRule("web-app/servlet/security-role-ref",
                     $mapper->methodSetter('addSecurityReference', 2));
    $mapper->addRule("web-app/servlet/security-role-ref/role-name",
                     $mapper->methodParam(0));
    $mapper->addRule("web-app/servlet/security-role-ref/role-link",
                     $mapper->methodParam(1));
    $mapper->addRule("web-app/servlet/servlet-class",
                     $mapper->methodSetter('setServletClass', 0));
    $mapper->addRule("web-app/servlet/servlet-name",
                     $mapper->methodSetter('setName', 0));

    # servlet mappings
    $mapper->addRule("web-app/servlet-mapping",
                     $mapper->methodSetter('addServletMapping', 2));
    $mapper->addRule("web-app/servlet-mapping/url-pattern",
                     $mapper->methodParam(0));
    $mapper->addRule("web-app/servlet-mapping/servlet-name",
                     $mapper->methodParam(1));

    # session config
    $mapper->addRule("web-app/session-config",
                     $mapper->methodSetter('setSessionTimeout', 1));
    $mapper->addRule("web-app/session-config/session-timeout",
                     $mapper->methodParam(0));

    return 1;
}

sub authenticatorConfig {
    my $self = shift;

    # make sure the application requires an authenticator
    my $constraints = $self->getConstraints();
    return 1 unless @$constraints;

    my $loginConfig = $self->getLoginConfig();
    unless ($loginConfig) {
        $self->setLoginConfig(Wombat::Deploy::LoginConfig->new('NONE'));
    }

    # make sure one hasn't already been configured
    if ($self->{pipeline}) {
        my $basic = $self->{pipeline}->getBasic();
        return 1 if $basic && $basic->isa('Wombat::Authenticator');

        for my $valve ($self->{pipeline}->getValves()) {
            return 1 if $valve->isa('Wombat::Authenticator');
        }
    }

    # make sure a realm has been configured
    unless ($self->getRealm()) {
        $self->log("security constraints configured without realm",
                  undef, 'ERROR');
        return 1;
    }

    my $authMethod = $loginConfig->getAuthMethod();
    my $class = AUTHENTICATORS->{$authMethod};
    unless ($class) {
        $self->log("no authenticator for auth method [$authMethod]",
                   undef, 'ERROR');
        return 1;
    }

    eval "require $class";
    if ($@) {
        $self->log("could not load authenticator $class", $@, 'ERROR');
        return 1;
    }

    my $authenticator = eval { $class->new() };
    if ($@) {
        $self->log("could not instantiate authenticator $class", $@, 'ERROR');
        return 1;
    }

    $self->{pipeline}->addValve($authenticator);

    return 1;
}

package Wombat::Util::XmlMapper::SetAuthConstraintAction;

use base qw(Wombat::Util::XmlAction);
use fields qw();

sub start {
    my $self = shift;
    my $mapper = shift;

    my $top = @{ $mapper->{objects} } - 1;
    my $obj = $mapper->{objects}->[$top];
    return 1 unless $obj;

    $obj->setAuthConstraint(1);

    return 1;
}

package Wombat::Util::XmlMapper::WrapperCreateAction;

use base qw(Wombat::Util::XmlMapper::ObjectCreateAction);
use fields qw();

sub start {
    my $self = shift;
    my $mapper = shift;

    $self->SUPER::start($mapper, @_);

    my $top = @{ $mapper->{objects} } - 1;
    my $wrapper = $mapper->{objects}->[$top];
    return 1 unless $wrapper;

    $wrapper->start();

    return 1;
}

1;
__END__
