package Plack::App::Path::Router;
use Moose;
use MooseX::NonMoose;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Plack::Request;

extends 'Plack::Component';

has 'router' => (
    is       => 'ro',
    isa      => 'Path::Router',
    required => 1,
);

sub call {
    my($self, $env) = @_;

    $env->{'router'} = $self->router;

    my $req = Plack::Request->new( $env );

    my $match = $self->router->match( $req->path );

    if ( $match ) {
        $env->{'router.match'} = $match;

        my $route   = $match->route;
        my $mapping = $match->mapping;

        my @args;
        foreach my $component ( @{ $route->components } ) {
            my $name = $route->get_component_name( $component );
            next unless $name;
            if (my $value = $mapping->{ $name }) {
                push @args => $value;
                $env->{ ('router.match.' . $name) } = $value;
            }
        }

        my $res = $req->new_response( 200 );
        $res->content_type('text/html');
        $res->body( $match->target->( $req, @args ) );
        return $res->finalize
    }

    return;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Plack::App::Path::Router - A Plack component for dispatching to Path::Router

=head1 SYNOPSIS

  use Plack::App::Path::Router;
  use Path::Router;

  my $router = Path::Router->new;
  $router->add_route('/' =>
      target => sub {
          my ($request) = @_;
          # ... do something with the $request
      }
  );
  $router->add_route('/:action/?:id' =>
      validation => {
          id => 'Int'
      },
      target => sub {
          my ($request, $action, $id) = @_;
          # $action and $id are passed in ...
      }
  );
  $router->add_route('/:action/edit/:id' =>
      validation => {
          id => 'Int'
      },
      target => sub {
          my ($r, $action, $id) = @_;
          # $action and $id are passed in ...
      }
  );

  # now create the Plack app
  my $app = Plack::App::Path::Router->new( router => $router );

=head1 DESCRIPTION

This is a L<Plack::Component> subclass which creates an endpoint to dispatch
using L<Path::Router>.

This module expects an instance of L<Path::Router> whose routes all have a
C<target> that is a CODE ref. The CODE ref will be called when a match is
found and passed a L<Plack::Request> instance followed by any path captures
that were found.

This thing is dead simple, if my docs don't make sense, then just read the
source (all 54 lines of it).

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut