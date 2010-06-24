use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::TinyMVC',
    AUTHOR              => 'Nuno Carvalho <smash@cpan.org>',
    VERSION_FROM        => 'lib/App/TinyMVC.pm',
    ABSTRACT_FROM       => 'lib/App/TinyMVC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML::AppConfig' => 0,
        'Template' => 0,
        'Template::Constants' => 0,
        'Cache::Memcached' => 0,
        'String::CRC32' => 0,
        'File::Slurp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-TinyMVC-*' },
);
