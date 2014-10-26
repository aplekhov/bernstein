# Bernstein

Bernstein is a simple Ruby message queue for [OSC](http://en.wikipedia.org/wiki/Open_Sound_Control) messages 
that gives Ruby the ability to asynchronously send messages to OSC-enabled software and hardware.
It is built on top of the [ruby-osc](https://github.com/maca/ruby-osc) libray and currently uses Redis to 
queue the messages. Bernstein provides support for float,integer and string datatypes.  In addition, it offers an
awk-mode that a client can use to be notified that an OSC message was delivered and awknowledged.

## Why is it useful?

While typical OSC communication is 1:1 between a client and an OSC consumer, Bernstein allows for many clients
to control an OSC device or process.  For example, there could be a web interface adapting requests from
many users and sending them as OSC messages to a sound generator in an installation or performance.  Due to the queuing
there is an inherent latency, however that might be neglible in certain situations.


## Basic Usage

    gem install bernstein

Make sure that Redis is running. Start the background poller daemon:
    
    bernstein start -- -c bernstein.yml

```ruby
require 'bernstein'

# see sample yml file for options
Bernstein.configure_from_yaml!('bernstein.yml')

# send a message string, all parameters will be converted to floats
msg_id = Bernstein::Client.send_message_by_string "/synths/4/filter_cutoff 0.5"

# send a message with specific types
msg_id = Bernstein::Client.send_message '/synth/params', 'sinewave', 440, 556.3, 334.0

# get status ('queued','sending','sent')
Bernstein::Client.message_status(msg_id)
```

Stop the background poller like this:

    bernstein stop

## Default Configuration
See bernstein.sample.yml.
Note: if no redis options are passed, then the redis connection defaults will be used.

## Awk mode
By default, bernstein has awk mode enabled which means that it will send an internal message id along with every
message and expect the OSC receiver to respond back with an OSC 'awk' that contains the same message id.  For many software
OSC implementations this is pretty easy to setup, however it is not likely to work with hardware.  Make sure to disable it 
using the `require_awks` config key.

## License
The MIT License.  Copyright (c) 2014 Anthony Plekhov. See LICENSE.
