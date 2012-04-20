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

        return $self->handle_response( $res );
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

=head1 DESCRIPTION

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
