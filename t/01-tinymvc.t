#!perl -T -Ilib

use Test::More tests => 6;

use App::TinyMVC;
use App::TinyMVC::Controller::Test;

$App::TinyMVC::CONFDIR = 'config';

my $tinymvc = new App::TinyMVC (
        controller => 'test',
        action => 'test',
        args => [],
        context => {
            params => {},
        }
    );

ok( $tinymvc->controller eq 'test', 'controller method' );
ok( $tinymvc->action eq 'test', 'controller method' );
my $empty = [];
is_deeply( $tinymvc->args, $empty, 'empty args method' );

my $output = $tinymvc->process;
ok( $output eq 'string: hello world', 'simple test' );

$tinymvc = new App::TinyMVC (
        controller => 'test',
        action => 'test',
        args => [1,2,3],
        context => {
            params => {},
        }
    );

my $args = [1,2,3];
is_deeply( $tinymvc->args, $args, 'not empty args method' );

$output = $tinymvc->process;
ok( $output eq 'string: got 1 2 3', 'simple test with arguments' );
