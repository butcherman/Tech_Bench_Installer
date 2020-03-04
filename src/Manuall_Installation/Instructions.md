# Preparing the server

Before the installation can begin, the following requirements must be met:

## Server Requirements

* Web Server is installed and running.
* Rewrite Module is enabled (to allow .htaccess rewrite)
* MySQL Database Server is installed and running

Note:  For security purposes, it is best practice to have the public folder of the Tech Bench application files be the Web Document Root

## PHP Requirements

* PHP 7.2 or higher is installed
* PHP-XML Module is installed and enabled
* PHP-DOM Module is installed and enabled (should be packaged with the XML Module)
* PHP-ZIP Module is installed and enabled
* PHP-GD Module is installed and enabled

## Additional Software Requirements for Dependency Management

* Coposer is installed
* Node.js is installed
* NPM is installed
* Supervisor is installed (Linux Distributions Only)

## Setting up files

* Download the latest build of Tech Bench
* Unzip files and place all files in the Web Root folder
* Be sure to copy the .htaccess files and .env.example files as well
* Rename the .env.example to .env
* Open the .env file and edit the following entries:

    * APP_URL -> This entry should contain the full URL of the Tech Bench Application (example:  https://techbench.mycompany.com)
    * DB_DATABASE -> This entry should contain the name of the database to be used for the Tech Bench.  Note:  you must create this database
    * DB_USERNAME -> The username that will be used by the tech bench to read and write to the database
        
        **Note:** This user must have full permissions to the database including 'GRANT.'  The user will also need select permissions from the 'information_schema' database as well
    
    * DB_PASSWORD -> The password for the database user

* Save the modifications and exit

## Downloading Dependencies

* From a command prompt, navigate to the Web Document Root folder and enter the following commands:
* Download all Composer dependencies

    ```composer install --no-dev --no-interation --optimize-autoloader```

* Download all NPM dependencies

    ```npm install --only=production```

* Create a new Application Encryption key

    ```php artisan key:generate```

* Create the virtual link for the public storage folder

    ```php artisan storage:link```

* Create the Javascript file

    ```php artisan ziggy:generate```

    ***Note:*** The APP_URL field must be correct before running this command.  Failure to do so will result in the application not running correctly!

* Compile the minimized Javascript and CSS Files

    ```npm run production```

You can now visit the web page for the Tech Bench application by browsing to the URL noted in the .env file under APP_URL

Default login is:

    Username:  admin
    Password:  password