#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use Try::Catch;

sub _eval {
  local $@;
  local $Test::Builder::Level = $Test::Builder::Level + 2;
  return ( scalar(eval { $_[0]->(); 1 }), $@ );
}

sub throws_ok (&$$) {
  my ( $code, $regex, $desc ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my ( $ok, $error ) = _eval($code);

  if ( $ok ) {
    fail($desc);
  } else {
    like($error || '', $regex, $desc );
  }
}

throws_ok {
  catch { 2 };
} qr/\QUseless bare catch()/, 'Bare catch() detected';

throws_ok {
  finally { 2 };
} qr/\QUseless bare finally()/, 'Bare finally() detected';

throws_ok {
  catch { 2 } finally { 2 };
} qr/\QUseless bare catch()/, 'Bare catch()/finally() detected';

throws_ok {
  finally { 2 } catch { 2 };
} qr/\QUseless bare finally()/, 'Bare finally()/catch() detected';


#throws_ok {
#  try { 1 } catch { 2 } catch { 3 } finally { 4 } finally { 5 }
#} qr/\QA try() may not be followed by multiple catch() blocks/, 'Multi-catch detected';


sub foo {
  catch { 2 }
}

throws_ok {
  if (foo()) {
    # ...
  }
} qr/\QUseless bare catch/,
  'Bare catch at the end of a function call';

sub bar {
  finally { 2 }
}

throws_ok {
  if (bar()) {
    # ...
  }
} qr/\QUseless bare finally/,
  'Bare finally at the end of a function call';


throws_ok {
  try {};
} qr/\Qsyntax error after try block/,
  'Try block not followed by catch or finally block';

throws_ok {
  try {} finally {} catch {};
} qr/\Qsyntax error after finally block/,
  'Try block followed by finally block then catch block';

throws_ok {
  try {} catch {}
  {
    hi => 1
  };
} qr/\Qsyntax error after catch block/,
  'catch block not followed by a semicolon';

