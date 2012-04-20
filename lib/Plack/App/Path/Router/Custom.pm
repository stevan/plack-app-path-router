package Plack::App::Path::Router::Custom;
use Moose;
use MooseX::NonMoose;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

extends 'Plack::Component';

has 'router' => (
    is       => 'ro',
    isa      => 'Path::Router',
    required => 1,
);

has new_request => (
    traits  => ['Code'],
    isa     => 'CodeRef',
    default => sub { sub { $_[0] } },
    handles => {
        new_request => 'execute',
    },
);

has target_to_app => (
    traits  => ['Code'],
    isa     => 'CodeRef',
    default => sub { sub { $_[0] } },
    handles => {
        target_to_app => 'execute',
    },
);

has handle_response => (
    traits  => ['Code'],
    isa     => 'CodeRef',
    default => sub { sub { $_[0] } },
    handles => {
        handle_response => 'execute',
    },
);

sub call {
    my ($self, $env) = @_;

    $env->{'plack.router'} = $self->router;

    my $req = $self->new_request( $env );

    my $match = $self->router->match( $env->{PATH_INFO} );

    if ( $match ) {
        $env->{'plack.router.match'} = $match;

        my $route   = $match->route;
        my $mapping = $match->mapping;

        my @args;
        foreach my $component ( @{ $route->components } ) {
            my $name = $route->get_component_name( $component );
            next unless $name;
            if (my $value = $mapping->{ $name }) {
                push @args => $value;
                $env->{ ('plack.router.match.args.' . $name) } = $value;
            }
        }

        $env->{ 'plack.router.match.args' } = \@args;

        my $target = $match->target;
        my $app = $self->target_to_app( $target );
        my $res = $app->( $req, @args );

        return $self->handle_response( $res, $req );
    }

    return [ 404, [ 'Content-Type' => 'text/html' ], [ 'Not Found' ] ];
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Plack::App::Path::Router::Custom - A Plack component for dispatching with Path::Router

=head1 SYNOPSIS

  use Plack::App::Path::Router::Custom;
  use Path::Router;

  my $router = Path::Router->new;
  $router->add_route('/' =>
      target => sub {
          my ($request) = @_;
          # use the Plack::Request to
          # create a Plack::Response ...
          my $response = $request->new_response( 200 );
          $response->content_type('text/html');
          $response->body('<html><body>HELLO WORLD</body></html>');
      }
  );
  $router->add_route('/:action/?:id' =>
      validations => {
          id => 'Int'
      },
      target => sub {
          # matches are passed to the target sub ...
          my ($request, $action, $id) = @_;
          # return a PSGI response ...
          [
            200,
            [ 'Content-Type' => 'text/html' ],
            [ '<html><body>', $action, $id, '</body></html>' ]
          ]
      }
  );
  $router->add_route('/:action/edit/:id' =>
      validations => {
          id => 'Int'
      },
      target => sub {
          my ($r, $action, $id) = @_;
          # return a string (we will wrap
          # it in a PSGI response for you)
          "This is my action($action), and I am editing this id($id)";
      }
  );
  $router->add_route('/foo' =>
      # target objects are also supported
      # as long as the object responds to
      # the ->execute method
      target => MyApp::Action->new( type => 'FOO' )
  );

  # now create the Plack app
  my $app = Plack::App::Path::Router::Custom->new(
      router => $router,
      new_request => sub {
          my ($env) = @_;
          Plack::Request->new($env)
      },
      target_to_app => sub {
          my ($target) = @_;
          blessed($target) && $target->can('execute')
              ? sub { $target->execute(@_) }
              : $target
      },
      handle_response => sub {
          my ($res, $req) = @_;
          if (!ref($res)) {
              return [ 200, [], [$res] ];
          }
          elsif (blessed($res) && $res->can('finalize')) {
              return $res->finalize;
          }
          else {
              return $res;
          }
      },
  );

=head1 DESCRIPTION

This is a L<Plack::Component> subclass which creates an endpoint to dispatch
using L<Path::Router>.

It is useful when you need a bit more control than is provided by
L<Plack::App::Path::Router> or L<Plack::App::Path::Router::PSGI> (those two
modules are in fact written in terms of this one). It provides hooks to
manipulate how the PSGI env is turned into a request object, how the target is
turned into a coderef which accepts a request and returns a response, and how
that response is turned back into a valid PSGI response.

By default, the target must be a coderef which accepts a valid PSGI env and
returns a valid PSGI response.

=head1 ATTRIBUTES

=over 4

=item I<router>

This is a required attribute and must be an instance of L<Path::Router>.

=item I<new_request>

Coderef which takes a PSGI env and returns a request object of some sort.
Defaults to just returning the env.

=item I<target_to_app>

Coderef which takes the target provided by the matched path and returns a
coderef which takes a request (as provided by C<new_request>) and the match
arguments, and returns something that C<handle_response> can turn into a PSGI
response. Defaults to just returning the target.

=item I<handle_response>

Coderef which takes the response and request and returns a valid PSGI response.
Defaults to just returning the given response.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
