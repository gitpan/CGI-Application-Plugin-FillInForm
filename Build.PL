#!/usr/bin/perl
use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'CGI::Application::Plugin::FillInForm',
    license             => 'perl',
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
    dist_version_from   => 'lib/CGI/Application/Plugin/FillInForm.pm',
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    requires => {
        'Test::More'       => 0,
        'HTML::FillInForm' => 1.05,
        'CGI::Application' => 0,
    },                             
    add_to_cleanup      => [ 'CGI-Application-Plugin-FillInForm-*' ],
);

$builder->create_build_script();
