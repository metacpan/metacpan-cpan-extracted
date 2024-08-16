#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::Kantan;
use YATT::t::t_preload; # To make Devel::Cover happy.
use YATT::Lite::WebMVC0::SiteApp;


BEGIN {
  foreach my $req (qw(Plack Plack::Test Plack::Response HTTP::Request::Common)) {
    unless (eval qq{require $req;}) {
      diag("$req is not installed.");
      skip_all();
    }
    $req->import;
  }
}


my $rootname = untaint_any($FindBin::Bin."/psgi");

my $site = YATT::Lite::WebMVC0::SiteApp
  ->new(  app_root => $FindBin::Bin
	  , doc_root => "$rootname.d"
	  # Below is required (currently) to decode input parameters.
	  , header_charset => 'utf-8'
	  , tmpl_encoding => 'utf-8'
	  , output_encoding => 'utf-8'
      );
my $app = $site->to_app;

my $client = Plack::Test->create($app);

sub action_response (&;@) {
  my ($sub, $params) = @_;

  $params //= "";

  my $URL = "/test";

  $site->mount_action($URL, $sub);

  $client->request(GET $URL.$params);
}

describe 'To preload CGen class', sub {
  my $res = $client->request(GET "/empty");

  it "should have code == 200", sub {
    expect($res->code)->to_be(200);
  };

  it "should contain Hello World", sub {
    expect($res->content)->to_match(qr/Hello World/);
  };
};

describe '$CON->error_with_status($code, $msg, @args...)', sub {

  describe "200 with reason as content", sub {

    my $res = action_response {
      my ($this, $con) = @_;
      $con->error_with_status(200, "From error");
    };

    it "should have code == 200", sub {
      expect($res->code)->to_be(200);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be("From error");
    };
  };

  describe "200 with default reason", sub {

    my $res = action_response {
      my ($this, $con) = @_;
      $con->error_with_status(200);
    };

    it "should have code == 200", sub {
      expect($res->code)->to_be(200);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be('Unknown reason!');
    };
  };

  describe "404 can be raised with content", sub {

    my $res = action_response {
      my ($this, $con) = @_;
      $con->error_with_status(404, "Not found xxx");
    };

    it "should have code == 404", sub {
      expect($res->code)->to_be(404);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be('Not found xxx');
    };
  };
};

describe '$dirapp->error_with_status($code, $msg, @args...)', sub {
  describe "200 with reason as content", sub {

    my $res = action_response {
      my ($this, $con) = @_;
      $this->YATT->error_with_status(200, "From error");
    };

    it "should have code == 200", sub {
      expect($res->code)->to_be(200);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be("From error");
    };
  };

  describe "200 with default reason", sub {

    my $res = action_response {
      my ($this, $con) = @_;
      $this->YATT->error_with_status(200);
    };

    it "should have code == 200", sub {
      expect($res->code)->to_be(200);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be('Unknown reason!');
    };
  };

  describe "404 can be raised with content", sub {

    my $res = action_response {
      my ($this, $con) = @_;
      $this->YATT->error_with_status(404, "Not found xxx");
    };

    it "should have code == 404", sub {
      expect($res->code)->to_be(404);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be('Not found xxx');
    };
  };
};

describe '$site->error_with_status($code, $msg, @args...)', sub {
  describe "200 with reason as content", sub {

    my $res = action_response {
      $site->error_with_status(200, "From error");
    };

    it "should have code == 200", sub {
      expect($res->code)->to_be(200);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be("From error");
    };
  };

  describe "200 with default reason", sub {

    my $res = action_response {
      $site->error_with_status(200);
    };

    it "should have code == 200", sub {
      expect($res->code)->to_be(200);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be('Unknown reason!');
    };
  };

  describe "404 can be raised with content", sub {

    my $res = action_response {
      $site->error_with_status(404, "Not found xxx");
    };

    it "should have code == 404", sub {
      expect($res->code)->to_be(404);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be('Not found xxx');
    };
  };
};

describe "Request errors", sub {

  describe "YATT::Lite::Partial::AppPath (might be deprecated though)", sub {

    describe "->app_path(unknown)", sub {
      my $res = action_response {
	shift->YATT->app_path("/should_not_found");
      };

      it "should return code == 404", sub {
	expect($res->code)->to_be(404);
      };
    };
  };

  describe "CON->param_type(name,typename,diag,opts)", sub {

    describe "When specified parameter is missing, response", sub {

      my $res = action_response {
	my ($this, $con) = @_;
	$con->param_type(foo => 'name');
      };

      it "should have 400 Bad Request", sub {
	expect($res->code)->to_be(400);
      };
      it "should have diag message", sub {
	expect($res->content)->to_be(q{Parameter 'foo' is missing!});
      };
    };

    describe "When the parameter doesn't match specified regexp", sub {

      my $res = action_response {
	my ($this, $con) = @_;
	$con->param_type(foo => 'name');
      } "?foo=a-b";

      it "should have 400 Bad Request", sub {
	expect($res->code)->to_be(400);
      };
      it "should have diag message", sub {
	expect($res->content)->to_be(q{Parameter 'foo' must match name!: 'a-b'});
      };
    };
  };
};

describe "General internal server errors", sub {

  describe "use of undef", sub {

    my $res = action_response { my $foo; $foo * $foo };

    it "should have code == 500", sub {
      expect($res->code)->to_be(500);
    };

    it "should have diag content", sub {
      expect($res->content)->to_match(qr/^Use of uninitialized/);
    };
  };
};

describe "Same with overwrite_status_code_for_errors_as => 200", sub {

  $site->get_yatt('/')->configure(overwrite_status_code_for_errors_as => 200);

  describe "use of undef", sub {

    my $res = action_response { my $foo; $foo * $foo };

    it "should have code == 200", sub {
      expect($res->code)->to_be(200);
    };

    it "should have diag content", sub {
      expect($res->content)->to_match(qr/^Use of uninitialized/);
    };
  };
};

done_testing();
