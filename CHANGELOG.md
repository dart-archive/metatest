# 0.2.2+2

* Compatibility with the latest `test`.

# 0.2.2+1

* Require `test` version `0.12.5`.

# 0.2.1

* Support passing named arguments through to the underlying call to `test()`.

# 0.2.0+1

* Compatibility with the latest `test`.

# 0.2.0

* Full compatibility with `test` `0.12.0`.

* Tests are no longer run in their own isolates. Instead, each test's
  environment is isolated manually using the `test` package's infrastructure.

* `initMetatest` is no longer necessary and has been removed.

* `metaSetUp` has been removed; the `test` package's `setUp` may be used
  instead.

* `expectTestResults` has been removed.

# 0.1.1

* Changed maximum version of `unittest` to support development.

# 0.1.0

* First release.
