package APR::Request::Magic;
require base;
our $VERSION = "2.15";
my $ctx;
eval { local $ENV{PERL_DL_NONLAZY} = 1; require APR::Request::Apache2; };
if ($@) {
    require APR::Pool;
    base->import("APR::Request::CGI");
    *handle = sub { $ctx ||= bless APR::Pool->new; APR::Request::CGI->handle($ctx, @_) };
    our $MODE = "CGI";
}
else {
    require Apache2::RequestUtil;
    base->import("APR::Request::Apache2");
    *handle = sub { APR::Request::Apache2->handle(Apache2::RequestUtil->request, @_) };
    our $MODE = "Apache2";
}

1;

__END__

=head1 NAME

APR::Request::Magic - Portable API for working with CGI and modperl scripting




=head1 SYNOPSIS

    # Be sure PerlOptions +GlobalRequest is set for mp2.

    use APR::Request::Magic;
    $apreq = APR::Request::Magic->handle;
    @foo   = $apreq->body("foo");
    $bar   = $apreq->args("bar");
    $c     = $apreq->jar("cookiename");




=head1 DESCRIPTION

The APR::Request::Magic module provides a cgi/mod_perl portable interface
to libapreq2.  It is a subclass of APR::Request so all of its methods are
available.




=head1 APR::Request::Magic




=head2 handle

    APR::Request::Magic->handle()

Creates a new APR::Request::Magic object.



=head2 $MODE

Global variable set to the operation mode of this module: either "CGI" or "Apache2".




=head1 SEE ALSO

L<APR::Request>, L<APR::Request::CGI>, L<APR::Request::Apache2>.




=head1 COPYRIGHT

  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
