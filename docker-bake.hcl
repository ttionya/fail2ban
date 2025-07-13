variable "VERSION" {
  default = "latest"
}

variable "TEST_TAG" {
  default = "ttionya/fail2ban:test"
}

target "docker-metadata-action" {}

target "_common" {
  inherits = ["docker-metadata-action"]
  context = "."
  dockerfile = "Dockerfile"
}

target "_common_multi_platforms" {
  platforms = [
    "linux/386",
    "linux/amd64",
    "linux/arm/v6",
    "linux/arm/v7",
    "linux/arm64",
    "linux/ppc64le",
    "linux/s390x"
  ]
}

target "_common_tags" {
  tags = [
    "ttionya/fail2ban:latest",
    "ttionya/fail2ban:${VERSION}",
    "ghcr.io/ttionya/fail2ban:latest",
    "ghcr.io/ttionya/fail2ban:${VERSION}"
  ]
}

target "image-stable" {
  inherits = ["_common", "_common_multi_platforms", "_common_tags"]
}

target "image-schedule" {
  inherits = ["image-stable"]
}

target "image-beta" {
  inherits = ["_common", "_common_multi_platforms"]
  tags = [
    "ttionya/fail2ban:${VERSION}"
  ]
}

target "image-test" {
  inherits = ["_common"]
  tags = [
    "${TEST_TAG}"
  ]
}
