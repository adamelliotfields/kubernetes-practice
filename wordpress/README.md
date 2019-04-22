# Wordpress

A single Wordpress Pod with PHP-FPM, NGINX, and MySQL using Unix sockets instead of TCP.

This is a basic example. A more advanced deployment could include:
  - Using `cert-manager` for TLS and configuring [Administration Over SSL](https://codex.wordpress.org/Administration_Over_SSL).
  - Replacing [WP-Cron](https://developer.wordpress.org/plugins/cron/hooking-into-the-system-task-scheduler) with a CronJob.

### Prerequisites

  1. This example uses the [hostpath](https://github.com/rimusz/hostpath-provisioner) StorageClass.
  2. This example uses the [nginx-ingress](https://github.com/helm/charts/tree/master/stable/nginx-ingress) Ingress controller.
  3. You must have public DNS records pointing to your cluster's external IP.
     - Including a CNAME record for `www`.

### Manifests

  - [`wordpress.yaml`](./wordpress.yaml) _(CM, PVC, Service, Deployment, Ingress)_

### Configuration

The manifest includes ConfigMaps with data for NGINX, PHP-FPM, and Wordpress.

`nginx.conf` is generated by [nginxconfig.io](https://nginxconfig.io). Change `example.com` to your
domain.

`php.ini` is the production configuration included with the Docker image, with comments removed.
File upload size has been increased to 16MB; but you may need to increase this more if you plan on
uploading larger themes (make sure to increase it in `nginx.conf` as well).

`zz-docker.conf` overrides the default listen address of `localhost:9000` and replaces it with a
Unix socket. Any settings you'd normally put in `pool.d` should go in this file.

`wp-config.php` is used instead of environment variables to configure Wordpress. This means it is
read-only, so it cannot be updated inside the container.

Note that because these files are mounted using `subPath`, Kubelet will not restart the containers
they're bound to. You'll have to scale the deployment down to 0, wait for the containers to
terminate, and scale back up to 1.

### Salt Keys

Wordpress uses salt keys to encrypt passwords. Normally you'd run `wp config shuffle-salts` to
generate these programmatically, but since ConfigMaps are read-only, you'll have to manually update
them.

Simply curl <https://api.wordpress.org/secret-key/1.1/salt> or visit it in your browser, and then
paste the result into `wp-config.php`.

```php
define('AUTH_KEY',         '-w>7z?Z3mV`s9:ErgP)u|xbNH)K[BTV8`xA6s<K5*dPN>e(a*yPZt-Ui/uYo~Y}B');
define('SECURE_AUTH_KEY',  '7O>gK0Lp?S_^4O&^V7gMNm(sxx7TwH*Vn.`;zQ*GHrnIJl+OcJ5dFg,2-[jDodk|');
define('LOGGED_IN_KEY',    'U|lVSq+ ?Iw~i^5t)-aEuu h%3]|yc>xwZN8w~lP_n VU_}@PoMU-i998xLZIbLs');
define('NONCE_KEY',        'oF3z!%>t)ffiQ^!b=Z*K?jt.y~iv@_yO:3r9{wd^Lx?|h/TgD+^C/o,B<Bv*<GlW');
define('AUTH_SALT',        'RgN-l/@]`Z|8oQBT|w-{+kb7+tx}}-%RB--V=_-U5eexV34E:c?2NX}a7wBE+R*u');
define('SECURE_AUTH_SALT', 'FsO3H@)3X#3a`&B Tu~-R3|i$ev-iU:iV~GdfjVfq&3-uD]K-s]|0 -On#q<*A6C');
define('LOGGED_IN_SALT',   'B]v>d6>YN%N|$[v1fjW##HiE|B| EuTjgFL7o{ky31R@h(fI|N,_L-HF g,-n=DK');
define('NONCE_SALT',       'eC=N `TpD4+XN+.F8H4A?G4m-*K Q3O!1h+C8DfquKO1QD`mDUdF@9hX-|;*w}M:');
```

### Deploy

Before deploying, change `example.com` in the Ingress to your domain.

```bash
kubectl -n wordpress apply -f ./wordpress.yaml
```

Tail the MySQL container once `kubectl -n wordpress get po` shows `3/3 Running`.

```bash
kubectl -n wordpress log -f -c mysql "$(kubectl -n wordpress get po -o=jsonpath='{.items[0].metadata.name}')"
```

Once you see `[Server] /usr/sbin/mysqld: ready for connections`, you can go to your site's URL and
complete the installation.

### Email

The easiest way to enable emails for your site is the [WP Mail SMTP](https://wordpress.org/plugins/wp-mail-smtp)
plugin by WPForms.

Simply install the plugin once your site is running and follow the instructions. It doesn't require
changing any configuration files, although you can optionally store your credentials in
`wp-config.php`.