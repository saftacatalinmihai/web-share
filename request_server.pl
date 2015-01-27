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

sub send_listeners{
	my ($channel, $msg) =  @_;

	if (exists $websocket_listeners->{$channel}) {
		for my $l (keys %{$websocket_listeners->{$channel}} )  {
			$websocket_listeners->{$channel}->{$l}->send($msg);
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
# websocket '/listener/register' => sub {
	my $c = shift;
	my $channel = $c->param("channel");

	# Remove inactivity timeout
	$c->inactivity_timeout(0);

  	# Opened
  	$c->app->log->debug("Client connected on channel $channel");

	my $id = "$c->tx";
	$websocket_listeners->{$channel}->{$id} = $c->tx;

	$c->on(message => sub {
			my ($c, $message) = @_;
			$c->app->log->debug("Recieved: $message");
			$c->send("pong") if $message eq 'ping';
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

		send_listeners($ch, $url_param);
		$c->render(text => $url_param);
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
	<head><title>Web-Share</title></head>
	<body>
		<p> Channel:  <%= $ch %></p>
		<script>
		var ws = new WebSocket('<%= url_for('listenerregister')->to_abs %>/<%= $ch %>');
		// Incoming messages
		ws.onmessage = function(event) {
			var data = event.data;
			if (data !== 'pong') {
				console.log(data);
				document.body.innerHTML += data + '<br/>';
				var href = "http://"+data

				window.location.href = href;
				// window.open("http://"+data,  "_blank");
			} else {
				console.log('pong recieved');
			}
		};
		window.setInterval(function () { ws.send('ping') }, 50000);
		// window.setInterval(function () { ws.send('ping') }, 3000);
		</script>
		<p>Listener registered, awaiting requests...</p>
	</body>
</html>
