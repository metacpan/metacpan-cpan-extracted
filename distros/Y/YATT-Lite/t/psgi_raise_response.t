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

use Plack::Builder;

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
  ->new(app_root => $FindBin::Bin
        , doc_root => "$rootname.d"
      );

my $client = Plack::Test->create($site->to_app);

sub action_response (&;@) {
  my ($sub, $params) = @_;

  $params //= "";

  my $URL = "/test";

  $site->mount_action($URL, $sub);

  $client->request(GET $URL.$params);
}

describe '$CON->raise_response([$code, $msg, @args...])', sub {

  describe "200 with reason as content", sub {

    my $res = action_response {
      my ($this, $con) = @_;
      $con->raise_response([200, [], ["From raise_response"]]);
    };

    it "should have code == 200", sub {
      expect($res->code)->to_be(200);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be("From raise_response");
    };
  };

  describe "404 can be raised with content", sub {

    my $res = action_response {
      my ($this, $con) = @_;
      $con->raise_response([404, [], ["Not found xxx"]]);
    };

    it "should have code == 404", sub {
      expect($res->code)->to_be(404);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be('Not found xxx');
    };
  };

};

describe '$this->raise_psgi_SOMETHING helpers', sub {
  describe '$this->raise_psgi_error', sub {
    my $res = action_response {
      my ($this, $con) = @_;
      $this->raise_psgi_error(403, "Not logged in");
    };

    it "should have code == 403", sub {
      expect($res->code)->to_be(403);
    };

    it "should have raised content", sub {
      expect($res->content)->to_be("Not logged in\n");
    };
  };

  describe '$this->raise_psgi_dump', sub {

    my $obj;
    my $res = action_response {
      my ($this, $con) = @_;
      $this->raise_psgi_dump($obj = [foo => {bar => 'baz', qux => undef}]);
    };

    it "should contain dumped items", sub {
      expect($res->content)->to_be(YATT::Lite::Util::terse_dump($obj)."\n");
    };
  };
};

describe '$CON->raise_response(sub {$streamhandler})', sub {
  #
  # Stolen (and converted for Test::Kantan) from Plack-Middleware/bufferedstreaming.t
  #

  my $URL = '/test';

  my $tester = sub {
    my ($block) = @_;
    my $sub = $block->{app};
    $site->mount_action($URL, sub {
                          my ($this, $con) = @_;
                          $con->raise_response($sub)
                        });
    my $handler = $site->wrapped_by(builder {
        enable "BufferedStreaming";
        $site->to_app;
      });

    my $res = $handler->($block->{env});

    describe "headers", sub {
      it "should be passed through", sub {
        expect($res->[1])->to_be($block->{headers});
      };
    };

    describe "body", sub {
      it "should be accumulated", sub {
        expect(join("", @{ $res->[2] }))->to_be($block->{body});
      };
    };
  };

  #========================================
  # Actual tests
  #========================================

  describe 'delayed response', sub {
    $tester->({
               app => sub {
                 $_[0]->([ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ]);
               },
               env => { REQUEST_METHOD => 'GET', PATH_INFO => $URL },
               headers => [ 'Content-Type' => 'text/plain' ],
               body => 'OK',
             });
  };

  describe 'responder->write()', sub {
    $tester->({
        app => sub {
          my $writer = $_[0]->([ 200, [ 'Content-Type' => 'text/plain' ]]);
          $writer->write("O");
          $writer->write("K");
          $writer->close();
        },
        env => { REQUEST_METHOD => 'GET', PATH_INFO => $URL },
        headers => [ 'Content-Type', 'text/plain' ],
        body => 'OK',
      });
  };
};

done_testing();
