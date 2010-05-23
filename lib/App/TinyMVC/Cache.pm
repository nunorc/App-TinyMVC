#!/usr/bin/perl

package App::TinyMVC::Cache;

use strict;
use warnings;

our $VERSION = '0.01_2';

use Cache::Memcached;

sub new {
	my($class) = @_;
	my $self = bless({}, $class);

	my $memd = new Cache::Memcached {
    		'servers' => [ "127.0.0.1:11211" ],
    		'debug' => 0,
    		'compress_threshold' => 10_000,
		};

	$self->{'memd'} = $memd;
	return $self;
}

sub set {
	my($self,$tinymvc,$prefix,$key,$value,$expire) = @_;

	unless ($tinymvc->{'config'}->{'cache'}->{'enabled'}) {
		$tinymvc->log('cache','cache disabled in configuration');
		return undef;
	}

	if (defined($tinymvc->{'context'}->{'query_string'}->{'cache'}) and $tinymvc->{'context'}->{'query_string'}->{'cache'} eq 'no') {
		$tinymvc->log('cache',"Skipped set by query_string! ".'desporto_stats:'.$prefix.'::'.$key);
		return;
	}

	unless ($expire) {
		$expire = $tinymvc->{'config'}->{'controllers'}->{$tinymvc->controller}->{$tinymvc->action}->{'expire'};
	}
	$tinymvc->log('cache',"set: ".'desporto_stats:'.$prefix.'::'.$key." Expire: $expire");
	$self->{'memd'}->set('desporto_stats:'.$prefix.'::'.$key, $value, $expire);
}

sub get {
	my($self,$tinymvc,$prefix,$key) = @_;

	unless ($tinymvc->{'config'}->{'cache'}->{'enabled'}) {
		$tinymvc->log('cache','cache disabled in configuration');
		return undef;
	}

	if (defined($tinymvc->{'context'}->{'query_string'}->{'cache'}) and ($tinymvc->{'context'}->{'query_string'}->{'cache'} eq 'no' or $tinymvc->{'context'}->{'query_string'}->{'cache'} eq 'reset') ) {
		$tinymvc->log('cache',"Skipped get by query_string! ".'desporto_stats:'.$prefix.'::'.$key);
		return;
	}

	my $res;
	if ($res = $self->{'memd'}->get('desporto_stats:'.$prefix.'::'.$key)) {
		$tinymvc->log('cache',"Hit! ".'desporto_stats:'.$prefix.'::'.$key);
	}
	else {
		$tinymvc->log('cache',"Miss! ".'desporto_stats:'.$prefix.'::'.$key);
	}
	$res;
}

1;
