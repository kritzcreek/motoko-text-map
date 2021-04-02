# motoko-text-map

A Motoko Hashmap that fixes its key type to Text.

People have reported that `base`'s HashMap type is less ergonomic than they'd like because they have to pass both an equality as well as a hash function on construction. So here's a monomorphic version of a HashMap with a few different implementation details.

## How to develop

- Write your library code in `*.mo` source files in the `src/` directory.
- Run `make check` to make sure your changes compile (or use the
  VSCode extension to get quicker feedback)
- Add tests to the source files in the `test/` directory, and run them
  with `make test`. The project template is set up to include
  motoko-matchers.
- Generate API documentation locally by running `make docs` and then
  open the resulting `docs/index.html` in your browser

## How to publish

- Create a git tag for the commit you'd like to be the published
  version. For example:
  ```bash
  git tag v1.1.0
  git push origin v1.1.0
  ```
- Follow the instructions at
  [`vessel-package-set`](https://github.com/dfinity/vessel-package-set)
  to make it easy for other to install your library

## API Documentation

API documentation for this library can be found at https://kritzcreek.github.io/motoko-text-map

## License

motoko-text-map is distributed under the terms of the Apache License (Version 2.0).

See LICENSE for details.
