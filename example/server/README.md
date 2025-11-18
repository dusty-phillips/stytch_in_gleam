# Example auth backend with stytch

This package illustrates how to call the stytch client in API requests
as part of a full stack lustre app.

## Run

First build the [client](../client).

Sign up for a free [Stytch](https://stytch.com) account.

Create a `.env` file in this folder with three keys:

```env
SECRET_KEY_BASE=<64 char random string>
STYTCH_PROJECT_ID=<your project id from stytch dashboard>
STYTCH_SECRET=<your project secret from stytch dashboard>
```

Then just `gleam run` in this package.
