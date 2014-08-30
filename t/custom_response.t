#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Path::Router;
use Plack::Test;
use Scalar::Util qw/ blessed /;

use Plack::App::Path::Router::Custom;

my $router = Path::Router->new;
$router->add_route('/bar' => target => sub { [ 200, [], ['BAR']] } );

my $app = Plack::App::Path::Router::Custom->new(
    router => $router,
    handle_response => sub {
        my ($res, $req) = @_;
        if (!ref($res)) {
            return [ 200, [], [$res] ];
        }
        elsif (blessed($res) && $res->can('finalize')) {
            return $res->finalize;
        }
        elsif ( $res->[0] eq 404 ) {
            $res->[2] = ['Overriden 404 message'];
            return $res;
        }
        else {
            return $res;
        }
    },
);

test_psgi
      app    => $app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/bar");
              my $res = $cb->($req);
              is($res->code, 200, '... got the expected match');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/foo");
              my $res = $cb->($req);
              is($res->code, 404, '... got the expected fail');
              is($res->content, 'Overriden 404 message', '... got the expected message');
          }
      };

done_testing;
