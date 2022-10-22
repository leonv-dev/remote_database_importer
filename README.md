# RemoteDatabaseImporter
**RemoteDatabaseImporter** is a small gem with one specific pupose of life: Dump remote databases and import it locally.

**Currently this gem is in the BETA version!**  
Its very well possible that unexpected errors occur

## Features
- Define multiple environments (such as staging, production)
- Rails intergration via rake task
- Decide for yourself if the dump should be done over a ssh connection or if the db port should be used directly (with pg_dump)
- It can therefore be used for all hosting providers (Heroku, Kubernetes, self-hosted, etc.)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'remote_database_importer'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install remote_database_importer

## Usage
Whenever you want current live data, you can run the command:

```ruby
rake remote_database:import
```

### Config
The settings for the different environments is in the `remote_database_importer.yml` file stored.  
When you first run the rake task, it will dynamically create this file for you.


![asdf](readme_images/config_sample.png)

### DB Access
The easiest and fastest way is to exchange your ssh-key with the server beforehand, so you don't have to enter a password.  
Otherwise during the rake task execution a password entry is required.

The effective dump call is as follows:
```ruby
"ssh #{ssh_user}@#{host} -p #{ssh_port} 'pg_dump -Fc -U #{db_user} -d #{db_name} -h localhost -C' > #{db_dump_location}"
or
"pg_dump -Fc 'host=#{host} dbname=#{db_name} user=#{db_user} port=#{postgres_port}' > #{db_dump_location}"
```

## Limitations
- At the moment only postgres databases are supported
- Not suitable for very large databases, because you could run into an SSH timeouts

## Contributing

Bug reports and pull requests are very welcome!

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
