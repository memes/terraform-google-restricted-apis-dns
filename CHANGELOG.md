# Changelog

## [2.0.1](https://github.com/memes/terraform-google-restricted-apis-dns/compare/v2.0.0...v2.0.1) (2025-10-17)


### Bug Fixes

* Add 'gke.goog' to default overrides set ([f413ff2](https://github.com/memes/terraform-google-restricted-apis-dns/commit/f413ff2c68e8a808bad56b917aaf0211647717a2))
* Strip domains from overrides if masked ([264eb3b](https://github.com/memes/terraform-google-restricted-apis-dns/commit/264eb3b11f9be88adc821a322163b6976d362b1d))

## [2.0.0](https://github.com/memes/terraform-google-restricted-apis-dns/compare/v1.3.0...v2.0.0) (2025-06-12)


### ⚠ BREAKING CHANGES

* The module has changed minimal requirements for terraform/tofu version to 1.5+ and Google provider to 6.0+.

### Features

* Add support for custom A/AAAA addresses ([d4c88ce](https://github.com/memes/terraform-google-restricted-apis-dns/commit/d4c88ce63a6e3dcb9e5051bbd3bf895edf93cf84))

## [1.3.0](https://github.com/memes/terraform-google-restricted-apis-dns/compare/v1.2.0...v1.3.0) (2023-12-07)


### Features

* Support Private Google API DNS entries ([769ca77](https://github.com/memes/terraform-google-restricted-apis-dns/commit/769ca77701f8701c139d0c8e4e2b97afddfd3d73)), closes [#41](https://github.com/memes/terraform-google-restricted-apis-dns/issues/41)

## [1.2.0](https://github.com/memes/terraform-google-restricted-apis-dns/compare/v1.1.1...v1.2.0) (2023-03-16)


### Features

* Remove Google DNS module from solution ([0dba3c3](https://github.com/memes/terraform-google-restricted-apis-dns/commit/0dba3c30667b5d9a4d2c85188ec71effc32e7f9a))

## [1.1.1](https://github.com/memes/terraform-google-restricted-apis-dns/compare/v1.1.0...v1.1.1) (2023-03-16)


### Bug Fixes

* Add description to overrides input ([87db263](https://github.com/memes/terraform-google-restricted-apis-dns/commit/87db263d643fa90387b19bb082309c93b7d998b6))

## [1.1.0](https://github.com/memes/terraform-google-restricted-apis-dns/compare/v1.0.1...v1.1.0) (2023-03-16)


### Features

* IPv6 support for restricted.googleapis.com ([6f39d04](https://github.com/memes/terraform-google-restricted-apis-dns/commit/6f39d0472823ddbdc3f252d94bb0ca5424dd1e79))

## [1.0.1](https://github.com/memes/terraform-google-restricted-apis-dns/compare/v1.0.0...v1.0.1) (2023-02-13)


### Bug Fixes

* Resolve broken validation ([d31d95e](https://github.com/memes/terraform-google-restricted-apis-dns/commit/d31d95e7415ee1b9279f207915038f4e7a9e45f0)), closes [#2](https://github.com/memes/terraform-google-restricted-apis-dns/issues/2)

## 1.0.0 (2023-02-13)


### Features

* Restricted APIs DNS module ([c651625](https://github.com/memes/terraform-google-restricted-apis-dns/commit/c651625c80d3c350ce6b4442256f1fd73dcb6690))

## Changelog

<!-- markdownlint-disable MD024 -->

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
