# Home Assistant Add-on: AppFlowy Cloud

## Configuration

Add-on configuration:

```yaml
  SECRET: change_me
  ADMIN_EMAIL: admin@example.com
  ADMIN_PASSWORD: password
  PUBLIC_URL: http://localhost
  SMTP_HOST: smtp.example.com
  SMTP_PORT: 465
  SMTP_USER: user@example.com
  SMTP_PASSWORD: password
```

### Option: `SECRET` (required)

Authentication key, change this and keep the key safe and secret.

### Option: `ADMIN_EMAIL` (required)

This admin user will be created when AppFlowy Cloud starts successfully.  
You can use this user to login to the admin panel.  
Every time you change this email a new admin user will be created (if the email does not already exist in the database).

### Option: `ADMIN_PASSWORD` (required)

Admin user password.  
This only takes effect the first time the new admin user is create. Once the user is created the password can be changed in the admin panel.

### Option: `PUBLIC_URL` (required)

The public URL you are using to expose the AppFlowy add-on.
This is typically the URL or IP address you use to connect to your Home Assistant, including the port used to expose the AppFlowy add-on. If you have configured a port other than 80, please include it in the URL. For example: `http://localhost:8080`.

### Option: `SMTP_HOST` (required)

For certain use cases (such as logging in via a magic link when using AppFlowy Web), an SMTP server is required to send the login link via email.
This is the SMTP server hostname.

### Option: `SMTP_PORT` (required)

The SMTP server port.

### Option: `SMTP_USER` (required)

The SMTP server user, usually an email address.

### Option: `SMTP_PASSWORD` (required)

The SMTP server password.

## Usage

Once the add-on is started, click on OPEN WEB UI. This will open a new browser tab at the `PUBLIC_URL`, displaying the AppFlowy Web application. For admin panel, (users management), please visit `PUBLIC_URL/console`

## Support

In case you've found a bug, please [open an issue on our GitHub][issue].

[issue]: https://github.com/SilvioMessi/hassio-addons/issues
