# switches #

Switches lets you turn on and off sections of your code with <tt>Switches.foobar?</tt> booleans.

It's an extraction from [http://brighterplanet.com](http://brighterplanet.com), where we use it as an emergency button to turn on/off API integration with Facebook, Campaign Monitor, etc.

## Quick start ##

Add 2 lines to <tt>config/environment.rb</tt>:

    require File.join(File.dirname(__FILE__), 'boot')
    [...]
    require 'switches'                                  # AFTER boot, BEFORE initializer
    [...]
    Rails::Initializer.run do |config|
    [...]
      config.gem 'switches', :lib => false              # INSIDE initializer

Now run this:

    my-macbook:~/my_app $ ./script/runner 'Switches.setup'

Add your defaults to <tt>config/switches/defaults.yml</tt>:

    --- 
    ssl: true                   # ssl support is on by default
    campaign_monitor: true      # campaign monitor integration is on by default

## Tasks ##

<table>
  <tr>
    <th>Rake task</th>
    <th>Cap task</th>
    <th>Notes</th>
  </tr>
  <tr>
    <td>rake s:c</td>
    <td>cap TARGET s:c</td>
    <td>show current switches</td>
  </tr>
  <tr>
    <td>rake s:d</td>
    <td>cap TARGET s:d</td>
    <td>show difference between current and default switches</td>
  </tr>
  <tr>
    <td>rake s:on[SWITCH]</td>
    <td>cap TARGET s:on ARG=SWITCH</td>
    <td>turn on SWITCH</td>
  </tr>
  <tr>
    <td>rake s:off[SWITCH]</td>
    <td>cap TARGET s:off ARG=SWITCH</td>
    <td>turn off SWITCH</td>
  </tr>
  <tr>
    <td>rake s:clear[SWITCH]</td>
    <td>cap TARGET s:clear ARG=SWITCH</td>
    <td>clear any switch for SWITCH</td>
  </tr>
  <tr>
    <td>rake s:reset</td>
    <td>cap TARGET s:reset</td>
    <td>go back to defaults (deletes <tt>config/switches/current.yml</tt>)</td>
  </tr>
  <tr>
    <td>rake s:backup</td>
    <td>cap TARGET s:backup</td>
    <td>backup current switches (copies to <tt>config/switches/backup.yml</tt>)</td>
  </tr>
  <tr>
    <td>rake s:restore</td>
    <td>cap TARGET s:restore</td>
    <td>restore backed-up switches (copies <tt>backup.yml</tt> to <tt>current.yml</tt>)</td>
  </tr>
  <tr>
    <td>rake s:default</td>
    <td>cap TARGET s:default</td>
    <td>list default settings</td>
  </tr>
</table>

## Throwing switches remotely with Capistrano ##

This is the minimum needed in the TARGET task:

    task :production do
      role :app, 'ec2-88-77-66-55.compute-1.amazonaws.com'
      role :app, '177.133.33.144'
  
      set :rails_env, 'production'
      set :deploy_to, '/data/my_app'
      set :gfs, false
    end

The switches will get applied to any role that matches <tt>/app/</tt> (so :app_master, :app, etc.)

## Usage ##

You can do stuff like (in <tt>app/models/user.rb</tt>):

    after_create :subscribe_email if Switches.campaign_monitor?
    def subscribe_email
      CampaignMonitor.subscribe email
    end

Uhh ohh! Campaign Monitor's API is down and you need to shut off those failing after_creates, like, NOW.

    production-server-1:/var/www/apps/my_app $ rake s:off[campaign_monitor]
    production-server-1:/var/www/apps/my_app $ sudo monit restart all -g my_app
    [...]
    production-server-2:/var/www/apps/my_app $ rake s:off[campaign_monitor]
    production-server-2:/var/www/apps/my_app $ sudo monit restart all -g my_app

Or, even better, do it with cap:

    my-macbook:~/my_app $ cap production s:off ARG=campaign_monitor
    my-macbook:~/my_app $ cap production mongrel:restart

For another example, let's say you're a developer who doesn't have a self-signed certificate:

    my-macbook:~/my_app $ rake s:off[ssl]

Those changes get persisted in <tt>config/switches/current.yml</tt>.

If you want to see your switches vis-a-vis the defaults:

    my-macbook:~/my_app $ rake s:d
    --- 
    ssl: true => false

And if you want to go back to the defaults:

    my-macbook:~/my_app $ rake s:reset

Remember, you should version control <tt>config/switches/defaults.yml</tt> and ignore <tt>config/switches/current.yml</tt>.

## Rationale ##

Sometimes you just need an easy way to "turn off" code.

## Wishlist ##

+ HOWTO do stuff to switches pre-rake db:migrate

## Copyright ##

Copyright (c) 2009 Seamus Abshere. See LICENSE for details.
