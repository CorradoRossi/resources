###

Open MAMP and create a new database (name, collation)

###

Create a wp-config.php file

```php
/** The name of the database for WordPress */
define('DB_NAME', 'database_name_here');
/** MySQL database username */
define('DB_USER', 'username_here');
/** MySQL database password */
define('DB_PASSWORD', 'password_here');
```

```php
/** The name of the database for WordPress */
define('DB_NAME', 'startwordpress');
/** MySQL database username */
define('DB_USER', 'root');
/** MySQL database password */
define('DB_PASSWORD', 'root');
```

###

Find this:

```php
$table_prefix  = 'wp_';
```

And change it to literally anything else with numbers and letters. For security. xyz_ or 735hjq9_, etc.

```php
$table_prefix  = 'xyz77_';
```

###

Go to this site and get a new salt.

https://api.wordpress.org/secret-key/1.1/salt/

Then replace the salt in your wp-config.php file and save.

###

Things to change when migrating:

mysitename.test => mysitename.com

db root:
db pw:

wp root:
wp pw:



