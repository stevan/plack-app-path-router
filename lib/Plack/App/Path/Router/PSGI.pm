package Plack::App::Path::Router::PSGI;
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

sub call {
    my ($self, $env) = @_;

    $env->{'plack.router'} = $self->router;

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
            }
        }

        $env->{ 'plack.router.match.args' } = \@args;

        my $target = $match->target;

        return blessed $target && $target->can('to_app')
             ? $target->to_app->( $env )
             : $target->( $env );
    }

    return [ 404, [ 'Content-Type' => 'text/html' ], [ 'Not Found' ] ];
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Plack::App::Path::Router::PSGI - A Plack component for dispatching with Path::Router to Pure PSGI targets

=head1 SYNOPSIS

  use Plack::App::Path::Router::PSGI;
  use Path::Router;

  my $router = Path::Router->new;
  $router->add_route('/' =>
      target => sub {
          my $env  = shift;
          [
            200,
            [ 'Content-Type' => 'text/html' ],
            [ '<html><body>Home</body></html>' ]
          ]
      }
  );
  $router->add_route('/:action/?:id' =>
      validations => {
          id => 'Int'
      },
      target => sub {
          my $env = shift;
          # matches are passed through the $env
          my ($action, $id) = @{ $env->{'plack.router.match.args'} };
          [
            200,
            [ 'Content-Type' => 'text/html' ],
            [ '<html><body>', $action, $id, '</body></html>' ]
          ]
      }
  );
  $router->add_route('admin/:action/?:id' =>
      validations => {
          id => 'Int'
      },
      # targets are just PSGI apps, so you can
      # wrap with middleware as needed ...
      target => Plack::Middleware::Auth::Basic->wrap(
          sub {
              my $env = shift;
              # matches are passed through the $env
              my ($action, $id) = @{ $env->{'plack.router.match.args'} };
              [
                200,
                [ 'Content-Type' => 'text/html' ],
                [ '<html><body>', $action, $id, '</body></html>' ]
              ]
          },
          authenticator => sub {
              my ($username, $password) = @_;
              return $username eq 'admin' && $password eq 's3cr3t';
          }
      )
  );

  # now create the Plack app
  my $app = Plack::App::Path::Router::PSGI->new( router => $router );

=head1 DESCRIPTION

This is a L<Plack::Component> subclass which creates an endpoint to dispatch
using L<Path::Router>.

This module is similar to L<Plack::App::Path::Router> except that it expects
all the route targets to be pure PSGI apps, nothing more, nothing less. Which
means that they will accept a single C<$env> argument and return a valid
PSGI formatted response.

This will place, into the C<$env> the router instance into 'plack.router',
any valid match in 'plack.router.match' and the collected URL match args in
'plack.router.match.args'.

This thing is dead simple, if my docs don't make sense, then just read the
source (all ~45 lines of it).

=head1 ATTRIBUTES

=over 4

=item I<router>

This is a required attribute and must be an instance of L<Path::Router>.

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
