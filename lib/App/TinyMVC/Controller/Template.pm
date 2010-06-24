
package App::TinyMVC::Controller::Template;

use warnings;
use strict;

sub dump {

my $template=<<'EOF';
{

package App::TinyMVC::Controller::[% name %];

use warnings;
use strict;

sub new {
    my($class) = shift;
    my $self = bless({}, $class);

    return $self;
}

sub auto {
	my($self,$tinymvc) = @_;
	$tinymvc->log('CONTROLLER', "App::TinyMVC::Controller::Test->auto");

	my $cache_id = $tinymvc->{'controller'}.$tinymvc->{'action'}.join '', @{$tinymvc->{'args'}};
	$tinymvc->log('cache', "cache id is: $cache_id\n");
	my $cache_type = App::TinyMVC::CACHE_VIEW;

	return($cache_id,$cache_type);
}

[% FOREACH key IN functions.keys %]
sub [% key %] {
	my($self,$tinymvc) = @_;
	$tinymvc->log('CONTROLLER', "App::TinyMVC::Controller::[% name %]->[% key %]");

	[% functions.item(key).source %]

	[% FOREACH e IN functions.item(key).returns %]
		$tinymvc->stash('[% e %]', $[% e %]);
	[% END %]
	}
[% END %]

}
EOF

return $template;
}

1;
