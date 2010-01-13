package Plack::App::Path::Router;
use Moose;
use MooseX::NonMoose;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use Plack::Request;

extends 'Plack::Component';

has 'router' => (
    is       => 'ro',
    isa      => 'Path::Router',
    required => 1,
);

has 'request_class' => (
    is      => 'ro',
    isa     => 'ClassName',
    default => sub { 'Plack::Request' },
);

sub call {
    my($self, $env) = @_;

    $env->{'plack.router'} = $self->router;

    my $req = $self->request_class->new( $env );

    my $match = $self->router->match( $req->path_info );

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
                $env->{ ('plack.router.match.' . $name) } = $value;
            }
        }

        my $target = $match->target;

        my $res;
        if (blessed $target && $target->can('execute')) {
            $res = $target->execute( $req, @args );
        }
        else {
            $res = $target->( $req, @args );
        }

        if ( blessed $res && $res->can('finalize') ) {
            return $res->finalize;
        }
        elsif ( not ref $res ) {
            return [ 200, [ 'Content-Type' => 'text/html' ], [ $res ] ];
        }
        else {
            return $res;
        }
    }

    return [ 404, [ 'Content-Type' => 'text/html' ], [ 'Not Found' ] ];
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Plack::App::Path::Router - A Plack component for dispatching with Path::Router

=head1 SYNOPSIS

  use Plack::App::Path::Router;
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
  my $app = Plack::App::Path::Router->new( router => $router );

=head1 DESCRIPTION

This is a L<Plack::Component> subclass which creates an endpoint to dispatch
using L<Path::Router>.

This module expects an instance of L<Path::Router> whose routes all have a
C<target> that is a CODE ref or an object which responds to the C<execute>
method. The CODE ref or C<execute> method will be called when a match is
found and passed a L<Plack::Request> instance followed by any path captures
that were found. It is expected that the target return one of the following;
an object which responds to the C<finalize> method (like L<Plack::Response>),
a properly formed PSGI response or a plain string (which we will wrap inside
a PSGI response with a status of 200 and a content type of "text/html").

This thing is dead simple, if my docs don't make sense, then just read the
source (all ~75 lines of it).

=head1 ATTRIBUTES

=over 4

=item I<router>

This is a required attribute and must be an instance of L<Path::Router>.

=item I<request_class>

This is a class name used to create the request object. It defaults to
L<Plack::Request> but anything that will accept a PSGI-style C<$env> in
the constructor and respond correctly to C<path_info> will work.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
