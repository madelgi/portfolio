# Portfolio

Source code for my website, uses [Gatsby](https://www.gatsbyjs.com/). Builds off
[this](https://github.com/LekoArts/gatsby-themes/tree/master/themes/gatsby-theme-minimal-blog)
beautiful theme designed by [LekoArts](https://github.com/LekoArts).

## Run locally

To run the site locally, create an `.env` file with the following variables:

```txt
BUILD_ENV=development
```

After this, enter:

```bash
$ docker-compose up --build frontend
```

in the root directory. The site should now be accessible at `0.0.0.0:8000`.
