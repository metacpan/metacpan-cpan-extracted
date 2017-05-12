#!/bin/bash

. `dirname $0`/sdbs.inc

# iam-mailserver-interface
for module in \
  XML::Compile::WSDL11 \
  XML::Compile::SOAP11 \
  XML::Compile::Transport::SOAPHTTP \
  Net::HTTP \
  Mojolicious \
  LWP::Protocol::https \
  IO::Socket::SSL \
  HTTP::CookieJar \
; do
  perlmodule $module
done

        
