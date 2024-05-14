# Home Assistant Add-on: AppFlowy Cloud

## Configuration

Add-on configuration:

```yaml
  SECRET: change_me
  ADMIN_EMAIL: admin@example.com
  ADMIN_PASSWORD: password
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

## Support

In case you've found a bug, please [open an issue on our GitHub][issue].

[issue]: https://github.com/SilvioMessi/hassio-addons/issues
