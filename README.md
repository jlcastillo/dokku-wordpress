# Wordpress with Dokku

This repo explains one of the many possible ways to deploy and work with Wordpress and Dokku. These are its benefits:

- automatic backups of the WP database and files, including plugins, themes, uploads and customizations.
- versioning of all changes, both in custom and official files.
- ability to debug code in a local machine
- easy manual deployment to staging or production.
- free and automatically renewed SSL certificates.
- automatic redirect from HTTP to HTTPS.
- optional CI/CD

# Intended Operation after Setup

1. Wordpress updates, plugins, themes, etc, will be managed from WordPress dashboard rather than from the local computer. That's how WordPress is designed to work and we find it easier and less intrusive than managing everything locally (although we see the beauty of that too).

2. You can also do local development, manually add themes and plugins, and push all changes. If you do this, try to periodically `git pull` in case there were changes added from the WordPress dashboard. Then you can either `git push` (if Gitium webhooks are in use) or `git push dokku master` otherwise. Continue reading for an explanation.

3. **Recovery** (in case of emergencies): go to the backups plugin and restore. If you cannot access it for any reason, just push the app again from your `local machine`:

        git pull
        git push dokku master




# Getting Started

Create a repository in your favaourite platform (i.e. `GitHub`, `GitLab`, `BitBucket`, etc) that will hold all the code and version control. Let's say the URL is `https://myrepo.git`. 

If you didn't do it yet, install Dokku and the needed plugins (visit Dokku site to get in case there are newer versions):

    wget https://raw.githubusercontent.com/dokku/dokku/v0.11.6/bootstrap.sh
    sudo DOKKU_TAG=v0.11.6 bash bootstrap.sh
    sudo dokku plugin:install https://github.com/dokku/dokku-mysql.git mysql
    sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

In the Dokku machine, create an app (let's call it `wp`) and a a database linked to it (let's call it `wp` as well), and associate some domains (otherwise the app won't be reachable to browsers):
    
    
    dokku apps:create wp
    dokku domains:add wp yourdomain.com
    dokku domains:add wp www.yourdomain.com
    dokku mysql:create wp
    dokku mysql:link wp wp

We recommend creating a persistent storage for uploads outside the Dokku app, to keep the later small and agile:

    sudo mkdir -p /var/lib/dokku/data/storage/wp-uploads
    sudo chown 32767:32767 /var/lib/dokku/data/storage/wp-uploads
    dokku storage:mount wp /var/lib/dokku/data/storage/wp-uploads:/app/wp-content/uploads

If you are creating a new project, visit https://api.wordpress.org/secret-key/1.1/salt to generate new secret keys.

Otherwise, get the keys from your previous project. Normally they are stored in the `wp-config.php` file, although they could also be located in a `.env` file or in the environment variables of the machine.

Add the secret keys to your Dokku app as environment variables:

    dokku config:set wp AUTH_KEY='...your key...'
    dokku config:set wp SECURE_AUTH_KEY='...your key...'
    dokku config:set wp LOGGED_IN_KEY='...your key...'
    dokku config:set wp NONCE_KEY='...your key...'
    dokku config:set wp AUTH_SALT='...your key...'
    dokku config:set wp SECURE_AUTH_SALT='...your key...'
    dokku config:set wp LOGGED_IN_SALT='...your key...'
    dokku config:set wp NONCE_SALT='...your key...'

If you are migrating an existing project that was using a custom prefix for the tables in your database (some security plugins do that), you could add it to your config as an environment variable.

    dokku config:set wp TABLE_PREFIX='...your table prefix...'

Copy the wp-config file in this repo to your WordPress repo. This version is different from the one provided by official WordPress in that it tries to load configuration from environment variables first, and takes default values where no environment variables are present.

Visit again https://api.wordpress.org/secret-key/1.1/salt to generate new secret keys, and store them in the wp-config.php file as default values. This file can be safely versioned and uploaded since the real databases in the dokku server will be using different keys, loaded from the environment variables that we previously configured.

    cp wp-config.php WordPress

## If creating a new project

In your `local machine`, download the latest WordPress code, deleting the .git folder since we won't use the official repo afterwards.

    git clone --depth 1 https://github.com/WordPress/WordPress.git
    rm -rf WordPress/.git

## If migrating an existing project

1. Copy all the files from your current project, including both the wp-core, wp-contents and everything else to a folder called `WordPress`

2. Dump your existing database to a SQL file. There are many ways to do this, i.e. `PHPMyAdmin`, `MySQL Workbench` or `mysqldump`. In any case we recommend to only dump 1 database and include DROP TABLE and CREATE TABLE statements, as this will make it easier to retry if we find errors related to size limits while importing.

3. Import your database into dokku with:

    dokku mysql:import wp < database.sql

## First Deployment (for both cases)

From your `local machine`:

Create a `WordPress/.gitignore` file. You may start with these contents and accomodate it to your specific needs:

    .heroku/
    vendor/
    .profile.d/
    .composer/
    .builders_run
    Procfile
    .release
    *.log
    *.swp
    *.back
    *.bak
    *.sql
    *.sql.gz
    ~*
    .htaccess
    .maintenance
    wp-content/blogs.dir/
    wp-content/upgrade/
    wp-content/backup-db/
    wp-content/cache/
    wp-content/backups/

Then proceed to 

    cd WordPress
    git init
    git remote add dokku dokku@yourdomain.com:wp
    git push dokku master

If the command fails, please check:

1. in your local machine, show your public key:

        cat ~/.ssh/id_rsa.pub

2. if it doesn't exist, create it:

        ssh-keygen

3. in your dokku machine, show the authorized keys:

        cat /home/dokku/.ssh/authorized_keys

4. make sure your public key is listed within the authorized ones. If it isn't, in your dokku machine:

        echo "your id_rsa.pub contents" | sudo dokku ssh-keys:add mykey


## Setup Wordpress

1. Visit `http://yourdomain.com`

2. Choose language and set password.


## Setup Control Versioning

From the wordpress dashboard (`http://yourdomain.com/wp-admin`)

1. `SideMenu->Plugins->Add New->Search->"gitium"->Install->Activate`.

2. In `SideMenu->Gitium`, set the URL of your repo.

3. Copy the SSH public key and configure it in your remote repo (go to your repo website, like `GitHub`, `GitLab`, `BitBucket` and try to find where to put the key to grant access).

4. In `SideMenu->Gitium`, press `Fetch`.

5. Make sure the versioned files are correct. If not modify the .gitignore file within Gitium.

6. Review and `Push`.

In your `local machine`:

    cd WordPress
    git remote add origin https://myrepo.git
    git pull

You can now make local changes to files. You then push them to the dokku remote:

    git push dokku master

or even better, if you want don't want to stop and recreate the app, go to your repo remote site and configure Gitium webhook to let it now when there are new changes that may be fetched. Then just do:

    git push

and your changes will be sent to origin, the webhook will be called and Gitium will fetch changes.

## Setup Backups

1. Within the wordpress dashboard, `Plugins->Add New->Search->"updraftplus"->Install->Activate`.

2. Configure the plugin to upload backups to a cloud storage system like S3, setting the frequency and scope.

## Setup SSL

This will configure SSL with automatic redirection from HTTP to HTTPS and automatic certificate renewals.

From the `dokku machine`:

    dokku letsencrypt wp
    dokku letsencrypt:auto-renew
    dokku letsencrypt:cron-job --add

## Setup local development environment

1. Install Visual Studio Code.

2. Add the `PHP Debug` extension.

3. Install Xampp.

4. Download the XDebug .dll or .so from https://xdebug.org/. Make sure you get the right version and place it in `xampp/php/ext` folder.

5. Add these lines to the end of `xampp/php/php.ini` (convert the path style to Unix if needed):

        [XDebug]
        zend_extension = "c:\xampp\php\ext\<your XDebug .dll or .so"
        xdebug.remote_autostart = 1
        xdebug.profiler_append = 0
        xdebug.profiler_enable = 0
        xdebug.profiler_enable_trigger = 0
        xdebug.profiler_output_dir = "c:\xampp\tmp"
        ;xdebug.profiler_output_name = "cachegrind.out.%t-%s"
        xdebug.remote_enable = 1
        xdebug.remote_handler = "dbgp"
        xdebug.remote_host = "127.0.0.1"
        xdebug.remote_log = "c:\xampp\tmp\xdebug.txt"
        xdebug.remote_port = 9000
        xdebug.trace_output_dir = "c:\xampp\tmp"
        ;36000 = 10h
        xdebug.remote_cookie_expire_time = 36000

## Setup a Staging App

We already described how to create an app in dokku and load it with contents, please read it again if you have any doubt.

In order to create a second app (let's call it `stg`), and use it to test features before they are deployed to production, go to the `dokku machine` and:

1. create the app and db:

        dokku apps:create stg
        dokku domains:add stg stg.yourdomain.com
        dokku mysql:create stg
        dokku mysql:link stg stg

2. setup folders:

        sudo mkdir -p /var/lib/dokku/data/storage/stg-uploads
        sudo chown 32767:32767 /var/lib/dokku/data/storage/stg-uploads
        dokku storage:mount stg /var/lib/dokku/data/storage/stg-uploads:/app/wp-content/uploads

3. setup keys:

        dokku config:set wp AUTH_KEY='...your key...'
        dokku config:set wp SECURE_AUTH_KEY='...your key...'
        dokku config:set wp LOGGED_IN_KEY='...your key...'
        dokku config:set wp NONCE_KEY='...your key...'
        dokku config:set wp AUTH_SALT='...your key...'
        dokku config:set wp SECURE_AUTH_SALT='...your key...'
        dokku config:set wp LOGGED_IN_SALT='...your key...'
        dokku config:set wp NONCE_SALT='...your key...'

In the `local machine`:

4. Add the staging remote and push to deploy:

        git remote add staging dokku@stg.yourdomain.com:stg
        git push staging master


## Setup CI/CD

If you already configured the Gitium webhooks, your code will be deployed to production whenever you push changes to the origin master branch.

If you want higher control over what branches to push and when,you may disable the Gitium webhook and use one of the many available services like `CircleCI`,  `Gitlab CD` or `Bitbucket Pipelines` to conditionally push to either staging or production environments.

