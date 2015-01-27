#!/usr/bin/env perl
#===============================================================================
#
#         FILE: request_server.pl
#
#        USAGE: ./request_server.pl
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Safta Catalin Mihai ,
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 12/14/2014 06:57:25 PM
#     REVISION: ---
#===============================================================================

use 5.14.1;
use strict;
use warnings;
use utf8;
use Mojolicious::Lite;
use Data::Printer;

my $websocket_listeners = {};

sub send_json_listeners{
	my ($channel, $hash) =  @_;

	if (exists $websocket_listeners->{$channel}) {
		for my $l (keys %{$websocket_listeners->{$channel}} )  {
			$websocket_listeners->{$channel}->{$l}->send({json =>$hash});
		}
	}
}

get '/' => sub {
	my $c = shift;
	$c->stash(ch => 'public');
	$c->render(template => 'index', format => 'html');
};

get '/channel/*ch' => sub {
		my $c = shift;
		$c->render(template => 'index', format => 'html' );
};

websocket '/listener/register' => sub {
	my $c= shift;
	return $c->redirect_to("/listener/register/public");
};

websocket '/listener/register/*channel' => sub {
	my $c = shift;
	my $channel = $c->param("channel");

	# Remove inactivity timeout
	$c->inactivity_timeout(0);

  	# Opened
  	$c->app->log->debug("Client connected on channel $channel");

	my $id = "$c->tx";
	$websocket_listeners->{$channel}->{$id} = $c->tx;

	$c->on(json => sub {
		my ($c, $hash) = @_;
		$c->app->log->debug("Recieved: $hash->{msg}");
		$c->send({json => {msg => "pong"}}) if $hash->{msg} eq 'ping';
	});

	$c->on(finish => sub {
			$c->app->log->debug("Client disconected from channel $channel");
			delete $websocket_listeners->{$channel}->{$id};
		});
};

get '/open' => sub {
		my $c = shift;
		my $ch = $c->param('ch') ? $c->param('ch') : "public";
		my $url_param = defined $c->param('url') ? $c->param('url') :  ${\$c->param()};

		my $page_url_target = $c->param("target") ?  $c->param("target") : "new_tab";
		$page_url_target = 'new_tab' if ( !($page_url_target  =~ /^(new_tab|iframe|replace)$/));

		$c->app->log->debug("Open request for url: [$url_param], on channel: [$ch], taget: [$page_url_target]");
		send_json_listeners($ch, {url => $url_param, page_url_target => $page_url_target});
		$c->render(text => $url_param);
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
	<head>
		<title>Web-Share</title>
		<style>
			body {
				position: relative;
				margin: 0;
				height: 100%;
				padding-top: 100px;
			}
			iframe {
				width: 100%;
				height: 100%;
				border: none;
			}
			.info {
				position: absolute;
				top: 0;
				left: 0;
				width: 100%;
				height: 100px;
			}
		</style>
	</head>
	<body>
		<p> Channel:  <%= $ch %></p>
		<div class='info'>

		</div>
		<iframe src="http://www.w3schools.com"></iframe>
		<script>
		var ws = new WebSocket('<%= url_for('listenerregister')->to_abs %>/<%= $ch %>');
		// Incoming messages
		ws.onmessage = function(event) {
			var url = JSON.parse(event.data).url;
			var page_url_target = JSON.parse(event.data).page_url_target;
			if (url !== 'pong') {
				console.log(url);
				console.log(page_url_target);
				document.body.innerHTML += url + '<br/>';
				var href = "http://"+url;
				
				switch (page_url_target) {
					case "new_tab":
						window.open(href,  "_blank");
						break;
					case "replace":
						window.location.href = href;
						break;
					case "iframe":
						document.getElementsByTagName('iframe')[0].src = href;
						break;
				}

			} else {
				console.log('pong recieved');
			}
		};
		window.setInterval(function () { ws.send(JSON.stringify({msg: 'ping'})) }, 50000);
		// window.setInterval(function () { ws.send(JSON.stringify({msg: 'ping'}))}, 3000);
		</script>
		<p>Listener registered, awaiting requests...</p>
	</body>
</html>
