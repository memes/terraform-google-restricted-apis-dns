"""Test fixture for Private APIs DNS module null value for overrides."""

import pathlib
from collections.abc import Callable, Generator
from typing import Any

import pytest

from .conftest import EXPECTED_ALWAYS_DNS_ZONES as EXPECTED_DNS_ZONES
from .conftest import EXPECTED_OVERRIDES_DNS_ZONES as UNEXPECTED_DNS_ZONES
from .conftest import EXPECTED_PRIVATE_A_RRS, EXPECTED_PRIVATE_AAAA_RRS, run_tofu_in_workspace

FIXTURE_NAME = "null-overrides-private"
FIXTURE_LABELS = {
    "fixture": FIXTURE_NAME,
}
FIXTURE_NETWORK_SELF_LINKS = []
FIXTURE_OVERRIDES = None


@pytest.fixture(scope="module")
def fixture_name(prefix: str) -> str:
    """Return the name to use for resources in this module."""
    return f"{prefix}-{FIXTURE_NAME}"


@pytest.fixture(scope="module")
def fixture_labels(labels: dict[str, str]) -> dict[str, str] | None:
    """Return a dict of labels for this test module."""
    return FIXTURE_LABELS | labels


@pytest.fixture(scope="module")
def fixture_output(
    root_fixture_dir: pathlib.Path,
    project_id: str,
    fixture_name: str,
    fixture_labels: dict[str, str] | None,
) -> Generator[dict[str, Any], None, None]:
    """Create Restricted APIs DNS zone and records for test case."""
    with run_tofu_in_workspace(
        fixture=root_fixture_dir,
        workspace=FIXTURE_NAME,
        tfvars={
            "project_id": project_id,
            "name": fixture_name,
            "use_private_access_endpoints": True,
            "labels": fixture_labels,
            "network_self_links": FIXTURE_NETWORK_SELF_LINKS,
            "overrides": FIXTURE_OVERRIDES,
        },
    ) as output:
        yield output


def test_output_values(fixture_output: dict[str, Any]) -> None:
    """Verify the fixture output meets expectations."""
    assert fixture_output is not None
    assert fixture_output == {}


@pytest.mark.parametrize("dns_zone", EXPECTED_DNS_ZONES)
def test_managed_zone(
    fixture_output: dict[str, Any],  # noqa: ARG001
    managed_zone_asserter: Callable[..., None],
    managed_zone_name_builder: Callable[[str, str], str],
    fixture_name: str,
    fixture_labels: dict[str, str] | None,
    dns_zone: str,
) -> None:
    """Verify that the Cloud DNS managed zone for DNS domain matches expectations."""
    managed_zone_asserter(
        dns_zone=dns_zone,
        managed_zone_name=managed_zone_name_builder(fixture_name, dns_zone),
        expected_labels=fixture_labels,
    )


@pytest.mark.parametrize("dns_zone", UNEXPECTED_DNS_ZONES)
def test_unexpected_managed_zone(
    fixture_output: dict[str, Any],  # noqa: ARG001
    managed_zone_does_not_exist_asserter: Callable[[str], None],
    managed_zone_name_builder: Callable[[str, str], str],
    fixture_name: str,
    dns_zone: str,
) -> None:
    """Verify that the Cloud DNS managed zone for unexpected DNS domain does not exist."""
    managed_zone_does_not_exist_asserter(managed_zone_name_builder(fixture_name, dns_zone))


@pytest.mark.parametrize("dns_zone", EXPECTED_DNS_ZONES)
def test_cname_record_set(
    fixture_output: dict[str, Any],  # noqa: ARG001
    resource_records_set_asserter: Callable[..., None],
    managed_zone_name_builder: Callable[[str, str], str],
    fixture_name: str,
    dns_zone: str,
) -> None:
    """Verify that the Cloud DNS CNAME resource records for the wildcard DNS domain matches expectations."""
    resource_records_set_asserter(
        managed_zone_name=managed_zone_name_builder(fixture_name, dns_zone),
        dns_zone=f"*.{dns_zone}",
        dns_type="CNAME",
        expected_rrdatas=[
            dns_zone,
        ],
    )


@pytest.mark.parametrize("dns_zone", EXPECTED_DNS_ZONES)
@pytest.mark.parametrize(
    ("dns_type", "expected_rrdatas"),
    [("A", EXPECTED_PRIVATE_A_RRS), ("AAAA", EXPECTED_PRIVATE_AAAA_RRS)],
)
def test_address_record_set(
    fixture_output: dict[str, Any],  # noqa: ARG001
    resource_records_set_asserter: Callable[..., None],
    managed_zone_name_builder: Callable[[str, str], str],
    fixture_name: str,
    dns_zone: str,
    dns_type: str,
    expected_rrdatas: list[str] | None,
) -> None:
    """Verify that the Cloud DNS address resource records for the DNS domain matches expectations."""
    resource_records_set_asserter(
        managed_zone_name=managed_zone_name_builder(fixture_name, dns_zone),
        dns_zone=dns_zone,
        dns_type=dns_type,
        expected_rrdatas=expected_rrdatas,
    )
