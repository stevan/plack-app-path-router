use strict;
use warnings;
use inc::Module::Install;

name 'Plack-App-Path-Router';
all_from 'lib/Plack/App/Path/Router.pm';
license 'perl';

# prereqs
requires 'Moose'            => '0';
requires 'MooseX::NonMoose' => '0';

requires 'Plack'            => '0';
requires 'Plack::Request'   => '0';

requires 'Path::Router'     => '0';

# things the tests need
build_requires 'Test::More' => '0';

tests_recursive;
auto_install;

WriteAll();

