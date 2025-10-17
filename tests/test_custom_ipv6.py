"""Test fixture for Restricted APIs DNS module with custom IPv4 addresses."""

import pathlib
from collections.abc import Callable, Generator
from typing import Any

import pytest

from .conftest import EXPECTED_DNS_ZONES, run_tofu_in_workspace

FIXTURE_NAME = "custom-ipv4"
FIXTURE_LABELS = {
    "fixture": FIXTURE_NAME,
}
FIXTURE_NETWORK_SELF_LINKS = []
EXPECTED_A_RRS = None
EXPECTED_AAAA_RRS = [
    "fe00::10",
]


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
            "labels": fixture_labels,
            "network_self_links": FIXTURE_NETWORK_SELF_LINKS,
            "addresses": {
                "ipv4": EXPECTED_A_RRS,
                "ipv6": EXPECTED_AAAA_RRS,
            },
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
        managed_zone_name=managed_zone_name_builder(fixture_name, dns_zone),
        dns_zone=dns_zone,
        expected_labels=fixture_labels,
    )


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
    [("A", EXPECTED_A_RRS), ("AAAA", EXPECTED_AAAA_RRS)],
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
