"""Common testing fixtures."""

import json
import os
import pathlib
import subprocess
import tempfile
from collections import Counter
from collections.abc import Callable, Generator
from contextlib import contextmanager
from typing import Any, cast

import google.auth
import googleapiclient.discovery
import googleapiclient.errors
import pytest

DEFAULT_PREFIX = "r-apis"
DEFAULT_LABELS = {
    "use_case": "automated-tofu-testing",
    "module": "terraform-google-restricted-apis-dns",
    "driver": "pytest",
}
DEFAULT_REGION = "us-west1"
EXPECTED_DESCRIPTION = "Override DNS entries for Google APIs access"
EXPECTED_DNS_ZONES = [
    "googleapis.com.",
    "gcr.io.",
    "pkg.dev.",
]
EXPECTED_VISIBILITY = "private"
EXPECTED_TTL = 300
EXPECTED_RESTRICTED_A_RRS = [
    "199.36.153.4",
    "199.36.153.5",
    "199.36.153.6",
    "199.36.153.7",
]
EXPECTED_RESTRICTED_AAAA_RRS = [
    "2600:2d00:2:1000::",
]
EXPECTED_PRIVATE_A_RRS = [
    "199.36.153.8",
    "199.36.153.9",
    "199.36.153.10",
    "199.36.153.11",
]
EXPECTED_PRIVATE_AAAA_RRS = [
    "2600:2d00:2:2000::",
]


@pytest.fixture(scope="session")
def prefix() -> str:
    """Return the prefix to use for test resources.

    Preference will be given to the environment variable TEST_PREFIX with default value of 'r-apis'.
    """
    prefix = os.getenv("TEST_PREFIX", DEFAULT_PREFIX)
    if prefix:
        prefix = prefix.strip()
    if not prefix:
        prefix = DEFAULT_PREFIX
    assert prefix
    return prefix


@pytest.fixture(scope="session")
def project_id() -> str:
    """Return the project id to use for tests.

    Preference will be given to the environment variables TEST_GOOGLE_CLOUD_PROJECT and GOOGLE_CLOUD_PROJECT followed by
    the default project identifier associated with local ADC credentials.
    """
    project_id = os.getenv("TEST_GOOGLE_CLOUD_PROJECT") or os.getenv("GOOGLE_CLOUD_PROJECT")
    if project_id:
        project_id = project_id.strip()
    if not project_id:
        _, project_id = google.auth.default()
    assert project_id
    return project_id


@pytest.fixture(scope="session")
def labels() -> dict[str, str]:
    """Return a dict of labels to apply to resources from environment variable TEST_GOOGLE_LABELS.

    If the environment variable TEST_GOOGLE_LABELS is not empty and can be parsed as a comma-separated list of key:value
    pairs then return a dict of keys to values.
    """
    raw = os.getenv("TEST_GOOGLE_LABELS")
    if not raw:
        return DEFAULT_LABELS
    return DEFAULT_LABELS | dict([x.split(":") for x in raw.split(",")])


@pytest.fixture(scope="session")
def region() -> str:
    """Return the Compute Engine region to use for tests.

    Preference will be given to the environment variables TEST_GOOGLE_REGION with fallback to 'us-west1'.
    """
    region = os.getenv("TEST_GOOGLE_REGION", DEFAULT_REGION)
    if region:
        region = region.strip()
    if not region:
        region = DEFAULT_REGION
    assert region
    return region


@pytest.fixture(scope="session")
def root_fixture_dir() -> pathlib.Path:
    """Return the fully-qualified directory at the fixture to exercise the root module."""
    root_fixture_dir = pathlib.Path(__file__).parent.joinpath("fixtures/root").resolve()
    assert root_fixture_dir.exists()
    assert root_fixture_dir.is_dir()
    assert root_fixture_dir.joinpath("main.tf").exists()
    assert root_fixture_dir.joinpath("outputs.tf").exists()
    assert root_fixture_dir.joinpath("variables.tf").exists()
    return root_fixture_dir


@pytest.fixture(scope="session")
def vpcs_fixture_dir() -> pathlib.Path:
    """Return the fully-qualified directory at the fixture to create testing VPC networks."""
    vpcs_fixture_dir = pathlib.Path(__file__).parent.joinpath("fixtures/vpcs").resolve()
    assert vpcs_fixture_dir.exists()
    assert vpcs_fixture_dir.is_dir()
    assert vpcs_fixture_dir.joinpath("main.tf").exists()
    assert vpcs_fixture_dir.joinpath("outputs.tf").exists()
    assert vpcs_fixture_dir.joinpath("variables.tf").exists()
    return vpcs_fixture_dir


def skip_destroy_phase() -> bool:
    """Determine if tofu destroy phase should be skipped for successful fixtures."""
    return os.getenv("TEST_SKIP_DESTROY_PHASE", "False").lower() in ["true", "t", "yes", "y", "1"]


@contextmanager
def run_tofu_in_workspace(
    fixture: pathlib.Path,
    workspace: str | None,
    tfvars: dict[str, Any] | None,
) -> Generator[dict[str, Any], None, None]:
    """Execute tofu fixture lifecycle in an optional workspace, yielding the output post-apply.

    NOTE: Resources will not be destroyed if the test case raises an error.
    """
    if tfvars is None:
        tfvars = {}
    tf_command = os.getenv("TEST_TF_COMMAND", "tofu")
    if workspace is not None and workspace != "":
        subprocess.run(
            [
                tf_command,
                f"-chdir={fixture!s}",
                "workspace",
                "select",
                "-or-create",
                workspace,
            ],
            check=True,
            capture_output=True,
        )
    subprocess.run(
        [
            tf_command,
            f"-chdir={fixture!s}",
            "init",
            "-no-color",
            "-input=false",
        ],
        check=True,
        capture_output=True,
    )
    with tempfile.NamedTemporaryFile(
        mode="w",
        prefix="tfvars",
        suffix=".json",
        encoding="utf-8",
        delete_on_close=False,
        delete=False,
    ) as tfvar_file:
        json.dump(tfvars, tfvar_file, ensure_ascii=False, indent=2)
        tfvar_file.close()
        # Execute plan then apply with a common plan file.
        with tempfile.NamedTemporaryFile(
            mode="w+b",
            prefix="tf",
            suffix=".plan",
            delete_on_close=False,
            delete=True,
        ) as plan_file:
            plan_file.close()
            subprocess.run(
                [
                    tf_command,
                    f"-chdir={fixture!s}",
                    "plan",
                    "-no-color",
                    "-input=false",
                    f"-var-file={tfvar_file.name}",
                    f"-out={plan_file.name}",
                ],
                check=True,
                capture_output=True,
            )
            subprocess.run(
                [
                    tf_command,
                    f"-chdir={fixture!s}",
                    "apply",
                    "-no-color",
                    "-input=false",
                    "-auto-approve",
                    plan_file.name,
                ],
                check=True,
                capture_output=True,
            )

        # Run plan again with -detailed-exitcode flag, which will only return an exit code of 0 if there are no further
        # changes. This is to find subtle issues in the Terraform declaration which inadvertently triggers unexpected
        # resource updates or recreations.
        subprocess.run(
            [
                tf_command,
                f"-chdir={fixture!s}",
                "plan",
                "-no-color",
                "-input=false",
                "-detailed-exitcode",
                f"-var-file={tfvar_file.name}",
            ],
            check=True,
            capture_output=True,
        )
        output = subprocess.run(
            [
                tf_command,
                f"-chdir={fixture!s}",
                "output",
                "-no-color",
                "-json",
            ],
            check=True,
            capture_output=True,
        )
        try:
            yield {k: v["value"] for k, v in json.loads(output.stdout).items()}
            if not skip_destroy_phase():
                subprocess.run(
                    [
                        tf_command,
                        f"-chdir={fixture!s}",
                        "destroy",
                        "-no-color",
                        "-input=false",
                        "-auto-approve",
                        f"-var-file={tfvar_file.name}",
                    ],
                    check=True,
                    capture_output=True,
                )
        finally:
            subprocess.run(
                [
                    tf_command,
                    f"-chdir={fixture!s}",
                    "workspace",
                    "select",
                    "default",
                ],
                check=True,
                capture_output=True,
            )


@pytest.fixture(scope="session")
def dns_client() -> googleapiclient.discovery.Resource:
    """Return a Cloud DNS client."""
    return googleapiclient.discovery.build("dns", "v1")


@pytest.fixture(scope="session")
def managed_zone_asserter(
    dns_client: googleapiclient.discovery.Resource,
    project_id: str,
) -> Callable[[str, str, str | None, dict[str, str] | None, list[str] | None], None]:
    """Return a function to assert a managed zone meets expectations."""

    def _asserter(
        managed_zone_name: str,
        dns_zone: str,
        expected_description: str | None = None,
        expected_labels: dict[str, str] | None = None,
        expected_network_self_links: list[str] | None = None,
    ) -> None:
        """Raise an AssertionError if Cloud DNS managed zone for DNS domain does not match expectations."""
        if expected_description is None:
            expected_description = EXPECTED_DESCRIPTION
        managed_zones = dns_client.managedZones()  # type: ignore[reportAttributeAccessIssue]
        result = managed_zones.get(
            project=project_id,
            managedZone=managed_zone_name,
        ).execute()
        assert result is not None
        assert result["description"] == expected_description
        assert result["dnsName"] == dns_zone
        assert result["visibility"] == EXPECTED_VISIBILITY
        if expected_labels is not None:
            labels = cast("dict[str, str]", result["labels"])
            assert labels is not None
            assert all(item in labels.items() for item in expected_labels.items())
        if expected_network_self_links is not None and len(expected_network_self_links) > 0:
            private_visibility_config = cast("dict[str, Any]", result["privateVisibilityConfig"])
            assert private_visibility_config is not None
            zone_networks = cast("list[dict[str, str]]", private_visibility_config["networks"])
            assert zone_networks is not None
            network_urls = [network["networkUrl"] for network in zone_networks]
            assert Counter(network_urls) == Counter(expected_network_self_links)
        else:
            assert "privateVisibilityConfig" not in result

    return _asserter


@pytest.fixture(scope="session")
def managed_zone_does_not_exist_asserter(
    dns_client: googleapiclient.discovery.Resource,
    project_id: str,
) -> Callable[[str], None]:
    """Return a function to assert the managed zone does not exist."""

    def _asserter(managed_zone_name: str) -> None:
        """Raise an error if the Cloud DNS managed zone exists."""
        managed_zones = dns_client.managedZones()  # type: ignore[reportAttributeAccessIssue]
        with pytest.raises(googleapiclient.errors.HttpError):
            managed_zones.get(
                project=project_id,
                managedZone=managed_zone_name,
            ).execute()

    return _asserter


@pytest.fixture(scope="session")
def resource_records_set_asserter(
    dns_client: googleapiclient.discovery.Resource,
    project_id: str,
) -> Callable[[str, str, str, list[str] | None], None]:
    """Return a function to assert a resource records set meets expectations."""

    def _asserter(
        managed_zone_name: str,
        dns_zone: str,
        dns_type: str,
        expected_rrdatas: list[str] | None,
    ) -> None:
        """Raise an error if the Cloud DNS address resource records for the DNS domain matches expectations."""
        resource_records = dns_client.resourceRecordSets()  # type: ignore[reportAttributeAccessIssue]
        request = resource_records.get(
            project=project_id,
            managedZone=managed_zone_name,
            name=dns_zone,
            type=dns_type,
        )
        if expected_rrdatas is not None and len(expected_rrdatas) > 0:
            result = request.execute()
            assert result is not None
            assert result["ttl"] == EXPECTED_TTL
            rrdatas = cast("list[str]", result["rrdatas"])
            assert rrdatas is not None
            assert Counter(rrdatas) == Counter(expected_rrdatas)
        else:
            with pytest.raises(googleapiclient.errors.HttpError):
                request.execute()

    return _asserter
