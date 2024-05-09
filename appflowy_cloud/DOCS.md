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
This only takes effect during the first startup. Once the database is initialized, admin user email cannot be changed.

### Option: `ADMIN_PASSWORD` (required)

Admin user password.  
After the first startup the password can be changed via the admin panel.

## Support

In case you've found a bug, please [open an issue on our GitHub][issue].

[issue]: https://github.com/SilvioMessi/hassio-addons/issues
