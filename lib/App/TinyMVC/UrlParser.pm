#!/usr/bin/perl

package App::TinyMVC::UrlParser;

use strict;
use warnings;

our $VERSION = '0.01_2';

sub new {
	my($class,$r) = @_;
	my $self = bless({}, $class);

	my $request_uri;
	my $script_name;
	if($ENV{'MOD_PERL'}) {
		$self->{'host'} = $r->hostname;
		$request_uri = $r->path_info;
	}
	else {
		$self->{'host'} = $ENV{'HTTP_HOST'};
		$request_uri = $ENV{'REQUEST_URI'};
		$script_name = $ENV{'SCRIPT_NAME'};
	}

	unless($ENV{'MOD_PERL'}) {
		$script_name =~ s#/index\.pl##;
		$request_uri =~ s/$script_name//;
	}
	$request_uri =~ s/^\/+//;
	$self->{'request_uri'} = $request_uri;

	my @tmp = split /\/+/, $request_uri;
	$self->{'controller'} = lc shift @tmp;
	$self->{'action'} = lc shift @tmp;
	@tmp = map {lc $_} @tmp;
	$self->{'args'} = \@tmp;

	return $self;
}

sub host {
	my $self = shift;

	$self->{'host'};
}

sub controller {
    my $self = shift;

    $self->{'controller'};
}

sub action {
    my $self = shift;

    $self->{'action'};
}

sub args {
	my $self = shift;

	$self->{'args'};
}

sub request_uri {
    my $self = shift;

    $self->{'request_uri'};
}

1;
