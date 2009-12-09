use strict;
use warnings;
use inc::Module::Install;

name 'Plack-App-Path-Router';
all_from 'lib/Plack/App/Path/Router.pm';
license 'perl';

# prereqs
requires 'Moose'            => '0.90';
requires 'MooseX::NonMoose' => '0.07';

requires 'Plack'            => '0.9021';
requires 'Plack::Request'   => '0.08';

requires 'Path::Router'     => '0.08';

# things the tests need
build_requires 'Test::More' => '0.88';

tests_recursive;
auto_install;

WriteAll();

