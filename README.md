# Portfolio Site (powered by Jekyll)
This repo contains the content for a Jekyll site, along with supporting files for a local preview function.

## Local environment setup

### Setting up Ruby, Bundler, Git, and Make on Gentoo Linux
Specify a Ruby target in `/etc/portage/make.conf`. I use Ruby 2.6, and I specify that as:

    RUBY_TARGETS="ruby26"

Next, you'll want to ensure you have `bundler`, `git`, and `make`. As root, or via `sudo`:

    emerge -au dev-ruby/bundler dev-vcs/git sys-devel/make

### Setting up Ruby, Bundler, Git, and Make on Debian-ish Linux
I'm using Debian under WSL2 for this, and that comes with some caveats. But generally speaking, we'll need `ruby`, `bundler`, `git`, and `make`. You can run (as root, or via `sudo`):

    apt install build-essential ruby-full bundler git

## Install
Find a convenient location to clone the repo, and run:

    git clone https://github.com/ironiridis/portfolio.git

This should clone into a folder named `portfolio`. `cd` into that folder, and run `make test`:

    cd portfolio
    make test

This will download all the dependencies and plop them into a repo-local folder. Jekyll should now be running and serving a local copy of the site at `http://[hostname or ip]:4000/` . If you ran this on the same machine you're using now, you should be able to find it at http://localhost:4000 but your mileage may vary.

